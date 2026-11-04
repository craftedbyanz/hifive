import '../domain/models/models.dart';
import 'lesson_repository.dart';

/// Clearly isolated demonstration records, not data read from a real account.
List<StudySession> sampleHistory() => [
  for (final mode in StudyMode.values)
    StudySession(
      id: 'sample-${mode.name}',
      lesson: Lesson(
        id: 'sample-lesson-${mode.name}',
        title: switch (mode) {
          StudyMode.grammar => 'Lời xin lỗi khi đi làm muộn',
          StudyMode.writing => 'Cáp treo Medellín',
          StudyMode.conversation => 'Mở rộng vốn từ tự nhiên',
        },
        description:
            'Bài mẫu để xem lại nội dung và làm quen với giao diện ôn tập.',
        mode: mode,
        questions: switch (mode) {
          StudyMode.grammar => apologyQuestions,
          StudyMode.writing => paragraphQuestions,
          StudyMode.conversation => conversationQuestions,
        },
      ),
      date: DateTime(2026, 10, 24),
      answers: List.generate(switch (mode) {
        StudyMode.grammar => apologyQuestions.length,
        StudyMode.writing => paragraphQuestions.length,
        StudyMode.conversation => conversationQuestions.length,
      }, (_) => const AnswerRecord('', 0, GradeKind.incorrect)),
      seconds: 0,
    ),
];
