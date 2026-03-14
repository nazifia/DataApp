from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql://postgres:password@localhost:5432/adp_db"
    secret_key: str = "dev-secret-key"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 30
    termii_api_key: str = ""
    termii_sender_id: str = "N-Alert"
    vtpass_api_key: str = ""
    vtpass_secret_key: str = ""
    vtpass_base_url: str = "https://sandbox.vtpass.com/api"
    dev_mode: bool = True
    test_otp: str = "123456"

    class Config:
        env_file = ".env"


settings = Settings()
