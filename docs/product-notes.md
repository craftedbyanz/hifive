# Ghi chú sản phẩm hifive

Ghi ngày 13/11/2026, cập nhật tiến độ cùng ngày sau khi làm xong Vườn và chế độ tập trung. Đây là bản tổng hợp sau buổi brainstorm về hướng sản phẩm, viết bằng tiếng Việt theo yêu cầu, dùng để xem lại và cập nhật tiến độ. Kế hoạch kỹ thuật chi tiết nằm ở `docs/memory-plan.md` (bộ lõi từ vựng) và `docs/backend-plan.md` (server, đồng bộ, AI).

Trạng thái: **xong**, **đang khoá** (có giao diện, nội dung còn giả lập, hiện nhãn "Sắp ra mắt"), **chưa làm**, **đang làm**.

## 1. Định vị

**hifive: học từ vựng và cụm từ mỗi ngày, vui như trồng một khu vườn.**

Lời hứa: mỗi từ người học gặp ở bất cứ đâu trong hifive đều được theo dõi cho đến khi họ dùng được nó.

Điểm khác biệt:

- Một bộ lõi ghi nhớ khoa học (lặp lại ngắt quãng, active recall) chạy phía sau mọi tính năng.
- Khu vườn và chế độ tập trung làm app được mở hằng ngày, kể cả khi không học tiếng Anh.
- Giao diện 4 ngôn ngữ (Việt, Anh, Trung giản thể, Hàn). Khoá học đầu tiên là tiếng Anh.

## 2. Bộ lõi từ vựng

Bốn việc bộ lõi làm:

1. **Theo dõi:** ghi mỗi lần gặp từ, ở bất kỳ tính năng nào: từ nào, lúc nào, đúng hay sai, kiểu bài tập, nhanh hay chậm, có dùng gợi ý không, đến từ đâu.
2. **Tính toán:** từ nhật ký, tính cho mỗi từ độ bền trí nhớ, độ khó và khả năng nhớ ngay lúc này (thuật toán FSRS). Đúng lúc sắp quên thì độ bền tăng nhiều; sai thì giảm mạnh nhưng không về 0.
3. **Đánh giá:** xếp mỗi từ vào một mức (Mới, Đang học, Đang nhớ, Thuộc, Thành thạo) và cho người học thấy số từ theo mức, tỉ lệ nhớ thực tế, từ khó, kỹ năng yếu.
4. **Nhắc và đề xuất:** nhắc ôn khi có từ sắp quên; số từ mới mỗi ngày tự điều chỉnh theo sức học; thứ tự chọn từ mới là từ tự lưu, bộ tự tạo, rồi kho của hifive.

Hai nguồn từ dùng chung một bộ lõi:

- **Kho của hifive:** từ theo trình độ và chủ đề. Người học bắt đầu học một bộ, thêm từ vào bộ riêng, ẩn từ, ghi chú riêng.
- **Của người học:** bộ thẻ và thẻ tự tạo, sửa, xoá; từ lưu từ từ điển.

Cùng một từ ở cả hai nguồn chỉ có một hồ sơ trí nhớ.

## 3. Tính năng theo hành trình học

