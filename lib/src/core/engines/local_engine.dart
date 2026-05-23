import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter_mind/src/core/configs/ai_config.dart';
import 'package:flutter_mind/src/core/engines/ai_engine.dart';
import 'package:flutter_mind/src/core/exceptions/flutter_mind_exception.dart';
import 'package:flutter_mind/src/core/models/ai_model.dart';
import 'package:flutter_mind/src/core/models/chat_message.dart';
import 'package:flutter_mind/src/ai_response.dart';

// ─── FFI type definitions ───────────────────────────────────────────────────

typedef _InitParamsC = Int32 Function(
  Pointer<Utf8> modelPath,
  Pointer<Utf8> systemPrompt,
  Float temperature,
  Int32 maxTokens,
  Int32 contextSize,
  Float repeatPenalty,
  Float topP,
  Int32 topK,
  Int32 seed,
  Int32 threadCount,
  Int32 modelType,
);
typedef _InitParamsDart = int Function(
  Pointer<Utf8> modelPath,
  Pointer<Utf8> systemPrompt,
  double temperature,
  int maxTokens,
  int contextSize,
  double repeatPenalty,
  double topP,
  int topK,
  int seed,
  int threadCount,
  int modelType,
);

typedef _PromptC    = Pointer<Utf8> Function(Pointer<Utf8> prompt);
typedef _PromptDart = Pointer<Utf8> Function(Pointer<Utf8> prompt);

typedef _CleanupC    = Void Function();
typedef _CleanupDart = void Function();

// ─── Engine ─────────────────────────────────────────────────────────────────

/// AI engine for local on-device models via llama.cpp.
///
/// Runs entirely offline — no API key, no internet required.
///
/// ```dart
/// // Minimal setup
/// final engine = LocalEngine(
///   config: LocalConfig(
///     modelPath: '/data/user/0/com.app/files/models/qwen.gguf',
///   ),
/// );
///
/// // Full setup
/// final engine = LocalEngine(
///   config: LocalConfig(
///     modelPath: '/path/to/model.gguf',
///     systemPrompt: Prompt(role: 'compassionate therapist'),
///     temperature: 0.8,
///     maxOutputTokens: 500,
///     modelType: LocalModelType.qwen,
///   ),
/// );
///
/// // Send a message
/// final response = await engine.send(userMessage: 'Hello!');
/// print(response.text);
///
/// // Stream response
/// engine.stream(userMessage: 'Tell me a story').listen((chunk) {
///   print(chunk);
/// });
/// ```
///
/// Always call [dispose] when done to free model memory.
class LocalEngine implements AiEngine {
  /// Creates a LocalEngine.
  ///
  /// [config] is required — must include [LocalConfig.modelPath].
  ///
  /// The model is loaded lazily on the first [send] or [stream] call.
  LocalEngine({
    required LocalConfig config,
  })  : _defaultConfig = _resolveSmartDefaults(config) {
    validate();
  }

  final LocalConfig _defaultConfig;
  bool _initialized = false;

  // FFI function bindings
  late final _InitParamsDart _ffiInit;
  late final _PromptDart _ffiPrompt;
  late final _CleanupDart _ffiCleanup;

  // ─── AiEngine interface ───────────────────────────────────────────────────

  @override
  AiModel get model => CustomModel(_defaultConfig.modelPath.split('/').last);

  @override
  Future<AiResponse> send({
    required String userMessage,
    AiConfig? config,
    List<ChatMessage>? history,
    int maxHistoryMessages = 20,
  }) async {
    final resolved = _mergeConfig(config);
    await _ensureInitialized(resolved);

    // build full prompt with history
    final prompt = _buildPrompt(
      userMessage: userMessage,
      history: history,
      maxHistoryMessages: maxHistoryMessages,
    );

    final promptPtr = prompt.toNativeUtf8();
    final responsePtr = _ffiPrompt(promptPtr);
    final text = responsePtr.toDartString().trim();
    calloc.free(promptPtr);

    return AiResponse(
      text: text,
      model: model,
    );
  }

  @override
  Stream<String> stream({
    required String userMessage,
    AiConfig? config,
    List<ChatMessage>? history,
    int maxHistoryMessages = 20,
  }) async* {
    // local models don't support true streaming yet
    // yield full response at once
    final response = await send(
      userMessage: userMessage,
      config: config,
      history: history,
      maxHistoryMessages: maxHistoryMessages,
    );
    yield response.text;
  }

  @override
  Future<int> countTokens({
    required String userMessage,
    AiConfig? config,
  }) async {
    // rough estimate: 1 token ≈ 4 characters
    return (userMessage.length / 4).ceil();
  }

  @override
  Future<bool> isAvailable() async {
    // check model file exists on device
    return File(_defaultConfig.modelPath).existsSync();
  }

