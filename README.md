# Sổ sức khỏe — SQL Server

Ứng dụng Flutter Android/Windows. Dữ liệu lưu trong SQL Server thông qua API ASP.NET Core. Cần API hoạt động khi đọc/lưu.

## Chạy

Cài Flutter, .NET SDK9, SQL Server và công cụ sqlcmd. Lấy đúng tên server trong SSMS.

Terminal1 tại thư mục project:

```powershell
.\tool\start_api.ps1 -Server "." -Initialize
```

Nếu dùng SQL Express, thay `.` bằng `.\SQLEXPRESS`. Script tạo database PersonalHealth nếu chưa có, khởi tạo bảng, tạo khóa riêng trong `.local/api-key.txt` và chạy API. Không xóa/reset dữ liệu cũ.

Terminal2:

```powershell
flutter pub get
.\tool\run_app.ps1 -Device windows
```

Script chạy Windows đặt thư mục tạm Flutter ở `.local/flutter-temp` trên ổ D. Khi chạy trực tiếp bằng nút Run của VS Code từ thư mục dự án, ứng dụng Windows cũng tự đọc `.local/api-key.txt` nếu API đã tạo khóa.

Nếu ứng dụng báo "Không kết nối được API", giữ terminal API ở bước trên đang chạy và kiểm tra `Test-NetConnection 127.0.0.1 -Port 5080` (cần thấy `TcpTestSucceeded : True`). Nếu `False`, khởi động lại `tool/start_api.ps1` rồi nhấn **Thử lại** trong ứng dụng.

Android emulator: `flutter devices`, rồi thay `windows` bằng ID emulator. Script dùng `http://10.0.2.2:5080/api/`. Máy thật cần IP LAN của máy chạy API; xem docs/sql-server.md.

APK Android chưa được đóng gói: môi trường kiểm thử không kết nối được Gradle daemon. Hãy build trên máy có Android SDK/Gradle hoạt động và cung cấp API_URL/API_KEY phù hợp cho thiết bị; xem hướng dẫn kiểm thử SQL Server.

## Dữ liệu SQLite cũ

File `.db` được giữ nguyên. Xuất chỉ đọc rồi nhập vào SQL Server rỗng:

```powershell
python tool/export_sqlite.py "DUONG_DAN_FILE.db" ".local/health.export.json"
$env:ConnectionStrings__Health = "Server=.;Database=PersonalHealth;Integrated Security=True;Encrypt=True;TrustServerCertificate=True"
dotnet run --project server/Health.Api -- --import (Resolve-Path .local/health.export.json).Path
```

Không đưa `.local`, khóa API, file DB hoặc export cá nhân lên GitHub. SQL login/password chỉ đặt trong biến `ConnectionStrings__Health` của backend.

## Tệp chính

- `lib/data`: HTTP client và repository; production không mở SQLite.
- `server/Health.Api`: API, schema SQL Server, validation và import.
- `test/support`: SQLite chỉ dùng để kiểm thử hồi quy dữ liệu/giao diện cũ.
- `docs/sql-server.md`: cấu hình, kiến trúc và giới hạn kiểm chứng.
- `deliverables/sqlite_archive`: binary, DOCX/PPTX SQLite cũ được giữ trong dự án gốc; gói SQL Server chỉ kèm README lưu trữ, không lặp lại các file cũ.
- `deliverables/bao_cao_sql_server.docx` và `thuyet_trinh_sql_server.pptx`: báo cáo và bản trình bày kiến trúc hiện tại.
- `deliverables/windows_sqlserver/Chay_Ung_Dung.cmd`: bản Windows Release, cần khởi động API và cấu hình HEALTH_API_KEY trước khi dùng.
- `deliverables/do_an_sql_server.zip`: mã nguồn, tài liệu hiện tại và bản Windows; không có khóa API hoặc dữ liệu cá nhân.

HTTP và chứng chỉ tự ký trong script chỉ phục vụ demo riêng. Khi triển khai dùng HTTPS và cấu hình chứng chỉ tin cậy. API key trên ứng dụng cá nhân không thay cho xác thực nhiều người dùng.
