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

// ================= DESIGN SYSTEM =================
class AppColors {
  static const Color bg = Color(0xFF030303); // OLED Black
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
List<CameraDescription> cameras = [];
final ValueNotifier<List<Map<String, String>>> globalLocalSongs = ValueNotifier([]);

String currentDeviceType = 'phone';
bool isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
bool isMobile = Platform.isAndroid || Platform.isIOS;
Color getAppTextColor(BuildContext c) => customColorNotifier.value ?? Colors.white;

// ================= ALIAS GENERATOR =================
final List<String> _adj = ["Nhanh nhẹn", "Vui vẻ", "Bí ẩn", "Lạnh lùng", "Dễ thương", "Mạnh mẽ", "Thông minh", "Lém lỉnh"];
final List<String> _noun = ["Cà chua", "Trái táo", "Quả cam", "Dưa hấu", "Phi hành gia", "Hiệp sĩ", "Hổ", "Gấu"];
String generateAlias() => "${_adj[math.Random().nextInt(_adj.length)]} ${_noun[math.Random().nextInt(_noun.length)]}";
final ValueNotifier<String> globalDeviceAlias = ValueNotifier(generateAlias());

// ================= AURORA BACKGROUND =================
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

// ================= NEON BUTTON (Animated V2) =================
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
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0, duration: const Duration(milliseconds: 150),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: widget.color.withAlpha(25),
              border: Border.all(color: widget.color.withAlpha(120), width: 1.5),
              boxShadow: [BoxShadow(color: widget.color.withAlpha(_isPressed ? 80 : 40), blurRadius: _isPressed ? 10 : 20, spreadRadius: 2)]
            ),
            child: Icon(widget.icon, color: widget.color, size: 22),
          ),
          if (widget.label != null) ...[
            const SizedBox(height: 8),
            Text(widget.label!, style: TextStyle(color: widget.color, fontSize: 11, fontFamily: 'Rissa', fontWeight: FontWeight.bold, letterSpacing: 0.5))
          ]
        ]),
      )
    );
  }
}

// ================= FLOAT LIQUID GLASS COMPONENT V2 =================
Widget glBox(Widget child, bool isDark, {double r = 24, EdgeInsetsGeometry? p, EdgeInsetsGeometry? m, Color? color, double blur = 25}) {
  return Container(
    margin: m,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: p ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color ?? Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(r),
            border: Border.all(color: Colors.white.withAlpha(25), width: 1.5),
            gradient: LinearGradient(
              colors: [Colors.white.withAlpha(20), Colors.white.withAlpha(0)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 30, spreadRadius: -5),
            ],
          ),
          child: child,
        ),
      ),
    ),
  );
}

Widget buildPCWarning(String title, IconData icon) => Center(child: glBox(Column(mainAxisSize: MainAxisSize.min, children: [
  Icon(icon, size: 60, color: AppColors.amber),
  const SizedBox(height: 20),
  Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Rissa', color: Colors.white)),
  const SizedBox(height: 10),
  const Text("Yêu cầu phần cứng Mobile.\nKhông khả dụng trên PC.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSec, fontSize: 14, fontFamily: 'Rissa')),
]), true, p: const EdgeInsets.all(32)));

// ================= MESH CORE MODELS & ENCRYPTION =================
final List<int> _encKey = utf8.encode("co-op-secret-key-2026");
String encryptMsg(String text) { final bytes = utf8.encode(text); return base64Encode(List.generate(bytes.length, (i) => bytes[i] ^ _encKey[i % _encKey.length])); }
String decryptMsg(String text) { final bytes = base64Decode(text); return utf8.decode(List.generate(bytes.length, (i) => bytes[i] ^ _encKey[i % _encKey.length])); }

class MeshMessage {
  final String id; final String sender; final String content; final int timestamp; final List<String> hops; final String roomId; final String? imagePath;
  MeshMessage({required this.id, required this.sender, required this.content, required this.timestamp, required this.hops, required this.roomId, this.imagePath});
  Map<String, dynamic> toJson() => {'id': id, 'sender': sender, 'content': content, 'timestamp': timestamp, 'hops': hops, 'roomId': roomId};
  factory MeshMessage.fromJson(Map<String, dynamic> json) => MeshMessage(id: json['id'], sender: json['sender'], content: json['content'], timestamp: json['timestamp'], hops: List<String>.from(json['hops']), roomId: json['roomId']);
}

final ValueNotifier<MeshMessage?> globalChatNoti = ValueNotifier(null);
final String myDeviceId = "ID_${math.Random().nextInt(999999)}_${DateTime.now().millisecondsSinceEpoch}";

// ================= MAIN & DATA MANAGER =================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isMobile) { try { cameras = await availableCameras(); } catch (e) {} if (Platform.isAndroid) { AndroidDeviceInfo info = await DeviceInfoPlugin().androidInfo; if ((info.displayMetrics.widthPx / info.displayMetrics.xDpi) > 7.0) currentDeviceType = 'tablet'; } } else { currentDeviceType = 'laptop'; }
  await LocalDataManager.initFolder(); globalLocalSongs.value = await LocalDataManager.loadLocalMusic(); runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override Widget build(BuildContext context) { return ValueListenableBuilder<bool>(valueListenable: isDarkModeNotifier, builder: (context, isDark, child) => ValueListenableBuilder<Color?>(valueListenable: customColorNotifier, builder: (context, customColor, child) => MaterialApp(title: 'Co-op', debugShowCheckedModeBanner: false, themeMode: ThemeMode.dark, theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: AppColors.bg, fontFamily: 'Rissa'), darkTheme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: AppColors.bg, fontFamily: 'Rissa'), home: const WalletPage()))); }
}

class LocalDataManager {
  static late Directory mainFolder, publicDownloadFolder;
  static Future<void> initFolder() async { Directory appDocDir = await getApplicationDocumentsDirectory(); mainFolder = Directory('${appDocDir.path}/money_schedule'); if (!await mainFolder.exists()) await mainFolder.create(recursive: true); if (Platform.isAndroid) { publicDownloadFolder = Directory('/storage/emulated/0/Download/Flutter'); if (!await publicDownloadFolder.exists()) await publicDownloadFolder.create(recursive: true); } else { publicDownloadFolder = mainFolder; } }
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
class ChatMessage { final String text; final bool isMe; final DateTime time; final String? imagePath; ChatMessage({required this.text, required this.isMe, required this.time, this.imagePath}); }

class FadeIndexedStack extends StatefulWidget { final int index; final List<Widget> children; const FadeIndexedStack({super.key, required this.index, required this.children}); @override State<FadeIndexedStack> createState() => _FadeIndexedStackState(); }
class _FadeIndexedStackState extends State<FadeIndexedStack> with SingleTickerProviderStateMixin { late AnimationController _c; @override void initState() { _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 300))..forward(); super.initState(); } @override void didUpdateWidget(FadeIndexedStack o) { if (widget.index != o.index) _c.forward(from: 0.0); super.didUpdateWidget(o); } @override void dispose() { _c.dispose(); super.dispose(); } @override Widget build(BuildContext context) => FadeTransition(opacity: _c, child: IndexedStack(index: widget.index, children: widget.children)); }

