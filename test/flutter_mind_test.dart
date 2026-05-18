import 'package:flutter_mind/src/core/parser/prompt_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mind/flutter_mind.dart';

void main() {
  // INPUT VALIDATOR
  group('InputValidator', () {
    const validator = InputValidator();

    test('throws ValidationException for empty message', () {
      expect(
        () => validator.validate(''),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws ValidationException for whitespace only', () {
      expect(
        () => validator.validate('   '),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws ValidationException for message exceeding maxLength', () {
      final longMessage = 'a' * 50001;
      expect(
        () => validator.validate(longMessage),
        throwsA(isA<ValidationException>()),
      );
    });

    test('does not throw for valid message', () {
      expect(() => validator.validate('hello'), returnsNormally);
    });

    test('isValid returns false for empty message', () {
      expect(validator.isValid(''), false);
    });

    test('isValid returns true for valid message', () {
      expect(validator.isValid('suggest a game'), true);
    });

    test('estimateTokens returns correct count — ceil(length / 4)', () {
      // 'hello world' = 11 chars → ceil(11/4) = 3
      expect(validator.estimateTokens('hello world'), 3);
    });

    test('estimateTokens returns 0 for empty string', () {
      final tokens = validator.estimateTokens('');
      expect(tokens, 0);
    });

    test('custom maxLength is respected', () {
      const strictValidator = InputValidator(maxLength: 10);
      expect(
        () => strictValidator.validate('this message is too long'),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  // RETRY CONFIG
  group('RetryConfig', () {
    test('default config has maxAttempts 2', () {
      const config = RetryConfig();
      expect(config.maxAttempts, 2);
    });

    test('RetryConfig.none is disabled', () {
      expect(RetryConfig.none.isDisabled, true);
    });

    test('RetryConfig.none has maxAttempts 1', () {
      expect(RetryConfig.none.maxAttempts, 1);
    });

    test('shouldRetry returns true for 429', () {
      const config = RetryConfig();
      expect(config.shouldRetry(429), true);
    });

    test('shouldRetry returns true for 500', () {
      const config = RetryConfig();
      expect(config.shouldRetry(500), true);
    });

    test('shouldRetry returns false for 401', () {
      const config = RetryConfig();
      expect(config.shouldRetry(401), false);
    });

    test('shouldRetry returns false for 400', () {
      const config = RetryConfig();
      expect(config.shouldRetry(400), false);
    });

    test('aggressive preset has maxAttempts 5', () {
      expect(RetryConfig.aggressive.maxAttempts, 5);
    });

    test('throws AssertionError for maxAttempts less than 1', () {
      expect(
        () => RetryConfig(maxAttempts: 0),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  // AI RESPONSE
  group('AiResponse', () {
    test('wasTruncated returns true for MAX_TOKENS', () {
      final response = AiResponse(
        text: 'hello',
        model: GeminiModel.flash25,
        finishReason: 'MAX_TOKENS',
      );
      expect(response.wasTruncated, true);
    });

    test('wasTruncated returns false for STOP', () {
      final response = AiResponse(
        text: 'hello',
        model: GeminiModel.flash25,
        finishReason: 'STOP',
      );
      expect(response.wasTruncated, false);
    });

    test('wasBlocked returns true for SAFETY', () {
      final response = AiResponse(
        text: '',
        model: GeminiModel.flash25,
        finishReason: 'SAFETY',
      );
      expect(response.wasBlocked, true);
    });

    test('totalTokens returns sum of input and output', () {
      final response = AiResponse(
        text: 'hello',
        model: GeminiModel.flash25,
        inputTokens: 10,
        outputTokens: 20,
      );
      expect(response.totalTokens, 30);
    });

    test('totalTokens returns null when tokens unavailable', () {
      final response = AiResponse(
        text: 'hello',
        model: GeminiModel.flash25,
      );
      expect(response.totalTokens, null);
    });

    test('hasThinking returns true when thinkingText is present', () {
      final response = AiResponse(
        text: 'answer',
        model: GeminiModel.pro25,
        thinkingText: 'let me think...',
      );
      expect(response.hasThinking, true);
    });

    test('hasThinking returns false when thinkingText is null', () {
      final response = AiResponse(
        text: 'answer',
        model: GeminiModel.flash25,
      );
      expect(response.hasThinking, false);
    });
  });

  // AI MODEL
  group('AiModel', () {
    test('GeminiModel.flash25 has correct value', () {
      expect(GeminiModel.flash25.value, 'gemini-2.5-flash');
    });

    test('GeminiModel.pro25 has correct value', () {
      expect(GeminiModel.pro25.value, 'gemini-2.5-pro');
    });

    test('CustomModel stores value correctly', () {
      const model = CustomModel('my-custom-model');
      expect(model.value, 'my-custom-model');
    });

    test('CustomModel throws AssertionError for empty string', () {
      expect(
        () => CustomModel(''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('GeminiModel.flash25 supports functionCalling', () {
      expect(
        GeminiModel.flash25.supports(Capability.functionCalling),
        true,
      );
    });

    test('GeminiModel.flash25 does not support imageGeneration', () {
      expect(
        GeminiModel.flash25.supports(Capability.imageGeneration),
        false,
      );
    });
  });

  // CHAT MESSAGE
  group('ChatMessage', () {
    test('ChatMessage.user has correct role', () {
      const message = ChatMessage.user('hello');
      expect(message.role, 'user');
    });

    test('ChatMessage.model has correct role', () {
      const message = ChatMessage.model('hi there');
      expect(message.role, 'model');
    });

    test('ChatMessage stores text correctly', () {
      const message = ChatMessage.user('suggest a game');
      expect(message.text, 'suggest a game');
    });
  });

  // FLUTTER MIND CLIENT — SINGLETON
  group('FlutterMindClient singleton', () {
    tearDown(() {
      // Reset singleton after each test
      FlutterMindClient.dispose();
    });

    test('throws StateError when accessed before init', () {
      expect(
        () => FlutterMindClient.instance,
        throwsA(isA<StateError>()),
      );
    });

    test('instance is available after init', () {
      FlutterMindClient.init(
        engine: GeminiEngine(apiKey: 'test-key'),
      );
      expect(FlutterMindClient.instance, isNotNull);
    });

    test('dispose clears the instance', () {
      FlutterMindClient.init(
        engine: GeminiEngine(apiKey: 'test-key'),
      );
      FlutterMindClient.dispose();
      expect(
        () => FlutterMindClient.instance,
        throwsA(isA<StateError>()),
      );
    });
  });

  // GEMINI CONFIG — ASSERT
  group('GeminiConfig', () {
    test('accepts GeminiModel', () {
      expect(
        () => GeminiConfig(model: GeminiModel.flash25),
        returnsNormally,
      );
    });

    test('accepts CustomModel', () {
      expect(
        () => GeminiConfig(model: CustomModel('gemini-4.0')),
        returnsNormally,
      );
    });

    test('throws AssertionError for wrong model type', () {
      expect(
        () => GeminiConfig(model: ClaudeModel.sonnet46),
        throwsA(isA<AssertionError>()),
      );
    });

    test('copyWith overrides only specified fields', () {
      const base = GeminiConfig(
        model: GeminiModel.flash25,
        temperature: 0.7,
        maxOutputTokens: 1000,
      );
      final copy = base.copyWith(temperature: 0.1);

      expect(copy.temperature, 0.1);
      expect(copy.model, GeminiModel.flash25);
      expect(copy.maxOutputTokens, 1000);
    });

    test('copyWith keeps all fields when nothing is overridden', () {
      const base = GeminiConfig(
        model: GeminiModel.flash25,
        temperature: 0.5,
      );
      final copy = base.copyWith();

      expect(copy.model, base.model);
      expect(copy.temperature, base.temperature);
    });
  });

  // THINKING BUDGET
  group('ThinkingBudget', () {
    test('ThinkingLevel.none has 0 tokens', () {
      expect(ThinkingLevel.none.tokens, 0);
    });

    test('ThinkingLevel.light has 512 tokens', () {
      expect(ThinkingLevel.light.tokens, 512);
    });

    test('ThinkingLevel.moderate has 2048 tokens', () {
      expect(ThinkingLevel.moderate.tokens, 2048);
    });

    test('ThinkingLevel.deep has 8192 tokens', () {
      expect(ThinkingLevel.deep.tokens, 8192);
    });

    test('ThinkingLevel.max has 24576 tokens', () {
      expect(ThinkingLevel.max.tokens, 24576);
    });

    test('CustomThinkingBudget stores token count correctly', () {
      const budget = CustomThinkingBudget(tokens: 1000);
      expect(budget.tokens, 1000);
    });

    test('CustomThinkingBudget throws AssertionError for negative tokens', () {
      expect(
        () => CustomThinkingBudget(tokens: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('CustomThinkingBudget allows 0 tokens', () {
      expect(
        () => CustomThinkingBudget(tokens: 0),
        returnsNormally,
      );
    });
  });

  // FLUTTER MIND — STATIC FACADE
  group('FlutterMind static facade', () {
    tearDown(() {
      FlutterMindClient.dispose();
    });

    test('send throws StateError before init', () {
      expect(
        () => FlutterMind.send(userMessage: 'hello'),
        throwsA(isA<StateError>()),
      );
    });

    test('stream throws StateError before init', () {
      expect(
        () => FlutterMind.stream(userMessage: 'hello'),
        throwsA(isA<StateError>()),
      );
    });

    test('isAvailable throws StateError before init', () {
      expect(
        () => FlutterMind.isAvailable(),
        throwsA(isA<StateError>()),
      );
    });

    test('init sets up the global instance', () {
      FlutterMind.init(engine: GeminiEngine(apiKey: 'test-key'));
      expect(FlutterMindClient.instance, isNotNull);
    });

    test('dispose resets the global instance', () {
      FlutterMind.init(engine: GeminiEngine(apiKey: 'test-key'));
      FlutterMind.dispose();
      expect(
        () => FlutterMindClient.instance,
        throwsA(isA<StateError>()),
      );
    });

    test('estimateTokens works without making API calls', () {
      FlutterMind.init(engine: GeminiEngine(apiKey: 'test-key'));
      // 'عامل إيه النهارده؟' = 19 chars → ceil(19/4) = 5
      expect(FlutterMind.estimateTokens('عامل إيه النهارده؟'), 5);
    });

    GeminiConfig(model: GeminiModel.flash25,systemPrompt: Prompt());
  });
}