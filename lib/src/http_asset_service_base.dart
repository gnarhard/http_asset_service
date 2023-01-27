import 'dart:io';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_archive/flutter_archive.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/subjects.dart';

class HttpAssetService {
  final String zipFileDir;
  final String zipFilename;
  final String destinationDir;
  final Future<http.StreamedResponse> Function() httpRequest;
  final Function(double)? extractionProgressCallback;
  final Function(double)? downloadProgressCallback;

  String get zipFilePath => '$zipFileDir/$zipFilename';

  final isdownloaded$ = BehaviorSubject<bool>.seeded(false);

  final List<int> _bytes = [];

  File? file;

  HttpAssetService({
    required this.httpRequest,
    required this.zipFileDir,
    required this.zipFilename,
    required this.destinationDir,
    this.downloadProgressCallback,
    this.extractionProgressCallback,
  }) {
    isdownloaded$.distinct().listen((value) {
      if (value) {
        extractWithProgress();
      }
    });
  }

  Future<void> downloadFile() async {
    isdownloaded$.add(false);

    final response = await httpRequest();
    final int? total = response.contentLength;
    response.stream.listen((value) async {
      _bytes.addAll(value);

      if (downloadProgressCallback != null) {
        downloadProgressCallback!(value.length / total! * 100);
      }
    }).onDone(() async {
      file = File(zipFilePath);
      await file!.writeAsBytes(_bytes);
      isdownloaded$.add(true);
    });
  }

  Future<void> extractWithProgress() async {
    print('here');
    try {
      await ZipFile.extractToDirectory(
        zipFile: file!,
        destinationDir: Directory(destinationDir),
        onExtracting: (zipEntry, progress) {
          if (extractionProgressCallback != null) {
            extractionProgressCallback!(progress);
          }
          print('progress: ${progress.toStringAsFixed(1)}%');
          print('name: ${zipEntry.name}');
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
    if (await Directory(destinationDir).exists()) {
      await Directory(destinationDir).delete(recursive: true);
    }

    await downloadFile();
  }
}
