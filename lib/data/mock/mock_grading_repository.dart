import '../../domain/grading.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/grading_repository.dart';

class MockGradingRepository implements GradingRepository {
  final Duration latency;
  const MockGradingRepository({
    this.latency = const Duration(milliseconds: 450),
  });
  Future<void> _wait() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
  }

  @override
  Future<Grade> grade(Question question, String submitted) async {
    await _wait();
    return gradeLocally(question, submitted);
  }

  @override
  Future<List<String>> assist(Question question, String draft) async {
    await _wait();
    final typed = draft
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z' ]"), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toSet();
    final missing = question.hints
        .where((w) => !typed.contains(w.toLowerCase()))
        .toList();
    return [
      if (missing.isEmpty)
        'Bản nháp đã có đủ từ khóa chính. Kiểm tra lại thì và mạo từ trước khi gửi.'
      else
        'Thử dùng các từ: ${missing.join(', ')}.',
      'Câu gốc có ${question.answer.split(' ').length} từ. Giữ đúng ý và thời gian của câu.',
    ];
  }
}
