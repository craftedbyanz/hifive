import 'models.dart';

/// Local stand-in for the lesson catalog a backend will serve. Every topic has
/// its own sentences, so flows can be tested with realistic variety. None of
/// this text comes from the reference app's servers; topic titles follow the
/// names seen on the reference where they were observed.

/// One lesson inside a topic's collection.
class MockSet {
  final String title, description;
  final List<Question> questions;
  const MockSet(this.title, this.questions, {this.description = ''});
}

class MockTopic {
  final String title, description;
  final List<String> categories;
  final List<MockSet> sets;

  /// The count shown on the topic tile ("5 Qs", "14 Sets"). For writing it is
  /// catalog metadata copied from the reference, not the number of local sets.
  final int listed;
  final int icon;
  const MockTopic(
    this.title, {
    required this.description,
    required this.categories,
    required this.sets,
    this.listed = 5,
    this.icon = 0,
  });
}

/// Category chips in the order the reference lists them for grammar and
/// writing (survey 07/13).
const lessonCategories = [
  'Dành cho bạn',
  'Giao tiếp',
  'Hằng ngày',
  'Công việc',
  'Du lịch',
  'Mua sắm',
  'Ẩm thực',
  'Sức khỏe',
  'Phim ảnh',
  'Âm nhạc',
  'Trò chơi',
  'Thể thao',
  'Văn hóa',
  'Truyện ngắn',
  'Tiểu luận',
  'Email',
  'Học thuật',
  'IELTS',
  'Công nghệ',
];

/// Conversation has its own categories. The order seen on 3 November 2026;
/// survey 09 (1 November) listed the same names in another order, so the
/// reference may shuffle them.
const conversationCategories = [
  'Dành cho bạn',
  'Sân bay & Khách sạn',
  'Văn hóa & Phim ảnh',
  'Học tập & Nghiên cứu',
  'Sức khỏe',
  'Công việc',
  'Công nghệ',
  'Giao tiếp',
  'Ẩm thực',
  'Vui chơi & Giải trí',
  'Mua sắm',
];

/// Preset topics on the AI chooser with the line it shows for each, in the
/// order seen on 3 November 2026. Survey 26 (1 November) listed a different
/// 20, so the reference appears to draw them from a larger pool.
const generatorPresets = [
  ('Ngữ pháp TOEIC', 'Sửa ngữ pháp theo ngữ cảnh công việc'),
  ('Từ dẫn lời thoại', 'He whispered, she exclaimed...'),
  ('Câu mở bài', 'Những câu mở đầu cho bài luận'),
  ('Vấn đề khi du lịch', 'Trì hoãn, thất lạc hành lý và vấn đề đặt chỗ'),
  ('Câu chủ đề', 'Nêu ý chính một cách rõ ràng'),
  ('Mệnh đề quan hệ', 'Cách dùng who, which, that, where'),
  ('Quan điểm văn hóa', 'Thảo luận về truyền thống một cách tôn trọng'),
  ('Mở đầu thuyết trình', 'Bắt đầu bài nói rõ ràng và tự tin'),
  ('Lời khen', 'Đưa ra lời khen chân thành'),
  ('Câu tường thuật', 'He said, she told me...'),
  ('Giới từ', 'Cách dùng in, on, at, by'),
  ('Gọi cà phê', 'Tùy chỉnh đồ uống một cách tự nhiên'),
  ('Mua sắm trực tuyến', 'Câu hỏi về giao hàng, kích cỡ và đổi trả'),
  ('Chăm sóc khách hàng', 'Xin lỗi và giải quyết vấn đề một cách lịch sự'),
  ('Câu bị động', 'Chuyển đổi từ chủ động sang bị động'),
  ('Cảm nhận về phim', 'Nói về cảnh phim và nhân vật'),
  ('Cụm động từ', 'Get up, look after, turn on...'),
  ('Mục tiêu tập luyện', 'Nói về lịch tập và tiến độ'),
  ('Lời mời', 'Would you like to...?'),
  ('Yêu cầu lịch sự', 'Could you please...?'),
];

final generatorSuggestions = [for (final (t, _) in generatorPresets) t];

/// The chooser's line under "MÔ TẢ CHỦ ĐỀ" for a preset.
String generatorDescription(String topic) => generatorPresets
    .firstWhere((p) => p.$1 == topic, orElse: () => (topic, topic))
    .$2;

/// Sample prompts on the AI editor (survey 28).
/// The first two in the reference's order; the rest were not seen in order.
const generatorExamples = [
  "Phrasal Verbs with 'Get'",
  'Job Interview Questions',
  'Ordering food at a restaurant',
  'Past Perfect Tense practice',
  'Slang used in movies',
];

const apologyQuestions = [
  Question(
    'Tôi rất xin lỗi vì hôm nay tôi đến muộn.',
    'I am very sorry for being late today.',
    alternatives: ["I'm very sorry for being late today."],
    explanation: 'Với chủ ngữ “I”, dùng “am”. Cấu trúc “be sorry for + V-ing” diễn đạt lời xin lỗi. Giữ đúng thời gian: today = hôm nay.',
  ),
  Question(
    'Xin hãy bỏ qua cho việc tôi đến muộn sáng nay.',
    'Please excuse me for being late this morning.',
    alternatives: ['Please excuse me for arriving late this morning.'],
  ),
  Question(
    'Tôi thức dậy muộn vì chuông báo thức không kêu.',
    'I woke up late because my alarm did not go off.',
  ),
  Question(
    'Giao thông hôm nay rất tệ và di chuyển chậm.',
    'The traffic today is very heavy and slow.',
    alternatives: ['Traffic is very bad and moving slowly today.'],
  ),
  Question(
    'Tôi đã lỡ chuyến xe buýt sớm đến văn phòng.',
    'I missed the early bus to the office.',
  ),
  Question(
    'Xe của tôi bị thủng lốp trên đường đi làm.',
    'My car got a flat tire on the way to work.',
  ),
  Question(
    'Tôi xin lỗi vì sự chậm trễ vào sáng nay.',
    'I apologize for the delay this morning.',
  ),
  Question(
    'Tôi sẽ cố gắng đến đúng giờ vào sáng mai.',
    'I will try to be on time tomorrow morning.',
    alternatives: ['I will try to arrive on time tomorrow morning.'],
  ),
  Question(
    'Tôi đã phải đưa con đến trường trước khi đi làm.',
    'I had to take my child to school before going to work.',
  ),
  Question(
    'Tôi đã quên chìa khóa nhà ở nhà sáng nay.',
    'I forgot my house keys at home this morning.',
  ),
  Question(
    'Đã có một vụ tai nạn lớn trên đường chính.',
    'There was a major accident on the main road.',
  ),
  Question(
    'Chuyến tàu đã bị trễ mười phút vào sáng nay.',
    'The train was ten minutes late this morning.',
  ),
  Question(
    'Tôi xin lỗi vì đã để bạn phải chờ đợi tôi.',
    'I am sorry for keeping you waiting for me.',
  ),
  Question(
    'Tôi có một vài việc cá nhân khẩn cấp cần giải quyết.',
    'I have a few urgent personal matters to deal with.',
  ),
  Question(
    'Tôi sẽ ở lại muộn để hoàn thành công việc hôm nay.',
    'I will stay late to finish my work today.',
  ),
  Question(
    'Tôi hứa việc này sẽ không lặp lại vào ngày mai.',
    'I promise this will not happen again tomorrow.',
  ),
  Question(
    'Tôi rất xin lỗi vì sự bất tiện cá nhân này.',
    'I am very sorry for this personal inconvenience.',
  ),
  Question(
    'Tôi đã gặp một tình huống khẩn cấp nhỏ tại nhà.',
    'I had a minor emergency at home.',
  ),
  Question(
    'Cơn mưa lớn đã gây ra tình trạng tắc đường nặng.',
    'The heavy rain caused a severe traffic jam.',
  ),
  Question(
    'Cảm ơn bạn vì sự kiên nhẫn và thấu hiểu.',
    'Thank you for your patience and understanding.',
  ),
];

