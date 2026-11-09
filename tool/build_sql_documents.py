"""Build the current SQL Server report and presentation; archived SQLite files stay intact."""
from pathlib import Path

from docx import Document
from docx.shared import Inches, Pt, RGBColor as DocColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from pptx import Presentation
from pptx.util import Inches as SlideInches, Pt as SlidePt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from pptx.enum.shapes import MSO_SHAPE

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'deliverables'
OUT.mkdir(exist_ok=True)
NAVY = (20, 39, 59)
TEAL = (2, 124, 114)

doc = Document()
section = doc.sections[0]
section.top_margin = Inches(.78)
section.bottom_margin = Inches(.72)
section.left_margin = Inches(.88)
section.right_margin = Inches(.88)
styles = doc.styles
styles['Normal'].font.name = 'Times New Roman'
styles['Normal'].font.size = Pt(12)
styles['Normal'].paragraph_format.space_after = Pt(6)
for name, size in [('Title', 22), ('Heading 1', 16), ('Heading 2', 13)]:
    style = styles[name]
    style.font.name = 'Times New Roman'
    style.font.size = Pt(size)
    style.font.color.rgb = DocColor(*NAVY)

def p(text, style=None):
    return doc.add_paragraph(text, style)

def bullets(*items):
    for item in items:
        p(item, 'List Bullet')

def table(headers, rows):
    t = doc.add_table(rows=1, cols=len(headers))
    t.style = 'Light Shading Accent 1'
    for i, header in enumerate(headers):
        t.rows[0].cells[i].text = header
    for row in rows:
        cells = t.add_row().cells
        for i, value in enumerate(row):
            cells[i].text = value
    doc.add_paragraph()

title = doc.add_paragraph(style='Title')
title.alignment = WD_ALIGN_PARAGRAPH.CENTER
title.add_run('BÁO CÁO ĐỒ ÁN\nỨNG DỤNG QUẢN LÝ SỨC KHỎE CÁ NHÂN')
for line in [
    'Học phần: Lập trình đa nền tảng',
    'Nền tảng: Android và Windows • Flutter / Dart',
    'Lưu trữ: Microsoft SQL Server qua ASP.NET Core Web API',
    'Phiên bản tài liệu: 09/11/2026',
    'Sinh viên: ........................................    Giảng viên: ........................................',
]:
    q = p(line)
    q.alignment = WD_ALIGN_PARAGRAPH.CENTER
p('Tài liệu này mô tả phiên bản SQL Server hiện tại. Tài liệu SQLite trước đó được giữ tại deliverables/sqlite_archive để đối chiếu lịch sử.')
doc.add_page_break()

doc.add_heading('1. Bài toán và phạm vi', level=1)
p('Người dùng cá nhân cần ghi nhận số đo sức khỏe và theo dõi lịch uống thuốc hoặc tái khám trên điện thoại, máy tính. Dữ liệu của một hồ sơ được lưu tập trung trong SQL Server để các thiết bị truy cập cùng một nguồn; ứng dụng chỉ sử dụng được khi kết nối API. Mục tiêu là quản lý thông tin, không chẩn đoán bệnh và không thay thế tư vấn y khoa.')
table(['Vai trò', 'Nhu cầu', 'Kết quả'], [
    ('Chủ hồ sơ', 'Nhập hồ sơ, số đo, kế hoạch chăm sóc', 'Xem diễn biến và việc đến hạn'),
    ('Thiết bị Android/Windows', 'Đặt thông báo cục bộ', 'Nhắc lịch theo quyền của hệ điều hành'),
    ('API và SQL Server', 'Xác thực khóa, kiểm tra nghiệp vụ, lưu tập trung', 'Trả dữ liệu và lịch sử nhất quán'),
])
p('Phạm vi triển khai là một hồ sơ cá nhân dùng khóa API riêng. Chưa có quản lý nhiều tài khoản, đồng bộ ngoại tuyến hoặc dịch vụ thông báo đẩy liên tục.')

doc.add_heading('2. Quy trình nghiệp vụ 1: theo dõi sức khỏe', level=1)
bullets(
    'Tạo/cập nhật hồ sơ: tên, ngày sinh, chiều cao và mục tiêu. Ứng dụng kiểm tra đầu vào, API là nơi quyết định dữ liệu hợp lệ.',
    'Nhập số đo với thời điểm ghi nhận: cân nặng, cặp huyết áp tâm thu/tâm trương hoặc nhịp tim. Huyết áp phải nhập đủ hai trị số; không lưu bản ghi hoàn toàn rỗng hoặc thời điểm trong tương lai.',
    'Khi thêm/sửa/xóa, API ghi vào SQL Server trong giao dịch. Bản ghi số đo giữ snapshot chiều cao để số đo lịch sử có ngữ cảnh.',
    'Màn hình tổng quan lấy giá trị mới nhất riêng cho từng loại số đo; biểu đồ và danh sách lọc theo khoảng ngày. Người dùng có thể sửa hoặc xóa bản ghi.',
)
p('Ngoại lệ: khi API không trả lời, nội dung form vẫn còn để thử lại. Trường hợp ghi thành công nhưng phản hồi thất lạc, khóa Idempotency-Key giúp tránh lặp lại trong cùng phiên ApiClient; sau khi khởi động lại cần kiểm tra danh sách trước khi tạo lại.')

