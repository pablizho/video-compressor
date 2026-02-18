@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion
title Сжатие видео (Drag and Drop)
color 0B

REM Загрузка настроек
call "%~dp0settings.bat"

REM Проверка FFmpeg
where ffmpeg >nul 2>&1
if errorlevel 1 (
    color 0C
    echo ОШИБКА: FFmpeg не найден!
    pause
    exit /b 1
)

if "%~1"=="" (
    echo ╔══════════════════════════════════════════════╗
    echo ║  Перетащите видеофайл(ы) на этот BAT файл!  ║
    echo ║  Или укажите путь к файлу как аргумент.     ║
    echo ╚══════════════════════════════════════════════╝
    pause
    exit /b 0
)

echo ╔══════════════════════════════════════════════╗
echo ║      СЖАТИЕ ВИДЕО - Drag and Drop           ║
echo ║  Кодек: %CODEC% / CRF: %CRF% / Пресет: %PRESET%
echo ╚══════════════════════════════════════════════╝
echo.

set "FILE_COUNT=0"

:process_loop
if "%~1"=="" goto :done

set /a FILE_COUNT+=1
set "INPUT_FILE=%~1"
set "FILE_NAME=%~n1"
set "FILE_DIR=%~dp1"
set "FILE_EXT=%~x1"

REM Выходной файл рядом с оригиналом
set "OUTPUT_FILE=%FILE_DIR%%FILE_NAME%_compressed.%OUTPUT_EXT%"

echo ──────────────────────────────────────────────
echo [%FILE_COUNT%] Файл: %FILE_NAME%%FILE_EXT%
echo ──────────────────────────────────────────────

REM Размер оригинала
for %%S in ("%INPUT_FILE%") do set "INPUT_SIZE=%%~zS"

REM Информация
for /f "tokens=*" %%I in ('ffprobe -v error -select_streams v:0 -show_entries stream^=width^,height^,codec_name -of csv^=p^=0 "%INPUT_FILE%" 2^>nul') do set "VIDEO_INFO=%%I"
echo Видео: !VIDEO_INFO!
echo Размер: !INPUT_SIZE! байт
echo.
echo Сжатие...

REM FFmpeg команда
if "%CODEC%"=="libx265" (
    ffmpeg -i "%INPUT_FILE%" -c:v %CODEC% -crf %CRF% -preset %PRESET% -tag:v hvc1 -x265-params log-level=error -c:a %AUDIO_CODEC% -b:a %AUDIO_BITRATE% -threads %THREADS% -movflags +faststart -y "%OUTPUT_FILE%"
) else if "%CODEC%"=="libsvtav1" (
    ffmpeg -i "%INPUT_FILE%" -c:v %CODEC% -crf %CRF% -preset 6 -c:a %AUDIO_CODEC% -b:a %AUDIO_BITRATE% -threads %THREADS% -movflags +faststart -y "%OUTPUT_FILE%"
) else (
    ffmpeg -i "%INPUT_FILE%" -c:v %CODEC% -crf %CRF% -preset %PRESET% -profile:v high -c:a %AUDIO_CODEC% -b:a %AUDIO_BITRATE% -threads %THREADS% -movflags +faststart -y "%OUTPUT_FILE%"
)

if errorlevel 1 (
    echo [ОШИБКА] Сжатие не удалось!
    if exist "%OUTPUT_FILE%" del "%OUTPUT_FILE%"
) else (
    for %%S in ("%OUTPUT_FILE%") do set "OUTPUT_SIZE=%%~zS"
    set /a SAVED=!INPUT_SIZE!-!OUTPUT_SIZE!
    if !OUTPUT_SIZE! gtr 0 (
        set /a SAVE_PERCENT=100-(!OUTPUT_SIZE!*100)/!INPUT_SIZE!
    ) else (
        set "SAVE_PERCENT=0"
    )
    echo.
    echo ✓ Готово!
    echo   Было:    !INPUT_SIZE! байт
    echo   Стало:   !OUTPUT_SIZE! байт  
    echo   Сжатие:  !SAVE_PERCENT!%%
    echo   Сохранен: %OUTPUT_FILE%
)
echo.

shift
goto :process_loop

:done
echo ══════════════════════════════════════════════
echo Обработано файлов: %FILE_COUNT%
echo ══════════════════════════════════════════════
pause
endlocal
exit /b 0