> **Tài liệu gốc của phiên bản SQLite.** Nội dung công nghệ và sơ đồ ở đây chưa mô tả SQL Server. Đọc [tài liệu SQL Server](sql-server.md) và bản bổ sung trong `deliverables` khi báo cáo phiên bản hiện tại.

Học phần Lập trình đa nền tảng

Công nghệ Flutter và Dart với cơ sở dữ liệu SQLite

Nền tảng mục tiêu Android và Windows

Trường: [Tên trường]
Khoa: [Tên khoa]
Lớp: [Tên lớp]
Sinh viên: Trương Kiến Phi
Mã sinh viên: 1250080141
Giảng viên hướng dẫn: [Họ và tên]
Hạn nộp: [Theo thông báo học phần]

Bản báo cáo ngày 01 tháng 11 năm 2026

Phạm vi đã triển khai gồm hai quy trình cá nhân: ghi nhận chỉ số và quản lý lịch chăm sóc. Bản Windows Release đã build; Android chưa tạo được APK trong môi trường kiểm thử. Dữ liệu và ảnh minh họa trong báo cáo không phải hồ sơ sức khỏe thật.

# Mục lục và cách đọc báo cáo

| Phần | Nội dung |

| 1 | Bài toán, mục tiêu và phạm vi |

| 2 | Yêu cầu và đặc tả hai quy trình |

| 3 | Use Case, Activity và Sequence |

| 4 | Kiến trúc, dữ liệu và xử lý |

| 5 | Giao diện và cài đặt |

| 6 | Kiểm thử và đánh giá |

| 7 | Kết luận, hạn chế và tài liệu tham khảo |

Các tiêu đề dùng Heading của Word để có thể tạo mục lục tự động theo mẫu trường. Mục lục trên là danh mục nội dung, không gán số trang tĩnh. Các thông tin đặt trong ngoặc vuông cần được sinh viên điền trước khi nộp.

## Tóm tắt

Sổ sức khỏe giúp một cá nhân tập trung các lần đo cân nặng, huyết áp, nhịp tim và lịch chăm sóc vào một ứng dụng cục bộ. Flutter đảm nhiệm giao diện trên điện thoại và desktop; Dart tổ chức quy tắc xử lý; SQLite lưu dữ liệu dạng quan hệ. Bản triển khai có kiểm tra đầu vào, giao dịch dữ liệu, lịch sử từng lần nhắc và đồng bộ trạng thái thông báo qua adapter native.

Kết quả tự động là 39 kiểm thử đạt qua runner Flutter không dùng socket và phân tích Dart không còn vấn đề. Bản Windows x64 biên dịch thành công. Bộ kiểm thử không thay cho nghiệm thu giao thông báo trên hệ điều hành; Android và MSIX đã được đưa vào danh sách kiểm chứng tiếp theo.

# 1 Bài toán và phạm vi

## 1 1 Phân tích tình huống sử dụng

Một cá nhân có thể ghi cân nặng vào giấy, giữ số đo huyết áp trong tin nhắn và nhớ lịch tái khám bằng lịch điện thoại. Dữ liệu phân tán khiến việc tìm lần đo gần nhất hoặc xem biến động theo thời gian mất công. Việc đánh dấu đã thực hiện cũng dễ bị nhầm giữa các ngày của một lịch lặp.

Đây là phân tích tình huống giả định phục vụ thiết kế đồ án. Nhóm chưa thực hiện phỏng vấn, khảo sát định lượng hoặc thử nghiệm với người bệnh; báo cáo không coi các nhận định trên là kết quả khảo sát thực địa.

## 1 2 Mục tiêu thực tế

Ứng dụng hỗ trợ ghi chép nhất quán, tìm lại số đo theo ngày và quản lý các việc chăm sóc có thời điểm rõ ràng. Hai quy trình tạo ra dữ liệu có thể lưu, sửa, tra cứu và giữ lại sau khi đóng ứng dụng, đáp ứng yêu cầu giao diện và xử lý của học phần.

| Trong phạm vi | Ngoài phạm vi |

| Một hồ sơ cục bộ, tiếng Việt | Tài khoản, phân quyền, nhiều bệnh nhân |

| Android và Windows dùng chung Dart | Web, iOS, macOS trong đợt này |

| Cân nặng, huyết áp, nhịp tim | Chẩn đoán, phân loại bệnh, chỉ định thuốc |