doc.add_heading('3. Quy trình nghiệp vụ 2: kế hoạch chăm sóc', level=1)
bullets(
    'Tạo nhắc thuốc một lần hoặc hằng ngày, tối đa 30 ngày và một lần/ngày; tạo lịch tái khám một lần. Ngày/giờ được diễn giải theo UTC+7.',
    'API tạo các lần đến hạn riêng (occurrence), chỉ cho phép đánh dấu hoàn thành hoặc bỏ qua khi đã đến hạn; kết quả đã lưu không bị thay đổi do sửa kế hoạch tương lai.',
    'Sửa, tắt hoặc lưu trữ kế hoạch: hủy occurrence tương lai không còn hiệu lực, tạo lịch thay thế và bảo toàn lịch sử đã hoàn thành/bỏ qua.',
    'Mỗi thiết bị đối chiếu các occurrence tương lai với thông báo hệ điều hành và trạng thái riêng của device_id; khi quay lại mạng sẽ hủy thông báo không còn trong danh sách máy chủ.',
)
p('Ngoại lệ: hệ điều hành có thể từ chối quyền hoặc chậm thông báo; lịch và kết quả trên SQL Server vẫn là nguồn dữ liệu chính. Thiết bị offline không biết ngay lịch vừa sửa từ thiết bị khác.')

doc.add_heading('4. Thiết kế kiến trúc và giao diện', level=1)
p('Flutter hiển thị giao diện thích ứng: điện thoại dùng điều hướng gọn, Windows dùng không gian rộng cho danh sách, biểu đồ và biểu mẫu. Tầng repository làm việc qua ApiClient HTTP/JSON. API ASP.NET Core xác thực khóa, kiểm tra quy tắc nghiệp vụ và truy cập SQL Server bằng câu lệnh có tham số; mật khẩu SQL chỉ nằm ở máy backend.')
table(['Tầng', 'Thành phần', 'Nhiệm vụ'], [
    ('Giao diện', 'Tổng quan, Sức khỏe, Kế hoạch, Hồ sơ', 'Hiển thị, nhập liệu, thông báo lỗi và xác nhận xóa'),
    ('Flutter', 'ApiClient, repositories, NotificationSync', 'Gọi API, giữ form, đặt/hủy thông báo thiết bị'),
    ('ASP.NET Core', 'Routes, Rules, SqlStore', 'Xác thực, kiểm tra dữ liệu, giao dịch và lịch'),
    ('SQL Server', '7 bảng và ràng buộc', 'Lưu hồ sơ, số đo, kế hoạch, lần đến hạn, trạng thái'),
])

doc.add_heading('5. Thiết kế dữ liệu SQL Server', level=1)
table(['Bảng', 'Nội dung / ràng buộc chính'], [
    ('profiles', 'Một hồ sơ id=1; thông tin cá nhân và mục tiêu'),
    ('health_records', 'Số đo và snapshot chiều cao; thời điểm UTC milliseconds'),
    ('care_reminders', 'Định nghĩa kế hoạch thuốc hoặc tái khám'),
    ('reminder_occurrences', 'Từng lần đến hạn; trạng thái và kết quả lịch sử'),
    ('device_notifications', 'Trạng thái đặt/hủy thông báo theo từng thiết bị'),
    ('api_requests', 'Khóa ghi, dấu vết nội dung và kết quả để chống ghi trùng'),
    ('server_settings', 'Phiên bản schema và mã backend phục vụ chuyển máy chủ'),
])
p('Chuỗi Unicode dùng nvarchar, số đo thực dùng float(53), thời điểm dùng bigint UTC milliseconds; lịch người dùng dùng ngày và giờ địa phương UTC+7. Khóa ngoại, CHECK và chỉ mục unique lọc cho occurrence còn hiệu lực bảo vệ tính toàn vẹn. Ghi dữ liệu có giao dịch serializable và khóa hàng cấu hình để tuần tự hóa thay đổi cho một hồ sơ.')

