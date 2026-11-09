# Thiết kế đồ án: Ứng dụng quản lý sức khỏe cá nhân

Ngày: 31/10/2026. Trạng thái: ĐÃ ĐƯỢC NGƯỜI DÙNG DUYỆT ngày 31/10/2026.

## 1. Những nội dung đã thống nhất

- Đề tài: Xây dựng ứng dụng quản lý sức khỏe.
- Đối tượng: cá nhân tự quản lý sức khỏe, không phải nhân viên phòng khám.
- Công nghệ bắt buộc: Flutter, Dart và SQLite.
- Chạy trên mobile và desktop.
- Phương án đã chọn: dùng chung giao diện thích ứng theo kích thước cửa sổ; dùng chung xử lý nghiệp vụ và dữ liệu.
- Đồ án cần phân tích nghiệp vụ, cài đặt ứng dụng, viết báo cáo và chuẩn bị nội dung trình bày; có ít nhất hai quy trình thực tế.

Các chi tiết còn lại dưới đây là đề xuất của người thiết kế. Chúng chỉ trở thành phạm vi triển khai khi bản thiết kế này được duyệt.

## 2. Mục đích và phạm vi

Ứng dụng giúp một cá nhân ghi lại các chỉ số do mình đo, xem diễn biến theo thời gian và quản lý lịch chăm sóc sức khỏe. Hai công việc được giải quyết là ghi chép sức khỏe phân tán và dễ quên các lịch cá nhân đã đặt.

- Nền tảng triển khai đề xuất: Android và Windows, phù hợp môi trường phát triển Windows hiện có. iOS, macOS, Linux và web không thuộc phạm vi kiểm chứng của bản đầu.
- Mỗi bản cài có một hồ sơ cá nhân, không đăng nhập, hoạt động ngoại tuyến.
- Dữ liệu nằm trong SQLite tại thư mục dữ liệu riêng của ứng dụng trên từng thiết bị. Điện thoại và máy tính không tự đồng bộ dữ liệu.
- Ngôn ngữ giao diện: tiếng Việt. Đơn vị: cm, kg, mmHg và nhịp/phút.
- Tất cả lịch trong bản đầu theo giờ Việt Nam, hiển thị rõ UTC+7; không tự đổi giờ uống thuốc khi thiết bị chuyển múi giờ.
- Ứng dụng ghi nhận dữ liệu và lịch do người dùng nhập; không chẩn đoán, phân loại bệnh hoặc đề xuất thuốc/liều dùng.
- Không thêm quản lý phòng khám, tài khoản bác sĩ, tư vấn AI, thiết bị đeo hoặc dịch vụ máy chủ vào bản đầu.

Thành công là hai quy trình hoạt động đầy đủ trên cả hai nền tảng, dữ liệu tồn tại sau khi mở lại ứng dụng, và báo cáo mô tả đúng phần đã cài đặt, kiểm thử.

## 3. Các phương án đã cân nhắc

| Phương án | Nội dung | Đánh đổi | Kết quả |
| --- | --- | --- | --- |
| Giao diện thích ứng | Một bộ màn hình, bố cục thay đổi theo không gian cửa sổ | Ít mã trùng, dễ bảo trì; cần kiểm tra nhiều độ rộng | Người dùng chọn phương án 1 |
| Giao diện riêng theo nền tảng | Thiết kế bộ màn hình mobile và desktop riêng | Tối ưu từng nền tảng, nhưng tăng công sức xây dựng và kiểm thử | Không chọn |

SQLite cục bộ được giữ theo yêu cầu. Đồng bộ nhiều thiết bị cần một thiết kế khác và không được ngầm đưa vào phạm vi.

## 4. Tác nhân và chức năng

Tác nhân nghiệp vụ duy nhất là người dùng cá nhân. Hệ điều hành cung cấp dịch vụ thông báo, không phải một vai trò đăng nhập.

