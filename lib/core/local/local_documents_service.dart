import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../database/app_database.dart';
import '../models/citation.dart';
import '../models/document.dart' as core_model;
import '../models/upload_result.dart';

class LocalChunkHit {
  const LocalChunkHit({
    required this.document,
    required this.section,
    required this.content,
    required this.score,
  });

  final String document;
  final String section;
  final String content;
  final double score;
}

class LocalDocumentsService {
  LocalDocumentsService(this._db);

  final AppDatabase _db;
  final Random _random = Random();

  Future<List<core_model.Document>> getDocuments() async {
    final rows = await _db.getAllDocuments();
    return rows
        .map(
          (row) => core_model.Document(
            id: row.id,
            title: row.title,
            year: row.year,
            sectionCount: row.sectionCount,
            createdAt: row.createdAt,
          ),
        )
        .toList();
  }

  Future<void> deleteDocument(String id) => _db.deleteDocument(id);

  Future<int> getTotalChunkCount() => _db.getTotalChunkCount();

  Future<UploadResult> ingestDocument({
    required String filePath,
    required String title,
    required int year,
  }) async {
    final source = File(filePath);
    if (!await source.exists()) {
      throw Exception('Selected file not found.');
    }

    final text = await _extractText(source);
    if (text.trim().isEmpty) {
      throw Exception('Could not extract readable text from this file.');
    }

    final chunkTexts = _chunkText(text);
    if (chunkTexts.isEmpty) {
      throw Exception('No valid content was extracted from this file.');
    }

    final documentId = _newId();
    final createdAt = DateTime.now();

    await _db.insertDocument(
      DocumentsCompanion(
        id: Value(documentId),
        title: Value(title),
        year: Value(year),
        sectionCount: Value(chunkTexts.length),
        createdAt: Value(createdAt),
      ),
    );

    final chunkRows = <ChunksCompanion>[];
    for (var i = 0; i < chunkTexts.length; i++) {
      chunkRows.add(
        ChunksCompanion(
          id: Value(_newId()),
          documentId: Value(documentId),
          documentTitle: Value(title),
          year: Value(year),
          section: Value('Section ${i + 1}'),
          content: Value(chunkTexts[i]),
        ),
      );
    }

    await _db.insertChunks(chunkRows);

    return UploadResult(
      id: documentId,
      title: title,
      year: year,
      chunksIndexed: chunkTexts.length,
      strategy: 'fixed_size',
    );
  }

  Future<List<LocalChunkHit>> searchChunks(String query, {int topK = 3}) async {
    final allChunks = await _db.getAllChunks();
    if (allChunks.isEmpty) return const <LocalChunkHit>[];

    final queryTokens = _tokenize(query);
    if (queryTokens.isEmpty) return const <LocalChunkHit>[];

    final scored = <LocalChunkHit>[];

    for (final chunk in allChunks) {
      final score = _scoreChunk(queryTokens, chunk.content);
      if (score <= 0) continue;
      scored.add(
        LocalChunkHit(
          document: chunk.documentTitle,
          section: chunk.section,
          content: chunk.content,
          score: score,
        ),
      );
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(topK).toList(growable: false);
  }

  Future<List<LocalChunkHit>> getChunksForCitations(
    List<Citation> citations, {
    int topK = 3,
  }) async {
    if (citations.isEmpty) return const <LocalChunkHit>[];

    final allChunks = await _db.getAllChunks();
    if (allChunks.isEmpty) return const <LocalChunkHit>[];

    final ordered = <LocalChunkHit>[];

    for (final citation in citations) {
      Chunk? match;
      for (final chunk in allChunks) {
        if (chunk.documentTitle == citation.document &&
            chunk.section == citation.section) {
          match = chunk;
          break;
        }
      }
      if (match == null) continue;

      ordered.add(
        LocalChunkHit(
          document: match.documentTitle,
          section: match.section,
          content: match.content,
          score: 1.0,
        ),
      );

      if (ordered.length >= topK) {
        break;
      }
    }

    return ordered;
  }

  Future<String> _extractText(File source) async {
    final extension = source.path.split('.').last.toLowerCase();
    if (extension == 'txt') {
      return source.readAsString();
    }

    if (extension == 'pdf') {
      final bytes = await source.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      try {
        final extractor = PdfTextExtractor(document);
        return extractor.extractText();
      } finally {
        document.dispose();
      }
    }

    throw Exception('Unsupported file type. Only PDF and TXT are supported.');
  }

  List<String> _chunkText(String rawText) {
    final text = rawText.replaceAll('\r\n', '\n').trim();
    if (text.isEmpty) return const <String>[];

    const int chunkSize = 900;
    const int overlap = 140;
    final chunks = <String>[];
    var cursor = 0;

    while (cursor < text.length) {
      final end = min(cursor + chunkSize, text.length);
      final chunk = text.substring(cursor, end).trim();
      if (chunk.length >= 40) {
        chunks.add(chunk);
      }
      if (end >= text.length) break;
      cursor = max(0, end - overlap);
    }

    return chunks;
  }

  Set<String> _tokenize(String input) {
    return input
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.length >= 3)
        .toSet();
  }

  double _scoreChunk(Set<String> queryTokens, String content) {
    final body = content.toLowerCase();
    var hits = 0;
    for (final token in queryTokens) {
      if (body.contains(token)) {
        hits++;
      }
    }
    if (hits == 0) return 0;

    final lengthPenalty = max(1, body.length / 500.0);
    return hits / lengthPenalty;
  }

  String _newId() {
    final micros = DateTime.now().microsecondsSinceEpoch;
    final salt = _random.nextInt(1 << 32);
    return '$micros-$salt';
  }
}

final localDocumentsServiceProvider = Provider<LocalDocumentsService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalDocumentsService(db);
});
