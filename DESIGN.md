---
version: alpha
name: "Sức Khỏe Cá Nhân"
description: "Sổ theo dõi chỉ số và lịch chăm sóc cá nhân, dùng SQL Server qua API trên Android và Windows."
colors:
  primary: "#2455A4"
  ink: "#152A43"
  secondary: "#0C776C"
  background: "#F3F6FA"
  surface: "#FFFFFF"
  border: "#DCE4EF"
  muted: "#53657B"
  danger: "#B32632"
  warning: "#875C12"
  success: "#0C776C"
typography:
  display:
    fontFamily: "Georgia, Segoe UI, Roboto, sans-serif"
  sans:
    fontFamily: "Segoe UI, Roboto, sans-serif"
  numeric:
    fontFamily: "Segoe UI, Roboto, sans-serif"
rounded:
  DEFAULT: "12px"
  sm: "8px"
  lg: "20px"
spacing:
  unit: "4px"
  control-gap: "12px"
  panel-gap: "20px"
  page-max: "1120px"
components:
  button: { minHeight: "48px" }
  card: { radius: "20px" }
  field: { minHeight: "56px" }
  dialog: { maxWidth: "640px" }
---

# Sức Khỏe Cá Nhân Design System

## Overview

### Creative North Star

Một cuốn sổ theo dõi sức khỏe có cấu trúc rõ như phiếu ghi chỉ số, nhưng thân thiện khi dùng hằng ngày. Điểm nhấn là dòng thời gian chăm sóc trong ngày: mốc giờ, nội dung và kết quả được đặt cạnh nhau, để việc cần làm luôn rõ hơn phần trang trí.

- Audience: một cá nhân tự ghi dữ liệu và thực hiện lịch chăm sóc; không phải phần mềm chẩn đoán hay quản lý phòng khám.
- Evidence: thiết kế và kế hoạch tại `docs/superpowers/`, được người dùng duyệt ngày 31/10/2026.
- Locale: tiếng Việt, lịch theo Asia/Ho_Chi_Minh, UTC+7; không có phạm vi thị trường/locale Nhật Bản.
- Product register: ứng dụng công cụ, dữ liệu thật và trạng thái dễ đọc đứng trước biểu đạt thương hiệu.
- Usage: thao tác nhanh trên điện thoại; xem lịch sử và chỉnh lịch trên máy tính. Ngoại tuyến.
- Restraint: không dùng hình ảnh trang trí, gradient lớn, huy hiệu bệnh hoặc màu biểu đồ để suy đoán sức khỏe.
- Anti-reference: giao diện bệnh viện nhiều vai trò và dashboard có số liệu mẫu giả như dữ liệu thật.
- Token mapping: frontmatter là chủ ý chuẩn; `lib/ui/app_theme.dart` là adapter Flutter duy nhất. Mọi màn hình dùng Theme/ColorScheme và shared primitives; kiểm tra drift bằng audit và xem hai luồng cùng nhau. Các số pixel trên tương ứng logical pixels trong Flutter.

## Colors

Nền xanh xám nhạt `background`, mặt giấy trắng `surface`, chữ xanh mực `ink`. Xanh dương `primary` dành cho thao tác chính và cân nặng; xanh lục `secondary` cho hoàn thành và nhịp tim. `danger` chỉ cho thao tác xóa/lỗi, không làm nhãn chẩn đoán. `warning` đi cùng chữ “Quá hạn” hoặc “Chưa bật thông báo”. Border và muted dùng thống nhất giữa hai luồng.

Bản đầu có một theme sáng; không tạo nút đổi theme không hoạt động. Focus và trạng thái selected có cả hình/nét/nhãn, không chỉ màu. Cố định palette chart trong theme, huyết áp có hai đường với legend tâm thu/tâm trương.

## Typography

