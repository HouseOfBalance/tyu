import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:device_apps/device_apps.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:safe_device/safe_device.dart';

import 'security/biometric_service.dart';
import 'security/secure_storage_service.dart';
import 'security/hidden_gate.dart';
import 'cinematic_login.dart';

const String mockLrcData = """
[00:00.00] Co-op Super App Demo
[00:05.00] Bật Radar, dò quanh căn phòng
[00:10.50] Tìm lại em giữa muôn trùng sóng
[00:15.20] Chẳng cần Net, chẳng cần mây xanh
[00:20.00] Chỉ cần Wifi Direct kết nối nhanh
[00:25.50] Sóng Neon dẫn đường đêm nay...
[00:30.00] Chạm một cái, tim em trong tầm tay
[00:35.00] Cảm ơn vì đã sử dụng ứng dụng offline
[00:40.00] Co-op luôn kết nối bạn và tôi.
""";

class AppColors {
  static const Color bg = Color(0xFF030303); 
  static const Color surface = Color(0xFF0F0F13);
  static const Color primary = Color(0xFF66FCF1);
  static const Color accent = Color(0xFFFF007F);
  static const Color rose = Color(0xFFFF007F);
  static const Color sky = Color(0xFF66FCF1);
  static const Color violet = Color(0xFF8A2BE2);
  static const Color amber = Color(0xFFFFB000);
  static const Color cyan = Color(0xFF00FFFF);
  static const Color teal = Color(0xFF00FFCC);
  static const Color coral = Color(0xFFFF6B72);
  static const Color textMain = Colors.white;
  static const Color textSec = Colors.white70;
  static const Color textMuted = Colors.white38;
}
class RobertColors {
  static const wall = Color(0xFFFFEFC5); static const brown = Color(0xFFCB8F66);
  static const note = Color(0xFFF8C760); static const noteBorder = Color(0xFFB47605);
  static const highlightPink = Color(0xFFFF8685); static const highlightRed = Color(0xFFDF6665);
}

final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(false);
final ValueNotifier<Color?> customColorNotifier = ValueNotifier(null);
final ValueNotifier<bool> isStealthMode = ValueNotifier(false); // 🕶️ STEALTH MODE STATE
List<CameraDescription> cameras = [];
final ValueNotifier<List<Map<String, String>>> globalLocalSongs = ValueNotifier([]);

String currentDeviceType = 'phone';
bool isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
bool isMobile = Platform.isAndroid || Platform.isIOS;

final List<String> _adj = ["Nhanh nhẹn", "Vui vẻ", "Bí ẩn", "Lạnh lùng", "Dễ thương", "Mạnh mẽ"];
final List<String> _noun = ["Cà chua", "Trái táo", "Quả cam", "Dưa hấu", "Hiệp sĩ", "Hổ"];
String generateAlias() => "${_adj[math.Random().nextInt(_adj.length)]} ${_noun[math.Random().nextInt(_noun.length)]}";
final ValueNotifier<String> globalDeviceAlias = ValueNotifier(generateAlias());

void toggleStealthMode() {
  isStealthMode.value = !isStealthMode.value;
  if (isStealthMode.value) {
    List<String> fakeNames = ["Samsung Smart TV", "HP LaserJet Pro", "AirPods Pro", "Sony BRAVIA", "Mi Box S"];
    globalDeviceAlias.value = fakeNames[math.Random().nextInt(fakeNames.length)];
  } else {
    globalDeviceAlias.value = generateAlias();
  }
}

Widget auroraBackground(Color accent) => Stack(children: [
  Container(color: AppColors.bg),
  Positioned(top: -120, left: -80,  child: _aOrb(340, const Color(0xFF062038))),
  Positioned(top: 260,  right: -100, child: _aOrb(300, const Color(0xFF180D50))),
  Positioned(bottom: 80, left: -60, child: _aOrb(240, const Color(0xFF072E22))),
  Positioned(bottom: -80, right: 40, child: _aOrb(280, Color.fromRGBO(accent.red, accent.green, accent.blue, 0.14))),
]);
Widget _aOrb(double s, Color c) => Container(width: s, height: s, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [c, c.withAlpha(0)], radius: 0.75)));

Color tabAccentColor(int idx) {
  const list = [AppColors.amber, AppColors.cyan, AppColors.cyan, AppColors.violet, AppColors.teal, AppColors.rose, AppColors.amber, AppColors.sky];
  return list[idx.clamp(0, list.length - 1)];
}

Widget tabHeader(String title, Color accent, {String? subtitle, Widget? trailing}) => Padding(
  padding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ShaderMask(shaderCallback: (b) => LinearGradient(colors: [Colors.white, accent]).createShader(b),
        child: Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Rissa'))),
      if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSec, fontFamily: 'Rissa')),
    ]),
    if (trailing != null) trailing,
  ]),
);

class NeonButton extends StatefulWidget {
  final IconData icon; final Color color; final VoidCallback onTap; final String? label;
  const NeonButton(this.icon, this.color, this.onTap, {super.key, this.label});
  @override State<NeonButton> createState() => _NeonButtonState();
}
class _NeonButtonState extends State<NeonButton> {
  bool _isPressed = false;
  @override Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { HapticFeedback.selectionClick(); setState(()=>_isPressed = true); },
      onTapUp: (_) { setState(()=>_isPressed = false); widget.onTap(); },
      onTapCancel: () => setState(()=>_isPressed = false),
      child: AnimatedScale(scale: _isPressed ? 0.9 : 1.0, duration: const Duration(milliseconds: 150),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withAlpha(25), border: Border.all(color: widget.color.withAlpha(120), width: 1.5), boxShadow: [BoxShadow(color: widget.color.withAlpha(_isPressed ? 80 : 40), blurRadius: _isPressed ? 10 : 20, spreadRadius: 2)]),
            child: Icon(widget.icon, color: widget.color, size: 22)),
          if (widget.label != null) ...[const SizedBox(height: 8), Text(widget.label!, style: TextStyle(color: widget.color, fontSize: 11, fontFamily: 'Rissa', fontWeight: FontWeight.bold))]
        ]),
      )
    );
  }
}

Widget glBox(Widget child, bool isDark, {double r = 24, EdgeInsetsGeometry? p, EdgeInsetsGeometry? m, Color? color, double blur = 25}) {
  return Container(margin: m, child: ClipRRect(borderRadius: BorderRadius.circular(r), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
    child: Container(padding: p ?? const EdgeInsets.all(20), decoration: BoxDecoration(color: color ?? Colors.white.withAlpha(8), borderRadius: BorderRadius.circular(r), border: Border.all(color: Colors.white.withAlpha(25), width: 1.5), gradient: LinearGradient(colors: [Colors.white.withAlpha(20), Colors.white.withAlpha(0)], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 30, spreadRadius: -5)]),
      child: child))));
}

Widget buildPCWarning(String title, IconData icon) => Center(child: glBox(Column(mainAxisSize: MainAxisSize.min, children: [
  Icon(icon, size: 60, color: AppColors.amber), const SizedBox(height: 20),
  Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Rissa', color: Colors.white)), const SizedBox(height: 10),
  const Text("Yêu cầu phần cứng Mobile.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSec, fontSize: 14, fontFamily: 'Rissa')),
]), true, p: const EdgeInsets.all(32)));

// ================= 🧠 MESH CORE MODELS (ĐÃ NÂNG CẤP LÊN PACKET CÓ TTL) =================
class MeshPacket {
  final String id; final String from; final String to; final List<String> route; final String type; final String data; final String? imagePath; int ttl;
  MeshPacket({required this.id, required this.from, required this.to, required this.route, required this.type, required this.data, this.imagePath, this.ttl = 5});
  Map<String, dynamic> toJson() => {'id': id, 'from': from, 'to': to, 'route': route, 'type': type, 'data': data, 'imagePath': imagePath, 'ttl': ttl};
  factory MeshPacket.fromJson(Map<String, dynamic> json) => MeshPacket(id: json['id'], from: json['from'], to: json['to'], route: List<String>.from(json['route']), type: json['type'], data: json['data'], imagePath: json['imagePath'], ttl: json['ttl'] ?? 5);
}

final ValueNotifier<MeshPacket?> globalChatNoti = ValueNotifier(null);
final String myDeviceId = "ID_${math.Random().nextInt(999999)}_${DateTime.now().millisecondsSinceEpoch}";

// ================= MAIN =================
// ================= MAIN =================
Future<void> main() async {
  // Bắt buộc khởi tạo Core của Flutter trước
  WidgetsFlutterBinding.ensureInitialized();
  
  // Bọc TRONG TRY-CATCH để đảm bảo runApp() LUÔN ĐƯỢC CHẠY dù thiết bị có chặn quyền
  try {
    if (isMobile) { 
      try { cameras = await availableCameras(); } catch (e) {} 
      if (Platform.isAndroid) { 
        AndroidDeviceInfo info = await DeviceInfoPlugin().androidInfo; 
        if ((info.displayMetrics.widthPx / info.displayMetrics.xDpi) > 7.0) currentDeviceType = 'tablet'; 
      } 
    } else { 
      currentDeviceType = 'laptop'; 
    }
    
    await LocalDataManager.initFolder(); 
    globalLocalSongs.value = await LocalDataManager.loadLocalMusic();
  } catch (e) {
    debugPrint("🚨 BOOT ERROR: $e"); // Báo lỗi ngầm nhưng không làm sập app
  }
  
  // Giao diện bắt buộc phải được gọi ra
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override Widget build(BuildContext context) { 
    return ValueListenableBuilder<bool>(valueListenable: isDarkModeNotifier, builder: (context, isDark, child) => ValueListenableBuilder<Color?>(valueListenable: customColorNotifier, builder: (context, customColor, child) => MaterialApp(title: 'Co-op', debugShowCheckedModeBanner: false, themeMode: ThemeMode.dark, theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: AppColors.bg, fontFamily: 'Rissa'), home: const CinematicLogin()))); 
  }
}

// ================= BỘ QUẢN LÝ DỮ LIỆU ĐÃ ĐƯỢC BẢO VỆ CHỐNG SẬP =================
class LocalDataManager {
  static late Directory mainFolder;
  static late Directory publicDownloadFolder;