doc.add_heading('6. An toàn dữ liệu và triển khai', level=1)
bullets(
    'Ứng dụng gọi API bằng X-Api-Key, X-Device-Id; các thao tác ghi có Idempotency-Key. API không trả lỗi SQL hoặc khóa bí mật trong phản hồi.',
    'Chỉ dùng HTTP/TrustServerCertificate cho demo Development trên máy hoặc LAN riêng. Vận hành thực tế cần HTTPS và chứng chỉ tin cậy; khóa API cá nhân không thay thế đăng nhập đa người dùng.',
    'SQL Server không mở trực tiếp cho ứng dụng di động. ConnectionStrings__Health cấu hình trên backend, không đóng gói vào APK/EXE; dữ liệu cũ chỉ nhập vào database rỗng.',
    'Xuất SQLite v1 ở chế độ chỉ đọc ra JSON, kiểm tra JSON rồi nhập bốn bảng trong một giao dịch; giữ ID, timestamp, snapshot và lịch sử. Bản gốc không bị sửa.',
)
p('Bắt đầu: cài Flutter, .NET SDK 9, SQL Server và sqlcmd. Tại thư mục dự án, chạy .\\tool\\start_api.ps1 -Server "." -Initialize; sau đó chạy .\\tool\\run_app.ps1 -Device windows. Android emulator dùng 10.0.2.2; thiết bị thật dùng HTTPS/IP thích hợp. Chi tiết trong README.md và docs/sql-server.md.')

doc.add_heading('7. Kiểm thử và giới hạn kết luận', level=1)
p('Bộ kiểm thử Flutter chạy 56/56, gồm giao diện, hai quy trình, thử lại sau khi API khôi phục, cấu hình khóa Windows, thông báo thừa và mất phản hồi. Bộ tự kiểm thử backend đạt 15/15; backend đã build với Microsoft.Data.SqlClient. Công cụ xuất SQLite được kiểm tra với dữ liệu thử. Flutter analyze và build Windows Release được chạy riêng; nhật ký tại docs/evidence/sql-server.')
p('Môi trường thực hiện chưa kết nối được SQL Server cục bộ. Vì vậy chưa xác minh kết nối/transaction T-SQL, nhập thực tế, hoạt động Android hoặc thông báo OS cuối cùng. Cần chạy kịch bản nghiệm thu trong docs/testing-sql-server.md trên máy có SQL Server trước khi sử dụng dữ liệu thật.')

doc.add_heading('8. Kết luận và tài liệu bàn giao', level=1)
p('Ứng dụng đáp ứng hai quy trình theo dõi số đo và quản lý kế hoạch chăm sóc trên Android/Windows, với SQL Server làm nguồn lưu trữ tập trung qua API. Mã nguồn, schema, hướng dẫn cài đặt, công cụ chuyển dữ liệu và kiểm thử nằm trong do_an_sql_server.zip. Các file báo cáo và bản chạy SQLite cũ chỉ dùng để tham khảo lịch sử, được tách vào sqlite_archive.')
doc.save(OUT / 'bao_cao_sql_server.docx')

deck = Presentation()
deck.slide_width = SlideInches(13.333)
deck.slide_height = SlideInches(7.5)

def block(slide, x, y, w, h, fill, radius=True):
    shape = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE if radius else MSO_SHAPE.RECTANGLE,
                                  SlideInches(x), SlideInches(y), SlideInches(w), SlideInches(h))
    shape.fill.solid()
    shape.fill.fore_color.rgb = RGBColor(*fill)
    shape.line.fill.background()
    return shape

def box(slide, text, x, y, w, h, size=22, color=NAVY, bold=False):
    shape = slide.shapes.add_textbox(SlideInches(x), SlideInches(y), SlideInches(w), SlideInches(h))
    frame = shape.text_frame
    frame.word_wrap = True
    frame.margin_left = SlideInches(.04)
    frame.margin_top = SlideInches(.04)
    frame.clear()
    for index, line in enumerate(text.split('\n')):
        para = frame.paragraphs[0] if index == 0 else frame.add_paragraph()
        para.text = line
        para.font.name = 'Aptos'
        para.font.size = SlidePt(size)
        para.font.bold = bold
        para.font.color.rgb = RGBColor(*color)
        para.space_after = SlidePt(10)
    return shape

def slide(title, eyebrow):
    s = deck.slides.add_slide(deck.slide_layouts[6])
    block(s, 0, 0, 13.333, 7.5, (246, 249, 248), False)
    block(s, .58, .45, .08, .56, TEAL, False)
    box(s, eyebrow.upper(), .8, .3, 11, .35, 12, TEAL, True)
    box(s, title, .8, .75, 11.6, .9, 32, NAVY, True)
    box(s, f'SỔ SỨC KHỎE CÁ NHÂN  •  SQL SERVER                                  {len(deck.slides):02d}', .8, 7.08, 11.7, .25, 10, (92, 108, 119))
    return s

