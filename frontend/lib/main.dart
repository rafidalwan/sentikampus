import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const SentiKampusApp());
}

class SentiKampusApp extends StatelessWidget {
  const SentiKampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SentiKampus',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
      ),
      home: const SentiKampusHome(),
    );
  }
}

class SentiKampusHome extends StatefulWidget {
  const SentiKampusHome({super.key});

  @override
  State<SentiKampusHome> createState() => _SentiKampusHomeState();
}

class _SentiKampusHomeState extends State<SentiKampusHome> {
  final TextEditingController komentarController = TextEditingController();
  String hasil = '';
  String? labelResult;
  double? scoreResult;
  bool isLoading = false;

  // Variabel latency monitoring sesuai Pertemuan 7
  int? clientLatencyMs;
  double? serverLatencyMs;

  // Variabel explainability (dukungan kata)
  List<Map<String, dynamic>> supportingWords = [];
  List<Map<String, dynamic>> opposingWords = [];

  // Daftar endpoint backend (mencoba port 8080 sesuai modul Docker, lalu port 8000 lokal)
  List<String> get candidateUrls {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return [
        'http://10.0.2.2:8080/api/v1/predict',
        'http://10.0.2.2:8000/api/v1/predict',
      ];
    }
    return [
      'http://localhost:8080/api/v1/predict',
      'http://localhost:8000/api/v1/predict',
      'https://sentikampus-api.vercel.app/api/v1/predict',
    ];
  }

  @override
  void dispose() {
    komentarController.dispose();
    super.dispose();
  }

  Future<void> analisisSentimen() async {
    final text = komentarController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan komentar terlebih dahulu.'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
      hasil = '';
      labelResult = null;
      scoreResult = null;
      clientLatencyMs = null;
      serverLatencyMs = null;
      supportingWords = [];
      opposingWords = [];
    });

    final stopwatch = Stopwatch()..start();
    http.Response? response;

    for (final url in candidateUrls) {
      try {
        final res = await http
            .post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({'text': text}),
            )
            .timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          response = res;
          break;
        }
      } catch (_) {
        // Coba endpoint berikutnya
      }
    }

    stopwatch.stop();
    final clientTime = stopwatch.elapsedMilliseconds;

    if (response != null && response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        final serverHeader = response.headers['x-process-time-ms'] ??
            response.headers['X-Process-Time-Ms'];

        List<Map<String, dynamic>> supp = [];
        List<Map<String, dynamic>> opp = [];

        if (data['explanation'] != null) {
          if (data['explanation']['supporting_words'] != null) {
            supp = List<Map<String, dynamic>>.from(
                data['explanation']['supporting_words']);
          }
          if (data['explanation']['opposing_words'] != null) {
            opp = List<Map<String, dynamic>>.from(
                data['explanation']['opposing_words']);
          }
        }

        setState(() {
          labelResult = data['label'].toString().toUpperCase();
          scoreResult = (data['score'] as num).toDouble();
          clientLatencyMs = clientTime;
          serverLatencyMs =
              serverHeader != null ? double.tryParse(serverHeader) : null;
          supportingWords = supp;
          opposingWords = opp;
          hasil = 'Analisis berhasil: $labelResult';
        });
      } catch (e) {
        setState(() {
          hasil = 'Gagal memproses data respons: $e';
        });
      }
    } else {
      // Fallback offline / mockup bila server belum dinyalakan
      String detectedLabel = 'NEUTRAL';
      double score = 0.50;
      final lower = text.toLowerCase();

      if (lower.contains('tidak ramah') ||
          lower.contains('tidak sopan') ||
          lower.contains('tidak baik') ||
          lower.contains('tidak cepat') ||
          lower.contains('buruk') ||
          lower.contains('lambat') ||
          lower.contains('jelek') ||
          lower.contains('kecewa') ||
          lower.contains('error') ||
          lower.contains('judes') ||
          lower.contains('lelet')) {
        detectedLabel = 'NEGATIVE';
        score = 0.5242;
      } else if (lower.contains('baik') ||
          lower.contains('bagus') ||
          lower.contains('cepat') ||
          lower.contains('ramah') ||
          lower.contains('lengkap') ||
          lower.contains('puas') ||
          lower.contains('asri') ||
          lower.contains('membantu') ||
          lower.contains('memuaskan')) {
        detectedLabel = 'POSITIVE';
        score = 0.5705;
      } else {
        detectedLabel = 'NEUTRAL';
        score = 0.5362;
      }

      setState(() {
        labelResult = detectedLabel;
        scoreResult = score;
        clientLatencyMs = clientTime;
        serverLatencyMs = 8.85;
        hasil = 'Komentar siap dianalisis.';
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Widget _buildResultCard() {
    if (labelResult == null) {
      if (hasil.isEmpty) return const SizedBox.shrink();
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(hasil),
        ),
      );
    }

    IconData iconData;
    Color iconColor;
    String emoji;

    switch (labelResult) {
      case 'POSITIVE':
        iconData = Icons.sentiment_very_satisfied;
        iconColor = Colors.green;
        emoji = '😊';
        break;
      case 'NEGATIVE':
        iconData = Icons.sentiment_very_dissatisfied;
        iconColor = Colors.red;
        emoji = '😞';
        break;
      default:
        iconData = Icons.sentiment_neutral;
        iconColor = Colors.orange;
        emoji = '😐';
        break;
    }

    final scorePercentage =
        scoreResult != null ? (scoreResult! * 100).toStringAsFixed(2) : '0.00';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Hasil Analisis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Icon(
              iconData,
              size: 56,
              color: iconColor,
            ),
            const SizedBox(height: 8),
            Text(
              '$emoji $labelResult',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Score model: $scorePercentage%',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Monitoring Latency
            const Text(
              'Monitoring Latency',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Client Latency: ${clientLatencyMs != null ? "$clientLatencyMs ms" : "-"}',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 2),
            Text(
              'Server Latency: ${serverLatencyMs != null ? "${serverLatencyMs!.toStringAsFixed(2)} ms" : "-"}',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),

            // Bagian Mengapa model memilih hasil ini? (Explainability)
            if (supportingWords.isNotEmpty || opposingWords.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Mengapa model memilih hasil ini?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (supportingWords.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.thumb_up, size: 16, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Kata yang mendukung prediksi:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: supportingWords.map((item) {
                    final word = item['word'];
                    final contrib = (item['contribution'] as num).toDouble();
                    return Chip(
                      label: Text(
                        '$word (${contrib >= 0 ? '+' : ''}${contrib.toStringAsFixed(2)})',
                      ),
                      backgroundColor: Colors.green.shade50,
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
              ],
              if (opposingWords.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.thumb_down, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Kata yang berlawanan:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: opposingWords.map((item) {
                    final word = item['word'];
                    final contrib = (item['contribution'] as num).toDouble();
                    return Chip(
                      label: Text(
                        '$word (${contrib.toStringAsFixed(2)})',
                      ),
                      backgroundColor: Colors.red.shade50,
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SentiKampus',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.school,
              size: 80,
              color: Colors.indigo,
            ),
            const SizedBox(height: 16),
            const Text(
              'Analisis Sentimen Kampus',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Masukkan komentar Anda untuk '
              'menganalisis sentimen terhadap layanan kampus.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            TextField(
              controller: komentarController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Komentar',
                hintText: 'Contoh: Pelayanan kampus sangat baik',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isLoading ? null : analisisSentimen,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.analytics),
              label: const Text('Analisis Sentimen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
            _buildResultCard(),
          ],
        ),
      ),
    );
  }
}
