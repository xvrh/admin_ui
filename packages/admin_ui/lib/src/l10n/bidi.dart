/// [text] set apart from the text around it and laid out in the direction
/// of its own first letter: a first-strong isolate (U+2068 … U+2069), what
/// `dir="auto"` does on the web.
///
/// Right-to-left text carries a slash, a dot or an ellipsis at either end
/// of left-to-right data over to the other side, so the path "/contact"
/// reads "contact/" in an Arabic admin. Isolated, a path, a URL, an email or
/// an SKU keeps its own order there, and an Arabic title keeps its order in
/// a left-to-right admin. Wrap data shown as a whole label, where the kit
/// cannot know its language: a link's target, a record's subtitle.
String bidiIsolate(String text) => '\u2068$text\u2069';
