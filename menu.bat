@echo off
chcp 65001 >nul 2>&1
setlocal
title Видео Компрессор - Главное Меню
color 0B

:main_menu
cls
echo.
echo  ╔═══════════════════════════════════════════════════════╗
echo  ║          ВИДЕО КОМПРЕССОР v2.0                       ║
echo  ╠═══════════════════════════════════════════════════════╣
echo  ║                                                       ║
echo  ║   [1]  Сжать все видео из папки INPUT                ║
echo  ║        (сбалансированные настройки)                   ║
echo  ║                                                       ║
echo  ║   [2]  МАКСИМАЛЬНОЕ сжатие (медленно)                ║
echo  ║                                                       ║
echo  ║   [3]  GPU-ускоренное сжатие (быстро)                ║
echo  ║                                                       ║
echo  ║   [4]  Открыть папку INPUT                           ║
echo  ║                                                       ║
echo  ║   [5]  Открыть папку OUTPUT                          ║
echo  ║                                                       ║
echo  ║   [6]  Редактировать настройки                       ║
echo  ║                                                       ║
echo  ║   [7]  Очистить папку OUTPUT                         ║
echo  ║                                                       ║
echo  ║   [0]  Выход                                         ║
echo  ║                                                       ║
echo  ╚═══════════════════════════════════════════════════════╝
echo.

set "CHOICE="
set /p "CHOICE=  Выберите действие (0-7): "

if "%CHOICE%"=="1" goto :do_normal
if "%CHOICE%"=="2" goto :do_max
if "%CHOICE%"=="3" goto :do_gpu
if "%CHOICE%"=="4" goto :do_open_input
if "%CHOICE%"=="5" goto :do_open_output
if "%CHOICE%"=="6" goto :do_settings
if "%CHOICE%"=="7" goto :do_clean
if "%CHOICE%"=="0" goto :do_exit

echo  Неверный выбор!
timeout /t 2 >nul
goto :main_menu

:do_normal
cmd /c "%~dp0compress.bat"
echo.
echo Нажмите любую клавишу для возврата в меню...
pause >nul
goto :main_menu

:do_max
cmd /c "%~dp0compress_max.bat"
echo.
echo Нажмите любую клавишу для возврата в меню...
pause >nul
goto :main_menu

:do_gpu
cmd /c "%~dp0compress_gpu.bat"
echo.
echo Нажмите любую клавишу для возврата в меню...
pause >nul
goto :main_menu

:do_open_input
call "%~dp0settings.bat"
if not exist "%INPUT_DIR%" mkdir "%INPUT_DIR%"
explorer "%INPUT_DIR%"
goto :main_menu

:do_open_output
call "%~dp0settings.bat"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
explorer "%OUTPUT_DIR%"
goto :main_menu

:do_settings
notepad "%~dp0settings.bat"
goto :main_menu

:do_clean
call "%~dp0settings.bat"
echo.
echo  ВНИМАНИЕ: Все файлы из OUTPUT будут удалены!
set /p "CONFIRM=  Точно удалить? (Y/N): "
if /i "%CONFIRM%"=="Y" (
    del /q "%OUTPUT_DIR%\*.*" 2>nul
    echo  Очищено!
    timeout /t 2 >nul
)
goto :main_menu

:do_exit
exit /b 0