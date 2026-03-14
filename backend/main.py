import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import engine
from app.models import user, wallet, transaction
from app.routers import auth, user as user_router, wallet as wallet_router, airtime, data, transactions

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)

# Create all database tables (no-op if they already exist)
user.Base.metadata.create_all(bind=engine)
wallet.Base.metadata.create_all(bind=engine)
transaction.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="ADP Nigeria API",
    version="1.0.0",
    description="Backend API for ADP — a Nigerian airtime and data purchase application.",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS — allow all origins in dev; restrict in production
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(auth.router, prefix="/api/v1")
app.include_router(user_router.router, prefix="/api/v1")
app.include_router(wallet_router.router, prefix="/api/v1")
app.include_router(airtime.router, prefix="/api/v1")
app.include_router(data.router, prefix="/api/v1")
app.include_router(transactions.router, prefix="/api/v1")


@app.get("/", tags=["Health"])
def root():
    """Health check / API info."""
    return {
        "message": "ADP Nigeria API",
        "version": "1.0.0",
        "docs": "/docs",
        "dev_mode": settings.dev_mode,
    }


@app.get("/health", tags=["Health"])
def health():
    """Simple health check endpoint."""
    return {"status": "ok"}
