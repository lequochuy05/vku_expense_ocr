// Service kiểm tra kết nối mạng
// Được dùng trước khi gọi Gemini API
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service kiểm tra trạng thái kết nối mạng
class ConnectivityService {
  ConnectivityService(this._connectivity);

  final Connectivity _connectivity;

  /// Kiểm tra có kết nối mạng không (không cần thiết là internet)
  Future<bool> hasConnection() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
  }

  /// Stream theo dõi thay đổi kết nối
  Stream<bool> get connectionStream => _connectivity.onConnectivityChanged.map(
        (results) => results.any((r) =>
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.ethernet),
      );
}

final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

final connectivityServiceProvider = Provider<ConnectivityService>((ref) =>
    ConnectivityService(ref.watch(connectivityProvider)));
