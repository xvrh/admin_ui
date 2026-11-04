import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Whether the platform writes shortcuts as glyphs (⌘K) and saves with ⌘.
bool get _apple =>
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.iOS;

/// [key] with the platform's primary modifier: ⌘ on macOS and iOS, Ctrl
/// elsewhere. The activator behind ⌘K / Ctrl+K and ⌘S / Ctrl+S; show it with
/// [shortcutLabel].
SingleActivator primaryModifierActivator(
  LogicalKeyboardKey key, {
  bool shift = false,
  bool alt = false,
}) => SingleActivator(
  key,
  meta: _apple,
  control: !_apple,
  shift: shift,
  alt: alt,
);

/// [activator] as the platform writes it: glyphs with no separator on macOS
/// and iOS ('⌘K', '⇧⌘P', in the order ⌃⌥⇧⌘), elsewhere modifier names joined
/// by '+' ('Ctrl+K', 'Ctrl+Shift+P'). Modifier and key names come from
/// [MaterialLocalizations], so they follow the app's language: 'Maj' for
/// Shift in French.
String shortcutLabel(BuildContext context, SingleActivator activator) {
  final strings =
      Localizations.of<MaterialLocalizations>(context, MaterialLocalizations) ??
      const DefaultMaterialLocalizations();
  final key = _keyName(activator.trigger, strings);
  if (_apple) {
    return [
      if (activator.control) '⌃',
      if (activator.alt) '⌥',
      if (activator.shift) '⇧',
      if (activator.meta) '⌘',
      key,
    ].join();
  }
  return [
    if (activator.control) strings.keyboardKeyControl,
    if (activator.alt) strings.keyboardKeyAlt,
    if (activator.shift) strings.keyboardKeyShift,
    if (activator.meta)
      defaultTargetPlatform == TargetPlatform.windows
          ? strings.keyboardKeyMetaWindows
          : strings.keyboardKeyMeta,
    key,
  ].join('+');
}

String _keyName(LogicalKeyboardKey key, MaterialLocalizations strings) {
  if (_glyph(key) case final glyph?) return glyph;
  if (_localized(key, strings) case final name?) return name;
  // A key that types a character reads as that character.
  if (key.keyId & LogicalKeyboardKey.planeMask == 0) {
    return String.fromCharCode(key.keyId & LogicalKeyboardKey.valueMask)
        .toUpperCase();
  }
  return key.keyLabel;
}

/// The keys drawn as a symbol: arrows everywhere, and on macOS and iOS the
/// ones its menus draw as symbols.
String? _glyph(LogicalKeyboardKey key) => switch (key) {
  LogicalKeyboardKey.arrowLeft => '←', // Physical: the key's own arrow.
  LogicalKeyboardKey.arrowRight => '→', // Physical: the key's own arrow.
  LogicalKeyboardKey.arrowUp => '↑',
  LogicalKeyboardKey.arrowDown => '↓',
  LogicalKeyboardKey.enter => _apple ? '↩' : '↵',
  _ when !_apple => null,
  LogicalKeyboardKey.escape => '⎋',
  LogicalKeyboardKey.backspace => '⌫',
  LogicalKeyboardKey.delete => '⌦',
  LogicalKeyboardKey.tab => '⇥',
  LogicalKeyboardKey.pageUp => '⇞',
  LogicalKeyboardKey.pageDown => '⇟',
  LogicalKeyboardKey.home => '↖',
  LogicalKeyboardKey.end => '↘',
  _ => null,
};

String? _localized(LogicalKeyboardKey key, MaterialLocalizations strings) =>
    switch (key) {
      LogicalKeyboardKey.backspace => strings.keyboardKeyBackspace,
      LogicalKeyboardKey.delete => strings.keyboardKeyDelete,
      LogicalKeyboardKey.end => strings.keyboardKeyEnd,
      LogicalKeyboardKey.escape => strings.keyboardKeyEscape,
      LogicalKeyboardKey.home => strings.keyboardKeyHome,
      LogicalKeyboardKey.insert => strings.keyboardKeyInsert,
      LogicalKeyboardKey.pageDown => strings.keyboardKeyPageDown,
      LogicalKeyboardKey.pageUp => strings.keyboardKeyPageUp,
      LogicalKeyboardKey.space => strings.keyboardKeySpace,
      LogicalKeyboardKey.capsLock => strings.keyboardKeyCapsLock,
      LogicalKeyboardKey.printScreen => strings.keyboardKeyPrintScreen,
      LogicalKeyboardKey.scrollLock => strings.keyboardKeyScrollLock,
      LogicalKeyboardKey.numLock => strings.keyboardKeyNumLock,
      LogicalKeyboardKey.fn => strings.keyboardKeyFn,
      _ => null,
    };
