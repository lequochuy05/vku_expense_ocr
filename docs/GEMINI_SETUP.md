# Hướng dẫn Cấu hình Gemini AI — VKU Expense AI

Tài liệu hướng dẫn cấu hình và tích hợp Google Gemini AI trong ứng dụng **VKU Expense AI** (`vkuexpenseocr`).

---

## 1. Tổng quan Tích hợp Gemini

VKU Expense AI sử dụng mô hình **Gemini 2.0 Flash** (`gemini-2.0-flash`) thông qua REST API của Google Generative AI để:
- Phân tích bức tranh tài chính và tỷ trọng chi tiêu của sinh viên.
- Phát hiện các danh mục chi tiêu bất thường hoặc tăng cao so với kỳ trước.
- Đưa ra 3-5 lời khuyên tiết kiệm thiết thực, phù hợp với đời sống sinh viên.
- Đề xuất kế hoạch phân bổ ngân sách cho kỳ tới.

Endpoint sử dụng:
```
https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={API_KEY}
```

---

## 2. Cách Lấy Gemini API Key Miễn phí

1. Truy cập vào **[Google AI Studio](https://aistudio.google.com/)** hoặc [ai.google.dev](https://ai.google.dev/).
2. Đăng nhập bằng tài khoản Google.
3. Chọn **Get API Key** -> **Create API Key**.
4. Sao chép chuỗi API key có dạng bắt đầu bằng `AIza...`.

---

## 3. Các Phương thức Cấu hình API Key

Ứng dụng hỗ trợ 3 phương thức cấu hình tùy theo môi trường triển khai:

### Phương thức 1: Cấu hình trực tiếp trong ứng dụng (Khuyến nghị cho người dùng)
1. Mở ứng dụng VKU Expense AI.
2. Điều hướng đến tab **Cài đặt** (Settings).
3. Tại mục **Cấu hình AI (Gemini)**, chọn **Gemini API Key**.
4. Dán API key của bạn và nhấn **Lưu**.
5. Key sẽ được lưu trữ an toàn trong `SharedPreferences` cục bộ trên thiết bị của bạn.

### Phương thức 2: Cấu hình lúc Build với `--dart-define` (Cho CI/CD & Production)
Khi biên dịch mã nguồn, truyền API key qua tham số dòng lệnh để nhúng vào bytecode mà không ghi vào mã nguồn:
```bash
flutter build apk --release --dart-define=GEMINI_API_KEY="AIzaSyYourActualKeyHere"
```

### Phương thức 3: Cấu hình tệp `.env` (Môi trường phát triển cục bộ)
Tạo hoặc chỉnh sửa tệp `.env` tại thư mục gốc dự án:
```env
GEMINI_API_KEY="AIzaSyYourActualKeyHere"
APP_ENV=development
```
> **CẢNH BÁO BẢO MẬT**: Tệp `.env` đóng gói trong ứng dụng di động có thể bị giải mã qua kỹ thuật Reverse Engineering (APK Decompilation). **Không bao giờ commit API key sản phẩm thực vào Git hoặc đẩy lên kho lưu trữ công khai**.

### Khuyến nghị cho Môi trường Sản xuất Lớn:
Xây dựng một dịch vụ **Backend Proxy (BFF)**:
- Ứng dụng di động gửi dữ liệu chi tiêu đã xác thực lên Backend server của trường/hệ thống.
- Backend server lưu trữ `GEMINI_API_KEY` bí mật trong biến môi trường server và thực hiện gọi Gemini API.
- Backend trả lời kết quả phân tích về ứng dụng.
- Phương pháp này loại bỏ 100% rủi ro lộ API key trên client.

---

## 4. Chính sách Bảo vệ Dữ liệu & Quyền Riêng tư (Privacy Boundary)

Ứng dụng tuân thủ nghiêm ngặt nguyên tắc **Privacy-by-Design**:
- **KHÔNG gửi ảnh**: Ảnh hóa đơn chỉ xử lý on-device qua Google ML Kit và lưu trong bộ nhớ máy.
- **KHÔNG gửi văn bản OCR thô**: Raw OCR text có thể chứa số điện thoại cửa hàng, địa chỉ cá nhân hay mã giao dịch; toàn bộ nội dung này bị chặn lại trên thiết bị.
- **CHỈ GỬI dữ liệu thống kê tổng hợp**:
  ```json
  {
    "period": "2026-10-01 đến 2026-10-31",
    "total_amount_vnd": 1500000,
    "transaction_count": 12,
    "change_percentage": "+15.0",
    "categories": [
      {
        "name": "Ăn uống",
        "amount_vnd": 900000,
        "percentage": "60.0",
        "transaction_count": 8
      }
    ]
  }
  ```

---

## 5. Xử lý Ngoại lệ & Trải nghiệm Ngoại tuyến (Offline Handling)

Khi không có kết nối internet hoặc API gặp sự cố, ứng dụng **hoàn toàn không bị crash**:
- **Không có mạng**: `ConnectivityService` phát hiện trước khi gọi API, thông báo thân thiện: *"Không có kết nối internet. Vui lòng kiểm tra mạng."*
- **Chưa cấu hình API Key**: Hiển thị hướng dẫn người dùng vào tab Cài đặt để thêm key.
- **API Key không hợp lệ (HTTP 401)**: Báo lỗi *"API key không hợp lệ hoặc đã hết hạn."*
- **Vượt tần suất (HTTP 429)**: Báo lỗi *"Quá nhiều yêu cầu. Vui lòng đợi giây lát."*
- **Dữ liệu thực tế luôn hiển thị**: Màn hình AI Advisor luôn tách bạch rõ ràng giữa khối *Thống kê thực tế từ SQLite* (luôn xem được offline) và khối *Phân tích AI* (cần mạng).
