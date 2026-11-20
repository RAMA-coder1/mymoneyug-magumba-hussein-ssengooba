
from sqlalchemy import Column, Integer, String, Numeric, DateTime, ForeignKey, Enum
from sqlalchemy.sql import func
from database import Base


class Account(Base):
    __tablename__ = "accounts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    account_name = Column(String(100), nullable=False)
    account_type = Column(
        Enum("cash", "mobile_money", "bank"),
        nullable=False
    )
    opening_balance = Column(Numeric(12, 2), nullable=False, default=0.00)
    created_at = Column(DateTime, server_default=func.current_timestamp())
