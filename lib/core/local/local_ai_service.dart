import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';

class LocalAiException implements Exception {
  const LocalAiException(this.message);

  final String message;

  @override
  String toString() => message;
}

enum LocalGenerationProfile { normal, stable }

class LocalAiService {
  LlamaController? _controller;
  String? _modelPath;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  int _recommendedThreads() {
    final processors = Platform.numberOfProcessors;
    if (processors <= 2) return 1;
    return 2;
  }

  Future<void> ensureLoaded(String modelPath) async {
    if (!Platform.isAndroid) {
      throw const LocalAiException(
        'On-device AI is currently supported on Android only.',
      );
    }

    final file = File(modelPath);
    if (!await file.exists()) {
      throw LocalAiException('Local model file not found: $modelPath');
    }

    if (_controller != null && _modelPath == modelPath && _isLoaded) {
      return;
    }

    await dispose();

    final controller = LlamaController();

    try {
      await controller.loadModel(
        modelPath: modelPath,
        threads: _recommendedThreads(),
        contextSize: 1280,
        gpuLayers: 0,
      );
      _controller = controller;
      _modelPath = modelPath;
      _isLoaded = true;
    } catch (e) {
      await controller.dispose();
      throw LocalAiException('Failed to initialize local model: $e');
    }
  }

  Future<Stream<String>> streamPrompt(
    String prompt, {
    LocalGenerationProfile profile = LocalGenerationProfile.normal,
  }) async {
    final controller = _controller;
    if (controller == null || !_isLoaded) {
      throw const LocalAiException(
        'Local model is not loaded. Configure local AI in Settings.',
      );
    }

    if (controller.isGenerating) {
      await controller.stop();
    }

    try {
      final useStable = profile == LocalGenerationProfile.stable;
      final stream = controller.generate(
        prompt: prompt,
        maxTokens: useStable ? 112 : 128,
        temperature: useStable ? 0.22 : 0.30,
        topP: useStable ? 0.80 : 0.88,
        topK: useStable ? 20 : 30,
        repeatPenalty: useStable ? 1.35 : 1.20,
        frequencyPenalty: useStable ? 0.30 : 0.10,
        presencePenalty: useStable ? 0.20 : 0.05,
        repeatLastN: useStable ? 128 : 64,
      );
      return stream.transform(
        StreamTransformer<String, String>.fromHandlers(
          handleError: (error, stackTrace, sink) {
            sink.addError(
              LocalAiException('Local generation failed: $error'),
              stackTrace,
            );
          },
        ),
      );
    } catch (e) {
      throw LocalAiException('Failed to queue local prompt: $e');
    }
  }

  Future<void> stopGeneration() async {
    final controller = _controller;
    if (controller == null) return;
    if (controller.isGenerating) {
      await controller.stop();
    }
  }

  Future<void> dispose() async {
    final controller = _controller;
    _controller = null;
    _modelPath = null;
    _isLoaded = false;
    if (controller != null) {
      await controller.dispose();
    }
  }
}

final localAiServiceProvider = Provider<LocalAiService>((ref) {
  final service = LocalAiService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});
