# Kịch Bản Video Demo — VKU Expense AI

> **Thời lượng mục tiêu**: 2–3 phút  
> **Yêu cầu chấm điểm**: Quét hóa đơn thật bằng camera, Regex parser trích xuất tức thời, Review confirmation, biểu đồ Donut & Bar chart (CustomPainter) cập nhật animation, Platform Channel native bridge

---

## Chuẩn Bị Trước Khi Quay

1. **Hóa đơn thật**: Chuẩn bị 1–2 hóa đơn (Highlands Coffee, Phúc Long, Circle K, hoặc siêu thị). Hóa đơn phải có dòng "TỔNG CỘNG" hoặc "THÀNH TIỀN" rõ ràng.
2. **Thiết bị Android**: Đã cài `app-release.apk`, pin > 20%.
3. **Dữ liệu ban đầu**: Đã nhập sẵn 3–5 giao dịch ở nhiều danh mục (Ăn uống, Di chuyển, Mua sắm) để biểu đồ hiển thị đẹp.
4. **Gemini API key**: Đã cấu hình trong Cài đặt (nếu muốn demo AI Advisor).
5. **Phần mềm quay**: Dùng ADB screenrecord hoặc app quay màn hình.

---

## Kịch Bản Chi Tiết

### Phân Cảnh 1: Dashboard Tổng Quan (0:00 – 0:25)

| Giây | Thao tác | Thuyết minh |
|---|---|---|
| 0:00 | Mở ứng dụng VKU Expense AI | "Đây là ứng dụng VKU Expense AI, quản lý chi tiêu cá nhân thông minh cho sinh viên VKU." |
| 0:05 | Cuộn dashboard hiển thị tổng chi tiêu tháng, số giao dịch | "Dashboard hiển thị tổng chi tiêu tháng, tuần, số lượng giao dịch, so sánh với tuần trước — tất cả tính từ dữ liệu SQLite thật." |
| 0:12 | Chỉ vào biểu đồ Donut Chart | "Biểu đồ hình vành khuyên tự vẽ 100% bằng CustomPainter, phân bổ chi tiêu theo danh mục." |
| 0:18 | Chỉ vào biểu đồ Weekly Bar Chart | "Biểu đồ cột 7 ngày cũng tự vẽ bằng CustomPainter, hiển thị biến động chi tiêu hàng ngày." |

### Phân Cảnh 2: Platform Channel / Native Bridge (0:25 – 0:45)

| Giây | Thao tác | Thuyết minh |
|---|---|---|
| 0:25 | Chuyển sang tab Cài đặt | "Tab Cài đặt cho phép chuyển đổi Dark/Light mode, thiết lập ngân sách, cấu hình Gemini API key." |
| 0:30 | Cuộn xuống phần "Thông tin thiết bị (Native Bridge)" | "Đây là phần tích hợp Platform Channel Part 7 — sử dụng MethodChannel gọi native Kotlin." |
| 0:35 | Chỉ vào mức pin và thông tin thiết bị | "getBatteryLevel() đọc mức pin qua BatteryManager. getDeviceInfo() lấy thông tin phần cứng từ android.os.Build." |
| 0:40 | Mở rộng ExpansionTile thông tin thiết bị | "Hiển thị Model, Android version, SDK, RAM tổng/khả dụng — tất cả từ native Kotlin." |

### Phân Cảnh 3: Quét Hóa Đơn (OCR Live Demo) (0:45 – 1:20)

| Giây | Thao tác | Thuyết minh |
|---|---|---|
| 0:45 | Bấm FAB (+) hoặc vào tab Quét hóa đơn | "Giờ ta quét hóa đơn thật. Bấm nút Camera hoặc chọn ảnh từ thư viện." |
| 0:50 | Bấm Camera, chụp hóa đơn thật | "Chụp hóa đơn Highlands Coffee. Ứng dụng xin quyền camera nếu chưa có." |
| 0:55 | Chờ ML Kit chạy OCR | "Google ML Kit Text Recognition chạy offline trên thiết bị, không cần internet." |
| 1:05 | Điện thoại rung nhẹ (haptic feedback) | "Rung phản hồi native qua triggerHaptic() — MethodChannel gọi Vibrator Android API." |
| 1:10 | Tự động chuyển sang màn hình Review | "Regex Parser phân tích văn bản: trích xuất TỔNG CỘNG, ngày giao dịch, tên cửa hàng theo đúng thuật toán đa tầng." |

