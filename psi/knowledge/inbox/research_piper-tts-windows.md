# Research: Piper TTS on Windows 11

**Date**: 2026-03-23
**Requested by**: Morpheus research query

---

## Summary

Piper TTS has official Windows support via both a standalone binary and a pip package.

---

## 1. Official Windows Binary

YES — there is an official Windows binary in the GitHub releases.

**Latest release**: `2023.11.14-2` (the most recent tag on rhasspy/piper)

**Windows AMD64 download URL**:
```
https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_windows_amd64.zip
```

This URL is confirmed live (returns a 302 redirect to GitHub's CDN with the zip file).

The zip contains the `piper.exe` binary and required DLLs — a fully self-contained Windows executable.

**Note**: The rhasspy/piper repo was archived. Active development moved to:
`https://github.com/OHF-Voice/piper1-gpl`

---

## 2. pip install on Windows

YES — `pip install piper-tts` works on Windows.

- **PyPI package**: `piper-tts`
- **Latest version**: 1.4.1 (released Feb 5, 2026)
- **Windows wheel**: `piper_tts-1.4.1-cp39-abi3-win_amd64.whl` (13.8 MB)
- **Python requirement**: >= 3.9
- **Install command**:
  ```bash
  pip install piper-tts
  ```
- The wheel bundles all required native libs including piper-phonemize

---

## 3. WSL Option

WSL works as a fallback — install the Linux binary inside WSL and call it from Windows. This was the recommended workaround before official Windows builds existed (pre-Sept 2023). Now unnecessary unless you prefer it.

---

## 4. piper-phonemize Windows Support

**Complicated situation**:

- The **PyPI `piper-phonemize` package** does NOT have Windows wheels on its own. It only has Linux (manylinux) and macOS wheels.
- However, the **`piper-tts` pip package** (1.4.1) bundles everything and installs on Windows — it handles piper-phonemize internally via its own distribution.
- The `rhasspy/piper-phonemize` repo was **archived July 10, 2025** (read-only, no longer maintained).
- The binary release (`piper_windows_amd64.zip`) embeds phonemization — no separate piper-phonemize install needed.
- Community alternative: `piper-phonemize-cross` on PyPI offers cross-platform wheels.
- `sherpa-onnx` uses piper-phonemize and supports Windows natively — viable alternative.

---

## 5. Voice Models (.onnx files) — Platform Independence

YES — `.onnx` model files are fully platform-independent. They are:
- Neural network weights in the ONNX format
- Read by the ONNX Runtime (cross-platform)
- The same `.onnx` + `.onnx.json` file pair works on macOS, Linux, Windows, ARM, x86

The voices you use on macOS (kristin, ryan, jenny, carlin, danny, bryce, alan, norman, hfc_male, lessac) will work identically on Windows with the same model files.

---

## Recommended Installation Path (Windows 11)

### Option A: pip (cleanest for Python integration)
```bash
python -m venv .venv
.venv\Scripts\activate
pip install piper-tts
# Download voice model:
# piper_en_US-ryan-high.onnx + .json from huggingface.co/rhasspy/piper-voices
python -m piper --model en_US-ryan-high.onnx --output_file output.wav <<< "Hello world"
```

### Option B: Standalone binary (cleanest for CLI/scripts)
1. Download: `https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_windows_amd64.zip`
2. Extract to a folder (e.g., `C:\tools\piper\`)
3. Download voice `.onnx` + `.onnx.json` from: `https://huggingface.co/rhasspy/piper-voices`
4. Run:
   ```
   echo "Hello world" | piper.exe --model en_US-ryan-high.onnx --output_file output.wav
   ```

---

## Voice Model Download URLs

All voice models: `https://huggingface.co/rhasspy/piper-voices`

Specific voices needed (en_US):
- `en_US/kristin/medium/` — kristin
- `en_US/ryan/high/` — ryan
- `en_US/jenny/medium/` — jenny (en_GB actually — check)
- `en_US/joe/medium/` — carlin (verify mapping)
- `en_US/danny/low/` — danny
- `en_US/bryce/medium/` — bryce
- `en_US/alan/medium/` — alan (may be en_GB)
- `en_US/norman/medium/` — norman
- `en_US/hfc_male/medium/` — hfc_male
- `en_US/lessac/medium/` — lessac

---

## Sources

- GitHub releases: https://github.com/rhasspy/piper/releases
- PyPI piper-tts: https://pypi.org/project/piper-tts/
- Windows discussion: https://github.com/rhasspy/piper/discussions/173
- piper-phonemize discussion: https://github.com/rhasspy/piper/discussions/577
- Active dev repo: https://github.com/OHF-Voice/piper1-gpl
- SourceForge mirror: https://sourceforge.net/projects/piper-tts.mirror/
