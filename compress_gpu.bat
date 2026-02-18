@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion
title Сжатие видео (GPU)
color 0E

call "%~dp0settings.bat"

if not exist "%INPUT_DIR%" mkdir "%INPUT_DIR%"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

where ffmpeg >nul 2>&1
if errorlevel 1 (
    echo ОШИБКА: FFmpeg не найден!
    pause
    exit /b 1
)

echo ╔══════════════════════════════════════════════════════╗
echo ║         СЖАТИЕ ВИДЕО С GPU-УСКОРЕНИЕМ               ║
echo ╠══════════════════════════════════════════════════════╣
echo ║                                                      ║
echo ║  Выберите вашу видеокарту:                          ║
echo ║                                                      ║
echo ║  [1] NVIDIA (GeForce GTX/RTX)                       ║
echo ║  [2] AMD (Radeon RX)                                ║
echo ║  [3] Intel (встроенная графика)                     ║
echo ║  [4] Не знаю / Автоопределение                     ║
echo ║                                                      ║
echo ╚══════════════════════════════════════════════════════╝
echo.

choice /c 1234 /n /m "Выберите (1-4): "

if errorlevel 4 goto :auto_detect
if errorlevel 3 goto :intel_gpu
if errorlevel 2 goto :amd_gpu
if errorlevel 1 goto :nvidia_gpu

:nvidia_gpu
set "GPU_CODEC=hevc_nvenc"
set "GPU_PARAMS=-rc:v vbr -cq:v 24 -qmin 20 -qmax 28 -b:v 0 -preset p7 -tier high -spatial-aq 1 -temporal-aq 1 -rc-lookahead 32"
set "GPU_NAME=NVIDIA NVENC"
goto :start_gpu

:amd_gpu
set "GPU_CODEC=hevc_amf"
set "GPU_PARAMS=-quality quality -rc cqp -qp_i 22 -qp_p 24 -qp_b 26"
set "GPU_NAME=AMD AMF"
goto :start_gpu

:intel_gpu
set "GPU_CODEC=hevc_qsv"
set "GPU_PARAMS=-global_quality 23 -preset veryslow -look_ahead 1"
set "GPU_NAME=Intel QSV"
goto :start_gpu

:auto_detect
echo Пробую NVIDIA...
ffmpeg -f lavfi -i color=c=black:s=64x64:d=1 -c:v hevc_nvenc -f null NUL >nul 2>&1
if not errorlevel 1 (
    set "GPU_CODEC=hevc_nvenc"
    set "GPU_PARAMS=-rc:v vbr -cq:v 24 -qmin 20 -qmax 28 -b:v 0 -preset p7 -tier high -spatial-aq 1 -temporal-aq 1"
    set "GPU_NAME=NVIDIA NVENC (авто)"
    goto :start_gpu
)

echo Пробую AMD...
ffmpeg -f lavfi -i color=c=black:s=64x64:d=1 -c:v hevc_amf -f null NUL >nul 2>&1
if not errorlevel 1 (
    set "GPU_CODEC=hevc_amf"
    set "GPU_PARAMS=-quality quality -rc cqp -qp_i 22 -qp_p 24 -qp_b 26"
    set "GPU_NAME=AMD AMF (авто)"
    goto :start_gpu
)

echo Пробую Intel...
ffmpeg -f lavfi -i color=c=black:s=64x64:d=1 -c:v hevc_qsv -f null NUL >nul 2>&1
if not errorlevel 1 (
    set "GPU_CODEC=hevc_qsv"
    set "GPU_PARAMS=-global_quality 23 -preset veryslow"
    set "GPU_NAME=Intel QSV (авто)"
    goto :start_gpu
)

echo.
color 0C
echo GPU-кодировщик не найден!
echo Используйте compress.bat для CPU-кодирования.
pause
exit /b 1

:start_gpu
echo.
echo Используется: %GPU_NAME%
echo Кодек: %GPU_CODEC%
echo.

REM ========================================
REM  ИСПРАВЛЕННЫЙ ПОИСК ФАЙЛОВ
REM ========================================

echo Сканирование папки: "%INPUT_DIR%"
echo.

REM Показать что реально лежит в папке
echo Содержимое папки INPUT:
echo ────────────────────────
dir /b "%INPUT_DIR%" 2>nul
echo ────────────────────────
echo.

