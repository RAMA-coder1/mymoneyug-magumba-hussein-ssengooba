# MyMoneyUG

MyMoneyUG is a personal finance tracking app for students and everyday users. It combines a **FastAPI backend** with a **Flutter frontend** to manage accounts, categories, transactions, and spending summaries.

## Features

- User registration and login with JWT authentication
- Account management (cash, mobile money, bank)
- Income and expense categories
- Transaction tracking with descriptions and dates
- Dashboard summaries and monthly reports
- Responsive Flutter UI for web, desktop, and mobile

## Tech Stack

### Backend

- Python 3.13
- FastAPI
- SQLAlchemy
- SQLite
- Pydantic
- python-jose (JWT)
- passlib (password hashing)
- python-dotenv

### Frontend

- Flutter (Dart)
- Provider (state management)
- http (API client)
- flutter_secure_storage (token storage)
- Lucide icons
- Google Fonts (Inter)

## Project Structure

```text
expenses-app/
├── backend/
│   └── fastapi-project/
│       ├── main.py
│       ├── database.py
│       ├── models/
│       ├── routers/
│       ├── schemas/
│       ├── .env
│       └── seed.py
├── frontend/
│   ├── lib/
│   ├── pubspec.yaml
│   └── web/
├── scripts/
│   ├── run-backend.bat
│   ├── run-frontend.bat
│   └── run-all.bat
└── README.md
```

## Prerequisites

- Python 3.13+
- Flutter SDK 3.47+
- Git

## Backend Setup

```bash
cd backend/fastapi-project
python -m venv .venv
.venv\Scripts\activate
pip install fastapi[standard] python-dotenv sqlalchemy "python-jose[cryptography]" passlib
python seed.py
```

Create or update `backend/fastapi-project/.env`:

```env
DATABASE_URL=sqlite:///./sql_app.db
SECRET_KEY=dev-secret-key-change-in-production-please
```

Run the backend:

```bash
fastapi dev main.py --port 8000
```

The API is available at `http://127.0.0.1:8000`, with docs at `http://127.0.0.1:8000/docs`.

## Frontend Setup

```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port=8080
```

The API base URL defaults to `http://localhost:8000/api/v1` on web/desktop. Override it with:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://192.168.1.50:8000/api/v1
```

## Startup Scripts (Windows)

From the project root:

```bat
scripts\run-backend.bat
scripts\run-frontend.bat
scripts\run-all.bat
```

- `run-backend.bat` starts FastAPI on port 8000.
- `run-frontend.bat` runs the Flutter web app on port 8080.
- `run-all.bat` opens both in separate terminal windows.

## Demo Account

After running `python seed.py`:

- Email: `demo@mymoney.ug`
- Password: `password123`

## API Overview

Base path: `/api/v1`

- `POST /auth/register`
- `POST /auth/login`
- `GET /auth/me`
- `GET/POST /accounts/`
- `GET /accounts/{id}/balance`
- `GET/POST /categories/`
- `GET/POST/PUT/DELETE /transactions/`
- `GET /dashboard/summary`
- `GET /dashboard/monthly-summary`

## Notes

- The backend uses SQLite by default; change `DATABASE_URL` for other databases.
- The frontend avoids port 8000 for its web server because the backend uses it.
- CORS is currently open for local development.

## License

This project is provided for educational and personal use.