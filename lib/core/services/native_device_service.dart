// NativeDeviceService — Cầu nối Dart ↔ Android Native qua MethodChannel
//
// Đây là implementation thực tế của Part 7 bài giảng:
// "Platform Channels & Native Interoperability"
//
// Channel name: "vn.edu.vku/device_info"
// Pattern: MethodChannel (Request-Response / Async RPC)
//
// Sử dụng Riverpod Provider để inject vào UI layer.
// Bắt PlatformException an toàn — trả giá trị mặc định khi chạy trên
// emulator hoặc platform không hỗ trợ.
library;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thông tin phần cứng thiết bị từ Android Native
class DeviceInfo {
  const DeviceInfo({
    required this.model,
    required this.manufacturer,
    required this.brand,
    required this.androidVersion,
    required this.sdkInt,
    required this.product,
    required this.hardware,
    required this.totalRamMB,
    required this.availRamMB,
    required this.securityPatch,
  });

  final String model;
  final String manufacturer;
  final String brand;
  final String androidVersion;
  final String sdkInt;
  final String product;
  final String hardware;
  final String totalRamMB;
  final String availRamMB;
  final String securityPatch;

  /// Parse từ Map trả về từ Kotlin qua MethodChannel
  factory DeviceInfo.fromMap(Map<Object?, Object?> map) {
    return DeviceInfo(
      model: (map['model'] as String?) ?? 'Unknown',
      manufacturer: (map['manufacturer'] as String?) ?? 'Unknown',
      brand: (map['brand'] as String?) ?? 'Unknown',
      androidVersion: (map['androidVersion'] as String?) ?? 'Unknown',
      sdkInt: (map['sdkInt'] as String?) ?? '0',
      product: (map['product'] as String?) ?? 'Unknown',
      hardware: (map['hardware'] as String?) ?? 'Unknown',
      totalRamMB: (map['totalRamMB'] as String?) ?? '0',
      availRamMB: (map['availRamMB'] as String?) ?? '0',
      securityPatch: (map['securityPatch'] as String?) ?? 'N/A',
    );
  }

  /// RAM hiển thị dạng GB cho dễ đọc
  String get totalRamFormatted {
    final mb = int.tryParse(totalRamMB) ?? 0;
    if (mb >= 1024) {
      return '${(mb / 1024).toStringAsFixed(1)} GB';
    }
    return '$mb MB';
  }

  String get availRamFormatted {
    final mb = int.tryParse(availRamMB) ?? 0;
    if (mb >= 1024) {
      return '${(mb / 1024).toStringAsFixed(1)} GB';
    }
    return '$mb MB';
  }

  @override
  String toString() =>
      'DeviceInfo(model: $model, android: $androidVersion, sdk: $sdkInt, ram: $totalRamFormatted)';
}

/// Service giao tiếp với Android native qua MethodChannel.
///
/// Tất cả method đều async vì Platform Channel truyền message
/// qua binary messenger — kết quả trả về từ native thread.
///
/// Xử lý PlatformException để tránh crash khi chạy trên:
/// - Emulator không có battery service
/// - Unit test không có native binding
/// - iOS (nếu sau này mở rộng)
class NativeDeviceService {
  NativeDeviceService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('vn.edu.vku/device_info');

  final MethodChannel _channel;

  /// Đọc mức pin hiện tại (0-100).
  /// Trả về -1 nếu không đọc được (emulator, quyền bị từ chối).
  Future<int> getBatteryLevel() async {
    try {
      final int level = await _channel.invokeMethod('getBatteryLevel');
      return level;
    } on PlatformException catch (_) {
      // Trên emulator hoặc thiết bị không hỗ trợ → trả -1
      return -1;
    } on MissingPluginException catch (_) {
      // Khi chạy unit test không có native binding
      return -1;
    }
  }

  /// Lấy thông tin phần cứng thiết bị từ Android Build API.
  /// Trả về null nếu gọi native thất bại.
  Future<DeviceInfo?> getDeviceInfo() async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getDeviceInfo',
      );
      if (result == null) return null;
      return DeviceInfo.fromMap(result);
    } on PlatformException catch (_) {
      return null;
    } on MissingPluginException catch (_) {
      return null;
    }
  }

  /// Kích hoạt rung phản hồi xúc giác (haptic feedback) native.
  /// Dùng sau khi OCR phân tích thành công để phản hồi người dùng.
  /// Im lặng nếu thiết bị không hỗ trợ rung.
  Future<void> triggerHaptic() async {
    try {
      await _channel.invokeMethod('triggerHaptic');
    } on PlatformException catch (_) {
      // Thiết bị không hỗ trợ rung — bỏ qua
    } on MissingPluginException catch (_) {
      // Unit test — bỏ qua
    }
  }
}

// ===== RIVERPOD PROVIDERS =====

/// Provider cho NativeDeviceService singleton
final nativeDeviceServiceProvider = Provider<NativeDeviceService>((ref) {
  return NativeDeviceService();
});

/// FutureProvider để UI tự động fetch và cache thông tin pin
final batteryLevelProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(nativeDeviceServiceProvider);
  return service.getBatteryLevel();
});

/// FutureProvider để UI tự động fetch và cache thông tin thiết bị
final deviceInfoProvider = FutureProvider<DeviceInfo?>((ref) async {
  final service = ref.watch(nativeDeviceServiceProvider);
  return service.getDeviceInfo();
});