  @override
  void validate() {
    if (_defaultConfig.modelPath.isEmpty) {
      throw const ConfigException(
        'LocalEngine: modelPath cannot be empty. '
        'Provide a path to a .gguf model file.',
      );
    }
    if (!_defaultConfig.modelPath.endsWith('.gguf')) {
      throw const ConfigException(
        'LocalEngine: modelPath must point to a .gguf file. '
        'Download a quantized model from HuggingFace.',
      );
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      _ffiCleanup();
      _initialized = false;
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  /// Loads the native library and initializes the model on first call.
  Future<void> _ensureInitialized(LocalConfig config) async {
    if (_initialized) return;

    // load native library
    final lib = _loadLibrary();
    _ffiInit    = lib.lookupFunction<_InitParamsC,    _InitParamsDart>('local_model_init_params');
    _ffiPrompt  = lib.lookupFunction<_PromptC,        _PromptDart>    ('local_model_prompt');
    _ffiCleanup = lib.lookupFunction<_CleanupC,       _CleanupDart>   ('local_model_cleanup');

    // check model file exists
    if (!await isAvailable()) {
      throw EngineException(
        'LocalEngine: model file not found at "${config.modelPath}". '
        'Download the model first.',
      );
    }

    // init with config
    final modelPathPtr    = config.modelPath.toNativeUtf8();
    final systemPromptPtr = (config.systemPrompt?.build(userMessage: '') ?? '').toNativeUtf8();

    final result = _ffiInit(
      modelPathPtr,
      systemPromptPtr,
      config.temperature ?? 0.7,
      config.maxOutputTokens ?? 512,
      config.contextSize ?? 2048,
      config.repeatPenalty ?? 1.1,
      config.topP ?? 0.9,
      config.topK ?? 40,
      config.seed ?? -1,
      config.threads ?? 0,
      config.modelType.index,
    );

    calloc.free(modelPathPtr);
    calloc.free(systemPromptPtr);

    if (result != 0) {
      throw EngineException(
        'LocalEngine: failed to load model at "${config.modelPath}". '
        'Make sure the file is a valid .gguf model.',
      );
    }

    _initialized = true;
  }

  /// Loads the compiled native library for the current platform.
  DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('liblocal_model.so');
    }
    if (Platform.isIOS) {
      return DynamicLibrary.process();
    }
    if (Platform.isLinux) {
      return DynamicLibrary.open('liblocal_model.so');
    }
    if (Platform.isMacOS) {
      return DynamicLibrary.open('liblocal_model.dylib');
    }
    throw const EngineException(
      'LocalEngine: platform not supported yet.',
    );
  }

  /// Builds a conversation-aware prompt string.
  ///
  /// Includes history turns so the model remembers context.
  String _buildPrompt({
    required String userMessage,
    List<ChatMessage>? history,
    int maxHistoryMessages = 20,
  }) {
    if (history == null || history.isEmpty) return userMessage;

    // trim history to max
    final trimmed = history.length > maxHistoryMessages
        ? history.sublist(history.length - maxHistoryMessages)
        : history;

    // build conversation string
    final buffer = StringBuffer();
    for (final msg in trimmed) {
      buffer.writeln('${msg.role}: ${msg.text}');
    }
    buffer.write('user: $userMessage');

    return buffer.toString();
  }

  /// Merges a per-call config override with the stored default config.
  LocalConfig _mergeConfig(AiConfig? override) {
    if (override == null) return _defaultConfig;
    if (override is! LocalConfig) {
      throw ConfigException(
        'LocalEngine received ${override.runtimeType} — '
        'expected LocalConfig.',
      );
    }
    return _defaultConfig.copyWith(
      modelPath:      override.modelPath,
      systemPrompt:   override.systemPrompt,
      temperature:    override.temperature,
      maxOutputTokens: override.maxOutputTokens,
      stopSequences:  override.stopSequences,
      topP:           override.topP,
      topK:           override.topK,
      contextSize:    override.contextSize,
      repeatPenalty:  override.repeatPenalty,
      seed:           override.seed,
      threads:        override.threads,
      modelType:      override.modelType,
    );
  }

  /// Applies smart defaults based on config.
  static LocalConfig _resolveSmartDefaults(LocalConfig config) {
    return config.copyWith(
      temperature:   config.temperature   ?? 0.7,
      maxOutputTokens: config.maxOutputTokens ?? 512,
      contextSize:   config.contextSize   ?? 2048,
      repeatPenalty: config.repeatPenalty ?? 1.1,
      topP:          config.topP          ?? 0.9,
      topK:          config.topK          ?? 40,
      threads:       config.threads       ?? 0,
    );
  }
}