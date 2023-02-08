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

  String get filePath => '$fileDirectory/$filename';

  final List<int> _bytes = [];

  HttpAssetService({
    required this.httpRequest,
    required this.fileDirectory,
    required this.filename,
    required this.destinationDirectory,
    this.downloadProgressCallback,
    this.extractionProgressCallback,
  });

  Future<File> downloadFile() async {
    final response = await httpRequest();
    final int? total = response.contentLength;

    // response.stream.listen((value) async {
    //   _bytes.addAll(value);
    //   if (downloadProgressCallback != null) {
    //     downloadProgressCallback!(_bytes.length / total! * 100);
    //   }
    // }, onDone: () async {});

    final file = File(filePath);
    await file.writeAsBytes(_bytes);

    return file;
  }

  Future<void> extractWithProgress(File file) async {
    try {
      await ZipFile.extractToDirectory(
        zipFile: file,
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
    } catch (e) {
      print(e);
    }
  }

  Future<void> downloadAndExtract() async {
    if (await Directory(destinationDirectory).exists()) {
      await Directory(destinationDirectory).delete(recursive: true);
    }

    final file = await downloadFile();
    await extractWithProgress(file);
    await file.delete();
  }
}
