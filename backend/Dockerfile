# Бэкенд корзины. Внешних зависимостей нет, только стандартная библиотека Python.
FROM python:3.13-slim

WORKDIR /app
COPY server.py test_server.py ./

# Тесты запускаются при сборке: если они падают, образ не собирается.
RUN python -m unittest test_server.py

ENV PORT=8000 \
    DB_PATH=/app/data/app.db \
    PYTHONUNBUFFERED=1

EXPOSE 8000
CMD ["python", "server.py"]
