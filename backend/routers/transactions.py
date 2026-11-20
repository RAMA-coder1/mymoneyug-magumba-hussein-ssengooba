from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session

from database import get_db
from models import Transaction, Account, Category, User
from schemas.transaction import (
    TransactionCreate,
    TransactionUpdate,
    TransactionResponse
)
from dependencies import get_current_user


router = APIRouter(
    prefix="/transactions",
    tags=["Transactions"]
)


@router.post(
    "/",
    response_model=TransactionResponse,
    status_code=status.HTTP_201_CREATED
)
def create_transaction(
    transaction: TransactionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    account = db.query(Account).filter(
        Account.id == transaction.account_id,
        Account.user_id == current_user.id
    ).first()

    if account is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Account not found"
        )

    category = db.query(Category).filter(
        Category.id == transaction.category_id,
        Category.user_id == current_user.id
    ).first()

    if category is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Category not found"
        )

    if category.category_type != transaction.transaction_type:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Transaction type must match category type"
        )

    new_transaction = Transaction(
        user_id=current_user.id,
        account_id=transaction.account_id,
        category_id=transaction.category_id,
        transaction_type=transaction.transaction_type,
        amount=transaction.amount,
        description=transaction.description,
        transaction_date=transaction.transaction_date
    )

    db.add(new_transaction)
    db.commit()
    db.refresh(new_transaction)

    return new_transaction


@router.get(
    "/",
    response_model=list[TransactionResponse]
)
def get_my_transactions(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    transactions = db.query(Transaction).filter(
        Transaction.user_id == current_user.id
    ).all()

    return transactions


@router.get(
    "/{transaction_id}",
    response_model=TransactionResponse
)
def get_transaction(
    transaction_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    transaction = db.query(Transaction).filter(
        Transaction.id == transaction_id,
        Transaction.user_id == current_user.id
    ).first()

    if transaction is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transaction not found"
        )

    return transaction
@router.put(
    "/{transaction_id}",
    response_model=TransactionResponse
)
def update_transaction(
    transaction_id: int,
    transaction: TransactionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    existing_transaction = db.query(Transaction).filter(
        Transaction.id == transaction_id,
        Transaction.user_id == current_user.id
    ).first()

    if existing_transaction is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transaction not found"
        )

    account = db.query(Account).filter(
        Account.id == transaction.account_id,
        Account.user_id == current_user.id
    ).first()

    if account is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Account not found"
        )

    category = db.query(Category).filter(
        Category.id == transaction.category_id,
        Category.user_id == current_user.id
    ).first()

    if category is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Category not found"
        )

    if category.category_type != transaction.transaction_type:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Transaction type must match category type"
        )

    existing_transaction.account_id = transaction.account_id
    existing_transaction.category_id = transaction.category_id
    existing_transaction.transaction_type = transaction.transaction_type
    existing_transaction.amount = transaction.amount
    existing_transaction.description = transaction.description
    existing_transaction.transaction_date = transaction.transaction_date

    db.commit()
    db.refresh(existing_transaction)

    return existing_transaction

@router.delete(
    "/{transaction_id}",
    status_code=status.HTTP_204_NO_CONTENT
)
def delete_transaction(
    transaction_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    transaction = db.query(Transaction).filter(
        Transaction.id == transaction_id,
        Transaction.user_id == current_user.id
    ).first()

    if transaction is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transaction not found"
        )

    db.delete(transaction)
    db.commit()

    return None