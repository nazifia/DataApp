import logging
import traceback

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from app.config import settings
from app.database import engine
from app.models import user, wallet, transaction, audit_log
from app.routers import auth, user as user_router, wallet as wallet_router, airtime, data, transactions
from app.routers import admin_pages
from app.routers import admin as admin_router

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
audit_log.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="TopUpNaija API",
    version="1.0.0",
    description="Backend API for TopUpNaija — a Nigerian airtime and data purchase application.",
    docs_url="/docs",
    redoc_url="/redoc",
    debug=settings.dev_mode,
)

@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    # Redirect browser admin pages to login on 401/403 instead of returning JSON
    if exc.status_code in (401, 403) and request.url.path.startswith("/admin/"):
        return RedirectResponse(url="/admin/login", status_code=302)
    return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail})


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    tb = traceback.format_exc()
    logger.error("Unhandled exception:\n%s", tb)
    detail = tb if settings.dev_mode else "Internal server error."
    return JSONResponse(status_code=500, content={"detail": detail})


# CORS — allow all origins in dev; restrict in production
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files
app.mount("/static", StaticFiles(directory="static"), name="static")

# Register routers
app.include_router(auth.router, prefix="/api/v1")
app.include_router(user_router.router, prefix="/api/v1")
app.include_router(wallet_router.router, prefix="/api/v1")
app.include_router(airtime.router, prefix="/api/v1")
app.include_router(data.router, prefix="/api/v1")
app.include_router(transactions.router, prefix="/api/v1")
app.include_router(admin_pages.router)
app.include_router(admin_router.router, prefix="/api/v1")


@app.get("/", tags=["Health"])
def root():
    """Health check / API info."""
    return {
        "message": "TopUpNaija API",
        "version": "1.0.0",
        "docs": "/docs",
        "dev_mode": settings.dev_mode,
    }


@app.get("/health", tags=["Health"])
def health():
    """Simple health check endpoint."""
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