s = slide('Ứng dụng quản lý sức khỏe cá nhân', 'Đồ án lập trình đa nền tảng')
box(s, 'Flutter / Dart   •   Android + Windows', .9, 2.08, 10, .7, 25, TEAL, True)
box(s, 'Theo dõi số đo và kế hoạch chăm sóc\nDữ liệu tập trung trong SQL Server qua ASP.NET Core API', .9, 3.02, 10.7, 2.0, 25)
block(s, .9, 5.55, 11.5, .7, (224, 239, 235))
box(s, 'Một hồ sơ cá nhân  |  Hai quy trình  |  Hai nền tảng', 1.15, 5.69, 11, .42, 19, TEAL, True)

s = slide('Bài toán và phạm vi', '01 / Nghiệp vụ')
for i, (a, b) in enumerate([
    ('GHI NHẬN', 'Hồ sơ, cân nặng, huyết áp, nhịp tim; biểu đồ và giá trị mới nhất'),
    ('LÊN LỊCH', 'Thuốc một lần / hằng ngày tối đa 30 ngày; tái khám một lần'),
    ('QUẢN LÝ', 'Sửa, xóa, hoàn thành hoặc bỏ qua đúng thời điểm; giữ lịch sử'),
]):
    y = 1.85 + i * 1.57
    block(s, .85, y, 11.6, 1.26, (229, 241, 237))
    box(s, a, 1.12, y + .15, 2.2, .5, 17, TEAL, True)
    box(s, b, 3.35, y + .14, 8.5, .85, 20)

s = slide('Hai quy trình chính', '02 / Luồng xử lý')
for i, (heading, lines) in enumerate([
    ('01  Theo dõi sức khỏe', 'Hồ sơ → Nhập số đo → API kiểm tra → SQL lưu → Xem biểu đồ / sửa / xóa'),
    ('02  Kế hoạch chăm sóc', 'Tạo lịch → Sinh lần đến hạn → Nhắc trên thiết bị → Hoàn thành / bỏ qua → Lưu lịch sử'),
]):
    y = 2.0 + i * 2.1
    block(s, .9, y, 11.5, 1.76, (228, 240, 237))
    box(s, heading, 1.15, y + .15, 10, .5, 21, TEAL, True)
    box(s, lines, 1.15, y + .76, 10.7, .82, 20)

s = slide('Kiến trúc SQL Server', '03 / Kỹ thuật')
for i, (head, detail) in enumerate([
    ('Flutter', 'Android / Windows\nGiao diện và thông báo'),
    ('ASP.NET Core', 'API JSON\nQuy tắc và giao dịch'),
    ('SQL Server', '7 bảng\nDữ liệu tập trung'),
]):
    x = .85 + i * 4.16
    block(s, x, 2.22, 3.78, 2.45, (225, 239, 234))
    box(s, head, x + .25, 2.47, 3.28, .56, 22, TEAL, True)
    box(s, detail, x + .25, 3.19, 3.32, 1.14, 19)
box(s, 'Khóa SQL chỉ đặt trên backend  •  Ghi có Idempotency-Key  •  Thời gian do máy chủ kiểm soát', .9, 5.35, 11.6, .85, 19)

s = slide('Cấu trúc dữ liệu và chuyển đổi', '04 / Dữ liệu')
box(s, 'profiles  •  health_records  •  care_reminders\nreminder_occurrences  •  device_notifications\napi_requests  •  server_settings', 1, 2.0, 11.4, 2.5, 22, NAVY, True)
block(s, .95, 5.1, 11.45, .86, (225, 239, 234))
box(s, 'SQLite v1 → xuất chỉ đọc → kiểm tra JSON → nhập một giao dịch vào SQL Server rỗng', 1.19, 5.29, 10.95, .54, 17, TEAL, True)

s = slide('Kiểm chứng và triển khai', '05 / Kết luận')
box(s, '56/56 kiểm thử Flutter  •  15/15 tự kiểm thử API', .95, 1.82, 11.3, .8, 25, TEAL, True)
box(s, 'Chạy API:  .\\tool\\start_api.ps1 -Server "." -Initialize\nChạy Windows:  .\\tool\\run_app.ps1 -Device windows', .95, 3.03, 11.4, 1.5, 21)
block(s, .95, 5.2, 11.4, .95, (248, 234, 219))
box(s, 'Cần nghiệm thu kết nối SQL Server và thông báo OS trên máy triển khai.', 1.18, 5.4, 10.9, .5, 18, NAVY)

deck.save(OUT / 'thuyet_trinh_sql_server.pptx')
print('Created SQL Server DOCX and 6-slide PPTX')
