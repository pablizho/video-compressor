@echo off
chcp 65001 >nul 2>&1
title Установка Видео Компрессора
color 0A

echo ╔══════════════════════════════════════╗
echo ║  Установка Видео Компрессора         ║
echo ╚══════════════════════════════════════╝
echo.

REM Проверка FFmpeg
where ffmpeg >nul 2>&1
if errorlevel 1 (
    color 0E
    echo [!] FFmpeg не найден в системе!
    echo.
    echo Для работы необходим FFmpeg.
    echo.
    echo Скачайте с: https://www.gyan.dev/ffmpeg/builds/
    echo Файл: ffmpeg-release-essentials.zip
    echo.
    echo 1. Распакуйте в C:\ffmpeg
    echo 2. Добавьте C:\ffmpeg\bin в системную переменную PATH
    echo 3. Перезапустите командную строку
    echo 4. Запустите этот скрипт снова
    echo.
    choice /c YN /m "Открыть страницу загрузки? (Y/N)"
    if not errorlevel 2 start https://www.gyan.dev/ffmpeg/builds/
    pause
    exit /b 1
) else (
    echo [✓] FFmpeg найден
    for /f "tokens=3" %%V in ('ffmpeg -version 2^>^&1 ^| findstr /i "ffmpeg version"') do echo     Версия: %%V
)

echo.

REM Создание папок
echo Создание папок...
if not exist "%~dp0input" (
    mkdir "%~dp0input"
    echo [✓] Создана папка: input
) else (
    echo [•] Папка input уже существует
)

if not exist "%~dp0output" (
    mkdir "%~dp0output"
    echo [✓] Создана папка: output
) else (
    echo [•] Папка output уже существует
)

echo.
echo ══════════════════════════════════════
echo  Установка завершена!
echo.
echo  Для начала работы:
echo  1. Положите видео в папку INPUT
echo  2. Запустите menu.bat
echo ══════════════════════════════════════
echo.
pause
exit /b 0