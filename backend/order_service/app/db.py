import os
import sys

from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base
from sqlalchemy.orm import sessionmaker

# Check if we're running tests
IS_TESTING = "pytest" in sys.modules or os.getenv("TESTING") == "true"

if IS_TESTING and os.getenv("POSTGRES_HOST") is None:
    # Use SQLite for local testing when PostgreSQL is not available
    DATABASE_URL = "sqlite:///./test_order_service.db"
    engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
else:
    # Use PostgreSQL for production and CI/CD
    POSTGRES_USER = os.getenv("POSTGRES_USER", "postgres")
    POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD", "postgres")
    POSTGRES_DB = os.getenv("POSTGRES_DB", "order_service")
    POSTGRES_HOST = os.getenv("POSTGRES_HOST", "localhost")
    POSTGRES_PORT = os.getenv("POSTGRES_PORT", "5432")

    DATABASE_URL = (
        f"postgresql://{POSTGRES_USER}:{POSTGRES_PASSWORD}@"
        f"{POSTGRES_HOST}:{POSTGRES_PORT}/{POSTGRES_DB}"
    )
    engine = create_engine(DATABASE_URL, pool_pre_ping=True)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
