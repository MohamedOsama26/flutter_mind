const _kDeprecationMessage =
    'LocalEngineEvent has moved to package:flutter_mind_local. '
    'Add flutter_mind_local to your pubspec.yaml and replace this import with '
    '`package:flutter_mind_local/flutter_mind_local.dart` — '
    'it re-exports all base types (AiEngine, AiConfig, AiResponse) so no other imports are needed. '
    'This will be removed in flutter_mind v1.0.0.';

/// **Deprecated.** This class has moved to `package:flutter_mind_local`.
///
/// Migration:
/// ```yaml
/// # pubspec.yaml
/// dependencies:
///   flutter_mind_local: ^0.1.0
/// ```
/// ```dart
/// // Before
/// import 'package:flutter_mind/flutter_mind.dart';
///
/// // After — re-exports all base types, no other imports needed
/// import 'package:flutter_mind_local/flutter_mind_local.dart';
/// ```
///
/// ---
///
/// Events emitted by [LocalEngine] at each stage of the model lifecycle.
///
/// Pass an [onEvent] handler to [LocalConfig] to receive these events:
///
/// ```dart
/// LocalConfig(
///   modelPath: '/path/to/model.gguf',
///   onEvent: (event) => switch (event) {
///     ModelLoadStarted()                       => setState(() => _loading = true),
///     ModelReady(:final loadTime)              => setState(() => _ready = true),
///     ModelFailed(:final error)                => setState(() => _error = error),
///     InferenceStarted()                       => setState(() => _thinking = true),
///     InferenceCompleted(:final inferenceTime) => setState(() => _thinking = false),
///     InferenceFailed(:final error)            => setState(() => _error = error),
///     ContextCleared()                         => debugPrint('context reset'),
///     ModelDisposed()                          => null,
///   },
/// )
/// ```
///
/// The sealed keyword gives exhaustiveness checking — if a new event is added
/// in a future version, the compiler warns you that your switch is incomplete.
@Deprecated(_kDeprecationMessage)
sealed class LocalEngineEvent {}

/// Fired when model loading begins.
@Deprecated(_kDeprecationMessage)
final class ModelLoadStarted extends LocalEngineEvent {}

/// Fired when the model is fully loaded and ready to accept messages.
///
/// [loadTime] is the total time from [ModelLoadStarted] to ready.
@Deprecated(_kDeprecationMessage)
final class ModelReady extends LocalEngineEvent {
  final Duration loadTime;
  ModelReady({required this.loadTime});
}

/// Fired when the model fails to load.
///
/// [error] contains the underlying exception message.
@Deprecated(_kDeprecationMessage)
final class ModelFailed extends LocalEngineEvent {
  final String error;
  ModelFailed({required this.error});
}

/// Fired when inference begins.
@Deprecated(_kDeprecationMessage)
final class InferenceStarted extends LocalEngineEvent {
  final String userMessage;
  InferenceStarted({required this.userMessage});
}

/// Fired when inference completes successfully.
@Deprecated(_kDeprecationMessage)
final class InferenceCompleted extends LocalEngineEvent {
  final String response;
  final Duration inferenceTime;
  InferenceCompleted({required this.response, required this.inferenceTime});
}

/// Fired when inference fails.
@Deprecated(_kDeprecationMessage)
final class InferenceFailed extends LocalEngineEvent {
  final String error;
  InferenceFailed({required this.error});
}

/// Fired when the KV cache is cleared due to context overflow.
@Deprecated(_kDeprecationMessage)
final class ContextCleared extends LocalEngineEvent {}

/// Fired when [LocalEngine.dispose] is called and the model is unloaded from RAM.
@Deprecated(_kDeprecationMessage)
final class ModelDisposed extends LocalEngineEvent {}
