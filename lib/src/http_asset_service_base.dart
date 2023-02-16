import 'dart:io';

import 'package:flutter_archive/flutter_archive.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/subjects.dart';

class HttpAssetService {
  final String fileDirectory;
  final String filename;
  final String destinationDirectory;
  final Future<http.StreamedResponse> Function() httpRequest;
  final Function(double)? extractionProgressCallback;
  final Function(double)? downloadProgressCallback;
  final isDownloaded$ = BehaviorSubject<bool>.seeded(false);
  File? file;
  final List<int> _bytes = [];

  String get filePath => '$fileDirectory/$filename';

  HttpAssetService({
    required this.httpRequest,
    required this.fileDirectory,
    required this.filename,
    required this.destinationDirectory,
    this.downloadProgressCallback,
    this.extractionProgressCallback,
  }) {
    isDownloaded$.distinct().listen((value) {
      if (value) {
        extractWithProgress();
      }
    });
  }

  Future<void> downloadFile() async {
    isDownloaded$.add(false);

    final response = await httpRequest();
    final int? total = response.contentLength;
    if (total == null) {
      return;
    }

    double progressTracker = total / 100;

    response.stream.listen((value) async {
      _bytes.addAll(value);

      if (downloadProgressCallback != null) {
        if (_bytes.length >= progressTracker) {
          downloadProgressCallback!(_bytes.length / total * 100);
          progressTracker += progressTracker;
        }
      }
    }).onDone(() async {
      file = File(filePath);
      await file!.writeAsBytes(_bytes);
      isDownloaded$.add(true);
    });
  }

  Future<void> extractWithProgress() async {
    try {
      await ZipFile.extractToDirectory(
        zipFile: file!,
        destinationDir: Directory(destinationDirectory),
        onExtracting: (zipEntry, progress) {
          if (extractionProgressCallback != null) {
            extractionProgressCallback!(progress);
          }
          // print('progress: ${progress.toStringAsFixed(1)}%');
          // print('name: ${zipEntry.name}');
          // print('isDirectory: ${zipEntry.isDirectory}');
          // print(
          //     'modificationDate: ${zipEntry.modificationDate?.toLocal().toIso8601String()}');
          // print('uncompressedSize: ${zipEntry.uncompressedSize}');
          // print('compressedSize: ${zipEntry.compressedSize}');
          // print('compressionMethod: ${zipEntry.compressionMethod}');
          // print('crc: ${zipEntry.crc}');
          return ZipFileOperation.includeItem;
        },
      );

      if (file != null) {
        await file!.delete();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> downloadAndExtract() async {
    if (await Directory(destinationDirectory).exists()) {
      await Directory(destinationDirectory).delete(recursive: true);
    }

    await downloadFile();
  }
}
