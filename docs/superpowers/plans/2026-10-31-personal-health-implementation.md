# Personal Health Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cài đặt ứng dụng quản lý sức khỏe cá nhân trên Android/Windows, hoàn thiện hai quy trình thực tế, báo cáo DOCX và slide PPTX.

**Architecture:** Một ứng dụng Flutter, giao diện thích ứng và SQLite cục bộ làm nguồn dữ liệu chính. Tách theo nghiệp vụ hồ sơ, chỉ số, lịch chăm sóc; dịch vụ thông báo xử lý khác biệt hệ điều hành. Không thêm máy chủ, tài khoản hoặc framework quản lý trạng thái nếu `ChangeNotifier` đã đáp ứng.

**Tech Stack:** Flutter/Dart; Material 3; `flutter_localizations`; SQLite qua `sqflite`/`sqflite_common_ffi`; `path_provider`; `path`; `flutter_local_notifications`; `timezone`. Chốt dependency bằng bộ giải phiên bản và giữ `pubspec.lock`; thư viện biểu đồ chỉ thêm khi cần ở task 5.

**Spec:** `docs/superpowers/specs/2026-10-31-personal-health-design.md` — người dùng đã duyệt trong cuộc trò chuyện ngày 31/10/2026. Dòng chờ duyệt trong bản thiết kế gốc được giữ như trạng thái tại thời điểm phát hành; quyết định duyệt được ghi nhận tại đây.

## Global Constraints

- Nền tảng nghiệm thu: Android và Windows; không suy kết quả của nền tảng này sang nền tảng kia.
- Một hồ sơ cá nhân, `id = 1`; không đăng nhập; không đồng bộ hoặc sao lưu/khôi phục trong bản đầu.
- Hai quy trình: theo dõi chỉ số sức khỏe; quản lý và thực hiện lịch uống thuốc/tái khám.
- Ngôn ngữ giao diện: tiếng Việt. Đơn vị: cm, kg, mmHg và nhịp/phút.
- `timezone_id = Asia/Ho_Chi_Minh`; lịch hiển thị UTC+7; thời điểm tuyệt đối lưu epoch milliseconds UTC.
- Biểu đồ hỗ trợ 7, 30 hoặc 90 ngày; không tạo điểm 0 cho ngày thiếu dữ liệu.
- Lịch uống thuốc một lần hoặc mỗi ngày, một giờ/lịch, tối đa 30 ngày liên tiếp; tái khám chỉ một lần.
- Trạng thái occurrence: `pending`, `completed`, `skipped`, `cancelled`; quá hạn được suy ra, không tự đổi thành bỏ qua.
- SQLite schema phiên bản 1, bật foreign keys, truy vấn có tham số, transaction; không reset database khi lỗi mở/migration.
- Chỉ sinh occurrence tương lai; sửa lịch giữ những lần quá hạn/đã xác nhận; tắt/xóa hủy lần chưa xác nhận.
- Thông báo dùng ID nguyên ổn định; hủy trước khi đăng ký mã thay thế; không dùng riêng Dart Timer cho thông báo nền.
- Không chẩn đoán, phân loại bệnh, phân loại BMI hoặc đề xuất thuốc/liều dùng; không đưa dữ liệu sức khỏe vào log.
- Kiểm tra ít nhất 360, 768, 1280 logical pixels; chuột, bàn phím, bàn phím ảo và cỡ chữ lớn.
- Báo cáo phải phân biệt Đạt/Không đạt/Chưa kiểm chứng; không dùng ảnh giả hoặc kết quả kiểm thử dự kiến như kết quả thật.
- Thông tin trường/lớp/giảng viên/hạn nộp còn thiếu để chỗ điền; không tự gán hạn hoàn thành.

## Review Focus

1. Người dùng nhập `65,5`, `NaN`, số âm, hoặc hai dấu phân cách: chỉ chấp nhận một giá trị hữu hạn dương, lỗi nằm đúng trường. Task 2 kiểm thử.
2. Lần đo mới nhất chỉ có huyết áp: tổng quan vẫn giữ cân nặng mới nhất từ bản ghi trước. Task 2 kiểm thử.
3. Tạo lịch hôm nay khi giờ nhắc đã qua, hoặc sửa lịch có ngày bắt đầu cũ: chỉ sinh mốc tương lai và giữ lịch sử quá hạn. Task 3 kiểm thử.
4. Hủy thông báo thất bại rồi bật lại lịch: không tái sử dụng ID, không đăng ký mã thay thế trước khi hủy xong mã cũ. Task 4 kiểm thử.
5. Lưu form lỗi, nhấn lưu hai lần, đổi tab hoặc thu nhỏ cửa sổ khi form còn dữ liệu: không mất nội dung, không ghi trùng, không tràn bố cục. Task 5–6 kiểm thử.

