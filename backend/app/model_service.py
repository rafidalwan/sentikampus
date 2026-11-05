import pickle
from pathlib import Path

MODEL_PATH = Path(__file__).resolve().parent.parent / "models" / "sentiment.pkl"

def get_model():
    if not MODEL_PATH.exists():
        alt_path = Path(__file__).resolve().parent.parent / "models" / "sentiment_lama.pkl"
        if alt_path.exists():
            with alt_path.open("rb") as f:
                return pickle.load(f)
        raise FileNotFoundError(f"Model file not found at {MODEL_PATH}")
    with MODEL_PATH.open("rb") as f:
        return pickle.load(f)

try:
    model = get_model()
except Exception:
    model = None

def get_explanation(active_model, text: str, label: str) -> dict:
    supporting = []
    opposing = []
    try:
        if hasattr(active_model, "named_steps"):
            vec = active_model.named_steps.get("tfidf")
            clf = active_model.named_steps.get("model")
            if vec is not None and clf is not None and hasattr(clf, "coef_"):
                class_idx = list(clf.classes_).index(label)
                coef = clf.coef_[class_idx]
                feature_names = vec.get_feature_names_out()
                X = vec.transform([text])
                nonzero_indices = X.nonzero()[1]

                for idx in nonzero_indices:
                    word = feature_names[idx]
                    val = float(X[0, idx] * coef[idx])
                    if val > 0:
                        supporting.append({"word": word, "contribution": val})
                    elif val < 0:
                        opposing.append({"word": word, "contribution": val})

                supporting.sort(key=lambda x: x["contribution"], reverse=True)
                opposing.sort(key=lambda x: x["contribution"])
    except Exception as e:
        print(f"Explanation extraction error: {e}")

    return {
        "supporting_words": supporting,
        "opposing_words": opposing
    }

def predict_text(text: str) -> dict:
    global model
    if model is None:
        model = get_model()
    label = model.predict([text])[0]
    probabilities = model.predict_proba([text])[0]
    score = float(max(probabilities))
    explanation = get_explanation(model, text, label)
    return {
        "label": label,
        "score": score,
        "explanation": explanation
    }
