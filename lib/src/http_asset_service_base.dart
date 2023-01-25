import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:path_provider/path_provider.dart';

class HttpAssetService {
  final HttpClient http;
  List<String> endpoints;

  String? currentEndpoint;
  String? currentZipFilePath;
  String? currentDesitinationDirPath;

  HttpAssetService({required this.http, required this.endpoints});

  Future<File> _downloadFile(String url, String filename) async {
    var request = await http.getUrl(Uri.parse(url));
    var response = await request.close();
    var bytes = await consolidateHttpClientResponseBytes(response);
    String dir = (await getApplicationDocumentsDirectory()).path;
    File file = File('$dir/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  _extractWithProgress() async {
    if (!_hasGoodConfigs()) {
      return;
    }

    final zipFile = File(currentZipFilePath!);
    final destinationDir = Directory(currentDesitinationDirPath!);

    try {
      await ZipFile.extractToDirectory(
          zipFile: zipFile,
          destinationDir: destinationDir,
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

  _hasGoodConfigs() {
    if (currentZipFilePath == null || currentEndpoint == null) {
      return false;
    }

    return true;
  }

  void downloadAndExtract() {
    if (endpoints.isEmpty) {
      return;
    }

    currentEndpoint = endpoints.first;
    currentZipFilePath = currentEndpoint!.split('/').last;
    currentDesitinationDirPath = currentZipFilePath!.split('.').first;

    _downloadFile(currentEndpoint!, currentZipFilePath!).then((file) {
      _extractWithProgress();
    });
  }
}
