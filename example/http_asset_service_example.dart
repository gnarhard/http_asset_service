import 'dart:io';

import 'package:http_asset_service/http_asset_service.dart';

void main() {
  final http = HttpClient();
  final httpAssetService = HttpAssetService(
      http: http, endpoints: ['https://wearegigabull.com/api/v1/game_assets']);

  httpAssetService.downloadAndExtract();
}
