# Themis Local RAG

On-device legal RAG assistant built with Flutter.

## What this app does

- Runs local AI on Android using a bundled GGUF model.
- Indexes uploaded PDF/TXT documents locally.
- Answers questions using retrieval-augmented generation (RAG).
- Keeps document processing and inference on-device.

## Quick setup (Windows / PowerShell)

1. Install dependencies:

```powershell
flutter pub get
```

2. Download the TinyLlama model into `assets/models`:

```powershell
Invoke-WebRequest "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q2_K.gguf?download=true" -OutFile "....\template_app\assets\models\tinyllama-1.1b-chat-v1.0.Q2_K.gguf"
```

3. Run the app:

```powershell
flutter run
```

4. In app settings:
- Enable `Run AI on this device`
- Tap `Save & Continue`

## Notes

- Model binaries (`*.gguf`) are git-ignored and are not pushed to GitHub.
- Default model filename expected by the app:
  - `tinyllama-1.1b-chat-v1.0.Q2_K.gguf`