  static Future<void> initFolder() async { 
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory(); 
      mainFolder = Directory('${appDocDir.path}/money_schedule'); 
      if (!await mainFolder.exists()) await mainFolder.create(recursive: true); 
      
      if (Platform.isAndroid) { 
        publicDownloadFolder = Directory('/storage/emulated/0/Download/Flutter'); 
        try {
          // Thử tạo ở bộ nhớ ngoài, nếu Android chặn thì rẽ nhánh xuống catch
          if (!await publicDownloadFolder.exists()) await publicDownloadFolder.create(recursive: true); 
        } catch (e) {
          // BỊ CHẶN QUYỀN -> Dùng tạm thư mục hệ thống bên trong app
          publicDownloadFolder = mainFolder;
        }
      } else { 
        publicDownloadFolder = mainFolder; 
      } 
    } catch (e) {
      // Trường hợp xấu nhất thiết bị lỗi nặng
      mainFolder = Directory.systemTemp;
      publicDownloadFolder = Directory.systemTemp;
    }
  }

  static Future<String> saveImage(File t) async { String n = "IMG_${DateTime.now().millisecondsSinceEpoch}.jpg"; return (await t.copy('${publicDownloadFolder.path}/$n')).path; }
  static Future<void> saveAppData(List<CardModel> c, List<Transaction> t) async { await File('${mainFolder.path}/data.json').writeAsString(jsonEncode({"cards": c.map((e)=>e.toJson()).toList(), "transactions": t.map((e)=>e.toJson()).toList()})); }
  static Future<Map<String, dynamic>?> loadAppData() async { File f = File('${mainFolder.path}/data.json'); return await f.exists() ? jsonDecode(await f.readAsString()) : null; }
  static Future<void> saveNotis(List<NotiModel> n) async { await File('${mainFolder.path}/noti.json').writeAsString(jsonEncode(n.map((e)=>e.toJson()).toList())); }
  static Future<List<NotiModel>> loadNotis() async { File f = File('${mainFolder.path}/noti.json'); return await f.exists() ? (jsonDecode(await f.readAsString()) as List).map((e)=>NotiModel.fromJson(e)).toList() : []; }
  static Future<void> saveLocalMusic(List<Map<String, String>> s) async { await File('${mainFolder.path}/local_music.json').writeAsString(jsonEncode(s)); }
  static Future<List<Map<String, String>>> loadLocalMusic() async { File f = File('${mainFolder.path}/local_music.json'); return await f.exists() ? (jsonDecode(await f.readAsString()) as List).map((e)=>Map<String, String>.from(e)).toList() : []; }
  static Future<void> saveNotes(List<NoteModel> n) async { await File('${mainFolder.path}/notes_robert.json').writeAsString(jsonEncode(n.map((e)=>e.toJson()).toList())); }
  static Future<List<NoteModel>> loadNotes() async { File f = File('${mainFolder.path}/notes_robert.json'); return await f.exists() ? (jsonDecode(await f.readAsString()) as List).map((e)=>NoteModel.fromJson(e)).toList() : []; }
  static Future<int> getFolderSize() async { int s=0; if(await mainFolder.exists()){await for(var f in mainFolder.list(recursive: true)){if(f is File) s+=await f.length();}} return s; }
  static Future<void> clearAllData() async { if(await mainFolder.exists()) await mainFolder.delete(recursive:true); await initFolder(); }
}

enum TransactionType { income, expense } enum CardCategory { bank, door, parking, other }
class CardModel { final String name, number; final Color color1, color2; final CardCategory category; CardModel(this.name, this.number, this.color1, this.color2, this.category); Map<String, dynamic> toJson() => {"name": name, "number": number, "color1": color1.value, "color2": color2.value, "category": category.index}; static CardModel fromJson(Map<String, dynamic> j) => CardModel(j["name"], j["number"], Color(j["color1"]), Color(j["color2"]), CardCategory.values[j["category"]]); }
class Transaction { final String? imagePath, note; final double amount; final DateTime date; final TransactionType type; Transaction(this.imagePath, this.amount, this.note, this.date, this.type); Map<String, dynamic> toJson() => {"imagePath": imagePath, "amount": amount, "note": note, "date": date.toIso8601String(), "type": type.index}; static Transaction fromJson(Map<String, dynamic> j) => Transaction(j["imagePath"], j["amount"], j["note"], DateTime.parse(j["date"]), TransactionType.values[j["type"]]); }
class NotiModel { final String id, packageName, title, body; final DateTime timestamp; NotiModel(this.id, this.packageName, this.title, this.body, this.timestamp); Map<String, dynamic> toJson() => {"id": id, "packageName": packageName, "title": title, "body": body, "timestamp": timestamp.toIso8601String()}; static NotiModel fromJson(Map<String, dynamic> j) => NotiModel(j["id"], j["packageName"], j["title"], j["body"], DateTime.parse(j["timestamp"])); }
class NoteModel { String id, type, text; double dx, dy, w, h; bool isDone; bool isLocked; NoteModel({required this.id, required this.type, required this.text, required this.dx, required this.dy, this.isDone = false, this.isLocked = false, this.w = 160, this.h = 160}); Map<String, dynamic> toJson() => {'id': id, 'type': type, 'text': text, 'dx': dx, 'dy': dy, 'isDone': isDone, 'isLocked': isLocked, 'w': w, 'h': h}; static NoteModel fromJson(Map<String, dynamic> j) => NoteModel(id: j['id'], type: j['type'] ?? 'text', text: j['text'], dx: j['dx'], dy: j['dy'], isDone: j['isDone'] ?? j['done'] ?? false, isLocked: j['isLocked'] ?? false, w: j['w']?.toDouble() ?? 160.0, h: j['h']?.toDouble() ?? 160.0); }

class FadeIndexedStack extends StatefulWidget { final int index; final List<Widget> children; const FadeIndexedStack({super.key, required this.index, required this.children}); @override State<FadeIndexedStack> createState() => _FadeIndexedStackState(); }
class _FadeIndexedStackState extends State<FadeIndexedStack> with SingleTickerProviderStateMixin { late AnimationController _c; @override void initState() { _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 300))..forward(); super.initState(); } @override void didUpdateWidget(FadeIndexedStack o) { if (widget.index != o.index) _c.forward(from: 0.0); super.didUpdateWidget(o); } @override void dispose() { _c.dispose(); super.dispose(); } @override Widget build(BuildContext context) => FadeTransition(opacity: _c, child: IndexedStack(index: widget.index, children: widget.children)); }

Future<bool> requestOfflinePermissions(BuildContext context) async {
  if (isDesktop) return false;
  Map<Permission, PermissionStatus> statuses = await [Permission.location, Permission.locationWhenInUse, Permission.bluetooth, Permission.bluetoothScan, Permission.bluetoothAdvertise, Permission.bluetoothConnect, Permission.nearbyWifiDevices].request();
  try { await const MethodChannel('flutter/platform').invokeMethod('setLocationAccuracy', {'accuracy': 'high'}); } catch (_) {}
  bool locGranted = statuses[Permission.location]?.isGranted ?? false;
  bool bleGranted = statuses[Permission.bluetoothScan]?.isGranted ?? false;
  return locGranted && bleGranted;
}

// ================= 📡 P2P NET MANAGER (ROUTING, PING & RELAY) =================
class FileProg { final String name; final double progress; FileProg(this.name, this.progress); }
enum P2pConnState { idle, discovering, hosting, connecting, connected, failed }

class P2pPeerMeta {
  final String deviceAddress; final String deviceName; final DateTime lastSeen; final bool isConnected; final bool isConnecting;
  const P2pPeerMeta({required this.deviceAddress, required this.deviceName, required this.lastSeen, this.isConnected = false, this.isConnecting = false});
  P2pPeerMeta copyWith({String? deviceAddress, String? deviceName, DateTime? lastSeen, bool? isConnected, bool? isConnecting}) => P2pPeerMeta(deviceAddress: deviceAddress ?? this.deviceAddress, deviceName: deviceName ?? this.deviceName, lastSeen: lastSeen ?? this.lastSeen, isConnected: isConnected ?? this.isConnected, isConnecting: isConnecting ?? this.isConnecting);
}

class HandshakeRequest {
  final String deviceId; final String alias; final String role; final String protocolVersion;
  const HandshakeRequest({required this.deviceId, required this.alias, required this.role, required this.protocolVersion});
  Map<String, dynamic> toJson() => {'deviceId': deviceId, 'alias': alias, 'role': role, 'protocolVersion': protocolVersion};
  factory HandshakeRequest.fromJson(Map<String, dynamic> json) => HandshakeRequest(deviceId: json['deviceId'] ?? '', alias: json['alias'] ?? 'Unknown', role: json['role'] ?? 'peer', protocolVersion: json['protocolVersion'] ?? '1');
}

class HandshakeEvent { final HandshakeRequest request; final bool accepted; const HandshakeEvent({required this.request, this.accepted = false}); }

class P2pNetManager {
  static final P2pNetManager instance = P2pNetManager._internal();
  P2pNetManager._internal();

  final FlutterP2pConnection p2p = FlutterP2pConnection();
  WifiP2PInfo? wifiP2PInfo;
  
  ServerSocket? _serverSocket;
  // 🔥 MESH ROUTING: Hỗ trợ Multi-socket cho Host để làm Relay Node
  final List<Socket> _activeSockets = [];
  
  final StreamController<MeshPacket> msgStream = StreamController<MeshPacket>.broadcast();
  final StreamController<FileProg> fileProgStream = StreamController<FileProg>.broadcast();
  final ValueNotifier<HandshakeEvent?> pendingHandshake = ValueNotifier(null);
  final ValueNotifier<P2pConnState> connectionState = ValueNotifier(P2pConnState.idle);
  final ValueNotifier<List<P2pPeerMeta>> peers = ValueNotifier([]);
  final ValueNotifier<Map<String, int>> pingMap = ValueNotifier({}); // 📡 Theo dõi Latency
  
  String? connectedDeviceName; String? connectedDeviceId; String? _connectingAddress;
  final Map<String, P2pPeerMeta> _peerMap = {};
  final Set<String> _seenPackets = {}; // 🧠 Bộ lọc vòng lặp Relay
  bool isHost = false; bool isConnected = false;
  Timer? _pingTimer;
  