| Lịch hữu hạn, xác nhận từng lần | Đơn thuốc điện tử, đồng bộ bệnh viện |

| SQLite offline | Cloud, đồng bộ, sao lưu, mã hóa DB |

# 2 Yêu cầu chức năng và quy tắc

| Mã | Yêu cầu | Tiêu chí chấp nhận |

| FR01 | Hồ sơ cá nhân | Tên và chiều cao hợp lệ; chỉ một hồ sơ id = 1 |

| FR02 | Ghi chỉ số | Ít nhất một nhóm; số hữu hạn dương; huyết áp đủ cặp |

| FR03 | Tra cứu chỉ số | CRUD, lọc ngày, 7/30/90 ngày, latest riêng từng nhóm |

| FR04 | Lịch chăm sóc | Thuốc một lần/hằng ngày; tái khám một lần |

| FR05 | Lịch sử từng lần | Chỉ đến hạn mới hoàn thành/bỏ qua; không ghi đè kết quả |

| FR06 | Thông báo | Lưu lịch dù thiếu quyền; cảnh báo và thử lại |

| FR07 | Thích ứng | Điều hướng dưới/bên, form cuộn và giữ dữ liệu khi resize |

Tất cả thời điểm được lưu UTC milliseconds. Lịch dùng ngày ISO và giờ HH:mm theo Việt Nam UTC+7 cố định. Một đợt lặp dài từ 1 đến 30 ngày kể cả hai đầu, một giờ mỗi ngày. Lịch mới phải có lần nhắc trong tương lai. Tái khám không được lặp hằng ngày.

Không tự sửa giờ người dùng nhập để làm cho dữ liệu hợp lệ. Số đo tương lai, nhóm huyết áp thiếu một thành phần hoặc tâm thu không lớn hơn tâm trương đều bị từ chối. Lỗi nhập đặt gần trường; lỗi lưu giữ nội dung và cho thử lại.

## Yêu cầu phi chức năng

Không yêu cầu mạng để ghi chép. Có trạng thái tải, rỗng và lỗi; ngăn bấm lưu nhiều lần; hỏi trước khi bỏ form đang sửa. Không ghi tên thuốc hay số đo vào payload thông báo. Dữ liệu cục bộ chưa mã hóa và phụ thuộc quyền bảo vệ tài khoản/thiết bị.

# 2 1 Quy trình ghi nhận chỉ số

| Thành phần | Đặc tả |

| Tác nhân | Cá nhân đang dùng ứng dụng |

| Tiền điều kiện | Đã tạo hồ sơ với chiều cao; database mở được |

| Kích hoạt | Chọn Thêm chỉ số tại nhật ký |

| Đầu vào | Thời điểm đo, các nhóm số đo, ghi chú tùy chọn |

| Hậu điều kiện thành công | Một bản ghi được commit, danh sách và biểu đồ tải lại |

| Hậu điều kiện thất bại | Không lưu một phần; form còn nội dung |

## Luồng chính

Người dùng mở form, chọn thời điểm đo và nhập ít nhất một nhóm chỉ số. UI chuẩn hóa số thập phân với dấu phẩy hoặc chấm và gọi quy tắc kiểm tra. Khi hợp lệ, repository mở transaction, lấy chiều cao hồ sơ nếu bản ghi có cân nặng và ghi dữ liệu. Sau commit, form đóng và màn hình nhật ký truy vấn lại.

Người dùng có thể chọn nhóm chỉ số, khoảng 7/30/90 ngày hoặc khoảng ngày tùy chọn. Sửa bản ghi giữ snapshot chiều cao đã có; thêm cân nặng vào bản chưa có sẽ lấy chiều cao hiện tại. Bỏ cân nặng sẽ bỏ snapshot tương ứng. Xóa cần xác nhận và cập nhật lại kết quả.

## Luồng ngoại lệ

Nếu thiếu nhóm số đo hoặc sai cặp huyết áp, không gọi lưu. Nếu database báo lỗi, giao diện hiện thông báo và cho thử lại mà không xóa nội dung. Nếu bản ghi đã bị xóa trước khi sửa, repository báo không tồn tại. Khi rời form bẩn, người dùng chọn tiếp tục sửa hoặc bỏ thay đổi.

# 2 2 Quy trình lịch chăm sóc

| Thành phần | Đặc tả |

| Tiền điều kiện | Có hồ sơ; ngày giờ Việt Nam được xác định |