| Chặng | Tính năng | Trạng thái |
|---|---|---|
| Gặp từ | Kho từ của hifive theo trình độ và chủ đề (gói khởi đầu 3 bộ A1, phát từ Worker) | xong, đã deploy |
| | Bộ thẻ tự tạo, sửa, xoá | xong |
| | Từ điển, lưu từ (chưa lưu kèm câu gốc) | xong |
| | Nghe: playlist YouTube phát ngay trong app (mục Nghe trong menu), nguồn do mình chọn trong kho từ, lưu từ vừa nghe; phụ đề tính sau | xong; nguồn đầu tiên: playlist A1 của kênh REACH (gói kho từ 2, chờ deploy) |
| Hiểu | Thẻ từ: nghĩa, phiên âm, giọng đọc, câu ví dụ | xong |
| | Cụm từ, cụm đi kèm, nhiều câu ví dụ | chưa làm |
| Nhớ | Flashcard với lịch ôn FSRS, cùng một từ ở nhiều bộ dùng chung một trí nhớ | xong |
| | "Ôn hôm nay" gộp mọi bộ, đề xuất từ mới theo sức học | xong |
| | Bài tập: chọn nghĩa, gõ từ, nghe viết, điền vào câu | xong |
| | FlowLetter, game chính tả (chưa nối bộ lõi) | xong |
| | Nhắc học khi có từ sắp quên (thông báo cục bộ mỗi ngày) | xong trên iOS |
| Áp dụng | Bài tập ghép câu, điền cụm, app tự chấm | chưa làm |
| | Shadowing: nghe rồi nhắc theo, thu âm so sánh (cần nội dung có mốc thời gian) | chưa làm |
| | Luyện viết, Ngữ pháp (cần AI chấm) | đang khoá |
| | Hội thoại với AI | đang khoá |
| | Tạo bài học và bộ thẻ bằng AI | đang khoá |
| Thấy tiến bộ | Insight: thống kê buổi học | xong |
| | Gợi ý cải thiện trong Insight (cần AI) | đang khoá |
| | Insight trí nhớ: số từ theo mức, tỉ lệ nhớ, dự báo 7 ngày, kỹ năng, từ khó; trang chi tiết từng từ | xong |
| | Chuỗi ngày học | xong |

## 4. Giữ thói quen và niềm vui

Kế hoạch kỹ thuật và chi tiết từng bước: `docs/garden-plan.md`. Bản mẫu đã duyệt: `docs/mockups/garden.html`.

### Đã làm

| Tính năng | Mô tả | Trạng thái |
|---|---|---|
| Khu vườn | Màn Vườn nhìn chéo chia ô, tab Ngày/Tuần/Tháng/Năm, số cây sống và héo, thống kê thời gian tập trung, lượt tưới, ngày học | xong, đã cài lên iPhone |
| Cây học | Mỗi thẻ mới hoặc đến hạn được ôn là một lượt tưới (mỗi thẻ một lần một ngày); 10 lượt thành một cây; chọn loài cho cây học tiếp theo | xong |
| 28 loài cây | 4 nhóm: Khởi đầu, Vườn học, Cây Việt Nam, Huyền thoại; vẽ bằng code, có gió, hoa rơi, chim, ong, bướm; 5 hình thái từ mầm đến nở hoa | xong |
| Mở khoá loài | Theo thành tích: số từ thuộc, chuỗi ngày, giờ tập trung, số phiên, học buổi tối, học trong tháng Tết… Bộ sưu tập ghi rõ điều kiện từng loài | xong; các mốc là đề xuất, chỉnh được |
| Chế độ tập trung | Thước kéo chọn phút (mỗi vạch 5 phút, tối đa 180, rung mỗi vạch), chế độ Bấm giờ đếm lên, 10 giây đầu huỷ miễn phí, bỏ cuộc thì cây héo | xong |
| Nhãn và tiêu đề phiên | Nhãn ở góc trên trái, tiêu đề phiên ngay dưới; 4 nhãn sẵn và nhãn tự tạo (tên, 8 màu, sửa, xoá); danh sách nhãn dạng viên bo tròn trên nền mờ | xong |
| Rời app và khoá máy | Rời app quá 30 giây thì cây héo; khoá máy thì không (iOS báo khi máy có mật mã); thông báo "Cây của bạn sắp héo" sau khoảng 12 giây rời app | xong trên iOS, chưa thử các ca này trên iPhone |
| Giờ nghỉ ôn từ | Phiên xong mời ôn tối đa 8 từ sắp quên; có ôn thì cây nở hoa | xong |
| Thống kê theo nhãn | Thanh màu, thời gian và tỉ lệ của từng nhãn trong kỳ đang xem | xong |
| Chia sẻ ảnh khu vườn | Ảnh nét của khu vườn và số cây, mở bảng chia sẻ của iPhone | xong |
| Lối vào | Khung "Vườn của bạn" trên Home thay chỗ "Đăng ký Hifive Plus"; mục Vườn trong menu; "Cây học +N lượt tưới" ở màn tổng kết ôn | xong |
| Ngọn lửa động, icon menu động, chuyển động menu, rung khi bấm | | xong |

### Còn thiếu