| Nhóm | Chức năng |
| --- | --- |
| Hồ sơ | Tạo và sửa họ tên, ngày sinh tùy chọn, chiều cao, cân nặng mục tiêu tùy chọn |
| Chỉ số | Thêm, xem, sửa, xóa bản ghi cân nặng, huyết áp, nhịp tim; lọc theo khoảng ngày |
| Diễn biến | Xem biểu đồ 7, 30 hoặc 90 ngày cho từng chỉ số |
| Lịch chăm sóc | Tạo, xem, sửa, bật/tắt và xóa lịch uống thuốc hoặc tái khám |
| Thực hiện lịch | Xem các lần đến hạn, đánh dấu hoàn thành hoặc bỏ qua, xem lịch sử |
| Tổng quan | Xem giá trị gần nhất của từng chỉ số và các lịch hôm nay |

## 5. Quy trình 1: Theo dõi chỉ số sức khỏe

### Luồng chính

1. Lần đầu mở ứng dụng, người dùng tạo hồ sơ; sau đó vào trang tổng quan.
2. Người dùng chọn thêm chỉ số, nhập thời điểm đo và ít nhất một nhóm dữ liệu: cân nặng, cặp huyết áp hoặc nhịp tim.
3. Ứng dụng kiểm tra dữ liệu, hiển thị lỗi ngay tại trường cần sửa.
4. Dữ liệu hợp lệ được lưu SQLite. Chỉ thông báo thành công sau khi lưu thành công.
5. Tổng quan, lịch sử và biểu đồ cập nhật từ dữ liệu đã lưu.
6. Người dùng có thể sửa bản ghi hoặc xóa sau khi xác nhận; biểu đồ phản ánh thay đổi ngay.

### Quy tắc

- Họ tên không được rỗng sau khi loại bỏ khoảng trắng đầu và cuối. Chiều cao là số hữu hạn lớn hơn 0.
- Ngày sinh, nếu nhập, không được ở tương lai. Cân nặng mục tiêu, nếu nhập, phải hữu hạn và lớn hơn 0.
- Thời điểm đo không được ở tương lai. Có thể ghi nhiều lần đo trong một ngày.
- Một bản ghi phải có ít nhất một nhóm chỉ số. Cân nặng và nhịp tim phải hữu hạn, lớn hơn 0 khi có nhập.
- Khi nhập huyết áp phải có cả tâm thu và tâm trương; cả hai lớn hơn 0 và tâm thu lớn hơn tâm trương. Đây là kiểm tra tính nhất quán dữ liệu, không phân loại sức khỏe.
- Hỗ trợ nhập phần thập phân bằng dấu phẩy hoặc dấu chấm, nhưng từ chối dữ liệu mơ hồ có nhiều dấu phân cách.
- Lưu chiều cao tại thời điểm ghi cân nặng để sau này sửa hồ sơ không làm đổi thông tin lịch sử. Không bổ sung phân loại BMI trong bản đầu.
- Tổng quan tìm bản ghi mới nhất riêng cho mỗi chỉ số, không lấy tất cả chỉ số từ cùng một dòng gần nhất.
- Biểu đồ sắp xếp theo thời điểm đo, giữ các lần đo thực tế; ngày không có dữ liệu không được coi là giá trị 0.
- Không có dữ liệu thì hiển thị hướng dẫn thêm dữ liệu; chỉ có một điểm thì vẫn hiển thị giá trị đó.
- Lỗi lưu không làm mất nội dung form. Chặn nhấn lưu lặp trong khi đang ghi.

## 6. Quy trình 2: Quản lý và thực hiện lịch chăm sóc

### Luồng chính

1. Người dùng chọn tạo lịch uống thuốc hoặc tái khám.
2. Nhập tiêu đề, ghi chú, ngày giờ và quy tắc lặp.
3. Ứng dụng lưu lịch và các lần thực hiện cụ thể trong một giao dịch SQLite.
4. Ứng dụng xin quyền thông báo khi người dùng bật nhắc nhở, sau đó đăng ký các lần thông báo với hệ điều hành.
5. Đến hạn, người dùng nhận thông báo hoặc nhìn thấy lịch đến hạn trong ứng dụng.
6. Chạm thông báo mở đúng lịch. Trong ứng dụng, người dùng đánh dấu hoàn thành hoặc bỏ qua cho từng lần thực hiện.
7. Lịch sử giữ thời điểm dự kiến, trạng thái và thời điểm xác nhận.