---

## Hiện trạng và điều kiện bắt đầu

- Workspace: `D:\Study\LapTrinhDaNenTang\doan`. Chưa có ứng dụng hoặc Git repository, chỉ có tài liệu thiết kế/kế hoạch.
- Metadata SDK hiện có ghi Flutter 3.47.6; chạy trực tiếp Dart xác nhận Dart 3.13.5.
- Có Android SDK và Visual Studio 2022 Community với C++ tools theo kiểm tra đường dẫn/tool cài đặt; chưa khẳng định toolchain build thành công.
- Chạy Flutter doctor thất bại tại `C:\Tools\flutter\bin\cache\lockfile`: Flutter không ghi được file khóa. Đây là lỗi quyền/vị trí SDK, không phải lỗi mã nguồn ứng dụng.
- Task 1 kiểm chứng môi trường trước. Nếu SDK cần quyền ghi ngoài vùng cho phép, dùng bản SDK/cache riêng trong vùng ghi được nếu khả thi, giữ nguyên SDK gốc; không đổi ACL hay yêu cầu chạy Administrator theo phỏng đoán. Nếu vẫn bị hạn chế, báo đúng thao tác bị chặn và tiếp tục các công việc không phụ thuộc.
- Do chưa có Git repository, kế hoạch không tự khởi tạo repo hoặc hứa có commit. Nếu người dùng cung cấp repo, ghi từng task đã kiểm chứng thành commit riêng, giữ nguyên thay đổi của người dùng.
- Các lệnh bên dưới chạy trong workspace với Flutter SDK đã hoạt động. Thay đường dẫn lệnh theo môi trường thực tế, không sửa mục tiêu kiểm chứng.

## Bản đồ file

| Phạm vi | File | Trách nhiệm |
| --- | --- | --- |
| Khởi động | `pubspec.yaml`, `lib/main.dart`, `lib/app.dart`, `lib/ui/app_shell.dart` | Dependency, khởi động, nội địa hóa, điều hướng thích ứng |
| Thiết kế | `DESIGN.md`, `lib/ui/app_theme.dart` | Ngữ cảnh thẩm mỹ, màu/font, trạng thái và thành phần dùng chung |
| SQLite | `lib/data/app_database.dart`, `lib/data/schema.dart` | Chọn backend theo nền tảng, mở file riêng, schema, migration |
| Hồ sơ | `lib/features/profile/profile.dart`, `profile_repository.dart`, `profile_screen.dart` | Model, lưu hồ sơ, thiết lập và sửa hồ sơ |
| Chỉ số | `lib/features/health/health_record.dart`, `health_rules.dart`, `health_repository.dart` | Model, kiểm tra số/nhóm chỉ số, CRUD và truy vấn |
| UI chỉ số | `lib/features/health/health_screen.dart`, `health_form.dart`, `health_chart.dart` | Lịch sử, bộ lọc, form và biểu đồ |
| Lịch | `lib/features/care/care_reminder.dart`, `reminder_occurrence.dart`, `care_rules.dart`, `care_repository.dart` | Lịch, các lần thực hiện, sinh thời điểm và transaction |
| UI lịch | `lib/features/care/care_screen.dart`, `care_form.dart`, `care_detail_screen.dart` | Danh sách, form, xác nhận từng lần và lịch sử |
| Thông báo | `lib/notifications/notification_port.dart`, `local_notification_service.dart`, `notification_sync.dart` | Ranh giới hệ điều hành, quyền, lập/hủy lịch, đối chiếu trạng thái |
| Tổng quan | `lib/features/overview/overview_screen.dart` | Giá trị gần nhất từng loại và các lịch hôm nay |
| Kiểm chứng | `test/data/`, `test/health/`, `test/care/`, `test/notifications/`, `test/ui/`, `integration_test/` | Unit, SQLite tạm, widget, tích hợp |
| Phát hành | `README.md`, `docs/testing.md`, `docs/demo-script.md`, `android/`, `windows/` | Hướng dẫn, bằng chứng, cấu hình build và thông báo |
| Đồ án | `deliverables/bao_cao_quan_ly_suc_khoe.docx`, `deliverables/thuyet_trinh_quan_ly_suc_khoe.pptx`, `docs/diagrams/`, `docs/evidence/` | Báo cáo, slide, sơ đồ và ảnh chạy thật |

