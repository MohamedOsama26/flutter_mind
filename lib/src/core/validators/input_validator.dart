import 'package:flutter_mind/src/core/exceptions/flutter_mind_exception.dart';

/// Validates user input before sending to any AI engine.
///
/// Called automatically by [FlutterMindClient] before every request.
/// Catches invalid input early — before any API call is made,
/// so no tokens are wasted on bad requests.
class InputValidator {
  const InputValidator({
    this.maxLength = 50000,
    this.minLength = 1,
  });

  /// Maximum allowed message length in characters.
  ///
  /// Default: 50,000 characters (~12,500 tokens)
  /// Override if your app needs stricter limits.
  final int maxLength;

  /// Minimum allowed message length in characters.
  ///
  /// Default: 1 — empty messages are never allowed.
  final int minLength;

  // VALIDATION
  /// Validates [message] before sending to the engine.
  ///
  /// Throws [ValidationException] if:
  /// - Message is empty or only whitespace
  /// - Message exceeds [maxLength] characters
  ///
  /// Does nothing if message is valid — call proceeds normally.
  void validate(String message) {
    final trimmed = message.trim();

    if (trimmed.isEmpty) {
      throw const ValidationException(
        'Message cannot be empty or whitespace only.',
      );
    }

    if (trimmed.length < minLength) {
      throw ValidationException(
        'Message too short — minimum $minLength character(s) required.',
      );
    }

    if (trimmed.length > maxLength) {
      throw ValidationException(
        'Message too long — ${trimmed.length} characters exceeds '
        'the $maxLength character limit (~${maxLength ~/ 4} tokens). '
        'Consider splitting into smaller requests.',
      );
    }
  }

  // HELPERS
  /// Returns true if [message] is valid without throwing.
  ///
  /// Use when you want to check validity without try/catch:
  /// ```dart
  /// if (validator.isValid(userInput)) {
  ///   // safe to send
  /// }
  /// ```
  bool isValid(String message) {
    try {
      validate(message);
      return true;
    } on ValidationException {
      return false;
    }
  }

  /// Returns a rough estimated token count for [message].
  ///
  /// Uses the rule of thumb: **1 token ≈ 4 characters** in English.
  /// Characters are divided by 4 and rounded up so the estimate never
  /// undercounts (e.g. 5 chars → 5÷4 = 1.25 → 2 tokens).
  ///
  /// **Arabic text tokenizes differently** — Arabic characters are often
  /// 1–2 characters per token, so the real token count can be 2–3× higher
  /// than this estimate. If your app sends Arabic messages, always use
  /// [AiEngine.countTokens] for an accurate count before sending long text.
  ///
  /// For an accurate count in any language, use [AiEngine.countTokens] —
  /// it calls the provider's real API and is always free.
  ///
  /// ```dart
  /// // English: "How are you today?" — estimate is close to reality
  /// validator.estimateTokens('How are you today?'); // → 5
  ///
  /// // Arabic: same meaning "عامل إيه النهارده؟" — estimate is too low
  /// validator.estimateTokens('عامل إيه النهارده؟'); // → 5 (real may be 10–14)
  ///
  /// // For accuracy use countTokens — always free
  /// final accurate = await gemini.countTokens(userMessage: 'عامل إيه النهارده؟');
  /// ```
  int estimateTokens(String message) => (message.length / 4).ceil();
}