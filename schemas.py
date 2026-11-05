from pydantic import BaseModel, Field, ConfigDict

# --- AUTH SCHEMAS ---
class RegisterRequest(BaseModel):
    full_name: str = Field(min_length=2, max_length=255)
    login: str = Field(min_length=3, max_length=100)
    password: str = Field(min_length=8, max_length=128)
    captcha_token: str = Field(min_length=20)

class LoginRequest(BaseModel):
    login: str = Field(min_length=3, max_length=100)
    password: str = Field(min_length=1, max_length=128)

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

class UserResponse(BaseModel):
    id_user: int
    full_name: str
    login: str
    role: str
    is_blocked: bool = False

# --- CAPTCHA SCHEMAS ---
class CaptchaChallengeResponse(BaseModel):
    challenge_id: str
    image_url: str          # Ссылка на картинку
    pieces: list[int]       # Перемешанные кусочки (от 0 до 8)
    expires_in_seconds: int

class CaptchaVerifyRequest(BaseModel):
    challenge_id: str
    user_order: str         # Порядок, в котором юзер собрал пазл (например "0,1,2,3,4,5,6,7,8")

class CaptchaVerifyResponse(BaseModel):
    success: bool
    captcha_token: str

# --- NOTES SCHEMAS (Task 5) ---
class NoteResponse(BaseModel):
    id: int
    title_user: str
    content: str
    formatted_date: str

    model_config = ConfigDict(from_attributes=True)

# --- ADMIN SCHEMAS (Task 4) ---
class AdminCreateUserRequest(BaseModel):
    full_name: str = Field(min_length=2, max_length=255)
    login: str = Field(min_length=3, max_length=100)
    password: str = Field(min_length=8, max_length=128)
    role: str = Field(pattern="^(Администратор|Пользователь)$")