Không tạo abstraction hoặc controller chung để dự phòng. Chỉ tách thêm file nếu trách nhiệm thực tế đã rõ.

### Task 1: Nền tảng chạy được, SQLite và hồ sơ cá nhân

**Files:** Create platform scaffold Android/Windows, `pubspec.yaml`, `lib/main.dart`, `lib/app.dart`, `lib/ui/app_shell.dart`, `DESIGN.md`, `lib/data/app_database.dart`, `lib/data/schema.dart`, `lib/features/profile/profile.dart`, `profile_repository.dart`; tests `test/data/app_database_test.dart`, `test/data/profile_repository_test.dart`.

**Interfaces:**
- Produces `Future<Database> openAppDatabase({DatabaseFactory? factory, String? path})`; tham số tùy chọn cho database tạm khi test, mặc định chọn Android/Windows và thư mục dữ liệu ứng dụng.
- Produces `Profile` với các trường `profiles` trong spec; `ProfileRepository(Database db).load(): Future<Profile?>` và `.save(Profile profile): Future<void>`.
- Các model giữ DateTime UTC tại ranh giới Dart; `toMap`/`fromMap` chuyển timestamp và enum sang định dạng SQLite trong spec. Mỗi model sở hữu cách chuyển của mình.

- [ ] **1.1** Kiểm chứng/khắc phục quyền SDK bằng chẩn đoán có bằng chứng; chạy `flutter doctor -v`, ghi Android SDK/JDK/C++ tools còn thiếu. Không cài/chỉnh hệ thống âm thầm.
- [ ] **1.2** Khởi tạo tại workspace bằng `flutter create --project-name suc_khoe_ca_nhan --platforms android,windows .`; giữ nguyên `docs/`. Đặt tên hiển thị “Sức Khỏe Cá Nhân”. Trước khi viết UI tùy chỉnh, áp dụng frontend-design và frontend-design-premium, khởi tạo DESIGN.md; task 5 hoàn thiện giao diện từ ngữ cảnh này. Thêm dependency cần cho task này và khóa phiên bản thực tế; dependency thông báo thêm ở task 4.
- [ ] **1.3** Viết test trước: mở database tạm; `expect(await db.getVersion(), 1)`; `expect((await db.rawQuery('PRAGMA foreign_keys')).single.values.single, 1)`; insert FK không tồn tại phải lỗi. Lưu hồ sơ hai lần vẫn chỉ có một dòng ID 1; mở lại file tạm vẫn còn dữ liệu.
- [ ] **1.4** Chạy `flutter test test/data/` và xác nhận FAIL do phần cài đặt chưa có, không phải vì test bị lỗi cú pháp.
- [ ] **1.5** Cài schema đủ bốn bảng, FK, CHECK và chỉ mục trong spec; mở database không xóa dữ liệu cũ khi lỗi. Cài đọc/lưu hồ sơ và khởi động có màn hình lỗi/thử lại; shell điều hướng dùng chung, chưa trang trí chi tiết.
- [ ] **1.6** Chạy lại `flutter test test/data/`; PASS. Chạy `flutter analyze`; không có lỗi. Ghi dependency/toolchain thực tế trong README.

### Task 2: Xử lý và lưu chỉ số sức khỏe

**Files:** Create `lib/features/health/health_record.dart`, `health_rules.dart`, `health_repository.dart`; tests `test/health/health_rules_test.dart`, `health_repository_test.dart`.

**Interfaces:**
- Consumes `Database` từ task 1 và `Profile.heightCm`.
- Produces `HealthRecord` theo bảng `health_records`, `enum HealthMetric { weight, bloodPressure, heartRate }`.
- Produces `double parsePositiveDecimal(String text)` ném `FormatException` khi không hợp lệ; `Map<String, String> validateHealthRecord(HealthRecord record, {required DateTime nowUtc})` trả lỗi theo tên trường.
- Produces `HealthRepository(Database db, {DateTime Function()? utcNow}).save(HealthRecord record): Future<int>`, `.delete(int id): Future<void>`, `.list({required DateTime fromUtc, required DateTime toUtc}): Future<List<HealthRecord>>`, `.latestByMetric(): Future<Map<HealthMetric, HealthRecord>>`. Clock mặc định là thời gian thực UTC, test có thể truyền clock cố định.
- `id` null là thêm mới. `save` lấy snapshot chiều cao từ hồ sơ khi thêm cân nặng, giữ snapshot cũ khi sửa. Bản ghi trước đó không có cân nặng nhưng nay bổ sung thì lấy chiều cao hồ sơ hiện tại; bỏ cân nặng thì xóa snapshot.

