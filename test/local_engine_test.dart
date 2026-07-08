import 'package:flutter_mind/src/core/shared/chat_message.dart';
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

  // ─── _buildPrompt ─────────────────────────────────────────────────────────

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
      final history = List.generate(20, (i) =>
        i.isEven ? ChatMessage.user('msg$i') : ChatMessage.model('msg$i'),
      );
      final prompt = engine.testBuildPrompt(
        userMessage: 'new message',
        history: history,
        maxHistoryMessages: 4,
      );
      expect(prompt, isNot(contains('msg0')));
      expect(prompt, isNot(contains('msg15')));
      expect(prompt, contains('msg16'));
      expect(prompt, contains('msg17'));
      expect(prompt, contains('msg18'));
      expect(prompt, contains('msg19'));
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

  // ─── Events — class fields ────────────────────────────────────────────────

  group('LocalEngineEvent — class fields', () {

    test('ModelReady carries loadTime', () {
      final event = ModelReady(loadTime: const Duration(seconds: 5));
      expect(event.loadTime, const Duration(seconds: 5));
    });

    test('ModelFailed carries error string', () {
      final event = ModelFailed(error: 'file not found');
      expect(event.error, 'file not found');
    });

    test('InferenceStarted carries userMessage', () {
      final event = InferenceStarted(userMessage: 'hello');
      expect(event.userMessage, 'hello');
    });

    test('InferenceCompleted carries response and inferenceTime', () {
      final event = InferenceCompleted(
        response: 'Hi there!',
        inferenceTime: const Duration(milliseconds: 800),
      );
      expect(event.response, 'Hi there!');
      expect(event.inferenceTime, const Duration(milliseconds: 800));
    });

    test('InferenceFailed carries error string', () {
      final event = InferenceFailed(error: 'crash');
      expect(event.error, 'crash');
    });
  });

  // ─── Events — switch exhaustiveness ──────────────────────────────────────

  group('LocalEngineEvent — switch exhaustiveness', () {

    test('switch covers all event types without default', () {
      // compile-time check — if a new event type is added, the compiler warns
      String label(LocalEngineEvent e) => switch (e) {
        ModelLoadStarted()   => 'load-started',
        ModelReady()         => 'ready',
        ModelFailed()        => 'load-failed',
        InferenceStarted()   => 'inference-started',
        InferenceCompleted() => 'inference-completed',
        InferenceFailed()    => 'inference-failed',
        ContextCleared()     => 'context-cleared',
        ModelDisposed()      => 'disposed',
      };

      expect(label(ModelLoadStarted()),                                             'load-started');
      expect(label(ModelReady(loadTime: Duration.zero)),                            'ready');
      expect(label(ModelFailed(error: '')),                                         'load-failed');
      expect(label(InferenceStarted(userMessage: '')),                              'inference-started');
      expect(label(InferenceCompleted(response: '', inferenceTime: Duration.zero)), 'inference-completed');
      expect(label(InferenceFailed(error: '')),                                     'inference-failed');
      expect(label(ContextCleared()),                                               'context-cleared');
      expect(label(ModelDisposed()),                                                'disposed');
    });
  });

  // ─── Events — onEvent fires ───────────────────────────────────────────────

  group('LocalEngineEvent — onEvent fires', () {

    test('ModelFailed fires when send() fails for any reason', () async {
      LocalEngineEvent? captured;
      final engine = LocalEngine(
        config: LocalConfig(
          modelPath: '/does/not/exist.gguf',
          onEvent: (e) => captured = e,
        ),
      );

      try {
        await engine.send(userMessage: 'hello');
      } catch (_) {}

      expect(captured, isA<ModelFailed>());
      expect((captured as ModelFailed).error, isNotEmpty);
    });

    test('onEvent null does not crash when send() fails', () async {
      final engine = LocalEngine(
        config: LocalConfig(modelPath: '/does/not/exist.gguf'),
      );

      await expectLater(
        engine.send(userMessage: 'hello'),
        throwsA(anything),
      );
    });
  });
}