  Future<void> init() async {
    await p2p.initialize(); await p2p.register();
    p2p.streamWifiP2PInfo().listen((info) {
      wifiP2PInfo = info;
      if (info.isConnected && info.isGroupOwner && _serverSocket == null) { _setState(P2pConnState.hosting); _startSocketServer(); } 
      else if (info.isConnected && !info.isGroupOwner && _activeSockets.isEmpty && info.groupOwnerAddress != null) { _setState(P2pConnState.connecting); _connectToHost(info.groupOwnerAddress!); } 
      else if (!info.isConnected && !isConnected && connectionState.value != P2pConnState.discovering) { _setState(P2pConnState.idle); }
    });
    p2p.streamPeers().listen((pList) { _refreshPeers(pList); });

    // 📡 Hệ thống tự động Ping đo chất lượng mạng
    _pingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_activeSockets.isNotEmpty) {
        MeshPacket pingPacket = MeshPacket(id: "PING_${math.Random().nextInt(999999)}", from: myDeviceId, to: "ALL", route: [myDeviceId], type: "PING", data: "${DateTime.now().millisecondsSinceEpoch}");
        _broadcastPacket(pingPacket);
      }
    });
  }

  void _setState(P2pConnState state) { connectionState.value = state; }

  void _refreshPeers(List<DiscoveredPeers> rawPeers) {
    final now = DateTime.now();
    for (final peer in rawPeers) {
      final key = peer.deviceAddress;
      _peerMap[key] = (_peerMap[key] ?? P2pPeerMeta(deviceAddress: key, deviceName: peer.deviceName, lastSeen: now)).copyWith(deviceName: peer.deviceName, lastSeen: now, isConnected: connectedDeviceId == key, isConnecting: _connectingAddress == key);
    }
    _peerMap.removeWhere((key, value) => now.difference(value.lastSeen).inSeconds > 10 && connectedDeviceId != key);
    final sorted = _peerMap.values.toList()..sort((a, b) {
        if (a.isConnected != b.isConnected) return a.isConnected ? -1 : 1;
        if (a.isConnecting != b.isConnecting) return a.isConnecting ? -1 : 1;
        return b.lastSeen.compareTo(a.lastSeen);
      });
    peers.value = sorted;
  }
  
  Future<void> startDiscovery() async {
    _setState(P2pConnState.discovering);
    await p2p.stopDiscovery();
    await Future.delayed(const Duration(milliseconds: 250));
    await p2p.discover();
  }
  
  Future<void> hostRoom() async {
    await p2p.stopDiscovery(); await p2p.removeGroup();
    await Future.delayed(const Duration(milliseconds: 250)); await p2p.createGroup();
    isHost = true; _connectingAddress = null; _setState(P2pConnState.hosting);
  }
  
  Future<void> joinRoom(P2pPeerMeta peer) async {
    if (_connectingAddress == peer.deviceAddress || isConnected) return;
    await p2p.stopDiscovery();
    _connectingAddress = peer.deviceAddress; _setState(P2pConnState.connecting);
    try {
      await Future.delayed(const Duration(milliseconds: 250));
      await p2p.connect(peer.deviceAddress);
      isHost = false;
    } catch (e) { _connectingAddress = null; _setState(P2pConnState.failed); rethrow; }
  }
  
  Future<void> leaveRoom() async {
    await p2p.removeGroup();
    for (var s in _activeSockets) { s.destroy(); } _activeSockets.clear();
    _serverSocket?.close(); _serverSocket = null;
    _connectingAddress = null; connectedDeviceId = null; connectedDeviceName = null;
    isConnected = false; isHost = false;
    _peerMap.updateAll((key, value) => value.copyWith(isConnected: false, isConnecting: false));
    peers.value = _peerMap.values.toList(); _setState(P2pConnState.idle);
  }
  
  void _startSocketServer() async {
    _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 8888);
    _serverSocket!.listen((Socket s) {
      s.setOption(SocketOption.tcpNoDelay, true);
      _activeSockets.add(s); // Host có thể nhận nhiều Socket
      isConnected = true; _connectingAddress = null; _setState(P2pConnState.connected);
      _handleSocketData(s);
    });
  }
  
  Future<void> _connectToHost(String ip) async {
    int retries = 0;
    while (_activeSockets.isEmpty && retries < 5) {
      try {
        Socket s = await Socket.connect(ip, 8888, timeout: const Duration(seconds: 4));
        s.setOption(SocketOption.tcpNoDelay, true);
        _activeSockets.add(s);
        isConnected = true; _connectingAddress = null; _setState(P2pConnState.connected);
        sendHandshake(globalDeviceAlias.value);
        _handleSocketData(s); return;
      } catch (e) { retries++; await Future.delayed(Duration(milliseconds: 500 * retries)); }
    }
  }

  void sendHandshake(String name) {
    final payload = jsonEncode(HandshakeRequest(deviceId: myDeviceId, alias: name, role: isHost ? 'host' : 'client', protocolVersion: '2').toJson());
    _broadcastRaw(utf8.encode('H|${utf8.encode(payload).length}|$payload'));
  }
  void sendHandshakeAccept(String name) {
    final payload = jsonEncode(HandshakeRequest(deviceId: myDeviceId, alias: name, role: 'accepted', protocolVersion: '2').toJson());
    _broadcastRaw(utf8.encode('HA|${utf8.encode(payload).length}|$payload'));
  }

  final List<int> _buffer = []; bool _isFileMode = false; int _curLen = 0; String _curName = ""; int _receivedLen = 0; IOSink? _sink;

  void _handleSocketData(Socket s) {
    s.listen((data) { _buffer.addAll(data); _processBuffer(s); }, onDone: () {
      _activeSockets.remove(s);
      if (_activeSockets.isEmpty) {
        isConnected = false; _connectingAddress = null; _sink?.close(); _setState(P2pConnState.idle);
      }
    });
  }

  Future<void> _processBuffer(Socket sourceSocket) async {
    while (_buffer.isNotEmpty) {
      if (!_isFileMode) {
        int p1 = _buffer.indexOf(124); if (p1 == -1) return;
        String type = utf8.decode(_buffer.sublist(0, p1));
        
        // 🧠 MESH ROUTING LOGIC XỬ LÝ GÓI TIN M
        if (type == "M") {
          int p2 = _buffer.indexOf(124, p1 + 1); if (p2 == -1) return;
          int len = int.parse(utf8.decode(_buffer.sublist(p1 + 1, p2)));
          if (_buffer.length < p2 + 1 + len) return;
          String json = utf8.decode(_buffer.sublist(p2 + 1, p2 + 1 + len));
          _buffer.removeRange(0, p2 + 1 + len);

          MeshPacket packet = MeshPacket.fromJson(jsonDecode(json));
          
          // Chống lặp (Loop Prevention)
          if (_seenPackets.contains(packet.id)) continue;
          _seenPackets.add(packet.id);

          // Phân loại Packet
          if (packet.type == "PING") {
            MeshPacket pong = MeshPacket(id: packet.id, from: myDeviceId, to: packet.from, route: [myDeviceId], type: "PONG", data: packet.data, ttl: 1);
            _broadcastPacket(pong);
          } else if (packet.type == "PONG") {
            int start = int.parse(packet.data);
            Map<String, int> newMap = Map.from(pingMap.value);
            newMap[packet.from] = DateTime.now().millisecondsSinceEpoch - start;
            pingMap.value = newMap;
          } else if (packet.type == "MSG") {
            if (packet.to == "ALL" || packet.to == myDeviceId) msgStream.add(packet);
            
            // RELAY LOGIC (Chuyển tiếp cho các node khác)
            if (packet.ttl > 0 && !packet.route.contains(myDeviceId)) {
              packet.route.add(myDeviceId);
              packet.ttl--;
              // Gửi tới tất cả các socket NGOẠI TRỪ socket vừa gửi đến mình
              String pLoad = jsonEncode(packet.toJson());
              List<int> bytes = utf8.encode("M|${utf8.encode(pLoad).length}|$pLoad");
              for (var sock in _activeSockets) {
                if (sock != sourceSocket) { try { sock.add(bytes); } catch(_) {} }
              }
            }
          }
        } else if (type == "F") {
          int p2 = _buffer.indexOf(124, p1 + 1); if (p2 == -1) return;
          int p3 = _buffer.indexOf(124, p2 + 1); if (p3 == -1) return;
          _curLen = int.parse(utf8.decode(_buffer.sublist(p1 + 1, p2)));
          _curName = utf8.decode(_buffer.sublist(p2 + 1, p3));
          String savePath = "${LocalDataManager.publicDownloadFolder.path}/$_curName";
          _sink = File(savePath).openWrite(mode: FileMode.write);
          _isFileMode = true; _receivedLen = 0; _buffer.removeRange(0, p3 + 1);
        } else if (type == "H" || type == "HA") {
          int p2 = _buffer.indexOf(124, p1 + 1); if (p2 == -1) return;
          int len = int.parse(utf8.decode(_buffer.sublist(p1 + 1, p2)));
          if (_buffer.length < p2 + 1 + len) return;
          String raw = utf8.decode(_buffer.sublist(p2 + 1, p2 + 1 + len));
          HandshakeRequest request;
          try { request = HandshakeRequest.fromJson(Map<String, dynamic>.from(jsonDecode(raw))); } catch (_) { request = HandshakeRequest(deviceId: '', alias: raw, role: 'legacy', protocolVersion: '1'); }
          connectedDeviceName = request.alias; connectedDeviceId = request.deviceId.isEmpty ? connectedDeviceName : request.deviceId;
          if (type == "H") { pendingHandshake.value = HandshakeEvent(request: request); } else { pendingHandshake.value = HandshakeEvent(request: request, accepted: true); _setState(P2pConnState.connected); }
          _buffer.removeRange(0, p2 + 1 + len);
        } else { _buffer.clear(); }
      } else {
        int remaining = _curLen - _receivedLen;
        if (_buffer.length <= remaining) { _sink!.add(_buffer); _receivedLen += _buffer.length; _buffer.clear(); } else { _sink!.add(_buffer.sublist(0, remaining)); _receivedLen += remaining; _buffer.removeRange(0, remaining); }
        fileProgStream.add(FileProg(_curName, _receivedLen / _curLen));
        if (_receivedLen == _curLen) { await _sink!.close(); _isFileMode = false; }
      }
    }
  }

  void _broadcastRaw(List<int> bytes) {
    for (var s in _activeSockets) { try { s.add(bytes); } catch(_) {} }
  }
  
  void _broadcastPacket(MeshPacket p) {
    String payload = jsonEncode(p.toJson());
    List<int> header = utf8.encode("M|${utf8.encode(payload).length}|$payload");
    _broadcastRaw(header);
  }

  void sendText(String jsonStr) {
    MeshPacket p = MeshPacket.fromJson(jsonDecode(jsonStr));
    _seenPackets.add(p.id); // Chống dội ngược lại máy mình
    _broadcastPacket(p);
  }
  
  Future<void> sendFile(String filePath, String realName) async {
    if (_activeSockets.isEmpty) return;
    File f = File(filePath); int len = await f.length();
    List<int> header = utf8.encode("F|$len|$realName|");
    _broadcastRaw(header);
    Stream<List<int>> fs = f.openRead(); int sent = 0;
    await for (var chunk in fs) { _broadcastRaw(chunk); sent += chunk.length; fileProgStream.add(FileProg(realName, sent / len)); }
  }
}

// ================= GIAO DIỆN CHÍNH (WALLET & MENU WRAPPER) =================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  static _MainScreenState? of(BuildContext context) => context.findAncestorStateOfType<_MainScreenState>();
  @override State<MainScreen> createState() => _MainScreenState();
}
class _MainScreenState extends State<MainScreen> {
  int index = 0;
  List<Transaction> transactions = []; 

  void navigateToTab(int i) { setState(() => index = i); }

late final List<Widget> tabs = [
    const WalletPage(),
    isDesktop 
      ? buildPCWarning("Locket Camera", Icons.camera_alt) 
      : LocketCameraTab(
          isActive: index == 1, 
          transactions: transactions, 
          onNewTransaction: (t) async { 
            String p = await LocalDataManager.saveImage(File(t.imagePath!)); 
            setState(() => transactions.add(Transaction(p, t.amount, t.note, t.date, t.type))); 
            await LocalDataManager.saveAppData([], transactions); 
          }
        ),
    isDesktop ? buildPCWarning("Game Space", Icons.games) : const GameSpaceTab(),
    isDesktop ? buildPCWarning("Notification Log", Icons.notifications) : const NotiLogTab(),
    
    // 🔥 ĐÃ FIX: Xóa chữ 'const' ở phía trước LocalSendTab
    isDesktop ? buildPCWarning("Nearby Send", Icons.wifi_tethering) : LocalSendTab(),
    
    const MusicTab(),
    const NotesTab(),
    
    // 🔥 ĐÃ FIX: Xóa chữ 'const' ở phía trước LocalChatTab
    isDesktop ? buildPCWarning("Mesh LocalChat", Icons.chat_bubble) : LocalChatTab(),
  ];

