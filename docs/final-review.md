# Rà soát cuối và xử lý

Một lượt rà soát độc lập đã kiểm tra source, native adapters, dữ liệu và các tuyên bố trong tài liệu. Không phát hiện Critical; ba lỗi Important được sửa trong lượt hoàn thiện:

1. Hồ sơ dùng UPSERT không phù hợp SQLite cũ của Android. Đổi sang UPDATE rồi INSERT trong transaction, giữ created_at và liên kết. Kiểm thử boundary SQL trước3.24 và dữ liệu thật đã thêm. Tham chiếu chính thức: https://www.sqlite.org/releaselog/3_24_0.html và https://developer.android.com/reference/android/database/sqlite/package-summary . Đây là kiểm chứng source/SQL, chưa thay nghiệm thu thiết bị.
2. Form sửa dùng định dạng hiển thị làm tròn2 chữ số, gây thay số đo khi chỉ sửa ghi chú/tên. Tách editNumber giữ giá trị round-trip, gồm số nhỏ dạng exponent. Đã quan sát lỗi65.23456789 thành65.23 trước sửa; kiểm thử widget lưu lại dữ liệu thật sau sửa.
3. Đóng gói lại có nguy cơ đưa DB cũ vào MSIX. Staging mới mỗi lần, lọc DB/sidecar ở mọi lần copy; giữ thư mục portable đang dùng và xuất thư mục mới khi đã tồn tại. Kiểm thử riêng tạo DB/sidecar sentinel, kiểm tra chúng còn nguyên và không nằm trong portable/MSIX mới.

Tài liệu đã sửa hai điểm: chưa có tính/hiển thị BMI (chỉ lưu snapshot chiều cao); các thao tác vòng đời lịch được kiểm thử ở repository, không tuyên bố đầy đủ widget coverage. Các giới hạn Android/OS/MSIX vẫn giữ rõ ràng.