- [ ] **2.1** Viết test: `expect(parsePositiveDecimal('65,5'), 65.5)`; `expect(() => parsePositiveDecimal('1,2.3'), throwsFormatException)`; từ chối `NaN`, vô hạn, rỗng và số không dương. Các trường huyết áp/nhịp tim dùng số nguyên dương; không ép cắt phần lẻ.
- [ ] **2.2** Viết test repository: bản ghi thiếu một vế huyết áp bị từ chối; thời điểm tương lai bị lỗi; lưu chỉ huyết áp sau bản ghi cân nặng vẫn trả đủ hai giá trị mới nhất riêng biệt. Thử sửa chiều cao hồ sơ không đổi snapshot bản ghi cũ; kiểm tra thêm/bỏ cân nặng theo quy tắc trên.
- [ ] **2.3** Chạy `flutter test test/health/`; xác nhận FAIL trước cài đặt.
- [ ] **2.4** Cài model, quy tắc và CRUD có tham số; lọc ngày dùng khoảng nửa mở `[fromUtc, toUtc)`; sắp xếp ổn định theo thời điểm đo rồi ID. Từ chối thao tác sửa/xóa ID không tồn tại bằng lỗi có thể hiển thị.
- [ ] **2.5** Chạy `flutter test test/data/ test/health/`; PASS, bao gồm đóng/mở lại database tạm.

### Task 3: Lịch chăm sóc và lịch sử thực hiện

**Files:** Create `lib/features/care/care_reminder.dart`, `reminder_occurrence.dart`, `care_rules.dart`, `care_repository.dart`; tests `test/care/care_rules_test.dart`, `care_repository_test.dart`.

**Interfaces:**
- Produces model `CareReminder`, `ReminderOccurrence` theo spec; enum `ReminderType { medication, appointment }`, `RepeatRule { none, daily }`, `OccurrenceStatus { pending, completed, skipped, cancelled }`.
- Produces `List<DateTime> generateOccurrenceTimes(CareReminder reminder, {required DateTime nowUtc, required bool creating})`; kết quả UTC tăng dần, chỉ tương lai; đầu vào vi phạm quy tắc ném lỗi kiểm tra dữ liệu có trường tương ứng.
- Produces `CareRepository(Database db).save(CareReminder reminder, {required DateTime nowUtc}): Future<int>`, `.setEnabled(int id, bool enabled, {required DateTime nowUtc}): Future<void>`, `.archive(int id, {required DateTime nowUtc}): Future<void>`, `.resolve(int occurrenceId, OccurrenceStatus result, {required DateTime nowUtc}): Future<void>`.
- Produces `.list({ReminderType? type, bool? enabled}): Future<List<CareReminder>>`, `.occurrencesFor(int reminderId): Future<List<ReminderOccurrence>>`, `.occurrencesBetween({required DateTime fromUtc, required DateTime toUtc}): Future<List<ReminderOccurrence>>`.

- [ ] **3.1** Viết test mốc giờ: “hôm nay 08:00, hiện tại 09:00, kết thúc ngày mai” sinh đúng lần ngày mai; ngày cuối tính bao gồm; 30 ngày hợp lệ, 31 ngày bị từ chối; một lần bằng/nhỏ hơn hiện tại bị từ chối. Dùng clock cố định và múi giờ Việt Nam, không phụ thuộc máy chạy test.
- [ ] **3.2** Viết test transaction: sửa chỉ thay pending tương lai; giữ quá hạn và đã hoàn thành; tắt hủy pending; bật lại tạo ID mới không trùng unique index; archived không hiện danh sách chính. Xác nhận tương lai bị từ chối; xác nhận lần thứ hai cùng kết quả không đổi `resolved_at_utc`; yêu cầu đổi kết quả đã xác nhận bị từ chối.
- [ ] **3.3** Chạy `flutter test test/care/`; xác nhận FAIL trước cài đặt.
- [ ] **3.4** Cài quy tắc task 3 và toàn bộ transaction. Chỉ mục unique một phần chỉ áp dụng occurrence chưa cancelled. Dòng bị hủy có `pending_cancel`; dòng mới có `pending_schedule`. `resolve` lưu kết quả và yêu cầu hủy thông báo còn lại trong cùng transaction. Giới hạn ID thông báo 1..2147483647; vượt giới hạn báo lỗi và rollback.
- [ ] **3.5** Chạy `flutter test test/care/ test/data/`; PASS. Kiểm tra transaction rollback khi một thao tác con thất bại, không để lịch lưu nửa chừng.

