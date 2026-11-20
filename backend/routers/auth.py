
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from database import get_db
from models import User
from schemas.auth import UserCreate, UserLogin, UserResponse, Token
from security import hash_password, verify_password, create_access_token
from dependencies import get_current_user
router = APIRouter(
    prefix="/auth",
    tags=["Authentication"]
)


@router.post("/register", response_model=UserResponse,
             status_code=status.HTTP_201_CREATED)
def register_user(user: UserCreate, db: Session = Depends(get_db)):

    existing_user = db.query(User).filter(
        User.email == user.email
    ).first()

    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="Email is already registered"
        )

    new_user = User(
        name=user.name,
        email=user.email,
        password_hash=hash_password(user.password)
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return new_user


@router.post("/login", response_model=Token)
def login_user(user: UserLogin, db: Session = Depends(get_db)):

    existing_user = db.query(User).filter(
        User.email == user.email
    ).first()

    if not existing_user or not verify_password(
        user.password, existing_user.password_hash
    ):
        raise HTTPException(
            status_code=401,
            detail="Incorrect email or password"
        )

    access_token = create_access_token(
        data={"sub": str(existing_user.id)}
    )

    return {
        "access_token": access_token,
        "token_type": "bearer"
    }
@router.get("/me", response_model=UserResponse)
def read_current_user(
    current_user: User = Depends(get_current_user)
):
    return current_user