// ================= OFFLINE PERMISSIONS HANDLER =================
Future<bool> requestOfflinePermissions(BuildContext context) async {
  if (isDesktop) return false;
  Map<Permission, PermissionStatus> statuses = await [
    Permission.location,
    Permission.locationWhenInUse,
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothAdvertise,
    Permission.bluetoothConnect,
    Permission.nearbyWifiDevices, // BẮT BUỘC CHO ANDROID 13+
  ].request();

  try {
    await const MethodChannel('flutter/platform').invokeMethod('setLocationAccuracy', {'accuracy': 'high'});
  } catch (_) {}

  if (await Permission.location.serviceStatus.isDisabled) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("💡 Bật Vị trí (GPS) để Radar quét được sóng!", style: TextStyle(fontFamily: 'Rissa', fontSize: 14)),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ));
    }
    return false;
  }

  bool locGranted = statuses[Permission.location]?.isGranted ?? false;
  bool bleGranted = statuses[Permission.bluetoothScan]?.isGranted ?? false;
  return locGranted && bleGranted;
}

// ================= PURE WIFI DIRECT SOCKET MANAGER =================
class FileProg { final String name; final double progress; FileProg(this.name, this.progress); }
class P2pNetManager {
  static final P2pNetManager instance = P2pNetManager._internal();
  P2pNetManager._internal();

  final FlutterP2pConnection p2p = FlutterP2pConnection();
  WifiP2PInfo? wifiP2PInfo;
  
  ServerSocket? _serverSocket;
  Socket? _socket; // active connection
  
  final StreamController<MeshMessage> msgStream = StreamController<MeshMessage>.broadcast();
  final StreamController<FileProg> fileProgStream = StreamController<FileProg>.broadcast();
  final ValueNotifier<String?> pendingHandshake = ValueNotifier(null);
  String? connectedDeviceName;
  
  bool isHost = false;
  bool isConnected = false;
  
  Future<void> init() async {
    await p2p.initialize();
    await p2p.register();
    p2p.streamWifiP2PInfo().listen((info) {
      wifiP2PInfo = info;
      if (info.isConnected && info.isGroupOwner && _serverSocket == null) {
        _startSocketServer();
      } else if (info.isConnected && !info.isGroupOwner && _socket == null) {
        _connectToHost(info.groupOwnerAddress!);
      }
    });
  }
  
  Future<void> hostRoom() async { await p2p.removeGroup(); await p2p.createGroup(); isHost = true; }
  Future<void> joinRoom(DiscoveredPeers peer) async { await p2p.stopDiscovery(); await Future.delayed(const Duration(milliseconds: 200)); await p2p.connect(peer.deviceAddress); isHost = false; }
  Future<void> leaveRoom() async { await p2p.removeGroup(); _socket?.destroy(); _serverSocket?.close(); _socket=null; _serverSocket=null; isConnected=false; }
  
