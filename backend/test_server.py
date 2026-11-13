"""Тесты бэкенда. Запуск: python -m unittest -v test_server.py"""

import json
import os
import tempfile
import threading
import unittest
import urllib.error
import urllib.request

import server


class CartApiTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmpdir = tempfile.mkdtemp()
        db_path = os.path.join(cls.tmpdir, "test.db")
        cls.httpd = server.make_server(0, db_path)  # порт 0 = свободный порт
        cls.port = cls.httpd.server_address[1]
        cls.thread = threading.Thread(target=cls.httpd.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.httpd.shutdown()
        cls.httpd.server_close()

    def setUp(self):
        # Очищаем корзину перед каждым тестом.
        self.httpd.RequestHandlerClass.conn.execute("DELETE FROM cart_items")
        self.httpd.RequestHandlerClass.conn.commit()

    def request(self, method, path, body=None):
        url = f"http://127.0.0.1:{self.port}{path}"
        data = json.dumps(body).encode("utf-8") if body is not None else None
        req = urllib.request.Request(url, data=data, method=method)
        if data is not None:
            req.add_header("Content-Type", "application/json")
        try:
            with urllib.request.urlopen(req) as resp:
                return resp.status, json.loads(resp.read().decode("utf-8") or "null")
        except urllib.error.HTTPError as err:
            return err.code, json.loads(err.read().decode("utf-8") or "null")

    def test_products_returns_four_items(self):
        status, body = self.request("GET", "/products")
        self.assertEqual(status, 200)
        self.assertEqual(len(body["products"]), 4)
        self.assertEqual({p["id"] for p in body["products"]}, {1, 2, 3, 4})

    def test_cart_empty_at_start(self):
        status, body = self.request("GET", "/cart")
        self.assertEqual(status, 200)
        self.assertEqual(body, {"items": [], "total": 0.0})

    def test_add_item_and_increment(self):
        status, body = self.request("POST", "/cart/items", {"product_id": 4})
        self.assertEqual(status, 201)
        self.assertEqual(body["items"][0]["quantity"], 1)

        status, body = self.request("POST", "/cart/items", {"product_id": 4})
        self.assertEqual(status, 201)
        self.assertEqual(body["items"][0]["quantity"], 2)
        price = server.PRODUCTS_BY_ID[4]["price"]
        self.assertEqual(body["total"], round(price * 2, 2))

    def test_delete_item(self):
        self.request("POST", "/cart/items", {"product_id": 1})
        self.request("POST", "/cart/items", {"product_id": 2})

        status, body = self.request("DELETE", "/cart/items/1")
        self.assertEqual(status, 200)
        self.assertEqual([i["productId"] for i in body["items"]], [2])

    def test_delete_missing_item_returns_404(self):
        status, _ = self.request("DELETE", "/cart/items/3")
        self.assertEqual(status, 404)

    def test_add_unknown_product_returns_404(self):
        status, _ = self.request("POST", "/cart/items", {"product_id": 99})
        self.assertEqual(status, 404)

    def test_add_invalid_body_returns_400(self):
        status, _ = self.request("POST", "/cart/items", {"product_id": "abc"})
        self.assertEqual(status, 400)
        status, _ = self.request("POST", "/cart/items", None)
        self.assertEqual(status, 400)

    def test_unknown_path_returns_404(self):
        status, _ = self.request("GET", "/nope")
        self.assertEqual(status, 404)


if __name__ == "__main__":
    unittest.main()