| Việc | Lý do hoặc điều kiện |
|---|---|
| Widget màn hình chính (cây đang lớn, số từ cần ôn) | Cần App Groups, tài khoản Apple cá nhân không có; chờ Apple Developer Program |
| Android: nhận biết khoá máy, thông báo sắp héo | Máy này chưa build được Android (lỗi chứng chỉ Gradle) |
| Khoá máy trên iPhone không đặt mật mã | iOS không báo, nên bị tính như rời app |
| Khoá các app gây xao nhãng | Cần Apple duyệt quyền Family Controls; ghi lại để làm sau |
| Dòng thời gian các phiên | Danh sách từng phiên theo ngày, kèm nhãn, tiêu đề, kết quả; dữ liệu đã có |
| Thử trên iPhone | Khoá máy giữa phiên, chuyển app để thấy cảnh báo, độ mượt khi nhiều cây, rung của thước |

### Quyết định đã chốt

- Một khu vườn, hai nguồn nuôi cây: việc học từ và phiên tập trung.
- Chế độ tập trung dùng cho mọi việc, không riêng tiếng Anh.
- Garden, tập trung và Cộng đồng là ý tưởng riêng của hifive, xây từ đầu.
- Cây tính trên máy từ nhật ký và đồng bộ sau; ngày tính theo giờ địa phương; khoá máy không làm héo cây; cây héo vẫn nằm trong vườn; dùng hifive trong phiên (ví dụ ôn từ) không tính là rời app.
- Vườn và chế độ tập trung học bố cục và cơ chế theo thể loại app trồng cây tập trung. Hình vẽ, màu và câu chữ làm riêng cho hifive; các phần khác của app giữ nguyên design system.
- Mặc định tạm dùng, đổi được: 10 lượt tưới một cây học; phiên tập trung không giữ chuỗi ngày.

Ghi lại để làm sau:

- Khoá các app gây xao nhãng trong phiên tập trung (Family Controls, cần Apple Developer Program và đơn xin).
- Không gian thư giãn: bài tập thở, âm thanh nền.
- Xu, cửa hàng cây và kiểu đất, lựa chọn mỗi ngày, vé mùa, thử thách ngày và tháng.

Không làm:

- Quảng cáo và các màn mời mua Plus chen vào giữa luồng dùng. Khung mời Plus trên Home đã thay bằng khung Vườn; trang Plus vẫn mở được từ menu.
- Ghi việc thường nhật kiểu "Did I Do". Chỉ lấy ý tưởng widget tối giản của nó.

## 5. Cộng đồng

Làm từng nấc, sau khi đã có người dùng.

| Nấc | Mô tả | Trạng thái |
|---|---|---|
| 1 | Chia sẻ bộ thẻ bằng liên kết hoặc mã | chưa làm |
| 2 | Khám phá bộ thẻ công khai; lưu hoặc tạo bản sao | chưa làm |
| 3 | Nhóm học: mã mời, mục tiêu số ngày mỗi tuần | chưa làm |
| 4 | Lớp học: giáo viên giao bài có hạn, xem báo cáo | chưa làm |

Lưu ý: nội dung do người dùng tạo cần báo cáo vi phạm và chặn người dùng (App Store bắt buộc), kèm rủi ro bản quyền. Hoàn thành bài giao nên đi qua bộ lõi, để chỉ có một hệ thống tiến độ.

## 6. Nền tảng

| Phần | Trạng thái |
|---|---|
| Đăng nhập email, Google | xong |
| Đăng nhập Apple | tắt, chờ Apple Developer Program |
| Lưu offline (SQLite), đồng bộ nhiều máy (Cloudflare Worker + D1) | xong, chưa thử trên máy thật |
| Đổi ngôn ngữ app (4 thứ tiếng) | xong, chưa xem chữ Trung và Hàn trên máy thật |
| Xoá tài khoản (App Store bắt buộc) | chưa làm |
| Trang chính sách, landing page, email hỗ trợ | chưa làm |
| Báo lỗi và phân tích (Crashlytics, Analytics) | chưa làm |
| Kho từ trên server | xong, đã deploy (Worker static assets; R2 chưa bật trên tài khoản) |
| AI trên Worker | chưa làm, chưa chọn nhà cung cấp |
| Thanh toán gói Plus | chưa làm |
| Build Android | vướng lỗi chứng chỉ Gradle trên máy này |