### Phạm vi lịch và quy tắc

- Lịch tái khám là lịch một lần, có ngày giờ ở tương lai khi tạo mới.
- Lịch uống thuốc hỗ trợ một lần hoặc mỗi ngày, một giờ cố định cho mỗi lịch. Nếu cần nhiều giờ, tạo các lịch riêng.
- Khi tạo lịch uống thuốc một lần, thời điểm phải ở tương lai. Với lịch mỗi ngày, ngày bắt đầu không trước hôm nay theo giờ Việt Nam; nếu giờ hôm nay đã qua thì lần đầu là ngày tiếp theo còn trong khoảng hiệu lực. Không còn thời điểm tương lai nào thì từ chối lưu và yêu cầu đổi ngày/giờ.
- Khi sửa lịch lặp đang còn hiệu lực, có thể giữ ngày bắt đầu cũ ở quá khứ, nhưng chỉ sinh lại các mốc lớn hơn thời điểm hiện tại. Không bổ sung occurrence quá hạn cho những ngày không từng được tạo; các occurrence quá hạn đã có được giữ nguyên. Nếu lịch đã hết lần tương lai thì phải chọn ngày bắt đầu mới không trước hôm nay và khoảng lịch có ít nhất một mốc tương lai.
- Lịch lặp bắt buộc có ngày bắt đầu và kết thúc, tối đa 30 ngày liên tiếp. Toàn bộ lần nhắc được tạo trước, không hứa nhắc vô hạn khi không mở ứng dụng. Giao diện ghi rõ ngày kết thúc; muốn tiếp tục thì sửa hoặc tạo lịch mới.
- Tên thuốc, hướng dẫn dùng và địa điểm tái khám do người dùng ghi trong tiêu đề/ghi chú. Ứng dụng không tính hoặc khuyên liều dùng.
- Mỗi lần thực hiện có trạng thái `pending`, `completed`, `skipped` hoặc `cancelled`. Quá hạn được tính từ `pending` và thời điểm hiện tại, không tự coi là bỏ qua.
- Chỉ xác nhận hoàn thành/bỏ qua lần đến hạn hoặc đã quá hạn; không xác nhận các lần ở tương lai. Thao tác xác nhận lặp không tạo bản ghi trùng hoặc đổi thời điểm hoàn thành đã lưu.
- Sửa lịch chỉ thay thế các lần chưa đến hạn; các lần đã hoàn thành, đã bỏ qua và quá hạn được giữ nguyên. Nếu không còn lần tương lai thì phải chọn ngày bắt đầu mới.
- Tắt hoặc xóa lịch hủy tất cả lần chưa hoàn thành, kể cả quá hạn. Lịch được lưu trữ ẩn để giữ lịch sử; các lần hoàn thành/bỏ qua không bị xóa.
- Bật lại lịch chỉ tạo lại các lần tương lai nằm trong khoảng ngày còn hiệu lực, không phục hồi các lần quá hạn đã hủy. Khi lịch hết hiệu lực, yêu cầu sửa khoảng ngày trước khi bật lại.
- Thông báo là nhắc việc, không tự xác nhận người dùng đã uống thuốc hay đã đi khám.
- Khi quyền thông báo bị từ chối, lịch vẫn được lưu và hiển thị; ứng dụng ghi rõ chưa bật thông báo và cho phép thử lại sau.
- Lỗi đăng ký/hủy thông báo không được làm mất lịch. Lưu trạng thái cần đồng bộ với hệ điều hành; thử lại khi mở ứng dụng, khi người dùng yêu cầu hoặc sau khi quyền thay đổi.
- Sau khi mở lại ứng dụng, đối chiếu các lần tương lai với trạng thái thông báo, không phát hàng loạt thông báo cho lịch đã quá hạn.

