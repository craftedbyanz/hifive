/// A language Hifive can teach. Saved by [code], never by index, so values
/// may be reordered or added anywhere.
enum Language {
  english('en', 'English', 'English', 'en-US'),
  korean('ko', 'Korean', '한국어', 'ko-KR'),
  chinese('zh', 'Chinese', '中文', 'zh-CN'),
  japanese('ja', 'Japanese', '日本語', 'ja-JP');

  final String code, title, nativeTitle;

  /// The text-to-speech locale for words in this language.
  final String speechLocale;
  const Language(this.code, this.title, this.nativeTitle, this.speechLocale);

  /// The language saved as [code], or null for an unknown or missing code.
  static Language? fromCode(String? code) {
    for (final l in values) {
      if (l.code == code) return l;
    }
    return null;
  }
}

/// A study course: one language and whether its lessons exist yet. A course
/// without content is listed as "Sắp ra mắt" and can't be chosen.
class Course {
  final Language language;
  final bool available;
  const Course(this.language, {required this.available});
}

/// One preset on the AI chooser's wheel and its line under "MÔ TẢ CHỦ ĐỀ".
class GeneratorPreset {
  final String title, description;
  const GeneratorPreset(this.title, this.description);
}

/// What the AI chooser offers for a course: wheel presets and the sample
/// prompts on its custom-topic editor.
class GeneratorCatalog {
  final List<GeneratorPreset> presets;
  final List<String> examples;
  const GeneratorCatalog({required this.presets, required this.examples});
}
