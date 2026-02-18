
@echo off
chcp 65001 >nul 2>&1
title Git Push - Video Compressor
color 0A

cd /d "C:\VideoCompressor"

echo ══════════════════════════════════════════
echo   PUSH: Video Compressor
echo ══════════════════════════════════════════
echo.

REM Проверка git
git --version >nul 2>&1
if errorlevel 1 (
    echo ОШИБКА: Git не установлен!
    echo Скачайте с https://git-scm.com
    pause
    exit /b 1
)

REM Создаём .gitkeep для пустых папок
if not exist "input\.gitkeep" echo. > "input\.gitkeep"
if not exist "output\.gitkeep" echo. > "output\.gitkeep"

REM Проверяем есть ли уже репозиторий
if exist ".git" (
    echo Репозиторий уже существует
    echo Добавляю изменения...
    echo.
    git add .
    
    set /p "MSG=Описание изменений: "
    git commit -m "%MSG%"
    git push
    
    echo.
    echo ГОТОВО!
    pause
    exit /b 0
)

echo Создание нового репозитория...
echo.

REM Ваши данные (ЗАМЕНИТЕ!)
set /p "GIT_NAME=Ваше имя для Git: "
set /p "GIT_EMAIL=Ваш email для Git: "
set /p "GIT_REPO=URL репозитория (https://github.com/...): "

git init
git config user.name "%GIT_NAME%"
git config user.email "%GIT_EMAIL%"

echo.
echo Добавляю файлы...
git add .

echo.
echo Файлы для коммита:
echo ────────────────────
git status --short
echo ────────────────────
echo.

git commit -m "Initial commit: Video Compressor"
git branch -M main
git remote add origin "%GIT_REPO%"

echo.
echo Пушу на GitHub...
git push -u origin main

echo.
echo ══════════════════════════════════════════
echo   ГОТОВО! Проверьте GitHub
echo ══════════════════════════════════════════
pause