  void _startSocketServer() async {
    _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 8888);
    _serverSocket!.listen((Socket s) {
      _socket = s; isConnected = true;
      _handleSocketData(s);
    });
  }
  
  void _connectToHost(String ip) async {
    int retries = 0;
    while (_socket == null && retries < 10) {
      try {
        _socket = await Socket.connect(ip, 8888, timeout: const Duration(seconds: 3));
        isConnected = true;
        sendHandshake(globalDeviceAlias.value);
        _handleSocketData(_socket!);
      } catch (e) {
        retries++; await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  void sendHandshake(String name) => _socket?.add(utf8.encode('H|${utf8.encode(name).length}|$name'));
  void sendHandshakeAccept(String name) => _socket?.add(utf8.encode('HA|${utf8.encode(name).length}|$name'));


  List<int> _buffer = [];
  bool _isFileMode = false;
  int _curLen = 0;
  String _curName = "";
  int _receivedLen = 0;
  IOSink? _sink;

  void _handleSocketData(Socket s) {
    s.listen((data) {
      _buffer.addAll(data);
      _processBuffer();
    }, onDone: () { _socket = null; isConnected = false; _sink?.close(); });
  }

  Future<void> _processBuffer() async {
    while (_buffer.isNotEmpty) {
      if (!_isFileMode) {
        int p1 = _buffer.indexOf(124); // '|'
        if (p1 == -1) return;
        String type = utf8.decode(_buffer.sublist(0, p1));
        
        if (type == "M") {
          int p2 = _buffer.indexOf(124, p1 + 1);
          if (p2 == -1) return;
          int len = int.parse(utf8.decode(_buffer.sublist(p1 + 1, p2)));
          if (_buffer.length < p2 + 1 + len) return;
          String json = utf8.decode(_buffer.sublist(p2 + 1, p2 + 1 + len));
          msgStream.add(MeshMessage.fromJson(jsonDecode(json)));
          _buffer.removeRange(0, p2 + 1 + len);
        } else if (type == "F") {
          int p2 = _buffer.indexOf(124, p1 + 1);
          if (p2 == -1) return;
          int p3 = _buffer.indexOf(124, p2 + 1);
          if (p3 == -1) return;
          _curLen = int.parse(utf8.decode(_buffer.sublist(p1 + 1, p2)));
          _curName = utf8.decode(_buffer.sublist(p2 + 1, p3));
          
          String savePath = "${LocalDataManager.publicDownloadFolder.path}/$_curName";
          _sink = File(savePath).openWrite(mode: FileMode.write);
          _isFileMode = true;
          _receivedLen = 0;
          _buffer.removeRange(0, p3 + 1);
        } else if (type == "H" || type == "HA") {
          int p2 = _buffer.indexOf(124, p1 + 1);
          if (p2 == -1) return;
          int len = int.parse(utf8.decode(_buffer.sublist(p1 + 1, p2)));
          if (_buffer.length < p2 + 1 + len) return;
          String name = utf8.decode(_buffer.sublist(p2 + 1, p2 + 1 + len));
          if (type == "H") {
            pendingHandshake.value = name;
          } else {
            pendingHandshake.value = "ACCEPTED";
            connectedDeviceName = name;
          }
          _buffer.removeRange(0, p2 + 1 + len);
        } else {
          _buffer.clear(); // Corrupted stream
        }
      } else {
        int remaining = _curLen - _receivedLen;
        if (_buffer.length <= remaining) {
          _sink!.add(_buffer);
          _receivedLen += _buffer.length;
          _buffer.clear();
        } else {
          _sink!.add(_buffer.sublist(0, remaining));
          _receivedLen += remaining;
          _buffer.removeRange(0, remaining);
        }
        fileProgStream.add(FileProg(_curName, _receivedLen / _curLen));
        if (_receivedLen == _curLen) {
          await _sink!.close();
          _isFileMode = false;
        }
      }
    }
  }
  
  void sendText(String json) {
    if (_socket == null) return;
    List<int> payload = utf8.encode(json);
    List<int> header = utf8.encode("M|${payload.length}|");
    _socket!.add([...header, ...payload]);
  }
  
  Future<void> sendFile(File f) async {
    if (_socket == null) return;
    String name = f.path.split('/').last;
    int len = await f.length();
    List<int> header = utf8.encode("F|$len|$name|");
    _socket!.add(header);
    
    // chunked transmission
    Stream<List<int>> fs = f.openRead();
    int sent = 0;
    await for (var chunk in fs) {
        _socket!.add(chunk);
        sent += chunk.length;
        fileProgStream.add(FileProg(name, sent / len));
    }
  }
}

// ================= GIAO DIỆN CHÍNH (WALLET & MENU WRAPPER) =================
class WalletPage extends StatefulWidget { const WalletPage({super.key}); @override State<WalletPage> createState() => _WalletPageState(); }
class _WalletPageState extends State<WalletPage> {
  int selectedIndex = 0; 
  int? expandedCardIndex; 
  bool isScanningNFC = false; 
  CardCategory selectedFilter = CardCategory.bank;
  List<CardModel> cards = []; 
  List<Transaction> transactions = [];
  
  @override void initState() { super.initState(); P2pNetManager.instance.pendingHandshake.addListener(_onHandshake); _init(); }
  @override void dispose() { P2pNetManager.instance.pendingHandshake.removeListener(_onHandshake); super.dispose(); }
  
  void _onHandshake() {
    String? val = P2pNetManager.instance.pendingHandshake.value;
    if (val == null) return;
    if (val == "ACCEPTED") {
      setState(() => selectedIndex = 6);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kết nối P2P Thành Công!")));
      return;
    }
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.sky, width: 2)),
      title: const Text("Yêu cầu ghép nối", style: TextStyle(color: Colors.white, fontFamily: 'Rissa', fontSize: 22)),
      content: Text("Thiết bị [$val] muốn ghép nối P2P. Bạn có đồng ý?", style: const TextStyle(color: Colors.white70, fontFamily: 'Rissa')),
      actions: [
        TextButton(onPressed: () { P2pNetManager.instance.leaveRoom(); Navigator.pop(context); }, child: const Text("Từ chối", style: TextStyle(color: AppColors.rose))),
        TextButton(onPressed: () { P2pNetManager.instance.sendHandshakeAccept(globalDeviceAlias.value); P2pNetManager.instance.connectedDeviceName = val; setState(() => selectedIndex = 6); Navigator.pop(context); }, child: const Text("Đồng ý", style: TextStyle(color: AppColors.sky))),
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
  
  void _showiOSGlassMenu() {
    showGeneralDialog(
      context: context, barrierDismissible: true, barrierLabel: "M",
      barrierColor: Colors.black.withAlpha(130),
      transitionDuration: const Duration(milliseconds: 380),
      transitionBuilder: (ctx, a1, a2, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(CurvedAnimation(parent: a1, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: a1, child: child),
      ),
      pageBuilder: (ctx, a1, a2) => Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 110, left: 14, right: 14),
          child: glBox(
            Padding(padding: const EdgeInsets.all(18),
              child: GridView.count(crossAxisCount: 4, mainAxisSpacing: 14, crossAxisSpacing: 8, childAspectRatio: 0.88, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                children: [
                  _mi(Icons.account_balance_wallet_outlined, "Wallet", 0, ctx),
                  _mi(Icons.camera_outlined, "Locket", 1, ctx),
                  _mi(Icons.sports_esports_outlined, "Games", 2, ctx),
                  _mi(Icons.notifications_outlined, "Noti", 3, ctx),
                  _mi(Icons.wifi_tethering, "Send", 4, ctx),
                  _mi(Icons.music_note_outlined, "Music", 5, ctx),
                  _mi(Icons.sticky_note_2_outlined, "Notes", 6, ctx),
                  _mi(Icons.chat_bubble_outline, "Chat", 7, ctx),
                ],
              )
            ), true,
          ),
        ),
      ),
    );
  }

  Widget _mi(IconData i, String l, int idx, BuildContext ctx) {
    bool a = selectedIndex == idx;
    Color accent = tabAccentColor(idx);
    return GestureDetector(
      onTap: () { HapticFeedback.mediumImpact(); setState(() => selectedIndex = idx); Navigator.pop(ctx); },
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 280), curve: Curves.easeOutBack,
          height: 56, width: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: a ? accent.withAlpha(35) : Colors.white.withAlpha(10),
            border: Border.all(color: a ? accent : Colors.white.withAlpha(28), width: 1.5),
            boxShadow: a ? [BoxShadow(color: accent.withAlpha(80), blurRadius: 18, spreadRadius: 1)] : [],
          ),
          child: Icon(i, color: a ? accent : Colors.white.withAlpha(155), size: 24),
        ),
        const SizedBox(height: 7),
        Text(l, style: TextStyle(color: a ? accent : AppColors.textSec, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Rissa'), overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _filterBtn(String label, CardCategory cat, IconData icon, bool isDark) {
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
    const bool isDark = true;
    bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned.fill(child: auroraBackground(AppColors.amber)),
          SafeArea(
            bottom: false,
            child: FadeIndexedStack(
              index: selectedIndex,
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
                          _filterBtn("Ngân Hàng", CardCategory.bank, Icons.credit_card_outlined, isDark),
                          _filterBtn("Thẻ Cửa", CardCategory.door, Icons.door_front_door_outlined, isDark),
                          _filterBtn("Thẻ Xe", CardCategory.parking, Icons.local_parking_outlined, isDark),
                        ]
                      ),
                    ),
                    Expanded(
                      child: cards.where((c) => c.category == selectedFilter).isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min, 
                              children: [
                                const Icon(Icons.credit_card_off_outlined, size: 52, color: AppColors.textMuted),
                                const SizedBox(height: 14),
                                const Text("Chưa có thẻ nào", style: TextStyle(color: AppColors.textSec, fontSize: 15, fontFamily: 'Rissa')),
                                const SizedBox(height: 6),
                                const Text("Chạm + để scan NFC", style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontFamily: 'Rissa')),
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
                isDesktop ? buildPCWarning("Locket Camera", Icons.camera_alt) : LocketCameraTab(isActive: selectedIndex == 1, transactions: transactions, onNewTransaction: (t) async { String p = await LocalDataManager.saveImage(File(t.imagePath!)); setState(() => transactions.add(Transaction(p, t.amount, t.note, t.date, t.type))); _save(); }),
                isDesktop ? buildPCWarning("Game Space", Icons.games) : const GameSpaceTab(),
                isDesktop ? buildPCWarning("Notification Log", Icons.notifications) : const NotiLogTab(),
                isDesktop ? buildPCWarning("Nearby Send", Icons.wifi_tethering) : const LocalSendTab(),
                const MusicTab(),
                const NotesTab(),
                isDesktop ? buildPCWarning("Mesh LocalChat", Icons.chat_bubble) : const LocalChatTab(),
              ],
            ),
          ),
          if (selectedIndex != 7 || (selectedIndex == 7 && LocalChatTab.activeChatId == null))
            Positioned(
              bottom: isLandscape ? 8 : 28, left: 0, right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _showiOSGlassMenu,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      color: Colors.white.withAlpha(14),
                      border: Border.all(color: tabAccentColor(selectedIndex).withAlpha(120), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: tabAccentColor(selectedIndex).withAlpha(60), blurRadius: 20, spreadRadius: 0),
                        BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 16),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.grid_view_rounded, color: tabAccentColor(selectedIndex), size: 18),
                          const SizedBox(width: 10),
                          const Text("MENU", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, fontFamily: 'Rissa', letterSpacing: 1.5)),
                        ]),
                      ),
                    ),
                  ),
                ),
              )
            ),
          if (selectedIndex == 0 && !isLandscape)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: GestureDetector(
                onVerticalDragEnd: (d) { if (d.primaryVelocity! < -100) _openQuickPay(); },
                onTap: _openQuickPay,
                child: Container(
                  height: 25, color: Colors.transparent, alignment: Alignment.bottomCenter, padding: const EdgeInsets.only(bottom: 8),
                  child: Container(width: 50, height: 5, decoration: BoxDecoration(color: isDark ? Colors.white38 : Colors.black26, borderRadius: BorderRadius.circular(10)))
                )
              )
            ),
          ValueListenableBuilder<MeshMessage?>(
            valueListenable: globalChatNoti,
            builder: (context, msg, child) {
              if (msg == null) return const SizedBox.shrink();
              return Positioned(
                top: 50, left: 20, right: 20,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: -100.0, end: 0.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  builder: (context, val, child) => Transform.translate(
                    offset: Offset(0, val),
                    child: glBox(
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          children: [
                            const CircleAvatar(backgroundColor: Colors.blueAccent, radius: 20, child: Icon(Icons.chat_bubble, color: Colors.white, size: 20)),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(msg.sender.length > 15 ? msg.sender.substring(0,15) : msg.sender, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Rissa', fontSize: 16)),
                                  Text(msg.imagePath != null ? "Đã gửi 1 ảnh 🖼️" : msg.content, style: const TextStyle(color: Colors.white70, fontFamily: 'Rissa', fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)
                                ]
                              )
                            )
                          ]
                        )
                      ),
                      isDark
                    )
                  )
                )
              );
            }
          )
        ],
      ),
    );
  }
}

