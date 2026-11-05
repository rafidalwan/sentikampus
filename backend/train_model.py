import os
import csv
import pickle
from pathlib import Path
from sklearn.pipeline import Pipeline
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix

# Lokasi file dataset
CSV_PATH = Path(__file__).resolve().parent.parent / "training_samples.csv"
if not CSV_PATH.exists():
    CSV_PATH = Path("training_samples.csv")

LABEL_MAPPING = {
    "negatif": "negative",
    "negative": "negative",
    "positif": "positive",
    "positive": "positive",
    "netral": "neutral",
    "neutral": "neutral"
}

texts = []
labels = []

if CSV_PATH.exists():
    with CSV_PATH.open("r", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        for row in reader:
            txt = row.get("text", "").strip()
            lbl = row.get("label", "").strip().lower()
            if txt and lbl:
                mapped_label = LABEL_MAPPING.get(lbl, lbl)
                texts.append(txt)
                labels.append(mapped_label)

if len(texts) < 10:
    # Fallback default texts jika csv belum siap
    texts = [
        'pelayanan cepat dan bagus', 'petugas sangat ramah dan membantu',
        'pelayanan lambat sekali', 'sistem sering error dan membingungkan',
        'jadwal kuliah diumumkan hari ini', 'pengurusan administrasi di kampus'
    ]
    labels = ['positive', 'positive', 'negative', 'negative', 'neutral', 'neutral']

# Train-test split untuk evaluasi model (20 data uji)
test_size = 20 if len(texts) >= 50 else 0.2
X_train, X_test, y_train, y_test = train_test_split(
    texts, labels, test_size=test_size, random_state=42, stratify=labels if len(texts) >= 50 else None
)

# Pipeline Model A - Unigram
pipeline = Pipeline([
    ('tfidf', TfidfVectorizer(ngram_range=(1, 1))),
    ('model', LogisticRegression(C=1.0, max_iter=200))
])

pipeline.fit(X_train, y_train)
y_pred = pipeline.predict(X_test)

classes = ['negative', 'neutral', 'positive']
print(classification_report(y_test, y_pred, labels=classes, target_names=classes, zero_division=0))
print("Confusion Matrix:")
print(confusion_matrix(y_test, y_pred, labels=classes))
print()

# Latih kembali pipeline pada seluruh dataset untuk hasil produksi optimal
pipeline.fit(texts, labels)

models_dir = Path(__file__).resolve().parent / "models"
models_dir.mkdir(parents=True, exist_ok=True)

sentiment_pkl = models_dir / "sentiment.pkl"
with sentiment_pkl.open("wb") as f:
    pickle.dump(pipeline, f)

sentiment_lama_pkl = models_dir / "sentiment_lama.pkl"
with sentiment_lama_pkl.open("wb") as f:
    pickle.dump(pipeline, f)

print("Training model final selesai.\n")
print(f"Model berhasil disimpan: {sentiment_pkl}")
print(f"Kelas model: {pipeline.named_steps['model'].classes_}")
print("Konfigurasi terpilih: Model A - Unigram")

if __name__ == "__main__":
    test_samples = [
        "pelayanan kampus baik",
        "pelayanan administrasi kampus sangat lambat",
        "pengurusan administrasi di kampus"
    ]
    print("\nTesting model...")
    for s in test_samples:
        pred = pipeline.predict([s])[0]
        prob = max(pipeline.predict_proba([s])[0])
        print(f"Text: '{s}' -> Pred: {pred} (Score: {prob:.4f})")