### Task 4: Thông báo Android/Windows và đối chiếu với SQLite

**Files:** Create `lib/notifications/notification_port.dart`, `local_notification_service.dart`, `notification_sync.dart`, `test/notifications/fake_notification_port.dart`, `notification_sync_test.dart`; Modify `lib/app.dart`, `pubspec.yaml`, Android manifest/Gradle và cấu hình Windows/MSIX phù hợp.

**Interfaces:**
- Consumes model và Database từ task 1–3; DB là trạng thái mong muốn.
- Produces `enum NotificationPermission { granted, denied, unavailable }` và `abstract class NotificationPort`: `requestPermission(): Future<NotificationPermission>`, `schedule(ReminderOccurrence occurrence, {required String title}): Future<void>`, `cancel(int id): Future<void>`, `pendingIds(): Future<Set<int>>`, `getLaunchOccurrenceId(): Future<int?>`, `selections: Stream<int>`.
- Produces `NotificationSync(Database db, NotificationPort port, {DateTime Function()? utcNow}).reconcile(): Future<void>`. Clock mặc định là thời gian thực UTC, test có thể truyền clock cố định. Các lần gọi đồng thời được gộp/tuần tự; lỗi từng thông báo được lưu trong DB, không mất lịch hoặc dừng mọi mục còn lại.
- Fake cho test ghi `events: List<String>`, hỗ trợ ném lỗi có chủ đích khi cancel/schedule, không phụ thuộc hệ điều hành.

- [ ] **4.1** Đối chiếu tài liệu chính chủ đúng phiên bản plugin; thêm dependency tương thích, receiver/permission Android, timezone và nhận diện ứng dụng Windows. Giữ `pubspec.lock`.
- [ ] **4.2** Viết test: fake từ chối quyền vẫn còn lịch trong DB; gọi reconcile hai lần không tạo trùng; khởi động lại chỉ đăng ký mốc tương lai còn pending, không phát bù hàng loạt quá hạn.
- [ ] **4.3** Viết test hủy-thay thế: `expect(fake.events, ['cancel:12'])` khi hủy ID 12 thất bại; không có `schedule:13` cho mã thay thế cùng lịch/thời điểm. Sau retry hủy thành công, thứ tự là cancel cũ rồi schedule mới. Hoàn thành occurrence phải hủy mã tương ứng; lỗi giữ `pending_cancel`.
- [ ] **4.4** Chạy `flutter test test/notifications/`; xác nhận FAIL trước cài đặt.
- [ ] **4.5** Cài adapter và sync: xử lý hủy trước; hoãn đăng ký mã thay thế của cùng lịch/thời điểm còn `pending_cancel`; kiểm tra `pendingIds` trước khi đăng ký lại. `failed` cho lần đăng ký lỗi vẫn được retry nếu còn tương lai và pending. Chỉ ghi mã lỗi kỹ thuật, không ghi nội dung sức khỏe. Đồng bộ khi khởi động/resume và sau sửa lịch/quyền; không hỏi quyền liên tục nếu đã từ chối.
- [ ] **4.6** Chạy `flutter test test/notifications/ test/care/`; PASS. Test native phải nằm task 7; mock PASS chưa chứng minh thông báo OS hoạt động.

### Task 5: Giao diện hồ sơ, chỉ số và biểu đồ thích ứng

**Files:** Create `lib/ui/app_theme.dart`, `lib/features/profile/profile_screen.dart`, `lib/features/health/health_screen.dart`, `health_form.dart`, `health_chart.dart`; Modify `DESIGN.md`, app/shell; tests `test/ui/profile_flow_test.dart`, `health_flow_test.dart`, `adaptive_layout_test.dart`.

