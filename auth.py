from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from sqlalchemy import text

from database import get_db
from schemas import RegisterRequest, LoginRequest, TokenResponse, UserResponse
from security import hash_password, verify_password, create_access_token, decode_access_token

router = APIRouter(prefix="/auth", tags=["Авторизация"])
bearer_scheme = HTTPBearer()

@router.post("/register", response_model=UserResponse)
def register(data: RegisterRequest, db: Session = Depends(get_db)):
    try:
        # Проверка на существование
        existing = db.execute(text("SELECT id_user FROM users WHERE login = :login"), {"login": data.login}).first()
        if existing:
            raise HTTPException(status_code=409, detail="Пользователь с таким логином уже существует")

        # Проверка капчи
        captcha = db.execute(
            text("UPDATE captcha_tokens SET is_used = TRUE WHERE token = :token AND is_used = FALSE AND expires_at > NOW() RETURNING token"),
            {"token": data.captcha_token}
        ).first()
        if not captcha:
            raise HTTPException(status_code=400, detail="CAPTCHA не пройдена или срок действия токена истёк")

        hashed = hash_password(data.password)
        result = db.execute(
            text("""
                INSERT INTO users (full_name, login, password_hash, role, is_blocked, failed_attempts)
                VALUES (:full_name, :login, :password_hash, 'Пользователь', FALSE, 0)
                RETURNING id_user, full_name, login, role, is_blocked
            """),
            {"full_name": data.full_name, "login": data.login, "password_hash": hashed}
        )
        user = result.mappings().one()
        db.commit()
        return dict(user)
    except HTTPException:
        db.rollback()
        raise
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="Пользователь с таким логином уже существует")
    except Exception:
        db.rollback()
        raise

@router.post("/login", response_model=TokenResponse)
def login(data: LoginRequest, db: Session = Depends(get_db)):
    user = db.execute(
        text("SELECT id_user, password_hash, role, is_blocked, failed_attempts FROM users WHERE login = :login"),
        {"login": data.login}
    ).mappings().first()

    if not user:
        raise HTTPException(status_code=401, detail="Вы ввели неверный логин или пароль. Пожалуйста проверьте ещё раз введенные данные")
    
    if user["is_blocked"]:
        raise HTTPException(status_code=403, detail="Вы заблокированы. Обратитесь к администратору")

    if not verify_password(data.password, user["password_hash"]):
        # Увеличиваем счетчик попыток
        new_attempts = user["failed_attempts"] + 1
        is_blocked = new_attempts >= 3

        db.execute(
            text("UPDATE users SET failed_attempts = :attempts, is_blocked = :blocked WHERE id_user = :id"),
            {"attempts": new_attempts, "blocked": is_blocked, "id": user["id_user"]}
        )
        db.commit()

        if is_blocked:
            raise HTTPException(status_code=403, detail="Вы заблокированы. Обратитесь к администратору")
        
        raise HTTPException(status_code=401, detail="Вы ввели неверный логин или пароль. Пожалуйста проверьте ещё раз введенные данные")

    # Успешный вход - сбрасываем попытки
    db.execute(text("UPDATE users SET failed_attempts = 0 WHERE id_user = :id"), {"id": user["id_user"]})
    db.commit()

    token = create_access_token(user_id=user["id_user"], role=user["role"])
    return {"access_token": token, "token_type": "bearer"}

# Зависимость для получения текущего пользователя
def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme), db: Session = Depends(get_db)):
    payload = decode_access_token(credentials.credentials)
    if not payload or not payload.get("sub"):
        raise HTTPException(status_code=401, detail="Недействительный или просроченный токен")
    
    user_id = int(payload["sub"])
    user = db.execute(
        text("SELECT id_user, full_name, login, role, is_blocked FROM users WHERE id_user = :id"),
        {"id": user_id}
    ).mappings().first()

    if not user or user["is_blocked"]:
        raise HTTPException(status_code=401, detail="Пользователь не найден или заблокирован")
    
    return dict(user)

@router.get("/me", response_model=UserResponse)
def get_me(current_user = Depends(get_current_user)):
    return current_user