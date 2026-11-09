# Kiểm tra tài liệu

> **Biên bản bản giao SQLite cũ.** Kết quả kiểm tra DOCX/PPTX dưới đây không chứng minh tài liệu hay backend SQL Server; xem [kiểm thử hiện tại](testing-sql-server.md).

DOCX được tạo bằng python-docx với Normal Times New Roman 13, A4, tiêu đề đen, không có đường viền đoạn tiêu đề. Đã kiểm tra gói OOXML và 24 trang render. Canonical render_docx.py không chạy được vì môi trường không có LibreOffice soffice.exe; fallback nhập chính DOCX bằng DocumentFile của artifact-tool, nhúng font Times New Roman từ Windows và xuất PDF để raster hóa bằng Poppler. Bản PDF/PNG chỉ dùng QA, không là tệp bàn giao chính. Chưa đối chiếu bố cục bằng Microsoft Word.

PPTX tạo bằng artifact-tool: 11 slide chính và 7 slide sơ đồ kỹ thuật. Native text/shape/connector có thể chỉnh sửa; ảnh UI nhúng bytes thực, không media rỗng. Đã render và xem toàn bộ slide. Package integrity và layout geometry không có lỗi; font Arial được kiểm tra ở mức package, không đồng nghĩa thử PowerPoint native. Finalizer hoàn tất kiểm tra/import nhưng Windows từ chối hard link khi promote; đã sao chép candidate đã kiểm tra rồi chạy validator trên tệp bàn giao.

UI audit strict không có findings. Các kiểm tra này không chứng minh Android hay thông báo OS đã chạy. Tham khảo docs/testing.md.