**Interfaces:**
- Consumes repository task 1–2; widget `ProfileScreen` hỗ trợ chế độ thiết lập lần đầu và chỉnh sửa; `HealthScreen` mở `HealthForm` để thêm/sửa.
- Produces `HealthChart({required List<HealthRecord> records, required HealthMetric metric})`; biểu đồ chỉ dùng dữ liệu đã lưu, có nhãn đơn vị và phần tóm tắt số liệu đọc được bằng screen reader.
- Shell giữ tab hiện tại và form chưa lưu khi thay đổi độ rộng. Dưới 600 logical pixels dùng thanh điều hướng dưới; từ 600 dùng thanh bên; form dài cuộn và giữ nội dung khi bàn phím hiện.

- [ ] **5.1** Áp dụng hai skill frontend-design và frontend-design-premium trước khi viết UI; ghi các lựa chọn màu/font/spacing, trạng thái, điều hướng và hành vi form vào `DESIGN.md`. Chọn phong cách sáng, rõ, bình tĩnh, dùng font có dấu tiếng Việt; không thêm tài nguyên mạng bắt buộc cho app ngoại tuyến.
- [ ] **5.2** Viết widget test: thiết lập hồ sơ hợp lệ mở tổng quan; số không hợp lệ hiển thị lỗi tại trường; repository lỗi vẫn giữ form; double tap lưu chỉ gọi save một lần; rời form dirty có xác nhận.
- [ ] **5.3** Viết widget test ở 360/768/1280, text scale 2, bàn phím ảo và resize khi form dirty: `expect(tester.takeException(), isNull)`; giá trị nhập và tab đang chọn không mất.
- [ ] **5.4** Chạy `flutter test test/ui/`; xác nhận FAIL trước cài đặt.
- [ ] **5.5** Cài màn hình, trạng thái tải/rỗng/lỗi/thử lại và bộ lọc 7/30/90 ngày. Biểu đồ không nối dữ liệu thành chuỗi số 0 khi thiếu ngày; một điểm vẫn nhìn/đọc được. Dùng widget/khả năng sẵn có trước; nếu thư viện biểu đồ tiết kiệm đáng kể mã và hỗ trợ Dart hiện tại thì chọn đúng một thư viện, ghi lý do trong DESIGN.
- [ ] **5.6** Chạy `flutter test test/ui/ test/health/`; PASS. Chụp/kiểm tra giao diện thật sau khi app có thể chạy; không dùng test bố cục thay cho quan sát UI.

### Task 6: Giao diện lịch chăm sóc và trang tổng quan

**Files:** Create `lib/features/care/care_screen.dart`, `care_form.dart`, `care_detail_screen.dart`, `lib/features/overview/overview_screen.dart`; Modify `lib/app.dart`, `lib/ui/app_shell.dart`; tests `test/ui/care_flow_test.dart`, `overview_test.dart`.

**Interfaces:**
- Consumes CareRepository, HealthRepository, ProfileRepository, NotificationPort và NotificationSync.
- Produces màn hình bốn tab hoàn chỉnh, form chung thêm/sửa lịch, và mở chi tiết từ ID occurrence. Nếu notification trỏ ID không còn hiệu lực, mở danh sách lịch kèm thông báo giải thích, không crash.
- Save SQLite thành công rồi mới sync OS; lỗi OS hiển thị “Đã lưu lịch, chưa bật được thông báo” kèm thử lại, không coi là lưu thất bại.

- [ ] **6.1** Viết widget test tạo lịch uống thuốc/tái khám, giới hạn 30 ngày, cảnh báo UTC+7 và ngày kết thúc. Thử hoàn thành một lần không tác động lần khác; nút hoàn thành tương lai bị khóa.
- [ ] **6.2** Viết widget test quyền từ chối/lỗi hủy vẫn giữ lịch, retry và bật/tắt giữ lịch sử. Tổng quan hiển thị chỉ số gần nhất riêng từng loại và lịch hôm nay. Chạm thông báo mở đúng lịch kể cả sau cold start; ID không tồn tại được xử lý.
- [ ] **6.3** Chạy `flutter test test/ui/care_flow_test.dart test/ui/overview_test.dart`; xác nhận FAIL trước cài đặt.
- [ ] **6.4** Cài giao diện và nối các dịch vụ; cập nhật nội dung sau save/resolve từ SQLite. Tái sử dụng quy tắc và thành phần task trước; không đặt lại quy tắc lặp trong widget. Thêm phần giải thích lưu cục bộ trong hồ sơ, không tạo nút sao lưu giả.
- [ ] **6.5** Chạy toàn bộ `flutter test` và `flutter analyze`; PASS. Hoàn thành kiểm tra thao tác bằng bàn phím, nhãn trạng thái và form dirty trên cả hai luồng.