set "TOTAL=0"

REM Считаем файлы через dir /b с каждым расширением
for %%E in (mp4 avi mkv mov wmv flv webm m4v ts mts m2ts mpg mpeg 3gp vob) do (
    for /f "delims=" %%F in ('dir /b "%INPUT_DIR%\*.%%E" 2^>nul') do (
        set /a TOTAL+=1
    )
)

echo Найдено видеофайлов: %TOTAL%

if %TOTAL% equ 0 (
    echo.
    echo ══════════════════════════════════════════
    echo   Нет видеофайлов в папке input!
    echo.
    echo   Убедитесь что файлы лежат ИМЕННО тут:
    echo   %INPUT_DIR%
    echo.
    echo   Поддерживаемые форматы:
    echo   MP4, AVI, MKV, MOV, WMV, FLV, WEBM,
    echo   M4V, TS, MTS, M2TS, MPG, MPEG, 3GP, VOB
    echo ══════════════════════════════════════════
    explorer "%INPUT_DIR%"
    pause
    exit /b 0
)

echo.
echo Нажмите любую клавишу для начала...
pause >nul

set "CURRENT=0"
set "SUCCESS=0"
set "FAILED=0"

REM ========================================
REM  ИСПРАВЛЕННЫЙ ЦИКЛ ОБРАБОТКИ
REM  Используем dir /b /s и for /f "delims="
REM  чтобы корректно обрабатывать пробелы
REM ========================================

for %%E in (mp4 avi mkv mov wmv flv webm m4v ts mts m2ts mpg mpeg 3gp vob) do (
    for /f "delims=" %%F in ('dir /b "%INPUT_DIR%\*.%%E" 2^>nul') do (
        set /a CURRENT+=1
        
        set "FULL_PATH=%INPUT_DIR%\%%F"
        set "FILE_NAME=%%~nF"
        set "OUTPUT_FILE=%OUTPUT_DIR%\%%~nF.mp4"
        
        if exist "!OUTPUT_FILE!" (
            echo [!CURRENT!/%TOTAL%] ПРОПУСК: %%~nF (уже существует^)
        ) else (
            echo.
            echo ═══════════════════════════════════════════════════
            echo [!CURRENT!/%TOTAL%] %%F
            echo ═══════════════════════════════════════════════════
            
            REM Размер оригинала
            for %%S in ("!FULL_PATH!") do set "IN_SIZE=%%~zS"
            echo Размер оригинала: !IN_SIZE! байт
            echo Кодирование через !GPU_NAME!...
            echo.
            
            ffmpeg -hwaccel auto -i "!FULL_PATH!" -c:v !GPU_CODEC! !GPU_PARAMS! -tag:v hvc1 -c:a aac -b:a %AUDIO_BITRATE% -movflags +faststart -y "!OUTPUT_FILE!"
            
            if errorlevel 1 (
                echo.
                echo [ОШИБКА] Не удалось сжать: %%F
                set /a FAILED+=1
                if exist "!OUTPUT_FILE!" del "!OUTPUT_FILE!"
            ) else (
                for %%S in ("!OUTPUT_FILE!") do set "OUT_SIZE=%%~zS"
                
                if !OUT_SIZE! gtr 0 (
                    set /a SAVE_PCT=100-^(!OUT_SIZE!*100^)/!IN_SIZE!
                ) else (
                    set "SAVE_PCT=0"
                )
                
                echo.
                echo ✓ Готово!
                echo   Было:   !IN_SIZE! байт
                echo   Стало:  !OUT_SIZE! байт
                echo   Сжатие: !SAVE_PCT!%%
                set /a SUCCESS+=1
            )
        )
    )
)

echo.
echo ╔══════════════════════════════════════════════════════╗
echo ║              ИТОГИ СЖАТИЯ                           ║
echo ╠══════════════════════════════════════════════════════╣
echo ║  Всего:     %TOTAL%
echo ║  Успешно:   %SUCCESS%
echo ║  Ошибки:    %FAILED%
echo ╚══════════════════════════════════════════════════════╝
echo.
echo Нажмите любую клавишу чтобы открыть папку с результатами...
pause >nul
explorer "%OUTPUT_DIR%"

endlocal
exit /b 0