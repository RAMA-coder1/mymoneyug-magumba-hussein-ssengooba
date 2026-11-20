from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from decimal import Decimal

from database import get_db
from models import Account, Transaction, User
from schemas.account import (
    AccountCreate,
    AccountResponse,
    AccountBalanceResponse
)
from dependencies import get_current_user


router = APIRouter(
    prefix="/accounts",
    tags=["Accounts"]
)


@router.post(
    "/",
    response_model=AccountResponse,
    status_code=status.HTTP_201_CREATED
)
def create_account(
    account: AccountCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    new_account = Account(
        user_id=current_user.id,
        account_name=account.account_name,
        account_type=account.account_type,
        opening_balance=account.opening_balance
    )

    db.add(new_account)
    db.commit()
    db.refresh(new_account)

    return new_account


@router.get(
    "/",
    response_model=list[AccountResponse]
)
def get_my_accounts(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    accounts = db.query(Account).filter(
        Account.user_id == current_user.id
    ).all()

    return accounts


@router.get(
    "/{account_id}/balance",
    response_model=AccountBalanceResponse
)
def get_account_balance(
    account_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    account = db.query(Account).filter(
        Account.id == account_id,
        Account.user_id == current_user.id
    ).first()

    if account is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Account not found"
        )

    total_income = db.query(
        func.coalesce(func.sum(Transaction.amount), 0)
    ).filter(
        Transaction.account_id == account_id,
        Transaction.user_id == current_user.id,
        Transaction.transaction_type == "income"
    ).scalar()

    total_expenses = db.query(
        func.coalesce(func.sum(Transaction.amount), 0)
    ).filter(
        Transaction.account_id == account_id,
        Transaction.user_id == current_user.id,
        Transaction.transaction_type == "expense"
    ).scalar()

    total_income = Decimal(str(total_income))
    total_expenses = Decimal(str(total_expenses))

    current_balance = (
        account.opening_balance
        + total_income
        - total_expenses
    )

    return {
        "account_id": account.id,
        "account_name": account.account_name,
        "opening_balance": account.opening_balance,
        "total_income": total_income,
        "total_expenses": total_expenses,
        "current_balance": current_balance
    }