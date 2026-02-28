import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BundledModelException implements Exception {
  const BundledModelException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BundledModelService {
  static const String defaultModelFileName =
      'tinyllama-1.1b-chat-v1.0.Q2_K.gguf';
  static const String defaultModelAssetPath =
      'assets/models/$defaultModelFileName';

  Future<bool> hasBundledModelAsset({
    String assetPath = defaultModelAssetPath,
  }) async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      return manifest.listAssets().contains(assetPath);
    } catch (_) {
      return false;
    }
  }

  Future<String> ensureDefaultModelInstalled() {
    return ensureBundledModelInstalled(
      assetPath: defaultModelAssetPath,
      targetFileName: defaultModelFileName,
    );
  }

  Future<String> ensureBundledModelInstalled({
    required String assetPath,
    required String targetFileName,
  }) async {
    final hasAsset = await hasBundledModelAsset(assetPath: assetPath);
    if (!hasAsset) {
      throw BundledModelException(
        'Bundled model not found in app assets at "$assetPath".',
      );
    }

    final supportDir = await getApplicationSupportDirectory();
    final modelsDir = Directory(p.join(supportDir.path, 'models'));
    await modelsDir.create(recursive: true);

    final installedPath = p.join(modelsDir.path, targetFileName);
    final installedFile = File(installedPath);
    if (await installedFile.exists()) {
      return installedPath;
    }

    try {
      final byteData = await rootBundle.load(assetPath);
      await installedFile.writeAsBytes(
        byteData.buffer.asUint8List(),
        flush: true,
      );
      return installedPath;
    } catch (_) {
      throw BundledModelException('Failed to load bundled asset "$assetPath".');
    }
  }
}

final bundledModelServiceProvider = Provider<BundledModelService>((ref) {
  return BundledModelService();
});
