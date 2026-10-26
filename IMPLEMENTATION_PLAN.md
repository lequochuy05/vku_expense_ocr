# IMPLEMENTATION PLAN — VKU Expense AI

> **Cập nhật lần cuối:** 2026-10-12 21:50 ICT  
> **Trạng thái tổng thể:** ✅ Đã hoàn thiện (Tất cả tính năng & Test 40/40 PASSED, Analyze 0 issues)

---

## Môi trường & Công cụ

| Thành phần | Phiên bản / Cấu hình | Trạng thái |
|---|---|---|
| OS | Linux (x86_64) | ✅ Hoàn thành |
| Java | OpenJDK 21.0.12.1 | ✅ Hoàn thành |
| Android SDK | API 34, 36 (Build Tools 34.0.0 → 37.0.0) | ✅ Hoàn thành |
| Android NDK | 28.2.13676358 (Installed in SDK) | ✅ Hoàn thành |
| Flutter SDK | 3.47.7 stable | ✅ Hoàn thành |
| Dart SDK | 3.13.5 (Bundled) | ✅ Hoàn thành |
| State Management | Flutter Riverpod 2 (pure idiomatic providers) | ✅ Hoàn thành |
| Navigation | GoRouter 14.6.2 (StatefulShellRoute with Bottom Nav) | ✅ Hoàn thành |
| Database | SQLite via sqflite 2.3.3 + sqflite_common_ffi for testing | ✅ Hoàn thành |

---

## Chi tiết các Increment

### Increment 0 — Thiết lập môi trường ✅
- [x] Kiểm tra OS Linux và kiến trúc máy tính
- [x] Cấu hình Java 21 OpenJDK
- [x] Khởi tạo Android SDK API 34/36 và chấp nhận licenses
- [x] Tải và giải nén Flutter 3.47.7 vào `/home/qhuy/flutter`
- [x] Tạo symlink cho `flutter` và `dart` vào PATH (`~/.local/bin`)
- [x] Chạy `flutter doctor -v` thành công

### Increment 1 — Project Scaffold & Dependencies ✅
- [x] Khởi tạo dự án Flutter `vku_expense_ocr`
- [x] Cấu hình `pubspec.yaml` với phiên bản tương thích Flutter 3.47:
  - `flutter_riverpod: ^2.5.1`
  - `go_router: ^14.6.2`
  - `sqflite: ^2.3.3`
  - `google_mlkit_text_recognition: ^0.13.1`
  - `image_picker: ^1.1.2`
  - `intl: ^0.19.0`
  - `http: ^1.2.2`
  - `sqflite_common_ffi: ^2.3.3` (dev)
  - `mocktail: ^1.0.4` (dev)
- [x] Thiết lập kiến trúc Feature-First: `core/`, `domain/`, `data/`, `features/`, `routing/`
- [x] Cấu hình `android/app/build.gradle.kts` (minSdk = 21 cho Google ML Kit)
- [x] Khai báo quyền Android trong `AndroidManifest.xml` (Camera, Images, Internet, Network state)

### Increment 2 — Domain Models & Regex Parsers ✅
- [x] `lib/core/constants/app_constants.dart`: Cấu hình hệ thống, tên bảng, timeouts
- [x] `lib/core/errors/app_exception.dart`: Sealed class hierarchy (`DatabaseException`, `OcrException`, `ParseException`, `GeminiException`, `ValidationException`, ...)
- [x] `lib/core/utils/currency_formatter.dart`: Format tiền VND (`1.250.000 ₫`, `1.25M ₫`), parser số nguyên chống float-rounding
- [x] `lib/core/utils/date_formatter.dart`: Format ngày tháng chuẩn Việt Nam (thứ hai - chủ nhật, dd/MM/yyyy)
- [x] `lib/domain/models/expense.dart`: Model Expense với `amount: int`, copyWith, toMap, fromMap
- [x] `lib/domain/models/expense_category.dart`: 9 danh mục chi tiêu, icons, màu Material 3, thuật toán `suggestFromText`
- [x] `lib/domain/models/receipt_ocr_result.dart`: Model kết quả OCR, confidence score (`OcrConfidence`), warnings
- [x] `lib/domain/models/spending_summary.dart`: Model tổng hợp dữ liệu chi tiêu cho Dashboard và Gemini AI
- [x] `lib/features/receipt_scanner/domain/receipt_parser.dart`: Regex parser nhiều tầng (high/medium priority labels, half-bottom fallback, phone/code filter)
- [x] `lib/features/receipt_scanner/domain/transfer_message_parser.dart`: Parser tin nhắn ngân hàng (phát hiện chiều chuyển đi/nhận về, mã GD, ngày giờ)
- [x] Unit tests: 16 test cases cho ReceiptParser + 5 test cases cho TransferMessageParser (Đạt 100%)