  @override void initState() {
    super.initState();
    P2pNetManager.instance.init();
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(child: auroraBackground(tabAccentColor(index))),
          SafeArea(bottom: false, child: FadeIndexedStack(index: index, children: tabs)),
          Positioned(bottom: 25, left: 0, right: 0, child: Center(child: buildMenuButton())),
          ValueListenableBuilder<MeshPacket?>(
            valueListenable: globalChatNoti,
            builder: (context, msg, child) {
              if (msg == null) return const SizedBox.shrink();
              return Positioned(
                top: 50, left: 20, right: 20,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: -100.0, end: 0.0), duration: const Duration(milliseconds: 300), curve: Curves.easeOutBack,
                  builder: (context, val, child) => Transform.translate(
                    offset: Offset(0, val),
                    child: glBox(Padding(padding: const EdgeInsets.all(15), child: Row(children: [
                      const CircleAvatar(backgroundColor: AppColors.sky, radius: 20, child: Icon(Icons.chat_bubble, color: Colors.white, size: 20)),
                      const SizedBox(width: 15),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text(msg.from.length > 15 ? msg.from.substring(0,15) : msg.from, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Rissa', fontSize: 16)),
                        Text(msg.imagePath != null ? "Đã gửi 1 ảnh 🖼️" : msg.data, style: const TextStyle(color: Colors.white70, fontFamily: 'Rissa', fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)
                      ]))
                    ])), true)
                  )
                )
              );
            }
          )
        ],
      ),
    );
  }

  Widget buildMenuButton() {
    return GestureDetector(
      onTap: openMenu,
      child: glBox(
        const Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.grid_view_rounded, color: Colors.white, size: 18), SizedBox(width: 10), Text("MENU", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, fontFamily: 'Rissa', letterSpacing: 1.5))])),
        true, p: const EdgeInsets.all(0), r: 30
      ),
    );
  }

  void openMenu() {
    showGeneralDialog(
      context: context, barrierDismissible: true, barrierLabel: "menu", barrierColor: Colors.black.withAlpha(130),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, a1, a2, child) => SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(CurvedAnimation(parent: a1, curve: Curves.easeOutCubic)), child: FadeTransition(opacity: a1, child: child)),
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: glBox(
              SizedBox(width: 320, height: 200,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.all(16), itemCount: 8,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 15, crossAxisSpacing: 10, childAspectRatio: 0.8),
                  itemBuilder: (_, i) {
                    bool a = index == i; Color accent = tabAccentColor(i);
                    return GestureDetector(
                      onTap: () { HapticFeedback.mediumImpact(); setState(() => index = i); Navigator.pop(context); },
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        AnimatedContainer(duration: const Duration(milliseconds: 280), height: 48, width: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: a ? accent.withAlpha(35) : Colors.white.withAlpha(10), border: Border.all(color: a ? accent : Colors.white.withAlpha(28), width: 1.5), boxShadow: a ? [BoxShadow(color: accent.withAlpha(80), blurRadius: 18)] : []), child: Icon(getIcon(i), color: a ? accent : Colors.white.withAlpha(155), size: 22)),
                        const SizedBox(height: 6),
                        Text(getLabel(i), style: TextStyle(color: a ? accent : AppColors.textSec, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Rissa'), overflow: TextOverflow.ellipsis)
                      ]),
                    );
                  },
                ),
              ), true, p: const EdgeInsets.all(0)
            ),
          ),
        );
      },
    );
  }

  IconData getIcon(int i) {
    switch (i) { case 0: return Icons.account_balance_wallet_outlined; case 1: return Icons.camera_outlined; case 2: return Icons.sports_esports_outlined; case 3: return Icons.notifications_outlined; case 4: return Icons.wifi_tethering; case 5: return Icons.music_note_outlined; case 6: return Icons.sticky_note_2_outlined; case 7: return Icons.chat_bubble_outline; default: return Icons.circle; }
  }
  String getLabel(int i) {
    switch (i) { case 0: return "Wallet"; case 1: return "Camera"; case 2: return "Game"; case 3: return "Noti"; case 4: return "Send"; case 5: return "Music"; case 6: return "Notes"; case 7: return "Chat"; default: return ""; }
  }
}

// ================= LOCAL SEND TAB (AIRDROP BUBBLE UI + PING COLORS) =================
class LocalSendTab extends StatefulWidget { const LocalSendTab({super.key}); @override State<LocalSendTab> createState() => _LocalSendTabState(); }
class _LocalSendTabState extends State<LocalSendTab> {
  List<P2pPeerMeta> discoveredNodes = [];
  List<File> filesToDrag = [];
  ValueNotifier<double> progress = ValueNotifier(-1.0);
  Timer? _scanTimer;

  @override void initState() {
    super.initState();
    P2pNetManager.instance.peers.addListener(_onPeersChanged);
    P2pNetManager.instance.fileProgStream.stream.listen((prog) { progress.value = prog.progress; });
    _startAutoScan();
  }

  void _onPeersChanged() {
    if (mounted) setState(() => discoveredNodes = P2pNetManager.instance.peers.value);
  }

  void _startAutoScan() {
    if (!P2pNetManager.instance.isConnected && !isStealthMode.value) P2pNetManager.instance.startDiscovery();
    _scanTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!P2pNetManager.instance.isConnected && !isStealthMode.value) P2pNetManager.instance.startDiscovery();
    });
  }

  @override void dispose() { 
    P2pNetManager.instance.peers.removeListener(_onPeersChanged);
    _scanTimer?.cancel(); 
    P2pNetManager.instance.p2p.stopDiscovery(); 
    super.dispose(); 
  }

  void _pickFiles() async {
    FilePickerResult? r = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (r != null && r.files.isNotEmpty) {
      List<File> newFiles = r.files.where((f) => f.path != null).map((f) => File(f.path!)).toList();
      if (mounted) setState(() => filesToDrag.addAll(newFiles));
    }
  }

  Widget _buildTicket(File file) {
    String ext = file.path.split('.').last.toUpperCase();
    Color extColor = ext == 'APK' ? AppColors.violet : ext == 'MP4' || ext == 'AVI' ? AppColors.coral : ext == 'ZIP' || ext == 'RAR' ? AppColors.amber : AppColors.teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(color: extColor.withAlpha(25), borderRadius: BorderRadius.circular(20), border: Border.all(color: extColor.withAlpha(80), width: 1), boxShadow: [BoxShadow(color: extColor.withAlpha(40), blurRadius: 10)]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: extColor.withAlpha(50), borderRadius: BorderRadius.circular(6)), child: Text(ext, style: TextStyle(color: extColor, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'Rissa'))),
        const SizedBox(width: 8),
        Text(file.path.split('/').last, style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Rissa'), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  @override Widget build(BuildContext context) {
    bool isConn = P2pNetManager.instance.isConnected;
    return Column(children: [
      tabHeader("Nearby Send", AppColors.teal,
        subtitle: isConn ? "Đã kết nối ngang hàng" : (isStealthMode.value ? "Stealth Mode: Ẩn danh" : "Đang dò tìm tự động..."),
        trailing: IconButton(icon: const Icon(Icons.add_circle, color: AppColors.teal, size: 36), onPressed: _pickFiles),
      ),
      
      ValueListenableBuilder<double>(
        valueListenable: progress,
        builder: (context, val, _) => val >= 0
          ? Container(height: 4, margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: AppColors.teal.withAlpha(30)),
              child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: val == 0 ? null : val,
                child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), gradient: const LinearGradient(colors: [AppColors.teal, AppColors.sky])))))
          : const SizedBox.shrink(),
      ),

      Expanded(child: Stack(
        alignment: Alignment.center,
        children: [
          glBox(const Icon(Icons.smartphone, size: 40, color: AppColors.teal), true, r: 40, p: const EdgeInsets.all(20)),
          
          ...discoveredNodes.asMap().entries.map((e) {
            int index = e.key; var peer = e.value;
            bool isConnectedPeer = P2pNetManager.instance.connectedDeviceId == peer.deviceAddress;
            double angle = (index * (2 * math.pi / math.max(discoveredNodes.length, 1)));
            double radius = 130.0;
            double dx = math.cos(angle) * radius;
            double dy = math.sin(angle) * radius;
            
            return Transform.translate(
              offset: Offset(dx, dy),
              child: DeviceBubble(
                peer: peer,
                isConnected: isConnectedPeer,
                onTap: () async {
                  if (!isConnectedPeer) { try { await P2pNetManager.instance.joinRoom(peer); } catch(e) {} }
                },
                onAccept: (file) async {
                  if (isConnectedPeer) {
                    await P2pNetManager.instance.sendFile(file.path, file.path.split('/').last);
                    setState(() => filesToDrag.remove(file));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chạm để kết nối trước khi gửi!")));
                  }
                }
              )
            );
          }),

          if (filesToDrag.isNotEmpty) 
            Positioned(bottom: 20, left: 0, right: 0,
              child: SizedBox(height: 54, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: filesToDrag.length,
                itemBuilder: (c, idx) => Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Draggable<File>(data: filesToDrag[idx],
                    feedback: Material(color: Colors.transparent, child: _buildTicket(filesToDrag[idx])),
                    childWhenDragging: Opacity(opacity: 0.3, child: _buildTicket(filesToDrag[idx])),
                    child: _buildTicket(filesToDrag[idx]))),
              )),
            ),
        ]
      ))
    ]);
  }
}

// BONG BÓNG THIẾT BỊ (MÀU THEO PING SIGNAL)
class DeviceBubble extends StatefulWidget {
  final P2pPeerMeta peer; final bool isConnected; final Function(File) onAccept; final VoidCallback onTap;
  const DeviceBubble({super.key, required this.peer, required this.isConnected, required this.onAccept, required this.onTap});
  @override State<DeviceBubble> createState() => _DeviceBubbleState();
}
class _DeviceBubbleState extends State<DeviceBubble> with SingleTickerProviderStateMixin {
  late AnimationController ctrl;
  @override void initState() {
    super.initState();
    ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }
  @override void dispose() { ctrl.dispose(); super.dispose(); }

