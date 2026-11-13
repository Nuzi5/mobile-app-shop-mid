import json
import os
import re
import sqlite3
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

# Запасной список товаров: используется, если каталог с dummyjson недоступен.
FALLBACK_PRODUCTS = [
    {
        "id": 1,
        "title": "Essence Mascara Lash Princess",
        "description": "The Essence Mascara Lash Princess is a popular mascara known for its volumizing and lengthening effects. Achieve dramatic lashes with this long-lasting and cruelty-free formula.",
        "category": "beauty",
        "brand": "Essence",
        "price": 9.99,
        "discountPercentage": 10.48,
        "rating": 2.56,
        "stock": 99,
        "thumbnail": "https://cdn.dummyjson.com/product-images/beauty/essence-mascara-lash-princess/thumbnail.webp",
    },
    {
        "id": 2,
        "title": "Eyeshadow Palette with Mirror",
        "description": "The Eyeshadow Palette with Mirror offers a versatile range of eyeshadow shades for creating stunning eye looks. With a built-in mirror, it's convenient for on-the-go makeup application.",
        "category": "beauty",
        "brand": "Glamour Beauty",
        "price": 19.99,
        "discountPercentage": 18.19,
        "rating": 2.86,
        "stock": 34,
        "thumbnail": "https://cdn.dummyjson.com/product-images/beauty/eyeshadow-palette-with-mirror/thumbnail.webp",
    },
    {
        "id": 3,
        "title": "Powder Canister",
        "description": "The Powder Canister is a finely milled setting powder designed to set makeup and control shine. With a lightweight and translucent formula, it provides a smooth and matte finish.",
        "category": "beauty",
        "brand": "Velvet Touch",
        "price": 14.99,
        "discountPercentage": 9.84,
        "rating": 4.64,
        "stock": 89,
        "thumbnail": "https://cdn.dummyjson.com/product-images/beauty/powder-canister/thumbnail.webp",
    },
    {
        "id": 4,
        "title": "Red Lipstick",
        "description": "The Red Lipstick is a classic and bold choice for adding a pop of color to your lips. With a creamy and pigmented formula, it provides a vibrant and long-lasting finish.",
        "category": "beauty",
        "brand": "Chic Cosmetics",
        "price": 12.99,
        "discountPercentage": 12.16,
        "rating": 4.36,
        "stock": 91,
        "thumbnail": "https://cdn.dummyjson.com/product-images/beauty/red-lipstick/thumbnail.webp",
    },
]

CATALOG_URL = os.environ.get("CATALOG_URL", "https://dummyjson.com/products?limit=4")

PRODUCT_FIELDS = {
    "id": None,
    "title": "",
    "description": "",
    "category": "",
    "brand": "",
    "price": 0.0,
    "discountPercentage": 0.0,
    "rating": 0.0,
    "stock": 0,
    "thumbnail": "",
}


def load_products():
    """Берёт 4 реальных товара с dummyjson (с настоящими картинками).

    Если сети нет или ответ неожиданный, возвращает запасной список.
    """
    try:
        # Сайт отклоняет запросы с заголовком по умолчанию от Python (403), поэтому задаём свой.
        request = urllib.request.Request(
            CATALOG_URL,
            headers={"User-Agent": "Mozilla/5.0 (cart-backend)", "Accept": "application/json"},
        )
        with urllib.request.urlopen(request, timeout=10) as resp:
            raw = json.loads(resp.read().decode("utf-8"))["products"][:4]
        products = []
        for item in raw:
            product = {key: item.get(key, default) for key, default in PRODUCT_FIELDS.items()}
            product["brand"] = product["brand"] or ""
            products.append(product)
        if len(products) == 4:
            print("Каталог загружен с dummyjson")
            return products
    except Exception as exc:  # сеть недоступна или формат ответа другой
        print(f"Каталог не загружен ({exc}), используем запасной список")
    return FALLBACK_PRODUCTS


PRODUCTS = load_products()
PRODUCTS_BY_ID = {p["id"]: p for p in PRODUCTS}


