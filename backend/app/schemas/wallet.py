from pydantic import BaseModel, field_validator


class WalletBalanceResponse(BaseModel):
    balance: float


class FundWalletRequest(BaseModel):
    amount: float

    @field_validator("amount")
    @classmethod
    def validate_amount(cls, v: float) -> float:
        if v <= 0:
            raise ValueError("Amount must be greater than 0.")
        if v < 50:
            raise ValueError("Minimum funding amount is NGN 50.")
        return v


class FundWalletResponse(BaseModel):
    message: str
    balance: float
