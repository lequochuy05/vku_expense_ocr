# Hướng dẫn và Báo cáo Kiểm thử — VKU Expense AI

Tài liệu kiểm thử tự động toàn diện cho ứng dụng **VKU Expense AI** (`vkuexpenseocr`).

---

## 1. Chiến lược Kiểm thử (Testing Strategy)

Hệ thống áp dụng kim tự tháp kiểm thử (Test Pyramid) chặt chẽ:
1. **Unit Testing (Kiểm thử đơn vị)**:
   - Thuật toán trích xuất hóa đơn `ReceiptParser`.
   - Phân tích tin nhắn ngân hàng `TransferMessageParser`.
   - Định dạng tiền tệ `CurrencyFormatter` và ngày tháng `DateFormatter`.
   - Gọi API Gemini và xử lý ngoại lệ HTTP với Mock Client.
   - Thao tác CRUD và truy vấn tổng hợp trên SQLite In-Memory qua `sqflite_common_ffi`.
2. **Widget Testing (Kiểm thử giao diện & thành phần)**:
   - Các CustomPainter tự vẽ (`DonutChart`, `WeeklyBarChart`).
   - Xử lý trạng thái rỗng (empty state), đơn danh mục, đa danh mục.
   - Tương tác chạm vào biểu đồ và hiển thị tooltip.
   - Thẻ giao dịch `ExpenseSummaryCard` và các badge nguồn dữ liệu.
3. **Integration & Error Boundary Testing**:
   - Kiểm tra mã hóa UTF-8 cho phản hồi tiếng Việt.
   - Kiểm tra bảo vệ quyền riêng tư (Privacy Boundary Assertion).

---

## 2. Danh mục Bộ Kiểm thử và Kết quả

Tất cả 48 kiểm thử tự động đã được thực thi và vượt qua 100% (**48/48 PASSED**).

### 2.1. ReceiptParser & CurrencyFormatter (`test/unit/parser/receipt_parser_test.dart`)
- `format VND numbers correctly`: Kiểm tra định dạng có dấu chấm phân cách hàng nghìn (1.250.000 ₫).
- `parse various Vietnamese currency representations`: Parse thành công các dạng `125.000`, `125,000`, `1.250.000 đ`, `1,250,000 VND`, `85.000 đồng`.
- `formatCompact handles K, M, B abbreviations`: Viết tắt gọn 50K, 2.5M, 1.5B cho thẻ tóm tắt.
- `extracts amount with high priority label TỔNG CỘNG`: Trích xuất chính xác tổng tiền khi có nhãn ưu tiên cao.
- `extracts amount with GRAND TOTAL label`: Trích xuất thành công nhãn tiếng Anh phổ biến.
- `ignores tiền thừa and discount when finding total`: Không bị nhầm lẫn giữa tiền thối lại (tiền thừa) và tổng thanh toán.
- `extracts amount when label and number are on separate lines`: Trích xuất khi nhãn và số tiền nằm ở 2 dòng kế tiếp.
- `handles fallback when no total label is present`: Cơ chế dự phòng lấy số tiền lớn nhất ở nửa dưới hóa đơn và phát sinh cảnh báo độ tin cậy.
- `handles empty and whitespace OCR text gracefully`: Trả về `OcrConfidence.unknown` khi văn bản rỗng, không gây crash ứng dụng.
- `extracts dd/MM/yyyy date format`: Nhận dạng ngày chuẩn Việt Nam.
- `extracts Ngày dd tháng MM năm yyyy format`: Nhận dạng dạng chữ tiếng Việt.
- `extracts ISO yyyy-MM-dd date format`: Nhận dạng định dạng ngày chuẩn quốc tế.
- `handles 2-digit year format (dd/MM/yy)`: Xử lý năm 2 chữ số (00-49 thành 2000+).
- `ignores phone numbers, addresses, and POS headers`: Bỏ qua số điện thoại, địa chỉ (cả `Dia chi` không dấu) để lấy đúng tên cửa hàng Title Case.
- `detects payment methods`: Nhận dạng thẻ (`card`), tiền mặt (`cash`), chuyển khoản (`transfer`).
- `categorizes utilities and transport properly`: Phân loại tự động danh mục Ăn uống, Di chuyển, Hóa đơn.

### 2.2. TransferMessageParser (`test/unit/parser/transfer_message_parser_test.dart`)
- `parses outgoing bank transfer correctly`: Trích xuất giao dịch chuyển tiền ra, số tiền, ngày giờ, người nhận và mã giao dịch.
- `parses merchant payment transfer message`: Trích xuất thanh toán tại cửa hàng.
- `detects incoming transfer and warns user`: Phân biệt giao dịch nhận tiền và cảnh báo người dùng xác nhận trước khi ghi vào chi tiêu.
- `ignores transaction codes when identifying amount`: Không nhầm lẫn mã giao dịch dài với số tiền chuyển.
- `handles empty message`: Xử lý ngoại lệ tin nhắn trống an toàn.

