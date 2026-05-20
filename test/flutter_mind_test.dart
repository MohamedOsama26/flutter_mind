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

    test('per-call override with no model preserves the engine init model', () {
      // Simulates: GeminiEngine init with pro25, then send with config that
      // only changes systemPrompt — model must stay pro25, not reset to flash25.
      const engineDefault = GeminiConfig(
        model: GeminiModel.pro25,
        temperature: 0.7,
      );
      const perCallOverride = GeminiConfig(
        // no model set — should inherit pro25 from engine default
        systemPrompt: Prompt(role: 'new role for this call'),
      );

      final merged = engineDefault.copyWith(
        model: perCallOverride.model,           // null — should NOT override
        systemPrompt: perCallOverride.systemPrompt,
      );

      expect(merged.model, GeminiModel.pro25,
          reason: 'model must stay as the engine init model when '
              'per-call config has no model set');
      expect(merged.systemPrompt?.role, 'new role for this call');
      expect(merged.temperature, 0.7);
    });

    test('per-call override with explicit model does change the model', () {
      const engineDefault = GeminiConfig(
        model: GeminiModel.flash25,
        temperature: 0.7,
      );
      const perCallOverride = GeminiConfig(
        model: GeminiModel.pro25,
        systemPrompt: Prompt(role: 'complex task'),
      );

      final merged = engineDefault.copyWith(
        model: perCallOverride.model,
        systemPrompt: perCallOverride.systemPrompt,
      );

      expect(merged.model, GeminiModel.pro25,
          reason: 'model must change when explicitly set in per-call config');
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

  });

  // PROMPT
  group('Prompt.build()', () {

    group('compressed output (default)', () {
      test('emits key:value role line', () {
        final result = Prompt(role: 'game assistant').build();
        expect(result, contains('role: game assistant'));
      });

      test('falls back to "assistant" when role is null', () {
        final result = Prompt().build();
        expect(result, contains('role: assistant'));
      });

      test('emits compressed tone label', () {
        final result = Prompt(tone: ResponseTone.friendly).build();
        expect(result, contains('tone: friendly'));
      });

      test('emits compressed format label', () {
        final result = Prompt(format: ResponseFormat.numberedList).build();
        expect(result, contains('format: numbered-list'));
      });

      test('emits count line for list format with maxItems', () {
        final result = Prompt(
          format: ResponseFormat.numberedList,
          maxItems: 3,
        ).build();
        expect(result, contains('count: 3'));
      });

      test('does not emit count line for non-list format', () {
        final result = Prompt(
          format: ResponseFormat.paragraph,
          maxItems: 3,
        ).build();
        expect(result, isNot(contains('count:')));
      });

      test('includes user constraints in rules line', () {
        final result = Prompt(
          constraints: ['mobile only', 'no violence'],
        ).build();
        expect(result, contains('rules: mobile only | no violence'));
      });

      test('always appends no-greetings and no-disclaimers to rules', () {
        final result = Prompt().build();
        expect(result, contains('no greetings'));
        expect(result, contains('no disclaimers'));
      });

      test('includes no: line with common filler phrases', () {
        final result = Prompt().build();
        expect(result, contains('no: '));
        expect(result, contains('Sure!'));
        expect(result, contains('As an AI'));
      });

      test('includes negativePatterns in no: line', () {
        final result = Prompt(
          negativePatterns: ['never suggest PC games'],
        ).build();
        expect(result, contains('never suggest PC games'));
      });

      test('includes optional fields when set', () {
        final result = Prompt(
          goal: 'suggest fun games',
          audience: 'teenagers',
          context: 'Egyptian market',
        ).build();
        expect(result, contains('goal: suggest fun games'));
        expect(result, contains('audience: teenagers'));
        expect(result, contains('context: Egyptian market'));
      });

      test('includes examples in Q/A format', () {
        final result = Prompt(
          examples: [
            PromptExample(input: 'fun game', output: 'Hollow Knight'),
          ],
        ).build();
        expect(result, contains('Q: fun game → A: Hollow Knight'));
      });
    });

    group('verbose output (compressed: false)', () {
      test('emits natural-language role sentence', () {
        final result = Prompt(
          role: 'game assistant',
          compressed: false,
        ).build();
        expect(result, contains('You are a game assistant.'));
      });

      test('emits tone instruction sentence', () {
        final result = Prompt(
          tone: ResponseTone.formal,
          compressed: false,
        ).build();
        expect(result, contains('Use formal, professional language.'));
      });

      test('emits format instruction sentence', () {
        final result = Prompt(
          format: ResponseFormat.bulletedList,
          compressed: false,
        ).build();
        expect(result, contains('Respond as a bulleted list'));
      });

      test('emits maxItems sentence for list format', () {
        final result = Prompt(
          format: ResponseFormat.steps,
          maxItems: 5,
          compressed: false,
        ).build();
        expect(result, contains('Return exactly 5 items.'));
      });
    });

    group('language auto-detection', () {
      test('resolves to ar for Arabic message', () {
        final result = Prompt(language: ResponseLanguage.auto)
            .build(userMessage: 'مرحبا كيف حالك اليوم');
        expect(result, contains('lang: ar'));
      });

      test('resolves to en for English message', () {
        final result = Prompt(language: ResponseLanguage.auto)
            .build(userMessage: 'Hello, how are you today?');
        expect(result, contains('lang: en'));
      });

      test('resolves to en+ar for mixed message', () {
        final result = Prompt(language: ResponseLanguage.auto)
            .build(userMessage: 'My name is محمد and I love games');
        expect(result, contains('lang: en+ar'));
      });

      test('no lang line when auto and no userMessage', () {
        final result = Prompt(language: ResponseLanguage.auto).build();
        expect(result, isNot(contains('lang:')));
      });

      test('fixed language always included without userMessage', () {
        final result = Prompt(language: ResponseLanguage.arabic).build();
        expect(result, contains('lang: ar'));
      });
    });

    group('chain of thought', () {
      test('generic directive when no steps provided', () {
        final result = Prompt(chainOfThought: true).build();
        expect(result, contains('Think step by step.'));
      });

      test('numbered steps when chainSteps provided', () {
        final result = Prompt(
          chainOfThought: true,
          chainSteps: ['identify mood', 'match genre', 'select games'],
        ).build();
        expect(result, contains('1. identify mood'));
        expect(result, contains('2. match genre'));
        expect(result, contains('3. select games'));
      });

      test('chain of thought appears before role', () {
        final result = Prompt(
          chainOfThought: true,
          role: 'game assistant',
        ).build();
        expect(
          result.indexOf('Think step by step'),
          lessThan(result.indexOf('role:')),
        );
      });

      test('no chain directive when chainOfThought is false', () {
        final result = Prompt(chainOfThought: false).build();
        expect(result, isNot(contains('Think step by step')));
      });
    });

    group('injection prevention', () {
      test('adds immutable header when preventInjection is true', () {
        final result = Prompt(preventInjection: true).build();
        expect(result, contains('IMMUTABLE SYSTEM INSTRUCTIONS'));
      });

      test('header appears before role line', () {
        final result = Prompt(
          preventInjection: true,
          role: 'game assistant',
        ).build();
        expect(
          result.indexOf('IMMUTABLE'),
          lessThan(result.indexOf('role:')),
        );
      });

      test('no header when preventInjection is false', () {
        final result = Prompt(preventInjection: false).build();
        expect(result, isNot(contains('IMMUTABLE')));
      });
    });

    group('stopSequences getter', () {
      test('returns [END] for list format with maxItems', () {
        final prompt = Prompt(
          format: ResponseFormat.numberedList,
          maxItems: 3,
        );
        expect(prompt.stopSequences, equals(['[END]']));
      });

      test('build() includes end: [END] for list with maxItems', () {
        final result = Prompt(
          format: ResponseFormat.numberedList,
          maxItems: 3,
        ).build();
        expect(result, contains('end: [END]'));
      });

      test('returns null for paragraph format', () {
        final prompt = Prompt(format: ResponseFormat.paragraph);
        expect(prompt.stopSequences, isNull);
      });

      test('returns null for list format without maxItems', () {
        final prompt = Prompt(format: ResponseFormat.numberedList);
        expect(prompt.stopSequences, isNull);
      });

      test('returns custom signal for manual mode', () {
        final prompt = Prompt(
          stopSignalMode: StopSignalMode.manual,
          customStopSignal: '[DONE]',
        );
        expect(prompt.stopSequences, equals(['[DONE]']));
      });

      test('returns null for StopSignalMode.none even with list + maxItems', () {
        final prompt = Prompt(
          format: ResponseFormat.numberedList,
          maxItems: 3,
          stopSignalMode: StopSignalMode.none,
        );
        expect(prompt.stopSequences, isNull);
      });
    });

    group('copyWith', () {
      test('changes only the specified field', () {
        const original = Prompt(role: 'game assistant', maxItems: 3);
        final copy = original.copyWith(role: 'cooking assistant');
        expect(copy.role, 'cooking assistant');
        expect(copy.maxItems, 3);
      });

      test('AiPreset.chat copyWith preserves other fields', () {
        final custom = AiPreset.chat.copyWith(role: 'Egyptian culture guide');
        expect(custom.role, 'Egyptian culture guide');
        expect(custom.tone, AiPreset.chat.tone);
        expect(custom.language, AiPreset.chat.language);
      });
    });

  });
}