// ================= LOCAL CHAT TAB (PURE WIFI DIRECT) =================
class LocalChatTab extends StatefulWidget { static String? activeChatId; const LocalChatTab({super.key}); @override State<LocalChatTab> createState() => _LocalChatTabState(); }
class _LocalChatTabState extends State<LocalChatTab> with SingleTickerProviderStateMixin {
  String myDeviceAlias = "MyPhone_${math.Random().nextInt(100)}";
  List<DiscoveredPeers> discoveredNodes = [];
  List<MeshMessage> chatHistory = [];
  
  TextEditingController chatCtrl = TextEditingController(); 
  ScrollController scrollCtrl = ScrollController(); 
  late AnimationController _radarCtrl;
  StreamSubscription? _msgSub;
  Timer? _radarTimer;
  bool _isScanning = false;

  @override void initState() { 
    super.initState(); 
    _radarCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(); 
    P2pNetManager.instance.init();
    
    P2pNetManager.instance.p2p.streamPeers().listen((peers) {
      if (mounted) setState(() => discoveredNodes = peers);
    });

    _msgSub = P2pNetManager.instance.msgStream.stream.listen((msg) {
      if (mounted) {
        setState(() => chatHistory.add(msg));
        if (LocalChatTab.activeChatId != msg.sender) {
          globalChatNoti.value = msg;
          Future.delayed(const Duration(seconds: 3), () => globalChatNoti.value = null);
        }
        _scrollToBottom();
      }
    });
  }
  @override void dispose() { _msgSub?.cancel(); _radarCtrl.dispose(); _radarTimer?.cancel(); P2pNetManager.instance.p2p.stopDiscovery(); super.dispose(); }

  void _startRadar() async {
    _isScanning = true; _radarTimer?.cancel();
    try {
      await P2pNetManager.instance.p2p.stopDiscovery();
      await Future.delayed(const Duration(milliseconds: 200));
      await P2pNetManager.instance.p2p.discover();
    } catch(e){}
  }

  void _sendText() {
    if (chatCtrl.text.isEmpty || !P2pNetManager.instance.isConnected) return;
    String content = chatCtrl.text;
    MeshMessage msg = MeshMessage(id: "MSG_${math.Random().nextInt(999999)}", sender: myDeviceAlias, content: content, timestamp: DateTime.now().millisecondsSinceEpoch, hops: [], roomId: "global");
    P2pNetManager.instance.sendText(jsonEncode(msg.toJson()));
    setState(() { chatHistory.add(msg); chatCtrl.clear(); });
    _scrollToBottom();
  }

  void _sendImageMMS() async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null && P2pNetManager.instance.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đang gửi ảnh gốc P2P...", style: TextStyle(fontFamily: 'Rissa'))));
      await P2pNetManager.instance.sendFile(File(image.path));
      setState(() { chatHistory.add(MeshMessage(id: "IMG_${math.Random().nextInt(9999)}", sender: myDeviceAlias, content: "Ảnh", timestamp: DateTime.now().millisecondsSinceEpoch, hops: [], roomId: "global", imagePath: image.path)); });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() { Future.delayed(const Duration(milliseconds: 100), () { if (scrollCtrl.hasClients) scrollCtrl.animateTo(scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); }); }

  void _showImageFullScreen(String path) { Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white), actions: [IconButton(icon: const Icon(Icons.download), onPressed: () async { await File(path).copy('${LocalDataManager.publicDownloadFolder.path}/IMG_${DateTime.now().millisecondsSinceEpoch}.jpg'); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu vào Download", style: TextStyle(fontFamily: 'Rissa')))); })]), extendBodyBehindAppBar: true, body: Center(child: InteractiveViewer(child: Image.file(File(path))))))); }

  Widget _buildInboxView(bool isDark) {
    bool isHost = P2pNetManager.instance.isHost;
    return Column(children: [
      tabHeader("WiFi Direct Chat", AppColors.sky, subtitle: "@${globalDeviceAlias.value}"),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5), child: glBox(TextField(onChanged: (v)=>globalDeviceAlias.value=v, decoration: const InputDecoration(hintText: "Nhập tên máy của bạn...", border: InputBorder.none, hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13)), style: const TextStyle(color: Colors.white, fontFamily: 'Rissa', fontSize: 14)), true, p: const EdgeInsets.symmetric(horizontal: 16), r: 16)),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
        Expanded(child: NeonButton(Icons.wifi_tethering, AppColors.sky, () async {
          _isScanning = false; _radarTimer?.cancel();
          await P2pNetManager.instance.p2p.removeGroup();
          await Future.delayed(const Duration(milliseconds: 200));
          bool? isCreated = await P2pNetManager.instance.p2p.createGroup();
          if (isCreated == true) {
            P2pNetManager.instance.isHost = true;
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã tạo phòng. Chờ người khác quét...")));
            setState((){});
          } else {
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi: Hãy bật Vị Trí (GPS) và Wi-Fi!", style: TextStyle(fontFamily: 'Rissa')), backgroundColor: AppColors.rose));
          }
        }, label: "Tạo Phòng (Host)")),
        const SizedBox(width: 14),
        Expanded(child: NeonButton(Icons.search, AppColors.violet, () async {
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Radar đang quét liên tục...")));
          _startRadar();
        }, label: "Tìm Phòng")),
      ])),
      const SizedBox(height: 20),
      if (isHost) const Padding(padding: EdgeInsets.all(10), child: Text("Đang làm Máy Chủ. Chờ kết nối...", style: TextStyle(color: AppColors.sky, fontFamily: 'Rissa'))),
      Expanded(child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(animation: _radarCtrl, builder: (c, w) => CustomPaint(painter: RadarPainter(_radarCtrl.value, AppColors.sky), size: const Size(double.infinity, double.infinity))),
          const Icon(Icons.smartphone, size: 50, color: Colors.white),
          ...discoveredNodes.asMap().entries.map((e) {
            final peer = e.value;
            math.Random r = math.Random(peer.deviceAddress.hashCode);
            double angle = r.nextDouble() * 2 * math.pi;
            double radius = 90 + r.nextDouble() * 80;
            return Positioned(
              left: MediaQuery.of(context).size.width/2 + math.cos(angle) * radius - 30,
              top: MediaQuery.of(context).size.height/3.5 + math.sin(angle) * radius - 30,
              child: GestureDetector(
                onTap: () async { await P2pNetManager.instance.joinRoom(peer); },
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.sky.withAlpha(50), border: Border.all(color: AppColors.sky, width: 2), boxShadow: const [BoxShadow(color: AppColors.sky, blurRadius: 15)]), child: const Icon(Icons.wifi, color: Colors.white, size: 20)),
                  const SizedBox(height: 5),
                  Text(peer.deviceName, style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Rissa', fontWeight: FontWeight.bold), maxLines: 1)
                ])
              )
            );
          }).toList(),
        ]
      )),
    ]);
  }

  Widget _buildChatRoom(bool isDark) {
    return Column(children: [
      glBox(Padding(padding: const EdgeInsets.only(top: 14, bottom: 10, left: 10, right: 10), child: Row(children: [
        IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.sky, size: 18), onPressed: () { P2pNetManager.instance.leaveRoom(); setState((){}); }),
        Container(width: 34, height: 34, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.sky.withAlpha(80), AppColors.violet.withAlpha(80)])),
          child: const Center(child: Text("P", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Rissa')))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Direct Peer", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Rissa')),
          Row(children: [Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 5), decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.teal)), const Text("TCP Raw Socket", style: TextStyle(fontSize: 10, color: AppColors.teal, fontFamily: 'Rissa'))]),
        ])),
      ])), true, r: 0),
      Expanded(child: ListView.builder(controller: scrollCtrl, padding: const EdgeInsets.all(14).copyWith(bottom: 20), itemCount: chatHistory.length, itemBuilder: (context, index) {
        final m = chatHistory[index]; bool isMe = m.sender == myDeviceAlias;
        return Align(alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            decoration: BoxDecoration( borderRadius: BorderRadius.circular(20), color: isMe ? AppColors.sky.withAlpha(45) : Colors.white.withAlpha(12), border: Border.all(color: isMe ? AppColors.sky.withAlpha(80) : Colors.white.withAlpha(20), width: 1), boxShadow: isMe ? [BoxShadow(color: AppColors.sky.withAlpha(30), blurRadius: 10)] : []),
            child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
              if (m.imagePath != null) GestureDetector(onTap: () => _showImageFullScreen(m.imagePath!), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(m.imagePath!), width: 180, fit: BoxFit.cover))),
              Text(m.content, style: TextStyle(color: isMe ? AppColors.sky : Colors.white, fontSize: 14, fontFamily: 'Rissa')),
            ]),
          ));
      })),
      glBox(Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10).copyWith(bottom: 90), child: Row(children: [
        GestureDetector(onTap: _sendImageMMS, child: const Icon(Icons.image_outlined, color: AppColors.sky, size: 26)),
        const SizedBox(width: 10),
        Expanded(child: glBox(TextField(controller: chatCtrl, style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Rissa'), decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), border: InputBorder.none, hintText: "Nhắn tin tốc độ cao...", hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13))), true, r: 25)),
        const SizedBox(width: 10),
        GestureDetector(onTap: _sendText, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.sky.withAlpha(30), border: Border.all(color: AppColors.sky.withAlpha(80), width: 1.5)), child: const Icon(Icons.send_rounded, color: AppColors.sky, size: 20))),
      ])), true, r: 0),
    ]);
  }

  @override Widget build(BuildContext context) { 
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return !P2pNetManager.instance.isConnected ? _buildInboxView(isDark) : _buildChatRoom(isDark); 
  }
}


