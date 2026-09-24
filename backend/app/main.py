# backend/app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.app.core.config import settings
from backend.app.core.database import Base, engine
from backend.app.routes import auth, search, bookings, payments, whatsapp, providers, admin

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Rafiki API",
    description="Local services booking for Kenya",
    version="0.2.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router,      prefix="/api/v1")
app.include_router(search.router,    prefix="/api/v1")
app.include_router(bookings.router,  prefix="/api/v1")
app.include_router(payments.router,  prefix="/api/v1")
app.include_router(whatsapp.router,  prefix="/api/v1")
app.include_router(providers.router, prefix="/api/v1")
app.include_router(admin.router,     prefix="/api/v1")


@app.get("/")
def root():
    return {
        "app": settings.APP_NAME,
        "status": "live",
        "docs": "/docs",
        "env": settings.APP_ENV,
    }