# Kiểm thử chuyển SQL Server

Ngày02/11/2026. Kết quả mới nằm docs/evidence/sql-server. Các log/ảnh SQLite ở thư mục cha là bằng chứng bản trước, không chứng minh SQL Server.

- Flutter: bộ hồi quy cũ dùng adapter SQLite trong test/support; kiểm thử API dùng transport giả lập; kiểm thử remote UI dùng repository production với phản hồi HTTP giả lập. Không coi đây là E2E SQL Server.
- Backend: self-tests validation, UTC+7, giới hạn30 ngày, resolution, import format và auth/TLS. Build với WithoutSqlDriver=true chỉ bỏ package SQL để kiểm tra C# khi NuGet bị chặn; không dùng cờ này khi chạy API thật.
- Công cụ export: kiểm tra checksum source không đổi, tiếng Việt và từ chối ghi đè file đích.
- Review cuối: đã tái hiện rồi sửa orphan OS alarm khi mất phản hồi ghi trạng thái; dọn theo danh sách canonical, chặn replacement nếu hủy thất bại.
- NuGet restore bình thường: thất bại DNS api.nuget.org. SQLcmd default instance: không tìm thấy/không truy cập được server. Chưa tạo/nhập/CRUD database SQL Server thật trong môi trường này.
- Cần làm trên máy có SQL Server: restore bình thường, init database riêng, tạo/sửa/xóa số đo, tạo/sửa/tắt/xác nhận lịch, kiểm tra hai device_id độc lập, lặp Idempotency-Key, nhập DB rỗng và thử target có dữ liệu/rollback lỗi, Windows/Android chạy cùng API. Không bỏ qua kiểm chứng driver/T-SQL vì self-tests đạt.
- Thiết bị: quyền OS, cold-start, Doze/force stop và MSIX signing/delivery vẫn chưa kiểm chứng. Không tự đổi firewall/trust/chứng chỉ.