// ================= LOCAL SEND TAB (PURE WIFI DIRECT) =================
class LocalSendTab extends StatefulWidget { const LocalSendTab({super.key}); @override State<LocalSendTab> createState() => _LocalSendTabState(); }
class _LocalSendTabState extends State<LocalSendTab> with SingleTickerProviderStateMixin {
  List<File> filesToDrag = [];
  ValueNotifier<double> progress = ValueNotifier(-1.0);
  late AnimationController _radar;
  String myDeviceAlias = "MyPhone_1";
  StreamSubscription? _progSub;
  Timer? _radarTimer;
  bool _isScanning = false;

  @override void initState() {
    super.initState();
    _radar = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _progSub = P2pNetManager.instance.fileProgStream.stream.listen((prog) {
      progress.value = prog.progress;
    });
  }

  @override void dispose() { _progSub?.cancel(); _radar.dispose(); _radarTimer?.cancel(); P2pNetManager.instance.p2p.stopDiscovery(); super.dispose(); }

  void _startRadar() async {
    _isScanning = true; _radarTimer?.cancel();
    try {
      await P2pNetManager.instance.p2p.stopDiscovery();
      await Future.delayed(const Duration(milliseconds: 200));
      await P2pNetManager.instance.p2p.discover();
    } catch(e){}
  }

  void _pickFiles(String type) async {
    FilePickerResult? r;
    if (type == 'image') r = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true);
    else if (type == 'video') r = await FilePicker.platform.pickFiles(type: FileType.video, allowMultiple: true);
    else if (type == 'apk') r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['apk'], allowMultiple: true);
    else if (type == 'zip') r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip', 'rar', '7z'], allowMultiple: true);
    else r = await FilePicker.platform.pickFiles(allowMultiple: true);

    if (r != null && r.paths.isNotEmpty) {
      List<File> newFiles = [];
      for (var path in r.paths) { if (path != null) newFiles.add(File(path)); }
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
      tabHeader("WiFi Direct Send", AppColors.teal,
        subtitle: isConn ? "Đã kết nối" : "Chưa kết nối ngang hàng P2P",
        trailing: Row(children: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_circle_outline, size: 26, color: AppColors.teal),
            color: AppColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), onSelected: _pickFiles,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'file', child: Row(children: [Icon(Icons.insert_drive_file, color: AppColors.textSec), SizedBox(width: 10), Text("Tài liệu", style: TextStyle(color: Colors.white))])),
              const PopupMenuItem(value: 'image', child: Row(children: [Icon(Icons.image, color: AppColors.textSec), SizedBox(width: 10), Text("Hình ảnh", style: TextStyle(color: Colors.white))])),
              const PopupMenuItem(value: 'video', child: Row(children: [Icon(Icons.videocam, color: AppColors.textSec), SizedBox(width: 10), Text("Video", style: TextStyle(color: Colors.white))])),
              const PopupMenuItem(value: 'zip', child: Row(children: [Icon(Icons.folder_zip, color: AppColors.textSec), SizedBox(width: 10), Text("Tệp nén", style: TextStyle(color: Colors.white))])),
              const PopupMenuItem(value: 'apk', child: Row(children: [Icon(Icons.android, color: AppColors.textSec), SizedBox(width: 10), Text("APK", style: TextStyle(color: Colors.white))])),
            ],
          ),
        ]),
      ),
      Expanded(child: Stack(children: [
        if (!isConn) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Vui lòng qua tab Chat để kết nối mạng WiFi Direct trước khi gửi file siêu tốc.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontFamily: 'Rissa', fontSize: 16)))),
        if (isConn) ...[
          Center(child: AnimatedBuilder(animation: _radar, builder: (c, w) => CustomPaint(painter: RadarPainter(_radar.value, AppColors.teal), size: const Size(250, 250)))),
          Center(child: glBox(const Icon(Icons.compare_arrows_rounded, size: 36, color: AppColors.teal), true, r: 38, p: const EdgeInsets.all(14))),
          Align(
            alignment: const FractionalOffset(0.5, 0.25),
            child: DragTarget<File>(
              onAcceptWithDetails: (details) async { await P2pNetManager.instance.sendFile(details.data); setState(() => filesToDrag.remove(details.data)); },
              builder: (c, cd, rd) => glBox(Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.smartphone, color: cd.isNotEmpty ? Colors.greenAccent : AppColors.teal, size: 26),
                const SizedBox(height: 5),
                const Text("Thả File Vào Đây", style: TextStyle(fontSize: 10, fontFamily: 'Rissa', color: Colors.white)),
              ]), true, p: const EdgeInsets.all(12), r: 18, color: cd.isNotEmpty ? Colors.greenAccent.withAlpha(30) : null),
            ),
          ),
        ],
        if (filesToDrag.isNotEmpty) Positioned(bottom: 20, left: 0, right: 0,
          child: SizedBox(height: 54, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: filesToDrag.length,
            itemBuilder: (c, idx) => Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Draggable<File>(data: filesToDrag[idx],
                feedback: Material(color: Colors.transparent, child: _buildTicket(filesToDrag[idx])),
                childWhenDragging: Opacity(opacity: 0.3, child: _buildTicket(filesToDrag[idx])),
                child: _buildTicket(filesToDrag[idx]))),
          )),
        ),
      ])),
      ValueListenableBuilder<double>(
        valueListenable: progress,
        builder: (context, val, _) => val >= 0
          ? Container(height: 4, margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: AppColors.teal.withAlpha(30)),
              child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: val == 0 ? null : val,
                child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(colors: [AppColors.teal, AppColors.sky])))))
          : const SizedBox.shrink(),
      ),
      const SizedBox(height: 8),
    ]);
  }
}
class RadarPainter extends CustomPainter { final double p; final Color c; RadarPainter(this.p, this.c); @override void paint(Canvas cv, Size s) { Paint pt = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5; for(int i=0;i<3;i++){ double r= ((p+i/3)%1)*s.width/2; pt.color=c.withOpacity(1-(p+i/3)%1); cv.drawCircle(s.center(Offset.zero), r, pt); } } @override bool shouldRepaint(RadarPainter old) => true; }

