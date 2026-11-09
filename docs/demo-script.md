# Kịch bản demo và bảo vệ

> **Lưu trữ SQLite (bản cũ).** Các bước dùng `Chay_Demo.cmd` không áp dụng cho ứng dụng SQL Server. Để demo bản mới, khởi động API theo [README](../README.md), chạy `tool/run_app.ps1` và thực hiện hai quy trình sức khỏe, nhắc việc; xem [hướng dẫn SQL Server](sql-server.md).

Gợi ý 8–10 phút, không phải hạn nộp do giảng viên giao. Điền metadata DOCX/PPTX trước khi nộp.

1. Mở Chay_Demo.cmd, chỉ rõ banner giả. Thu nhỏ/phóng rộng để thấy điều hướng thích ứng.
2. Tổng quan: latest riêng từng nhóm; bản mới chỉ có nhịp tim không làm mất cân nặng trước đó.
3. Thêm 65,5 kg. Thử chỉ tâm thu để báo thiếu cặp; thêm tâm trương rồi lưu. Đổi 7/30/90 ngày. Sửa ghi chú, xóa bản thử có xác nhận.
4. Hồ sơ: giải thích snapshot chiều cao giữ ngữ cảnh số đo. Chưa tính BMI. Không kết luận y khoa.
5. Tạo lịch thuốc ba ngày, một giờ/ngày và tái khám một lần. Mỗi occurrence có kết quả riêng. Tương lai chưa được xác nhận.
6. Để demo hoàn thành UI: tạo lịch trước buổi bảo vệ và chờ qua hạn thật, bấm làm mới nếu cần. Không đổi giờ hệ thống. Clock kiểm thử không là tùy chọn phát hành.
7. Sửa giờ: giữ lịch sử; tắt/bật/lưu trữ lịch thử, xem nhóm đã lưu trữ.
8. Nêu giới hạn portable/MSIX và Android chưa APK vì Gradle bị chặn. Không giả thông báo thành công.
9. Đóng/mở lại cùng chế độ để thấy SQLite lưu dữ liệu.

## Câu hỏi bảo vệ

**Vì sao SQLite?** Một cá nhân, offline, truy vấn theo ngày và transaction. Không tự đồng bộ giữa máy.

**Vì sao bốn bảng?** Tách hồ sơ, số đo, kế hoạch, từng lần thực hiện. Completed của cả lịch lặp không biểu diễn kết quả từng ngày.

**Tránh nhắc trùng?** ID ổn định, đối chiếu pending OS, hủy trước thay thế, lưu lỗi để retry. Schedule thành công không chứng minh OS giao.

**Sửa có mất lịch sử?** Thay lần tương lai, giữ lần đã xử lý. Tắt/lưu trữ hủy lần chờ và giữ kết quả.

**Giới hạn?** Chưa nghiệm thu thiết bị, không bảo đảm đúng phút, DB chưa mã hóa. Phạm vi ghi chép đồ án.

**Phát triển tiếp?** Kiểm chứng Android/MSIX, ký phát hành, migration có test, sao lưu mã hóa theo sự đồng ý.