Hạ tầng giữ nguyên: Firebase cho phần trên điện thoại (đăng nhập, thông báo, báo lỗi, phân tích), Cloudflare cho phần server (API, cơ sở dữ liệu, file, web). Không thêm Supabase hay Vercel.

## 7. Mô hình kinh doanh

**Miễn phí:** bộ lõi ghi nhớ, Flashcard, FlowLetter, khu vườn, chế độ tập trung, widget, xem video YouTube (điều khoản YouTube không cho bán quyền xem), chia sẻ và lưu bộ thẻ.

**Plus (theo tháng hoặc năm):** mọi tính năng AI (chấm bài viết, hội thoại, tạo bộ thẻ và bài học, gợi ý cải thiện, bài nghe cá nhân hoá, chấm phát âm), kho từ đầy đủ các trình độ, thống kê trí nhớ nâng cao, loài cây và cảnh vườn đặc biệt.

**Về sau:** gói cho giáo viên và trung tâm (lớp học, báo cáo).

Chi phí: hạ tầng từ 0 đến khoảng 5 USD/tháng cho đến vài chục nghìn người dùng; Apple Developer 99 USD/năm; AI theo lượt dùng, chỉ phát sinh ở người dùng Plus; phí store 15% doanh thu với chương trình doanh nghiệp nhỏ. Các con số cần kiểm tra lại trên trang giá trước khi dựa vào.

Kênh tăng trưởng: bộ thẻ chia sẻ bằng liên kết, nhóm học mời bạn, ảnh khu vườn, tìm kiếm trên store theo cả "học từ vựng" và "tập trung".

## 8. Lộ trình

| Giai đoạn | Nội dung | Trạng thái |
|---|---|---|
| 1. Bộ lõi | FSRS, ôn hôm nay, bài tập đa dạng, nhắc học, Insight trí nhớ, kho từ | xong (`docs/memory-plan.md`), kho từ đã deploy |
| 2. Lên store | Apple Developer, xoá tài khoản, trang chính sách, báo lỗi | chưa làm |
| 3. Niềm vui | Khu vườn, chế độ tập trung, nhãn, chia sẻ, widget | xong trừ widget (chờ Apple Developer Program) và Android |
| 4. Nội dung | Kho từ theo trình độ, mục Nghe với YouTube, chia sẻ bộ thẻ | chưa làm |
| 5. Doanh thu | AI trên server, mở Luyện viết và Hội thoại, gói Plus | chưa làm |
| 6. Mở rộng | Shadowing, Khám phá, Nhóm, Lớp học, khoá ngôn ngữ thứ hai | chưa làm |

## 9. Rủi ro

- Phạm vi rất rộng: app học từ, app tập trung, cộng đồng và video. Làm dàn trải thì không phần nào đủ tốt.
- Kho từ và nguồn video cần người tuyển chọn đều đặn.
- Cộng đồng kéo theo kiểm duyệt và bản quyền.
- Tài khoản Apple hiện tại là tài khoản cá nhân: chưa phát hành được, bản cài hết hạn sau 7 ngày.
- Shadowing từng câu cần phụ đề có mốc thời gian, mà YouTube không cấp phụ đề của video người khác qua API chính thức.

## 10. Điểm còn chờ quyết định

1. Phiên tập trung có giữ chuỗi ngày không (đang tạm: không).
2. Số lượt tưới cho một cây học (đang tạm: 10) và các mốc mở khoá loài cây.
3. Home xoay quanh "buổi học hôm nay", hay giữ dạng chọn tính năng.
4. Người học mục tiêu: người mới cần dẫn dắt, hay người đã có nền.
5. Ranh giới miễn phí và Plus ở mục 7.
6. Cụm từ là một loại thẻ ngang hàng với từ đơn, hay phần gắn kèm mỗi từ.
7. Số từ mới mỗi ngày mặc định; bài tập gõ từ bật sẵn hay không; kho từ đầu tiên phủ trình độ nào và ai soạn.
