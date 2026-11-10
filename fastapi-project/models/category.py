
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Enum
from sqlalchemy.sql import func
from database import Base


class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    category_name = Column(String(100), nullable=False)
    category_type = Column(
        Enum("income", "expense"),
        nullable=False
    )
    created_at = Column(DateTime, server_default=func.current_timestamp())
