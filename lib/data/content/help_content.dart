const helpTitles = [
  '3 Chế Độ Luyện Tập Chính',
  'Trợ Lý AI & Hệ Thống Phản Hồi',
  'AI Magic Generator',
  'Hệ thống Flashcard & SRS',
  'Hệ Thống Theo Dõi Tiến Độ',
  'Chức Năng Ôn Tập Thông Minh',
  'Mini Game: Flow Letter',
];

/// The reference's own text (survey 93, 100–105), word for word.
const helpBodies = [
  'Ứng dụng cung cấp 3 phương thức thực hành riêng biệt nhằm phát triển toàn diện các kỹ năng:\n\n• Đoạn văn (Paragraph): Tập trung kỹ năng viết và dịch thuật văn bản dài. Người dùng viết đoạn văn theo gợi ý, sau đó AI sẽ chấm điểm và chỉnh sửa văn phong tự nhiên.\n\n• Luyện câu (Sentence): Giải quyết các lỗi ngữ pháp và cấu trúc trong câu đơn. Phù hợp cho việc ôn tập nhanh các quy tắc ngữ pháp cơ bản.\n\n• Hội thoại (Conversation): Thực hành phản xạ giao tiếp. Bao gồm chế độ \'Kịch bản\' (tình huống giả định như đi du lịch, phỏng vấn) và \'Tự do\' (trò chuyện mở với AI).',
  'Sau mỗi bài tập, AI sẽ cung cấp phân tích chi tiết để người dùng hiểu rõ các lỗi đã mắc phải:\n\n1. Nhận diện lỗi: Màu đỏ đánh dấu các lỗi sai về ngữ pháp hoặc từ vựng cần sửa đổi.\n2. Gợi ý nâng cao: Màu xanh lá hiển thị các cách diễn đạt tự nhiên hơn hoặc chính xác hơn về mặt ngữ cảnh.\n3. Giải thích chi tiết: Chạm vào vùng được đánh dấu lỗi hoặc gợi ý để xem giải thích sâu về quy tắc ngôn ngữ hoặc lý do tại sao gợi ý đó lại tốt hơn.',
  'AI Magic Generator cho phép người dùng tự thiết kế lộ trình học tập dựa trên nhu cầu thực tế thay vì các bài học cố định:\n\n1. Cách sử dụng: Nhập bất kỳ chủ đề hoặc tình huống cụ thể (Ví dụ: \'Phỏng vấn xin việc\', \'Email phàn nàn về dịch vụ\', \'Hội thoại đi mua sắm\').\n2. Tùy chỉnh: Lựa chọn độ khó từ Cơ bản đến Nâng cao để nội dung bài tập được tối ưu theo trình độ của bạn.\n3. Kết quả: AI sẽ phân tích yêu cầu và tạo ra các bài tập cụ thể (Viết hoặc Hội thoại) liên quan trực tiếp đến chủ đề đã nhập.',
  'Hệ thống tích hợp giúp bạn lưu trữ và ôn tập từ vựng hiệu quả thông qua phương pháp lặp lại ngắt quãng (Spaced Repetition):\n\n1. Thu thập từ: Trong quá trình luyện tập, chạm vào bất kỳ từ nào bạn chưa biết để xem định nghĩa và nhấn nút \'Lưu\' để thêm vào bộ sưu tập cá nhân.\n2. Cơ chế ôn tập: Ứng dụng tự động tính toán và nhắc nhở ôn tập các từ đã lưu dựa trên mức độ ghi nhớ của bạn (Sử dụng các mức: Luyện lại, Tốt, Dễ).\n3. Thư viện: Quản lý các bộ từ vựng theo chủ đề để tập trung ôn luyện vào các nhóm từ vựng cụ thể.',
  'Các công cụ giúp người dùng đánh giá quá trình học tập theo thời gian:\n\n1. Lịch (Calendar): Ghi nhận chi tiết các ngày có tham gia học tập trong tháng dưới dạng giao diện lịch trực quan.\n2. Chuỗi (Streak): Đếm số ngày liên tiếp luyện tập nhằm khuyến khích thói quen học tập hàng ngày.\n3. Huy hiệu: Các mốc thành tựu ghi nhận sự nỗ lực khi người dùng đạt được các mục tiêu học tập nhất định.',
  'Mục Ôn tập là nơi lưu trữ toàn bộ lịch sử học tập để bạn củng cố kiến thức:\n\n1. Xem lại lịch sử: Truy cập và xem lại nội dung bài làm bất cứ lúc nào, bao gồm các sửa lỗi và nhận xét chi tiết của AI.\n2. Chức năng Làm lại (Redo): Cho phép thực hiện lại các bài tập đã hoàn thành để kiểm tra mức độ cải thiện kỹ năng so với lần làm trước.',
  'Đây là phương thức học tập bổ trợ thông qua mô hình trò chơi giải đố:\n\n1. Cách chơi: Hệ thống hiển thị các chữ cái bị xáo trộn, nhiệm vụ của bạn là sắp xếp lại thành từ vựng hoàn chỉnh dựa trên định nghĩa hoặc ví dụ.\n2. Hỗ trợ Offline: Đây là tính năng duy nhất trong ứng dụng có thể sử dụng khi thiết bị không có kết nối internet.\n3. Giới hạn: Hiện tại tính năng này chỉ được thiết kế dành riêng cho ngôn ngữ học tập là Tiếng Anh.',
];
