import secrets
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session

from database import get_db
from schemas import CaptchaChallengeResponse, CaptchaVerifyRequest, CaptchaVerifyResponse

router = APIRouter(prefix="/captcha", tags=["CAPTCHA"])

# Генерация пазла 3x3 (9 фрагментов)
def generate_puzzle():
    # Правильный порядок всегда 0,1,2,3,4,5,6,7,8
    correct_order = "0,1,2,3,4,5,6,7,8"
    
    # Создаем список [0, 1, ..., 8] и перемешиваем его
    pieces = list(range(9))
    secrets.SystemRandom().shuffle(pieces)
    
    # Защита от случайного совпадения (чтобы не выдать уже собранный пазл)
    if ",".join(map(str, pieces)) == correct_order:
        pieces[0], pieces[1] = pieces[1], pieces[0]
        
    return pieces, correct_order

@router.get("/challenge", response_model=CaptchaChallengeResponse)
def create_challenge(db: Session = Depends(get_db)):
    challenge_id = secrets.token_urlsafe(32)
    
    # Получаем перемешанные кусочки и правильный ответ
    pieces, correct_order = generate_puzzle()
    
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=2)

    db.execute(
        text("""
            INSERT INTO captcha_challenges (challenge_id, correct_answer, expires_at)
            VALUES (:challenge_id, :answer, :expires_at)
        """),
        {"challenge_id": challenge_id, "answer": correct_order, "expires_at": expires_at}
    )
    db.commit()

    # Возвращаем клиенту данные для отрисовки пазла
    return {
        "challenge_id": challenge_id,
        "image_url": "https://picsum.photos/300/300", # Ссылка на рандомную картинку-заглушку
        "pieces": pieces,
        "expires_in_seconds": 120
    }

@router.post("/verify", response_model=CaptchaVerifyResponse)
def verify_captcha(data: CaptchaVerifyRequest, db: Session = Depends(get_db)):
    challenge = db.execute(
        text("SELECT correct_answer, expires_at, is_used FROM captcha_challenges WHERE challenge_id = :id"),
        {"id": data.challenge_id}
    ).mappings().first()

    if not challenge:
        raise HTTPException(status_code=404, detail="CAPTCHA не найдена")
    if challenge["is_used"]:
        raise HTTPException(status_code=400, detail="CAPTCHA уже использована")
    if challenge["expires_at"] <= datetime.now(timezone.utc):
        db.execute(text("UPDATE captcha_challenges SET is_used = TRUE WHERE challenge_id = :id"), {"id": data.challenge_id})
        db.commit()
        raise HTTPException(status_code=400, detail="Время действия CAPTCHA истекло")

    # Сравниваем порядок, который собрал юзер, с правильным
    if data.user_order.strip() != challenge["correct_answer"]:
        db.execute(text("UPDATE captcha_challenges SET is_used = TRUE WHERE challenge_id = :id"), {"id": data.challenge_id})
        db.commit()
        raise HTTPException(status_code=400, detail="Пазл собран неверно. Попробуйте еще раз")

    # Успех
    db.execute(text("UPDATE captcha_challenges SET is_used = TRUE WHERE challenge_id = :id"), {"id": data.challenge_id})
    captcha_token = secrets.token_urlsafe(32)
    db.execute(
        text("INSERT INTO captcha_tokens (token, expires_at) VALUES (:token, :expires_at)"),
        {"token": captcha_token, "expires_at": datetime.now(timezone.utc) + timedelta(minutes=5)}
    )
    db.commit()

    return {"success": True, "captcha_token": captcha_token}