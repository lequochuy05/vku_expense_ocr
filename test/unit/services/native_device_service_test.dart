// Unit tests cho NativeDeviceService — Platform Channel mock
//
// Kiểm thử cầu nối MethodChannel mà không cần thiết bị Android thật.
// Sử dụng TestDefaultBinaryMessengerBinding để giả lập native response.
//
// Đây là minh họa kỹ thuật mock Platform Channel theo Part 7 bài giảng.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vku_expense_ocr/core/services/native_device_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Tên kênh phải khớp chính xác với native side
  const channelName = 'vn.edu.vku/device_info';
  late MethodChannel channel;
  late NativeDeviceService service;

  setUp(() {
    channel = const MethodChannel(channelName);
    service = NativeDeviceService(channel: channel);
  });

  group('NativeDeviceService Platform Channel Tests', () {
    test('getBatteryLevel trả về mức pin từ native', () async {
      // Giả lập native handler trả về 85%
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getBatteryLevel') {
          return 85;
        }
        return null;
      });

      final level = await service.getBatteryLevel();
      expect(level, 85);

      // Dọn dẹp handler
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('getBatteryLevel trả về -1 khi native ném PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getBatteryLevel') {
          throw PlatformException(
            code: 'UNAVAILABLE',
            message: 'Không thể đọc mức pin.',
          );
        }
        return null;
      });

      final level = await service.getBatteryLevel();
      expect(level, -1); // Graceful degradation

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('getDeviceInfo trả về thông tin thiết bị từ native Map', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getDeviceInfo') {
          return <String, String>{
            'model': 'Pixel 7',
            'manufacturer': 'Google',
            'brand': 'google',
            'androidVersion': '14',
            'sdkInt': '34',
            'product': 'panther',
            'hardware': 'tensor',
            'totalRamMB': '8192',
            'availRamMB': '4096',
            'securityPatch': '2026-09-01',
          };
        }
        return null;
      });

      final info = await service.getDeviceInfo();
      expect(info, isNotNull);
      expect(info!.model, 'Pixel 7');
      expect(info.manufacturer, 'Google');
      expect(info.androidVersion, '14');
      expect(info.sdkInt, '34');
      expect(info.totalRamFormatted, '8.0 GB');
      expect(info.availRamFormatted, '4.0 GB');

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('getDeviceInfo trả về null khi native không khả dụng', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getDeviceInfo') {
          throw PlatformException(
            code: 'UNAVAILABLE',
            message: 'Thiết bị không hỗ trợ.',
          );
        }
        return null;
      });

      final info = await service.getDeviceInfo();
      expect(info, isNull); // Graceful degradation

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('triggerHaptic gọi native method mà không ném exception', () async {
      bool hapticCalled = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'triggerHaptic') {
          hapticCalled = true;
          return true;
        }
        return null;
      });

      // Không ném exception
      await service.triggerHaptic();
      expect(hapticCalled, isTrue);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('triggerHaptic im lặng khi thiết bị không hỗ trợ rung', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'triggerHaptic') {
          throw PlatformException(
            code: 'NOT_SUPPORTED',
            message: 'Thiết bị không hỗ trợ rung.',
          );
        }
        return null;
      });

      // Không ném exception — graceful degradation
      await expectLater(service.triggerHaptic(), completes);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
  });

  group('DeviceInfo Model Tests', () {
    test('DeviceInfo.fromMap parse đầy đủ các trường', () {
      final map = <Object?, Object?>{
        'model': 'Samsung Galaxy S24',
        'manufacturer': 'Samsung',
        'brand': 'samsung',
        'androidVersion': '15',
        'sdkInt': '35',
        'product': 'dm3q',
        'hardware': 'exynos2400',
        'totalRamMB': '12288',
        'availRamMB': '6144',
        'securityPatch': '2026-10-01',
      };

      final info = DeviceInfo.fromMap(map);
      expect(info.model, 'Samsung Galaxy S24');
      expect(info.totalRamFormatted, '12.0 GB');
      expect(info.availRamFormatted, '6.0 GB');
    });

    test('DeviceInfo.fromMap xử lý Map với giá trị null', () {
      final map = <Object?, Object?>{
        'model': null,
        'manufacturer': null,
      };

      final info = DeviceInfo.fromMap(map);
      expect(info.model, 'Unknown');
      expect(info.manufacturer, 'Unknown');
      expect(info.totalRamMB, '0');
    });
  });
}