### Task 7: Kiểm thử tích hợp, build và bằng chứng thực tế

**Files:** Create `integration_test/personal_health_flow_test.dart`, `docs/testing.md`, `docs/demo-script.md`, `docs/evidence/`; Modify README, platform packaging configuration, `pubspec.yaml` nếu cần MSIX.

**Interfaces:** Consumes ứng dụng task 1–6; produces biên bản với môi trường/lệnh/kết quả/ảnh, đường dẫn artifact thực tế và hướng dẫn cài/chạy. Chỉ dùng dữ liệu giả có nhãn demo.

- [ ] **7.1** Viết/chạy integration test: tạo hồ sơ, thêm hai nhóm chỉ số ở hai thời điểm, sửa/xóa, tạo lịch, xác nhận lần đến hạn bằng clock kiểm thử, đóng/mở database, xác minh dữ liệu. Clock kiểm thử không được trở thành tùy chọn chỉnh giờ của người dùng bản phát hành.
- [ ] **7.2** Chạy `flutter analyze`, `flutter test`; ghi output và lỗi còn tồn tại, không tuyên bố đạt khi command chưa chạy được.
- [ ] **7.3** Chạy `flutter build apk --release` và `flutter build windows --release`. Ghi đường dẫn APK/thư mục release thực tế. Kiểm tra bản Windows chạy ngoài IDE vẫn tải được SQLite native library.
- [ ] **7.4** Kiểm chứng Windows notification trên bản có package identity, dự kiến MSIX: tạo, nhận sau đóng app, chạm mở đúng lịch, sửa/tắt/xóa hủy lịch cũ. Ghi yêu cầu ký/cài gói; không tự cài chứng chỉ hoặc đổi cấu hình bảo mật hệ thống để vượt hạn chế.
- [ ] **7.5** Kiểm chứng Android khi mở/đóng app, quyền bị từ chối, quyền được cấp lại, sửa/tắt/hủy lịch và khởi động lại thiết bị nếu cấu hình hỗ trợ. Ghi rõ trạng thái tắt cưỡng bức/tiết kiệm pin được kiểm tra, không hứa các trạng thái chưa thử.
- [ ] **7.6** Kiểm tra trực quan hai nền tảng: cỡ chữ, lỗi/rỗng/tải, chart thiếu dữ liệu, phóng/thu cửa sổ, cuộn form; chụp ảnh bằng dữ liệu giả. Mục không có thiết bị/quyền ghi Chưa kiểm chứng và nêu cách người dùng kiểm tra.
- [ ] **7.7** Cập nhật README và kịch bản demo hai quy trình; kiểm tra hướng dẫn bằng chính bản build hiện có.

### Task 8: Báo cáo phân tích nghiệp vụ và cài đặt

**Files:** Create `docs/diagrams/`, `deliverables/bao_cao_quan_ly_suc_khoe.docx`; nguồn nội dung có thể lưu `docs/report-source.md` để tái tạo.

**Interfaces:** Consumes spec được duyệt, schema/model thực tế, DESIGN, ảnh và biên bản task 7; produces DOCX tiếng Việt với sơ đồ và kết quả đúng ứng dụng.

- [ ] **8.1** Áp dụng skill documents trước khi tạo DOCX. Lập nội dung theo mục 11 của spec; đặc tả đủ hai quy trình, tiền/hậu điều kiện, luồng chính/ngoại lệ, quy tắc và ánh xạ kiểm thử.
- [ ] **8.2** Tạo Use Case tổng quát, Activity và Sequence cho từng quy trình, ERD bốn bảng. Hệ điều hành là hệ thống ngoài cung cấp thông báo; không bịa tác nhân đăng nhập. ERD/kiểu dữ liệu phải đối chiếu schema cuối, không chỉ sao bản nháp.
- [ ] **8.3** Soạn DOCX với mặc định Times New Roman 13, trang A4, mục lục/caption nhất quán. Bảng/sơ đồ ưu tiên dễ đọc khi in đen trắng; thông tin chưa có để chỗ điền. Phần khảo sát mô tả là phân tích tình huống giả định nếu không có khảo sát thật.
- [ ] **8.4** Render DOCX thành trang ảnh/PDF bằng workflow của skill, kiểm tra toàn bộ trang; sửa bảng tràn, sơ đồ mờ, chữ nhỏ và ngắt trang xấu. Kiểm tra thuật ngữ, số hình/bảng, tham khảo chính chủ, tình trạng kiểm thử và giới hạn 30 ngày/không đồng bộ.
- [ ] **8.5** Đối chiếu mọi khẳng định Đạt với `docs/testing.md`; không dùng ảnh màn hình ngoài app thật. Lưu bản cuối theo yêu cầu lưu deliverable.

