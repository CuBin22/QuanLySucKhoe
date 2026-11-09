# SQL Server và API

Ngày chuyển đổi: 02/11/2026. Giao diện và nghiệp vụ giữ nguyên, lớp production chỉ gọi HTTP API. Không dùng TDS/ODBC trực tiếp từ Flutter và không đặt mật khẩu SQL trong app.

## Thành phần

Flutter sử dụng ProfileRepository, HealthRepository, CareRepository và NotificationStore. ApiClient gửi JSON cùng X-Api-Key, X-Device-Id; các lệnh ghi có Idempotency-Key. ASP.NET Core kiểm tra đầu vào và thời gian máy chủ, thực hiện SQL có tham số trong transaction serializable. Khóa singleton của một hồ sơ tuần tự hóa các thay đổi, tránh ghi một phần hoặc hai yêu cầu sinh trùng occurrence.

| Bảng SQL Server | Vai trò |
|---|---|
| profiles | Một hồ sơ id=1, chiều cao và mục tiêu |
| health_records | Số đo, snapshot chiều cao, thời điểm UTC |
| care_reminders | Kế hoạch thuốc/tái khám hữu hạn |
| reminder_occurrences | Từng lần đến hạn và kết quả riêng |
| device_notifications | Trạng thái thông báo theo device_id và occurrence_id |
| api_requests | Kết quả lệnh ghi để chống tạo trùng khi thử lại |
| server_settings | Phiên bản schema và mã backend |

Chuỗi tiếng Việt dùng nvarchar; số đo dùng float(53) tương ứng double, thời điểm dùng bigint UTC milliseconds. Ngày kế hoạch date và giờ HH:mm theo UTC+7. ID occurrence int dùng cho OS notification. API không nhận nowUtc từ client để xác nhận sớm. Quy tắc30 ngày, đủ cặp huyết áp, snapshot và giữ lịch sử không thay đổi.

## Cấu hình

Cài .NET SDK9 hoặc môi trường có thể build net9.0, SQL Server2016+ và sqlcmd. Package Microsoft.Data.SqlClient7.1.1 được restore ở máy backend. Dùng database riêng, không dùng master/model/msdb/tempdb.

`tool/start_api.ps1 -Server "." -Initialize` dùng Windows Authentication, tạo PersonalHealth nếu chưa có và khởi tạo schema. Với instance khác, dùng tên trong SSMS, ví dụ `.\SQLEXPRESS`. `-Initialize` không reset bảng. Nếu bảng đã có nhưng không có metadata của app, init từ chối; chọn database rỗng khác thay vì xóa dữ liệu.

Nếu SQL Authentication hoặc server riêng, tạo database trước và đặt `ConnectionStrings__Health` trong terminal backend. Khi biến này đã tồn tại, script không tự tạo database ở server mặc định. Không commit connection string thật. Tài khoản API chỉ cần quyền cần thiết trên database; quyền tạo schema chỉ dùng lúc init.

Khóa cá nhân tự sinh nằm `.local/api-key.txt` khi không cung cấp HEALTH_API_KEY. File không được đóng gói/commit. Nếu đặt HEALTH_API_KEY thủ công thì phải đặt cùng giá trị ở terminal Flutter. HEALTH_API_URL hoặc dart-define API_BASE_URL chọn URL; API_KEY là dart-define cho Android. Windows có thể nhận key từ environment; nếu build để khởi động độc lập/nhấn toast phải cấu hình key khi build hoặc môi trường người dùng tương ứng. Key đóng trong APK/binary có thể trích xuất: phạm vi này là một người dùng trên hạ tầng riêng, không phải hệ thống nhiều tài khoản công khai.

## Android và LAN

Desktop mặc định `http://127.0.0.1:5080/api/`. Android emulator dùng `http://10.0.2.2:5080/api/`; loopback của emulator không phải máy Windows. Máy Android thật dùng IP LAN của máy API, cùng mạng.

Ví dụ demo riêng:

```powershell
.\tool\start_api.ps1 -Server "." -Urls "http://0.0.0.0:5080"
.\tool\run_app.ps1 -Device "ID_THIET_BI" -ApiBaseUrl "http://IP_MAY_API:5080/api/"
```

Chỉ dùng HTTP cho demo trên mạng riêng tin cậy, không mở ra Internet. Không tự đổi firewall/chứng chỉ trong phiên làm việc. Debug Android cho phép cleartext để dùng emulator/LAN; release mặc định cần HTTPS tin cậy. Backend ngoài Development từ chối HTTP. Khi triển khai, cấu hình ASPNETCORE_ENVIRONMENT=Production, ASPNETCORE_URLS và chứng chỉ HTTPS/Kestrel phù hợp; không dùng TrustServerCertificate=True như cấu hình mặc định demo cho server thật.

## Chuyển dữ liệu

`tool/export_sqlite.py` mở source ở mode=ro, đọc bốn bảng trong cùng read transaction, giữ Unicode và ID. Không ghi file SQLite và không ghi đè export đã tồn tại. Chỉ hỗ trợ SQLite schema1.

CLI `--import path.json` kiểm tra dữ liệu, từ chối target có dữ liệu, rồi nhập bốn bảng cùng transaction với IDENTITY_INSERT. ID, timestamp, snapshot và lịch sử được giữ. Lỗi FK/CHECK/ID rollback toàn bộ. Trạng thái thông báo SQLite không nhập sang trạng thái thiết bị mới. File source và JSON giữ nguyên để đối chiếu; JSON chứa dữ liệu cá nhân, bảo vệ như database.

Có thể kiểm tra file trước khi kết nối SQL:

```powershell
dotnet run --project server/Health.Api -- --validate-import (Resolve-Path .local/health.export.json).Path
```

Backend không tự tạo dữ liệu minh họa vào DB cá nhân. Muốn demo riêng hãy dùng database khác, không nhập đè hồ sơ hiện có.

## Mất mạng và thông báo

Khi API lỗi, app giữ nội dung form và báo thử lại; không tự ghi vào SQLite. Idempotency-Key được giữ khi cùng nội dung ghi thử lại trong vòng đời ApiClient hiện tại; đóng ứng dụng sẽ mất key chờ, nên kiểm tra danh sách sau khi mở lại trước khi tạo lại mục vừa bị mất phản hồi. Không tuyên bố chống trùng qua khởi động lại.

Thông báo vẫn đặt cục bộ theo từng thiết bị. Khi đổi backend, client hủy pending OS cũ trước khi đặt lại. Khi đối chiếu, client còn hủy ID OS không thuộc danh sách tương lai trên server để dọn lịch đã đặt nhưng mất phản hồi ghi trạng thái. Hủy thất bại sẽ chặn đặt thay thế và thử ở lần đối chiếu sau.

Thiết bị offline không thể biết ngay lịch đã sửa ở máy khác; app đối chiếu khi mở/resume hoặc thử lại. Không có push/background sync mới. Lịch OS đã đặt còn phụ thuộc quyền/pin/Doze/tắt máy; Android dùng inexact alarm, Windows toast cần package identity. Không cam kết giao đúng phút.

## Kiểm chứng

Đọc docs/testing.md và docs/evidence/sql-server. Build C# và self-tests không có driver chỉ chứng minh mã C#/nghiệp vụ; không chứng minh T-SQL, driver, kết nối SQL Server hoặc OS đã chạy. Bản DOCX/PPTX và Windows SQLite cũ nằm trong sqlite_archive, không phải bản mô tả SQL Server.
