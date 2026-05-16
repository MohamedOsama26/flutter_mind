import 'package:flutter/material.dart';
import 'package:flutter_mind/flutter_mind.dart';

/// flutter_mind example app
///
/// Shows the four core features:
/// 1. Basic send() — full response
/// 2. Stream()     — typing effect
/// 3. History      — multi-turn conversation
/// 4. Config       — per-call override
///
/// To run this example:
/// 1. Get a free Gemini API key at https://aistudio.google.com/apikey
/// 2. Replace 'YOUR_GEMINI_API_KEY' below with your key
/// 3. Run: flutter run

void main() {
  FlutterMind.init(
    engine: GeminiEngine(
      apiKey: 'YOUR_GEMINI_API_KEY', // 🔑 replace with your key
      config: GeminiConfig(
        model: GeminiModel.flash25,
        systemPrompt: 'You are a helpful assistant. Keep responses short.',
        temperature: 0.7,
      ),
    ),
  );
  runApp(const FlutterMindExampleApp());
}

class FlutterMindExampleApp extends StatelessWidget {
  const FlutterMindExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_mind example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ExampleScreen(),
    );
  }
}

class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  final _controller = TextEditingController();
  final _history = <ChatMessage>[];

  String _output = 'Choose an example below and type a message.';
  bool _loading = false;
  int? _lastTokenCount;

  // EXAMPLE 1 — Basic send()
  Future<void> _send() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _loading = true;
      _output = '';
      _lastTokenCount = null;
    });

    try {
      final response = await FlutterMind.send(userMessage: message);
      setState(() {
        _output = response.text;
        _lastTokenCount = response.totalTokens;
      });
    } on ValidationException catch (e) {
      setState(() => _output = '⚠️ Validation: ${e.message}');
    } on EngineException catch (e) {
      setState(() => _output = '❌ Engine error: ${e.message}\n\n${e.raw ?? ''}');
    } finally {
      setState(() => _loading = false);
      _controller.clear();
    }
  }

  // EXAMPLE 2 — stream()
  Future<void> _stream() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _loading = true;
      _output = '';
      _lastTokenCount = null;
    });

    try {
      FlutterMind.stream(userMessage: message).listen(
        (chunk) => setState(() => _output += chunk),
        onDone: () => setState(() => _loading = false),
        onError: (e) => setState(() {
          _output = '❌ Stream error: $e';
          _loading = false;
        }),
      );
    } on ValidationException catch (e) {
      setState(() {
        _output = '⚠️ Validation: ${e.message}';
        _loading = false;
      });
    }

    _controller.clear();
  }

  // EXAMPLE 3 — History (multi-turn chat)
  Future<void> _sendWithHistory() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _loading = true;
      _output = '';
      _lastTokenCount = null;
    });

    try {
      final response = await FlutterMind.send(
        userMessage: message,
        history: _history,
        maxHistoryMessages: 10,
      );

      // Add this exchange to history
      _history.add(ChatMessage.user(message));
      _history.add(ChatMessage.model(response.text));

      setState(() {
        _output = response.text;
        _lastTokenCount = response.totalTokens;
      });
    } on ValidationException catch (e) {
      setState(() => _output = '⚠️ Validation: ${e.message}');
    } on EngineException catch (e) {
      setState(() => _output = '❌ Engine error: ${e.message}\n\n${e.raw ?? ''}');
    } finally {
      setState(() => _loading = false);
      _controller.clear();
    }
  }

  void _clearHistory() {
    setState(() {
      _history.clear();
      _output = 'History cleared. Start a new conversation.';
    });
  }

  // EXAMPLE 4 — Per-call config override
  Future<void> _sendWithConfig() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _loading = true;
      _output = '';
      _lastTokenCount = null;
    });

    try {
      // Override config just for this call
      // Uses pro25 with thinking for complex reasoning
      final response = await FlutterMind.send(
        userMessage: message,
        config: GeminiConfig(
          model: GeminiModel.pro25,
          temperature: 0.1,
          thinkingLevel: ThinkingLevel.moderate,
          maxOutputTokens: 500,
        ),
      );

      setState(() {
        _output = '🧠 Thinking response:\n\n${response.text}';
        if (response.hasThinking) {
          _output += '\n\n💭 Thinking:\n${response.thinkingText}';
        }
        _lastTokenCount = response.totalTokens;
      });
    } on ValidationException catch (e) {
      setState(() => _output = '⚠️ Validation: ${e.message}');
    } on EngineException catch (e) {
      setState(() => _output = '❌ Engine error: ${e.message}\n\n${e.raw ?? ''}');
    } finally {
      setState(() => _loading = false);
      _controller.clear();
    }
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Mind'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Output area
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_loading)
                        const Center(child: CircularProgressIndicator()),
                      Text(
                        _output,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (_lastTokenCount != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '📊 Tokens used: $_lastTokenCount',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (_history.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '💬 History: ${_history.length ~/ 2} turns',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Input field
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              maxLines: 3,
              minLines: 1,
              onSubmitted: (_) => _send(),
            ),

            const SizedBox(height: 12),

            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Example 1
                ElevatedButton.icon(
                  onPressed: _loading ? null : _send,
                  icon: const Icon(Icons.send),
                  label: const Text('Send'),
                ),

                // Example 2
                ElevatedButton.icon(
                  onPressed: _loading ? null : _stream,
                  icon: const Icon(Icons.stream),
                  label: const Text('Stream'),
                ),

                // Example 3
                ElevatedButton.icon(
                  onPressed: _loading ? null : _sendWithHistory,
                  icon: const Icon(Icons.chat),
                  label: const Text('Chat'),
                ),

                // Clear history
                OutlinedButton.icon(
                  onPressed: _clearHistory,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear history'),
                ),

                // Example 4
                ElevatedButton.icon(
                  onPressed: _loading ? null : _sendWithConfig,
                  icon: const Icon(Icons.psychology),
                  label: const Text('Think'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    FlutterMind.dispose();
    super.dispose();
  }
}