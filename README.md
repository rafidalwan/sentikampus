---
title: SentiKampus API
emoji: 🎓
colorFrom: indigo
colorTo: blue
sdk: docker
app_port: 8000
---

# SentiKampus - Sistem Analisis Sentimen Layanan Kampus

Proyek pembelajaran SentiKampus mencakup:
1. **Backend API**: FastAPI (`/health`, `/api/v1/predict`) dengan validasi schema Pydantic.
2. **Machine Learning Model**: Pipeline TfidfVectorizer + LogisticRegression (`models/sentiment.pkl`).
3. **Web Interface**: Streamlit (`app.py`) pada port 8501.
4. **Mobile & Web Interface**: Flutter App (`frontend/`) pada port 8000/8501 / cloud.
5. **Docker Compose**: Orkestrasi multi-container untuk backend (`sentikampus-api`) dan frontend (`sentikampus-web`).
