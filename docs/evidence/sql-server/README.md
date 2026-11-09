# Kết quả kiểm chứng bản SQL Server (09/11/2026)

| Hạng mục | Kết quả | Bằng chứng |
|---|---|---|
| Flutter test và integration qua runner không dùng localhost | 56/56 đạt | `flutter-tests.log` |
| Flutter analyze | Không có vấn đề | `flutter-analyze.log` |
| Windows Release | Build thành công | `windows-release.log` |
| Đóng gói Windows không kèm khóa hoặc database | Thành công | `windows-package.log` |
| Tự kiểm tra API C# và quy tắc nghiệp vụ | 15/15 đạt; backend build cùng Microsoft.Data.SqlClient | `api-self-tests.log`, `backend-build.log` |
| Xuất SQLite v1 chỉ đọc | Giữ nguyên checksum, Unicode, từ chối ghi đè | `export-sqlite.log` |
| Kiểm tra cấu trúc JSON nhập | Đạt; chưa kết nối SQL Server | `validate-export.log` |
| DOCX/PPTX mới | OOXML hợp lệ; 6 slide | `documents.log` |

Android debug build đã được thử nhưng Gradle không kết nối được daemon trong môi trường chạy; chưa có APK SQL Server được xác nhận. Backend C# đã build với SQL driver trong máy thử, nhưng chưa kết nối được SQL Server cục bộ. Vì vậy T-SQL, nhập dữ liệu thật, Android runtime và thông báo hệ điều hành vẫn cần nghiệm thu trên máy triển khai theo `docs/testing-sql-server.md`.