const paragraphQuestions = [
  Question(
    'Medellín là một thành phố đẹp ở Colombia.',
    'Medellín is a beautiful city in Colombia.',
  ),
  Question(
    'Nó có một hệ thống cáp treo nổi tiếng tên là Metrocable.',
    'It has a famous cable car system called Metrocable.',
  ),
  Question(
    'Bạn có thể đi cáp treo để ngắm nhìn thành phố.',
    'You can take the cable car to see the city.',
  ),
  Question(
    'Tầm nhìn từ cửa sổ rất tuyệt vời.',
    'The view from the window is wonderful.',
  ),
  Question(
    'Bạn thấy nhiều ngôi nhà đầy màu sắc trên những ngọn đồi.',
    'You can see many colorful houses on the hills.',
  ),
  Question(
    'Cáp treo di chuyển chậm qua những ngọn núi.',
    'The cable car moves slowly through the mountains.',
  ),
  Question(
    'Mọi người sử dụng nó để đi làm mỗi ngày.',
    'People use it to go to work every day.',
  ),
  Question(
    'Đó là một cách di chuyển rẻ và dễ dàng.',
    'It is a cheap and easy way to travel.',
  ),
  Question(
    'Chụp ảnh từ trên cao là một ý tưởng tuyệt vời.',
    'Taking photos from above is a great idea.',
  ),
  Question(
    'Du khách yêu thích chuyến đi yên tĩnh và không khí trong lành.',
    'Tourists love the quiet ride and the fresh air.',
  ),
];

/// Lines alternate between the partner (even index) and the learner.
const conversationQuestions = [
  Question(
    'Chào bạn, bạn muốn mua gì?',
    'Hello, what would you like to buy?',
    partner: true,
  ),
  Question('Tôi muốn mua táo.', 'I would like to buy some apples.'),
  Question('Táo này rất tươi.', 'These apples are very fresh.', partner: true),
  Question('Bao nhiêu tiền một ký vậy?', 'How much is a kilo?'),
  Question(
    'Ba mươi nghìn một ký.',
    'Thirty thousand dong a kilo.',
    partner: true,
  ),
  Question('Bạn có thể chọn giúp tôi không?', 'Can you help me choose?'),
  Question(
    'Được chứ, tôi sẽ chọn loại ngon nhất.',
    'Of course, I will choose the best ones.',
    partner: true,
  ),
  Question('Cảm ơn bạn rất nhiều.', 'Thank you very much.'),
];

const _grammarDescription =
    'Thực hành các mẫu câu quen thuộc trong cuộc sống và công việc.';

