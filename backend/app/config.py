from pydantic import model_validator
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Leave empty to auto-select based on dev_mode
    database_url: str = ""
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

    # Production PostgreSQL defaults (used when dev_mode=False and DATABASE_URL not set)
    pg_host: str = "localhost"
    pg_port: int = 5432
    pg_user: str = "postgres"
    pg_password: str = "password"
    pg_db: str = "adp_db"

    @model_validator(mode="after")
    def set_database_url(self) -> "Settings":
        if not self.database_url:
            if self.dev_mode:
                self.database_url = "sqlite:///./adp.db"
            else:
                self.database_url = (
                    f"postgresql://{self.pg_user}:{self.pg_password}"
                    f"@{self.pg_host}:{self.pg_port}/{self.pg_db}"
                )
        return self

    class Config:
        env_file = ".env"


settings = Settings()