// ================= CÁC TAB KHÁC =================
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
        backgroundColor: Colors.transparent, elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: ShaderMask(shaderCallback: (b) => const LinearGradient(colors: [Colors.white, AppColors.amber]).createShader(b),
          child: const Text("Cài đặt", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 22, fontFamily: 'Rissa'))),
      ),
      body: Stack(children: [
        Positioned.fill(child: auroraBackground(AppColors.amber)),
        ListView(padding: const EdgeInsets.all(20), children: [
          const SizedBox(height: 4),
          _settingsSection("Giao diện", Icons.palette_outlined, AppColors.amber, [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Màu chữ ứng dụng", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Rissa')),
              const SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 8, children: [
                _colorBtn(null, "Mặc định"),
                _colorBtn(AppColors.sky, "Xanh trời"),
                _colorBtn(AppColors.teal, "Xanh ngọc"),
                _colorBtn(AppColors.amber, "Vàng"),
                _colorBtn(AppColors.rose, "Hồng"),
              ]),
            ])),
          ]),
          const SizedBox(height: 20),
          _settingsSection("Thiết bị", Icons.memory_outlined, AppColors.violet, [
            _infoRow("Hệ điều hành", osVersion.isEmpty ? "N/A" : osVersion, AppColors.teal),
            _infoRow("Trạng thái Root", isRooted ? "Đã Root" : "An toàn", isRooted ? AppColors.rose : AppColors.teal),
            _infoRow("USB Debugging", isDevMode ? "Đang bật" : "Đã tắt", isDevMode ? AppColors.amber : AppColors.textSec),
          ]),
          const SizedBox(height: 20),
          _settingsSection("Lưu trử", Icons.storage_outlined, AppColors.teal, [
            _infoRow("Dung lượng Data", folderSizeStr, AppColors.amber),
          ]),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () { widget.onClearData(); Navigator.pop(context); },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
                color: AppColors.rose.withAlpha(20), border: Border.all(color: AppColors.rose.withAlpha(80), width: 1),
                boxShadow: [BoxShadow(color: AppColors.rose.withAlpha(40), blurRadius: 16)]),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.delete_forever_outlined, color: AppColors.rose, size: 20),
                SizedBox(width: 10),
                Text("Xóa toàn bộ dữ liệu", style: TextStyle(color: AppColors.rose, fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Rissa')),
              ]),
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
      Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8), child: Row(children: [
        Icon(icon, color: accent, size: 18), const SizedBox(width: 8),
        Text(title, style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Rissa')),
      ])),
      const Divider(color: Colors.white10, height: 1),
      ...children,
      const SizedBox(height: 8),
    ]),
  );
}