### Phân Cảnh 4: Review & Verification Screen (1:20 – 1:50)

| Giây | Thao tác | Thuyết minh |
|---|---|---|
| 1:20 | Màn hình Review hiển thị kết quả | "Đây là màn hình Review bắt buộc — sinh viên kiểm tra cửa hàng, số tiền, ngày, danh mục." |
| 1:30 | Chỉnh sửa nhẹ một trường (ví dụ sửa ghi chú) | "Có thể chỉnh sửa bất kỳ trường nào. Không có dữ liệu nào được lưu ngầm." |
| 1:35 | Cuộn xuống xem Raw OCR Text | "Văn bản OCR gốc được hiển thị đầy đủ để đối chiếu." |
| 1:42 | Bấm nút "Lưu vào sổ chi tiêu" | "Bấm Lưu để ghi vào SQLite." |

### Phân Cảnh 5: Biểu Đồ Cập Nhật Tức Thì (1:50 – 2:25)

| Giây | Thao tác | Thuyết minh |
|---|---|---|
| 1:50 | Tự động về Dashboard | "Quay lại Dashboard — tổng chi tiêu tháng đã tăng, Donut Chart tự vẽ lại tỷ lệ phần trăm." |
| 2:00 | Chỉ vào Donut Chart | "Danh mục Ăn uống vừa tăng sau khi thêm hóa đơn Highlands." |
| 2:08 | Chỉ vào Weekly Bar Chart | "Cột ngày hôm nay trong biểu đồ cột đã cao hơn — Riverpod notifyListeners tự động." |
| 2:15 | Chạm vào 1 cột trong Bar Chart | "Touch tooltip hiển thị chi tiết số tiền và ngày khi chạm vào cột." |

### Phân Cảnh 6: AI Advisor — Gemini (2:25 – 3:00)

| Giây | Thao tác | Thuyết minh |
|---|---|---|
| 2:25 | Chuyển tab "Cố vấn AI" | "Tab Cố vấn AI tích hợp Google Gemini 2.0 Flash." |
| 2:30 | Bấm "Phân tích chi tiêu" | "Chỉ gửi dữ liệu tổng hợp dạng JSON — ảnh hóa đơn và thông tin cá nhân không rời khỏi thiết bị." |
| 2:40 | Chờ Gemini phản hồi (~3–5 giây) | "Gemini phân tích mô hình chi tiêu và đưa ra lời khuyên cụ thể cho sinh viên." |
| 2:50 | Cuộn đọc lời khuyên AI | "Phân tách rõ: khối số liệu thực (Dữ liệu từ SQLite) và khối phân tích AI (lời khuyên tham khảo)." |
| 2:55 | Kết thúc | "Cảm ơn đã xem demo VKU Expense AI — ứng dụng quản lý chi tiêu offline-first với OCR, Regex, CustomPainter và AI." |

---

## Lệnh Quay Màn Hình (Nếu Dùng ADB)

```bash
# Bắt đầu quay (tối đa 3 phút)
adb shell screenrecord --time-limit 180 /sdcard/vku_expense_demo.mp4

# Kéo file về máy tính
adb pull /sdcard/vku_expense_demo.mp4 ./demo/
```

---

## Checklist Trước Khi Nộp Video

- [ ] Video hiển thị rõ ràng, ít nhất 720p
- [ ] Có quét hóa đơn THẬT bằng camera (không dùng ảnh stock)
- [ ] Hiển thị rõ Regex parsing kết quả trên màn hình Review
- [ ] Bấm xác nhận lưu (Review Confirmation)
- [ ] Biểu đồ Donut & Bar chart cập nhật tức thì sau khi lưu
- [ ] Hiển thị Platform Channel native info (battery, device)
- [ ] Demo cả Light mode và Dark mode (chuyển đổi trong video)
- [ ] Tổng thời lượng 2–3 phút
