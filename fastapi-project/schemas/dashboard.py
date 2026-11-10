from pydantic import BaseModel
from decimal import Decimal


class DashboardSummaryResponse(BaseModel):
    total_income: Decimal
    total_expenses: Decimal
    total_balance: Decimal
    account_count: int
    transaction_count: int


class MonthlySummaryResponse(BaseModel):
    year: int
    month: int
    total_income: Decimal
    total_expenses: Decimal
    net_savings: Decimal
    transaction_count: int