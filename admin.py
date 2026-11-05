from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text

from database import get_db
from auth import get_current_user
from schemas import AdminCreateUserRequest, UserResponse
from security import hash_password

router = APIRouter(prefix="/admin", tags=["Панель Администратора"])

# Проверка, что зашел именно админ
def check_admin(current_user = Depends(get_current_user)):
    if current_user["role"] != "Администратор":
        raise HTTPException(status_code=403, detail="Доступ запрещен. Требуются права Администратора")
    return current_user

@router.get("/users", response_model=list[UserResponse])
def get_all_users(db: Session = Depends(get_db), admin = Depends(check_admin)):
    users = db.execute(text("SELECT id_user, full_name, login, role, is_blocked FROM users ORDER BY id_user")).mappings().all()
    return [dict(u) for u in users]

@router.post("/users", response_model=UserResponse)
def create_user(data: AdminCreateUserRequest, db: Session = Depends(get_db), admin = Depends(check_admin)):
    existing = db.execute(text("SELECT id_user FROM users WHERE login = :login"), {"login": data.login}).first()
    if existing:
        raise HTTPException(status_code=409, detail="Пользователь с таким логином уже существует")
    
    hashed = hash_password(data.password)
    result = db.execute(
        text("""
            INSERT INTO users (full_name, login, password_hash, role, is_blocked, failed_attempts)
            VALUES (:full_name, :login, :password_hash, :role, FALSE, 0)
            RETURNING id_user, full_name, login, role, is_blocked
        """),
        {"full_name": data.full_name, "login": data.login, "password_hash": hashed, "role": data.role}
    )
    db.commit()
    return dict(result.mappings().one())

@router.patch("/users/{user_id}/unblock", response_model=UserResponse)
def unblock_user(user_id: int, db: Session = Depends(get_db), admin = Depends(check_admin)):
    # Снимаем блокировку и сбрасываем счетчик
    result = db.execute(
        text("""
            UPDATE users 
            SET is_blocked = FALSE, failed_attempts = 0 
            WHERE id_user = :id
            RETURNING id_user, full_name, login, role, is_blocked
        """),
        {"id": user_id}
    )
    db.commit()
    user = result.mappings().first()
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")
    return dict(user)