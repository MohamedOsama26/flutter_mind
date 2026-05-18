import 'package:flutter_mind/src/core/parser/response_language.dart';
import 'package:flutter_mind/src/core/parser/response_tone.dart';

/// Analyzes user messages to infer metadata before they are sent to the AI.
///
/// Used by [Prompt] to resolve [ResponseLanguage.auto] and
/// [ResponseTone] smart defaults — it reads the message and picks the right
/// values so developers don't have to.
///
/// All methods are static, pure, and free — no API calls, no side effects.
///
/// ```dart
/// MessageAnalyzer.detectLanguage('مرحبا كيف حالك');   // arabic
/// MessageAnalyzer.detectLanguage('Hello, how are you?'); // english
/// MessageAnalyzer.detectLanguage('Hi مرحبا');           // bilingual
///
/// MessageAnalyzer.isQuestion('what is Flutter?'); // true
/// MessageAnalyzer.isQuestion('ما هو فلاتر؟');    // true
///
/// MessageAnalyzer.detectTone('hi');               // casual
/// MessageAnalyzer.detectTone('Can you explain...'); // friendly
/// MessageAnalyzer.detectTone('Analyze this full document and provide...'); // formal
/// ```
class MessageAnalyzer {
  const MessageAnalyzer._();

  /// Detects the dominant script in [message] and returns the matching
  /// [ResponseLanguage].
  ///
  /// Only letters are counted — whitespace, numbers, and punctuation
  /// are ignored so they don't dilute the ratio.
  ///
  /// Returns:
  /// - [ResponseLanguage.arabic] if ≥ 60% of letters are Arabic
  /// - [ResponseLanguage.english] if < 10% of letters are Arabic
  /// - [ResponseLanguage.bilingual] when both scripts appear significantly
  ///
  /// ```dart
  /// MessageAnalyzer.detectLanguage('عامل إيه النهارده؟'); // arabic
  /// MessageAnalyzer.detectLanguage('What time is it?');    // english
  /// MessageAnalyzer.detectLanguage('My name is محمد');     // bilingual
  /// ```
  static ResponseLanguage detectLanguage(String message) {
    if (message.trim().isEmpty) return ResponseLanguage.english;

    final letters = message.runes
        .where((r) => _isArabic(r) || _isLatin(r))
        .toList();

    if (letters.isEmpty) return ResponseLanguage.english;

    final arabicCount = letters.where(_isArabic).length;
    final ratio = arabicCount / letters.length;

    if (ratio >= 0.6) return ResponseLanguage.arabic;
    if (ratio >= 0.1) return ResponseLanguage.bilingual;
    return ResponseLanguage.english;
  }

  /// Returns `true` if [message] appears to be a question.
  ///
  /// Detects both English `?` and Arabic `؟` question marks.
  ///
  /// ```dart
  /// MessageAnalyzer.isQuestion('what is Flutter?'); // true
  /// MessageAnalyzer.isQuestion('ما هو فلاتر؟');    // true
  /// MessageAnalyzer.isQuestion('tell me a story');  // false
  /// ```
  static bool isQuestion(String message) =>
      message.trimRight().endsWith('?') ||
      message.trimRight().endsWith('؟');

  /// Infers a likely [ResponseTone] from message length.
  ///
  /// Short messages are typically quick and casual — long messages signal
  /// the user wants a thorough, more formal response.
  ///
  /// | Length | Tone |
  /// |---|---|
  /// | < 30 chars | [ResponseTone.casual] — quick exchange |
  /// | 30 – 149 chars | [ResponseTone.friendly] — conversational |
  /// | 150+ chars | [ResponseTone.formal] — detailed request |
  ///
  /// This is a rough heuristic. Override it via [Prompt.tone] when
  /// you need a specific tone regardless of message length.
  ///
  /// ```dart
  /// MessageAnalyzer.detectTone('hi');                          // casual
  /// MessageAnalyzer.detectTone('Can you suggest a game?');     // friendly
  /// MessageAnalyzer.detectTone('Analyze this document and...'); // formal
  /// ```
  static ResponseTone detectTone(String message) {
    final length = message.length;
    if (length < 30) return ResponseTone.casual;
    if (length < 150) return ResponseTone.friendly;
    return ResponseTone.formal;
  }

  // Arabic Unicode block: U+0600 – U+06FF
  static bool _isArabic(int rune) => rune >= 0x0600 && rune <= 0x06FF;

  // Basic Latin letters only: A–Z (0x41–0x5A) and a–z (0x61–0x7A)
  static bool _isLatin(int rune) =>
      (rune >= 0x0041 && rune <= 0x005A) ||
      (rune >= 0x0061 && rune <= 0x007A);
}
