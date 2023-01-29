import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:http/http.dart' as http;
import 'package:http_asset_service/http_asset_service.dart';
import 'package:test/test.dart';
import 'package:test_storage/test_storage.dart';

void main() {
  group('HttpAssetService', () {
    late HttpAssetService service;
    final String zipFileDir = Directory.current.path;
    final String zipFilename = 'test.zip';
    final String destinationDir = '$zipFileDir/dest';
    File zipFile = File('$zipFileDir/$zipFilename');

    http.StreamedResponse? httpResponse;
    double downloadProgress = 0;
    double extractionProgress = 0;
    const List<List<int>> fileBytes = [
      [1, 2, 3],
      [4, 5, 6],
    ];

    setUp(() async {
      WidgetsFlutterBinding.ensureInitialized();
      httpResponse = http.StreamedResponse(
        Stream.fromIterable(fileBytes),
        200,
        contentLength: 6,
      );
      downloadProgress = 0;
      extractionProgress = 0;

      service = HttpAssetService(
        httpRequest: () => Future.value(httpResponse),
        zipFileDir: zipFileDir,
        zipFilename: zipFilename,
        destinationDir: destinationDir,
        downloadProgressCallback: (progress) => downloadProgress = progress,
        extractionProgressCallback: (progress) => extractionProgress = progress,
      );
    });

    tearDown(() async {
      if (await zipFile.exists()) {
        zipFile.delete();
      }
      // remove the test directory created
      final dir = Directory(destinationDir);
      if (await dir.exists()) {
        dir.delete(recursive: true);
      }
    });

    test('downloadFile', () async {
      await service.downloadFile();

      await expectLater(
          service.isdownloaded$.stream, emitsInOrder([false, true]));
      expect(await zipFile.exists(), true);
      expect(downloadProgress, 100);
    });
  });
}
