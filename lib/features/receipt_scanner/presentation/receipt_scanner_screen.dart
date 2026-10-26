// Màn hình quét hóa đơn
// Camera/Gallery → ML Kit OCR → Review Screen
// Kiểm tra quyền, hiển thị trạng thái xử lý
// Tích hợp Platform Channel (Part 7): haptic feedback khi OCR xong,
// cảnh báo pin yếu trước khi quét
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../core/services/native_device_service.dart';
import '../../../routing/app_router.dart';
import '../domain/receipt_parser.dart';

class ReceiptScannerScreen extends ConsumerStatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  ConsumerState<ReceiptScannerScreen> createState() =>
      _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState
    extends ConsumerState<ReceiptScannerScreen> {
  final _imagePicker = ImagePicker();
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  File? _selectedImage;
  String? _statusMessage;
  bool _isProcessing = false;

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét hóa đơn'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hướng dẫn
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Hướng dẫn',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Chụp hoặc chọn ảnh hóa đơn\n'
                        '2. Ứng dụng sẽ nhận diện văn bản tự động\n'
                        '3. Kiểm tra và xác nhận thông tin trước khi lưu',
                        style: TextStyle(height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Xem trước ảnh
              if (_selectedImage != null)
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                        ),
                      ),
                      if (_isProcessing)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                    color: Colors.white),
                                SizedBox(height: 12),
                                Text(
                                  'Đang nhận diện văn bản...',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              if (_selectedImage == null)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chọn ảnh hóa đơn',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_statusMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _statusMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _statusMessage!.contains('Lỗi')
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Nút chụp ảnh
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _isProcessing ? null : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Thư viện'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _isProcessing ? null : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Chụp ảnh'),
                    ),
                  ),
                ],
              ),

              // Nút nhập tin nhắn chuyển khoản
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isProcessing ? null : _showTransferMessageDialog,
                icon: const Icon(Icons.message_outlined),
                label: const Text('Dán tin nhắn chuyển khoản'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    // Kiểm tra quyền
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          _showPermissionDialog('camera');
        }
        return;
      }
    }

    try {
      final xFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2048,
      );

      if (xFile == null) return; // Người dùng hủy

      setState(() {
        _selectedImage = File(xFile.path);
        _statusMessage = null;
      });

      await _processImage(File(xFile.path));
    } catch (e) {
      if (mounted) {
        setState(() =>
            _statusMessage = 'Lỗi chọn ảnh: $e');
      }
    }
  }

  /// Chạy ML Kit OCR và Regex parser
  /// Tích hợp Platform Channel (Part 7):
  /// - Rung phản hồi haptic khi OCR phân tích thành công
  /// - Cảnh báo pin yếu trước khi quét (ML Kit tiêu tốn pin)
  Future<void> _processImage(File imageFile) async {
    // Kiểm tra pin trước khi chạy OCR (ML Kit tiêu tốn CPU/GPU)
    // Sử dụng MethodChannel("vn.edu.vku/device_info") → getBatteryLevel
    final nativeService = ref.read(nativeDeviceServiceProvider);
    final batteryLevel = await nativeService.getBatteryLevel();
    if (batteryLevel >= 0 && batteryLevel < 15 && mounted) {
      // Pin dưới 15%: cảnh báo nhưng vẫn cho phép tiếp tục
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠ Pin yếu ($batteryLevel%) — OCR có thể tiêu tốn pin'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Đang nhận diện văn bản...';
    });

    try {
      // ML Kit chạy on-device, không cần internet
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final rawText = recognizedText.text;

      if (rawText.trim().isEmpty) {
        setState(() {
          _statusMessage =
              'Không nhận diện được văn bản trong ảnh này.\n'
              'Hãy chụp lại rõ hơn hoặc chọn ảnh khác.';
          _isProcessing = false;
        });
        return;
      }

      // Phân tích bằng Regex parser
      final ocrResult = ReceiptParser.parse(rawText);

      // Kích hoạt rung phản hồi xúc giác native (haptic feedback)
      // qua MethodChannel("vn.edu.vku/device_info") → triggerHaptic
      // Cho người dùng biết OCR đã hoàn thành thành công
      await nativeService.triggerHaptic();

      setState(() {
        _isProcessing = false;
        _statusMessage = 'Nhận diện thành công!';
      });

      // Chuyển sang Review screen (truyền qua extra, không qua URL)
      if (mounted) {
        context.push(AppRoutes.receiptReview, extra: ocrResult);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage =
              'Lỗi nhận diện: $e\nVui lòng thử lại.';
        });
      }
    }
  }

  void _showPermissionDialog(String type) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Không có quyền truy cập'),
        content: Text(
          'Ứng dụng cần quyền truy cập $type để quét hóa đơn.\n'
          'Vui lòng cấp quyền trong Cài đặt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('Mở Cài đặt'),
          ),
        ],
      ),
    );
  }

  void _showTransferMessageDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dán tin nhắn ngân hàng'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Dán nội dung tin nhắn chuyển khoản vào đây...\n\n'
                'Ví dụ: Bạn đã chuyển khoản thành công 250,000 VND...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.of(ctx).pop();
              if (text.isNotEmpty) {
                _processTransferMessage(text);
              }
            },
            child: const Text('Phân tích'),
          ),
        ],
      ),
    );
  }

  void _processTransferMessage(String message) {
    // Dùng ReceiptParser với thông tin chuyển khoản
    final result = ReceiptParser.parse(message);
    if (mounted) {
      context.push(AppRoutes.receiptReview, extra: result);
    }
  }
}
