import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_constants.dart';
import '../enums/cmd_type.dart';
import 'ws_event.dart';

class WsManager {
  WsManager();

  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  int _connId = 0;

  WsStatus _status = WsStatus.disconnected;
  WsStatus get status => _status;
  bool get isConnected => _status == WsStatus.connected;

  String? _wsUrl;
  String? _token;
  String? _devId;

  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  DateTime _lastConnectTime = DateTime.fromMillisecondsSinceEpoch(0);

  bool _autoReconnect = true;

  final StreamController<WsEvent> _eventCtrl =
      StreamController<WsEvent>.broadcast();
  final StreamController<WsStatus> _statusCtrl =
      StreamController<WsStatus>.broadcast();

  Stream<WsEvent> get events => _eventCtrl.stream;

  Stream<WsStatus> get statusStream => _statusCtrl.stream;

  void Function()? onLoginSuccess;

  void _setStatus(WsStatus s) {
    if (_status == s) return;
    _status = s;
    _statusCtrl.add(s);
  }

  void connect({
    required String wsUrl,
    required String token,
    required String devId,
  }) {
    _wsUrl = wsUrl;
    _token = token;
    _devId = devId;
    _autoReconnect = true;

    if (_status == WsStatus.connecting ||
        _status == WsStatus.authing ||
        _status == WsStatus.connected) {
      return;
    }

    final myConnId = ++_connId;
    _lastConnectTime = DateTime.now();
    _setStatus(WsStatus.connecting);
    

    try {
      final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel = channel;

      channel.ready.then((_) {
        if (!_isActive(myConnId)) return;
        
        _setStatus(WsStatus.authing);
        // 杩炰笂绔嬪嵆鍙戠櫥褰曞寘 cmd0 {accessToken, devId}
        _send({
          'cmd': CmdType.login,
          'data': {'accessToken': _token, 'devId': _devId},
        });
      }).catchError((Object e) {
        if (!_isActive(myConnId)) return;
        
        _onDisconnected(myConnId);
      });

      _sub = channel.stream.listen(
        (dynamic raw) => _onMessage(myConnId, raw),
        onError: (Object e) {
          if (!_isActive(myConnId)) return;
          
          _onDisconnected(myConnId);
        },
        onDone: () {
          if (!_isActive(myConnId)) {
            
            return;
          }
          
          _onDisconnected(myConnId);
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (!_isActive(myConnId)) return;
      
      _onDisconnected(myConnId);
    }
  }

  bool _isActive(int connId) => connId == _connId;

  void _onMessage(int connId, dynamic raw) {
    if (!_isActive(connId)) return;
    final Map<String, dynamic> frame;
    try {
      frame = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (e) {
      
      return;
    }
    final cmd = frame['cmd'] as int? ?? -1;
    final data = frame['data'];

    if (cmd == CmdType.login) {
      // 鐧诲綍鎴愬姛
      
      _setStatus(WsStatus.connected);
      _startHeartbeat();
      onLoginSuccess?.call();
    } else if (cmd == CmdType.heartbeat) {
      // 蹇冭烦鍥炴墽锛屾棤闇€澶勭悊锛堝績璺崇敱鍛ㄦ湡瀹氭椂鍣ㄩ┍鍔級
    } else {
      
      _eventCtrl.add(WsEvent(cmd, data));
    }
  }

  void _send(Map<String, dynamic> frame) {
    final ch = _channel;
    if (ch == null) return;
    try {
      ch.sink.add(jsonEncode(frame));
    } catch (e) {
      
    }
  }

  void send(int cmd, Object? data) => _send({'cmd': cmd, 'data': data ?? {}});

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    // 复刻 wssocket.js：登录成功后立即发一次心跳，再周期发送。
    _send({'cmd': CmdType.heartbeat, 'data': {}});
    _heartbeatTimer = Timer.periodic(AppConstants.heartbeatInterval, (_) {
      if (_status == WsStatus.connected) {
        _send({'cmd': CmdType.heartbeat, 'data': {}});
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _onDisconnected(int connId) {
    if (!_isActive(connId)) return;
    _stopHeartbeat();
    _cleanupChannel();
    _setStatus(WsStatus.disconnected);
    if (_autoReconnect) _scheduleReconnect();
  }

  void _cleanupChannel() {
    _sub?.cancel();
    _sub = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void _scheduleReconnect() {
    if (!_autoReconnect) return;
    final url = _wsUrl, token = _token, devId = _devId;
    if (url == null || token == null || devId == null) return;

    final elapsed = DateTime.now().difference(_lastConnectTime);
    final delay = elapsed < AppConstants.reconnectMinInterval
        ? AppConstants.reconnectMinInterval - elapsed
        : Duration.zero;

    _reconnectTimer?.cancel();
    
    _reconnectTimer = Timer(delay, () {
      unawaited(_tryReconnectWithNetwork(url: url, token: token, devId: devId));
    });
  }

  Future<void> _tryReconnectWithNetwork({
    required String url,
    required String token,
    required String devId,
  }) async {
    if (isConnected) return;
    try {
      final results = await Connectivity().checkConnectivity();
      final offline = results.isEmpty ||
          results.every((r) => r == ConnectivityResult.none);
      if (offline) {
        
        _reconnectTimer?.cancel();
        _reconnectTimer = Timer(const Duration(seconds: 5), _scheduleReconnect);
        return;
      }
    } catch (e) {
      
    }
    connect(wsUrl: url, token: token, devId: devId);
  }

  void tryReconnect() {
    if (isConnected || _status == WsStatus.connecting) return;
    _scheduleReconnect();
  }

  void forceReconnect({
    required String wsUrl,
    required String token,
    required String devId,
  }) {
    
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    // 立即作废旧连接所有回调
    _connId++;
    _cleanupChannel();
    _setStatus(WsStatus.disconnected);
    _lastConnectTime = DateTime.fromMillisecondsSinceEpoch(0);
    connect(wsUrl: wsUrl, token: token, devId: devId);
  }

  void close() {
    
    _autoReconnect = false;
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    _connId++; // 作废旧回调
    _cleanupChannel();
    _setStatus(WsStatus.disconnected);
  }

  void dispose() {
    close();
    _eventCtrl.close();
    _statusCtrl.close();
  }
}

