import '../../domain/models/models.dart';
import '../../domain/repositories/insight_repository.dart';

class MockInsightRepository implements InsightRepository {
  final Duration latency;
  const MockInsightRepository({
    this.latency = const Duration(milliseconds: 1400),
  });

  @override
  Future<List<String>> tips(List<StudySession> month) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    return mockInsightTips;
  }
}

/// Local tips. The reference's own tips depend on the account's mistakes and
/// are not copied.
const mockInsightTips = [
  'Hãy đọc lại những câu đã sai và ghi chú lý do sai ngay bên cạnh.',
  'Khi viết, hãy kiểm tra từ mình chọn có đúng nghĩa trong ngữ cảnh của câu không.',
  'Học từ mới theo cụm cố định thay vì từng từ riêng lẻ để nhớ lâu hơn.',
  'Trước khi kiểm tra đáp án, đọc lại cả câu một lần. Nếu chưa chắc, hãy chọn cách nói đơn giản hơn.',
];
