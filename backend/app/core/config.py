# backend/app/core/config.py
from pydantic_settings import BaseSettings
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent.parent.parent

class Settings(BaseSettings):
    APP_NAME: str = "Rafiki"
    APP_ENV: str = "development"
    SECRET_KEY: str = "change-this-later"
    DATABASE_URL: str = "sqlite:///./rafiki.db"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 10080
    ALGORITHM: str = "HS256"

    # M-Pesa
    MPESA_CONSUMER_KEY: str = ""
    MPESA_CONSUMER_SECRET: str = ""
    MPESA_SHORTCODE: str = ""
    MPESA_PASSKEY: str = ""
    MPESA_CALLBACK_URL: str = ""

    # SMS
    AT_USERNAME: str = ""
    AT_API_KEY: str = ""

    class Config:
        env_file = str(BASE_DIR / ".env")
        extra = "ignore"

settings = Settings()