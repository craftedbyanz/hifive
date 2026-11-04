import 'models.dart';

List<Deck> seedDecks() {
  final entries = [
    [
      'Rotate',
      'Quay hoặc xoay quanh một điểm hoặc trục trung tâm.',
      '/rəʊˈteɪt/',
      'Rotate the handle slowly.',
    ],
    [
      'Partnership',
      'Sự hợp tác, mối quan hệ đối tác.',
      '/ˈpɑːrtnərʃɪp/',
      'We have a strong partnership.',
    ],
    [
      'Claims',
      'Những lời khẳng định hoặc yêu cầu.',
      '/kleɪmz/',
      'She checks all the claims.',
    ],
    [
      'Resilient',
      'Kiên cường, có khả năng phục hồi.',
      '/rɪˈzɪliənt/',
      'The team is resilient.',
    ],
    [
      'Acquire',
      'Có được hoặc tiếp thu.',
      '/əˈkwaɪər/',
      'You acquire new skills every day.',
    ],
    [
      'Deadline',
      'Hạn chót để hoàn thành công việc.',
      '/ˈdedlaɪn/',
      'The deadline is tomorrow.',
    ],
    ['Meeting', 'Cuộc họp.', '/ˈmiːtɪŋ/', 'We have a meeting today.'],
    ['Colleague', 'Đồng nghiệp.', '/ˈkɑːliːɡ/', 'My colleague is helpful.'],
    ['Project', 'Dự án.', '/ˈprɑːdʒekt/', 'Our project is nearly finished.'],
    ['Schedule', 'Lịch trình.', '/ˈskedʒuːl/', 'Check your schedule.'],
    ['Budget', 'Ngân sách.', '/ˈbʌdʒɪt/', 'We agreed on the budget.'],
    ['Strategy', 'Chiến lược.', '/ˈstrætədʒi/', 'We need a clear strategy.'],
  ];
  List<FlashWord> words(String deck, List<List<String>> list) => [
    for (var i = 0; i < list.length; i++)
      FlashWord(
        id: '$deck-$i',
        word: list[i][0],
        meaning: list[i][1],
        phonetic: list[i][2],
        example: list[i][3],
      ),
  ];
  // Words and meanings as the reference's cooking deck shows them. Parts of
  // speech, English definitions and examples are mock data, except where the
  // reference showed them: all of "Bakes", and the labels of Guava, Flabby, Molding.
  const cooking = [
    (
      "Guava",
      "Một loại cây hoặc bụi cây nhiệt đới cho quả ngọt.",
      "/ˈɡwɑvə/",
      "Guava juice is popular in the summer.",
      "NOUN",
      "A tropical fruit with sweet pink or white flesh.",
    ),
    (
      "Blitz",
      "Một cuộc tấn công bất ngờ, áp đảo, đặc biệt là cuộc không kích.",
      "/blɪts/",
      "The team launched a marketing blitz.",
      "NOUN",
      "A sudden, overwhelming attack, especially from the air.",
    ),
    (
      "Melon",
      "Một loại trái cây lớn, tròn với vỏ cứng và thịt ngọt, mọng nước, như dưa hấu hoặc dưa lưới.",
      "/ˈmɛlən/",
      "She cut the melon into thin slices.",
      "NOUN",
      "A large round fruit with a hard rind and sweet flesh.",
    ),
    (
      "Flabby",
      "Mềm, lỏng lẻo và không săn chắc, thường dùng để chỉ các bộ phận cơ thể thiếu cơ bắp.",
      "/ˈflæb.i/",
      "He wanted to tone his flabby arms.",
      "ADJECTIVE",
      "Soft and loose, often describing parts of the body.",
    ),
    (
      "Watermelons",
      "Một loại cây thân leo lớn, tròn hoặc bầu dục màu xanh lá cây, cho ra quả ngọt và mọng nước.",
      "",
      "We bought two watermelons at the market.",
      "NOUN",
      "Large green fruits with sweet, juicy red flesh.",
    ),
    (
      "Bakes",
      "Nấu thức ăn bằng nhiệt khô, đặc biệt là trong lò nướng (ngôi thứ ba số ít hiện tại).",
      "/beɪks/",
      "My grandmother bakes delicious apple pies.",
      "NOUN",
      "To cook food using dry heat, especially in an oven (third person singular present).",
    ),
    (
      "Waffles",
      "Số nhiều của 'waffle': những chiếc bánh dẹt, giòn với hoa văn hình vuông, thường ăn kèm với si-rô hoặc trái cây.",
      "",
      "We had waffles with honey for breakfast.",
      "NOUN",
      "Crisp flat cakes with a pattern of squares.",
    ),
    (
      "Caramelized",
      "Biến đường thành caramel bằng cách đun nóng, thường cho đến khi nó chuyển màu nâu và ngọt.",
      "",
      "The chef caramelized the onions slowly.",
      "VERB",
      "Turned sugar into caramel by heating it until brown.",
    ),
    (
      "Sweetener",
      "Chất tạo ngọt (chất dùng để làm ngọt thức ăn hoặc đồ uống, đặc biệt là chất thay thế đường nhân tạo).",
      "",
      "He adds a sweetener to his coffee.",
      "NOUN",
      "A substance used to make food or drinks sweet.",
    ),
    (
      "Molding",
      "Tạo hình một chất liệu mềm thành một dạng nhất định.",
      "/ˈmoʊldɪŋ/",
      "She is molding the dough into small balls.",
      "VERB",
      "Shaping a soft material into a particular form.",
    ),
  ];
  return [
    Deck(
      id: 'business',
      title: 'Công việc & Kinh doanh',
      description: 'Từ vựng về công việc, kinh doanh',
      words: words('business', entries),
    ),
    Deck(
      id: 'work',
      title: 'Công việc',
      description: 'Từ vựng về công việc',
      words: words('work', entries.sublist(5)),
    ),
    Deck(
      id: 'cooking',
      title: 'Nấu ăn & Ẩm thực',
      description: 'Từ vựng về nấu ăn, ẩm thực',
      words: [
        for (final (i, c) in cooking.indexed)
          FlashWord(
            id: 'cooking-$i',
            word: c.$1,
            meaning: c.$2,
            phonetic: c.$3,
            example: c.$4,
            partOfSpeech: c.$5,
            definition: c.$6,
          ),
      ],
      icon: 1,
    ),
  ];
}
