/// A single input/output example for few-shot prompting.
///
/// Few-shot prompting means showing the model 2–5 real examples of what
/// you expect before asking your question. The model learns your desired
/// format, length, and style from the examples — no extra instructions needed.
///
/// **Without examples** — the model guesses what format you want:
/// ```
/// Input:  "fun game for kids"
/// Output: "There are many great games for kids! Minecraft is a popular
///          sandbox game that encourages creativity. It is suitable for
///          ages 7 and up and..."
/// ```
///
/// **With a PromptExample** — the model matches your style exactly:
/// ```
/// Input:  "fun game for kids"
/// Output: "Minecraft — creative sandbox game perfect for all ages"
/// ```
///
/// ## How many examples?
///
/// - **1 example** — establishes the format, minimal token cost
/// - **2–3 examples** — the sweet spot for most apps
/// - **5+ examples** — use only for very strict output requirements
///
/// More examples = more tokens per request. Keep each output short.
///
/// ## Usage
///
/// ```dart
/// PromptConfig(
///   examples: [
///     PromptExample(
///       input: 'fun game for kids',
///       output: 'Minecraft — creative sandbox game perfect for all ages',
///     ),
///     PromptExample(
///       input: 'relaxing game for adults',
///       output: 'Stardew Valley — peaceful farming sim, no time pressure',
///     ),
///   ],
/// )
/// ```
class PromptExample {
  const PromptExample({
    required this.input,
    required this.output,
  });

  /// The example user message — what the user might type.
  final String input;

  /// The ideal model response for this input.
  ///
  /// Keep this short and in exactly the style you want the model to follow.
  /// The model will mirror this format for every real request.
  final String output;

  @override
  String toString() => 'PromptExample(input: "$input", output: "$output")';
}
