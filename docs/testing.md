# Trạng thái hiện tại

Ứng dụng hiện dùng SQL Server qua API. Xem [kiểm thử SQL Server](testing-sql-server.md) và [cách chạy](../README.md).

Nội dung dưới đây là biên bản SQLite ngày01/11/2026, giữ để đối chiếu lịch sử; không áp dụng như kết quả kiểm chứng SQL Server.
# Biên bản kiểm thử

Ngày 01/11/2026, dữ liệu giả. Windows x64, Flutter 3.47.6, Dart 3.13.5, SQLite Windows qua FFI.

| Mục | Bằng chứng trong docs/evidence | Kết quả |
|---|---|---|
| tool/run_checks.ps1 -Tests @('test','integration_test') | test-results.log | 39 đạt, 0 lỗi |
| flutter analyze --no-pub lib test integration_test tool | analyze.log | Không có vấn đề |
| flutter build windows --release --no-pub | windows-build.log | Build thành công x64 |
| EXE --demo --portable ngoài IDE, sau 8 giây | windows-smoke.log | Xem log; không thay đánh giá UI |
| flutter build apk --release --target-platform android-arm64 --no-pub | android-build.log | Could not connect to the Gradle daemon; chưa APK |
| standard flutter test | Môi trường chặn IPC 127.0.0.1 | Không tuyên bố lệnh chuẩn đạt |

Runner bổ sung chạy cùng suite trên engine Flutter với SQLite thật. Adapter thông báo là giả lập, không chứng minh giao OS. Integration test hai repository với DB dạng tệp, đóng/mở lại; không phải E2E Android.

| Mã | Trường hợp | Nguồn |
|---|---|---|
| DB01 | Bốn bảng, FK, version, thiếu snapshot bị từ chối | test/data/app_database_test.dart |
| DB02 | Một hồ sơ; demo không ghi đè | test/data |
| HE01 | Dấu phẩy/chấm, nhóm số đo, đủ cặp huyết áp | test/health/health_rules_test.dart |
| HE02 | Latest riêng, snapshot, lọc thời gian | test/health/health_repository_test.dart |
| CA01 | UTC+7 qua ngày, 30 ngày, lịch quá khứ | test/care/care_rules_test.dart |
| CA02 | Giữ lịch sử, bật lại ID mới, idempotent, rollback | test/care/care_repository_test.dart |
| NO01 | Không trùng, hủy trước đặt, retry, không phát lại quá hạn | test/notifications/notification_sync_test.dart |
| UI01 | Hồ sơ đầu, nhập sai, bấm lặp, DB lỗi giữ form | test/ui |
| UI02 | 360/768/1280, chữ lớn, bàn phím, form bẩn | test/ui/adaptive_layout_test.dart và health_flow_test.dart |
| UI03 | Tạo khi thiếu quyền, chọn thông báo, xác nhận đến hạn, ID lạ | test/ui/care_flow_test.dart |
| IN01 | Hai quy trình, đóng/mở file DB | integration_test/personal_health_flow_test.dart |

PNG render widget thật trong Flutter engine, viewport hẹp/rộng có nhãn demo. Không phải ảnh thiết bị Android hay bằng chứng giao thông báo.

## Checklist thiết bị chưa kiểm chứng

| Nền tảng | Thao tác và kỳ vọng | Trạng thái |
|---|---|---|
| Android | Build/cài APK, CRUD, đóng/mở còn dữ liệu | Chưa kiểm chứng |
| Android | Từ chối/cấp quyền: lịch còn, cảnh báo/retry | Chưa kiểm chứng |
| Android | Hẹn, đóng app, nhận và mở đúng occurrence | Chưa kiểm chứng |
| Android | Sửa/tắt/lưu trữ hủy alarm cũ | Chưa kiểm chứng |
| Android | Reboot, Doze, battery saver, force stop: ghi độ trễ thực | Chưa kiểm chứng |
| Windows MSIX | Ký/cài; có identity và quyền | Chưa kiểm chứng |
| Windows MSIX | Hẹn, đóng app, toast mở đúng lần | Chưa kiểm chứng |
| Windows MSIX | Sửa/tắt/lưu trữ; reboot không còn lịch cũ | Chưa kiểm chứng |

Không tự cài chứng chỉ/đổi chính sách. Android alarm inexact; Windows có thể bỏ toast khi máy tắt quá lâu. Không bảo đảm giao đúng phút.

Rà soát cuối bổ sung kiểm thử tương thích SQL cũ và giữ nguyên số thập phân khi chỉ sửa ghi chú/tên. Lifecycle sửa/tắt/bật/lưu trữ được kiểm thử ở repository, chưa có đủ widget test cho từng thao tác. Kiểm thử đóng gói riêng: docs/evidence/packaging-regression.log, bảo toàn DB cũ và không chứa DB trong gói mới.