### Increment 3 — SQLite Database Layer ✅
- [x] `lib/data/database/app_database.dart`: SQLite singleton, WAL mode, Index trên `transaction_date` và `category`
- [x] `lib/domain/repositories/expense_repository.dart`: Interface repository độc lập
- [x] `lib/data/repositories/expense_repository_impl.dart`: Implement CRUD, SQL `SUM`, `GROUP BY category`, `GROUP BY transaction_date`
- [x] Unit tests: 7 test cases kiểm thử database bằng in-memory SQLite (`sqflite_common_ffi`) (Đạt 100%)

### Increment 4 — UI & State Management (Material 3 + Riverpod 2) ✅
- [x] `lib/core/theme/app_theme.dart`: Thiết kế theme Material 3 cho cả Light & Dark mode
- [x] `lib/routing/app_router.dart`: Cấu hình GoRouter với `StatefulShellRoute.indexedStack` (4 tabs: Tổng quan, Chi tiêu, Thống kê, Cố vấn AI + Quét hóa đơn & Cài đặt)
- [x] Pure idiomatic Riverpod 2 providers: `recentExpensesProvider`, `monthlySpendingSummaryProvider`, `weeklyTotalProvider`, `expenseRepositoryProvider`
- [x] `lib/features/dashboard/presentation/dashboard_screen.dart`: Dashboard fintech hiện đại với pull-to-refresh, skeleton loaders, error boundaries
- [x] `lib/features/dashboard/presentation/widgets/expense_summary_card.dart`: Transaction card hiển thị icon, màu, nhãn nguồn (`manual`, `ocr`, `transfer`)
- [x] `lib/features/expenses/presentation/expense_list_screen.dart`: Danh sách giao dịch, thanh tìm kiếm, bộ lọc theo danh mục
- [x] `lib/features/expenses/presentation/add_edit_expense_screen.dart`: Form thêm/sửa giao dịch, validation đầy đủ, date picker

### Increment 5 — Custom Charts (Donut & Weekly Bar via CustomPainter) ✅
- [x] `lib/features/statistics/presentation/widgets/donut_chart.dart`: `_DonutChartPainter` tự vẽ hình vành khuyên (donut), tính góc chính xác, legend tỷ lệ %
- [x] `lib/features/statistics/presentation/widgets/weekly_bar_chart.dart`: `_BarChartPainter` tự vẽ biểu đồ cột 7 ngày, đường lưới tham chiếu, tooltip khi chạm
- [x] Xử lý giới hạn render bằng `LayoutBuilder` và kích thước hữu hạn để tránh lỗi layout overflow
- [x] `lib/features/statistics/presentation/statistics_screen.dart`: Màn hình thống kê với bộ lọc thời gian (Tuần này, Tháng này, Tháng trước, Năm nay)
- [x] Widget tests: 5 test cases cho DonutChart và WeeklyBarChart (Đạt 100%)