const grammarTopics = [
  MockTopic(
    'Đi làm muộn',
    description: _grammarDescription,
    categories: ['Công việc', 'Hằng ngày'],
    icon: 2,
    sets: [
      MockSet('Lời xin lỗi khi đi làm muộn', apologyQuestions),
      MockSet('Thông báo đến muộn do sự cố giao thông', [
        Question(
          'Đường cao tốc đang bị tắc vì sửa chữa.',
          'The highway is blocked because of repairs.',
        ),
        Question(
          'Tôi sẽ đến văn phòng muộn khoảng hai mươi phút.',
          'I will arrive at the office about twenty minutes late.',
        ),
        Question(
          'Xe buýt của tôi bị hỏng giữa đường.',
          'My bus broke down on the way.',
        ),
        Question(
          'Bạn có thể bắt đầu cuộc họp mà không có tôi.',
          'You can start the meeting without me.',
        ),
        Question(
          'Tôi sẽ gửi tin nhắn khi tôi gần đến nơi.',
          'I will send a message when I am almost there.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Nghi thức tiệc tối',
    description: 'Lời mời, lời cảm ơn và phép lịch sự quanh bàn ăn.',
    categories: ['Ẩm thực', 'Văn hóa'],
    icon: 3,
    sets: [
      MockSet('Lịch sự trong bữa tối', [
        Question(
          'Xin chào, rất vui được gặp bạn tối nay.',
          'Hello, it is nice to meet you tonight.',
          alternatives: ["Hello, it's nice to meet you tonight."],
        ),
        Question(
          'Thức ăn trông rất ngon, phải không?',
          'The food looks delicious, doesn’t it?',
          alternatives: ["The food looks delicious, doesn't it?"],
        ),
        Question(
          'Bạn có thể đưa giúp tôi lọ muối được không?',
          'Could you pass me the salt, please?',
        ),
        Question(
          'Cảm ơn bạn đã mời tôi đến bữa tối.',
          'Thank you for inviting me to dinner.',
        ),
        Question(
          'Món tráng miệng này là món tôi thích nhất.',
          'This dessert is my favorite dish.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Sắp xếp hồ sơ',
    description: 'Giao việc và sắp xếp giấy tờ trong văn phòng.',
    categories: ['Công việc', 'Email'],
    icon: 2,
    sets: [
      MockSet('Tài liệu gọn gàng', [
        Question(
          'Tôi cần sắp xếp các hồ sơ này theo ngày.',
          'I need to sort these files by date.',
        ),
        Question(
          'Bạn đã lưu bản hợp đồng ở đâu?',
          'Where did you save the contract?',
        ),
        Question(
          'Hãy đặt các hóa đơn cũ vào ngăn kéo dưới cùng.',
          'Please put the old invoices in the bottom drawer.',
        ),
        Question(
          'Tôi sẽ quét các tài liệu này vào máy tính.',
          'I will scan these documents into the computer.',
        ),
        Question(
          'Chúng ta nên đặt tên tệp rõ ràng hơn.',
          'We should name the files more clearly.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Khu vực yên tĩnh',
    description: 'Nói nhỏ nhẹ và nhờ người khác giữ yên lặng.',
    categories: ['Hằng ngày', 'Học thuật'],
    icon: 5,
    sets: [
      MockSet('Giữ yên lặng', [
        Question(
          'Đây là khu vực yên tĩnh của thư viện.',
          'This is the quiet area of the library.',
        ),
        Question(
          'Bạn có thể nói nhỏ hơn một chút không?',
          'Could you speak a little more quietly?',
        ),
        Question(
          'Vui lòng tắt chuông điện thoại của bạn.',
          'Please turn off the ringer on your phone.',
        ),
        Question(
          'Tôi cần tập trung để học cho kỳ thi.',
          'I need to focus on studying for the exam.',
        ),
        Question(
          'Chúng ta có thể nói chuyện ở bên ngoài.',
          'We can talk outside.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Thể thao mạo hiểm kịch tính',
    description: 'Kể về cảm giác hồi hộp khi thử thách bản thân.',
    categories: ['Thể thao', 'Du lịch'],
    icon: 0,
    sets: [
      MockSet('Thử thách bản thân', [
        Question(
          'Tôi đã thử nhảy dù vào mùa hè năm ngoái.',
          'I tried skydiving last summer.',
        ),
        Question(
          'Leo núi đòi hỏi rất nhiều sức bền.',
          'Rock climbing requires a lot of stamina.',
        ),
        Question(
          'Tim tôi đập rất nhanh trước khi nhảy.',
          'My heart was beating very fast before the jump.',
        ),
        Question(
          'Bạn luôn phải đội mũ bảo hiểm khi lướt ván.',
          'You must always wear a helmet when skateboarding.',
        ),
        Question(
          'Huấn luyện viên đã kiểm tra thiết bị của chúng tôi.',
          'The instructor checked our equipment.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Ngày đầu đi làm',
    description: 'Giới thiệu bản thân và làm quen với nơi làm việc mới.',
    categories: ['Công việc', 'Giao tiếp'],
    icon: 2,
    sets: [
      MockSet('Chào đồng nghiệp mới', [
        Question(
          'Hôm nay là ngày đầu tiên tôi đi làm.',
          'Today is my first day at work.',
        ),
        Question(
          'Tôi là nhân viên mới của phòng marketing.',
          'I am the new employee in the marketing department.',
        ),
        Question(
          'Bạn có thể chỉ cho tôi phòng họp ở đâu không?',
          'Can you show me where the meeting room is?',
        ),
        Question(
          'Tôi rất mong được làm việc cùng mọi người.',
          'I look forward to working with everyone.',
        ),
        Question(
          'Giờ nghỉ trưa bắt đầu lúc mấy giờ?',
          'What time does the lunch break start?',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Chia sẻ quan điểm sống',
    description: 'Diễn đạt quan điểm cá nhân một cách rõ ràng.',
    categories: ['Tiểu luận', 'IELTS'],
    icon: 1,
    sets: [
      MockSet('Điều quan trọng nhất', [
        Question(
          'Tôi tin rằng sức khỏe quan trọng hơn tiền bạc.',
          'I believe that health is more important than money.',
        ),
        Question(
          'Theo tôi, gia đình luôn đứng ở vị trí đầu tiên.',
          'In my opinion, family always comes first.',
        ),
        Question(
          'Chúng ta nên sống chậm lại một chút.',
          'We should slow down a little.',
        ),
        Question(
          'Thất bại giúp chúng ta học được nhiều điều.',
          'Failure helps us learn many things.',
        ),
        Question(
          'Tôi nghĩ mỗi người nên có một sở thích riêng.',
          'I think everyone should have their own hobby.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Chuẩn bị cặp sách',
    description: 'Từ vựng đồ dùng học tập và thói quen buổi sáng.',
    categories: ['Hằng ngày', 'Học thuật'],
    icon: 5,
    sets: [
      MockSet('Sẵn sàng đến trường', [
        Question(
          'Con đã bỏ sách toán vào cặp chưa?',
          'Have you put your math book in your bag?',
        ),
        Question(
          'Đừng quên mang theo bút chì và thước kẻ.',
          'Do not forget to bring your pencil and ruler.',
          alternatives: ["Don't forget to bring your pencil and ruler."],
        ),
        Question(
          'Bình nước của con ở trên bàn bếp.',
          'Your water bottle is on the kitchen table.',
        ),
        Question(
          'Chúng ta cần mua thêm vở mới.',
          'We need to buy more new notebooks.',
        ),
        Question(
          'Xe buýt trường học sẽ đến lúc bảy giờ.',
          'The school bus will arrive at seven o’clock.',
          alternatives: ["The school bus will arrive at seven o'clock."],
        ),
      ]),
    ],
  ),
  MockTopic(
    'Bảo tồn động vật hoang dã',
    description: 'Bàn luận về môi trường và các loài có nguy cơ tuyệt chủng.',
    categories: ['IELTS', 'Tiểu luận'],
    icon: 5,
    sets: [
      MockSet('Bảo vệ thiên nhiên', [
        Question(
          'Nhiều loài động vật đang có nguy cơ tuyệt chủng.',
          'Many animal species are in danger of extinction.',
        ),
        Question(
          'Chúng ta phải bảo vệ môi trường sống của chúng.',
          'We must protect their natural habitats.',
        ),
        Question(
          'Săn bắt trái phép là một vấn đề nghiêm trọng.',
          'Illegal hunting is a serious problem.',
        ),
        Question(
          'Các khu bảo tồn giúp động vật được an toàn.',
          'Nature reserves help animals stay safe.',
        ),
        Question(
          'Mỗi người có thể góp phần bảo vệ thiên nhiên.',
          'Everyone can help protect nature.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Nghỉ trưa cùng đồng nghiệp',
    description: 'Rủ đồng nghiệp đi ăn và trò chuyện giờ nghỉ.',
    categories: ['Ẩm thực', 'Công việc'],
    icon: 3,
    sets: [
      MockSet('Đi ăn trưa', [
        Question(
          'Bạn có muốn đi ăn trưa cùng chúng tôi không?',
          'Would you like to have lunch with us?',
        ),
        Question(
          'Có một quán phở mới gần văn phòng.',
          'There is a new pho restaurant near the office.',
        ),
        Question(
          'Hôm nay tôi mang cơm từ nhà.',
          'I brought lunch from home today.',
        ),
        Question(
          'Chúng ta nên quay lại trước một giờ.',
          'We should be back before one o’clock.',
          alternatives: ["We should be back before one o'clock."],
        ),
        Question(
          'Để tôi mời bạn ly cà phê hôm nay.',
          'Let me buy you a coffee today.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Sửa lỗi máy tính',
    description: 'Mô tả sự cố kỹ thuật và nhờ hỗ trợ.',
    categories: ['Công nghệ'],
    icon: 4,
    sets: [
      MockSet('Máy tính gặp sự cố', [
        Question(
          'Máy tính của tôi không thể khởi động.',
          'My computer cannot start.',
          alternatives: ["My computer won't start."],
        ),
        Question(
          'Màn hình bị đứng khi tôi mở ứng dụng này.',
          'The screen freezes when I open this app.',
        ),
        Question(
          'Bạn đã thử khởi động lại máy chưa?',
          'Have you tried restarting the computer?',
        ),
        Question(
          'Tôi cần cập nhật phần mềm mới nhất.',
          'I need to install the latest software update.',
        ),
        Question(
          'Hãy sao lưu dữ liệu trước khi sửa chữa.',
          'Please back up your data before the repair.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Khen ngợi đồng nghiệp',
    description: 'Ghi nhận và cảm ơn đóng góp của người khác.',
    categories: ['Giao tiếp', 'Công việc'],
    icon: 1,
    sets: [
      MockSet('Lời khen chân thành', [
        Question(
          'Bài thuyết trình của bạn thật xuất sắc.',
          'Your presentation was excellent.',
        ),
        Question(
          'Cảm ơn bạn đã giúp tôi hoàn thành dự án.',
          'Thank you for helping me finish the project.',
        ),
        Question(
          'Bạn luôn làm việc rất chăm chỉ.',
          'You always work very hard.',
        ),
        Question(
          'Ý tưởng của bạn đã giúp cả nhóm rất nhiều.',
          'Your idea helped the whole team a lot.',
        ),
        Question(
          'Tôi rất ấn tượng với báo cáo của bạn.',
          'I am very impressed with your report.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Chào hỏi cơ bản',
    description: 'Những câu chào hỏi đầu tiên khi gặp ai đó.',
    categories: ['Giao tiếp'],
    icon: 1,
    sets: [
      MockSet('Lần đầu gặp mặt', [
        Question('Xin chào, tên tôi là Lan.', 'Hello, my name is Lan.'),
        Question('Bạn đến từ đâu?', 'Where are you from?'),
        Question(
          'Rất vui được làm quen với bạn.',
          'It is nice to meet you.',
          alternatives: ["It's nice to meet you.", 'Nice to meet you.'],
        ),
        Question('Dạo này bạn thế nào?', 'How have you been lately?'),
        Question('Hẹn gặp lại bạn vào tuần sau.', 'See you again next week.'),
      ]),
    ],
  ),
  MockTopic(
    'Xin lỗi lịch sự',
    description: 'Xin lỗi đúng mực trong nhiều tình huống.',
    categories: ['Giao tiếp'],
    icon: 1,
    sets: [
      MockSet('Nói lời xin lỗi', [
        Question(
          'Tôi xin lỗi vì đã làm phiền bạn.',
          'I am sorry for bothering you.',
        ),
        Question(
          'Xin lỗi, tôi không cố ý làm vậy.',
          'Sorry, I did not mean to do that.',
          alternatives: ["Sorry, I didn't mean to do that."],
        ),
        Question(
          'Tôi sẽ sửa lỗi này ngay lập tức.',
          'I will fix this mistake right away.',
        ),
        Question(
          'Mong bạn thông cảm cho sự bất tiện này.',
          'Please understand this inconvenience.',
        ),
        Question(
          'Tôi xin lỗi vì đã trả lời tin nhắn muộn.',
          'I am sorry for replying to your message late.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Hỏi đường đi',
    description: 'Hỏi và chỉ đường khi đi du lịch.',
    categories: ['Du lịch', 'Giao tiếp'],
    icon: 0,
    sets: [
      MockSet('Tìm đường', [
        Question(
          'Xin lỗi, ga tàu ở đâu vậy?',
          'Excuse me, where is the train station?',
        ),
        Question(
          'Đi thẳng rồi rẽ trái ở ngã tư.',
          'Go straight and turn left at the intersection.',
        ),
        Question(
          'Từ đây đi bộ đến đó có xa không?',
          'Is it far to walk there from here?',
        ),
        Question(
          'Bảo tàng nằm đối diện công viên.',
          'The museum is opposite the park.',
        ),
        Question(
          'Bạn có thể chỉ cho tôi trên bản đồ không?',
          'Can you show me on the map?',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Mua thuốc ở tiệm',
    description: 'Mô tả triệu chứng và hỏi dược sĩ.',
    categories: ['Sức khỏe', 'Mua sắm'],
    icon: 3,
    sets: [
      MockSet('Tại hiệu thuốc', [
        Question(
          'Tôi bị đau đầu từ sáng nay.',
          'I have had a headache since this morning.',
        ),
        Question(
          'Bạn có thuốc ho cho trẻ em không?',
          'Do you have cough medicine for children?',
        ),
        Question(
          'Tôi nên uống thuốc này mấy lần một ngày?',
          'How many times a day should I take this medicine?',
        ),
        Question(
          'Hãy uống thuốc sau khi ăn.',
          'Take the medicine after eating.',
        ),
        Question(
          'Tôi bị dị ứng với một số loại thuốc.',
          'I am allergic to some medicines.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Lâu đài và cung điện cổ kính',
    description: 'Miêu tả công trình lịch sử khi tham quan.',
    categories: ['Du lịch', 'Văn hóa'],
    icon: 5,
    sets: [
      MockSet('Tham quan di tích', [
        Question(
          'Lâu đài này được xây dựng từ thế kỷ mười lăm.',
          'This castle was built in the fifteenth century.',
        ),
        Question(
          'Các bức tường được làm bằng đá lớn.',
          'The walls are made of large stones.',
        ),
        Question(
          'Nhà vua từng sống trong cung điện này.',
          'The king used to live in this palace.',
        ),
        Question(
          'Chúng ta không được chụp ảnh bên trong.',
          'We are not allowed to take photos inside.',
        ),
        Question(
          'Khu vườn phía sau rất rộng và đẹp.',
          'The garden at the back is very large and beautiful.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Bối cảnh phim ảnh nổi tiếng',
    description: 'Kể về bộ phim và địa điểm quay mà bạn yêu thích.',
    categories: ['Phim ảnh'],
    icon: 5,
    sets: [
      MockSet('Những thước phim đáng nhớ', [
        Question(
          'Bộ phim này được quay ở New Zealand.',
          'This movie was filmed in New Zealand.',
        ),
        Question(
          'Cảnh cuối cùng làm tôi rất xúc động.',
          'The final scene moved me a lot.',
        ),
        Question(
          'Nam diễn viên chính diễn xuất rất tự nhiên.',
          'The lead actor acted very naturally.',
        ),
        Question(
          'Tôi đã xem bộ phim này ba lần.',
          'I have watched this movie three times.',
        ),
        Question(
          'Nhạc phim vẫn còn vang trong đầu tôi.',
          'The soundtrack is still playing in my head.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Viết nhật ký',
    description: 'Ghi lại những điều xảy ra trong ngày.',
    categories: ['Truyện ngắn', 'Hằng ngày'],
    icon: 1,
    sets: [
      MockSet('Nhật ký một ngày', [
        Question(
          'Hôm nay là một ngày dài nhưng vui.',
          'Today was a long but happy day.',
        ),
        Question(
          'Buổi sáng tôi đi dạo quanh hồ.',
          'In the morning I took a walk around the lake.',
        ),
        Question(
          'Tôi đã gặp lại một người bạn cũ.',
          'I met an old friend again.',
        ),
        Question('Chúng tôi nói chuyện hàng giờ liền.', 'We talked for hours.'),
        Question(
          'Tôi muốn nhớ mãi khoảnh khắc này.',
          'I want to remember this moment forever.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Âm nhạc yêu thích',
    description: 'Nói về ca sĩ, thể loại và buổi hòa nhạc.',
    categories: ['Âm nhạc'],
    icon: 1,
    sets: [
      MockSet('Giai điệu của tôi', [
        Question(
          'Tôi thích nghe nhạc jazz vào buổi tối.',
          'I like listening to jazz in the evening.',
        ),
        Question(
          'Ca sĩ này có giọng hát rất ấm áp.',
          'This singer has a very warm voice.',
        ),
        Question(
          'Chúng tôi đã đi xem hòa nhạc tuần trước.',
          'We went to a concert last week.',
        ),
        Question(
          'Tôi đang học chơi đàn guitar.',
          'I am learning to play the guitar.',
        ),
        Question(
          'Bài hát này làm tôi nhớ về tuổi thơ.',
          'This song reminds me of my childhood.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Trò chơi cuối tuần',
    description: 'Rủ bạn bè chơi game và nói về luật chơi.',
    categories: ['Trò chơi'],
    icon: 4,
    sets: [
      MockSet('Chơi cùng bạn bè', [
        Question(
          'Cuối tuần này chúng ta chơi cờ nhé.',
          'Let’s play chess this weekend.',
          alternatives: ["Let's play chess this weekend."],
        ),
        Question(
          'Đến lượt bạn tung xúc xắc.',
          'It is your turn to roll the dice.',
          alternatives: ["It's your turn to roll the dice."],
        ),
        Question(
          'Đội của chúng tôi đã thắng trận cuối.',
          'Our team won the last match.',
        ),
        Question(
          'Bạn có biết luật của trò chơi này không?',
          'Do you know the rules of this game?',
        ),
        Question(
          'Trò chơi này cần ít nhất bốn người.',
          'This game needs at least four players.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Email xin nghỉ phép',
    description: 'Viết email trang trọng gửi quản lý.',
    categories: ['Email', 'Công việc'],
    icon: 2,
    sets: [
      MockSet('Viết email trang trọng', [
        Question(
          'Tôi viết email này để xin nghỉ phép hai ngày.',
          'I am writing this email to request two days of leave.',
        ),
        Question(
          'Tôi cần về quê vì việc gia đình.',
          'I need to go back to my hometown for family reasons.',
        ),
        Question(
          'Đồng nghiệp của tôi sẽ hỗ trợ công việc khi tôi vắng mặt.',
          'My colleague will cover my work while I am away.',
        ),
        Question(
          'Tôi sẽ kiểm tra email mỗi buổi tối.',
          'I will check my email every evening.',
        ),
        Question(
          'Rất mong nhận được phản hồi từ anh.',
          'I look forward to hearing from you.',
        ),
      ]),
    ],
  ),
];

const _writingDescription =
    'Khám phá những câu chuyện và luyện diễn đạt một cách tự nhiên.';

const writingTopics = [
  MockTopic(
    'Khám phá Nam Mỹ',
    description: _writingDescription,
    categories: ['Du lịch', 'Văn hóa'],
    listed: 14,
    icon: 0,
    sets: [MockSet('Cáp treo Medellín', paragraphQuestions)],
  ),
  MockTopic(
    'Di sản và lịch sử',
    description: 'Kể về những công trình mang dấu ấn lịch sử.',
    categories: ['Văn hóa', 'Học thuật'],
    listed: 14,
    icon: 5,
    sets: [
      MockSet('Trung tâm lịch sử Quito', [
        Question(
          'Quito là thủ đô của Ecuador.',
          'Quito is the capital of Ecuador.',
        ),
        Question(
          'Khu phố cổ có nhiều nhà thờ đẹp.',
          'The old town has many beautiful churches.',
        ),
        Question(
          'Những con đường ở đây rất hẹp và dốc.',
          'The streets here are very narrow and steep.',
        ),
        Question(
          'Nơi này đã được UNESCO công nhận.',
          'This place has been recognized by UNESCO.',
        ),
        Question(
          'Du khách thường đi bộ khám phá vào buổi sáng.',
          'Visitors often explore on foot in the morning.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Trải nghiệm giác quan',
    description: 'Miêu tả mùi vị, âm thanh và màu sắc xung quanh.',
    categories: ['Ẩm thực', 'Truyện ngắn'],
    listed: 15,
    icon: 3,
    sets: [
      MockSet('Chợ đêm Đài Bắc', [
        Question(
          'Chợ đêm luôn đông đúc vào cuối tuần.',
          'The night market is always crowded on weekends.',
        ),
        Question(
          'Mùi đồ ăn nướng lan khắp con phố.',
          'The smell of grilled food fills the street.',
        ),
        Question(
          'Người bán hàng gọi khách rất to.',
          'The vendors call out to customers very loudly.',
        ),
        Question(
          'Tôi đã thử một ly trà sữa trân châu.',
          'I tried a cup of bubble milk tea.',
        ),
        Question(
          'Những chiếc đèn lồng đỏ làm khung cảnh thêm ấm áp.',
          'The red lanterns make the scene feel warmer.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Di chuyển và giao thông',
    description: 'Viết về các phương tiện đi lại trong thành phố.',
    categories: ['Du lịch', 'Hằng ngày'],
    listed: 14,
    icon: 0,
    sets: [
      MockSet('Xe đạp ở Amsterdam', [
        Question(
          'Ở Amsterdam, xe đạp nhiều hơn ô tô.',
          'In Amsterdam, there are more bicycles than cars.',
        ),
        Question(
          'Thành phố có làn đường riêng cho xe đạp.',
          'The city has separate lanes for bicycles.',
        ),
        Question(
          'Người dân đạp xe đi làm mỗi ngày.',
          'Locals ride their bikes to work every day.',
        ),
        Question(
          'Bạn có thể thuê xe đạp gần nhà ga.',
          'You can rent a bike near the station.',
        ),
        Question(
          'Đạp xe bên các con kênh rất thú vị.',
          'Cycling along the canals is very enjoyable.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Văn hóa và truyền thống',
    description: 'Giới thiệu lễ hội và phong tục địa phương.',
    categories: ['Văn hóa'],
    listed: 14,
    icon: 5,
    sets: [
      MockSet('Đêm đèn lồng Hội An', [
        Question(
          'Hội An là một phố cổ ở miền Trung Việt Nam.',
          'Hoi An is an ancient town in central Vietnam.',
        ),
        Question(
          'Mỗi tháng có một đêm thả đèn lồng.',
          'There is a lantern night every month.',
        ),
        Question(
          'Người dân tắt đèn điện và thắp đèn lồng.',
          'People turn off the electric lights and light lanterns.',
        ),
        Question(
          'Du khách thả hoa đăng trên sông Hoài.',
          'Visitors release floating lanterns on the Hoai River.',
        ),
        Question(
          'Khung cảnh lúc đó thật lung linh.',
          'The scene at that moment is truly sparkling.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Nghệ thuật và thủ công',
    description: 'Tìm hiểu nghề truyền thống và sản phẩm thủ công.',
    categories: ['Văn hóa', 'Mua sắm'],
    listed: 14,
    icon: 5,
    sets: [
      MockSet('Làng gốm Bát Tràng', [
        Question(
          'Bát Tràng là một làng gốm nổi tiếng gần Hà Nội.',
          'Bat Trang is a famous pottery village near Hanoi.',
        ),
        Question(
          'Nghề làm gốm ở đây đã có hàng trăm năm.',
          'Pottery making here is hundreds of years old.',
        ),
        Question(
          'Du khách có thể tự nặn một chiếc bình.',
          'Visitors can make a vase by themselves.',
        ),
        Question(
          'Các sản phẩm được nung trong lò rất nóng.',
          'The products are fired in a very hot kiln.',
        ),
        Question(
          'Tôi đã mua một bộ chén làm quà.',
          'I bought a set of cups as a gift.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Phát triển sự nghiệp',
    description: 'Viết về mục tiêu và bước tiến trong công việc.',
    categories: ['Công việc', 'Email'],
    listed: 13,
    icon: 2,
    sets: [
      MockSet('Buổi phỏng vấn đầu tiên', [
        Question(
          'Tuần trước tôi có buổi phỏng vấn đầu tiên.',
          'Last week I had my first job interview.',
        ),
        Question(
          'Tôi đã chuẩn bị câu trả lời rất kỹ.',
          'I prepared my answers very carefully.',
        ),
        Question(
          'Người phỏng vấn hỏi về điểm mạnh của tôi.',
          'The interviewer asked about my strengths.',
        ),
        Question(
          'Tôi cố gắng giữ bình tĩnh và tự tin.',
          'I tried to stay calm and confident.',
        ),
        Question(
          'Hai ngày sau, công ty gọi điện cho tôi.',
          'Two days later, the company called me.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Kỹ năng xã hội tại nơi làm việc',
    description: 'Xây dựng mối quan hệ tốt với đồng nghiệp.',
    categories: ['Công việc', 'Giao tiếp'],
    listed: 15,
    icon: 1,
    sets: [
      MockSet('Làm quen đồng nghiệp mới', [
        Question(
          'Nhóm của tôi vừa có một thành viên mới.',
          'My team has just welcomed a new member.',
        ),
        Question(
          'Cô ấy đến từ văn phòng ở Đà Nẵng.',
          'She comes from the Da Nang office.',
        ),
        Question(
          'Tôi mời cô ấy uống cà phê vào giờ nghỉ.',
          'I invited her for coffee during the break.',
        ),
        Question(
          'Chúng tôi phát hiện ra có chung sở thích.',
          'We found out that we share the same hobbies.',
        ),
        Question(
          'Bây giờ chúng tôi làm việc với nhau rất ăn ý.',
          'Now we work together very well.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Quy tắc văn phòng',
    description: 'Mô tả nội quy và thói quen ở nơi làm việc.',
    categories: ['Công việc'],
    listed: 16,
    icon: 2,
    sets: [
      MockSet('Một ngày ở văn phòng', [
        Question(
          'Văn phòng của chúng tôi mở cửa lúc tám giờ.',
          'Our office opens at eight o’clock.',
          alternatives: ["Our office opens at eight o'clock."],
        ),
        Question(
          'Mọi người phải đeo thẻ nhân viên.',
          'Everyone must wear an employee badge.',
        ),
        Question(
          'Chúng tôi không ăn uống ở bàn làm việc.',
          'We do not eat at our desks.',
          alternatives: ["We don't eat at our desks."],
        ),
        Question(
          'Phòng họp phải được đặt trước.',
          'Meeting rooms must be booked in advance.',
        ),
        Question(
          'Người cuối cùng rời đi sẽ tắt đèn.',
          'The last person to leave turns off the lights.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Kỹ năng hội thoại cơ bản',
    description: 'Bắt đầu và duy trì một cuộc trò chuyện.',
    categories: ['Giao tiếp'],
    listed: 16,
    icon: 1,
    sets: [
      MockSet('Gặp gỡ hàng xóm', [
        Question(
          'Hôm qua tôi gặp người hàng xóm mới.',
          'Yesterday I met my new neighbor.',
        ),
        Question(
          'Anh ấy vừa chuyển đến từ Huế.',
          'He has just moved here from Hue.',
        ),
        Question(
          'Chúng tôi nói chuyện về khu phố.',
          'We talked about the neighborhood.',
        ),
        Question(
          'Tôi giới thiệu cho anh ấy một tiệm bánh ngon.',
          'I recommended a good bakery to him.',
        ),
        Question(
          'Anh ấy hứa sẽ mời tôi ăn tối.',
          'He promised to invite me to dinner.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Công nghệ và thiết bị',
    description: 'Viết về thiết bị và cách công nghệ thay đổi cuộc sống.',
    categories: ['Công nghệ', 'Trò chơi'],
    listed: 14,
    icon: 4,
    sets: [
      MockSet('Chiếc điện thoại mới', [
        Question(
          'Tôi vừa mua một chiếc điện thoại mới.',
          'I have just bought a new phone.',
        ),
        Question(
          'Máy ảnh của nó chụp ban đêm rất rõ.',
          'Its camera takes very clear photos at night.',
        ),
        Question('Pin có thể dùng cả ngày.', 'The battery can last all day.'),
        Question(
          'Tôi dùng nó để chơi game và học tiếng Anh.',
          'I use it to play games and learn English.',
        ),
        Question(
          'Tuy nhiên, giá của nó khá đắt.',
          'However, it is quite expensive.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Quản lý tài chính',
    description: 'Lên kế hoạch chi tiêu và tiết kiệm.',
    categories: ['Hằng ngày', 'IELTS'],
    listed: 13,
    icon: 2,
    sets: [
      MockSet('Lập kế hoạch chi tiêu', [
        Question(
          'Mỗi tháng tôi ghi lại mọi khoản chi tiêu.',
          'Every month I write down all my expenses.',
        ),
        Question(
          'Tôi tiết kiệm hai mươi phần trăm thu nhập.',
          'I save twenty percent of my income.',
        ),
        Question(
          'Tôi hạn chế mua sắm trực tuyến.',
          'I limit my online shopping.',
        ),
        Question(
          'Một quỹ khẩn cấp giúp tôi yên tâm hơn.',
          'An emergency fund helps me feel more secure.',
        ),
        Question(
          'Năm sau tôi muốn đi du lịch bằng tiền tiết kiệm.',
          'Next year I want to travel with my savings.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Sống khỏe mỗi ngày',
    description: 'Kể về thói quen tập luyện và ăn uống lành mạnh.',
    categories: ['Sức khỏe', 'Thể thao'],
    listed: 14,
    icon: 3,
    sets: [
      MockSet('Chạy bộ buổi sáng', [
        Question(
          'Tôi chạy bộ trong công viên mỗi sáng.',
          'I go running in the park every morning.',
        ),
        Question(
          'Không khí lúc sáng sớm rất trong lành.',
          'The air is very fresh in the early morning.',
        ),
        Question(
          'Sau khi chạy, tôi uống nhiều nước.',
          'After running, I drink a lot of water.',
        ),
        Question(
          'Thói quen này giúp tôi ngủ ngon hơn.',
          'This habit helps me sleep better.',
        ),
        Question(
          'Tôi cảm thấy khỏe mạnh và tràn đầy năng lượng.',
          'I feel healthy and full of energy.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Đêm nhạc ngoài trời',
    description: 'Miêu tả một buổi biểu diễn đáng nhớ.',
    categories: ['Âm nhạc', 'Phim ảnh'],
    listed: 13,
    icon: 1,
    sets: [
      MockSet('Buổi hòa nhạc trong công viên', [
        Question(
          'Tối thứ bảy có một buổi hòa nhạc trong công viên.',
          'There was a concert in the park on Saturday night.',
        ),
        Question(
          'Hàng nghìn người ngồi trên bãi cỏ.',
          'Thousands of people sat on the grass.',
        ),
        Question(
          'Ban nhạc chơi những bài hát nổi tiếng.',
          'The band played famous songs.',
        ),
        Question(
          'Mọi người cùng hát theo điệp khúc.',
          'Everyone sang along to the chorus.',
        ),
        Question(
          'Đó là một đêm tôi sẽ không bao giờ quên.',
          'It was a night I will never forget.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Bảo vệ môi trường',
    description: 'Trình bày quan điểm về các vấn đề môi trường.',
    categories: ['Tiểu luận', 'IELTS', 'Học thuật'],
    listed: 15,
    icon: 5,
    sets: [
      MockSet('Giảm rác thải nhựa', [
        Question(
          'Rác thải nhựa đang gây hại cho đại dương.',
          'Plastic waste is harming the oceans.',
        ),
        Question(
          'Nhiều loài cá nuốt phải những mảnh nhựa nhỏ.',
          'Many fish swallow small pieces of plastic.',
        ),
        Question(
          'Chúng ta nên mang túi vải khi đi chợ.',
          'We should bring cloth bags when we go shopping.',
        ),
        Question(
          'Chính phủ cần hạn chế đồ nhựa dùng một lần.',
          'The government needs to limit single-use plastics.',
        ),
        Question(
          'Những thay đổi nhỏ có thể tạo ra khác biệt lớn.',
          'Small changes can make a big difference.',
        ),
      ]),
    ],
  ),
];

const _conversationDescription =
    'Tăng khả năng dùng từ vựng linh hoạt trong giao tiếp bằng những đoạn hội thoại gần gũi.';

const conversationTopics = [
  MockTopic(
    'Mở rộng vốn từ tự nhiên',
    description: _conversationDescription,
    categories: ['Mua sắm', 'Giao tiếp'],
    listed: 1,
    icon: 6,
    sets: [MockSet('Mua táo ở chợ', conversationQuestions)],
  ),
  MockTopic(
    'Nhận phòng khách sạn',
    description: 'Đặt phòng, nhận phòng và hỏi về tiện nghi.',
    categories: ['Sân bay & Khách sạn'],
    listed: 1,
    icon: 0,
    sets: [
      MockSet('Tại quầy lễ tân', [
        Question(
          'Chào buổi tối, tôi có thể giúp gì cho bạn?',
          'Good evening, how can I help you?',
          partner: true,
        ),
        Question(
          'Tôi đã đặt một phòng đôi cho hai đêm.',
          'I booked a double room for two nights.',
        ),
        Question(
          'Vui lòng cho tôi xem hộ chiếu của bạn.',
          'May I see your passport, please?',
          partner: true,
        ),
        Question('Đây là hộ chiếu của tôi.', 'Here is my passport.'),
        Question(
          'Phòng của bạn ở tầng năm, số 502.',
          'Your room is on the fifth floor, number 502.',
          partner: true,
        ),
        Question(
          'Bữa sáng bắt đầu lúc mấy giờ?',
          'What time does breakfast start?',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Gọi món ở nhà hàng',
    description: 'Đọc thực đơn, gọi món và thanh toán.',
    categories: ['Ẩm thực'],
    listed: 1,
    icon: 3,
    sets: [
      MockSet('Bữa tối ở nhà hàng', [
        Question(
          'Bạn đã sẵn sàng gọi món chưa?',
          'Are you ready to order?',
          partner: true,
        ),
        Question(
          'Cho tôi một phần bò bít tết, cảm ơn.',
          'I would like a steak, please.',
          alternatives: ["I'd like a steak, please."],
        ),
        Question(
          'Bạn muốn thịt chín ở mức nào?',
          'How would you like it cooked?',
          partner: true,
        ),
        Question('Chín vừa, làm ơn.', 'Medium, please.'),
        Question(
          'Bạn có muốn uống gì không?',
          'Would you like something to drink?',
          partner: true,
        ),
        Question(
          'Cho tôi một ly nước cam.',
          'A glass of orange juice, please.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Hỏi bài thầy cô',
    description: 'Đặt câu hỏi và xin lời khuyên về việc học.',
    categories: ['Học tập & Nghiên cứu'],
    listed: 1,
    icon: 5,
    sets: [
      MockSet('Sau giờ học', [
        Question(
          'Em có câu hỏi nào về bài hôm nay không?',
          'Do you have any questions about today’s lesson?',
          alternatives: ["Do you have any questions about today's lesson?"],
          partner: true,
        ),
        Question(
          'Em chưa hiểu phần câu bị động.',
          'I do not understand the passive voice yet.',
          alternatives: ["I don't understand the passive voice yet."],
        ),
        Question(
          'Không sao, thầy sẽ giải thích lại.',
          'No problem, I will explain it again.',
          partner: true,
        ),
        Question(
          'Em nên làm thêm bài tập nào ạ?',
          'Which exercises should I do?',
        ),
        Question(
          'Hãy làm các bài ở trang ba mươi.',
          'Please do the exercises on page thirty.',
          partner: true,
        ),
        Question('Em cảm ơn thầy nhiều ạ.', 'Thank you very much, teacher.'),
      ]),
    ],
  ),
  MockTopic(
    'Đi khám bệnh',
    description: 'Mô tả triệu chứng và làm theo lời dặn của bác sĩ.',
    categories: ['Sức khỏe'],
    listed: 1,
    icon: 3,
    sets: [
      MockSet('Tại phòng khám', [
        Question(
          'Hôm nay bạn thấy trong người thế nào?',
          'How are you feeling today?',
          partner: true,
        ),
        Question(
          'Tôi bị sốt và đau họng.',
          'I have a fever and a sore throat.',
        ),
        Question(
          'Bạn bị như vậy bao lâu rồi?',
          'How long have you had these symptoms?',
          partner: true,
        ),
        Question('Khoảng hai ngày rồi.', 'For about two days.'),
        Question(
          'Bạn nên nghỉ ngơi và uống nhiều nước.',
          'You should rest and drink plenty of water.',
          partner: true,
        ),
        Question('Tôi sẽ làm theo lời bác sĩ.', 'I will follow your advice.'),
      ]),
    ],
  ),
  MockTopic(
    'Họp nhóm dự án',
    description: 'Cập nhật tiến độ và phân công công việc.',
    categories: ['Công việc'],
    listed: 1,
    icon: 2,
    sets: [
      MockSet('Cuộc họp buổi sáng', [
        Question(
          'Dự án của chúng ta đang tiến triển thế nào?',
          'How is our project going?',
          partner: true,
        ),
        Question(
          'Chúng tôi đã hoàn thành phần thiết kế.',
          'We have finished the design part.',
        ),
        Question(
          'Khi nào bạn có thể gửi bản báo cáo?',
          'When can you send the report?',
          partner: true,
        ),
        Question('Tôi sẽ gửi trước thứ sáu.', 'I will send it before Friday.'),
        Question(
          'Tốt lắm, có khó khăn gì không?',
          'Great, are there any problems?',
          partner: true,
        ),
        Question(
          'Chúng tôi cần thêm một người kiểm thử.',
          'We need one more tester.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Nhờ hỗ trợ kỹ thuật',
    description: 'Mô tả lỗi và làm theo hướng dẫn khắc phục.',
    categories: ['Công nghệ'],
    listed: 1,
    icon: 4,
    sets: [
      MockSet('Gọi tổng đài hỗ trợ', [
        Question(
          'Bộ phận hỗ trợ xin nghe, bạn gặp vấn đề gì?',
          'Support desk, what problem are you having?',
          partner: true,
        ),
        Question(
          'Tôi không kết nối được wifi.',
          'I cannot connect to the wifi.',
          alternatives: ["I can't connect to the wifi."],
        ),
        Question(
          'Bạn đã thử khởi động lại bộ phát chưa?',
          'Have you tried restarting the router?',
          partner: true,
        ),
        Question(
          'Tôi thử rồi nhưng vẫn không được.',
          'I tried, but it still does not work.',
        ),
        Question(
          'Tôi sẽ gửi kỹ thuật viên đến nhà bạn.',
          'I will send a technician to your home.',
          partner: true,
        ),
        Question(
          'Cảm ơn, tôi sẽ ở nhà cả chiều.',
          'Thanks, I will be home all afternoon.',
        ),
      ]),
    ],
  ),
  MockTopic(
    'Rủ bạn đi xem phim',
    description: 'Lên kế hoạch đi chơi cuối tuần cùng bạn bè.',
    categories: ['Văn hóa & Phim ảnh', 'Vui chơi & Giải trí'],
    listed: 1,
    icon: 5,
    sets: [
      MockSet('Kế hoạch cuối tuần', [
        Question(
          'Tối thứ bảy bạn có rảnh không?',
          'Are you free on Saturday night?',
          partner: true,
        ),
        Question('Có, bạn muốn đi đâu?', 'Yes, where do you want to go?'),
        Question(
          'Mình muốn đi xem bộ phim hành động mới.',
          'I want to see the new action movie.',
          partner: true,
        ),
        Question(
          'Nghe hay đấy, phim chiếu lúc mấy giờ?',
          'Sounds good, what time is the movie?',
        ),
        Question(
          'Suất chiếu lúc tám giờ tối.',
          'The show is at eight in the evening.',
          partner: true,
        ),
        Question('Hẹn gặp bạn ở rạp nhé.', 'See you at the cinema.'),
      ]),
    ],
  ),
];

List<MockTopic> mockTopics(StudyMode mode) => switch (mode) {
  StudyMode.grammar => grammarTopics,
  StudyMode.writing => writingTopics,
  StudyMode.conversation => conversationTopics,
};

List<String> mockCategories(StudyMode mode) =>
    mode == StudyMode.conversation ? conversationCategories : lessonCategories;
