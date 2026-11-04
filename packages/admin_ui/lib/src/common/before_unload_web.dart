import 'dart:js_interop';

/// The window's `addEventListener`.
@JS('addEventListener')
external void _addEventListener(String type, JSFunction listener);

/// The window's `removeEventListener`.
@JS('removeEventListener')
external void _removeEventListener(String type, JSFunction listener);

/// The part of a `BeforeUnloadEvent` that asks the browser to prompt.
extension type _BeforeUnloadEvent._(JSObject _) implements JSObject {
  external void preventDefault();
  external set returnValue(String value);
}

/// Asks the browser to confirm leaving: `preventDefault` for current
/// browsers, `returnValue` for older ones.
final JSFunction _prompt = ((_BeforeUnloadEvent event) {
  event
    ..preventDefault()
    ..returnValue = '';
}).toJS;

bool _on = false;

/// Turns the browser's "Leave site?" prompt on or off: while on, reloading
/// or closing the tab, or leaving for another site, asks first. The browser
/// words the prompt itself.
void setBeforeUnloadGuard(bool on) {
  if (on == _on) return;
  _on = on;
  if (on) {
    _addEventListener('beforeunload', _prompt);
  } else {
    _removeEventListener('beforeunload', _prompt);
  }
}