### Ràng buộc theo nền tảng

Thông báo phải được kiểm thử khi ứng dụng đang mở và sau khi đóng trên từng nền tảng, dưới quyền và cấu hình hệ điều hành phù hợp. Không dùng riêng `Timer` của Dart để giả lập thông báo nền.

Đề xuất dùng `flutter_local_notifications`. Vì hỗ trợ thông báo lặp và quản lý thông báo trên Windows khác Android, nghiệp vụ tạo các lần nhắc một lần từ lịch hữu hạn. Bản Windows cần kiểm chứng đăng ký/hủy thông báo với danh tính ứng dụng và cách đóng gói phù hợp, dự kiến MSIX. Không dùng bản chạy debug để kết luận chức năng thông báo trên bản phát hành đã đạt.

Android cần khai báo thành phần lên lịch và xin các quyền cần thiết theo phiên bản plugin, Android SDK thực dùng. Nhắc theo thời điểm mong muốn có thể chịu giới hạn tiết kiệm pin, quyền thông báo và chế độ báo thức. Khi thiếu quyền, giao diện phải phản ánh đúng khả năng hiện có, không hứa thông báo chính xác tuyệt đối.

Nếu môi trường không cho kiểm chứng một hành vi thông báo, ghi rõ chưa kiểm chứng trong biên bản; không ghi là đạt hoặc âm thầm thay bằng chỉ nhắc khi ứng dụng đang mở.

## 7. Màn hình và trải nghiệm

Chưa chốt màu sắc, typography hoặc bản mẫu hình ảnh. Đây là các lựa chọn dành cho bước thiết kế giao diện sau khi phạm vi được duyệt.

| Màn hình | Nội dung và thao tác chính |
| --- | --- |
| Thiết lập hồ sơ lần đầu | Họ tên, chiều cao, ngày sinh và cân nặng mục tiêu tùy chọn |
| Tổng quan | Chỉ số mới nhất từng loại, lịch hôm nay, thao tác thêm nhanh |
| Chỉ số | Danh sách đo, lọc ngày, chọn chỉ số và khoảng thời gian biểu đồ |
| Form chỉ số | Ngày giờ, nhóm chỉ số, đơn vị và lỗi ngay tại trường |
| Lịch chăm sóc | Danh sách lịch, bộ lọc loại/trạng thái, bật/tắt, thêm/sửa/xóa |
| Chi tiết lịch | Thông tin lịch, các lần thực hiện và lịch sử xác nhận |
| Hồ sơ | Chỉnh sửa thông tin, hướng dẫn quyền thông báo và thông tin lưu cục bộ |

Điều hướng có bốn mục: Tổng quan, Chỉ số, Lịch chăm sóc, Hồ sơ. Màn hình hẹp dùng thanh điều hướng dưới; màn hình rộng dùng thanh bên. Bố cục dựa trên độ rộng cửa sổ, không chỉ dựa trên Android hay Windows.

Yêu cầu chung: trạng thái đang tải/rỗng/lỗi, nút thử lại, xác nhận xóa, ngày giờ tiếng Việt, cuộn được khi bàn phím xuất hiện, thao tác bằng chuột và bàn phím trên desktop, hỗ trợ cỡ chữ lớn và nhãn tiếp cận. Trạng thái không được chỉ phân biệt bằng màu. Form chưa lưu cần được bảo vệ khi chuyển màn hình.

## 8. Thiết kế dữ liệu SQLite

Một cơ sở dữ liệu, schema phiên bản 1. Bật khóa ngoại, dùng truy vấn có tham số và transaction khi ghi nhiều bảng. Không tạo nhiều lớp dữ liệu trùng nhau cho Android và Windows.