### Task 9: Slide, kịch bản bảo vệ và bàn giao

**Files:** Create `deliverables/thuyet_trinh_quan_ly_suc_khoe.pptx`; Modify `docs/demo-script.md`, README; tập hợp các artifact build task 7 thực sự tạo được.

**Interfaces:** Consumes báo cáo đã kiểm tra và bằng chứng task 7; produces slide 10–12 trang, kịch bản demo và các đường dẫn bàn giao.

- [ ] **9.1** Áp dụng skill presentations trước khi tạo PPTX. Xây 11 slide: bài toán, mục tiêu/phạm vi, chức năng, quy trình chỉ số, quy trình lịch, kiến trúc đa nền tảng, SQLite, UI Android, UI Windows, demo/kiểm thử, kết quả/hạn chế/hướng phát triển.
- [ ] **9.2** Mỗi slide dùng sơ đồ/ảnh hoặc nội dung cần trình bày, không dán đoạn báo cáo dài. Ghi chú thuyết trình mô tả thao tác demo và nhấn mạnh hai quy trình thực tế.
- [ ] **9.3** Render/kiểm tra toàn bộ slide theo skill; sửa font tiếng Việt, tràn chữ, hình nhỏ và thứ tự trình bày. Đường dẫn APK/Windows chỉ có nếu đã build; không đưa artifact rỗng.
- [ ] **9.4** Dùng verification-before-completion; chạy lại check liên quan nếu có sửa code kể từ task 7, kiểm tra tệp bàn giao mở được và README khớp. Thực hiện một review cuối toàn phạm vi theo phương thức người dùng chọn; không tự merge/publish.
- [ ] **9.5** Lưu/đồng bộ các tài liệu bàn giao; trả link mã nguồn/artifact/tài liệu và phần chưa kiểm chứng cụ thể. Không tuyên bố hoàn tất cả hai nền tảng nếu còn nền tảng chưa chạy.

## Tự rà soát kế hoạch

- Phạm vi spec 1–4 được bao phủ bởi Global Constraints và task 1, 5, 6.
- Quy trình chỉ số và toàn bộ kiểm tra dữ liệu: task 2, 5, 7.
- Quy trình lịch, lịch sử, quyền và retry thông báo: task 3, 4, 6, 7.
- Schema, chỉ mục, snapshot và an toàn dữ liệu: task 1–4.
- Giao diện thích ứng, tiếp cận, form dirty và trạng thái: task 5–7.
- Báo cáo, sơ đồ, slide, giới hạn và bằng chứng: task 7–9.
- Các interface được khai báo ở task tạo ra chúng; task sau dùng lại, không sinh bộ quy tắc riêng trong UI.
- Review Focus đều có phép kiểm chứng tại task sở hữu hành vi; test mock không thay thế native verification.
- Không có bước cài sản phẩm nào được đánh dấu đã xong chỉ vì thiết kế hoặc kế hoạch đã hoàn thành.

## Phương thức thực hiện đề xuất

Đề xuất Native: tác nhân chính thực hiện tuần tự các task trong phiên này, dùng `superpowers:executing-plans`, rồi một người rà soát độc lập kiểm tra cuối. Các task phụ thuộc chung schema, trạng thái lịch và hợp đồng thông báo; làm tuần tự giảm thay đổi giao diện giữa người triển khai và chi phí nhiều ngữ cảnh.

Lựa chọn thay thế là Subagent-driven: mỗi task do một tác nhân mới thực hiện và một tác nhân khác rà soát trước khi chuyển tiếp; tốn nhiều ngữ cảnh hơn nhưng có kiểm tra độc lập từng phần.

Kế hoạch đang chờ người dùng xem và chọn phương thức thực hiện theo skill writing-plans. Chưa khởi tạo ứng dụng hoặc cài dependency ở bước lập kế hoạch.