### 2.3. SQLite Database (`test/unit/database/database_test.dart`)
- `addExpense inserts record and returns valid ID`: Thêm giao dịch và nhận ID tự tăng.
- `updateExpense updates record fields accurately`: Cập nhật thông tin giao dịch.
- `deleteExpense removes record from database`: Xóa giao dịch khỏi cơ sở dữ liệu.
- `getExpenses filters by category and searchQuery`: Lọc giao dịch theo danh mục và tìm kiếm theo từ khóa.
- `getTotalAmount and getCategoryTotals calculate aggregates correctly`: Tính tổng tiền và tổng theo từng danh mục bằng SQL SUM/GROUP BY.
- `getSpendingSummary generates complete metrics`: Tạo tóm tắt chi tiêu hoàn chỉnh cho Dashboard và AI.
- `clearAll removes all expenses`: Xóa toàn bộ dữ liệu giao dịch an toàn.

### 2.4. NativeDeviceService Platform Channel Tests (`test/unit/services/native_device_service_test.dart`)
- `getBatteryLevel trả về mức pin từ native`: Giả lập `MethodChannel` trả về 85% qua `setMockMethodCallHandler`.
- `getBatteryLevel trả về -1 khi native ném PlatformException`: Graceful degradation khi không đọc được pin.
- `getDeviceInfo trả về thông tin thiết bị từ native Map`: Parse Model, Manufacturer, OS, RAM tổng/khả dụng.
- `getDeviceInfo trả về null khi native không khả dụng`: Xử lý an toàn khi thiếu native plugin.
- `triggerHaptic gọi native method mà không ném exception`: Rung phản hồi native 50ms khi hoàn tất OCR.
- `triggerHaptic im lặng khi thiết bị không hỗ trợ rung`: Không làm sập ứng dụng nếu máy không có bộ rung.
- `DeviceInfo.fromMap parse đầy đủ các trường`: Kiểm tra parse Map với dữ liệu chuẩn.
- `DeviceInfo.fromMap xử lý Map với giá trị null`: Kiểm tra fallback `Unknown` và `0` an toàn.

### 2.5. CustomPainter Charts (`test/widget/charts_test.dart`)
- `DonutChart: renders empty state when totalAmount is 0`: Hiển thị giao diện thông báo khi chưa có dữ liệu.
- `DonutChart: renders properly with multiple categories and legends`: Vẽ các cung tròn và chú thích tỷ lệ phần trăm chính xác.
- `DonutChart: renders properly with a single category`: Vẽ cung tròn 100% khi chỉ có 1 danh mục.
- `WeeklyBarChart: renders empty state when all 7 days have zero spending`: Hiển thị thông báo khi 7 ngày qua không có chi tiêu.
- `WeeklyBarChart: renders bar chart when spending exists and handles taps`: Vẽ 7 cột, đường lưới và xử lý tương tác chạm mở Tooltip chi tiết.

### 2.6. GeminiService (`test/unit/services/gemini_service_test.dart`)
- `successful 200 response parses advice text correctly`: Đọc và phân tích câu trả lời của AI.
- `throws GeminiException with 401 status on invalid API key`: Bắt lỗi xác thực API key.
- `throws GeminiException with 429 on rate limit`: Bắt lỗi vượt giới hạn tần suất.
- `throws GeminiException on empty API key`: Ngăn chặn gọi API khi chưa nhập key.
- `verifies request body sends only aggregated summary without sensitive data`: Khẳng định bảo mật — chỉ gửi số liệu thống kê tổng hợp, tuyệt đối không gửi ảnh hay raw text.

### 2.7. ExpenseSummaryCard (`test/widget/expense_summary_card_test.dart`)
- `renders transaction details and source badges`: Hiển thị đầy đủ tên, cửa hàng, số tiền VND, icon danh mục và badge nguồn `OCR`.
- `renders transfer source badge`: Hiển thị đúng badge `Chuyển khoản`.

---

## 3. Lệnh Chạy Kiểm Thử

Chạy toàn bộ test suite:
```bash
flutter test
```

Chạy riêng từng bộ kiểm thử:
```bash
# Unit test Regex Parser
flutter test test/unit/parser/

# Unit test SQLite Database
flutter test test/unit/database/

# Unit test Gemini Service
flutter test test/unit/services/

# Widget test Biểu đồ CustomPainter
flutter test test/widget/charts_test.dart

# Widget test Card giao dịch
flutter test test/widget/expense_summary_card_test.dart
```

Kiểm tra cú pháp và quy chuẩn mã nguồn:
```bash
flutter analyze
```
Kết quả mong đợi: `No issues found!`.