| Đầu vào | Loại, tiêu đề, ngày bắt đầu/kết thúc, giờ, quy tắc lặp, ghi chú |

| Hậu điều kiện lưu | Kế hoạch và occurrence được lưu cùng transaction |

| Hậu điều kiện xác nhận | Một occurrence chuyển completed hoặc skipped, có resolved_at_utc |

| Ngoại lệ quyền OS | Lịch vẫn lưu; trạng thái lỗi/cảnh báo và hành động thử lại |

## Luồng chính và thay đổi kế hoạch

Người dùng tạo lịch. Bộ quy tắc kiểm tra loại lặp, giới hạn ngày và thời điểm tương lai; repository sinh từng occurrence bằng UTC+7 rồi lưu nguyên tử cùng kế hoạch. NotificationSync đối chiếu các ID đang chờ trong OS và thực hiện hủy/đặt cần thiết. Khi đến hạn, người dùng mở chi tiết và chọn Hoàn thành hoặc Bỏ qua.

Khi sửa, chỉ các lần tương lai đang chờ được hủy và thay bằng lần mới; lần quá hạn và kết quả đã có được giữ. Khi tắt hoặc lưu trữ, các lần đang chờ bị hủy, kết quả đã ghi vẫn tồn tại. Bật lại sinh các lần tương lai có ID mới. Lưu trữ là xóa mềm kế hoạch, không xóa lịch sử.

Một lần xác nhận cùng kết quả lần hai không đổi thời điểm xử lý; đổi kết quả sau khi đã xử lý bị từ chối. Không cho xác nhận sớm. Nếu hủy OS thất bại, đồng bộ chặn đặt thay thế cho lịch đó và lưu lỗi để thử lại, giảm khả năng tồn tại lịch cũ và mới cùng lúc.

# 3 1 Use Case tổng quát

![Hình 1 Use Case của ứng dụng](docs/diagrams/use_case_report.png)

Cá nhân là tác nhân sử dụng duy nhất. Hệ điều hành cung cấp thông báo, không phải vai trò đăng nhập. Các use case được nhóm theo nghiệp vụ; CRUD là các thao tác trong nhóm quản lý.

# 3 2 Activity ghi chỉ số

![Hình 2 Luồng xử lý ghi số đo](docs/diagrams/activity_health_report.png)

Nhánh không hợp lệ quay lại bước nhập. Transaction chỉ bắt đầu sau kiểm tra. Lỗi lưu không làm mất dữ liệu đang nhập; màn hình tra cứu tải lại sau commit.

# 3 3 Activity lịch chăm sóc

![Hình 3 Luồng kế hoạch và từng lần thực hiện](docs/diagrams/activity_care_report.png)

Lưu kế hoạch và giao thông báo là hai trạng thái khác nhau. Việc từ chối quyền không làm mất lịch; xác nhận là hành động của người dùng, không tự coi thông báo đã giao là đã hoàn thành.

# 3 4 Sequence ghi chỉ số

![Hình 4 Các lời gọi chính khi lưu số đo](docs/diagrams/sequence_health_report.png)

HealthRepo trong sơ đồ là HealthRepository. Nhánh lỗi trả về UI để giữ form. Các lời gọi SQL được thực hiện trong transaction; hình lược bỏ xử lý lỗi chi tiết.

# 3 5 Sequence lịch chăm sóc

![Hình 5 Các lời gọi chính của lịch chăm sóc](docs/diagrams/sequence_care_report.png)

CareRepo là CareRepository; NotifySync là NotificationSync. Bộ đồng bộ gọi NotificationPort/adapter OS, xử lý trạng thái từng occurrence. Sơ đồ lược bỏ phản hồi và chi tiết native; mã nguồn thể hiện đầy đủ.

# 4 1 Kiến trúc ứng dụng

![Hình 6 Phân tách giao diện nghiệp vụ và nền tảng](docs/diagrams/architecture_report.png)

UI sử dụng AppServices và repository; quy tắc Dart độc lập nền tảng. Android dùng sqflite, Windows dùng sqflite_common_ffi với winsqlite3. MethodChannel nối Dart với Kotlin AlarmManager và C++ WinRT.

# 4 2 Mô hình quan hệ dữ liệu

![Hình 7 ERD bốn bảng SQLite](docs/diagrams/erd_report.png)

