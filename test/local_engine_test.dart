import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mind/flutter_mind.dart';

void main() {

  // ─── LocalConfig validation ───────────────────────────────────────────────

  group('LocalConfig validation', () {

    test('throws ConfigException if modelPath is empty', () {
      expect(
        () => LocalEngine(config: LocalConfig(modelPath: '')),
        throwsA(isA<ConfigException>()),
      );
    });

    test('throws ConfigException if modelPath does not end with .gguf', () {
      expect(
        () => LocalEngine(config: LocalConfig(modelPath: '/path/to/model.bin')),
        throwsA(isA<ConfigException>()),
      );
    });

    test('accepts a valid .gguf path without throwing', () {
      expect(
        () => LocalEngine(config: LocalConfig(modelPath: '/path/to/model.gguf')),
        returnsNormally,
      );
    });
  });

  // ─── Smart defaults ───────────────────────────────────────────────────────

  group('LocalConfig smart defaults', () {

    test('default temperature is 0.7', () {
      final engine = LocalEngine(
        config: LocalConfig(modelPath: '/model.gguf'),
      );
      expect(engine.defaultConfig.temperature, 0.7);
    });

    test('default threads is 4', () {
      final engine = LocalEngine(
        config: LocalConfig(modelPath: '/model.gguf'),
      );
      expect(engine.defaultConfig.threads, 4);
    });

    test('default contextSize is 2048', () {
      final engine = LocalEngine(
        config: LocalConfig(modelPath: '/model.gguf'),
      );
      expect(engine.defaultConfig.contextSize, 2048);
    });

    test('default repeatPenalty is 1.1', () {
      final engine = LocalEngine(
        config: LocalConfig(modelPath: '/model.gguf'),
      );
      expect(engine.defaultConfig.repeatPenalty, 1.1);
    });

    test('user-supplied values are not overridden by defaults', () {
      final engine = LocalEngine(
        config: LocalConfig(
          modelPath: '/model.gguf',
          temperature: 0.3,
          threads: 2,
        ),
      );
      expect(engine.defaultConfig.temperature, 0.3);
      expect(engine.defaultConfig.threads, 2);
    });
  });

  // ─── Stop sequences ───────────────────────────────────────────────────────
  // These tests are pure Dart — no engine, no device needed.

  group('Stop sequences — delimiter format', () {

    test('joins list correctly with \\x1F delimiter', () {
      final sequences = ['<|im_end|>', '<|im_start|>'];
      final joined = sequences.join('\x1F');
      expect(joined, '<|im_end|>\x1F<|im_start|>');
    });

    test('single item has no delimiter', () {
      final sequences = ['<|im_end|>'];
      final joined = sequences.join('\x1F');
      expect(joined, '<|im_end|>');
    });

    test('empty list produces empty string', () {
      final sequences = <String>[];
      final joined = sequences.join('\x1F');
      expect(joined, '');
    });

    test('joined string splits back to original list', () {
      final original = ['<|im_end|>', '<|im_start|>', '[/INST]'];
      final joined   = original.join('\x1F');
      final restored = joined.split('\x1F');
      expect(restored, original);
    });
  });

  // ─── _buildPrompt — Dart-side history formatting ──────────────────────────
  // _buildPrompt concatenates history as plain "role: text" lines.
  // The chat template (<|im_start|> etc.) is applied later in C++.

  group('_buildPrompt', () {

    test('no history — returns just the user message', () {
      final engine = LocalEngine(
        config: LocalConfig(modelPath: '/model.gguf'),
      );
      final prompt = engine.testBuildPrompt(userMessage: 'hello');
      expect(prompt, 'hello');
    });

    test('with history — contains all messages', () {
      final engine = LocalEngine(
        config: LocalConfig(modelPath: '/model.gguf'),
      );
      final history = [
        ChatMessage.user('what is dart'),
        ChatMessage.model('dart is a language'),
      ];
      final prompt = engine.testBuildPrompt(
        userMessage: 'tell me more',
        history: history,
      );
      expect(prompt, contains('what is dart'));
      expect(prompt, contains('dart is a language'));
      expect(prompt, contains('tell me more'));
    });

    test('history is formatted as role: text lines', () {
      final engine = LocalEngine(
        config: LocalConfig(modelPath: '/model.gguf'),
      );
      final history = [
        ChatMessage.user('hi'),
        ChatMessage.model('hello'),
      ];
      final prompt = engine.testBuildPrompt(
        userMessage: 'how are you',
        history: history,
      );
      expect(prompt, contains('user: hi'));
      expect(prompt, contains('model: hello'));
      expect(prompt, contains('user: how are you'));
    });

    test('history trimmed to maxHistoryMessages', () {
      final engine = LocalEngine(
        config: LocalConfig(modelPath: '/model.gguf'),
      );
      // 10 user + 10 model = 20 messages (indices 0–19)
      final history = List.generate(20, (i) =>
        i.isEven ? ChatMessage.user('msg$i') : ChatMessage.model('msg$i'),
      );
      final prompt = engine.testBuildPrompt(
        userMessage: 'new message',
        history: history,
        maxHistoryMessages: 4,
      );
      // first 16 messages should be dropped
      expect(prompt, isNot(contains('msg0')));
      expect(prompt, isNot(contains('msg15')));
      // last 4 messages (16–19) should be present
      expect(prompt, contains('msg16'));
      expect(prompt, contains('msg17'));
      expect(prompt, contains('msg18'));
      expect(prompt, contains('msg19'));
      // current user message always included
      expect(prompt, contains('new message'));
    });

    test('empty history behaves like no history', () {
      final engine = LocalEngine(
        config: LocalConfig(modelPath: '/model.gguf'),
      );
      final prompt = engine.testBuildPrompt(
        userMessage: 'hello',
        history: [],
      );
      expect(prompt, 'hello');
    });
  });

  // ─── isAvailable ──────────────────────────────────────────────────────────

  group('isAvailable', () {

    test('returns false when model file does not exist', () async {
      final engine = LocalEngine(
        config: LocalConfig(modelPath: '/this/path/does/not/exist.gguf'),
      );
      expect(await engine.isAvailable(), false);
    });
  });
}
