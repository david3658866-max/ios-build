import 'dart:async';

/// HTTP 发送串行队列。对齐 uniapp chat-box `reqQueue` / `processReqQueue`。
class MessageSendQueue {
  Future<void>? _tail;

  Future<T> run<T>(Future<T> Function() fn) {
    final completer = Completer<T>();
    _tail = (_tail ?? Future<void>.value()).then((_) async {
      try {
        completer.complete(await fn());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }
}