| Bảng | Trường chính | Quan hệ và ràng buộc |
| --- | --- | --- |
| `profiles` | `id`, `full_name`, `birth_date`, `height_cm`, `target_weight_kg`, `created_at_utc`, `updated_at_utc` | Một dòng, `id = 1` |
| `health_records` | `id`, `profile_id`, `measured_at_utc`, `weight_kg`, `height_cm_snapshot`, `systolic`, `diastolic`, `heart_rate`, `note`, `created_at_utc`, `updated_at_utc` | FK hồ sơ; ít nhất một nhóm chỉ số; chỉ mục thời điểm đo |
| `care_reminders` | `id`, `profile_id`, `type`, `title`, `note`, `repeat_rule`, `start_date`, `end_date`, `local_time`, `timezone_id`, `is_enabled`, `is_archived`, `created_at_utc`, `updated_at_utc` | FK hồ sơ; loại `medication`/`appointment`; lặp `none`/`daily` |
| `reminder_occurrences` | `id`, `reminder_id`, `scheduled_at_utc`, `status`, `resolved_at_utc`, `notification_state`, `notification_error`, `created_at_utc` | FK lịch; chỉ mục ngày giờ/trạng thái; `id` dùng làm mã thông báo |

- Thời điểm tuyệt đối lưu dưới dạng số nguyên epoch milliseconds UTC. Ngày sinh, ngày bắt đầu/kết thúc lưu `YYYY-MM-DD`; giờ lịch lưu `HH:mm` và `timezone_id = Asia/Ho_Chi_Minh`.
- `height_cm_snapshot` bắt buộc nếu có cân nặng, trống nếu không có cân nặng. Khi sửa giá trị cân nặng của bản ghi cũ vẫn giữ snapshot cũ; chỉ bản ghi mới dùng chiều cao hồ sơ hiện tại.
- `notification_state` tối thiểu có `pending_schedule`, `scheduled`, `pending_cancel`, `cancelled`, `failed`. Khi cần hủy, giữ dòng cũ cho đến khi xử lý xong yêu cầu hủy; không tái sử dụng mã thông báo cho dòng mới.
- Chỉ một occurrence chưa hủy được phép tồn tại cho cùng lịch và cùng thời điểm dự kiến. Dùng partial unique index cho `(reminder_id, scheduled_at_utc)` với `status != cancelled` để có thể bật lại lịch mà vẫn giữ các dòng đã hủy.
- Mã thông báo dùng ID nguyên ổn định trong giới hạn kiểu số được plugin hỗ trợ; không dùng `hashCode` của đối tượng Dart.
- `notification_error` chỉ chứa thông tin lỗi cần hiển thị/chẩn đoán, không chứa nội dung thuốc hoặc dữ liệu chỉ số.
- Không xóa hoặc tạo lại database khi gặp lỗi mở file hay migration. Trình bày lỗi có thể thử lại, giữ file dữ liệu cũ.
- Đối chiếu thông báo theo thứ tự hủy mã cũ rồi mới đăng ký mã mới. Nếu không hủy được mã cũ, giữ yêu cầu hủy và hoãn đăng ký mã thay thế của cùng lần lịch để tránh hai thông báo; hiển thị lỗi và cho thử lại. Đánh dấu hoàn thành/bỏ qua cũng yêu cầu hủy thông báo còn lại của occurrence đó.
- Dữ liệu mẫu chỉ được thêm bằng thao tác demo rõ ràng, không tự trộn vào hồ sơ thật. Không dùng dữ liệu sức khỏe thật trong ảnh báo cáo.

## 9. Cấu trúc cài đặt đề xuất

Ứng dụng Flutter duy nhất. Tách vừa đủ: model, truy cập SQLite, xử lý chỉ số/lịch, dịch vụ thông báo và màn hình. Sử dụng `ChangeNotifier`/`ValueNotifier` có sẵn nếu đáp ứng; không mặc định thêm framework quản lý trạng thái, code generation hoặc máy chủ.

Đề xuất thư viện cần thiết, chốt phiên bản theo SDK thực dùng trong bước lập kế hoạch/cài đặt:

