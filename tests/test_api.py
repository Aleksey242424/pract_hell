import secrets
import re
from datetime import datetime, timedelta, timezone

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import text
from jose import jwt

from main import app
from database import SessionLocal
from security import SECRET_KEY, ALGORITHM

# raise_server_exceptions=False нужно, чтобы тесты ловили 500 ошибку, а не падали
client = TestClient(app, raise_server_exceptions=False)

# ==========================================
# ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
# ==========================================

def get_captcha():
    """Создаёт CAPTCHA и возвращает её правильный ответ."""
    response = client.get("/captcha/challenge")
    assert response.status_code == 200
    data = response.json()
    
    # Парсим математический пример из вопроса
    match = re.search(r"Сколько будет (\d+) \+ (\d+)\?", data["question"])
    assert match is not None
    correct_answer = str(int(match.group(1)) + int(match.group(2)))
    
    return data, correct_answer

def create_test_captcha_token():
    """Создаёт валидный токен капчи напрямую в БД для тестов регистрации."""
    token = secrets.token_urlsafe(32)
    db = SessionLocal()
    try:
        db.execute(
            text("INSERT INTO captcha_tokens (token, expires_at, is_used) VALUES (:token, :exp, FALSE)"),
            {"token": token, "exp": datetime.now(timezone.utc) + timedelta(minutes=5)}
        )
        db.commit()
    finally:
        db.close()
    return token

@pytest.fixture
def auth_test_data():
    """Фикстура создаёт уникальный логин и удаляет юзера после теста."""
    login = "test_" + secrets.token_hex(8)
    yield {"login": login}
    
    # Очистка БД после теста
    db = SessionLocal()
    try:
        db.execute(text("DELETE FROM users WHERE login = :login"), {"login": login})
        db.commit()
    finally:
        db.close()

def register_test_user(login, role="Пользователь"):
    """Регистрирует пользователя. (Роль по умолчанию Пользователь, как в API)."""
    token = create_test_captcha_token()
    response = client.post("/auth/register", json={
        "full_name": "Тестовый Пользователь",
        "login": login,
        "password": "TestPassword123!",
        "captcha_token": token
    })
    
    # Если нужен Админ, меняем роль напрямую в БД (т.к. через API регистрируются только юзеры)
    if role == "Администратор" and response.status_code == 200:
        db = SessionLocal()
        try:
            db.execute(text("UPDATE users SET role = 'Администратор' WHERE login = :l"), {"l": login})
            db.commit()
        finally:
            db.close()
            
    return response


# ==========================================
# ТЕСТЫ: СИСТЕМА И КАПЧА
# ==========================================

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

def test_captcha_challenge():
    data, correct_answer = get_captcha()
    assert "challenge_id" in data
    assert "question" in data
    assert len(data["options"]) == 4
    assert correct_answer in data["options"]
    assert data["expires_in_seconds"] == 120

def test_captcha_wrong_answer():
    data, correct_answer = get_captcha()
    wrong_answer = next(opt for opt in data["options"] if opt != correct_answer)
    
    response = client.post("/captcha/verify", json={
        "challenge_id": data["challenge_id"],
        "answer": wrong_answer
    })
    assert response.status_code == 400
    assert "Неправильный ответ" in response.json()["detail"]

def test_captcha_cannot_be_reused():
    data, correct_answer = get_captcha()
    payload = {"challenge_id": data["challenge_id"], "answer": correct_answer}
    
    # Первый раз - успех
    assert client.post("/captcha/verify", json=payload).status_code == 200
    # Второй раз - ошибка
    assert client.post("/captcha/verify", json=payload).status_code == 400


# ==========================================
# ТЕСТЫ: АВТОРИЗАЦИЯ И РЕГИСТРАЦИЯ
# ==========================================

def test_register_success(auth_test_data):
    res = register_test_user(auth_test_data["login"])
    assert res.status_code == 200
    assert res.json()["login"] == auth_test_data["login"]
    assert res.json()["role"] == "Пользователь"
    assert res.json()["is_blocked"] is False

def test_register_duplicate(auth_test_data):
    register_test_user(auth_test_data["login"])
    res = register_test_user(auth_test_data["login"])
    assert res.status_code == 409
    assert "уже существует" in res.json()["detail"]

def test_login_success(auth_test_data):
    register_test_user(auth_test_data["login"])
    res = client.post("/auth/login", json={"login": auth_test_data["login"], "password": "TestPassword123!"})
    assert res.status_code == 200
    assert "access_token" in res.json()
    assert res.json()["token_type"] == "bearer"

def test_login_wrong_password(auth_test_data):
    register_test_user(auth_test_data["login"])
    res = client.post("/auth/login", json={"login": auth_test_data["login"], "password": "WrongPassword!"})
    assert res.status_code == 401
    assert res.json()["detail"] == "Вы ввели неверный логин или пароль. Пожалуйста проверьте ещё раз введенные данные"

def test_login_block_after_three_attempts(auth_test_data):
    register_test_user(auth_test_data["login"])
    payload = {"login": auth_test_data["login"], "password": "WrongPassword!"}
    
    # 1 и 2 попытки - просто ошибка 401
    assert client.post("/auth/login", json=payload).status_code == 401
    assert client.post("/auth/login", json=payload).status_code == 401
    
    # 3 попытка - должна заблокировать (403)
    res3 = client.post("/auth/login", json=payload)
    assert res3.status_code == 403
    assert res3.json()["detail"] == "Вы заблокированы. Обратитесь к администратору"

    # Проверяем, что даже с правильным паролем не пускает
    res_correct = client.post("/auth/login", json={"login": auth_test_data["login"], "password": "TestPassword123!"})
    assert res_correct.status_code == 403
    assert res_correct.json()["detail"] == "Вы заблокированы. Обратитесь к администратору"

