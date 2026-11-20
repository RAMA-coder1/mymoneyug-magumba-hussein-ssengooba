
from sqlalchemy import (
    Column, Integer, String, Numeric, Date, DateTime,
    ForeignKey, Enum, CheckConstraint
)
from sqlalchemy.sql import func
from database import Base


class Transaction(Base):
    __tablename__ = "transactions"

    __table_args__ = (
        CheckConstraint("amount > 0", name="chk_transaction_amount"),
    )

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    account_id = Column(Integer, ForeignKey("accounts.id"), nullable=False)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=False)
    transaction_type = Column(
        Enum("income", "expense"),
        nullable=False
    )
    amount = Column(Numeric(12, 2), nullable=False)
    description = Column(String(255), nullable=True)
    transaction_date = Column(Date, nullable=False)
    created_at = Column(DateTime, server_default=func.current_timestamp())