Mỗi bản ghi đo và kế hoạch thuộc profile id = 1. Mỗi kế hoạch có nhiều occurrence. Cả bốn bảng có created_at_utc; profiles, health_records và care_reminders có updated_at_utc. Các cột chi tiết được mô tả ở các trang sau.

# 4 3 Từ điển dữ liệu hồ sơ và chỉ số

| Bảng và trường | Kiểu | Ý nghĩa và ràng buộc |

| profiles.id | INTEGER PK | CHECK id = 1, một hồ sơ |

| full_name / birth_date | TEXT | Tên NOT NULL không rỗng; ngày sinh tùy chọn |

| height_cm | REAL | NOT NULL, hữu hạn và > 0 |

| target_weight_kg | REAL | Tùy chọn, hữu hạn và > 0 |

| created_at_utc / updated_at_utc | INTEGER | NOT NULL UTC milliseconds |

| health_records.id / profile_id | INTEGER | PK AUTOINCREMENT; FK profiles, NOT NULL |

| measured_at_utc | INTEGER | NOT NULL, thời điểm đo |

| weight_kg / height_cm_snapshot | REAL | Tùy chọn; có cân nặng phải có snapshot dương |

| systolic / diastolic | INTEGER | Cùng null hoặc đủ cặp; tâm thu > tâm trương > 0 |

| heart_rate | INTEGER | Null hoặc > 0 |

| note | TEXT | NOT NULL, mặc định rỗng |

| created_at_utc / updated_at_utc | INTEGER | NOT NULL, thời điểm tạo/cập nhật |

CHECK yêu cầu ít nhất một trong weight_kg, systolic, heart_rate khác NULL. Ràng buộc snapshot kiểm tra IS NOT NULL tường minh vì SQLite coi kết quả CHECK là NULL khác với vi phạm bằng 0 [2]. Quy tắc ngày và tính hữu hạn tiếp tục được kiểm tra ở Dart trước khi ghi.

Chỉ mục health_time(measured_at_utc DESC, id DESC) phục vụ lọc và sắp xếp. Truy vấn latestByMetric lọc cột của từng nhóm khác NULL và lấy dòng đầu; không lấy một bản ghi chung rồi coi các trường trống là mất dữ liệu.

# 4 4 Từ điển dữ liệu lịch chăm sóc

| Bảng và trường | Kiểu | Ý nghĩa và ràng buộc |

| care_reminders.id / profile_id | INTEGER | PK AUTOINCREMENT; FK hồ sơ |

| type | TEXT | medication hoặc appointment |

| title / note | TEXT | Tiêu đề không rỗng; ghi chú mặc định rỗng |

| repeat_rule | TEXT | none hoặc daily; appointment chỉ none |

| start_date / end_date | TEXT | ISO, độ dài đợt 1–30 ngày |

| local_time / timezone_id | TEXT | HH:mm; Asia/Ho_Chi_Minh |

| is_enabled / is_archived | INTEGER | 0 hoặc 1, bật và lưu trữ |

| created_at_utc / updated_at_utc | INTEGER | NOT NULL UTC milliseconds |

| reminder_occurrences.id | INTEGER PK | AUTOINCREMENT, 1 đến 2147483647; dùng làm notification ID |

| reminder_id | INTEGER FK | NOT NULL, care_reminders |

| scheduled_at_utc | INTEGER | NOT NULL thời điểm đến hạn |

| status | TEXT | pending / completed / skipped / cancelled |

| resolved_at_utc | INTEGER | Thời điểm xác nhận, tùy chọn |

| notification_state | TEXT | pending_schedule / scheduled / pending_cancel / cancelled / failed |

| notification_error | TEXT | Mã lỗi tùy chọn, không chứa dữ liệu sức khỏe |

| created_at_utc | INTEGER | NOT NULL |

Unique index một phần trên (reminder_id, scheduled_at_utc) với status khác cancelled ngăn lần hiệu lực trùng nhau. Index occurrence_time(scheduled_at_utc, status) phục vụ lịch trong ngày. Ngày/giờ và điều kiện tương lai được xác nhận tại care_rules trước khi lưu.

# 4 5 Thuật toán và tính nhất quán

## Lịch hữu hạn theo giờ Việt Nam

