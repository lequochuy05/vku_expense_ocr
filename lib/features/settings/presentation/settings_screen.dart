// Màn hình cài đặt — theme, ngân sách, API Gemini, thông tin thiết bị, xóa dữ liệu
// Tích hợp Platform Channel (Part 7) hiển thị thông tin phần cứng native
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/native_device_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/repositories/expense_repository_impl.dart';

class BudgetNotifier extends StateNotifier<int> {
  BudgetNotifier() : super(0);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(AppConstants.prefMonthlyBudget) ?? 0;
  }

  Future<void> setBudget(int amount) async {
    state = amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefMonthlyBudget, amount);
  }
}

final budgetNotifierProvider =
    StateNotifierProvider<BudgetNotifier, int>((ref) {
  return BudgetNotifier();
});

class GeminiApiKeyNotifier extends StateNotifier<String> {
  GeminiApiKeyNotifier() : super('');

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(AppConstants.prefGeminiApiKey) ?? '';
  }

  Future<void> setKey(String key) async {
    state = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefGeminiApiKey, key);
  }
}

final geminiApiKeyNotifierProvider =
    StateNotifierProvider<GeminiApiKeyNotifier, String>((ref) {
  return GeminiApiKeyNotifier();
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(budgetNotifierProvider.notifier).load();
      ref.read(geminiApiKeyNotifierProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeNotifierProvider);
    final budget = ref.watch(budgetNotifierProvider);
    final apiKey = ref.watch(geminiApiKeyNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          // --- GIAO DIỆN ---
          const _SectionHeader(title: 'Giao diện'),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Chế độ hiển thị'),
            subtitle: Text(_themeLabel(themeMode)),
            onTap: () => _showThemePicker(context),
          ),

          // --- NGÂN SÁCH ---
          const _SectionHeader(title: 'Ngân sách'),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Ngân sách tháng'),
            subtitle: Text(
              budget > 0
                  ? CurrencyFormatter.format(budget)
                  : 'Chưa thiết lập',
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _editBudget(context, budget),
          ),

          // --- CẤU HÌNH AI ---
          const _SectionHeader(title: 'Cấu hình AI (Gemini)'),
          ListTile(
            leading: Icon(
              Icons.psychology_outlined,
              color: apiKey.isNotEmpty ? Colors.green : Colors.grey,
            ),
            title: const Text('Gemini API Key'),
            subtitle: Text(
              apiKey.isEmpty
                  ? 'Chưa cấu hình — AI Advisor không khả dụng'
                  : '✅ Đã cấu hình (${apiKey.length} ký tự)',
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _editApiKey(context, apiKey),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              '⚠ API key được lưu cục bộ trên thiết bị. '
              'Không chia sẻ với ai. '
              'Xét sử dụng backend proxy trong môi trường sản xuất.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ),

          // --- DỮ LIỆU ---
          const _SectionHeader(title: 'Dữ liệu'),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined,
                color: Colors.red),
            title: const Text('Xóa tất cả dữ liệu'),
            subtitle: const Text('Không thể hoàn tác!'),
            onTap: _confirmClearAll,
          ),

          // --- THÔNG TIN ---
          const _SectionHeader(title: 'Thông tin ứng dụng'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Phiên bản'),
            subtitle: Text(AppConstants.appVersion),
          ),
          const ListTile(
            leading: Icon(Icons.school_outlined),
            title: Text('Tên ứng dụng'),
            subtitle: Text('VKU Expense AI — Đẳng cấp VKU'),
          ),

          // --- THÔNG TIN THIẾT BỊ (Platform Channel - Part 7) ---
          // Sử dụng MethodChannel("vn.edu.vku/device_info") gọi native Kotlin
          // để lấy thông tin phần cứng thực tế từ Android OS
          const _SectionHeader(title: 'Thông tin thiết bị (Native Bridge)'),
          _buildBatteryTile(),
          _buildDeviceInfoTile(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'Sáng (Light)',
      ThemeMode.dark => 'Tối (Dark)',
      ThemeMode.system => 'Theo hệ thống',
    };
  }

  void _showThemePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          const Text('Chế độ hiển thị',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...ThemeMode.values.map(
            (mode) {
              final isSelected = ref.read(themeModeNotifierProvider) == mode;
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                ),
                title: Text(_themeLabel(mode)),
                onTap: () {
                  ref
                      .read(themeModeNotifierProvider.notifier)
                      .setThemeMode(mode);
                  Navigator.of(ctx).pop();
                },
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _editBudget(
      BuildContext context, int currentBudget) async {
    final controller = TextEditingController(
      text: currentBudget > 0 ? currentBudget.toString() : '',
    );
    final result = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thiết lập ngân sách tháng'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Số tiền (VND)',
            suffixText: '₫',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = int.tryParse(controller.text);
              Navigator.of(ctx).pop(amount);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result != null && result >= 0) {
      await ref.read(budgetNotifierProvider.notifier).setBudget(result);
    }
  }

  Future<void> _editApiKey(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gemini API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'AIza...',
              ),
              obscureText: true,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            const Text(
              'Lấy API key miễn phí tại: ai.google.dev',
              style: TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result != null) {
      await ref.read(geminiApiKeyNotifierProvider.notifier).setKey(result);
    }
  }

  /// Widget hiển thị mức pin từ native Android BatteryManager
  /// Gọi qua MethodChannel("vn.edu.vku/device_info") → getBatteryLevel
  Widget _buildBatteryTile() {
    final batteryAsync = ref.watch(batteryLevelProvider);
    return batteryAsync.when(
      data: (level) {
        final icon = level > 80
            ? Icons.battery_full
            : level > 50
                ? Icons.battery_5_bar
                : level > 20
                    ? Icons.battery_3_bar
                    : Icons.battery_1_bar;
        final color = level > 20 ? Colors.green : Colors.red;
        return ListTile(
          leading: Icon(icon, color: color),
          title: const Text('Mức pin (Native)'),
          subtitle: Text(
            level >= 0
                ? '$level% ${level < 15 ? "⚠ Pin yếu — hạn chế quét OCR" : ""}'
                : 'Không đọc được mức pin',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: () => ref.invalidate(batteryLevelProvider),
          ),
        );
      },
      loading: () => const ListTile(
        leading: Icon(Icons.battery_unknown),
        title: Text('Mức pin (Native)'),
        subtitle: Text('Đang đọc...'),
      ),
      error: (_, __) => const ListTile(
        leading: Icon(Icons.battery_unknown, color: Colors.grey),
        title: Text('Mức pin (Native)'),
        subtitle: Text('Không thể đọc mức pin'),
      ),
    );
  }

  /// Widget hiển thị thông tin phần cứng thiết bị từ native Android Build API
  /// Gọi qua MethodChannel("vn.edu.vku/device_info") → getDeviceInfo
  Widget _buildDeviceInfoTile() {
    final deviceAsync = ref.watch(deviceInfoProvider);
    return deviceAsync.when(
      data: (info) {
        if (info == null) {
          return const ListTile(
            leading: Icon(Icons.phone_android, color: Colors.grey),
            title: Text('Thông tin thiết bị'),
            subtitle: Text('Không lấy được thông tin'),
          );
        }
        return ExpansionTile(
          leading: const Icon(Icons.phone_android),
          title: Text('${info.manufacturer} ${info.model}'),
          subtitle: Text('Android ${info.androidVersion} (SDK ${info.sdkInt})'),
          children: [
            _infoRow('Nhà sản xuất', info.manufacturer),
            _infoRow('Model', info.model),
            _infoRow('Android', info.androidVersion),
            _infoRow('SDK Level', info.sdkInt),
            _infoRow('Hardware', info.hardware),
            _infoRow('Product', info.product),
            _infoRow('RAM Tổng', info.totalRamFormatted),
            _infoRow('RAM Khả dụng', info.availRamFormatted),
            _infoRow('Security Patch', info.securityPatch),
            const SizedBox(height: 8),
          ],
        );
      },
      loading: () => const ListTile(
        leading: Icon(Icons.phone_android),
        title: Text('Thông tin thiết bị'),
        subtitle: Text('Đang đọc từ native...'),
      ),
      error: (_, __) => const ListTile(
        leading: Icon(Icons.phone_android, color: Colors.grey),
        title: Text('Thông tin thiết bị'),
        subtitle: Text('Lỗi kết nối native bridge'),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tất cả dữ liệu?'),
        content: const Text(
          'Hành động này sẽ xóa toàn bộ lịch sử giao dịch và không thể hoàn tác!\n\n'
          'Nhập XÓA để xác nhận.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('XÓA TẤT CẢ'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      await ref.read(expenseRepositoryProvider).clearAll();
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã xóa toàn bộ dữ liệu')),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
