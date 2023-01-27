import 'dart:io';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_archive/flutter_archive.dart';
import 'package:http/http.dart' as http;

class HttpAssetService {
  final String zipFileDir;
  final String zipFilename;
  final String destinationDir;
  final Future<http.StreamedResponse> Function() httpRequest;
  final Function(double)? progressCallback;

  String get zipFilePath => '$zipFileDir/$zipFilename';

  final List<int> _bytes = [];

  HttpAssetService({
    required this.httpRequest,
    required this.zipFileDir,
    required this.zipFilename,
    required this.destinationDir,
    this.progressCallback,
  });

  Future<File> downloadFile() async {
    final response = await httpRequest();
    final int? total = response.contentLength;
    response.stream.listen((value) {
      _bytes.addAll(value);
      if (progressCallback != null) {
        progressCallback!(value.length / total!);
      }
    });
    File file = File(zipFilePath);
    await compute(file.writeAsBytes, _bytes);
    return file;
  }

  extractWithProgress(File zipFile) async {
    try {
      await ZipFile.extractToDirectory(
        zipFile: zipFile,
        destinationDir: Directory(destinationDir),
        onExtracting: (zipEntry, progress) {
          if (progressCallback != null) {
            progressCallback!(progress);
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
    } catch (e) {
      print(e);
    }
  }

  Future<void> downloadAndExtract() async {
    if (await Directory(destinationDir).exists()) {
      await Directory(destinationDir).delete(recursive: true);
    }

    await downloadFile().then((file) async {
      await extractWithProgress(file);
      await file.delete();
    });
  }
}