def get_db_path():
    return os.environ.get("DB_PATH", os.path.join("data", "app.db"))


def connect(db_path):
    conn = sqlite3.connect(db_path, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def init_db(conn):
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS cart_items (
            product_id INTEGER PRIMARY KEY,
            quantity   INTEGER NOT NULL CHECK (quantity > 0)
        )
        """
    )
    conn.commit()


def cart_snapshot(conn):
    rows = conn.execute(
        "SELECT product_id, quantity FROM cart_items ORDER BY product_id"
    ).fetchall()
    items = []
    total = 0.0
    for row in rows:
        product = PRODUCTS_BY_ID.get(row["product_id"])
        if product is None:
            continue
        line_total = round(product["price"] * row["quantity"], 2)
        total += line_total
        items.append(
            {
                "productId": product["id"],
                "title": product["title"],
                "price": product["price"],
                "quantity": row["quantity"],
                "lineTotal": line_total,
            }
        )
    return {"items": items, "total": round(total, 2)}


class Handler(BaseHTTPRequestHandler):
    server_version = "CartBackend/1.0"

    # Подключение к БД создаётся один раз на сервер (см. main()).
    conn = None

    def _send_json(self, status, payload):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self._send_cors()
        self.end_headers()
        self.wfile.write(body)

    def _send_cors(self):
        # Нужно для Flutter Web, который работает в браузере на другом порту.
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def _read_json(self):
        length = int(self.headers.get("Content-Length", 0))
        if length == 0:
            return None
        raw = self.rfile.read(length)
        try:
            return json.loads(raw.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError):
            return None

    def do_OPTIONS(self):
        self.send_response(204)
        self._send_cors()
        self.end_headers()

    def do_GET(self):
        if self.path == "/products":
            return self._send_json(200, {"products": PRODUCTS})
        if self.path == "/cart":
            return self._send_json(200, cart_snapshot(self.conn))
        return self._send_json(404, {"error": "not found"})

    def do_POST(self):
        if self.path != "/cart/items":
            return self._send_json(404, {"error": "not found"})

        data = self._read_json()
        product_id = data.get("product_id") if isinstance(data, dict) else None
        if not isinstance(product_id, int) or isinstance(product_id, bool):
            return self._send_json(400, {"error": "product_id must be an integer"})
        if product_id not in PRODUCTS_BY_ID:
            return self._send_json(404, {"error": "product not found"})

        self.conn.execute(
            """
            INSERT INTO cart_items (product_id, quantity) VALUES (?, 1)
            ON CONFLICT(product_id) DO UPDATE SET quantity = quantity + 1
            """,
            (product_id,),
        )
        self.conn.commit()
        return self._send_json(201, cart_snapshot(self.conn))

    def do_DELETE(self):
        match = re.fullmatch(r"/cart/items/(\d+)", self.path)
        if not match:
            return self._send_json(404, {"error": "not found"})

        product_id = int(match.group(1))
        cur = self.conn.execute(
            "DELETE FROM cart_items WHERE product_id = ?", (product_id,)
        )
        self.conn.commit()
        if cur.rowcount == 0:
            return self._send_json(404, {"error": "item not in cart"})
        return self._send_json(200, cart_snapshot(self.conn))

    def log_message(self, fmt, *args):
        print("%s - %s" % (self.address_string(), fmt % args))


def make_server(port, db_path):
    directory = os.path.dirname(db_path)
    if directory:
        os.makedirs(directory, exist_ok=True)
    conn = connect(db_path)
    init_db(conn)
    handler = type("BoundHandler", (Handler,), {"conn": conn})
    return ThreadingHTTPServer(("0.0.0.0", port), handler)


def main():
    port = int(os.environ.get("PORT", "8000"))
    db_path = get_db_path()
    server = make_server(port, db_path)
    print(f"Backend listening on :{port}, database: {db_path}")
    server.serve_forever()


if __name__ == "__main__":
    main()