class LocketCameraTab extends StatefulWidget { final bool isActive; final List<Transaction> transactions; final Function(Transaction) onNewTransaction; const LocketCameraTab({super.key, required this.isActive, required this.transactions, required this.onNewTransaction}); @override State<LocketCameraTab> createState() => _LocketCameraTabState(); }
class _LocketCameraTabState extends State<LocketCameraTab> with WidgetsBindingObserver {
  CameraController? _c; bool _flash = false; @override void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); if (widget.isActive) _init(); }
  @override void didUpdateWidget(LocketCameraTab old) { super.didUpdateWidget(old); if (widget.isActive && !old.isActive) _init(); else if (!widget.isActive && old.isActive) _dispose(); }
  @override void didChangeAppLifecycleState(AppLifecycleState s) { if (s == AppLifecycleState.paused) _dispose(); else if (s == AppLifecycleState.resumed && widget.isActive) _init(); }
  @override void dispose() { WidgetsBinding.instance.removeObserver(this); _dispose(); super.dispose(); }
  void _init() async { if (cameras.isEmpty || isDesktop) return; await _dispose(); _c = CameraController(cameras[0], ResolutionPreset.high, enableAudio: false); try { await _c!.initialize(); } catch (e) { _c = null; return; } if (mounted) setState(() {}); }
  Future<void> _dispose() async { final old = _c; _c = null; await old?.dispose(); }
  void _take() async { if (_c == null) return; final i = await _c!.takePicture(); if (!mounted) return; final t = await Navigator.push(context, MaterialPageRoute(builder: (_) => LocketEditorScreen(imageFile: File(i.path)))); if (t != null) widget.onNewTransaction(t); }
  @override Widget build(BuildContext context) {
    if (!widget.isActive) return const Center(child: Text("Camera paused", style: TextStyle(fontFamily: 'Rissa', color: AppColors.textSec)));
    if (_c == null || !_c!.value.isInitialized) return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      CircularProgressIndicator(color: AppColors.coral, strokeWidth: 2),
      SizedBox(height: 16),
      Text("Khởi động camera...", style: TextStyle(color: AppColors.textSec, fontFamily: 'Rissa', fontSize: 13)),
    ]));
    return Column(children: [
      Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 0), child: ClipRRect(borderRadius: BorderRadius.circular(36), child: Stack(fit: StackFit.expand, children: [
        CameraPreview(_c!),
        Container(decoration: BoxDecoration(gradient: RadialGradient(colors: [Colors.transparent, Colors.black.withAlpha(80)], radius: 1.2))),
        Positioned(top: 16, right: 16, child: GestureDetector(onTap: () => setState(() { _flash = !_flash; _c!.setFlashMode(_flash ? FlashMode.torch : FlashMode.off); }),
          child: Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withAlpha(80), border: Border.all(color: Colors.white.withAlpha(60), width: 1)),
            child: Icon(_flash ? Icons.flash_on : Icons.flash_off_rounded, color: _flash ? AppColors.amber : Colors.white, size: 20)))),
      ])))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        NeonButton(Icons.photo_library_outlined, AppColors.coral, () async {
          var i = await ImagePicker().pickImage(source: ImageSource.gallery);
          if (i != null && mounted) { final t = await Navigator.push(context, MaterialPageRoute(builder: (_) => LocketEditorScreen(imageFile: File(i.path)))); if (t != null) widget.onNewTransaction(t); }
        }),
        GestureDetector(onTap: _take, child: Container(height: 76, width: 76,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [AppColors.coral, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: AppColors.coral.withAlpha(100), blurRadius: 20, spreadRadius: 2)]),
          child: Center(child: Container(height: 60, width: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(220)))))),
        NeonButton(Icons.flip_camera_ios_outlined, AppColors.coral, _init),
      ])),
      GestureDetector(
        onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (c) => HistoryBottomSheet(transactions: widget.transactions)),
        child: const Padding(padding: EdgeInsets.only(bottom: 100), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("Lịch sử", style: TextStyle(color: AppColors.coral, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Rissa')),
          Icon(Icons.keyboard_arrow_down, color: AppColors.coral),
        ])),
      ),
    ]);
  }
}
class HistoryBottomSheet extends StatelessWidget { final List<Transaction> transactions; const HistoryBottomSheet({super.key, required this.transactions}); @override Widget build(BuildContext context) { Map<String, List<Transaction>> grouped = {}; List<Transaction> sorted = List.from(transactions)..sort((a, b) => b.date.compareTo(a.date)); for (var t in sorted) { String date = DateFormat('EEE, dd/MM/yyyy').format(t.date); grouped.putIfAbsent(date, () => []); grouped[date]!.add(t); } return DraggableScrollableSheet(initialChildSize: 0.9, maxChildSize: 0.9, minChildSize: 0.5, builder: (_, controller) { return glBox(Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), child: Column(children: [Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))), const SizedBox(height: 20), const Text("Lịch sử chi tiêu", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Rissa')), const SizedBox(height: 20), Expanded(child: grouped.isEmpty ? const Center(child: Text("Chưa có giao dịch", style: TextStyle(color: Colors.white54, fontSize: 16, fontFamily: 'Rissa'))) : ListView(controller: controller, children: grouped.entries.map((entry) { return Padding(padding: const EdgeInsets.only(bottom: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(entry.key, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Rissa')), const SizedBox(height: 10), GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: entry.value.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.8), itemBuilder: (_, i) { final t = entry.value[i]; return ClipRRect(borderRadius: BorderRadius.circular(15), child: Stack(fit: StackFit.expand, children: [if (t.imagePath != null) Image.file(File(t.imagePath!), fit: BoxFit.cover) else Container(color: Colors.grey.shade900), Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.9), Colors.transparent]))), Positioned(bottom: 5, left: 5, right: 5, child: Text("${t.type == TransactionType.expense ? '-' : '+'}${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(t.amount)}", style: TextStyle(color: t.type == TransactionType.expense ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Rissa')))])); })])); }).toList()))])), Theme.of(context).brightness == Brightness.dark, r: 30); }); } }
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
                    if (app is ApplicationWithIcon) ClipRRect(borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                      child: Image.memory(app.icon, width: 70, height: 70, fit: BoxFit.cover)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(app.appName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Rissa')),
                      const SizedBox(height: 4),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: AppColors.cyan.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                        child: Text(app.packageName, style: const TextStyle(color: AppColors.cyan, fontSize: 10, fontFamily: 'Rissa'), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ])),
                    Padding(padding: const EdgeInsets.only(right: 14),
                      child: GestureDetector(onTap: () => DeviceApps.openApp(app.packageName),
                        child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.cyan.withAlpha(25), border: Border.all(color: AppColors.cyan.withAlpha(80), width: 1.5), boxShadow: [BoxShadow(color: AppColors.cyan.withAlpha(50), blurRadius: 12)]),
                          child: const Icon(Icons.play_arrow_rounded, color: AppColors.cyan, size: 22)))),
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
          ? Row(children: [
              NeonButton(Icons.select_all, AppColors.violet, () => setState(() => selectedIndexes = Set.from(Iterable.generate(notifications.length)))),
              const SizedBox(width: 8),
              NeonButton(Icons.delete_outline, AppColors.rose, _deleteSelected),
              const SizedBox(width: 8),
              NeonButton(Icons.close, AppColors.textSec, () => setState(() { isSelectionMode = false; selectedIndexes.clear(); })),
            ])
          : const Icon(Icons.history_outlined, color: AppColors.textSec, size: 22),
      ),
      Expanded(child: notifications.isEmpty
        ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.notifications_off_outlined, size: 52, color: AppColors.textMuted),
            SizedBox(height: 14),
            const Text("Nhật ký trống", style: TextStyle(color: AppColors.textSec, fontSize: 15, fontFamily: 'Rissa')),
          ]))
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 110),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              NotiModel noti = notifications[index];
              bool isSelected = selectedIndexes.contains(index);
              return GestureDetector(
                onLongPress: () { HapticFeedback.heavyImpact(); setState(() { isSelectionMode = true; selectedIndexes.add(index); }); },
                onTap: () { if (isSelectionMode) setState(() { if (isSelected) selectedIndexes.remove(index); else selectedIndexes.add(index); if (selectedIndexes.isEmpty) isSelectionMode = false; }); },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
                    color: isSelected ? AppColors.rose.withAlpha(20) : Colors.white.withAlpha(10),
                    border: Border.all(color: isSelected ? AppColors.rose.withAlpha(80) : Colors.white.withAlpha(18), width: 1)),
                  child: Row(children: [
                    Container(width: 4, height: 72, decoration: BoxDecoration(borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)), color: AppColors.violet.withAlpha(isSelected ? 60 : 180))),
                    const SizedBox(width: 12),
                    if (isSelectionMode) ...[Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? AppColors.rose : AppColors.textSec, size: 20), const SizedBox(width: 10)],
                    Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(child: Text(noti.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Rissa'), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Text(DateFormat('HH:mm').format(noti.timestamp), style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Rissa')),
                      ]),
                      const SizedBox(height: 3),
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
  List<double> eqGains = [0.0, 0.0, 0.0, 0.0, 0.0];
  double currentPos = 0; double maxPos = 1;
  
  @override void initState() {
    super.initState();
    _parseLrc();
    _isP = widget.player.playing; 
    _sub = widget.player.playingStream.listen((p) { if(mounted) setState((){ _isP = p; }); });
    _pSub = widget.player.positionStream.listen((p) {
      if(!mounted) return;
      setState(() => currentPos = p.inMilliseconds.toDouble());
      if(lrc.isEmpty) return;
      double sec = p.inMilliseconds / 1000.0; int ni = lrc.length - 1;
      for (int i=0; i<lrc.length; i++) { if (sec < lrc[i]["time"]) { ni = i - 1; break; } }
      if (ni < 0) ni = 0;
      if (ni != curLine) { setState(() => curLine = ni); if (_sc.hasClients) _sc.animateToItem(curLine, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); }
    });
    _dSub = widget.player.durationStream.listen((d) {
      if (d != null && mounted) setState(() => maxPos = d.inMilliseconds.toDouble());
    });
  }
  void _parseLrc() {
    for (var line in mockLrcData.split('\n')) {
      if (line.trim().isEmpty) continue;
      int b1 = line.indexOf('['); int b2 = line.indexOf(']');
      if (b1 != -1 && b2 != -1) {
        List<String> p = line.substring(b1+1, b2).split(':');
        lrc.add({"time": double.parse(p[0]) * 60 + double.parse(p[1]), "text": line.substring(b2+1).trim()});
      }
    }
  }
  String formatDuration(double ms) { int s = ms ~/ 1000; int m = s ~/ 60; return "$m:${(s%60).toString().padLeft(2, '0')}"; }
  @override void dispose() { _timer?.cancel(); _sub?.cancel(); _pSub?.cancel(); _dSub?.cancel(); _sc.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return Container(color: AppColors.bg, child: Column(children: [
      const SizedBox(height: 50),
      Row(children: [IconButton(icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 36), onPressed: () => Navigator.pop(context))]),
      const SizedBox(height: 10),
      Container(width: 250, height: 250, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [AppColors.rose, AppColors.violet]), boxShadow: [BoxShadow(color: AppColors.rose.withAlpha(50), blurRadius: 40, spreadRadius: 5)]), child: const Center(child: Icon(Icons.music_note, size: 80, color: Colors.white24))),
      const SizedBox(height: 20),
      Text(widget.song['title']!, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'Rissa'), maxLines: 1),
      Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: ListWheelScrollView.useDelegate(
        controller: _sc, itemExtent: 60, physics: const FixedExtentScrollPhysics(), onSelectedItemChanged: (i) => setState(()=>curLine=i),
        childDelegate: ListWheelChildBuilderDelegate(childCount: lrc.length, builder: (c, i) {
          bool isHi = i == curLine;
          return AnimatedDefaultTextStyle(duration: const Duration(milliseconds: 300), style: TextStyle(color: isHi ? Colors.white : Colors.white38, fontSize: isHi ? 24 : 16, fontWeight: isHi ? FontWeight.bold : FontWeight.normal, fontFamily: 'Rissa'), child: Center(child: Text(lrc[i]["text"]!)));
        })
      ))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 30), child: Row(children: [
        Text(formatDuration(currentPos), style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Rissa')),
        Expanded(child: Slider(
           value: currentPos.clamp(0.0, maxPos > 0 ? maxPos : 1.0), min: 0.0, max: maxPos > 0 ? maxPos : 1.0,
           activeColor: AppColors.rose, inactiveColor: Colors.white12,
           onChangeEnd: (v) => widget.player.seek(Duration(milliseconds: v.toInt())),
           onChanged: (v) => setState(() => currentPos = v),
        )),
        Text(formatDuration(maxPos), style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Rissa')),
      ])),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: Row(children: [
        const Icon(Icons.volume_down, color: Colors.white54),
        Expanded(child: Slider(value: v, min: 0.0, max: 2.0, activeColor: v > 1.0 ? AppColors.rose : AppColors.sky, onChanged: (nv) async { setState(() => v = nv); if(nv <= 1.0) { await widget.player.setVolume(nv); widget.le.setEnabled(false); } else { await widget.player.setVolume(1.0); await widget.le.setEnabled(true); await widget.le.setTargetGain((nv - 1.0) * 2000.0); } })),
        Text("${(v*100).toInt()}%", style: TextStyle(color: v > 1.0 ? AppColors.rose : Colors.white, fontFamily: 'Rissa', fontWeight: FontWeight.bold))
      ])),
      const SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        NeonButton(Icons.timer, AppColors.sky, () { setState(()=>t=15); _timer?.cancel(); _timer = Timer(const Duration(minutes: 15), ()=>widget.player.pause()); }, label: t>0?"${t}m":"Timer"),
        GestureDetector(onTap: () => _isP ? widget.player.pause() : widget.player.play(), child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.rose, boxShadow: [BoxShadow(color: AppColors.rose.withAlpha(100), blurRadius: 20)]), child: Icon(_isP ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 40))),
        NeonButton(Icons.equalizer, AppColors.violet, () {
          showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (_) => StatefulBuilder(builder: (c, setS) => glBox(Container(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text("Real EQ Settings", style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Rissa')), const SizedBox(height: 30),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(5, (i) => Expanded(child: Column(children: [
              SizedBox(height: 120, child: RotatedBox(quarterTurns: 3, child: Slider(value: eqGains[i], min: -1.0, max: 1.0, onChanged: (nv) async { setS(() => eqGains[i] = nv); widget.eq.setEnabled(true); final p = await widget.eq.parameters; final bands = p.bands; if(i < bands.length) { p.bands[i].setGain(nv); } }, activeColor: AppColors.rose))),
              Text(["60","230","910","3k","14k"][i], style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'Rissa'))
            ]))))
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
      tabHeader("Music", AppColors.rose,
        subtitle: "${globalLocalSongs.value.length} bài",
        trailing: NeonButton(Icons.add, AppColors.rose, () async {
          var r = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.audio);
          if (r != null) {
            final newList = List<Map<String, String>>.from(globalLocalSongs.value)..addAll(r.paths.map((p) => {"title": p!.split('/').last, "artist": "Local", "path": p, "cover": ""}));
            globalLocalSongs.value = newList; LocalDataManager.saveLocalMusic(newList); setState(() {});
          }
        }),
      ),
      Expanded(child: globalLocalSongs.value.isEmpty
        ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.music_off_outlined, size: 52, color: AppColors.textMuted),
            SizedBox(height: 14),
            Text("Chưa có bài nhạc", style: TextStyle(color: AppColors.textSec, fontSize: 15, fontFamily: 'Rissa')),
            SizedBox(height: 6),
            Text("Nhấn + để thêm nhạc local", style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontFamily: 'Rissa')),
          ]))
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: cur >= 0 ? 170 : 110),
            itemCount: globalLocalSongs.value.length,
            itemBuilder: (c, i) {
              bool isCur = cur == i; bool playing = isCur && isP;
              return GestureDetector(
                onTap: () { HapticFeedback.lightImpact(); _play(i); },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration( borderRadius: BorderRadius.circular(18), color: Colors.white.withAlpha(10), border: Border.all(color: isCur ? AppColors.rose.withAlpha(80) : Colors.white.withAlpha(18), width: 1), boxShadow: isCur ? [BoxShadow(color: AppColors.rose.withAlpha(50), blurRadius: 20)] : [], ),
                  child: Row(children: [
                    Container(width: 50, height: 50, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [AppColors.rose, AppColors.violet])), child: Icon(playing ? Icons.graphic_eq : Icons.music_note, color: Colors.white, size: 24)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                       Text(globalLocalSongs.value[i]["title"]!, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Rissa'), maxLines: 1, overflow: TextOverflow.ellipsis),
                       const SizedBox(height: 4),
                       const Text("Local Audio File", style: TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Rissa'))
                    ])),
                    if (isCur) Icon(isP ? Icons.graphic_eq : Icons.play_arrow_rounded, color: AppColors.rose, size: 26),
                  ]),
                ),
              );
            }),
      ),
      if (globalLocalSongs.value.isNotEmpty)
        GestureDetector(
          onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => FullscreenPlayer(globalLocalSongs.value[cur], _p, _le, _eq)),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 110),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: AppColors.rose.withAlpha(20), border: Border.all(color: AppColors.rose.withAlpha(70), width: 1), boxShadow: [BoxShadow(color: AppColors.rose.withAlpha(50), blurRadius: 20)]),
            child: ClipRRect(borderRadius: BorderRadius.circular(24), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), child: Row(children: [
                Container(width: 38, height: 38, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppColors.rose.withAlpha(40)), child: const Icon(Icons.music_note, color: AppColors.rose, size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Text(globalLocalSongs.value[cur]["title"]!, style: const TextStyle(color: Colors.white, fontFamily: 'Rissa', fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => isP ? _p.pause() : _play(cur),
                  child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.rose.withAlpha(30), border: Border.all(color: AppColors.rose.withAlpha(80), width: 1.5)), child: Icon(isP ? Icons.pause_rounded : Icons.play_arrow_rounded, color: AppColors.rose, size: 22))),
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
