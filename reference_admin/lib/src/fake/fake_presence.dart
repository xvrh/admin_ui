import 'package:admin_ui/widgets.dart' show PresenceChannel;

/// Who else has one product open in the editor. Nobody, until a scenario
/// (or the live app's demo) scripts a teammate in with [join]: enough to
/// show the kit's avatars and field ring without a realtime model.
class FakePresence implements PresenceChannel {
  static const _self = 1;
  // A peer's colour follows its client id (the kit's golden-angle hues),
  // not the theme: 16 draws in orange, apart from every theme's primary.
  static const _peer = 16;

  final _listeners = <void Function()>[];
  String? _localField;
  ({String name, String field})? _peerState;

  /// A teammate called [name] opens the product and works on [field].
  void join(String name, {required String field}) {
    _peerState = (name: name, field: field);
    _changed();
  }

  /// The teammate closes the product.
  void leave() {
    if (_peerState == null) return;
    _peerState = null;
    _changed();
  }

  @override
  int get clientId => _self;

  @override
  Map<int, Map<String, Object?>> get states => {
    _self: {
      'user': {'name': 'You'},
      'field': ?_localField,
    },
    if (_peerState case final peer?)
      _peer: {
        'user': {'name': peer.name},
        'field': peer.field,
      },
  };

  @override
  void Function() onChange(void Function() cb) {
    _listeners.add(cb);
    return () => _listeners.remove(cb);
  }

  @override
  void setLocalField(String fieldId) {
    if (_localField == fieldId) return;
    _localField = fieldId;
    _changed();
  }

  void _changed() {
    for (final listener in [..._listeners]) {
      listener();
    }
  }
}