- SQLite: `sqflite` trên Android và `sqflite_common_ffi` trên Windows, chung API truy vấn; `path_provider` và `path` để xác định đường dẫn.
- Thông báo: `flutter_local_notifications`; `timezone` để chuyển lịch giờ Việt Nam thành thời điểm thực.
- Định dạng tiếng Việt dùng công cụ địa phương hóa Flutter/Dart phù hợp. Biểu đồ chọn giải pháp nhỏ đáp ứng tương tác và khả năng tiếp cận; không tự thêm nhiều thư viện UI.
- Khóa dependency sau khi giải quyết tương thích. Nếu cách tích hợp thông báo hoặc SQLite đòi đổi toolchain, báo rõ tác động trước khi thay đổi môi trường hệ thống.

Nguồn SQLite là nguồn dữ liệu chính. UI không tự giữ bản lịch sử khác với database. Ghi database và thao tác hệ điều hành là hai bước riêng: lưu thành công nhưng thông báo thất bại phải được thể hiện đúng, có cơ chế thử lại.

## 10. Kiểm thử và tiêu chí nghiệm thu

| Nhóm | Bằng chứng cần có |
| --- | --- |
| Chất lượng mã | `flutter analyze` và các kiểm thử tự động phù hợp chạy thành công |
| Quy trình 1 | Tạo/sửa/xóa, lỗi dữ liệu, dấu phẩy thập phân, nhóm huyết áp thiếu, sắp xếp/lọc; tổng quan lấy chỉ số gần nhất riêng từng loại |
| Quy trình 2 | Tạo lịch một lần/lặp hữu hạn; không trùng lần nhắc; hoàn thành/bỏ qua chỉ tác động một occurrence; sửa/tắt/bật/xóa giữ đúng lịch sử |
| Lỗi dịch vụ | Từ chối quyền, đăng ký/hủy thông báo lỗi, lưu lịch không mất, thử lại không tạo thông báo trùng |
| Lưu trữ | Đóng/mở lại ứng dụng vẫn giữ hồ sơ, chỉ số, lịch và kết quả thực hiện; lỗi migration không xóa dữ liệu |
| Hiển thị | Kiểm tra ít nhất 360, 768, 1280 logical pixels; cửa sổ resize, bàn phím mobile và cỡ chữ lớn không tràn |
| Android | Build APK; chạy trên thiết bị/emulator; xác minh thông báo và chạm mở lịch; kiểm tra lịch sau khi đóng ứng dụng |
| Windows | Build release; chạy trên Windows; kiểm chứng SQLite và thông báo trên bản đóng gói có danh tính phù hợp; ghi cách cài và điều kiện hệ điều hành |
| Tài liệu | Sơ đồ, ảnh chụp, hướng dẫn và kết quả kiểm thử khớp đúng phiên bản thực tế |

Unit test tập trung quy tắc chỉ số, tạo occurrence, chuyển trạng thái và đối chiếu thông báo. Test database thực hoặc database tạm cho transaction/ràng buộc. Widget test tập trung hai luồng chính và thay đổi bố cục. Kiểm thử thông báo hệ điều hành là kiểm thử tích hợp/thủ công, không được thay thế bằng mock.

Mỗi phép kiểm chứng ghi rõ đã đạt, không đạt hoặc chưa kiểm chứng, kèm nền tảng và điều kiện. Không suy ra Android đạt chỉ vì Windows đạt hoặc ngược lại.

## 11. Hồ sơ đồ án và nội dung trình bày

Đầu ra đề xuất:

1. Mã nguồn Flutter có hướng dẫn chạy Android/Windows, dependency và cách tạo dữ liệu demo.
2. Bản chạy Android APK, bản Windows release và hướng dẫn/cấu hình đóng gói phục vụ thông báo; chỉ đính kèm bản đã build thực tế.
3. Báo cáo DOCX tiếng Việt: đặt vấn đề; khảo sát và phân tích nghiệp vụ; yêu cầu; tác nhân và đặc tả Use Case; sơ đồ Use Case, Activity, Sequence cho hai quy trình; ERD và thiết kế bảng; thiết kế giao diện/xử lý; cài đặt; kiểm thử; kết quả, hạn chế, hướng phát triển; tài liệu tham khảo.
4. Slide PPTX khoảng 10–12 slide: vấn đề, mục tiêu, hai quy trình, kiến trúc, database, giao diện hai nền tảng, demo, kiểm thử và kết luận.
5. Kịch bản demo ngắn đi trọn cả hai quy trình, có mẫu lỗi dữ liệu và thao tác mở lại ứng dụng chứng minh lưu trữ.

