from pydantic import BaseModel, Field
from typing import Literal
from decimal import Decimal
from datetime import date, datetime


class TransactionCreate(BaseModel):
    account_id: int
    category_id: int

    transaction_type: Literal[
        "income",
        "expense"
    ]

    amount: Decimal = Field(
        gt=0,
        max_digits=12,
        decimal_places=2
    )

    description: str | None = Field(
        default=None,
        max_length=255
    )

    transaction_date: date


class TransactionUpdate(BaseModel):
    account_id: int
    category_id: int

    transaction_type: Literal[
        "income",
        "expense"
    ]

    amount: Decimal = Field(
        gt=0,
        max_digits=12,
        decimal_places=2
    )

    description: str | None = Field(
        default=None,
        max_length=255
    )

    transaction_date: date


class TransactionResponse(BaseModel):
    id: int
    user_id: int
    account_id: int
    category_id: int
    transaction_type: str
    amount: Decimal
    description: str | None
    transaction_date: date
    created_at: datetime

    model_config = {"from_attributes": True}