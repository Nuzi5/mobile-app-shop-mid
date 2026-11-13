**Mid-term project: Магазин (товары и корзина)**

Mid-term project - Mobile App Development
Мобильное приложение на Flutter, которое получает товары с сервера и управляет корзиной. 
Состояние приложения управляется через Bloc, бэкенд хранит корзину в SQLite, всё собирается в Docker.

1. Что реализовано
- Список товаров: 4 карточки с картинкой, брендом, названием, рейтингом и ценой (со скидкой, если есть).
- Экран товара: описание, категория, рейтинг, остаток на складе, кнопки «В корзину», «Добавить ещё» и «Удалить из корзины».
- Корзина: добавление товара (повторное добавление увеличивает количество), удаление позиции, итоговая сумма, экран корзины со списком позиций.
- Счётчик корзины в шапке списка товаров.
- Обработка ошибок: при недоступном сервере показывается сообщение и кнопка «Повторить», ошибки корзины выводятся всплывающей строкой.
- Тесты: unit-тесты бэкенда (8 штук) и тесты блоков Flutter (`bloc_test`) на подменённом репозитории.
- Docker: сборка бэкенда и Android APK, запуск тестов в контейнере.

2. Требования
- Кроссплатформенное Flutter-приложение -> Flutter, Material 3, один код для Android и других платформ 
- Связь с сервером -> REST-бэкенд, приложение обращается к нему через `dio` 
- Код на GitHub -> Этот репозиторий https://github.com/Nuzi5/mobile-app-shop-mid
- Управление состоянием через Bloc -> `ProductsBloc` и `CartBloc` на пакете `flutter_bloc` 
- Сборка в Docker -> `Dockerfile` для бэкенда и для Flutter (тесты и APK), `docker-compose.yml` 

3. Структура проекта
```
backend/                  бэкенд корзины
  server.py               REST-сервер на стандартной библиотеке Python и SQLite
  test_server.py          тесты API
  Dockerfile              образ бэкенда, тесты запускаются при сборке
mobile/                   Flutter-приложение
  lib/
    core/                 настройки ,адрес бэкенда
    data/                 модели, ApiClient, ShopRepository
    bloc/products/        ProductsBloc
    bloc/cart/            CartBloc
    presentation/         экраны и виджеты
  test/                   тесты блоков
  Dockerfile              тесты и APK
docker-compose.yml        запуск бэкенда
```

4. Что использовано
- Frontend: Flutter (Dart), Material 3, `flutter_bloc` для состояния, `equatable` для сравнения состояний, `dio` для HTTP, `bloc_test` для тестов блоков.
- Backend: Python 3.13, стандартная библиотека (`http.server`, `sqlite3`, `urllib`) без внешних зависимостей. Образ собирается быстро и не требует установки пакетов.
- Инфраструктура: Docker, Docker Compose, GitHub, Android Studio с эмулятором.
- Внешний источник данных: dummyjson.com, для списка товаров и картинок.

5. Как устроено
Бэкенд. Четыре эндпоинта:
- `GET /products` — список 4 товаров;
- `GET /cart` — корзина и итог;
- `POST /cart/items` — добавить товар (`{"product_id": 1}`);
- `DELETE /cart/items/{product_id}` — удалить товар из корзины.

Список товаров берётся с dummyjson.com при старте сервера. 
Если сайт недоступен, используется встроенный запасной список с теми же товарами. 
Корзина хранится в SQLite (файл `backend/data/app.db`), поэтому сохраняется между перезапусками.
Приложение. 
Экраны не обращаются к сети напрямую. Они отправляют события в блоки (`CartItemAdded`, `CartItemRemoved`, `ProductsRequested`), блоки обращаются к `ShopRepository`, а тот к `ApiClient`. 
Благодаря этому блоки тестируются без запущенного сервера.
Добавление в корзину: 
кнопка → событие `CartItemAdded` → `CartBloc` → `ShopRepository.addToCart` → `POST /cart/items` → 
-> сервер возвращает обновлённую корзину → блок выдаёт новое состояние → экран перерисовывается. 
Сервер является источником правды, приложение не считает корзину само.
Тесты. Бэкенд: все эндпоинты, ошибки 400 и 404. 
Блоки: загрузка, добавление, повторное добавление, удаление и ошибка сервера, через `FakeShopRepository`.

6. Запуск после клонирования
Нужны: Git, Docker Desktop (на Windows с WSL 2) и Android Studio с эмулятором, если хотите запускать приложение на эмуляторе.

1. Клонировать репозиторий
git clone https://github.com/Nuzi5/mobile-app-shop-mid.git
cd mobile-app-shop-mid
2. Запустить Docker Desktop и дождаться статуса Engine running
3. Запустить бэкенд
docker compose up --build
Проверка: откройте `http://localhost:8000/products`, должны быть 4 товара. Примечание:Бэкенд работает на порту 8000. Если порт занят другим контейнером, будут ошибки.
4. Запустить тесты Flutter (в новом терминале)
docker build --target test ./mobile
5. Собрать APK
docker build --target build -t shop-apk ./mobile
mkdir -p out
docker create --name shop-apk-tmp shop-apk
docker cp shop-apk-tmp:/app/build/app/outputs/flutter-apk/app-release.apk ./out/app-release.apk
docker rm shop-apk-tmp
Файл появится в `out/app-release.apk`
6. Установить APK в эмулятор
adb install -r out/app-release.apk
Или перетащите файл на окно эмулятора Android Studio. Если `adb` не находится, используйте полный путь к `adb.exe` из папки Android SDK, `platform-tools`.

Примечания
- Адрес бэкенда для эмулятора по умолчанию `http://10.0.2.2:8000`.
- Для реального телефона пересоберите APK с IP компьютера в локальной сети:
docker build --target build --build-arg API_BASE_URL=http://192.168.x.x:8000 -t shop-apk ./mobile
Затем повторите шаг с `docker create` и `docker cp`, чтобы достать новый APK.

Известные ограничения

- Сборка для iOS не выполнена: для неё нужен Mac или сборка через GitHub Actions.
- Картинки товаров загружаются с `cdn.dummyjson.com`, для их показа нужен интернет.
- Товары нельзя редактировать: бэкенд отдаёт только список из 4 позиций.
- Приложение только читает товары и управляет корзиной через API.
- Авторизации и оплаты нет.
