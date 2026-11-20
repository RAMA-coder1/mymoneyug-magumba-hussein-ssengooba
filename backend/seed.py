import os
from datetime import date

from database import Base, engine, SessionLocal
from models import User, Account, Category, Transaction
from security import hash_password

Base.metadata.create_all(bind=engine)

db = SessionLocal()

user = db.query(User).filter(User.email == "demo@mymoney.ug").first()
if user is None:
    user = User(name="Demo User", email="demo@mymoney.ug", password_hash=hash_password("password123"))
    db.add(user)
    db.commit()
    db.refresh(user)

accounts = db.query(Account).filter(Account.user_id == user.id).all()
if not accounts:
    accounts = [
        Account(user_id=user.id, account_name="Cash", account_type="cash", opening_balance=50000),
        Account(user_id=user.id, account_name="MTN MoMo", account_type="mobile_money", opening_balance=20000),
        Account(user_id=user.id, account_name="Bank", account_type="bank", opening_balance=100000),
    ]
    db.add_all(accounts)
    db.commit()
    for a in accounts:
        db.refresh(a)

categories = db.query(Category).filter(Category.user_id == user.id).all()
if not categories:
    categories = [
        Category(user_id=user.id, category_name="Food", category_type="expense"),
        Category(user_id=user.id, category_name="Transport", category_type="expense"),
        Category(user_id=user.id, category_name="Salary", category_type="income"),
    ]
    db.add_all(categories)
    db.commit()
    for c in categories:
        db.refresh(c)

expense_cat = next(c for c in categories if c.category_type == "expense")
income_cat = next(c for c in categories if c.category_type == "income")
cash = accounts[0]

txns = db.query(Transaction).filter(Transaction.user_id == user.id).all()
if not txns:
    db.add_all([
        Transaction(user_id=user.id, account_id=cash.id, category_id=income_cat.id,
                    transaction_type="income", amount=300000, description="Monthly salary",
                    transaction_date=date.today()),
        Transaction(user_id=user.id, account_id=cash.id, category_id=expense_cat.id,
                    transaction_type="expense", amount=15000, description="Lunch",
                    transaction_date=date.today()),
    ])
    db.commit()

db.close()
print("Seeded demo user: demo@mymoney.ug / password123")
