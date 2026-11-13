# Сборка Flutter-приложения в контейнере: анализ, тесты и Android APK.
#
# Собрать APK и достать его на компьютер:
#   docker build --target apk -o out .
#   (файл появится в папке out/app-release.apk)
#
# Только тесты:
#   docker build --target test .

FROM ghcr.io/cirruslabs/flutter:stable AS base
WORKDIR /app
COPY pubspec.yaml ./
RUN flutter pub get
COPY . .

# Проверка кода и тесты. Если тест падает, сборка останавливается.
FROM base AS test
RUN flutter analyze
RUN flutter test

# Release-APK. Адрес бэкенда задаётся при сборке.
# Для эмулятора Android оставьте значение по умолчанию (10.0.2.2).
# Для реального телефона укажите IP компьютера в локальной сети.
FROM base AS build
ARG API_BASE_URL=http://10.0.2.2:8000
RUN flutter build apk --release --dart-define=API_BASE_URL=${API_BASE_URL}

# Минимальный образ, в котором лежит только APK (нужен для вытаскивания файла).
FROM scratch AS apk
COPY --from=build /app/build/app/outputs/flutter-apk/app-release.apk /app-release.apk
