import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/local/bundled_model_service.dart';
import '../../../core/models/health_status.dart';
import '../../../shared/constants/api_constants.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _serverUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();

  bool _useLocalAi = false;
  String? _localModelPath;
  bool _obscureApiKey = true;
  bool _isTesting = false;
  bool _isSaving = false;
  bool _isPickingModel = false;
  bool _isInstallingBundledModel = false;
  bool _bundledModelAvailable = false;

  HealthStatus? _healthStatus;
  String? _errorMessage;
  bool _testSucceeded = false;

  @override
  void initState() {
    super.initState();
    _loadExistingConfig();
  }

  Future<void> _loadExistingConfig() async {
    final remoteConfig = await ref.read(serverConfigProvider.future);
    final localConfig = await ref.read(localAiConfigProvider.future);
    final bundledService = ref.read(bundledModelServiceProvider);
    final bundledAvailable = await bundledService.hasBundledModelAsset();
    if (!mounted) return;

    _serverUrlController.text = remoteConfig?.serverUrl ?? '';
    _apiKeyController.text = remoteConfig?.apiKey ?? '';

    setState(() {
      _useLocalAi = localConfig.enabled;
      _localModelPath = localConfig.modelPath;
      _bundledModelAvailable = bundledAvailable;
    });

    if (_useLocalAi &&
        (_localModelPath == null || _localModelPath!.trim().isEmpty) &&
        _bundledModelAvailable) {
      await _installBundledModel();
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _pickLocalModel() async {
    setState(() {
      _isPickingModel = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['gguf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final selected = result.files.first;
      final appDir = await getApplicationSupportDirectory();
      final modelDir = Directory(p.join(appDir.path, 'models'));
      await modelDir.create(recursive: true);

      final fileName = selected.name.toLowerCase().endsWith('.gguf')
          ? selected.name
          : '${selected.name}.gguf';
      final targetPath = p.join(modelDir.path, fileName);
      final target = File(targetPath);

      if (selected.path != null && selected.path!.isNotEmpty) {
        final source = File(selected.path!);
        if (source.absolute.path != target.absolute.path) {
          await source.copy(targetPath);
        }
      } else if (selected.bytes != null) {
        await target.writeAsBytes(selected.bytes!, flush: true);
      } else {
        throw Exception('Unable to read selected model file.');
      }

      if (mounted) {
        setState(() {
          _localModelPath = targetPath;
          _testSucceeded = false;
          _healthStatus = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to select model: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingModel = false;
        });
      }
    }
  }

  Future<void> _testConnection() async {
    final serverUrl = _serverUrlController.text.trim();
    final apiKey = _apiKeyController.text.trim();

    if (serverUrl.isEmpty || apiKey.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both a server URL and an API key.';
        _healthStatus = null;
        _testSucceeded = false;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _errorMessage = null;
      _healthStatus = null;
      _testSucceeded = false;
    });

    String baseUrl = serverUrl;
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: ApiConstants.defaultTimeout,
        receiveTimeout: ApiConstants.defaultTimeout,
        headers: {'X-API-Key': apiKey, 'Accept': 'application/json'},
      ),
    );

    try {
      final response = await dio.get<Map<String, dynamic>>('/api/health');
      final health = HealthStatus.fromJson(response.data!);
      if (mounted) {
        setState(() {
          _healthStatus = health;
          _testSucceeded = true;
          _isTesting = false;
        });
      }
    } on DioException catch (e) {
      final apiError = ApiException.fromDioException(e);
      if (mounted) {
        setState(() {
          _errorMessage = apiError.message;
          _testSucceeded = false;
          _isTesting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _testSucceeded = false;
          _isTesting = false;
        });
      }
    }
  }

  Future<void> _saveAndContinue() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    var shouldNavigate = false;

    try {
      if (_useLocalAi &&
          (_localModelPath == null || _localModelPath!.trim().isEmpty)) {
        if (!_bundledModelAvailable) {
          throw Exception(
            'No local model selected. Choose a GGUF model first.',
          );
        }

        final installed = await _installBundledModel().timeout(
          const Duration(minutes: 3),
        );
        if (!installed) {
          return;
        }
      }

      final params = SaveSettingsParams(
        useLocalAi: _useLocalAi,
        localModelPath: _localModelPath,
        serverUrl: _serverUrlController.text.trim(),
        apiKey: _apiKeyController.text.trim(),
      );

      await ref.read(saveSettingsProvider(params).future).timeout(
        const Duration(seconds: 20),
      );
      shouldNavigate = true;
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Saving took too long. Please try again. '
            'If this is first setup, wait for bundled model install to finish.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to save settings: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        if (shouldNavigate) {
          context.go('/ask');
        }
      }
    }
  }

  bool get _canSave {
    if (_useLocalAi) {
      return !_isSaving &&
          !_isInstallingBundledModel &&
          ((_localModelPath != null && _localModelPath!.trim().isNotEmpty) ||
              _bundledModelAvailable);
    }
    return !_isSaving && _testSucceeded;
  }

  Future<bool> _installBundledModel() async {
    if (_isInstallingBundledModel) return false;

    setState(() {
      _isInstallingBundledModel = true;
      _errorMessage = null;
    });

    final bundledService = ref.read(bundledModelServiceProvider);
    try {
      final modelPath = await bundledService
          .ensureDefaultModelInstalled()
          .timeout(const Duration(minutes: 3));
      if (!mounted) return false;
      setState(() {
        _localModelPath = modelPath;
      });
      return true;
    } on TimeoutException {
      if (!mounted) return false;
      setState(() {
        _errorMessage =
            'Bundled model install timed out. Try again or select a model file manually.';
      });
      return false;
    } catch (e) {
      if (!mounted) return false;
      setState(() {
        _errorMessage = e.toString();
      });
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isInstallingBundledModel = false;
        });
      }
    }
  }

  Future<void> _onUseLocalAiChanged(bool value) async {
    setState(() {
      _useLocalAi = value;
      _errorMessage = null;
      _testSucceeded = false;
      _healthStatus = null;
    });

    if (value &&
        (_localModelPath == null || _localModelPath!.trim().isEmpty) &&
        _bundledModelAvailable) {
      await _installBundledModel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'AI Mode',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: SwitchListTile(
                value: _useLocalAi,
                onChanged: _onUseLocalAiChanged,
                title: const Text('Run AI on this device'),
                subtitle: const Text('Use an on-device GGUF model'),
              ),
            ),
            const SizedBox(height: 20),

            if (_useLocalAi) _buildLocalModeCard(colorScheme),
            if (!_useLocalAi) _buildRemoteModeCard(colorScheme),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorCard(colorScheme),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _canSave ? _saveAndContinue : null,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_isSaving ? 'Saving...' : 'Save & Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalModeCard(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'On-Device Model',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a `.gguf` model file to run fully on your phone.\n'
              'For maximum compatibility on weak devices, start with '
              'TinyLlama Q2_K.\n'
              'Bundled model: ${_bundledModelAvailable ? 'available' : 'not found in assets'}',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            if (_bundledModelAvailable) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isInstallingBundledModel
                      ? null
                      : _installBundledModel,
                  icon: _isInstallingBundledModel
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_done_rounded),
                  label: Text(
                    _isInstallingBundledModel
                        ? 'Installing bundled model...'
                        : 'Use Bundled TinyLlama Q2_K',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isPickingModel ? null : _pickLocalModel,
                icon: _isPickingModel
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.folder_open_rounded),
                label: Text(
                  _isPickingModel ? 'Selecting...' : 'Select GGUF Model',
                ),
              ),
            ),
            if (_localModelPath != null) ...[
              const SizedBox(height: 10),
              Text(
                'Model: $_localModelPath',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteModeCard(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Server Configuration',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _serverUrlController,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Server URL',
            hintText: 'https://your-server:8001',
            prefixIcon: Icon(Icons.dns_outlined),
          ),
          onChanged: (_) => _resetRemoteTestState(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _apiKeyController,
          obscureText: _obscureApiKey,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: 'API Key',
            hintText: 'Enter your API key',
            prefixIcon: const Icon(Icons.key_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureApiKey
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() => _obscureApiKey = !_obscureApiKey);
              },
            ),
          ),
          onChanged: (_) => _resetRemoteTestState(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isTesting ? null : _testConnection,
            icon: _isTesting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_find_rounded),
            label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
          ),
        ),
        if (_healthStatus != null) ...[
          const SizedBox(height: 16),
          _buildSuccessCard(colorScheme),
        ],
      ],
    );
  }

  void _resetRemoteTestState() {
    if (_testSucceeded || _errorMessage != null || _healthStatus != null) {
      setState(() {
        _testSucceeded = false;
        _healthStatus = null;
        _errorMessage = null;
      });
    }
  }

  Widget _buildSuccessCard(ColorScheme colorScheme) {
    final health = _healthStatus!;
    return Card(
      color: colorScheme.primaryContainer.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade700,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Connection Successful',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _statusRow('Status', health.status),
            _statusRow('Database', health.database),
            _statusRow('Model Loaded', health.modelLoaded ? 'Yes' : 'No'),
            _statusRow(
              'Chunks',
              '${health.totalChunks} total, ${health.indexedChunks} indexed',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(ColorScheme colorScheme) {
    return Card(
      color: colorScheme.errorContainer.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: colorScheme.onErrorContainer,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: colorScheme.onErrorContainer,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
