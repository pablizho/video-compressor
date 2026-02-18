@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion
title Пакетное сжатие видео
color 0A

REM Загрузка настроек
call "%~dp0settings.bat"

REM Создание папок
if not exist "%INPUT_DIR%" mkdir "%INPUT_DIR%"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM Проверка FFmpeg
where ffmpeg >nul 2>&1
if errorlevel 1 (
    color 0C
    echo ══════════════════════════════════════════
    echo   ОШИБКА: FFmpeg не найден!
    echo   Установите FFmpeg и добавьте в PATH
    echo ══════════════════════════════════════════
    pause
    exit /b 1
)

echo ╔══════════════════════════════════════════════════════╗
echo ║         ПАКЕТНОЕ СЖАТИЕ ВИДЕО v2.0                  ║
echo ╠══════════════════════════════════════════════════════╣
echo ║  Кодек:    %CODEC%
echo ║  CRF:      %CRF%
echo ║  Пресет:   %PRESET%
echo ║  Аудио:    %AUDIO_CODEC% @ %AUDIO_BITRATE%
echo ║  Вход:     %INPUT_DIR%
echo ║  Выход:    %OUTPUT_DIR%
echo ╚══════════════════════════════════════════════════════╝
echo.

REM Показать содержимое
echo Содержимое папки INPUT:
echo ────────────────────────
dir /b "%INPUT_DIR%" 2>nul
echo ────────────────────────
echo.

REM Подсчет файлов
set "TOTAL=0"
for %%E in (mp4 avi mkv mov wmv flv webm m4v ts mts m2ts mpg mpeg 3gp vob) do (
    for /f "delims=" %%F in ('dir /b "%INPUT_DIR%\*.%%E" 2^>nul') do (
        set /a TOTAL+=1
    )
)

if %TOTAL% equ 0 (
    color 0E
    echo ══════════════════════════════════════════
    echo   Нет видеофайлов в папке input!
    echo ══════════════════════════════════════════
    explorer "%INPUT_DIR%"
    pause
    exit /b 0
)

echo Найдено файлов: %TOTAL%
echo.
echo Нажмите любую клавишу для начала сжатия...
pause >nul

REM Счетчики
set "CURRENT=0"
set "SUCCESS=0"
set "FAILED=0"
set "START_TIME=%time%"

REM Обработка файлов
for %%E in (mp4 avi mkv mov wmv flv webm m4v ts mts m2ts mpg mpeg 3gp vob) do (
    for /f "delims=" %%F in ('dir /b "%INPUT_DIR%\*.%%E" 2^>nul') do (
        set /a CURRENT+=1
        
        set "FULL_PATH=%INPUT_DIR%\%%F"
        set "FILE_NAME=%%~nF"
        set "OUTPUT_FILE=%OUTPUT_DIR%\%%~nF.%OUTPUT_EXT%"
        
        REM Пропуск если файл уже существует
        if exist "!OUTPUT_FILE!" (
            echo [!CURRENT!/%TOTAL%] ПРОПУСК: %%~nF (уже существует^)
        ) else (
            echo.
            echo ══════════════════════════════════════════════════
            echo [!CURRENT!/%TOTAL%] Обработка: %%F
            echo ══════════════════════════════════════════════════
            
            REM Размер исходного файла
            for %%S in ("!FULL_PATH!") do set "INPUT_SIZE=%%~zS"
            echo Размер оригинала: !INPUT_SIZE! байт
            echo Сжатие...
            echo.
            
            REM FFmpeg кодирование
            if "%CODEC%"=="libx265" (
                ffmpeg -i "!FULL_PATH!" -c:v libx265 -crf %CRF% -preset %PRESET% -tag:v hvc1 -x265-params log-level=error -c:a %AUDIO_CODEC% -b:a %AUDIO_BITRATE% -threads %THREADS% -movflags +faststart -y "!OUTPUT_FILE!"
            ) else if "%CODEC%"=="libsvtav1" (
                ffmpeg -i "!FULL_PATH!" -c:v libsvtav1 -crf %CRF% -preset 6 -c:a %AUDIO_CODEC% -b:a %AUDIO_BITRATE% -threads %THREADS% -movflags +faststart -y "!OUTPUT_FILE!"
            ) else (
                ffmpeg -i "!FULL_PATH!" -c:v %CODEC% -crf %CRF% -preset %PRESET% -profile:v high -level 4.1 -c:a %AUDIO_CODEC% -b:a %AUDIO_BITRATE% -threads %THREADS% -movflags +faststart -y "!OUTPUT_FILE!"
            )
            
            if errorlevel 1 (
                color 0C
                echo [ОШИБКА] Не удалось сжать: %%F
                set /a FAILED+=1
                if exist "!OUTPUT_FILE!" del "!OUTPUT_FILE!"
                color 0A
            ) else (
                for %%S in ("!OUTPUT_FILE!") do set "OUTPUT_SIZE=%%~zS"
                
                if !OUTPUT_SIZE! gtr 0 (
                    set /a PERCENT=!OUTPUT_SIZE!*100/!INPUT_SIZE!
                    set /a SAVE_PERCENT=100-!PERCENT!
                ) else (
                    set "SAVE_PERCENT=0"
                )
                
                echo.
                echo ✓ Готово!
                echo   Было:    !INPUT_SIZE! байт
                echo   Стало:   !OUTPUT_SIZE! байт
                echo   Сжатие:  !SAVE_PERCENT!%%
                set /a SUCCESS+=1
            )
        )
    )
)

echo.
echo ╔══════════════════════════════════════════════════════╗
echo ║              ИТОГИ СЖАТИЯ                           ║
echo ╠══════════════════════════════════════════════════════╣
echo ║  Всего файлов:     %TOTAL%
echo ║  Успешно:          %SUCCESS%
echo ║  Ошибки:           %FAILED%
echo ║  Начало:           %START_TIME%
echo ║  Конец:            %time%
echo ╚══════════════════════════════════════════════════════╝
echo.
pause
explorer "%OUTPUT_DIR%"

endlocal
exit /b 0