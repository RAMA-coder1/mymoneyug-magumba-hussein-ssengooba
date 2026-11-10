from fastapi import FastAPI, APIRouter

from routers.auth import router as auth_router
from routers.accounts import router as accounts_router
from routers.categories import router as categories_router
from routers.transactions import router as transactions_router
from routers.dashboard import router as dashboard_router


app = FastAPI(
    title="MyMoneyUG API",
    description="Student Personal Expense Tracking and Finance API",
    version="1.0.0"
)


api_router = APIRouter(prefix="/api/v1")

api_router.include_router(auth_router)
api_router.include_router(accounts_router)
api_router.include_router(categories_router)
api_router.include_router(transactions_router)
api_router.include_router(dashboard_router)

app.include_router(api_router)


@app.get("/")
def home():
    return {
        "message": "Welcome to MyMoneyUG API",
        "status": "running"
    }