### Increment 6 — OCR Scanner & Review Flow ✅
- [x] `lib/data/services/image_storage_service.dart`: Quản lý lưu trữ ảnh hóa đơn cục bộ theo UUID
- [x] `lib/features/receipt_scanner/presentation/receipt_scanner_screen.dart`: Giao diện chụp ảnh / chọn thư viện ảnh, tích hợp Google ML Kit text recognition
- [x] `lib/features/receipt_scanner/presentation/receipt_review_screen.dart`: **Bắt buộc Review trước khi lưu** — cho phép kiểm tra, chỉnh sửa merchant, số tiền, ngày, danh mục, hiển thị văn bản OCR gốc
- [x] Tích hợp tab chuyển đổi: Quét ảnh hóa đơn OCR vs Nhập tin nhắn chuyển khoản ngân hàng

### Increment 7 — Gemini AI Advisor ✅
- [x] `lib/data/services/gemini_service.dart`: Client gọi Google Gemini API (`gemini-2.0-flash`), giải mã UTF-8 chuẩn xác, prompt định hướng sinh viên
- [x] An toàn dữ liệu: Chỉ gửi dữ liệu tổng hợp (`SpendingSummary`), không gửi ảnh, thông tin nhạy cảm hay API key ra ngoài
- [x] `lib/features/ai_advisor/presentation/ai_advisor_screen.dart`: Giao diện Cố vấn tài chính AI với phân tích ngân sách sinh viên VKU, thẻ dữ liệu thực tế và lời khuyên tiết kiệm
- [x] Fallback offline: Thông báo rõ ràng khi mất kết nối mạng hoặc chưa cấu hình API key
- [x] Unit tests: 5 test cases với Mock HTTP client kiểm tra parse response, HTTP error codes (401, 429, 500) và UTF-8 (Đạt 100%)

### Increment 8 — Settings & Quality Assurance ✅
- [x] `lib/features/settings/presentation/settings_screen.dart`: Tùy chỉnh chế độ sáng/tối, thiết lập ngân sách tháng, cấu hình Gemini API Key an toàn trong app, xóa dữ liệu cục bộ
- [x] Static Analysis: `flutter analyze` ➔ **0 issues found**
- [x] Test Suite: `flutter test` ➔ **40/40 tests PASSED (100%)**
- [x] Android Build: Chạy Gradle assembleDebug trên Android SDK 34/36 với NDK 28 ➔ **Build thành công: `build/app/outputs/flutter-apk/app-debug.apk` (188 MB)**

### Increment 9 — Platform Channels & Native Interoperability (Part 7) ✅
- [x] `android/app/src/main/kotlin/.../MainActivity.kt`: Đăng ký `MethodChannel("vn.edu.vku/device_info")` xử lý:
  - `getBatteryLevel`: Đọc mức pin hiện tại (%) qua `BatteryManager`.
  - `getDeviceInfo`: Lấy thông tin phần cứng qua `android.os.Build` (Model, Manufacturer, Android Version, SDK Level, RAM).
  - `triggerHaptic`: Kích hoạt rung phản hồi xúc giác native (`VibrationEffect` / `Vibrator`) 50ms khi quét hóa đơn thành công.
- [x] `lib/core/services/native_device_service.dart`: Cầu nối Dart với class `DeviceInfo`, singleton `NativeDeviceService`, các Riverpod provider (`nativeDeviceServiceProvider`, `batteryLevelProvider`, `deviceInfoProvider`).
- [x] Tích hợp UI `SettingsScreen`: Thêm section "Thông tin thiết bị (Native Bridge)" hiển thị mức pin và expansion tile thông số phần cứng thiết bị.
- [x] Tích hợp UI `ReceiptScannerScreen`: Kiểm tra cảnh báo pin yếu (< 15%) trước khi chạy OCR và kích hoạt `triggerHaptic()` khi OCR hoàn tất.
- [x] Unit Tests: `test/unit/services/native_device_service_test.dart` (8 tests) mock `MethodChannel` bằng `TestDefaultBinaryMessengerBinding` ➔ **8/8 PASSED**.

