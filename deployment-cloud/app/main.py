from time import perf_counter
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from .schemas import SentimentRequest, SentimentResponse
from .model_service import predict_text

MODEL_VERSION = "v1"

app = FastAPI(title="SentiKampus API Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type", "Accept"],
    expose_headers=["X-Process-Time-Ms"],
)

# MIDDLEWARE LATENCY MONITORING
@app.middleware("http")
async def add_process_time(request: Request, call_next):
    start = perf_counter()
    response = await call_next(request)
    elapsed_ms = (perf_counter() - start) * 1000
    response.headers["X-Process-Time-Ms"] = f"{elapsed_ms:.2f}"
    print({
        "path": request.url.path,
        "status": response.status_code,
        "latency_ms": round(elapsed_ms, 2),
        "model_version": MODEL_VERSION
    })
    return response

@app.get("/")
def home():
    return {
        "message": "SentiKampus API berjalan",
        "docs": "/docs",
        "health": "/health"
    }

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/api/v1/predict", response_model=SentimentResponse)
def predict(data: SentimentRequest):
    result = predict_text(data.text)
    return SentimentResponse(**result)
