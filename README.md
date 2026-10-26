# VKU Expense AI (vkuexpenseocr)

> **Ứng dụng Quản lý Chi tiêu Thông minh Tích hợp Nhận diện Hóa đơn OCR và Trợ lý Tài chính Google Gemini cho Sinh viên VKU**

[![Flutter](https://img.shields.io/badge/Flutter-3.47.7-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.5-0175C2?logo=dart)](https://dart.dev)
[![Material 3](https://img.shields.io/badge/Design-Material%203-7D5260)](https://m3.material.io)
[![Tests](https://img.shields.io/badge/Tests-48%2F48%20Passed-brightgreen)](docs/TESTING.md)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 🌟 Tính năng Nổi bật

- **📸 Quét Hóa đơn OCR On-Device**: Sử dụng Google ML Kit Text Recognition để trích xuất văn bản hóa đơn trực tiếp trên thiết bị Android, hoạt động hoàn toàn offline và bảo mật thông tin.
- **⚡ Regex Parser Đa tầng**: Thuật toán bóc tách thông minh trích xuất chính xác tổng tiền thanh toán (ưu tiên các nhãn *TỔNG CỘNG*, *GRAND TOTAL*), ngày giao dịch tiếng Việt, người bán, và tự động gợi ý danh mục chi tiêu.
- **💬 Phân tích Tin nhắn Chuyển khoản**: Hỗ trợ dán tin nhắn ngân hàng (SMS/Banking App), tự động phát hiện số tiền chuyển đi, mã giao dịch và cảnh báo nếu là giao dịch nhận tiền.
- **🛡️ Màn hình Review Xác nhận**: Nguyên tắc không âm thầm suy đoán — người dùng luôn được xem lại, điều chỉnh và xác nhận thông tin hóa đơn trước khi lưu vào cơ sở dữ liệu.
- **🔌 Platform Channels Native Bridge (Part 7)**: Cầu nối `MethodChannel("vn.edu.vku/device_info")` với Kotlin:
  - Đọc dung lượng pin native (`getBatteryLevel`) để cảnh báo trước khi quét.
  - Đọc cấu hình phần cứng thiết bị (`getDeviceInfo`) hiển thị trong Cài đặt.
  - Kích hoạt rung phản hồi xúc giác native (`triggerHaptic`) khi OCR thành công.
- **📊 Biểu đồ Phân tích Tự vẽ (CustomPainter)**:
  - **Donut Chart**: Phân bổ tỷ lệ chi tiêu theo danh mục với animation mượt mà và chú thích tương tác.
  - **Weekly Bar Chart**: Biến động chi tiêu 7 ngày gần nhất, chuẩn hóa chiều cao, đường lưới mốc giá trị, hỗ trợ chạm cột hiển thị tooltip chi tiết.
- **🤖 Trợ lý Tài chính AI (Google Gemini 2.0 Flash)**: Phân tích thói quen tài chính của sinh viên, cảnh báo các khoản chi bất thường và đưa ra lời khuyên tiết kiệm thực tế. Tuân thủ chính sách bảo mật — chỉ gửi dữ liệu thống kê tổng hợp, không bao giờ gửi ảnh.
- **💾 Cơ sở Dữ liệu SQLite Cục bộ**: Lưu trữ offline-first bền vững, cấu hình chế độ WAL mode và đánh chỉ mục tối ưu hiệu năng. Số tiền VND luôn được lưu dưới dạng số nguyên `int` để triệt tiêu sai số.
- **🎨 Giao diện Material 3 Đẳng cấp**: Tối ưu trải nghiệm với chế độ Sáng / Tối (Dark / Light mode) và ngôn ngữ tiếng Việt thân thiện.

---

## 📁 Cấu trúc Dự án (Feature-First)

```
lib/
├── core/                       # Thành phần dùng chung (theme, utils, errors, network)
├── data/                       # Quản lý SQLite, Repository implementation, Gemini service
├── domain/                     # Entity models, interfaces, Regex receipt parser
├── features/                   # Từng tính năng độc lập (presentation, widgets, providers)
│   ├── dashboard/              # Tổng quan tài chính, thống kê tháng/tuần
│   ├── expenses/               # Danh sách giao dịch, lọc danh mục, form thêm/sửa
│   ├── receipt_scanner/        # Camera/thư viện OCR, màn hình Review xác nhận
│   ├── statistics/             # Biểu đồ Donut & Bar chart tự vẽ CustomPainter
│   ├── ai_advisor/             # Cố vấn tài chính với Google Gemini
│   └── settings/               # Cài đặt giao diện, ngân sách tháng, API key
├── routing/                    # Điều hướng GoRouter với StatefulShellRoute
└── main.dart                   # Điểm khởi động ứng dụng
```

---

## 🚀 Hướng dẫn Cài đặt & Chạy Ứng dụng

### Yêu cầu Hệ thống
- Flutter SDK `>= 3.47.0`
- Dart SDK `>= 3.13.0`
- Android SDK với API level tối thiểu là 21 (Android 5.0+)

### Các bước Thực hiện

1. **Clone repository và di chuyển vào thư mục dự án**:
   ```bash
   cd vku_expense_ocr
   ```

2. **Cài đặt các gói phụ thuộc**:
   ```bash
   flutter pub get
   ```

3. **Cấu hình môi trường (Tùy chọn cho Gemini AI)**:
   - Sao chép file mẫu: `cp .env.example .env` (nếu có) hoặc cấu hình Gemini API key trực tiếp trong tab **Cài đặt** của ứng dụng.
   - Xem chi tiết tại [docs/GEMINI_SETUP.md](docs/GEMINI_SETUP.md).

4. **Chạy ứng dụng trên thiết bị / máy ảo**:
   ```bash
   flutter run
   ```

---

## 🧪 Kiểm thử Tự động (Automated Testing)

Dự án sở hữu bộ kiểm thử tự động toàn diện bao quát Unit Test và Widget Test:

```bash
# Chạy toàn bộ 40 test case
flutter test

# Kiểm tra phân tích tĩnh mã nguồn (Static Analysis)
flutter analyze
```

Kết quả: **40/40 tests passed** • **No issues found in flutter analyze**.  
Chi tiết xem tại [docs/TESTING.md](docs/TESTING.md).

---

## 📚 Tài liệu Chi tiết

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): Kiến trúc hệ thống, nguyên lý thiết kế, sơ đồ luồng dữ liệu.
- [docs/TESTING.md](docs/TESTING.md): Báo cáo kiểm thử, danh sách 48 ca kiểm thử và hướng dẫn test.
- [docs/DEMO_VIDEO_SCRIPT.md](docs/DEMO_VIDEO_SCRIPT.md): Kịch bản quay video demo 2–3 phút đáp ứng tiêu chí chấm điểm Part 8.
- [docs/GEMINI_SETUP.md](docs/GEMINI_SETUP.md): Hướng dẫn lấy key, tích hợp và các biện pháp bảo vệ quyền riêng tư cho Gemini AI.
- [docs/TECHNICAL_REPORT.md](docs/TECHNICAL_REPORT.md): Báo cáo kỹ thuật tổng kết toàn diện dự án (Sơ đồ Pipeline, Platform Channel, Bảng Regex, UI Specs).
- [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md): Nhật ký tiến độ và lộ trình triển khai chi tiết.
