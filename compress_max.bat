@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion
title МАКСИМАЛЬНОЕ сжатие видео
color 0D

call "%~dp0settings.bat"

set "CRF=22"
set "PRESET=veryslow"
set "CODEC=libx265"
set "AUDIO_CODEC=aac"
set "AUDIO_BITRATE=128k"

if not exist "%INPUT_DIR%" mkdir "%INPUT_DIR%"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

where ffmpeg >nul 2>&1
if errorlevel 1 (
    echo ОШИБКА: FFmpeg не найден!
    pause
    exit /b 1
)

echo ╔══════════════════════════════════════════════════════╗
echo ║      МАКСИМАЛЬНОЕ СЖАТИЕ ВИДЕО                      ║
echo ╚══════════════════════════════════════════════════════╝
echo.

echo Содержимое папки INPUT:
echo ────────────────────────
dir /b "%INPUT_DIR%" 2>nul
echo ────────────────────────
echo.

set "TOTAL=0"
for %%E in (mp4 avi mkv mov wmv flv webm m4v ts mts m2ts mpg mpeg 3gp vob) do (
    for /f "delims=" %%F in ('dir /b "%INPUT_DIR%\*.%%E" 2^>nul') do (
        set /a TOTAL+=1
    )
)

if %TOTAL% equ 0 (
    echo Нет файлов в папке input!
    explorer "%INPUT_DIR%"
    pause
    exit /b 0
)

echo Найдено: %TOTAL% файлов
echo.
echo Нажмите любую клавишу для СТАРТА...
pause >nul
echo.
echo СТАРТ! Пожалуйста, ждите...
echo.

set "CURRENT=0"
set "SUCCESS=0"
set "FAILED=0"

for %%E in (mp4 avi mkv mov wmv flv webm m4v ts mts m2ts mpg mpeg 3gp vob) do (
    for /f "delims=" %%F in ('dir /b "%INPUT_DIR%\*.%%E" 2^>nul') do (
        set /a CURRENT+=1

        set "FULL_PATH=%INPUT_DIR%\%%F"
        set "OUTPUT_FILE=%OUTPUT_DIR%\%%~nF.%OUTPUT_EXT%"

        if exist "!OUTPUT_FILE!" (
            echo [!CURRENT!/%TOTAL%] ПРОПУСК: %%~nF - уже есть
        ) else (
            echo ═══════════════════════════════════════════
            echo [!CURRENT!/%TOTAL%] %%F
            echo ═══════════════════════════════════════════

            for %%S in ("!FULL_PATH!") do set "IN_SIZE=%%~zS"
            echo Размер оригинала: !IN_SIZE! байт
            echo Кодирую... это займет время...
            echo.

            ffmpeg -i "!FULL_PATH!" -c:v libx265 -crf 22 -preset veryslow -tag:v hvc1 -x265-params "log-level=error" -pix_fmt yuv420p10le -c:a aac -b:a 128k -movflags +faststart -threads 0 -y "!OUTPUT_FILE!"

            if !errorlevel! neq 0 (
                echo.
                echo [ОШИБКА] %%F
                set /a FAILED+=1
                if exist "!OUTPUT_FILE!" del "!OUTPUT_FILE!"
            ) else (
                for %%S in ("!OUTPUT_FILE!") do set "OUT_SIZE=%%~zS"
                if !OUT_SIZE! gtr 0 (
                    set /a SAVE_PCT=100-!OUT_SIZE!*100/!IN_SIZE!
                )
                echo.
                echo ГОТОВО: %%~nF
                echo   Было:   !IN_SIZE! байт
                echo   Стало:  !OUT_SIZE! байт
                echo   Сжатие: !SAVE_PCT!%%
                echo.
                set /a SUCCESS+=1
            )
        )
    )
)

echo.
echo ════════════════════════════════════════
echo   ИТОГО
echo   Успешно: %SUCCESS%
echo   Ошибки:  %FAILED%
echo ════════════════════════════════════════
echo.
echo Нажмите любую клавишу чтобы открыть результаты...
pause >nul
explorer "%OUTPUT_DIR%"

endlocal
exit /b 0