def test_get_current_user(auth_test_data):
    register_test_user(auth_test_data["login"])
    login_res = client.post("/auth/login", json={"login": auth_test_data["login"], "password": "TestPassword123!"})
    token = login_res.json()["access_token"]
    
    res = client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 200
    assert res.json()["login"] == auth_test_data["login"]


# ==========================================
# ТЕСТЫ: АДМИН ПАНЕЛЬ (ЗАДАНИЕ 4)
# ==========================================

def test_admin_create_user(auth_test_data):
    # 1. Создаем Админа и логинимся
    admin_login = "admin_" + secrets.token_hex(4)
    register_test_user(admin_login, role="Администратор")
    admin_token = client.post("/auth/login", json={"login": admin_login, "password": "TestPassword123!"}).json()["access_token"]
    
    # 2. Админ создает нового юзера через свой эндпоинт
    new_user_login = "created_" + secrets.token_hex(4)
    res = client.post("/admin/users", 
        headers={"Authorization": f"Bearer {admin_token}"},
        json={
            "full_name": "Созданный Админом",
            "login": new_user_login,
            "password": "NewPassword123!",
            "role": "Пользователь"
        }
    )
    
    assert res.status_code == 200
    assert res.json()["login"] == new_user_login
    
    # Очистка созданного админом юзера
    db = SessionLocal()
    db.execute(text("DELETE FROM users WHERE login IN (:a, :u)"), {"a": admin_login, "u": new_user_login})
    db.commit()
    db.close()

def test_admin_unblock_user(auth_test_data):
    # 1. Создаем юзера, ловим бан
    register_test_user(auth_test_data["login"])
    payload = {"login": auth_test_data["login"], "password": "WrongPassword!"}
    client.post("/auth/login", json=payload) # 1
    client.post("/auth/login", json=payload) # 2
    client.post("/auth/login", json=payload) # 3 (бан)
    
    # 2. Создаем Админа и логинимся
    admin_login = "admin_" + secrets.token_hex(4)
    register_test_user(admin_login, role="Администратор")
    admin_token = client.post("/auth/login", json={"login": admin_login, "password": "TestPassword123!"}).json()["access_token"]
    
    # Получаем ID заблокированного юзера
    db = SessionLocal()
    user_id = db.execute(text("SELECT id_user FROM users WHERE login = :l"), {"l": auth_test_data["login"]}).scalar()
    db.close()

    # 3. Админ снимает блокировку
    res = client.patch(f"/admin/users/{user_id}/unblock", headers={"Authorization": f"Bearer {admin_token}"})
    assert res.status_code == 200
    assert res.json()["is_blocked"] is False

    # 4. Проверяем, что юзер может войти
    res_login = client.post("/auth/login", json={"login": auth_test_data["login"], "password": "TestPassword123!"})
    assert res_login.status_code == 200
    
    # Очистка админа
    db = SessionLocal()
    db.execute(text("DELETE FROM users WHERE login = :a"), {"a": admin_login})
    db.commit()
    db.close()


# ==========================================
# ТЕСТЫ: API ЗАМЕТОК (ЗАДАНИЕ 5)
# ==========================================

def test_get_notes_format():
    """Проверяем, что данные отдаются в нужном формате (title_user, formatted_date)"""
    login = "test_note_" + secrets.token_hex(4)
    register_test_user(login)
    
    # Достаем ID юзера
    db = SessionLocal()
    user_id = db.execute(text("SELECT id_user FROM users WHERE login = :l"), {"l": login}).scalar()
    
    # Создаем заметку
    db.execute(
        text("INSERT INTO notes (title, content, id_user, created_at) VALUES ('Тестовая заметка', 'Контент', :u, '2026-11-03 12:00:00')"),
        {"u": user_id}
    )
    db.commit()
    db.close()

    # Запрашиваем API
    res = client.get("/notes")
    assert res.status_code == 200
    notes = res.json()
    
    # Ищем нашу заметку
    note = next((n for n in notes if n["content"] == "Контент"), None)
    assert note is not None
    
    # ПРОВЕРКА ПО ТЗ: title_user = "Title - login"
    assert note["title_user"] == f"Тестовая заметка - {login}"
    # ПРОВЕРКА ПО ТЗ: formatted_date = "ДД.ММ.ГГГГ"
    assert note["formatted_date"] == "03.11.2026"

    # Чистим за собой
    db = SessionLocal()
    db.execute(text("DELETE FROM users WHERE login = :l"), {"l": login})
    db.commit()
    db.close()

def test_get_notes_empty():
    """Проверка, что если нет заметок, возвращается пустой массив []"""
    # Временно удаляем все заметки (для теста)
    db = SessionLocal()
    db.execute(text("DELETE FROM notes"))
    db.commit()
    db.close()

    res = client.get("/notes")
    assert res.status_code == 200
    assert res.json() == []


# ==========================================
# ТЕСТЫ: ОБРАБОТКА ОШИБОК (HTTP СТАТУСЫ)
# ==========================================

def test_register_validation_error():
    # Отправляем пустой JSON, ждем 400
    response = client.post("/auth/register", json={})
    assert response.status_code == 400
    assert response.json()["detail"] == "Ошибка валидации данных"

def test_get_current_user_invalid_token():
    response = client.get("/auth/me", headers={"Authorization": "Bearer invalid_token"})
    assert response.status_code == 401