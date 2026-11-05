from fastapi import FastAPI, Request, Depends
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from database import get_db
from auth import router as auth_router
from captcha import router as captcha_router
from admin import router as admin_router
from schemas import NoteResponse

app = FastAPI(
    title="Production API",
    description="API системы управления производством (Учебная практика)",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Разрешаем запросы отовсюду
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Подключаем все роутеры
app.include_router(auth_router)
app.include_router(captcha_router)
app.include_router(admin_router)

# --- ОБРАБОТЧИКИ ОШИБОК (по ТЗ) ---

# 400 Bad Request
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=400,
        content={"detail": "Ошибка валидации данных", "errors": exc.errors()}
    )

# 500 Internal Server Error
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content={"error": "Внутренняя ошибка сервера. Обратитесь к администратору."}
    )

@app.get("/health", tags=["Системные"])
def health():
    return {"status": "ok"}

# --- ЗАДАНИЕ 5: Интеграция модулей (API) ---
@app.get("/notes", response_model=list[NoteResponse], tags=["Заметки"])
def get_notes(db=Depends(get_db)):
    """
    Возвращает список заметок с преобразованными данными (title_user, formatted_date).
    """
    query = text("""
        SELECT 
            n.id,
            n.title,
            n.content,
            n.created_at,
            u.login
        FROM notes n
        JOIN users u ON n.id_user = u.id_user
        ORDER BY n.created_at DESC
    """)
    
    result = db.execute(query).mappings().all()
    
    # Если данных нет - FastAPI вернет пустой массив [], что соответствует ТЗ
    return [
        {
            "id": row["id"],
            "title_user": f'{row["title"]} - {row["login"]}',
            "content": row["content"],
            "formatted_date": row["created_at"].strftime("%d.%m.%Y")
        }
        for row in result
    ]

# --- ДОПОЛНИТЕЛЬНЫЕ ЭНДПОИНТЫ ДЛЯ ФРОНТЕНДА ---

@app.get("/counterparties", tags=["Справочники"])
def get_counterparties(db=Depends(get_db)):
    """Возвращает список всех заказчиков"""
    res = db.execute(text("SELECT * FROM counterparties ORDER BY name")).mappings().all()
    return [dict(r) for r in res]

@app.get("/products", tags=["Справочники"])
def get_products(db=Depends(get_db)):
    """Возвращает список продукции"""
    res = db.execute(text("SELECT * FROM products ORDER BY name")).mappings().all()
    return [dict(r) for r in res]

@app.get("/orders", tags=["Заказы"])
def get_orders(db=Depends(get_db)):
    """Возвращает заказы с посчитанной итоговой суммой"""
    query = """
        SELECT 
            co.id_order, 
            co.order_number, 
            co.order_date, 
            co.status, 
            c.name as customer_name, 
            COALESCE(SUM(coi.quantity * coi.unit_price * (1 - coi.discount_percent/100)), 0) as total_sum
        FROM customer_orders co
        JOIN counterparties c ON co.id_customer = c.id_counterparty
        LEFT JOIN customer_order_items coi ON co.id_order = coi.id_order
        GROUP BY co.id_order, co.order_number, co.order_date, co.status, c.name
        ORDER BY co.order_date DESC
    """
    res = db.execute(text(query)).mappings().all()
    return [dict(r) for r in res]


# --- ДОПОЛНИТЕЛЬНЫЕ ЭНДПОИНТЫ ДЛЯ ОСТАЛЬНЫХ ТАБЛИЦ ---

@app.get("/resources", tags=["Справочники"])
def get_resources(db=Depends(get_db)):
    """Материалы и технологические операции"""
    query = """
        SELECT r.id_resource, r.code, r.name, r.resource_kind, r.unit_price, u.metric_unit
        FROM resources r
        JOIN units u ON r.id_unit = u.id_unit
        ORDER BY r.resource_kind, r.name
    """
    res = db.execute(text(query)).mappings().all()
    return [dict(r) for r in res]

@app.get("/production-orders", tags=["Производство"])
def get_production_orders(db=Depends(get_db)):
    """Заказы на производство продукции"""
    query = """
        SELECT 
            po.id_production_order, 
            po.order_number, 
            po.launch_date, 
            po.department,
            p.name as product_name,
            poi.quantity
        FROM production_orders po
        LEFT JOIN production_order_items poi ON po.id_production_order = poi.id_production_order
        LEFT JOIN products p ON poi.id_product = p.id_product
        ORDER BY po.launch_date DESC
    """
    res = db.execute(text(query)).mappings().all()
    return [dict(r) for r in res]

@app.get("/specifications", tags=["Производство"])
def get_specifications(db=Depends(get_db)):
    """Спецификации продукции (состав)"""
    query = """
        SELECT 
            s.id_specification,
            p.name as product_name,
            r.name as resource_name,
            si.norm_quantity,
            u.metric_unit,
            r.unit_price,
            (si.norm_quantity * r.unit_price) as cost
        FROM specifications s
        JOIN products p ON s.id_product = p.id_product
        JOIN specification_items si ON s.id_specification = si.id_specification
        JOIN resources r ON si.id_resource = r.id_resource
        JOIN units u ON r.id_unit = u.id_unit
        ORDER BY p.name, r.name
    """
    res = db.execute(text(query)).mappings().all()
    return [dict(r) for r in res]