  Color _getSignalColor(String deviceAddress) {
    if (!widget.isConnected) return Colors.white54;
    int ping = P2pNetManager.instance.pingMap.value[myDeviceId] ?? 0; // Trỏ tạm, nếu có ping thật sẽ update
    if (ping == 0) return AppColors.teal; // Mặc định xanh khi mới nối
    if (ping < 100) return Colors.greenAccent;
    if (ping < 300) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override Widget build(BuildContext context) {
    return DragTarget<File>(
      onAcceptWithDetails: (details) => widget.onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        bool isHovered = candidateData.isNotEmpty;
        Color sigColor = _getSignalColor(widget.peer.deviceAddress);
        
        return GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: ctrl,
            builder: (_, __) {
              double scale = 1 + (widget.isConnected ? (ctrl.value * 0.05) : 0.0);
              if (isHovered) scale += 0.1;

              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isConnected ? sigColor.withAlpha(50) : Colors.white.withAlpha(10),
                    border: Border.all(color: widget.isConnected ? sigColor : (isHovered ? Colors.greenAccent : Colors.white24), width: isHovered ? 3 : 2),
                    boxShadow: widget.isConnected || isHovered ? [BoxShadow(color: (isHovered ? Colors.greenAccent : sigColor).withAlpha(80), blurRadius: 15)] : [],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(radius: 22, backgroundColor: widget.isConnected ? sigColor : Colors.transparent, child: Icon(Icons.person, color: widget.isConnected ? AppColors.bg : Colors.white70, size: 24)),
                      const SizedBox(height: 6),
                      SizedBox(width: 60, child: Text(widget.peer.deviceName, style: TextStyle(color: widget.isConnected ? sigColor : Colors.white, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Rissa'), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }
    );
  }
}

// ================= LOCAL CHAT TAB (TELEGRAM MINI UI + MESH PROTOCOL) =================
class LocalChatTab extends StatefulWidget { static String? activeChatId; const LocalChatTab({super.key}); @override State<LocalChatTab> createState() => _LocalChatTabState(); }
class _LocalChatTabState extends State<LocalChatTab> {
  List<MeshPacket> chatHistory = [];
  TextEditingController chatCtrl = TextEditingController(); 
  ScrollController scrollCtrl = ScrollController(); 
  StreamSubscription? _msgSub;

  @override void initState() { 
    super.initState(); 
    _msgSub = P2pNetManager.instance.msgStream.stream.listen((msg) {
      if (msg.type == "MSG" && mounted) {
        setState(() => chatHistory.add(msg));
        if (LocalChatTab.activeChatId != msg.from) {
          globalChatNoti.value = msg;
          Future.delayed(const Duration(seconds: 3), () => globalChatNoti.value = null);
        }
        _scrollToBottom();
      }
    });
  }
  @override void dispose() { _msgSub?.cancel(); super.dispose(); }

  void _sendText() {
    if (chatCtrl.text.isEmpty || !P2pNetManager.instance.isConnected) return;
    MeshPacket msg = MeshPacket(id: "MSG_${math.Random().nextInt(999999)}", from: globalDeviceAlias.value, to: "ALL", route: [myDeviceId], type: "MSG", data: chatCtrl.text, ttl: 5);
    P2pNetManager.instance.sendText(jsonEncode(msg.toJson()));
    setState(() { chatHistory.add(msg); chatCtrl.clear(); });
    _scrollToBottom();
  }

  void _scrollToBottom() { Future.delayed(const Duration(milliseconds: 100), () { if (scrollCtrl.hasClients) scrollCtrl.animateTo(scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); }); }

  @override Widget build(BuildContext context) { 
    bool isConn = P2pNetManager.instance.isConnected;
    
    if (!isConn) {
      return Column(children: [
        tabHeader("Mesh Chat", AppColors.sky, subtitle: "Bảo mật End-to-End"),
        const Spacer(),
        const Icon(Icons.wifi_off_rounded, size: 80, color: Colors.white24),
        const SizedBox(height: 20),
        const Text("Chưa có kết nối mạng", style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Rissa', fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text("Vui lòng qua Tab Send để kết nối với bạn bè\ntrước khi bắt đầu trò chuyện.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 14, fontFamily: 'Rissa')),
        const Spacer(),
      ]);
    }

    return Container(
      color: const Color(0xFF0F0F0F),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.only(top: 50, bottom: 15, left: 16, right: 16),
          decoration: const BoxDecoration(color: Color(0xFF212121)),
          child: Row(children: [
            const CircleAvatar(backgroundColor: AppColors.sky, radius: 20, child: Text("M", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
            const SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(P2pNetManager.instance.connectedDeviceName ?? "Mesh Network", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Rissa')),
              const Text("Đang hoạt động qua Relay", style: TextStyle(fontSize: 12, color: AppColors.sky, fontFamily: 'Rissa')),
            ])),
          ]),
        ),
        
        Expanded(child: ListView.builder(controller: scrollCtrl, padding: const EdgeInsets.all(14).copyWith(bottom: 20), itemCount: chatHistory.length, itemBuilder: (context, index) {
          final m = chatHistory[index]; bool isMe = m.from == globalDeviceAlias.value;
          return Align(alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration( 
                borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(isMe ? 18 : 4), bottomRight: Radius.circular(isMe ? 4 : 18)), 
                color: isMe ? const Color(0xFF2B5278) : const Color(0xFF2A2A2A), 
              ),
              child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
                if (!isMe) Text(m.from, style: const TextStyle(color: AppColors.sky, fontSize: 12, fontWeight: FontWeight.bold)),
                if (m.data.isNotEmpty) Padding(padding: EdgeInsets.only(top: !isMe ? 4 : 0), child: Text(m.data, style: const TextStyle(color: Colors.white, fontSize: 15))),
              ]),
            ));
        })),
        
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12).copyWith(bottom: 90),
          decoration: const BoxDecoration(color: Color(0xFF212121)),
          child: Row(children: [
            const Icon(Icons.attach_file, color: Colors.white54, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: const Color(0xFF141414), borderRadius: BorderRadius.circular(24)), child: TextField(controller: chatCtrl, style: const TextStyle(color: Colors.white, fontSize: 15), decoration: const InputDecoration(border: InputBorder.none, hintText: "Message via Mesh...", hintStyle: TextStyle(color: Colors.white38))))),
            const SizedBox(width: 10),
            GestureDetector(onTap: _sendText, child: const CircleAvatar(backgroundColor: AppColors.sky, radius: 24, child: Icon(Icons.send_rounded, color: Colors.white, size: 22))),
          ]),
        ),
      ]),
    );
  }
}

// CÁC TAB KHÁC NHƯ WALLET, SETTING, CAMERA, GAME, MUSIC... (Giữ nguyên cho an toàn)
class WalletPage extends StatefulWidget { const WalletPage({super.key}); @override State<WalletPage> createState() => _WalletPageState(); }
class _WalletPageState extends State<WalletPage> {
  int? expandedCardIndex; 
  bool isScanningNFC = false; 
  CardCategory selectedFilter = CardCategory.bank;
  List<CardModel> cards = []; 
  List<Transaction> transactions = [];
  
  @override void initState() { super.initState(); P2pNetManager.instance.pendingHandshake.addListener(_onHandshake); _init(); }
  @override void dispose() { P2pNetManager.instance.pendingHandshake.removeListener(_onHandshake); super.dispose(); }
  
  void _onHandshake() {
    final event = P2pNetManager.instance.pendingHandshake.value;
    if (event == null) return;
    if (event.accepted) {
      MainScreen.of(context)?.navigateToTab(6); 
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Kết nối P2P thành công với ${event.request.alias}!")));
      return;
    }
    final alias = event.request.alias;
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.sky, width: 2)),
      title: const Text("Yêu cầu ghép nối", style: TextStyle(color: Colors.white, fontFamily: 'Rissa', fontSize: 22)),
      content: Text("Thiết bị [$alias] muốn ghép nối P2P. Bạn có đồng ý?", style: const TextStyle(color: Colors.white70, fontFamily: 'Rissa')),
      actions: [
        TextButton(onPressed: () { P2pNetManager.instance.leaveRoom(); Navigator.pop(context); }, child: const Text("Từ chối", style: TextStyle(color: AppColors.rose))),
        TextButton(onPressed: () { P2pNetManager.instance.sendHandshakeAccept(globalDeviceAlias.value); P2pNetManager.instance.connectedDeviceName = alias; MainScreen.of(context)?.navigateToTab(6); Navigator.pop(context); }, child: const Text("Đồng ý", style: TextStyle(color: AppColors.sky))),
      ],
    ));
  }

  void _init() async { 
    if (isMobile) { await requestOfflinePermissions(context); } 
    var d = await LocalDataManager.loadAppData(); 
    if (d != null && mounted) { 
      setState(() { 
        cards = (d["cards"] as List).map((e) => CardModel.fromJson(e)).toList(); 
        transactions = (d["transactions"] as List).map((e) => Transaction.fromJson(e)).toList(); 
      }); 
    } 
  }
  void _save() async => await LocalDataManager.saveAppData(cards, transactions);
  
  void scanNFC() async { 
    if (isDesktop) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thiết bị PC không có chip NFC!", style: TextStyle(fontFamily: 'Rissa')))); return; }
    if(!await NfcManager.instance.isAvailable()) return; setState(()=>isScanningNFC=true); 
    NfcManager.instance.startSession(onDiscovered: (t) async { NfcManager.instance.stopSession(); setState(()=>isScanningNFC=false); _showSaveCardDialog("UID-${DateTime.now().millisecondsSinceEpoch}"); }); 
  }

  void _showSaveCardDialog(String uid) { 
    TextEditingController n = TextEditingController(); CardCategory c = CardCategory.door; 
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => glBox(Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20), child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: n, style: const TextStyle(color: Colors.white, fontFamily: 'Rissa'), decoration: const InputDecoration(labelText: "Tên thẻ", labelStyle: TextStyle(color: Colors.white54, fontFamily: 'Rissa'))), const SizedBox(height: 20), Wrap(spacing: 10, children: [ChoiceChip(label: const Text("Cửa", style: TextStyle(fontFamily: 'Rissa')), selected: c==CardCategory.door, onSelected: (_)=>setS(()=>c=CardCategory.door)), ChoiceChip(label: const Text("Xe", style: TextStyle(fontFamily: 'Rissa')), selected: c==CardCategory.parking, onSelected: (_)=>setS(()=>c=CardCategory.parking)), ChoiceChip(label: const Text("Bank", style: TextStyle(fontFamily: 'Rissa')), selected: c==CardCategory.bank, onSelected: (_)=>setS(()=>c=CardCategory.bank))]), const SizedBox(height: 20), ElevatedButton(onPressed: () { setState(() { cards.add(CardModel(n.text.isEmpty?"New":n.text, uid, Colors.blueAccent, Colors.grey, c)); _save(); }); Navigator.pop(ctx); }, child: const Text("Lưu", style: TextStyle(fontFamily: 'Rissa')))])), Theme.of(context).brightness == Brightness.dark))); 
  }
  
  void _openQuickPay() { 
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (c) => glBox(Column(children: [const SizedBox(height: 20), const Text("Quick Pay", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Rissa')), Expanded(child: ListView(children: cards.where((e)=>e.category==CardCategory.bank).map((e)=>Padding(padding: const EdgeInsets.all(10), child: _buildCard(e))).toList()))]), Theme.of(context).brightness == Brightness.dark)); 
  }
  
  Widget _buildCard(CardModel c) {
    IconData catIcon = c.category == CardCategory.bank ? Icons.credit_card_outlined : c.category == CardCategory.door ? Icons.door_front_door_outlined : Icons.local_parking_outlined;
    return Container(
      height: 160,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c.color1, c.color2.withAlpha(200)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(40), width: 1),
        boxShadow: [
          BoxShadow(color: c.color1.withAlpha(90), blurRadius: 28, offset: const Offset(0, 10)),
          BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 17, fontFamily: 'Rissa', fontWeight: FontWeight.w700)),
          Icon(catIcon, color: Colors.white.withAlpha(190), size: 22),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c.number, style: const TextStyle(color: Colors.white, fontSize: 17, fontFamily: 'Rissa', fontWeight: FontWeight.bold, letterSpacing: 2.5)),
          const SizedBox(height: 4),
          Container(width: 36, height: 3, decoration: BoxDecoration(color: Colors.white.withAlpha(80), borderRadius: BorderRadius.circular(2))),
        ]),
      ]),
    );
  }

  Widget _filterBtn(String label, CardCategory cat, IconData icon) {
    bool s = selectedFilter == cat;
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); setState(() { selectedFilter = cat; expandedCardIndex = null; }); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 230), curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: s ? AppColors.amber.withAlpha(30) : Colors.white.withAlpha(12),
          border: Border.all(color: s ? AppColors.amber : Colors.white.withAlpha(25), width: 1.5),
          boxShadow: s ? [BoxShadow(color: AppColors.amber.withAlpha(65), blurRadius: 16)] : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: s ? AppColors.amber : AppColors.textSec),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: s ? AppColors.amber : AppColors.textSec, fontWeight: FontWeight.bold, fontFamily: 'Rissa', fontSize: 13)),
        ]),
      ),
    );
  }

  @override Widget build(BuildContext context) {
    bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return Stack(
      children: [
        Column(
          children: [
            tabHeader(
              "My Wallet", AppColors.amber,
              subtitle: "${cards.length} thẻ đã lưu",
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NeonButton(Icons.nfc_outlined, AppColors.amber, scanNFC),
                  const SizedBox(width: 10),
                  NeonButton(Icons.settings_outlined, AppColors.textSec, () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage(onClearData: () => setState(() { cards.clear(); transactions.clear(); LocalDataManager.clearAllData(); }))))),
                ]
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              child: Row(
                children: [
                  _filterBtn("Ngân Hàng", CardCategory.bank, Icons.credit_card_outlined),
                  _filterBtn("Thẻ Cửa", CardCategory.door, Icons.door_front_door_outlined),
                  _filterBtn("Thẻ Xe", CardCategory.parking, Icons.local_parking_outlined),
                ]
              ),
            ),
            Expanded(
              child: cards.where((c) => c.category == selectedFilter).isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min, 
                      children: [
                        Icon(Icons.credit_card_off_outlined, size: 52, color: AppColors.textMuted),
                        SizedBox(height: 14),
                        Text("Chưa có thẻ nào", style: TextStyle(color: AppColors.textSec, fontSize: 15, fontFamily: 'Rissa')),
                        SizedBox(height: 6),
                        Text("Chạm + để scan NFC", style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontFamily: 'Rissa')),
                      ]
                    )
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8).copyWith(bottom: 120),
                    children: cards.where((c) => c.category == selectedFilter).map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildCard(c),
                    )).toList(),
                  ),
            ),
          ]
        ),
        if (!isLandscape)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: GestureDetector(
              onVerticalDragEnd: (d) { if (d.primaryVelocity! < -100) _openQuickPay(); },
              onTap: _openQuickPay,
              child: Container(
                height: 25, color: Colors.transparent, alignment: Alignment.bottomCenter, padding: const EdgeInsets.only(bottom: 8),
                child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(10)))
              )
            )
          ),
      ]
    );
  }
}

