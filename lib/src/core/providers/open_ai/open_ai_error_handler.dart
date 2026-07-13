part of 'open_ai_engine.dart';

/// Converts [DioException]s from OpenAI's API into readable [EngineException]s.
///
/// Reads OpenAI's `error.code` field from the response body to produce
/// specific, actionable messages for the most common failure cases.
class _OpenAiErrorHandler {
  const _OpenAiErrorHandler({
    required this.timeoutSeconds,
    required this.modelValue,
  });

  final int timeoutSeconds;
  final String modelValue;

  EngineException handle(DioException e) {
    final statusCode = e.response?.statusCode;
    final raw = e.response?.data?.toString();
    final errorCode = _extractErrorCode(e.response?.data);

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return EngineException(
        'OpenAiEngine: request timed out after ${timeoutSeconds}s. '
        'Consider increasing the timeout or using a faster model.',
        statusCode: statusCode,
        raw: raw,
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return const EngineException(
        'OpenAiEngine: no internet connection or server unreachable.',
      );
    }

    return switch (statusCode) {
      400 => EngineException(
        'OpenAiEngine: bad request — ${raw ?? 'no details from server'}',
        statusCode: 400,
        raw: raw,
      ),
      401 => _handle401(errorCode, raw),
      403 => EngineException(
        'OpenAiEngine: access denied — '
        'your API key may not have permission for this model or region.',
        statusCode: 403,
        raw: raw,
      ),
      404 => EngineException(
        'OpenAiEngine: model not found — "$modelValue". '
        'Check the model name or use a CustomModel string.',
        statusCode: 404,
        raw: raw,
      ),
      429 => _handle429(errorCode, raw),
      500 => EngineException(
        'OpenAiEngine: OpenAI server error. Try again shortly.',
        statusCode: 500,
        raw: raw,
      ),
      503 => EngineException(
        'OpenAiEngine: OpenAI service overloaded or temporarily unavailable. '
        'Retry after a brief wait.',
        statusCode: 503,
        raw: raw,
      ),
      _ => EngineException(
        'OpenAiEngine: unexpected error — ${e.message}',
        statusCode: statusCode,
        raw: raw,
      ),
    };
  }

  EngineException _handle401(String? errorCode, String? raw) {
    final detail = switch (errorCode) {
      'invalid_api_key' =>
        'The API key is incorrect or has been revoked. '
        'Generate a new one at https://platform.openai.com/api-keys',
      'no_such_organization' =>
        'Your account is not part of an organization, or the org ID is wrong. '
        'Check your organization settings.',
      'ip_not_allowed' =>
        'Your IP address is not on the allowlist for this project. '
        'Update it at https://platform.openai.com/settings/organization/security/ip-allowlist',
      _ =>
        'Authentication failed. '
        'Check your API key at https://platform.openai.com/api-keys',
    };
    return EngineException('OpenAiEngine: $detail', statusCode: 401, raw: raw);
  }

  EngineException _handle429(String? errorCode, String? raw) {
    final detail = switch (errorCode) {
      'insufficient_quota' =>
        'You have exceeded your usage quota or run out of credits. '
        'Check your billing at https://platform.openai.com/settings/organization/billing',
      _ =>
        'Rate limit exceeded — too many requests. '
        'Add a RetryConfig or slow down your request rate.',
    };
    return EngineException('OpenAiEngine: $detail', statusCode: 429, raw: raw);
  }

  String? _extractErrorCode(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        return (data['error'] as Map<String, dynamic>?)?['code'] as String?;
      }
      if (data is String) {
        final json = jsonDecode(data) as Map<String, dynamic>;
        return (json['error'] as Map<String, dynamic>?)?['code'] as String?;
      }
    } catch (_) {}
    return null;
  }
}