from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from database import get_db
from models import Category, User
from schemas.category import CategoryCreate, CategoryResponse
from dependencies import get_current_user


router = APIRouter(
    prefix="/categories",
    tags=["Categories"]
)


@router.post(
    "/",
    response_model=CategoryResponse,
    status_code=status.HTTP_201_CREATED
)
def create_category(
    category: CategoryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    new_category = Category(
        user_id=current_user.id,
        category_name=category.category_name,
        category_type=category.category_type
    )

    db.add(new_category)
    db.commit()
    db.refresh(new_category)

    return new_category


@router.get(
    "/",
    response_model=list[CategoryResponse]
)
def get_my_categories(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    categories = db.query(Category).filter(
        Category.user_id == current_user.id
    ).all()

    return categories