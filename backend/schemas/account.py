from pydantic import BaseModel, Field
from typing import Literal
from decimal import Decimal
from datetime import datetime


class AccountCreate(BaseModel):
    account_name: str = Field(min_length=1, max_length=100)

    account_type: Literal[
        "cash",
        "mobile_money",
        "bank"
    ]

    opening_balance: Decimal = Field(
        default=Decimal("0.00"),
        ge=0,
        max_digits=12,
        decimal_places=2
    )


class AccountResponse(BaseModel):
    id: int
    user_id: int
    account_name: str
    account_type: str
    opening_balance: Decimal
    created_at: datetime

    model_config = {"from_attributes": True}


class AccountBalanceResponse(BaseModel):
    account_id: int
    account_name: str
    opening_balance: Decimal
    total_income: Decimal
    total_expenses: Decimal
    current_balance: Decimal