class SettingsPage extends StatefulWidget { final VoidCallback onClearData; const SettingsPage({super.key, required this.onClearData}); @override State<SettingsPage> createState() => _SettingsPageState(); }
class _SettingsPageState extends State<SettingsPage> { 
  String folderSizeStr = "Đang tính..."; String osVersion = "Đang tải..."; bool isRooted = false; bool isDevMode = false;
  @override void initState() { super.initState(); _loadSystemInfo(); } 
  Future<void> _loadSystemInfo() async { 
    int sizeBytes = await LocalDataManager.getFolderSize(); DeviceInfoPlugin deviceInfo = DeviceInfoPlugin(); String os = ""; 
    if (Platform.isAndroid) { AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo; os = "Android ${androidInfo.version.release}"; } 
    try { isRooted = await SafeDevice.isJailBroken; isDevMode = await SafeDevice.isDevelopmentModeEnable; } catch (e) {} 
    if (mounted) setState(() { folderSizeStr = "${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB"; osVersion = os; }); 
  } 
  Widget _colorBtn(Color? color, String label) { bool isSelected = customColorNotifier.value == color; return GestureDetector(onTap: () { HapticFeedback.selectionClick(); customColorNotifier.value = color; }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: color ?? Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(20), border: isSelected ? Border.all(color: Colors.white, width: 2) : null), child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Rissa')))); } 
  Widget _infoRow(String title, String val, Color valColor) => Padding(padding: const EdgeInsets.fromLTRB(16, 6, 16, 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(color: AppColors.textSec, fontSize: 14, fontFamily: 'Rissa')), Text(val, style: TextStyle(color: valColor, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Rissa'))]));

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white),
        title: ShaderMask(shaderCallback: (b) => const LinearGradient(colors: [Colors.white, AppColors.amber]).createShader(b), child: const Text("Cài đặt", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 22, fontFamily: 'Rissa'))),
      ),
      body: Stack(children: [
        Positioned.fill(child: auroraBackground(AppColors.amber)),
        ListView(padding: const EdgeInsets.all(20), children: [
          const SizedBox(height: 4),
          _settingsSection("Giao diện", Icons.palette_outlined, AppColors.amber, [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Màu chữ ứng dụng", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Rissa')),
              const SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 8, children: [ _colorBtn(null, "Mặc định"), _colorBtn(AppColors.sky, "Xanh trời"), _colorBtn(AppColors.teal, "Xanh ngọc"), _colorBtn(AppColors.amber, "Vàng"), _colorBtn(AppColors.rose, "Hồng") ]),
            ])),
          ]),
          const SizedBox(height: 20),
          _settingsSection("Thiết bị", Icons.memory_outlined, AppColors.violet, [ _infoRow("Hệ điều hành", osVersion.isEmpty ? "N/A" : osVersion, AppColors.teal), _infoRow("Trạng thái Root", isRooted ? "Đã Root" : "An toàn", isRooted ? AppColors.rose : AppColors.teal), _infoRow("USB Debugging", isDevMode ? "Đang bật" : "Đã tắt", isDevMode ? AppColors.amber : AppColors.textSec) ]),
          const SizedBox(height: 20),
          _settingsSection("Mạng & Bảo Mật", Icons.security, AppColors.rose, [
            ValueListenableBuilder<bool>(
              valueListenable: isStealthMode,
              builder: (c, isStealth, _) => SwitchListTile(
                title: const Text("Stealth Mode (Ẩn danh)", style: TextStyle(color: Colors.white, fontFamily: 'Rissa')),
                subtitle: const Text("Ngụy trang tên thiết bị khi quét Radar", style: TextStyle(color: Colors.white54, fontSize: 11)),
                value: isStealth,
                activeColor: AppColors.sky,
                onChanged: (_) => toggleStealthMode(),
              )
            ),
          ]),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () { widget.onClearData(); Navigator.pop(context); },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: AppColors.rose.withAlpha(20), border: Border.all(color: AppColors.rose.withAlpha(80), width: 1), boxShadow: [BoxShadow(color: AppColors.rose.withAlpha(40), blurRadius: 16)]),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.delete_forever_outlined, color: AppColors.rose, size: 20), SizedBox(width: 10), Text("Xóa toàn bộ dữ liệu", style: TextStyle(color: AppColors.rose, fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Rissa')) ]),
            ),
          ),
        ]),
      ]),
    );
  }
  Widget _settingsSection(String title, IconData icon, Color accent, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white.withAlpha(10), border: Border.all(color: Colors.white.withAlpha(20), width: 1)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8), child: Row(children: [ Icon(icon, color: accent, size: 18), const SizedBox(width: 8), Text(title, style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Rissa')) ])),
      const Divider(color: Colors.white10, height: 1), ...children, const SizedBox(height: 8)
    ]),
  );
}

class LocketCameraTab extends StatefulWidget { final bool isActive; final List<Transaction> transactions; final Function(Transaction) onNewTransaction; const LocketCameraTab({super.key, required this.isActive, required this.transactions, required this.onNewTransaction}); @override State<LocketCameraTab> createState() => _LocketCameraTabState(); }
class _LocketCameraTabState extends State<LocketCameraTab> with WidgetsBindingObserver {
  CameraController? _c; bool _flash = false; @override void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); if (widget.isActive) _init(); }
  @override void didUpdateWidget(LocketCameraTab old) { super.didUpdateWidget(old); if (widget.isActive && !old.isActive) { _init(); } else if (!widget.isActive && old.isActive) _dispose(); }
  @override void didChangeAppLifecycleState(AppLifecycleState s) { if (s == AppLifecycleState.paused) { _dispose(); } else if (s == AppLifecycleState.resumed && widget.isActive) _init(); }
  @override void dispose() { WidgetsBinding.instance.removeObserver(this); _dispose(); super.dispose(); }
  void _init() async { if (cameras.isEmpty || isDesktop) return; await _dispose(); _c = CameraController(cameras[0], ResolutionPreset.high, enableAudio: false); try { await _c!.initialize(); } catch (e) { _c = null; return; } if (mounted) setState(() {}); }
  Future<void> _dispose() async { final old = _c; _c = null; await old?.dispose(); }
  void _take() async { if (_c == null) return; final i = await _c!.takePicture(); if (!mounted) return; final t = await Navigator.push(context, MaterialPageRoute(builder: (_) => LocketEditorScreen(imageFile: File(i.path)))); if (t != null) widget.onNewTransaction(t); }
  @override Widget build(BuildContext context) {
    if (!widget.isActive) return const Center(child: Text("Camera paused", style: TextStyle(fontFamily: 'Rissa', color: AppColors.textSec)));
    if (_c == null || !_c!.value.isInitialized) { return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [ CircularProgressIndicator(color: AppColors.coral, strokeWidth: 2), SizedBox(height: 16), Text("Khởi động camera...", style: TextStyle(color: AppColors.textSec, fontFamily: 'Rissa', fontSize: 13)), ])); }
    return Column(children: [
      Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 0), child: ClipRRect(borderRadius: BorderRadius.circular(36), child: Stack(fit: StackFit.expand, children: [
        CameraPreview(_c!),
        Container(decoration: BoxDecoration(gradient: RadialGradient(colors: [Colors.transparent, Colors.black.withAlpha(80)], radius: 1.2))),
        Positioned(top: 16, right: 16, child: GestureDetector(onTap: () => setState(() { _flash = !_flash; _c!.setFlashMode(_flash ? FlashMode.torch : FlashMode.off); }),
          child: Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withAlpha(80), border: Border.all(color: Colors.white.withAlpha(60), width: 1)),
            child: Icon(_flash ? Icons.flash_on : Icons.flash_off_rounded, color: _flash ? AppColors.amber : Colors.white, size: 20)))),
      ])))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        NeonButton(Icons.photo_library_outlined, AppColors.coral, () async { var i = await ImagePicker().pickImage(source: ImageSource.gallery); if (i != null && mounted) { final t = await Navigator.push(context, MaterialPageRoute(builder: (_) => LocketEditorScreen(imageFile: File(i.path)))); if (t != null) widget.onNewTransaction(t); } }),
        GestureDetector(onTap: _take, child: Container(height: 76, width: 76, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [AppColors.coral, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: [BoxShadow(color: AppColors.coral.withAlpha(100), blurRadius: 20, spreadRadius: 2)]), child: Center(child: Container(height: 60, width: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(220)))))),
        NeonButton(Icons.flip_camera_ios_outlined, AppColors.coral, _init),
      ])),
      GestureDetector(
        onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (c) => HistoryBottomSheet(transactions: widget.transactions)),
        child: const Padding(padding: EdgeInsets.only(bottom: 100), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [ Text("Lịch sử", style: TextStyle(color: AppColors.coral, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Rissa')), Icon(Icons.keyboard_arrow_down, color: AppColors.coral), ])),
      ),
    ]);
  }
}
class HistoryBottomSheet extends StatelessWidget { final List<Transaction> transactions; const HistoryBottomSheet({super.key, required this.transactions}); @override Widget build(BuildContext context) { Map<String, List<Transaction>> grouped = {}; List<Transaction> sorted = List.from(transactions)..sort((a, b) => b.date.compareTo(a.date)); for (var t in sorted) { String date = DateFormat('EEE, dd/MM/yyyy').format(t.date); grouped.putIfAbsent(date, () => []); grouped[date]!.add(t); } return DraggableScrollableSheet(initialChildSize: 0.9, maxChildSize: 0.9, minChildSize: 0.5, builder: (_, controller) { return glBox(Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), child: Column(children: [Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))), const SizedBox(height: 20), const Text("Lịch sử chi tiêu", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Rissa')), const SizedBox(height: 20), Expanded(child: grouped.isEmpty ? const Center(child: Text("Chưa có giao dịch", style: TextStyle(color: Colors.white54, fontSize: 16, fontFamily: 'Rissa'))) : ListView(controller: controller, children: grouped.entries.map((entry) { return Padding(padding: const EdgeInsets.only(bottom: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(entry.key, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Rissa')), const SizedBox(height: 10), GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: entry.value.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.8), itemBuilder: (_, i) { final t = entry.value[i]; return ClipRRect(borderRadius: BorderRadius.circular(15), child: Stack(fit: StackFit.expand, children: [if (t.imagePath != null) Image.file(File(t.imagePath!), fit: BoxFit.cover) else Container(color: Colors.grey.shade900), Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.9), Colors.transparent]))), Positioned(bottom: 5, left: 5, right: 5, child: Text("${t.type == TransactionType.expense ? '-' : '+'}${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(t.amount)}", style: TextStyle(color: t.type == TransactionType.expense ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Rissa')))])); })])); }).toList()))])), true, r: 30); }); } }
class LocketEditorScreen extends StatefulWidget { final File imageFile; const LocketEditorScreen({super.key, required this.imageFile}); @override State<LocketEditorScreen> createState() => _LocketEditorScreenState(); }
class _LocketEditorScreenState extends State<LocketEditorScreen> { String a = "0", n = ""; TransactionType t = TransactionType.expense; @override Widget build(BuildContext context) { return Scaffold(backgroundColor: Colors.black, body: Stack(fit: StackFit.expand, children: [Image.file(widget.imageFile, fit: BoxFit.cover), Container(color: Colors.black54), SafeArea(child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)), TextButton(onPressed: () => Navigator.pop(context, Transaction(widget.imageFile.path, double.parse(a), n, DateTime.now(), t)), child: const Text("Post", style: TextStyle(color: Colors.amber, fontSize: 18, fontFamily: 'Rissa')))]), const Spacer(), TextField(textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontFamily: 'Rissa'), decoration: const InputDecoration(hintText: "Ghi chú...", border: InputBorder.none, hintStyle: TextStyle(color: Colors.white54, fontFamily: 'Rissa')), onChanged: (v) => n = v), GestureDetector(onTap: () => setState(() => t = t == TransactionType.expense ? TransactionType.income : TransactionType.expense), child: Text("${t == TransactionType.expense ? '-' : '+'}$a", style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Rissa'))), const Spacer(), SizedBox(height: 250, child: GridView.count(crossAxisCount: 3, childAspectRatio: 2, physics: const NeverScrollableScrollPhysics(), children: ["1","2","3","4","5","6","7","8","9","000","0","<"].map((k) => GestureDetector(onTap: () => setState(() { if (k == "<") { a = a.length > 1 ? a.substring(0, a.length - 1) : "0"; } else { a = a == "0" ? k : a + k; } }), child: Center(child: Text(k, style: const TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Rissa'))))).toList()))]))])); } }

