import 'dart:io';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_archive/flutter_archive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class HttpAssetService {
  final String zipFilePath;
  final String zipFilename;
  final Future<http.Response> Function() httpRequest;

  HttpAssetService({
    required this.httpRequest,
    required this.zipFilePath,
    required this.zipFilename,
  });

  Future<File> _downloadFile() async {
    final response = await httpRequest();
    String dir = (await getApplicationDocumentsDirectory()).path;
    File file = File('$dir/$zipFilename');
    await compute(file.writeAsBytes, response.bodyBytes);
    return file;
  }

  _extractWithProgress() async {
    final zipFile = File(zipFilePath);

    try {
      await ZipFile.extractToDirectory(
          zipFile: zipFile,
          destinationDir: await getApplicationDocumentsDirectory(),
          onExtracting: (zipEntry, progress) {
            print('progress: ${progress.toStringAsFixed(1)}%');
            print('name: ${zipEntry.name}');
            print('isDirectory: ${zipEntry.isDirectory}');
            print(
                'modificationDate: ${zipEntry.modificationDate?.toLocal().toIso8601String()}');
            print('uncompressedSize: ${zipEntry.uncompressedSize}');
            print('compressedSize: ${zipEntry.compressedSize}');
            print('compressionMethod: ${zipEntry.compressionMethod}');
            print('crc: ${zipEntry.crc}');
            return ZipFileOperation.includeItem;
          });
    } catch (e) {
      print(e);
    }
  }

  Future<void> downloadAndExtract() async {
    // todo: compute()?
    await _downloadFile().then((file) {
      _extractWithProgress();
    });
  }
}