Body dùng font hệ thống có tiếng Việt: Segoe UI trên Windows, Roboto trên Android. Không tải font từ mạng khi ứng dụng mở. Tiêu đề chính có thể dùng Georgia với fallback sans, dùng tiết chế như tiêu đề sổ. Dữ liệu dùng số có độ rộng nhất quán khi font hỗ trợ. Body 15–16 logical pixels, chiều cao dòng khoảng 1.45; heading 24–30. Cho phép text scaling, không cố định chiều cao khối nội dung dựa trên một dòng.

## Layout

Khoảng cách theo bội số 4: 12 giữa control, 20 giữa panel, 24 padding desktop và 16 mobile. Nội dung tối đa 1120. Dưới 600 dùng NavigationBar; từ 600 dùng NavigationRail. LayoutBuilder chọn theo cửa sổ, không chọn theo tên hệ điều hành. Phần tổng quan và card chỉ số đổi từ một cột sang hai cột theo không gian có sẵn. Form tối đa 640, có cuộn riêng khi bàn phím hiện; điều hướng tab giữ vị trí và bộ lọc.

Mỗi màn hình có một chủ sở hữu cuộn chính, không đặt list không giới hạn trong Column thiếu ràng buộc. Danh sách được lọc ngày hoặc tải theo lô; không fetch vô hạn vào bộ nhớ chỉ để vẽ bảng.

## Elevation & Depth

Mặt phẳng và đường viền thể hiện cấu trúc; card thường không bóng đậm. Dialog và menu có elevation Material hợp lý. Không làm form hoặc bảng nổi như nút. Thanh điều hướng có ranh giới tĩnh, không overlay che focus.

## Shapes

Card bo 20; field và control bo 12; icon nhỏ bo 8. Hình tròn chỉ dùng cho mốc thời gian hoặc icon trạng thái. Không ép mọi control thành capsule.

## Components

- States: mặc định, hover/focus/pressed, disabled/busy, loading, rỗng, lỗi/thử lại, success. Dùng CircularProgressIndicator của app; giữ kích thước nút khi busy. Không dựng skeleton chỉ để trang trí.
- Buttons: FilledButton cho Lưu/Thêm, OutlinedButton cho thao tác phụ, TextButton cho Hủy; xóa tách khỏi nút chính và xác nhận bằng AlertDialog.
- Navigation: Tổng quan, Chỉ số, Lịch chăm sóc, Hồ sơ; cùng nhãn và thứ tự trên hai layout.
- Forms: TextFormField có label và đơn vị; lỗi tại trường; preserve giá trị khi lỗi, chống double submit, cảnh báo rời form dirty. Date/time picker Material với locale tiếng Việt; single-select dùng DropdownButtonFormField Material, không tạo popup riêng.
- Feedback: shared SnackBar xác nhận kết quả; lỗi cần sửa giữ inline. Lỗi thông báo không làm lịch vừa lưu biến mất.
- Scrollbars: ScrollbarTheme và ScrollBehavior toàn app; desktop hiển thị thanh cuộn theo con trỏ, không ẩn scrollbar để làm đẹp.
- Icons: Material Icons outlined khi chưa chọn và filled khi chọn; icon-only có tooltip tiếng Việt.
- Motion: animation Material ngắn để thể hiện trạng thái; tôn trọng disableAnimations, không có chuyển động trang trí liên tục.
- Charts: đọc giá trị và thời điểm, không chèn ngày thiếu thành 0. Có legend, đơn vị và bản tóm tắt/văn bản tương đương; không chỉ truyền đạt bằng màu.
- Voice: “Thêm chỉ số”, “Lưu chỉ số”, “Tạo lịch”, “Hoàn thành”, “Bỏ qua”. Không ghi thuật ngữ schema, API hoặc dependency vào flow người dùng.

## Do's and Don'ts

- Do: đưa lịch hôm nay và chỉ số gần nhất lên trước.
- Do: cùng một thao tác có cùng nhãn, trạng thái và kết quả điều hướng giữa các màn hình.
- Don't: tự thêm dữ liệu giả vào hồ sơ thật hoặc hiển thị số 0 như thể đã đo.
- Don't: dùng màu/huy hiệu để chẩn đoán, hoặc hứa thông báo chính xác khi quyền hệ điều hành chưa có.
