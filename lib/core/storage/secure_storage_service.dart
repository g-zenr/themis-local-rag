import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../shared/constants/api_constants.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> getServerUrl() =>
      _storage.read(key: ApiConstants.serverUrlKey);

  Future<String?> getApiKey() => _storage.read(key: ApiConstants.apiKeyKey);

  Future<bool> getUseLocalAi() async =>
      (await _storage.read(key: ApiConstants.useLocalAiKey)) == 'true';

  Future<String?> getLocalModelPath() =>
      _storage.read(key: ApiConstants.localModelPathKey);

  Future<void> setServerUrl(String url) =>
      _storage.write(key: ApiConstants.serverUrlKey, value: url);

  Future<void> setApiKey(String key) =>
      _storage.write(key: ApiConstants.apiKeyKey, value: key);

  Future<void> setUseLocalAi(bool value) => _storage.write(
    key: ApiConstants.useLocalAiKey,
    value: value ? 'true' : 'false',
  );

  Future<void> setLocalModelPath(String? path) async {
    if (path == null || path.isEmpty) {
      await _storage.delete(key: ApiConstants.localModelPathKey);
      return;
    }
    await _storage.write(key: ApiConstants.localModelPathKey, value: path);
  }

  Future<bool> hasRemoteConfig() async {
    final url = await getServerUrl();
    final key = await getApiKey();
    return url != null && url.isNotEmpty && key != null && key.isNotEmpty;
  }

  Future<bool> hasLocalConfig() async {
    final localEnabled = await getUseLocalAi();
    if (!localEnabled) return false;
    final modelPath = await getLocalModelPath();
    return modelPath != null && modelPath.isNotEmpty;
  }

  Future<bool> hasConfig() async {
    final localConfig = await hasLocalConfig();
    if (localConfig) return true;
    return hasRemoteConfig();
  }

  Future<void> clear() => _storage.deleteAll();
}
