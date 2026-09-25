# backend/app/core/database.py
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from backend.app.core.config import settings

# Read the DB URL from settings
_db_url = settings.DATABASE_URL

# Normalize URL prefix
if _db_url.startswith("postgres://"):
    _db_url = _db_url.replace("postgres://", "postgresql://", 1)

# 🔧 Force SQLAlchemy to use psycopg2 driver (v2), NOT psycopg (v3)
# This prevents "ModuleNotFoundError: No module named 'psycopg'"
if _db_url.startswith("postgresql://") and "+psycopg2" not in _db_url:
    _db_url = _db_url.replace("postgresql://", "postgresql+psycopg2://", 1)

# SQLite needs extra args, PostgreSQL doesn't
_connect_args = {}
if _db_url.startswith("sqlite"):
    _connect_args = {"check_same_thread": False}

engine = create_engine(
    _db_url,
    connect_args=_connect_args,
    pool_pre_ping=True,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()