Bộ sinh lịch kết hợp ngày ISO với HH:mm ở UTC+7, trừ 7 giờ để chuyển UTC. Lặp từng ngày trong khoảng đã kiểm tra tối đa 30 ngày. Các lần tương lai mới được tạo khi bật lại; không phát lại những lần đã quá hạn. Kiểm thử bao gồm thời điểm qua ranh giới ngày để tránh dùng nhầm giờ máy.

## Đồng bộ với hệ điều hành

NotificationSync thực hiện theo hàng đợi nối tiếp để không có hai lượt đồng bộ cạnh tranh. Bộ đồng bộ kiểm tra quyền mà không tự mở hộp xin quyền khi khởi động; người dùng chủ động bấm bật nhắc nhở. Danh sách pendingIds từ adapter được dùng để không đặt trùng. Trạng thái scheduled chỉ có nghĩa OS đã nhận lệnh đặt, không chứng minh thông báo đã hiện.

Mỗi occurrence có trạng thái nghiệp vụ và trạng thái thông báo riêng. Lệnh hủy được xử lý trước lệnh đặt mới. Sau phản hồi native, cập nhật DB có điều kiện để tránh kết quả cũ ghi đè thay đổi mới. Lỗi được giữ dưới dạng mã để retry. Khi resume, ứng dụng chạy đối chiếu lại; ID không còn hợp lệ mở danh sách lịch với giải thích thay vì một chi tiết sai.

## Giao dịch và phiên bản dữ liệu

SQLite bật PRAGMA foreign_keys = ON. Tạo/sửa kế hoạch và occurrence dùng transaction: lỗi giữa chừng rollback cả thao tác. Schema hiện tại version 1. Nhánh nâng/hạ phiên bản chưa hỗ trợ trả lỗi, không tự xóa database. Trước khi thay đổi schema ở bản sau cần viết migration có kiểm thử với dữ liệu cũ.

Phiên bản hiện tại lưu snapshot chiều cao nhưng chưa tính hoặc hiển thị BMI. Trường này giữ ngữ cảnh của số đo và có thể phục vụ mở rộng sau này; không có phân loại hoặc chẩn đoán.

# 5 1 Thiết kế giao diện và tương tác

Ứng dụng có bốn khu vực: Tổng quan, Chỉ số, Lịch chăm sóc và Hồ sơ. Chiều rộng dưới 600 logical px dùng NavigationBar phía dưới; từ 600 dùng NavigationRail, từ 1050 mở rộng nhãn bên. Một AppShell giữ lựa chọn màn hình và form khi đổi kích thước, tránh mất nội dung đang nhập.

| Trạng thái | Cách xử lý |

| Đang tải | Hiện tiến trình trong vùng nội dung, giữ bố cục ổn định |

| Danh sách rỗng | Giải thích và nút tạo mục đầu tiên |

| Nhập sai | Thông báo gần trường, không xóa dữ liệu |

| Lỗi DB | Thông báo thử lại; form vẫn còn nội dung |

| Form bẩn | Hỏi trước khi rời màn hình |

| Đang lưu | Khóa thao tác gửi lặp |

| Thiếu quyền OS | Lịch còn trong DB, cảnh báo và nút thử lại |

Màu nền sáng, chữ slate đậm và màu nhấn xanh giúp phân biệt nội dung, thao tác. Các chuỗi giao diện bằng tiếng Việt, định dạng ngày dd/MM/yyyy và số theo locale. Form cuộn để tránh bàn phím che nút; biểu đồ có nhãn trục, khoảng thời gian và trạng thái khi thiếu dữ liệu.

Ảnh ở các trang sau là kết quả render thực tế của Flutter engine từ bộ kiểm thử. Cùng mã nguồn được đặt ở viewport 360 và 1280 logical px. Các ảnh chứng minh bố cục, không chứng minh chạy Android trên máy thật hoặc nhận thông báo OS.

# 5 2 Giao diện trên chiều rộng điện thoại

![Hình 8 Nhật ký chỉ số ở viewport hẹp](docs/evidence/mobile_health.png)

Thanh điều hướng dưới giữ bốn khu vực nhất quán. Bộ lọc và hành động xuống dòng khi không đủ chiều rộng. Dữ liệu minh họa có banner rõ ràng. Ảnh chưa phải ảnh chụp từ thiết bị Android.

# 5 3 Giao diện trên desktop

![Hình 9 Nhật ký chỉ số ở viewport desktop](docs/evidence/desktop_health.png)

