from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from decimal import Decimal
from datetime import date

from database import get_db
from models import Account, Transaction, User
from schemas.dashboard import (
    DashboardSummaryResponse,
    MonthlySummaryResponse
)
from dependencies import get_current_user


router = APIRouter(
    prefix="/dashboard",
    tags=["Dashboard"]
)


@router.get(
    "/summary",
    response_model=DashboardSummaryResponse
)
def get_dashboard_summary(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    total_income = db.query(
        func.coalesce(func.sum(Transaction.amount), 0)
    ).filter(
        Transaction.user_id == current_user.id,
        Transaction.transaction_type == "income"
    ).scalar()

    total_expenses = db.query(
        func.coalesce(func.sum(Transaction.amount), 0)
    ).filter(
        Transaction.user_id == current_user.id,
        Transaction.transaction_type == "expense"
    ).scalar()

    accounts = db.query(Account).filter(
        Account.user_id == current_user.id
    ).all()

    total_balance = Decimal("0.00")

    for account in accounts:
        account_income = db.query(
            func.coalesce(func.sum(Transaction.amount), 0)
        ).filter(
            Transaction.account_id == account.id,
            Transaction.user_id == current_user.id,
            Transaction.transaction_type == "income"
        ).scalar()

        account_expenses = db.query(
            func.coalesce(func.sum(Transaction.amount), 0)
        ).filter(
            Transaction.account_id == account.id,
            Transaction.user_id == current_user.id,
            Transaction.transaction_type == "expense"
        ).scalar()

        total_balance += (
            account.opening_balance
            + Decimal(str(account_income))
            - Decimal(str(account_expenses))
        )

    transaction_count = db.query(
        func.count(Transaction.id)
    ).filter(
        Transaction.user_id == current_user.id
    ).scalar()

    return {
        "total_income": Decimal(str(total_income)),
        "total_expenses": Decimal(str(total_expenses)),
        "total_balance": total_balance,
        "account_count": len(accounts),
        "transaction_count": transaction_count
    }


@router.get(
    "/monthly-summary",
    response_model=MonthlySummaryResponse
)
def get_monthly_summary(
    year: int,
    month: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if month < 1 or month > 12:
        raise HTTPException(
            status_code=400,
            detail="Month must be between 1 and 12"
        )

    if year < 2000 or year > 2100:
        raise HTTPException(
            status_code=400,
            detail="Invalid year"
        )

    start_date = date(year, month, 1)

    if month == 12:
        end_date = date(year + 1, 1, 1)
    else:
        end_date = date(year, month + 1, 1)

    total_income = db.query(
        func.coalesce(func.sum(Transaction.amount), 0)
    ).filter(
        Transaction.user_id == current_user.id,
        Transaction.transaction_type == "income",
        Transaction.transaction_date >= start_date,
        Transaction.transaction_date < end_date
    ).scalar()

    total_expenses = db.query(
        func.coalesce(func.sum(Transaction.amount), 0)
    ).filter(
        Transaction.user_id == current_user.id,
        Transaction.transaction_type == "expense",
        Transaction.transaction_date >= start_date,
        Transaction.transaction_date < end_date
    ).scalar()

    transaction_count = db.query(
        func.count(Transaction.id)
    ).filter(
        Transaction.user_id == current_user.id,
        Transaction.transaction_date >= start_date,
        Transaction.transaction_date < end_date
    ).scalar()

    total_income = Decimal(str(total_income))
    total_expenses = Decimal(str(total_expenses))

    return {
        "year": year,
        "month": month,
        "total_income": total_income,
        "total_expenses": total_expenses,
        "net_savings": total_income - total_expenses,
        "transaction_count": transaction_count
    }