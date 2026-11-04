import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/core/catalog.dart';
import 'package:hifive/core/design/design.dart';
import 'package:hifive/core/state.dart';
import 'package:hifive/domain/grading.dart';
import 'package:hifive/domain/models/models.dart';

import 'helpers.dart';

void main() {
  appearanceLooks();
  test('demo records expose three saved-result modes without affecting current streak', () async {
    final state = AppState(
      repository: MemoryAppRepository(),
      feedback: SilentFeedback(),
      includeExamples: true,
      now: () => DateTime(2026, 11, 1),
    );
    await state.load();
    expect(
      state.history.map((s) => s.lesson.mode).toSet(),
      StudyMode.values.toSet(),
    );
    expect(state.streak, 0);
    expect(state.history.every((s) => s.id.startsWith('sample-')), isTrue);
  });
  test(
    'correction diff preserves shared words and marks insertions/deletions',
    () {
      final diff = diffWords(
        'I is late yesterday.',
        'I am very sorry for being late today.',
      );
      expect(
        diff.where((t) => t.change == TokenChange.unchanged).map((t) => t.text),
        ['I', 'late', '.'],
      );
      expect(
        diff.where((t) => t.change == TokenChange.removed).map((t) => t.text),
        ['is', 'yesterday'],
      );
      expect(
        diff.where((t) => t.change == TokenChange.added).map((t) => t.text),
        ['am', 'very', 'sorry', 'for', 'being', 'today'],
      );
    },
  );
  test('local grading distinguishes correct, near and unrelated answers', () {
    const q = Question('Xin lỗi', 'I am very sorry for being late today.');
    expect(
      gradeLocally(q, "I'm very sorry for being late today!").kind,
      GradeKind.correct,
    );
    expect(
      gradeLocally(q, 'I am sorry for being late today').kind,
      GradeKind.near,
    );
    expect(gradeLocally(q, 'The dog is happy').kind, GradeKind.incorrect);
  });
  test(
    'completion persists and reloads without overwriting previous results',
    () async {
      final repo = MemoryAppRepository();
      final state = AppState(repository: repo, feedback: SilentFeedback());
      await state.load();
      final lesson = sampleLesson(StudyMode.grammar, title: 'Một buổi học');
      for (var i = 0; i < 2; i++) {
        state.complete(
          StudySession(
            id: 'result-$i',
            lesson: lesson,
            date: DateTime(2026, 11, 1),
            answers: [const AnswerRecord('Answer', 1, GradeKind.correct)],
            seconds: 30,
          ),
        );
      }
      await state.flush();
      final reloaded = AppState(repository: repo, feedback: SilentFeedback());
      await reloaded.load();
      expect(reloaded.history.map((s) => s.id), ['result-1', 'result-0']);
      expect(
        reloaded.history.first.lesson.questions.first.answer,
        apologyQuestions.first.answer,
      );
      expect(reloaded.history.first.accuracy, 100);
    },
  );
  test(
    'streak handles yesterday, gaps, duplicate sessions and month boundaries',
    () {
      final state = AppState(
        repository: MemoryAppRepository(),
        feedback: SilentFeedback(),
        now: () => DateTime(2026, 11, 2),
      );
      final lesson = sampleLesson(StudyMode.grammar, title: 'Test');
      for (final date in [
        DateTime(2026, 10, 30),
        DateTime(2026, 10, 31),
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 1),
      ]) {
        state.history.add(
          StudySession(
            id: '$date-${state.history.length}',
            lesson: lesson,
            date: date,
            answers: [],
            seconds: 0,
          ),
        );
      }
      expect(state.streak, 3);
      expect(state.longestStreak, 3);
      expect(state.studyDays.length, 3);
    },
  );
  test(
    'review ratings update due dates on the clone only and survive reload',
    () async {
      final repo = MemoryAppRepository();
      final now = DateTime(2026, 11, 1, 10);
      final state = AppState(
        repository: repo,
        now: () => now,
        feedback: SilentFeedback(),
      );
      final word = state.decks.first.words.first;
      state.rate(word, 2);
      await state.flush();
      final next = AppState(repository: repo, feedback: SilentFeedback());
      await next.load();
      expect(next.decks.first.words.first.status, 'review');
      expect(
        next.decks.first.words.first.due,
        now.add(const Duration(days: 1)),
      );
    },
  );
  test('saved dictionary words deduplicate case-insensitively', () {
    final state = AppState(
      repository: MemoryAppRepository(),
      feedback: SilentFeedback(),
    );
    state.saveWord('Sorry', 'xin lỗi');
    state.saveWord('sorry', 'xin lỗi');
    expect(state.decks.singleWhere((d) => d.id == 'saved').words.length, 1);
  });
  group('mock catalog', () {
    final repo = MockLessonRepository(latency: Duration.zero);
    test('every category of every mode has runnable topics', () async {
      for (final mode in StudyMode.values) {
        final categories = await repo.categories(mode);
        expect(categories.first, 'Dành cho bạn');
        for (final category in categories) {
          final topics = await repo.topics(mode, category);
          expect(topics, isNotEmpty, reason: '${mode.name} / $category');
          for (final topic in topics) {
            final lessons = await repo.lessons(topic);
            expect(lessons, isNotEmpty);
            for (final lesson in lessons) {
              expect(
                lesson.questions.every(
                  (q) => q.answer.isNotEmpty && q.prompt.isNotEmpty,
                ),
                isTrue,
              );
            }
          }
        }
      }
    });

    test('each topic has its own sentences', () async {
      for (final mode in StudyMode.values) {
        final seen = <String>{};
        for (final category in await repo.categories(mode)) {
          for (final topic in await repo.topics(mode, category)) {
            final first = (await repo.lessons(topic)).first.questions.first;
            seen.add('${topic.id}|${first.answer}');
          }
        }
        final byTopic = {for (final e in seen) e.split('|').first: e};
        final answers = byTopic.values.map((e) => e.split('|').last).toSet();
        expect(answers.length, byTopic.length, reason: mode.name);
      }
    });

    test('conversation has its own categories', () async {
      final grammar = await repo.categories(StudyMode.grammar);
      final conversation = await repo.categories(StudyMode.conversation);
      expect(grammar, hasLength(19));
      expect(conversation, contains('Sân bay & Khách sạn'));
      expect(grammar, isNot(contains('Sân bay & Khách sạn')));
    });

    test('refresh changes the suggested topics', () async {
      final first = await repo.topics(StudyMode.grammar, 'Dành cho bạn');
      final next = await repo.topics(
        StudyMode.grammar,
        'Dành cho bạn',
        refresh: 1,
      );
      expect(first.first.title, 'Đi làm muộn');
      expect(next.map((t) => t.id), isNot(first.map((t) => t.id)));
    });

    test('the same AI topic text gives the same practice', () async {
      final a = await repo.createPractice('Gọi cà phê', StudyMode.grammar);
      final b = await repo.createPractice('Gọi cà phê', StudyMode.grammar);
      expect(a.title, 'Gọi cà phê');
      expect(a.questions, same(b.questions));
    });
  });

  test('conversation scores ignore partner lines', () {
    final lesson = sampleLesson(StudyMode.conversation);
    final session = StudySession(
      id: 'chat',
      lesson: lesson,
      date: DateTime(2026, 11, 1),
      answers: [
        for (final q in lesson.questions)
          q.partner
              ? AnswerRecord(q.answer, 1, GradeKind.correct)
              : const AnswerRecord('x', 0, GradeKind.incorrect),
      ],
      seconds: 1,
    );
    expect(session.scored, hasLength(4));
    expect(session.accuracy, 0);
    expect(session.correct, 0);
  });

  test('the partner flag survives saving', () {
    const q = Question('Chào', 'Hello', partner: true);
    expect(Question.fromJson(q.toJson()).partner, isTrue);
    expect(Question.fromJson({'prompt': 'a', 'answer': 'b'}).partner, isFalse);
  });
}

void appearanceLooks() {
  test('card looks follow the reference per appearance', () {
    expect(D.cardLook('Regular', StudyMode.grammar).$1, Palette.regularDark);
    expect(D.cardLook('Regular', StudyMode.writing).$1, Colors.white);
    expect(D.cardLook('Mono', StudyMode.grammar), (
      Palette.monoCard,
      Palette.monoInk,
    ));
    expect(D.cardLook('Minimal', StudyMode.writing).$2, D.ink);
    expect(
      D.cardLook('Glass', StudyMode.grammar).$1,
      D.modeColor(StudyMode.grammar),
    );
  });
}
