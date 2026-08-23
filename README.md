# video-compressor

**Batch video compression on FFmpeg. Windows batch scripts, no runtime to install.**

![Batch](https://img.shields.io/badge/Windows-batch-0078D6?style=flat-square&logo=windows&logoColor=white)
![FFmpeg](https://img.shields.io/badge/FFmpeg-007808?style=flat-square&logo=ffmpeg&logoColor=white)
![NVENC](https://img.shields.io/badge/NVENC%20%2F%20AMF%20%2F%20QSV-hardware-76B900?style=flat-square)

811 lines of batch across 7 files · 15 recognised extensions · 3 hardware encoders

---

## Why it exists

Screen recordings from a test pass are big. A two-minute capture at 1440p is 300 MB, and the tracker rejects it. Re-encoding one file by hand is fine; re-encoding thirty after a regression day is not.

Drop files in `input/`, run `menu.bat`, collect `output/`. No Python, no dependencies, nothing to install except FFmpeg itself — which matters when the machine is a work laptop you don't fully control.

## What it does

- Seven-item text menu; batch, maximum-quality and GPU modes.
- 15 video extensions discovered from `input/`.
- Hardware encoding on NVIDIA, AMD or Intel, with **auto-detection**.
- Drag-and-drop mode: drop one or several files onto `compress_single.bat`, results land beside the originals.
- Resume — already-encoded files are skipped, so a killed 200-file batch picks up where it stopped.
- Per-file before/after sizes and a run summary with success/failure counts.
- All settings in one `settings.bat`, editable from the menu.

## Files

| File | Lines | Role |
|---|---|---|
| `menu.bat` | 99 | Menu loop, dispatches to workers via `cmd /c` |
| `compress.bat` | 148 | Balanced batch pass, settings-driven |
| `compress_max.bat` | 116 | Maximum quality: CRF 22, `veryslow`, 10-bit |
| `compress_gpu.bat` | 217 | Vendor picker + auto-detect + per-vendor rate control |
| `compress_single.bat` | 99 | Drag-and-drop target |
| `settings.bat` | 69 | Config only — just `set` statements |
| `install.bat` | 63 | Preflight: checks FFmpeg, creates folders |

## Engineering notes

**Hardware detection is a real capability probe, not a guess.** `:auto_detect` in `compress_gpu.bat` encodes a synthetic one-second clip to null for each vendor in turn:

```bat
ffmpeg -f lavfi -i color=c=black:s=64x64:d=1 -c:v hevc_nvenc -f null NUL
```

NVENC → AMF → QSV, falling through to "use the CPU script" only if all three fail. A registry lookup or a `wmic` GPU-name check gets this wrong whenever the driver is present but the encoder isn't — a laptop with a disabled dGPU, a VM, a stripped driver install.

**Rate control is tuned per vendor rather than shared.** This is the part people get wrong with hardware encoding — the same flags do not mean the same thing across encoders:

- NVENC — `-rc:v vbr -cq:v 24 -qmin 20 -qmax 28 -b:v 0 -preset p7 -tier high -spatial-aq 1 -temporal-aq 1 -rc-lookahead 32`
- AMD — `-quality quality -rc cqp -qp_i 22 -qp_p 24 -qp_b 26`
- Intel — `-global_quality 23 -preset veryslow -look_ahead 1`

**Skip and cleanup are designed against each other.** Every worker skips a file if the output already exists — which is what makes the batch resumable. That would be dangerous on its own, because a half-written file from a killed encode looks finished. So on any non-zero FFmpeg exit the scripts `del` the partial output. The two behaviours only work as a pair.

**Filenames with spaces.** `for /f "delims="` disables the default space/tab tokenisation that otherwise truncates `My Video.mp4` to `My`. This is the classic batch bug, and it's fixed in both the counting pass and the processing pass.

**`-tag:v hvc1` on every HEVC path**, paired with `-movflags +faststart`. Without the tag an x265 MP4 is a black frame on Apple devices.

**`chcp 65001` at the top of every script**, because the whole UI is Cyrillic and the default OEM codepage renders it as mojibake.

## Install

1. Install FFmpeg, add `bin` to PATH.
2. Run `install.bat` — verifies FFmpeg and creates `input/` and `output/`.
3. Put videos in `input/`, run `menu.bat`.

Or just drag files onto `compress_single.bat`.

## Known issues

- **The reported compression percentage is wrong.** `set /a` is 32-bit signed, and the scripts compute `100 - OUTPUT_SIZE * 100 / INPUT_SIZE`. The multiply overflows once the output exceeds ~21.5 MB — nearly every real video — so the number shown is garbage or negative. Dividing before multiplying fixes it. The encoding itself is unaffected.
- No guard against `INPUT_SIZE` being 0, which makes `set /a` fail mid-batch.
- **`compress_max.bat` ignores its own configuration** three times over: it calls `settings.bat`, overwrites five of the variables, then hardcodes `-crf 22 -preset veryslow -c:a aac -b:a 128k` in the FFmpeg line anyway. Only `OUTPUT_EXT` still comes from settings.
- Dead configuration in `settings.bat`: `SUFFIX`, `STRIP_METADATA`, `LOGGING` and `EXTENSIONS` are read by nothing. `LOGGING=yes` implies a log file that is never written; the extension list is duplicated as a literal in four scripts.
- Error checking is inconsistent — three scripts use `if errorlevel 1`, one uses `if !errorlevel! neq 0`, and success/failure counts can be off as a result.
- The double directory scan means a file added mid-run is processed but not counted, so `[N/TOTAL]` can exceed TOTAL.
- Subdirectories are ignored; no parallelism, no ETA, no per-file log, no dry run.
- `menu.bat` option 6 opens `settings.bat` in Notepad, and every worker `call`s that file — so "edit settings" is by construction a way to run arbitrary commands. Local-only, but worth knowing before running a `settings.bat` that came from someone else.
- Windows and `cmd.exe` only.

---

<details>
<summary><b>🇷🇺 По-русски</b></summary>

<br>

**Пакетное сжатие видео на FFmpeg. Батники под Windows, ставить нечего.**

### Зачем

Записи экрана с прогона тяжёлые. Две минуты в 1440p — это 300 МБ, и трекер такое не принимает. Пережать один файл руками нормально, тридцать после дня регресса — уже нет.

Кладёшь файлы в `input/`, запускаешь `menu.bat`, забираешь `output/`. Ни Python, ни зависимостей — только сам FFmpeg. Это важно, когда машина рабочая и ставить на неё можно не всё.

### Интересные места

- **Определение видеокарты — реальная проба, а не догадка.** `:auto_detect` кодирует синтетический односекундный клип в null каждым энкодером по очереди: NVENC → AMF → QSV. Проверка по названию GPU через реестр или `wmic` ошибается всегда, когда драйвер есть, а энкодер недоступен — отключённая дискретка на ноутбуке, виртуалка, урезанная установка драйвера.
- **Rate control настроен под каждого вендора отдельно** — это то, на чём обычно спотыкаются: одинаковые флаги у разных энкодеров означают разное. NVENC получает `-rc:v vbr -cq:v 24 -spatial-aq 1 -rc-lookahead 32`, AMD — `-rc cqp -qp_i 22`, Intel — `-global_quality 23 -look_ahead 1`.
- **Пропуск готовых файлов и удаление битых спроектированы в паре.** Пропуск даёт возобновляемость: убил батч на 200 файлах — перезапустил с того же места. Сам по себе он опасен, потому что недописанный файл выглядит готовым, поэтому при ненулевом коде возврата FFmpeg частичный выход удаляется.
- `for /f "delims="` — отключение разбиения по пробелам, иначе `Моё видео.mp4` обрезается до `Моё`. Классическая ошибка батников, поправлена в обоих проходах.
- `-tag:v hvc1` на всех путях HEVC — без него x265 в MP4 показывает чёрный кадр на технике Apple.

### Известные проблемы

**Процент сжатия считается неверно** — `set /a` 32-битный, и `OUTPUT_SIZE * 100` переполняется на файлах больше ~21,5 МБ. На само кодирование не влияет, только на цифру в отчёте. Ещё: `compress_max.bat` игнорирует собственные настройки, часть переменных в `settings.bat` не читается никем, подпапки не обходятся, только Windows.

</details>