class GameSpaceTab extends StatefulWidget { const GameSpaceTab({super.key}); @override State<GameSpaceTab> createState() => _GameSpaceTabState(); }
class _GameSpaceTabState extends State<GameSpaceTab> { 
  List<Application> apps = []; bool isLoading = true; 
  @override void initState() { super.initState(); _loadGamesFast(); } 
  Future<void> _loadGamesFast() async { if(isDesktop)return; List<Application> allApps = await DeviceApps.getInstalledApplications(includeAppIcons: false, includeSystemApps: false, onlyAppsWithLaunchIntent: true); var rawGames = allApps.where((app) => app.category == ApplicationCategory.game || app.packageName.toLowerCase().contains("game") || app.packageName.toLowerCase().contains("tencent") || app.packageName.toLowerCase().contains("mojang")).toList(); List<Application> gamesWithIcon = []; for (var app in rawGames) { Application? appWithIcon = await DeviceApps.getApp(app.packageName, true); if (appWithIcon != null) gamesWithIcon.add(appWithIcon); } if (mounted) setState(() { apps = gamesWithIcon; isLoading = false; }); } 
  @override Widget build(BuildContext context) {
    return Column(children: [
      tabHeader("Game Space", AppColors.cyan, subtitle: "${apps.length} game"),
      Expanded(child: isLoading
        ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: AppColors.cyan, strokeWidth: 2), SizedBox(height: 14), Text("Loading games...", style: TextStyle(color: AppColors.textSec, fontFamily: 'Rissa', fontSize: 13))]))
        : apps.isEmpty
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.sports_esports_outlined, size: 52, color: AppColors.textMuted), SizedBox(height: 14), Text("Chưa có game", style: TextStyle(color: AppColors.textSec, fontSize: 15, fontFamily: 'Rissa'))]))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 110),
              itemCount: apps.length,
              itemBuilder: (context, index) {
                Application app = apps[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white.withAlpha(10), border: Border.all(color: Colors.white.withAlpha(18), width: 1)),
                  child: Row(children: [
                    if (app is ApplicationWithIcon) ClipRRect(borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)), child: Image.memory(app.icon, width: 70, height: 70, fit: BoxFit.cover)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(app.appName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Rissa')), const SizedBox(height: 4),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: AppColors.cyan.withAlpha(20), borderRadius: BorderRadius.circular(6)), child: Text(app.packageName, style: const TextStyle(color: AppColors.cyan, fontSize: 10, fontFamily: 'Rissa'), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ])),
                    Padding(padding: const EdgeInsets.only(right: 14), child: GestureDetector(onTap: () => DeviceApps.openApp(app.packageName), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.cyan.withAlpha(25), border: Border.all(color: AppColors.cyan.withAlpha(80), width: 1.5), boxShadow: [BoxShadow(color: AppColors.cyan.withAlpha(50), blurRadius: 12)]), child: const Icon(Icons.play_arrow_rounded, color: AppColors.cyan, size: 22)))),
                  ]),
                );
              }),
      ),
    ]);
  }
}

class NotiLogTab extends StatefulWidget { const NotiLogTab({super.key}); @override State<NotiLogTab> createState() => _NotiLogTabState(); }
class _NotiLogTabState extends State<NotiLogTab> { 
  List<NotiModel> notifications = []; bool isSelectionMode = false; Set<int> selectedIndexes = {};
  StreamSubscription? _notiSub;
  @override void initState() { super.initState(); _initNotiListener(); }
  @override void dispose() { _notiSub?.cancel(); super.dispose(); }
  Future<void> _initNotiListener() async { 
    if(isDesktop)return;
    notifications = await LocalDataManager.loadNotis(); if (mounted) setState(() {}); 
    bool isGranted = await NotificationListenerService.isPermissionGranted(); 
    if (!isGranted) await NotificationListenerService.requestPermission(); 
    _notiSub = NotificationListenerService.notificationsStream.listen((event) async { 
      if (event.packageName == null || event.title == null) return; 
      if (event.title!.isEmpty && (event.content == null || event.content!.isEmpty)) return; 
      if (mounted) setState(() { notifications.insert(0, NotiModel(event.id.toString(), event.packageName!, event.title ?? "Không", event.content ?? "", DateTime.now())); }); 
      await LocalDataManager.saveNotis(notifications); 
    }); 
  } 
  void _deleteSelected() async { List<NotiModel> remaining = []; for (int i = 0; i < notifications.length; i++) { if (!selectedIndexes.contains(i)) remaining.add(notifications[i]); } setState(() { notifications = remaining; selectedIndexes.clear(); isSelectionMode = false; }); await LocalDataManager.saveNotis(notifications); HapticFeedback.vibrate(); } 
  @override Widget build(BuildContext context) {
    return Column(children: [
      tabHeader("Noti Log", AppColors.violet,
        subtitle: "${notifications.length} thông báo",
        trailing: isSelectionMode
          ? Row(children: [ NeonButton(Icons.select_all, AppColors.violet, () => setState(() => selectedIndexes = Set.from(Iterable.generate(notifications.length)))), const SizedBox(width: 8), NeonButton(Icons.delete_outline, AppColors.rose, _deleteSelected), const SizedBox(width: 8), NeonButton(Icons.close, AppColors.textSec, () => setState(() { isSelectionMode = false; selectedIndexes.clear(); })), ])
          : const Icon(Icons.history_outlined, color: AppColors.textSec, size: 22),
      ),
      Expanded(child: notifications.isEmpty
        ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [ Icon(Icons.notifications_off_outlined, size: 52, color: AppColors.textMuted), SizedBox(height: 14), Text("Nhật ký trống", style: TextStyle(color: AppColors.textSec, fontSize: 15, fontFamily: 'Rissa')), ]))
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 110), itemCount: notifications.length,
            itemBuilder: (context, index) {
              NotiModel noti = notifications[index]; bool isSelected = selectedIndexes.contains(index);
              return GestureDetector(
                onLongPress: () { HapticFeedback.heavyImpact(); setState(() { isSelectionMode = true; selectedIndexes.add(index); }); },
                onTap: () { if (isSelectionMode) setState(() { if (isSelected) { selectedIndexes.remove(index); } else { selectedIndexes.add(index); } if (selectedIndexes.isEmpty) isSelectionMode = false; }); },
                child: Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: isSelected ? AppColors.rose.withAlpha(20) : Colors.white.withAlpha(10), border: Border.all(color: isSelected ? AppColors.rose.withAlpha(80) : Colors.white.withAlpha(18), width: 1)),
                  child: Row(children: [
                    Container(width: 4, height: 72, decoration: BoxDecoration(borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)), color: AppColors.violet.withAlpha(isSelected ? 60 : 180))),
                    const SizedBox(width: 12),
                    if (isSelectionMode) ...[Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? AppColors.rose : AppColors.textSec, size: 20), const SizedBox(width: 10)],
                    Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Expanded(child: Text(noti.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Rissa'), maxLines: 1, overflow: TextOverflow.ellipsis)), Text(DateFormat('HH:mm').format(noti.timestamp), style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Rissa')), ]), const SizedBox(height: 3),
                      Text(noti.body, style: const TextStyle(color: AppColors.textSec, fontSize: 12, fontFamily: 'Rissa'), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ]))),
                    const SizedBox(width: 12),
                  ]),
                ),
              );
            }),
      ),
    ]);
  }
}

class FullscreenPlayer extends StatefulWidget { 
  final Map<String,String> song; final AudioPlayer player; final AndroidLoudnessEnhancer le; final AndroidEqualizer eq; 
  const FullscreenPlayer(this.song, this.player, this.le, this.eq, {super.key}); 
  @override State<FullscreenPlayer> createState() => _FullscreenState(); 
}
class _FullscreenState extends State<FullscreenPlayer> {
  double v = 1.0; int t = 0; Timer? _timer; bool _isP = false; StreamSubscription? _sub, _pSub, _dSub;
  List<Map<String, dynamic>> lrc = []; int curLine = 0; final FixedExtentScrollController _sc = FixedExtentScrollController();
  List<double> eqGains = [0.0, 0.0, 0.0, 0.0, 0.0]; double currentPos = 0; double maxPos = 1;
  