Ở màn hình rộng, điều hướng chuyển sang bên trái, biểu đồ dùng vùng nội dung rộng và lịch sử tiếp tục cuộn. Bộ kiểm thử xác nhận resize không làm mất form bẩn. Biểu đồ không cung cấp kết luận chẩn đoán từ đường xu hướng.

# 5 4 Cài đặt và đóng gói

Máy build dùng Flutter 3.47.6, Dart 3.13.5, Visual Studio 2022 C++ desktop, Windows SDK 10.0.26100 và JDK 21. pubspec.lock giữ phiên bản thư viện. Cần SDK/cache có quyền ghi. Trên máy khác chạy flutter pub get, flutter analyze, flutter test rồi build theo nền tảng.

| Lệnh | Kết quả hoặc cách dùng |

| flutter build windows --release | EXE trong build/windows/x64/runner/Release |

| Chay_Demo.cmd | Demo riêng, data/demo_health.db cạnh EXE |

| Chay_Ca_Nhan.cmd | Hồ sơ thật riêng, data/personal_health.db |

| Không tham số dòng lệnh | Lưu application support theo nền tảng |

| tool/package_windows.ps1 | Portable và MSIX chưa ký |

| flutter build apk --release | Chưa tạo APK vì Gradle daemon bị chặn |

Portable phải giữ EXE, DLL và data assets cùng nhau, đặt tại nơi có quyền ghi. Gói MSIX đăng ký protocol suckhoe-ca-nhan; cần chứng chỉ đúng Publisher và cài theo chính sách máy để có package identity. Chưa ký/cài gói trong phiên làm việc này, không tự cài trust hoặc thay bảo mật.

Android dùng AlarmManager inexact; hệ điều hành có thể trì hoãn do Doze/tiết kiệm pin [3]. Windows scheduled toast có giới hạn giao khi máy tắt [4]. Các hành vi mở app từ thông báo, reboot, force stop và hủy lịch cần nghiệm thu trên thiết bị. Release Android còn debug signing theo scaffold, chưa đủ điều kiện phát hành chính thức.

# 6 1 Kiểm thử và bằng chứng

Đã chạy 39 kiểm thử đạt, không lỗi, bằng runner socket-free với engine Flutter và SQLite thật. Standard flutter test không kết nối được 127.0.0.1 trong sandbox; báo cáo không coi lệnh chuẩn đã chạy thành công. Adapter OS được giả lập để kiểm tra logic; không suy ra thông báo native đã giao.

| Nhóm | Nội dung đã kiểm tra | Bằng chứng |

| Dữ liệu | Schema/FK, hồ sơ, demo không ghi đè, snapshot bắt buộc | test/data |

| Chỉ số | Đầu vào, latest độc lập, snapshot, truy vấn ngày | test/health |

| Lịch | 30 ngày, UTC+7, sửa giữ lịch sử, rollback, resolve | test/care |

| Thông báo | Không trùng, hủy trước thay, lỗi/retry, quá hạn | test/notifications |

| Giao diện | Form bẩn, resize/chữ lớn, lỗi DB, bấm lặp, routing | test/ui |

| Tích hợp DB | CRUD và xác nhận, đóng/mở file vẫn còn dữ liệu | integration_test |

Phân tích Dart không có vấn đề. Windows Release build thành công, tiến trình chạy ngoài IDE sau kiểm tra 8 giây và tạo demo database. Gói MSIX được tạo nhưng chưa ký/cài. Build APK thất bại ở kết nối Gradle daemon; chưa có APK bàn giao. Log lệnh được lưu trong docs/evidence.

Một kiểm thử bổ sung bắt lỗi CHECK của SQLite cho trường snapshot: trước sửa, INSERT cân nặng không snapshot được chấp nhận; sau thêm IS NOT NULL, INSERT bị từ chối. Kiểm thử dữ liệu tích hợp xác nhận hai quy trình vẫn tồn tại khi đóng và mở lại file database.

# 6 2 Đánh giá và kiểm chứng còn lại

| Yêu cầu | Mức đáp ứng |

| Ít nhất hai quy trình có ý nghĩa thực tế | Đã triển khai ghi chỉ số và lịch chăm sóc |

| Xây dựng giao diện và thiết kế xử lý | Có UI thích ứng, quy tắc Dart và repository |

| SQLite lưu cục bộ | Đã kiểm thử thực với in-memory và file DB |

| Windows desktop | Build Release và khởi chạy tiến trình |