Thông tin trường, lớp, giảng viên và hạn nộp chưa được cung cấp: để chỗ điền trong bản thảo, không tự bịa. Ảnh và kết quả chạy chỉ bổ sung sau khi có bản cài đặt thực tế; không ghi kết quả kiểm thử dự kiến thành đã đạt.

## 12. Trình tự và các giới hạn cần biết

Thứ tự đề xuất: duyệt thiết kế; lập kế hoạch; chốt mẫu giao diện; cài dữ liệu và hai quy trình; tích hợp/kiểm chứng từng nền tảng; hoàn thiện báo cáo và slide bằng bằng chứng thực tế.

- Chưa có hạn nộp nên không tự gán ngày hoàn thành.
- Không có đồng bộ hoặc sao lưu/khôi phục trong phạm vi bản đầu. Gỡ ứng dụng, xóa dữ liệu ứng dụng hoặc mất thiết bị có thể làm mất dữ liệu cục bộ.
- Chưa có mã PIN, mã hóa database riêng hoặc chia sẻ hồ sơ; bản đầu dựa trên bảo vệ tài khoản/thiết bị và vùng dữ liệu ứng dụng. Không đưa dữ liệu sức khỏe vào log.
- Giới hạn 30 ngày của lịch uống thuốc phải được thể hiện trong UI, hướng dẫn và báo cáo.
- Android/Windows là lựa chọn kỹ thuật đề xuất, không phải cam kết đã chạy thành công; kết quả build/demo phải được kiểm chứng sau cài đặt.

Các lựa chọn nhỏ còn giao người triển khai: tên hiển thị ứng dụng, tên package, màu/font sau khi xem mẫu, cấu trúc thư mục chi tiết, phiên bản dependency tương thích, công cụ vẽ biểu đồ và cơ chế thông báo cụ thể đáp ứng những tiêu chí trên. Không được tự thay đổi hai quy trình hoặc giảm yêu cầu chạy trên hai nền tảng.

## 13. Nguồn kỹ thuật đã đối chiếu ngày 31/10/2026

Rà soát thiết kế: một tác nhân độc lập đã đọc tài liệu. Điểm cần làm rõ về ngày bắt đầu quá khứ đã được người thiết kế xử lý bằng quy tắc chỉ sinh lần tương lai tại mục 6. Lựa chọn này là đề xuất kỹ thuật, không phải yêu cầu mới từ người dùng. Tài liệu vẫn đang chờ người dùng duyệt.

- Flutter, General approach to adaptive apps: https://docs.flutter.dev/ui/adaptive-responsive/general — chọn bố cục theo kích thước cửa sổ, dùng chung nội dung điều hướng.
- Flutter, Persist data with SQLite: https://docs.flutter.dev/cookbook/persistence/sqlite — lưu trữ SQLite trong Flutter, phạm vi nền tảng của sqflite.
- Tekartik, sqflite: https://pub.dev/packages/sqflite — SQLite trên Android và các nền tảng plugin hỗ trợ.
- Tekartik, sqflite_common_ffi: https://pub.dev/packages/sqflite_common_ffi — API SQLite dùng trên Windows và kiểm thử Dart.
- Tác giả flutter_local_notifications: https://pub.dev/packages/flutter_local_notifications — cấu hình, quyền và hành vi thông báo theo nền tảng.
- Tác giả Windows implementation: https://pub.dev/packages/flutter_local_notifications_windows — giới hạn thông báo lặp và quản lý thông báo trên Windows. Phiên bản cụ thể cần đối chiếu lại khi khóa dependency.
