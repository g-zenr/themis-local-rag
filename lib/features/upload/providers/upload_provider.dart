import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/router.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/local/local_documents_service.dart';
import '../../../core/models/upload_result.dart';
import '../../../shared/constants/api_constants.dart';

// ---------------------------------------------------------------------------
// Upload state
// ---------------------------------------------------------------------------

/// Immutable state object for the upload workflow.
class UploadState {
  /// Absolute path to the selected file on disk.
  final String? selectedFile;

  /// Display name of the selected file.
  final String? fileName;

  /// Size of the selected file in bytes.
  final int? fileSize;

  /// The file extension (e.g. "pdf", "txt").
  final String? fileExtension;

  /// User-editable document title.
  final String title;

  /// User-editable document year.
  final int year;

  /// Whether an upload is currently in progress.
  final bool isUploading;

  /// Error message from the last failed operation, or `null`.
  final String? error;

  /// File validation error (wrong extension, too large, etc.), or `null`.
  final String? fileError;

  /// The result returned after a successful upload.
  final UploadResult? result;

  const UploadState({
    this.selectedFile,
    this.fileName,
    this.fileSize,
    this.fileExtension,
    this.title = '',
    int? year,
    this.isUploading = false,
    this.error,
    this.fileError,
    this.result,
  }) : year = year ?? 2026;

  UploadState copyWith({
    String? selectedFile,
    String? fileName,
    int? fileSize,
    String? fileExtension,
    String? title,
    int? year,
    bool? isUploading,
    String? error,
    String? fileError,
    UploadResult? result,
    // Sentinel flags for nullable fields.
    bool clearSelectedFile = false,
    bool clearError = false,
    bool clearFileError = false,
    bool clearResult = false,
  }) {
    return UploadState(
      selectedFile: clearSelectedFile
          ? null
          : (selectedFile ?? this.selectedFile),
      fileName: clearSelectedFile ? null : (fileName ?? this.fileName),
      fileSize: clearSelectedFile ? null : (fileSize ?? this.fileSize),
      fileExtension: clearSelectedFile
          ? null
          : (fileExtension ?? this.fileExtension),
      title: title ?? this.title,
      year: year ?? this.year,
      isUploading: isUploading ?? this.isUploading,
      error: clearError ? null : (error ?? this.error),
      fileError: clearFileError ? null : (fileError ?? this.fileError),
      result: clearResult ? null : (result ?? this.result),
    );
  }

  /// Whether the form is valid and ready for submission.
  bool get isFormValid =>
      selectedFile != null &&
      fileError == null &&
      title.length >= ApiConstants.minTitleLength &&
      title.length <= ApiConstants.maxTitleLength &&
      year >= ApiConstants.minYear &&
      year <= ApiConstants.maxYear;

  /// Human-readable file size string.
  String get fileSizeFormatted {
    if (fileSize == null) return '';
    final kb = fileSize! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}

// ---------------------------------------------------------------------------
// Upload notifier
// ---------------------------------------------------------------------------

/// State notifier that manages the upload workflow: file picking, validation,
/// form editing, and multipart upload to the server.
class UploadNotifier extends StateNotifier<UploadState> {
  final Ref _ref;

  UploadNotifier(this._ref) : super(const UploadState());

  // ---- File selection ----

  /// Opens the system file picker, validates the selected file's extension
  /// and size, and updates the state accordingly.
  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ApiConstants.supportedFileExtensions,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final path = file.path;
      if (path == null) {
        state = state.copyWith(
          fileError: 'Could not read the selected file.',
          clearError: true,
        );
        return;
      }

      // Validate extension.
      final ext = file.extension?.toLowerCase() ?? '';
      if (!ApiConstants.supportedFileExtensions.contains(ext)) {
        state = state.copyWith(
          fileError:
              'Unsupported file type ".$ext". Please select a ${ApiConstants.supportedFileExtensions.map((e) => '.$e').join(' or ')} file.',
          clearError: true,
        );
        return;
      }

      // Validate size.
      final size = file.size;
      if (size > ApiConstants.maxFileSizeBytes) {
        final maxMb = ApiConstants.maxFileSizeBytes / (1024 * 1024);
        state = state.copyWith(
          fileError:
              'File is too large (${(size / (1024 * 1024)).toStringAsFixed(1)} MB). Maximum allowed size is ${maxMb.toStringAsFixed(0)} MB.',
          clearError: true,
        );
        return;
      }

      // Derive a default title from the file name (without extension).
      final nameWithoutExt = file.name.replaceAll(RegExp(r'\.[^.]+$'), '');

      state = UploadState(
        selectedFile: path,
        fileName: file.name,
        fileSize: size,
        fileExtension: ext,
        title: nameWithoutExt,
        year: state.year,
      );
    } catch (e) {
      state = state.copyWith(
        fileError: 'Failed to pick file: ${e.toString()}',
        clearError: true,
      );
    }
  }

  // ---- Form editing ----

  void setTitle(String value) {
    state = state.copyWith(title: value, clearError: true);
  }

  void setYear(int value) {
    state = state.copyWith(year: value, clearError: true);
  }

  // ---- Upload ----

  /// Sends the selected file to POST /api/upload-document as multipart
  /// form data. Returns the [UploadResult] on success, or sets the error
  /// in the state on failure.
  Future<UploadResult?> upload() async {
    if (!state.isFormValid || state.isUploading) return null;

    state = state.copyWith(
      isUploading: true,
      clearError: true,
      clearResult: true,
    );

    final storage = _ref.read(secureStorageServiceProvider);
    final useLocalAi = await storage.getUseLocalAi();

    if (useLocalAi) {
      try {
        final localDocs = _ref.read(localDocumentsServiceProvider);
        final uploadResult = await localDocs.ingestDocument(
          filePath: state.selectedFile!,
          title: state.title,
          year: state.year,
        );
        state = state.copyWith(isUploading: false, result: uploadResult);
        return uploadResult;
      } catch (e) {
        state = state.copyWith(isUploading: false, error: e.toString());
        return null;
      }
    }

    final serverUrl = await storage.getServerUrl();
    final apiKey = await storage.getApiKey();

    if (serverUrl == null ||
        serverUrl.isEmpty ||
        apiKey == null ||
        apiKey.isEmpty) {
      state = state.copyWith(
        isUploading: false,
        error: 'Server not configured. Please check your settings.',
      );
      return null;
    }

    String baseUrl = serverUrl.trim();
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 120),
        headers: {'X-API-Key': apiKey, 'Accept': 'application/json'},
      ),
    );

    try {
      final file = File(state.selectedFile!);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: state.fileName,
        ),
        'title': state.title,
        'year': state.year.toString(),
      });

      final response = await dio.post<Map<String, dynamic>>(
        '/api/upload-document',
        data: formData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final uploadResult = UploadResult.fromJson(response.data!);
        state = state.copyWith(isUploading: false, result: uploadResult);
        return uploadResult;
      } else {
        state = state.copyWith(
          isUploading: false,
          error: 'Unexpected response: ${response.statusCode}',
        );
        return null;
      }
    } on DioException catch (e) {
      final apiError = ApiException.fromDioException(e);
      state = state.copyWith(isUploading: false, error: apiError.message);
      return null;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: 'Upload failed: ${e.toString()}',
      );
      return null;
    }
  }

  // ---- Reset ----

  /// Resets the notifier back to its initial state.
  void reset() {
    state = const UploadState();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Provides the [UploadNotifier] and its [UploadState].
final uploadProvider = StateNotifierProvider<UploadNotifier, UploadState>((
  ref,
) {
  return UploadNotifier(ref);
});
