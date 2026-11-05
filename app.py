import os
import requests
import streamlit as st

st.set_page_config(page_title="SentiKampus", page_icon="🎓")
st.title("🎓 SentiKampus")
st.subheader("Analisis Sentimen Layanan Kampus")
st.write("Masukkan komentar untuk mengetahui sentimennya.")

# URL FastAPI: default ke http://localhost:8080 atau 8000
default_url = os.environ.get("SENTIKAMPUS_API_URL", "http://localhost:8080")
api_url = st.text_input(
    "URL FastAPI",
    value=default_url,
    placeholder="http://localhost:8080"   
)
komentar = st.text_area("Komentar", height=120, placeholder="Contoh: Pelayanan kampus sangat baik")

TAMPILAN = {
    "positive": ("😊 Sentimen Positif", st.success),
    "negative": ("😞 Sentimen Negatif", st.error),
    "netral":   ("😐 Sentimen Netral", st.info),
    "neutral":  ("😐 Sentimen Netral", st.info),
    "error":    ("⚠️ Terdeteksi gangguan/error", st.warning),
}

if st.button("Analisis Komentar", type="primary"):
    if not api_url.strip():
        st.warning("URL FastAPI belum diisi.")
    elif len(komentar.strip()) < 3:
        st.warning("Komentar minimal 3 karakter.")
    else:
        try:
            target_url = api_url.strip().rstrip("/")
            if not target_url.endswith("/api/v1/predict"):
                target_url += "/api/v1/predict"
            resp = requests.post(
                target_url,
                json={"text": komentar.strip()},
                timeout=20,
            )
            if resp.status_code == 200:
                data = resp.json()
                label = data.get("label", "").lower()
                teks, tampil = TAMPILAN.get(label, (f"Label: {label}", st.info))
                tampil(teks)
                st.write("### Skor dari API")
                st.header(f"{data['score']:.2f}")

                latency = resp.headers.get("X-Process-Time-Ms") or resp.headers.get("x-process-time-ms")
                if latency:
                    st.info(f"⚡ **Server Latency**: {latency} ms")

                explanation = data.get("explanation")
                if explanation:
                    st.write("#### Mengapa model memilih hasil ini?")
                    supp = explanation.get("supporting_words", [])
                    opp = explanation.get("opposing_words", [])
                    if supp:
                        st.write("👍 **Kata pendukung:** " + ", ".join([f"`{w['word']}` (+{w['contribution']:.2f})" for w in supp]))
                    if opp:
                        st.write("👎 **Kata berlawanan:** " + ", ".join([f"`{w['word']}` ({w['contribution']:.2f})" for w in opp]))

                st.caption("Skor mengikuti respons backend dengan monitoring waktu respons & explainability.")
            else:
                st.error(f"API error {resp.status_code}: {resp.text[:200]}")
        except Exception as e:
            st.error(f"Gagal terhubung ke API: {e}")
