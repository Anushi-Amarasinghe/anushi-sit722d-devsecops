import logging
import os
from decimal import Decimal
from unittest.mock import AsyncMock, patch

import pytest
from app.db import SessionLocal, engine, get_db
from app.main import PRODUCT_SERVICE_URL, app
from app.models import Base, Order, OrderItem

from fastapi.testclient import TestClient
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import Session

# Suppress noisy logs from SQLAlchemy/FastAPI/Uvicorn during tests for cleaner output
logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)
logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
logging.getLogger("uvicorn.error").setLevel(logging.WARNING)
logging.getLogger("fastapi").setLevel(logging.WARNING)
logging.getLogger("app.main").setLevel(logging.WARNING)


# --- Pytest Fixtures ---
@pytest.fixture(scope="session", autouse=True)
def setup_database_for_tests():
    """Set up the test database. Uses SQLite for local testing, PostgreSQL for CI/CD."""
    try:
        logging.info("Order Service Tests: Setting up test database...")
        
        # Clean up any existing test database file (for SQLite)
        if "sqlite" in str(engine.url):
            test_db_path = "./test_order_service.db"
            if os.path.exists(test_db_path):
                os.remove(test_db_path)
                logging.info("Order Service Tests: Removed existing SQLite test database.")
        
        # Create all tables required by the application
        Base.metadata.create_all(bind=engine)
        logging.info("Order Service Tests: Successfully created all tables for test setup.")
        
    except Exception as e:
        pytest.fail(
            f"Order Service Tests: Failed to set up test database: {e}",
            pytrace=True,
        )

    yield
    
    # Clean up after tests
    try:
        if "sqlite" in str(engine.url):
            test_db_path = "./test_order_service.db"
            if os.path.exists(test_db_path):
                os.remove(test_db_path)
                logging.info("Order Service Tests: Cleaned up SQLite test database.")
    except Exception as e:
        logging.warning(f"Order Service Tests: Failed to clean up test database: {e}")


@pytest.fixture(scope="function")
def db_session_for_test():
    connection = engine.connect()
    transaction = connection.begin()
    db = SessionLocal(bind=connection)

    def override_get_db():
        yield db

    app.dependency_overrides[get_db] = override_get_db

    try:
        yield db
    finally:
        transaction.rollback()
        db.close()
        connection.close()
        app.dependency_overrides.pop(get_db, None)


@pytest.fixture(scope="module")
def client():
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture(scope="function")
def mock_httpx_client():
    with patch("app.main.httpx.AsyncClient") as mock_async_client_cls:
        mock_client_instance = AsyncMock()
        mock_async_client_cls.return_value.__aenter__.return_value = (
            mock_client_instance
        )
        yield mock_client_instance


# --- Order Service Tests ---
def test_read_root(client: TestClient):
    """Test the root endpoint."""
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Welcome to the Order Service!"}


def test_health_check(client: TestClient):
    """Test the health check endpoint."""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "service": "order-service"}
