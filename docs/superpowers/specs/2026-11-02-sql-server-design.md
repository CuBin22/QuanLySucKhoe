# Chuyển SQL Server

02/11/2026. Người dùng yêu cầu đổi database và đã cho phép tự quyết, không hỏi lại. Thực thi tuần tự.

Flutter gọi ASP.NET Core9 API C#, API dùng Microsoft.Data.SqlClient7.1.1 và SQL Server. Không chứa mật khẩu SQL hay endpoint SQL tùy ý trong app. Giữ giao diện và hai quy trình. Bốn bảng nghiệp vụ giữ ID, snapshot, lịch sử; trạng thái thông báo tách riêng theo thiết bị. API token cá nhân từ môi trường, HTTPS khi triển khai; kiểm tra đầu vào/thời gian ở server. Một hồ sơ, không thêm đăng nhập hoặc đa người dùng.

SQLite bỏ khỏi production, chỉ dùng adapter kiểm thử và xuất dữ liệu cũ. Khi mất API, báo lỗi và giữ form, không tự ghi DB khác. Lịch OS đã đặt vẫn hoạt động theo giới hạn OS; sửa từ máy khác chỉ hủy trên thiết bị offline khi app đó kết nối lại. Đổi backend phải hủy pending OS cũ để tránh trùng ID.

Xuất SQLite chỉ đọc sang JSON, nhập CLI vào SQL Server rỗng trong transaction, giữ ID/snapshot/lịch sử. Không xóa source hoặc ghi đè target đã có dữ liệu. Binary/báo cáo SQLite cũ được ghi rõ là bản lưu trước chuyển.

Kết nối SQL trực tiếp từ Flutter làm lộ thông tin SQL; giữ SQLite và đồng bộ hai chiều tăng phạm vi ngoài yêu cầu. Chọn API ASP.NET vì SDK9 đã cài và SQL Server được hỗ trợ. Phải phân biệt test hợp đồng/giả lập với kiểm chứng SQL Server thật.
