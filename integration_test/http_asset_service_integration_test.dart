import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http_asset_service/http_asset_service.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:http_asset_service/src/empty_app.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('HttpAssetService', () {
    late HttpAssetService service;

    http.StreamedResponse? httpResponse;
    double downloadProgress = 0;
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

      service = HttpAssetService(
        httpRequest: () => Future.value(httpResponse),
        fileDirectory: (await getApplicationDocumentsDirectory()).path,
        filename: 'test.zip',
        destinationDirectory: '/dest',
        downloadProgressCallback: (progress) => downloadProgress = progress,
      );
    });

    tearDown(() async {
      File zipFile = File(service.filePath);
      if (await zipFile.exists()) {
        zipFile.delete();
      }
      // remove the test directory created
      final dir = Directory(service.fileDirectory);
      if (await dir.exists()) {
        dir.delete(recursive: true);
      }
    });

    testWidgets('files can be downloaded', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final file = await service.downloadFile();

      expect(file, isNotNull);
      expect(await file.exists(), true);
      expect(downloadProgress, 100);
    });
  });
}