### Increment 10 — Mini-Project 3 Final Sprint Deliverables (Part 8) ✅
- [x] `docs/DEMO_VIDEO_SCRIPT.md`: Kịch bản video demo 2–3 phút chi tiết 6 phân cảnh (Dashboard ➔ Platform Channel ➔ Quét hóa đơn OCR ➔ Review Confirmation ➔ Biểu đồ cập nhật tức thì ➔ Gemini AI) kèm lệnh ADB screenrecord và checklist chấm điểm.
- [x] `docs/TECHNICAL_REPORT.md`: Báo cáo kỹ thuật toàn diện chuẩn slide gồm:
  - Sơ đồ kiến trúc Mermaid khép kín từ Chụp ảnh đến Cập nhật Biểu đồ.
  - Bảng đối chiếu 3 Channel Flavors (MethodChannel, EventChannel, BasicMessageChannel).
  - Bảng tinh chỉnh Regex bóc tách hóa đơn Việt Nam theo thứ tự ưu tiên.
  - Bảng đặc tả giao diện Light Mode / Dark Mode theo Material 3.
  - Kết quả kiểm thử tự động 48 bài và phân tích tĩnh 0 cảnh báo.
  - Giới hạn kỹ thuật và hướng mở rộng Clean Architecture tuần 9.
- [x] Đóng gói Release APK: `flutter build apk --release` ➔ **Build thành công: `build/app/outputs/flutter-apk/app-release.apk` (83 MB, tối ưu hóa R8 & tree-shaking)**.

---

## Tổng kết Kiểm thử (Test Results)

```
00:00 +0: ReceiptParser Unit Tests: format & parse VND amounts (16 tests)
00:00 +16: TransferMessageParser: outgoing & incoming SMS detection (5 tests)
00:00 +21: Database: SQLite CRUD & aggregations (7 tests)
00:00 +28: GeminiService: advice parse, UTF-8 & privacy boundary (5 tests)
00:00 +33: NativeDeviceService: Platform Channel mock, battery & hardware (8 tests)
00:00 +41: DonutChart: empty state, multiple categories & legends (3 tests)
00:00 +44: ExpenseSummaryCard: rendering transaction details & badges (2 tests)
00:00 +46: WeeklyBarChart: empty state, spending bars & touch tooltip (2 tests)
00:01 +48: All tests passed! (48/48 - 100%)
```

---

## Các vấn đề kỹ thuật đã xử lý (Bug Fixes & Technical Decisions)

1. **Riverpod Code Generation vs Pure Riverpod 2**:
   - `build_runner` gặp xung đột phiên bản analyzer SDK giữa Dart 3.13 và analyzer 3.9.
   - *Giải pháp:* Chuyển sang pure idiomatic Riverpod 2 (`Provider`, `FutureProvider`, `StateNotifierProvider`). Không cần build runner, build nhanh hơn và hoàn toàn an toàn type.
2. **CustomPainter Layout Constraints**:
   - `CustomPaint(size: Size.infinite)` trong `Column` gây lỗi unbound height crash layout.
   - *Giải pháp:* Dùng `LayoutBuilder` đọc `constraints.maxWidth`, truyền kích thước cố định `Size(width, 220)` và đặt `mainAxisSize: MainAxisSize.min`.
3. **LocaleDataException trong Headless Unit Tests**:
   - `DateFormat` với locale `'vi'` khi chạy không có `initializeDateFormatting` ném exception.
   - *Giải pháp:* Dùng định dạng chuẩn `dd/MM/yyyy` kết hợp bảng tra thứ tiếng Việt bằng Dart thuần (`['Thứ Hai', 'Thứ Ba', ...]`).
4. **UTF-8 Character Encoding cho Gemini API**:
   - `http.Response.body` mặc định ISO-8859-1 làm sai dấu tiếng Việt.
   - *Giải pháp:* Decode rõ ràng bằng `utf8.decode(response.bodyBytes)`.
5. **Regex Edge Cases cho Tiền tệ & Ngân hàng**:
   - Thêm lọc tiền thừa/tiền thối (`tiền thừa`, `change`, `discount`).
   - Xử lý các hậu tố `đồng`, `đ`, `VND`.
   - Lọc mã giao dịch ngân hàng dài tránh nhận nhầm thành số tiền.
