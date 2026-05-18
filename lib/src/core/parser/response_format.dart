/// The structure the AI should use when formatting its response.
///
/// Pass this to [PromptConfig] to tell the model exactly how to shape
/// its output. The [PromptBuilder] converts this value into a natural-language
/// instruction that is injected into the system prompt automatically.
///
/// ```dart
/// PromptConfig(
///   format: ResponseFormat.numberedList,
///   tone: ResponseTone.concise,
/// )
/// ```
enum ResponseFormat {
  /// Free-form prose — one or more paragraphs of natural text.
  ///
  /// The default format for most responses. Best for explanations,
  /// stories, opinions, and open-ended questions.
  paragraph,

  /// Items numbered 1. 2. 3. — ordered list.
  ///
  /// Best when order matters: rankings, priorities, instructions
  /// where sequence is important but steps are not technical.
  numberedList,

  /// Items with bullet points — unordered list.
  ///
  /// Best when order does not matter: features, options, pros and cons.
  bulletedList,

  /// Markdown table with headers and rows.
  ///
  /// Best for comparing multiple items across the same attributes.
  /// Example: comparing phone models across price, battery, and camera.
  table,

  /// Valid JSON object or array.
  ///
  /// Use this alongside [GeminiConfig.responseMimeType] `'application/json'`
  /// to guarantee a parseable response every time.
  json,

  /// Numbered steps — structured instructions for a task.
  ///
  /// Similar to [numberedList] but each item is an action the user
  /// should perform. Best for tutorials, how-to guides, recipes.
  steps,

  /// A single word — no punctuation, no explanation.
  ///
  /// Best for classification, yes/no decisions, or single-label tagging.
  /// Example: "positive", "negative", "dart".
  oneWord,

  /// A code block with the appropriate language tag.
  ///
  /// The model returns only the code — no surrounding explanation unless
  /// you explicitly ask for it. The language is detected from context.
  code,

  /// A single sentence — concise direct answer.
  ///
  /// Best for quick facts, definitions, or short confirmations.
  /// The model will not elaborate beyond one sentence.
  oneSentence;

  /// The natural-language instruction injected into the system prompt.
  String get instruction => switch (this) {
        ResponseFormat.paragraph    => 'Respond in clear paragraphs.',
        ResponseFormat.numberedList => 'Respond as a numbered list.',
        ResponseFormat.bulletedList => 'Respond as a bulleted list using "•".',
        ResponseFormat.table        => 'Respond as a markdown table with headers.',
        ResponseFormat.json         => 'Respond with valid JSON only. No extra text outside the JSON.',
        ResponseFormat.steps        => 'Respond as clear numbered steps.',
        ResponseFormat.oneWord      => 'Respond with one word only. No punctuation.',
        ResponseFormat.code         => 'Respond with a code block only. Use the correct language tag.',
        ResponseFormat.oneSentence  => 'Respond in one sentence only. Do not elaborate.',
      };

  /// Whether this format produces a list of items.
  ///
  /// Used to determine if [PromptBuilder.maxItems] applies.
  bool get isList => switch (this) {
        ResponseFormat.numberedList ||
        ResponseFormat.bulletedList ||
        ResponseFormat.steps        => true,
        _                           => false,
      };

  /// Short token-compressed label used in the telegraphic system prompt.
  String get compressed => switch (this) {
        ResponseFormat.paragraph    => 'paragraph',
        ResponseFormat.numberedList => 'numbered-list',
        ResponseFormat.bulletedList => 'bullet-list',
        ResponseFormat.table        => 'table',
        ResponseFormat.json         => 'json',
        ResponseFormat.steps        => 'steps',
        ResponseFormat.oneWord      => 'word',
        ResponseFormat.code         => 'code',
        ResponseFormat.oneSentence  => 'sentence',
      };
}
