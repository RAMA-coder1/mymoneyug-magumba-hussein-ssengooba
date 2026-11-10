from pydantic import BaseModel, Field
from typing import Literal
from datetime import datetime


class CategoryCreate(BaseModel):
    category_name: str = Field(min_length=1, max_length=100)

    category_type: Literal[
        "income",
        "expense"
    ]


class CategoryResponse(BaseModel):
    id: int
    user_id: int
    category_name: str
    category_type: str
    created_at: datetime

    model_config = {"from_attributes": True}