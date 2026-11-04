enum StudyMode { writing, grammar, conversation }

extension ModeLabels on StudyMode {
  String get title => ['Đoạn văn', 'Sửa câu', 'Hội thoại'][index];
  String get category => ['LUYỆN VIẾT', 'NGỮ PHÁP', 'GIAO TIẾP'][index];
  String get headline => ['Viết nên', 'Hoàn thiện', 'Thực hành'][index];
  String get accentTitle => ['câu chuyện', 'ngữ pháp', 'giao tiếp'][index];
  String get action => ['Bắt đầu', 'Sửa nhanh', 'Bắt đầu chat'][index];
}