| Android mobile | Có source và UI hẹp; chưa build/cài APK |

| Thông báo hệ điều hành | Có adapter; chưa nghiệm thu Android/MSIX |

| Báo cáo và trình bày | DOCX, PPTX 11 slide, nguồn sơ đồ và kịch bản |

Các bước còn lại trước nghiệm thu thực tế: trên Android build/cài, kiểm tra từ chối/cấp quyền, mở/đóng app, reboot, Doze và force stop; trên Windows ký/cài MSIX, kiểm tra identity, đặt/hủy, nhận và mở đúng occurrence khi app đóng. Mỗi thử nghiệm cần ghi giờ dự kiến, giờ thực tế và trạng thái ứng dụng.

Không có cam kết độ trễ hoặc giao chắc chắn khi chưa thử. Chưa đánh giá hiệu năng trên hàng chục nghìn bản ghi, chưa thực hiện kiểm thử khả dụng với người dùng thật, chưa có mã hóa database hoặc sao lưu. Không dùng số lượng kiểm thử tự động để thay thế các giới hạn này.

# 7 Kết luận và hướng phát triển

Đồ án đã xây dựng nền tảng ghi chép sức khỏe cá nhân bằng Flutter/Dart và SQLite, với hai quy trình hoàn chỉnh ở lớp giao diện, nghiệp vụ và lưu trữ. Thiết kế tách kế hoạch khỏi từng lần thực hiện giúp giữ lịch sử nhất quán. Việc dùng chung mã Dart và adapter riêng minh họa cách tổ chức ứng dụng đa nền tảng.

Bản Windows Release cùng tài liệu và bộ kiểm thử có thể dùng để trình bày học phần. Mức hoàn thành Android và thông báo native cần được mô tả đúng: có triển khai nguồn, chưa có kết quả nghiệm thu thiết bị. Không coi ứng dụng là công cụ chẩn đoán hay hệ thống nhắc thuốc bảo đảm đúng thời gian.

## Hướng phát triển ưu tiên

Ưu tiên trước hết là kiểm chứng Android và MSIX trên máy thật, sửa các khác biệt nền tảng rồi cấu hình ký phát hành. Bước tiếp theo là migration schema có kiểm thử, cải thiện khả năng truy cập theo phản hồi sử dụng và đánh giá dữ liệu lớn. Nếu mở rộng sao lưu/đồng bộ, cần thiết kế quyền đồng ý, mã hóa và giải quyết xung đột thay vì chỉ chép file SQLite giữa hai máy.

## Tệp bàn giao

Mã nguồn Flutter và native; Windows portable; MSIX chưa ký; báo cáo DOCX; bài trình bày 11 slide; PPTX sơ đồ kỹ thuật chỉnh sửa được; biên bản kiểm thử, log và kịch bản demo. Không bao gồm SDK/cache lớn hoặc khóa ký cá nhân. Metadata trường/lớp/sinh viên/giảng viên/hạn nộp cần được điền bởi người thực hiện.

# Tài liệu tham khảo

[1] Flutter
Persistent storage architecture SQL và Persist data with SQLite. Tài liệu chính thức.
https://docs.flutter.dev/app-architecture/design-patterns/sql
https://docs.flutter.dev/cookbook/persistence/sqlite

[2] SQLite
CREATE TABLE, mục CHECK constraints. Tài liệu chính thức.
https://www.sqlite.org/lang_createtable.html

[3] Android Developers
Schedule alarms. Quy tắc inexact alarms và giới hạn hệ điều hành.
https://developer.android.com/develop/background-work/services/alarms

[4] Microsoft Learn
Schedule an app notification. ScheduledToastNotification và hủy lịch.
https://learn.microsoft.com/en-us/windows/apps/develop/notifications/app-notifications/app-notifications-scheduled

Các trang tham khảo được kiểm tra ngày 01/11/2026. Báo cáo diễn giải theo thiết kế và triển khai dự án; không sao chép bài hướng dẫn. Phiên bản dependency chính xác nằm trong pubspec.lock.

## Nguồn kiểm chứng nội bộ

lib/data/schema.dart; lib/features/health/health_repository.dart; lib/features/care/care_repository.dart; lib/notifications/notification_sync.dart; android/app/src/main/kotlin; windows/runner/health_notifications.cpp; docs/testing.md; docs/evidence/test-results.log và các log build/analyze.