  @override void initState() {
    super.initState();
    _parseLrc(); _isP = widget.player.playing; 
    _sub = widget.player.playingStream.listen((p) { if(mounted) setState((){ _isP = p; }); });
    _pSub = widget.player.positionStream.listen((p) {
      if(!mounted) return; setState(() => currentPos = p.inMilliseconds.toDouble());
      if(lrc.isEmpty) return;
      double sec = p.inMilliseconds / 1000.0; int ni = lrc.length - 1;
      for (int i=0; i<lrc.length; i++) { if (sec < lrc[i]["time"]) { ni = i - 1; break; } }
      if (ni < 0) ni = 0;
      if (ni != curLine) { setState(() => curLine = ni); if (_sc.hasClients) _sc.animateToItem(curLine, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); }
    });
    _dSub = widget.player.durationStream.listen((d) { if (d != null && mounted) setState(() => maxPos = d.inMilliseconds.toDouble()); });
  }
  void _parseLrc() {
    for (var line in mockLrcData.split('\n')) {
      if (line.trim().isEmpty) continue; int b1 = line.indexOf('['); int b2 = line.indexOf(']');
      if (b1 != -1 && b2 != -1) { List<String> p = line.substring(b1+1, b2).split(':'); lrc.add({"time": double.parse(p[0]) * 60 + double.parse(p[1]), "text": line.substring(b2+1).trim()}); }
    }
  }
  String formatDuration(double ms) { int s = ms ~/ 1000; int m = s ~/ 60; return "$m:${(s%60).toString().padLeft(2, '0')}"; }
  @override void dispose() { _timer?.cancel(); _sub?.cancel(); _pSub?.cancel(); _dSub?.cancel(); _sc.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return Container(color: AppColors.bg, child: Column(children: [
      const SizedBox(height: 50), Row(children: [IconButton(icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 36), onPressed: () => Navigator.pop(context))]), const SizedBox(height: 10),
      Container(width: 250, height: 250, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [AppColors.rose, AppColors.violet]), boxShadow: [BoxShadow(color: AppColors.rose.withAlpha(50), blurRadius: 40, spreadRadius: 5)]), child: const Center(child: Icon(Icons.music_note, size: 80, color: Colors.white24))), const SizedBox(height: 20),
      Text(widget.song['title']!, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'Rissa'), maxLines: 1),
      Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: ListWheelScrollView.useDelegate(
        controller: _sc, itemExtent: 60, physics: const FixedExtentScrollPhysics(), onSelectedItemChanged: (i) => setState(()=>curLine=i),
        childDelegate: ListWheelChildBuilderDelegate(childCount: lrc.length, builder: (c, i) {
          bool isHi = i == curLine; return AnimatedDefaultTextStyle(duration: const Duration(milliseconds: 300), style: TextStyle(color: isHi ? Colors.white : Colors.white38, fontSize: isHi ? 24 : 16, fontWeight: isHi ? FontWeight.bold : FontWeight.normal, fontFamily: 'Rissa'), child: Center(child: Text(lrc[i]["text"]!)));
        })
      ))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 30), child: Row(children: [ Text(formatDuration(currentPos), style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Rissa')), Expanded(child: Slider( value: currentPos.clamp(0.0, maxPos > 0 ? maxPos : 1.0), min: 0.0, max: maxPos > 0 ? maxPos : 1.0, activeColor: AppColors.rose, inactiveColor: Colors.white12, onChangeEnd: (v) => widget.player.seek(Duration(milliseconds: v.toInt())), onChanged: (v) => setState(() => currentPos = v))), Text(formatDuration(maxPos), style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Rissa')), ])),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: Row(children: [ const Icon(Icons.volume_down, color: Colors.white54), Expanded(child: Slider(value: v, min: 0.0, max: 2.0, activeColor: v > 1.0 ? AppColors.rose : AppColors.sky, onChanged: (nv) async { setState(() => v = nv); if(nv <= 1.0) { await widget.player.setVolume(nv); widget.le.setEnabled(false); } else { await widget.player.setVolume(1.0); await widget.le.setEnabled(true); await widget.le.setTargetGain((nv - 1.0) * 2000.0); } })), Text("${(v*100).toInt()}%", style: TextStyle(color: v > 1.0 ? AppColors.rose : Colors.white, fontFamily: 'Rissa', fontWeight: FontWeight.bold)) ])),
      const SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        NeonButton(Icons.timer, AppColors.sky, () { setState(()=>t=15); _timer?.cancel(); _timer = Timer(const Duration(minutes: 15), ()=>widget.player.pause()); }, label: t>0?"${t}m":"Timer"),
        GestureDetector(onTap: () => _isP ? widget.player.pause() : widget.player.play(), child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.rose, boxShadow: [BoxShadow(color: AppColors.rose.withAlpha(100), blurRadius: 20)]), child: Icon(_isP ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 40))),
        NeonButton(Icons.equalizer, AppColors.violet, () {
          showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (_) => StatefulBuilder(builder: (c, setS) => glBox(Container(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text("Real EQ Settings", style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Rissa')), const SizedBox(height: 30),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(5, (i) => Expanded(child: Column(children: [ SizedBox(height: 120, child: RotatedBox(quarterTurns: 3, child: Slider(value: eqGains[i], min: -1.0, max: 1.0, onChanged: (nv) async { setS(() => eqGains[i] = nv); widget.eq.setEnabled(true); final p = await widget.eq.parameters; final bands = p.bands; if(i < bands.length) { p.bands[i].setGain(nv); } }, activeColor: AppColors.rose))), Text(["60","230","910","3k","14k"][i], style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'Rissa')) ]))))
          ])), true)));
        }, label: "EQ"),
      ]), const SizedBox(height: 60),
    ]));
  }
}

class MusicTab extends StatefulWidget { const MusicTab({super.key}); @override State<MusicTab> createState() => _MusicTabState(); }
class _MusicTabState extends State<MusicTab> {
  late AudioPlayer _p; late AndroidLoudnessEnhancer _le; late AndroidEqualizer _eq;
  bool isP = false; int cur = 0; StreamSubscription? _playerSub;
  @override void initState() { 
    super.initState(); 
    _le = AndroidLoudnessEnhancer(); _eq = AndroidEqualizer();
    _p = AudioPlayer(audioPipeline: AudioPipeline(androidAudioEffects: [_le, _eq]));
    _playerSub = _p.playingStream.listen((s) { if (mounted) setState(() => isP = s); }); 
    if (globalLocalSongs.value.isNotEmpty) _p.setAudioSource(AudioSource.file(globalLocalSongs.value[0]["path"]!)); 
  }
  @override void dispose() { _playerSub?.cancel(); _p.dispose(); super.dispose(); }
  void _play(int i) async { cur = i; await _p.setAudioSource(AudioSource.file(globalLocalSongs.value[i]["path"]!)); _p.play(); }
  @override Widget build(BuildContext context) {
    return Column(children: [
      tabHeader("Music", AppColors.rose, subtitle: "${globalLocalSongs.value.length} bài", trailing: NeonButton(Icons.add, AppColors.rose, () async { var r = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.audio); if (r != null) { final newList = List<Map<String, String>>.from(globalLocalSongs.value)..addAll(r.paths.map((p) => {"title": p!.split('/').last, "artist": "Local", "path": p, "cover": ""})); globalLocalSongs.value = newList; LocalDataManager.saveLocalMusic(newList); setState(() {}); } }), ),
      Expanded(child: globalLocalSongs.value.isEmpty
        ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [ Icon(Icons.music_off_outlined, size: 52, color: AppColors.textMuted), SizedBox(height: 14), Text("Chưa có bài nhạc", style: TextStyle(color: AppColors.textSec, fontSize: 15, fontFamily: 'Rissa')), SizedBox(height: 6), Text("Nhấn + để thêm nhạc local", style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontFamily: 'Rissa')), ]))
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: cur >= 0 ? 170 : 110), itemCount: globalLocalSongs.value.length,
            itemBuilder: (c, i) {
              bool isCur = cur == i; bool playing = isCur && isP;
              return GestureDetector(
                onTap: () { HapticFeedback.lightImpact(); _play(i); },
                child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13), decoration: BoxDecoration( borderRadius: BorderRadius.circular(18), color: Colors.white.withAlpha(10), border: Border.all(color: isCur ? AppColors.rose.withAlpha(80) : Colors.white.withAlpha(18), width: 1), boxShadow: isCur ? [BoxShadow(color: AppColors.rose.withAlpha(50), blurRadius: 20)] : [], ),
                  child: Row(children: [
                    Container(width: 50, height: 50, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [AppColors.rose, AppColors.violet])), child: Icon(playing ? Icons.graphic_eq : Icons.music_note, color: Colors.white, size: 24)), const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(globalLocalSongs.value[i]["title"]!, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Rissa'), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), const Text("Local Audio File", style: TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Rissa')) ])),
                    if (isCur) Icon(isP ? Icons.graphic_eq : Icons.play_arrow_rounded, color: AppColors.rose, size: 26),
                  ]),
                ),
              );
            }),
      ),
      if (globalLocalSongs.value.isNotEmpty)
        GestureDetector(
          onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => FullscreenPlayer(globalLocalSongs.value[cur], _p, _le, _eq)),
          child: Container(margin: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 110), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: AppColors.rose.withAlpha(20), border: Border.all(color: AppColors.rose.withAlpha(70), width: 1), boxShadow: [BoxShadow(color: AppColors.rose.withAlpha(50), blurRadius: 20)]),
            child: ClipRRect(borderRadius: BorderRadius.circular(24), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), child: Row(children: [
                Container(width: 38, height: 38, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppColors.rose.withAlpha(40)), child: const Icon(Icons.music_note, color: AppColors.rose, size: 20)), const SizedBox(width: 12),
                Expanded(child: Text(globalLocalSongs.value[cur]["title"]!, style: const TextStyle(color: Colors.white, fontFamily: 'Rissa', fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)), const SizedBox(width: 10),
                GestureDetector(onTap: () => isP ? _p.pause() : _play(cur), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.rose.withAlpha(30), border: Border.all(color: AppColors.rose.withAlpha(80), width: 1.5)), child: Icon(isP ? Icons.pause_rounded : Icons.play_arrow_rounded, color: AppColors.rose, size: 22))),
              ])))),
          ),
        ),
    ]);
  }
}

class NotesTab extends StatefulWidget { const NotesTab({super.key}); @override State<NotesTab> createState() => _NotesTabState(); }
class _NotesTabState extends State<NotesTab> {
  List<NoteModel> notes = []; @override void initState() { super.initState(); _load(); }
  void _load() async { notes = await LocalDataManager.loadNotes(); setState(() {}); }
  @override Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: Colors.transparent, body: Stack(children: [
      ...notes.map((n) => Positioned(left: n.dx, top: n.dy, child: GestureDetector(
        onPanUpdate: (d) => setState(() { n.dx += d.delta.dx; n.dy += d.delta.dy; }),
        onPanEnd: (d) { LocalDataManager.saveNotes(notes); },
        child: Container(width: n.w, height: n.h, decoration: BoxDecoration(color: RobertColors.note, borderRadius: BorderRadius.circular(10), border: Border.all(color: RobertColors.noteBorder, width: 2), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)]), child: Column(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: const BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            GestureDetector(onTap: () => setState((){ n.isLocked = !n.isLocked; LocalDataManager.saveNotes(notes); }), child: Icon(n.isLocked ? Icons.lock : Icons.edit, size: 16, color: Colors.black54)),
            GestureDetector(onTap: () => setState((){ notes.remove(n); LocalDataManager.saveNotes(notes); }), child: const Icon(Icons.close, size: 18, color: Colors.black54))
          ])),
          Expanded(child: GestureDetector(
            onTap: () { if (n.isLocked) setState((){ n.isDone = !n.isDone; LocalDataManager.saveNotes(notes); }); },
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(fontSize: 18, color: n.isDone ? Colors.black26 : Colors.black87, fontFamily: 'Rissa', decoration: n.isDone ? TextDecoration.lineThrough : null),
              child: n.isLocked ? Padding(padding: const EdgeInsets.all(8), child: Align(alignment: Alignment.topLeft, child: Text(n.text))) : _NoteTextField(note: n, onChanged: (v){ n.text = v; LocalDataManager.saveNotes(notes); })
            )
          ))
        ])),
      ))),
      Positioned(bottom: 110, right: 20, child: glBox(IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: () { notes.add(NoteModel(id: "${DateTime.now().millisecondsSinceEpoch}", type: 's', text: "", dx: 50, dy: 100)); setState(() {}); }), isDark, color: Colors.blueAccent, r: 30)),
    ]));
  }
}

class _NoteTextField extends StatefulWidget {
  final NoteModel note;
  final ValueChanged<String> onChanged;
  const _NoteTextField({required this.note, required this.onChanged});
  @override State<_NoteTextField> createState() => _NoteTextFieldState();
}
class _NoteTextFieldState extends State<_NoteTextField> {
  late final TextEditingController _ctrl;
  @override void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.note.text);
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => TextField(
    controller: _ctrl,
    onChanged: widget.onChanged,
    maxLines: null,
    style: TextStyle(fontSize: widget.note.w * 0.1, fontFamily: 'Rissa'),
    decoration: const InputDecoration(border: InputBorder.none),
  );
}