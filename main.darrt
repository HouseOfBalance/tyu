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
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:safe_device/safe_device.dart';

// ================= THEME & COLORS =================
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

Color getAppTextColor(BuildContext c) => customColorNotifier.value ?? (Theme.of(c).brightness == Brightness.dark ? Colors.white : Colors.black87);

Widget glBox(Widget child, bool isDark, {double r = 20, EdgeInsets? p, EdgeInsets? m, Color? color, double blur = 15}) {
  return Container(margin: m, child: ClipRRect(borderRadius: BorderRadius.circular(r), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: Container(padding: p, decoration: BoxDecoration(color: color ?? (isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.3)), borderRadius: BorderRadius.circular(r), border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 1)]), child: child))));
}

Widget buildPCWarning(String title, IconData icon) => Center(child: glBox(Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 60, color: Colors.amber), const SizedBox(height: 20), Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Rissa')), const SizedBox(height: 10), const Text("Yêu cầu phần cứng Mobile.\nKhông khả dụng trên PC.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Rissa'))]), false, p: const EdgeInsets.all(30)));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isMobile) { try { cameras = await availableCameras(); } catch (e) {} if (Platform.isAndroid) { AndroidDeviceInfo info = await DeviceInfoPlugin().androidInfo; if ((info.displayMetrics.widthPx / info.displayMetrics.xDpi) > 7.0) currentDeviceType = 'tablet'; } } else { currentDeviceType = 'laptop'; }
  await LocalDataManager.initFolder(); globalLocalSongs.value = await LocalDataManager.loadLocalMusic();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override Widget build(BuildContext context) { return ValueListenableBuilder<bool>(valueListenable: isDarkModeNotifier, builder: (context, isDark, child) => ValueListenableBuilder<Color?>(valueListenable: customColorNotifier, builder: (context, customColor, child) => MaterialApp(title: 'Co-op', debugShowCheckedModeBanner: false, themeMode: isDark ? ThemeMode.dark : ThemeMode.light, theme: ThemeData(brightness: Brightness.light, scaffoldBackgroundColor: RobertColors.wall, fontFamily: 'Rissa'), darkTheme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xFF0B1220), fontFamily: 'Rissa'), home: const WalletPage()))); }
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
class NoteModel { String id, type, text; double dx, dy, w, h; bool done; NoteModel({required this.id, required this.type, required this.text, required this.dx, required this.dy, this.done = false, this.w = 160, this.h = 160}); Map<String, dynamic> toJson() => {'id': id, 'type': type, 'text': text, 'dx': dx, 'dy': dy, 'done': done, 'w': w, 'h': h}; static NoteModel fromJson(Map<String, dynamic> j) => NoteModel(id: j['id'], type: j['type'] ?? 'text', text: j['text'], dx: j['dx'], dy: j['dy'], done: j['done'] ?? false, w: j['w']?.toDouble() ?? 160.0, h: j['h']?.toDouble() ?? 160.0); }
class ChatMessage { final String text; final bool isMe; final DateTime time; final String? imagePath; ChatMessage({required this.text, required this.isMe, required this.time, this.imagePath}); }

class FadeIndexedStack extends StatefulWidget { final int index; final List<Widget> children; const FadeIndexedStack({super.key, required this.index, required this.children}); @override State<FadeIndexedStack> createState() => _FadeIndexedStackState(); }
class _FadeIndexedStackState extends State<FadeIndexedStack> with SingleTickerProviderStateMixin { late AnimationController _c; @override void initState() { _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 300))..forward(); super.initState(); } @override void didUpdateWidget(FadeIndexedStack o) { if (widget.index != o.index) _c.forward(from: 0.0); super.didUpdateWidget(o); } @override void dispose() { _c.dispose(); super.dispose(); } @override Widget build(BuildContext context) => FadeTransition(opacity: _c, child: IndexedStack(index: widget.index, children: widget.children)); }

class WalletPage extends StatefulWidget { const WalletPage({super.key}); @override State<WalletPage> createState() => _WalletPageState(); }
class _WalletPageState extends State<WalletPage> {
  int selectedIndex = 7; 
  int? expandedCardIndex; bool isScanningNFC = false; CardCategory selectedFilter = CardCategory.bank;
  List<CardModel> cards = []; List<Transaction> transactions = [];
  
  @override void initState() { super.initState(); _init(); }
  void _init() async { if (isMobile) { await [Permission.storage, Permission.manageExternalStorage, Permission.camera, Permission.location, Permission.bluetooth, Permission.bluetoothScan, Permission.bluetoothAdvertise, Permission.bluetoothConnect, Permission.audio].request(); } var d = await LocalDataManager.loadAppData(); if (d != null) { setState(() { cards = (d["cards"] as List).map((e) => CardModel.fromJson(e)).toList(); transactions = (d["transactions"] as List).map((e) => Transaction.fromJson(e)).toList(); }); } }
  void _save() async => await LocalDataManager.saveAppData(cards, transactions);
  
  void scanNFC() async { if (isDesktop) return; if(!await NfcManager.instance.isAvailable()) return; NfcManager.instance.startSession(onDiscovered: (t) async { NfcManager.instance.stopSession(); _showSaveCardDialog("UID-${DateTime.now().millisecondsSinceEpoch}"); }); }
  void _showSaveCardDialog(String uid) { TextEditingController n = TextEditingController(); CardCategory c = CardCategory.door; showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => glBox(Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20), child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: n, style: const TextStyle(color: Colors.white, fontFamily: 'Rissa'), decoration: const InputDecoration(labelText: "Tên thẻ", labelStyle: TextStyle(color: Colors.white54, fontFamily: 'Rissa'))), const SizedBox(height: 20), Wrap(spacing: 10, children: [ChoiceChip(label: const Text("Cửa", style: TextStyle(fontFamily: 'Rissa')), selected: c==CardCategory.door, onSelected: (_)=>setS(()=>c=CardCategory.door)), ChoiceChip(label: const Text("Xe", style: TextStyle(fontFamily: 'Rissa')), selected: c==CardCategory.parking, onSelected: (_)=>setS(()=>c=CardCategory.parking)), ChoiceChip(label: const Text("Bank", style: TextStyle(fontFamily: 'Rissa')), selected: c==CardCategory.bank, onSelected: (_)=>setS(()=>c=CardCategory.bank))]), const SizedBox(height: 20), ElevatedButton(onPressed: () { setState(() { cards.add(CardModel(n.text.isEmpty?"New":n.text, uid, Colors.blueAccent, Colors.grey, c)); _save(); }); Navigator.pop(ctx); }, child: const Text("Lưu", style: TextStyle(fontFamily: 'Rissa')))])), Theme.of(context).brightness == Brightness.dark))); }
  
  void _openQuickPay() { showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (c) => glBox(Column(children: [const SizedBox(height: 20), const Text("Quick Pay", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Rissa')), Expanded(child: ListView(children: cards.where((e)=>e.category==CardCategory.bank).map((e)=>Padding(padding: const EdgeInsets.all(10), child: _buildCard(e))).toList()))]), Theme.of(context).brightness == Brightness.dark)); }
  Widget _buildCard(CardModel c) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: [c.color1, c.color2]), borderRadius: BorderRadius.circular(15)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Rissa')), const SizedBox(height: 15), Text(c.number, style: const TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Rissa', fontWeight: FontWeight.bold))]));
  
  void _showiOSGlassMenu() { 
    showGeneralDialog(context: context, barrierDismissible: true, barrierLabel: "M", transitionDuration: const Duration(milliseconds: 300), pageBuilder: (ctx, a1, a2) => Align(alignment: Alignment.bottomCenter, child: Padding(padding: const EdgeInsets.only(bottom: 120, left: 20, right: 20), child: glBox(SizedBox(height: 480, child: SingleChildScrollView(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(20), child: GridView.count(crossAxisCount: 3, mainAxisSpacing: 15, crossAxisSpacing: 15, childAspectRatio: 0.8, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: [
      _mi(Icons.wallet, "Wallet", 0, ctx), _mi(Icons.camera, "Locket", 1, ctx), _mi(Icons.gamepad, "Games", 2, ctx), _mi(Icons.notifications, "Noti", 3, ctx), _mi(Icons.share, "LocalSend", 4, ctx), _mi(Icons.music_note, "Music", 5, ctx), _mi(Icons.note, "Notes", 6, ctx), _mi(Icons.chat_bubble, "Chat", 7, ctx) 
    ]))), Theme.of(context).brightness == Brightness.dark)))); 
  }
  
  Widget _mi(IconData i, String l, int idx, BuildContext ctx) { bool a = selectedIndex == idx; return GestureDetector(onTap: () { setState(() => selectedIndex = idx); Navigator.pop(ctx); }, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(height: 60, width: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: a ? Colors.amber : Colors.white10, border: Border.all(color: a ? Colors.amber : Colors.white24)), child: Icon(i, color: a ? Colors.black : Colors.white, size: 28)), const SizedBox(height: 10), Text(l, style: TextStyle(color: a ? Colors.amber : Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Rissa'), overflow: TextOverflow.ellipsis)])); }

  Widget _filterBtn(String label, CardCategory cat, IconData icon, bool isDark) { 
    bool isSelected = selectedFilter == cat; 
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); setState(() { selectedFilter = cat; expandedCardIndex = null; }); }, 
      child: glBox(Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: isSelected ? Colors.amberAccent : (isDark ? Colors.white54 : Colors.black54)), const SizedBox(width: 5), Text(label, style: TextStyle(color: isSelected ? Colors.amberAccent : (isDark ? Colors.white54 : Colors.black54), fontWeight: FontWeight.bold, fontFamily: 'Rissa', fontSize: 13))]), isDark, color: isSelected ? (isDark ? Colors.white24 : Colors.black87) : null, p: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), r: 25, m: const EdgeInsets.only(right: 10))
    ); 
  }

  @override Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: Stack(children: [
        SafeArea(bottom: false, child: FadeIndexedStack(index: selectedIndex, children: [
          Column(children: [const SizedBox(height: 20), Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("My Wallet", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: getAppTextColor(context), fontFamily: 'Rissa')), Row(children: [IconButton(icon: const Icon(Icons.add), onPressed: scanNFC), IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage(onClearData: () => setState(() { cards.clear(); transactions.clear(); LocalDataManager.clearAllData(); })))))])])), 
          SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Row(children: [_filterBtn("Ngân Hàng", CardCategory.bank, Icons.account_balance_wallet, isDark), _filterBtn("Thẻ Cửa", CardCategory.door, Icons.door_front_door, isDark), _filterBtn("Thẻ Xe", CardCategory.parking, Icons.local_parking, isDark)])),
          Expanded(child: ListView(padding: const EdgeInsets.all(20), children: cards.where((c) => c.category == selectedFilter).map((c) => Padding(padding: const EdgeInsets.only(bottom: 15), child: _buildCard(c))).toList()))]),
          isDesktop ? buildPCWarning("Locket Camera", Icons.camera_alt) : LocketCameraTab(isActive: selectedIndex == 1, transactions: transactions, onNewTransaction: (t) async { String p = await LocalDataManager.saveImage(File(t.imagePath!)); setState(() => transactions.add(Transaction(p, t.amount, t.note, t.date, t.type))); _save(); }),
          isDesktop ? buildPCWarning("Game Space", Icons.games) : const GameSpaceTab(), 
          isDesktop ? buildPCWarning("Notification Log", Icons.notifications) : const NotiLogTab(), 
          isDesktop ? buildPCWarning("Nearby Send", Icons.wifi_tethering) : const LocalSendTab(), 
          const MusicTab(), const NotesTab(),
          isDesktop ? buildPCWarning("Mesh LocalChat", Icons.chat_bubble) : const LocalChatTab()
        ])),
        if (selectedIndex != 7 || (selectedIndex == 7 && LocalChatTab.activeChatId == null))
          Positioned(bottom: isLandscape ? 10 : 30, left: 0, right: 0, child: Center(child: GestureDetector(onTap: _showiOSGlassMenu, child: glBox(const Padding(padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.widgets, color: Colors.white, size: 20), SizedBox(width: 10), Text("MENU", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Rissa'))])), isDark, r: 40)))),
        if (selectedIndex == 0 && !isLandscape) Positioned(bottom: 0, left: 0, right: 0, child: GestureDetector(onVerticalDragEnd: (d) { if (d.primaryVelocity! < -100) _openQuickPay(); }, onTap: _openQuickPay, child: Container(height: 25, color: Colors.transparent, alignment: Alignment.bottomCenter, padding: const EdgeInsets.only(bottom: 8), child: Container(width: 50, height: 5, decoration: BoxDecoration(color: isDark ? Colors.white38 : Colors.black26, borderRadius: BorderRadius.circular(10))))))
      ]),
    );
  }
}

// ================= LOCAL CHAT TAB (MESH OFFLINE + FULL QUALITY MMS + DOWNLOAD) =================
class LocalChatTab extends StatefulWidget {
  static String? activeChatId; 
  const LocalChatTab({super.key});
  @override State<LocalChatTab> createState() => _LocalChatTabState();
}

class _LocalChatTabState extends State<LocalChatTab> with SingleTickerProviderStateMixin {
  final Strategy strategy = Strategy.P2P_CLUSTER;
  String userName = "Khanh_" + math.Random().nextInt(100).toString();
  Map<String, Map<String, dynamic>> discoveredNodes = {}; 
  Map<String, String> connectedDevices = {}; 
  Map<String, List<ChatMessage>> chatHistory = {}; 
  Map<String, int> unreadCounts = {}; 
  Map<int, String> pendingChatImages = {}; 
  Map<int, String> chatTempPaths = {};     
  Set<int> finishedTransfers = {};         
  TextEditingController chatCtrl = TextEditingController();
  ScrollController scrollCtrl = ScrollController();
  late AnimationController _radarCtrl;
  OverlayEntry? _peekOverlay;
  OverlayEntry? _notiOverlay;

  @override void initState() { super.initState(); _radarCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(); _startMeshNetwork(); }
  @override void dispose() { _radarCtrl.dispose(); Nearby().stopAllEndpoints(); super.dispose(); }

  Future<bool> _req() async {
    // Đã gỡ bỏ Permission Wi-Fi. Ép ứng dụng dùng BLE.
    await [Permission.location, Permission.bluetooth, Permission.bluetoothScan, Permission.bluetoothAdvertise, Permission.bluetoothConnect].request();
    if (await Permission.location.serviceStatus.isDisabled) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bật GPS & Bluetooth để Chat Offline!", style: TextStyle(fontFamily: 'Rissa', fontSize: 14)), backgroundColor: Colors.orange)); } 
    return true;
  }

  void _startMeshNetwork() async {
    if (!await _req()) return; await Nearby().stopAllEndpoints(); discoveredNodes.clear(); connectedDevices.clear(); if (mounted) setState(() {});
    try {
      await Nearby().startAdvertising(userName, strategy, onConnectionInitiated: _onConnectionInitiated, onConnectionResult: (id, status) { if (status == Status.CONNECTED) setState(() {}); }, onDisconnected: (id) => setState(() => connectedDevices.remove(id)), serviceId: "com.coop.meshchat");
      await Nearby().startDiscovery(userName, strategy, onEndpointFound: (id, name, serviceId) { if (!connectedDevices.containsKey(id)) { double a = math.Random().nextDouble()*2*math.pi, r = 0.3 + math.Random().nextDouble()*0.5; setState(() => discoveredNodes[id] = {'name': name.split(" :: ")[0], 'type': name.contains(" :: ") ? name.split(" :: ")[1] : 'phone', 'pos': Offset(math.cos(a)*r, math.sin(a)*r), 'rawName': name}); } }, onEndpointLost: (id) => setState(()=> discoveredNodes.remove(id)), serviceId: "com.coop.meshchat");
    } catch (e) {}
  }

  void _requestConnect(String id, String name) async {
    bool ok = await showDialog(context: context, builder: (c) => AlertDialog(backgroundColor: const Color(0xFF1E1E1E), title: const Text("Kết nối", style: TextStyle(color: Colors.white, fontFamily: 'Rissa')), content: Text("Bạn có muốn kết nối với $name không?", style: const TextStyle(color: Colors.white70, fontFamily: 'Rissa', fontSize: 16)), actions: [TextButton(onPressed: ()=>Navigator.pop(c, false), child: const Text("Hủy", style: TextStyle(color: Colors.redAccent))), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent), onPressed: ()=>Navigator.pop(c, true), child: const Text("Kết nối"))])) ?? false;
    if (ok) Nearby().requestConnection(userName, id, onConnectionInitiated: _onConnectionInitiated, onConnectionResult: (id, status) {}, onDisconnected: (id) => setState(() => connectedDevices.remove(id)));
  }

  void _checkAndProcessImage(int pId) async {
    if (pendingChatImages.containsKey(pId) && chatTempPaths.containsKey(pId) && finishedTransfers.contains(pId)) {
      String peerId = pendingChatImages[pId]!; String tempPath = chatTempPaths[pId]!;
      try { File tempFile = File(tempPath); if (await tempFile.exists()) { String newPath = await LocalDataManager.saveImage(tempFile); setState(() { if (!chatHistory.containsKey(peerId)) chatHistory[peerId] = []; chatHistory[peerId]!.add(ChatMessage(text: "Đã gửi 1 ảnh", isMe: false, time: DateTime.now(), imagePath: newPath)); if (LocalChatTab.activeChatId != peerId) { unreadCounts[peerId] = (unreadCounts[peerId] ?? 0) + 1; _showInAppNotification(connectedDevices[peerId] ?? "Người lạ", "Đã gửi 1 ảnh 🖼️"); } else { _scrollToBottom(); } }); } } catch (e) {}
      pendingChatImages.remove(pId); chatTempPaths.remove(pId); finishedTransfers.remove(pId);
    }
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) async {
    bool ok = await showDialog(context: context, builder: (c) => AlertDialog(backgroundColor: const Color(0xFF1E1E1E), title: const Text("Yêu cầu Chat", style: TextStyle(color: Colors.white, fontFamily: 'Rissa')), content: Text("Máy ${info.endpointName} muốn kết nối chat. Đồng ý?", style: const TextStyle(color: Colors.white70, fontFamily: 'Rissa', fontSize: 16)), actions: [TextButton(onPressed: ()=>Navigator.pop(c, false), child: const Text("Từ chối", style: TextStyle(color: Colors.redAccent))), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: ()=>Navigator.pop(c, true), child: const Text("Chấp nhận"))])) ?? false;
    if (ok) {
      Nearby().acceptConnection(id, onPayLoadRecieved: (endId, payload) {
        if (payload.type == PayloadType.BYTES) {
          String text = utf8.decode(payload.bytes!);
          if (text.startsWith("TXT:")) {
            String actualMsg = text.substring(4); setState(() { if (!chatHistory.containsKey(endId)) chatHistory[endId] = []; chatHistory[endId]!.add(ChatMessage(text: actualMsg, isMe: false, time: DateTime.now())); if (LocalChatTab.activeChatId != endId) { unreadCounts[endId] = (unreadCounts[endId] ?? 0) + 1; _showInAppNotification(connectedDevices[endId] ?? "Người lạ", actualMsg); } else { _scrollToBottom(); } });
          } else if (text.startsWith("IMG:")) { int pId = int.parse(text.substring(4)); pendingChatImages[pId] = endId; _checkAndProcessImage(pId); }
        } else if (payload.type == PayloadType.FILE) { chatTempPaths[payload.id] = payload.filePath!; _checkAndProcessImage(payload.id); }
      }, onPayloadTransferUpdate: (endId, update) async { if (update.status == PayloadStatus.SUCCESS) { finishedTransfers.add(update.id); _checkAndProcessImage(update.id); } });
      setState(() { discoveredNodes.remove(id); connectedDevices[id] = info.endpointName; if (!chatHistory.containsKey(id)) chatHistory[id] = []; unreadCounts.putIfAbsent(id, () => 0); });
    } else { Nearby().rejectConnection(id); }
  }

  void _showInAppNotification(String senderName, String message) {
    HapticFeedback.vibrate(); _notiOverlay?.remove();
    _notiOverlay = OverlayEntry(builder: (context) => Positioned(top: 50, left: 20, right: 20, child: Material(color: Colors.transparent, child: TweenAnimationBuilder<double>(tween: Tween<double>(begin: -100.0, end: 0.0), duration: const Duration(milliseconds: 300), curve: Curves.easeOutBack, builder: (context, val, child) => Transform.translate(offset: Offset(0, val), child: glBox(Padding(padding: const EdgeInsets.all(15), child: Row(children: [const CircleAvatar(backgroundColor: Colors.blueAccent, radius: 20, child: Icon(Icons.chat_bubble, color: Colors.white, size: 20)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(senderName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Rissa', fontSize: 16)), Text(message, style: const TextStyle(color: Colors.white70, fontFamily: 'Rissa', fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)]))])), Theme.of(context).brightness == Brightness.dark))))));
    Overlay.of(context).insert(_notiOverlay!); Future.delayed(const Duration(seconds: 3), () { _notiOverlay?.remove(); _notiOverlay = null; });
  }

  void _sendText(String peerId) { if (chatCtrl.text.isEmpty) return; String msg = chatCtrl.text; Nearby().sendBytesPayload(peerId, Uint8List.fromList(utf8.encode("TXT:$msg"))); setState(() { chatHistory[peerId]!.add(ChatMessage(text: msg, isMe: true, time: DateTime.now())); chatCtrl.clear(); }); _scrollToBottom(); }
  
  // GỬI ẢNH NGUYÊN BẢN (KHÔNG NÉN)
  void _sendImageMMS(String peerId) async { 
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery); 
    if (image != null) { 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đang gửi ảnh gốc qua Bluetooth, vui lòng đợi...", style: TextStyle(fontFamily: 'Rissa'))));
      int payloadId = await Nearby().sendFilePayload(peerId, image.path); 
      Nearby().sendBytesPayload(peerId, Uint8List.fromList(utf8.encode("IMG:$payloadId"))); 
      setState(() { chatHistory[peerId]!.add(ChatMessage(text: "Đã gửi ảnh", isMe: true, time: DateTime.now(), imagePath: image.path)); }); 
      _scrollToBottom(); 
    } 
  }
  
  void _scrollToBottom() { Future.delayed(const Duration(milliseconds: 100), () { if (scrollCtrl.hasClients) scrollCtrl.animateTo(scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); }); }

  // TRÌNH XEM ẢNH ZOOM & NÚT DOWNLOAD
  void _showImageFullScreen(String path) { 
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      backgroundColor: Colors.black, 
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: () async {
            await File(path).copy('${LocalDataManager.publicDownloadFolder.path}/IMG_${DateTime.now().millisecondsSinceEpoch}.jpg');
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu ảnh vào thư mục Download", style: TextStyle(fontFamily: 'Rissa'))));
          })
        ]
      ), 
      extendBodyBehindAppBar: true,
      body: Center(child: InteractiveViewer(child: Image.file(File(path))))
    ))); 
  }

  void _showPeek(String peerId, String peerName) {
    HapticFeedback.heavyImpact(); List<ChatMessage> msgs = chatHistory[peerId] ?? []; bool isDark = Theme.of(context).brightness == Brightness.dark;
    _peekOverlay = OverlayEntry(builder: (context) => Material(color: Colors.transparent, child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), child: Center(child: TweenAnimationBuilder<double>(tween: Tween(begin: 0.8, end: 1.0), duration: const Duration(milliseconds: 200), curve: Curves.easeOutBack, builder: (context, scale, child) => Transform.scale(scale: scale, child: glBox(SizedBox(width: MediaQuery.of(context).size.width * 0.85, height: MediaQuery.of(context).size.height * 0.6, child: Column(children: [Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2)))), child: Row(children: [CircleAvatar(backgroundColor: Colors.blueAccent.withOpacity(0.2), child: Text(peerName[0].toUpperCase(), style: const TextStyle(color: Colors.blueAccent))), const SizedBox(width: 15), Text(peerName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: getAppTextColor(context), fontFamily: 'Rissa'))])), Expanded(child: ListView.builder(padding: const EdgeInsets.all(15), itemCount: msgs.length, itemBuilder: (c, i) => Align(alignment: msgs[i].isMe ? Alignment.centerRight : Alignment.centerLeft, child: glBox(Column(crossAxisAlignment: msgs[i].isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [ if(msgs[i].imagePath != null) Padding(padding: const EdgeInsets.only(bottom: 5), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(msgs[i].imagePath!), width: 150, fit: BoxFit.cover))), Text(msgs[i].text, style: TextStyle(color: msgs[i].isMe ? Colors.white : Colors.black87, fontFamily: 'Rissa', fontSize: 14))]), isDark, r: 15, color: msgs[i].isMe ? Colors.blueAccent : Colors.grey.shade300, p: const EdgeInsets.all(12), m: const EdgeInsets.only(bottom: 10)))))])), isDark)))))));
    Overlay.of(context).insert(_peekOverlay!);
  }
  void _hidePeek() { if (_peekOverlay != null) { _peekOverlay!.remove(); _peekOverlay = null; } }

  Widget _buildInboxView(bool isDark, Color txtColor) {
    return Column(children: [
      Padding(padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Chats & Radar", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: txtColor, fontFamily: 'Rissa')), CircleAvatar(backgroundColor: Colors.grey.withOpacity(0.2), child: IconButton(icon: const Icon(Icons.refresh, color: Colors.blueAccent), onPressed: _startMeshNetwork))])),
      SizedBox(height: 250, width: double.infinity, child: Stack(children: [
        Center(child: AnimatedBuilder(animation: _radarCtrl, builder: (c, w) => CustomPaint(painter: RadarPainter(_radarCtrl.value, Colors.blueAccent), size: const Size(200, 200)))),
        Center(child: Icon(currentDeviceType == 'tablet' ? Icons.tablet_mac : Icons.smartphone, size: 30, color: txtColor)),
        ...discoveredNodes.entries.map((e) => Align(alignment: FractionalOffset((e.value['pos'].dx+1)/2, (e.value['pos'].dy+1)/2), child: GestureDetector(onTap: () => _requestConnect(e.key, e.value['name']), child: glBox(Padding(padding: const EdgeInsets.all(8), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(e.value['type']=='tablet'?Icons.tablet_mac:Icons.smartphone, color: Colors.blueAccent, size: 20), Text(e.value['name'], style: TextStyle(fontSize: 10, color: txtColor, fontFamily: 'Rissa'))])), isDark, r: 15))))
      ])),
      Expanded(child: connectedDevices.isEmpty 
        ? Center(child: Text("Bấm vào máy trên Radar để bắt đầu Chat", style: TextStyle(color: Colors.grey.shade500, fontFamily: 'Rissa', fontSize: 14)))
        : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 10), itemCount: connectedDevices.length, itemBuilder: (context, index) {
          String peerId = connectedDevices.keys.elementAt(index); String peerName = connectedDevices[peerId]!; List<ChatMessage> msgs = chatHistory[peerId] ?? []; String lastMsg = msgs.isNotEmpty ? (msgs.last.imagePath!=null?"[Hình ảnh]":msgs.last.text) : "Đã kết nối"; String time = msgs.isNotEmpty ? DateFormat('HH:mm').format(msgs.last.time) : ""; int unread = unreadCounts[peerId] ?? 0; bool hasUnread = unread > 0;
          return GestureDetector(
            onLongPressStart: (_) => _showPeek(peerId, peerName), onLongPressEnd: (_) => _hidePeek(),
            onTap: () { setState(() { LocalChatTab.activeChatId = peerId; unreadCounts[peerId] = 0; }); _scrollToBottom(); },
            child: glBox(Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), child: Row(children: [
              CircleAvatar(radius: 25, backgroundColor: Colors.blueAccent.withOpacity(0.2), child: Text(peerName[0].toUpperCase(), style: const TextStyle(color: Colors.blueAccent, fontSize: 20, fontWeight: FontWeight.bold))), const SizedBox(width: 15),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(peerName, style: TextStyle(color: txtColor, fontSize: 16, fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600, fontFamily: 'Rissa')), const SizedBox(height: 5), Text(lastMsg, style: TextStyle(color: hasUnread ? txtColor : Colors.grey, fontSize: 13, fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal, fontFamily: 'Rissa'), maxLines: 1, overflow: TextOverflow.ellipsis)])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(time, style: const TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'Rissa')), const SizedBox(height: 5), if (hasUnread) Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle), child: Text(unread.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))])
            ])), isDark, m: const EdgeInsets.only(bottom: 10))
          );
        }))
    ]);
  }

  Widget _buildChatRoom(bool isDark, Color txtColor) {
    String peerId = LocalChatTab.activeChatId!; String peerName = connectedDevices[peerId] ?? "Người lạ"; List<ChatMessage> msgs = chatHistory[peerId] ?? [];
    return Column(children: [
      glBox(Padding(padding: const EdgeInsets.only(top: 15, bottom: 10, left: 10, right: 10), child: Row(children: [
        IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.blueAccent, size: 20), onPressed: () => setState(() => LocalChatTab.activeChatId = null)),
        CircleAvatar(radius: 16, backgroundColor: Colors.blueAccent.withOpacity(0.2), child: Text(peerName[0].toUpperCase(), style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(peerName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: txtColor, fontFamily: 'Rissa')), const Text("Đang hoạt động", style: TextStyle(fontSize: 10, color: Colors.green))]))
      ])), isDark, r: 0),
      Expanded(child: ListView.builder(controller: scrollCtrl, padding: const EdgeInsets.all(15).copyWith(bottom: 20), itemCount: msgs.length, itemBuilder: (context, index) {
        final m = msgs[index]; return Align(alignment: m.isMe ? Alignment.centerRight : Alignment.centerLeft, child: glBox(Column(crossAxisAlignment: m.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [if(m.imagePath != null) GestureDetector(onTap: () => _showImageFullScreen(m.imagePath!), child: Padding(padding: const EdgeInsets.only(bottom: 5), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(m.imagePath!), width: 180, fit: BoxFit.cover)))), Text(m.text, style: TextStyle(color: m.isMe ? Colors.white : txtColor, fontSize: 14, fontFamily: 'Rissa'))]), isDark, r: 20, color: m.isMe ? Colors.blueAccent.withOpacity(0.8) : null, m: const EdgeInsets.only(bottom: 10), p: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)));
      })),
      glBox(Padding(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10).copyWith(bottom: 90), child: Row(children: [
        GestureDetector(onTap: () => _sendImageMMS(peerId), child: const Icon(Icons.image, color: Colors.blueAccent, size: 28)), const SizedBox(width: 10),
        Expanded(child: glBox(TextField(controller: chatCtrl, style: TextStyle(color: txtColor, fontSize: 14, fontFamily: 'Rissa'), decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 15), border: InputBorder.none, hintText: "Nhắn tin...", hintStyle: TextStyle(fontSize: 13, color: txtColor.withOpacity(0.5)))), isDark, r: 25)),
        const SizedBox(width: 10), GestureDetector(onTap: () => _sendText(peerId), child: const Icon(Icons.send, color: Colors.blueAccent, size: 28)),
      ])), isDark, r: 0)
    ]);
  }

  @override Widget build(BuildContext context) { return LocalChatTab.activeChatId == null ? _buildInboxView(Theme.of(context).brightness == Brightness.dark, getAppTextColor(context)) : _buildChatRoom(Theme.of(context).brightness == Brightness.dark, getAppTextColor(context)); }
}

// ================= LOCAL SEND TAB (THÊM NÚT RADAR Ở CẠNH FILE PICKER) =================
class LocalSendTab extends StatefulWidget { const LocalSendTab({super.key}); @override State<LocalSendTab> createState() => _LocalSendTabState(); }
class _LocalSendTabState extends State<LocalSendTab> with SingleTickerProviderStateMixin {
  String userName = "Send_" + math.Random().nextInt(100).toString(); 
  List<File> filesToDrag = []; Map<String, Map<String, dynamic>> devices = {}; late AnimationController _radar; final ValueNotifier<double> progress = ValueNotifier(-1); Map<int, String> meta = {}; Map<int, String> paths = {}; String? nextName;

  @override void initState() { super.initState(); _radar = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(); _startEverything(); }
  @override void dispose() { _radar.dispose(); if(isMobile) Nearby().stopAllEndpoints(); super.dispose(); }
  
  Future<bool> _req() async { if(isDesktop)return false; await [Permission.location, Permission.bluetooth, Permission.bluetoothScan, Permission.bluetoothAdvertise, Permission.bluetoothConnect].request(); if (await Permission.location.serviceStatus.isDisabled) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bật GPS để quét Radar!"), backgroundColor: Colors.orange)); return false; } return true; }
  
  void _startEverything() async { 
    if(isDesktop)return; await Nearby().stopAllEndpoints(); devices.clear(); if (mounted) setState((){}); if (!await _req()) return; await Future.delayed(const Duration(milliseconds: 500)); 
    Nearby().startAdvertising(userName, Strategy.P2P_STAR, onConnectionInitiated: (id, info) async { 
      Nearby().acceptConnection(id, onPayLoadRecieved: (eid, p) async { 
        if (p.type == PayloadType.BYTES) { 
          String s = utf8.decode(p.bytes!); 
          if (s == "OK") { await Future.delayed(const Duration(milliseconds: 1500)); if(filesToDrag.isNotEmpty) Nearby().sendFilePayload(id, filesToDrag.first.path); } 
          else if (s.contains("|")) { 
            var parts = s.split("|"); String name = parts[0], size = parts[1]; nextName = name; 
            bool acc = await showDialog(context: context, builder: (c) => AlertDialog(backgroundColor: const Color(0xFF1E1E1E), content: Text("Máy ${info.endpointName} muốn gửi file $name $size MB. Đồng ý?", style: const TextStyle(color: Colors.white, fontFamily: 'Rissa', fontSize: 16)), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Từ chối", style: TextStyle(color: Colors.red))), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Chấp nhận"))])) ?? false; 
            if (acc) { progress.value = 0; Nearby().sendBytesPayload(id, Uint8List.fromList(utf8.encode("OK"))); } else { Nearby().disconnectFromEndpoint(id); } 
          } 
        } else if (p.type == PayloadType.FILE) { meta[p.id] = nextName!; paths[p.id] = p.filePath!; } 
      }, onPayloadTransferUpdate: (eid, u) async { 
        if (u.status == PayloadStatus.IN_PROGRESS) progress.value = u.bytesTransferred / u.totalBytes; 
        else if (u.status == PayloadStatus.SUCCESS) { 
          if (paths.containsKey(u.id)) { File f = File(paths[u.id]!); await f.copy('${LocalDataManager.publicDownloadFolder.path}/${meta[u.id]}'); } 
          progress.value = 1; Future.delayed(const Duration(seconds: 4), () { progress.value = -1; Nearby().disconnectFromEndpoint(eid); }); 
        } 
      }); 
    }, onConnectionResult: (id, s) {}, onDisconnected: (id) {}, serviceId: "com.coop.ls");
    Nearby().startDiscovery(userName, Strategy.P2P_STAR, onEndpointFound: (id, name, sid) { 
      var parts = name.split("::"); String n = parts[0], t = parts.length > 1 ? parts[1] : 'phone'; double a = math.Random().nextDouble()*2*math.pi, r = 0.5 + math.Random().nextDouble()*0.3; 
      setState(() => devices[id] = {'name': n, 'type': t, 'pos': Offset(math.cos(a)*r, math.sin(a)*r)}); 
    }, onEndpointLost: (id) => setState(() => devices.remove(id)), serviceId: "com.coop.ls"); 
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
      setState(() => filesToDrag.addAll(newFiles));
    }
  }

  @override Widget build(BuildContext context) { 
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      Padding(padding: const EdgeInsets.all(20), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("LocalSend", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'Rissa')), 
        Row(children: [
          GestureDetector(onTap: _startEverything, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.radar, color: Colors.blueAccent))),
          const SizedBox(width: 10),
          PopupMenuButton<String>(icon: const Icon(Icons.add_circle_outline, size: 28), color: isDark ? const Color(0xFF2C2C2E) : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), onSelected: _pickFiles, itemBuilder: (context) => [const PopupMenuItem(value: 'file', child: Row(children: [Icon(Icons.insert_drive_file), SizedBox(width: 10), Text("Tài liệu")])), const PopupMenuItem(value: 'image', child: Row(children: [Icon(Icons.image), SizedBox(width: 10), Text("Hình ảnh")])), const PopupMenuItem(value: 'video', child: Row(children: [Icon(Icons.videocam), SizedBox(width: 10), Text("Video")])), const PopupMenuItem(value: 'zip', child: Row(children: [Icon(Icons.folder_zip), SizedBox(width: 10), Text("Tệp nén")])), const PopupMenuItem(value: 'apk', child: Row(children: [Icon(Icons.android), SizedBox(width: 10), Text("Ứng dụng (APK)")]))])
        ])
      ])), 
      Expanded(
        child: Stack(
          children: [
            Center(child: AnimatedBuilder(animation: _radar, builder: (c, w) => CustomPaint(painter: RadarPainter(_radar.value, Colors.blueAccent)))), 
            Center(child: Icon(currentDeviceType == 'tablet' ? Icons.tablet_mac : Icons.smartphone, size: 40)), 
            ...devices.entries.map((e) => Align(
              alignment: FractionalOffset((e.value['pos'].dx+1)/2, (e.value['pos'].dy+1)/2), 
              child: DragTarget<File>(
                onAccept: (f) => _send(e.key, f), 
                builder: (c, cd, rd) => glBox(Column(mainAxisSize: MainAxisSize.min, children: [Icon(e.value['type']=='tablet'?Icons.tablet_mac:Icons.smartphone, color: cd.isNotEmpty?Colors.green:Colors.blueAccent, size: 28), const SizedBox(height: 5), Text(e.value['name'], style: const TextStyle(fontSize: 10, fontFamily: 'Rissa'))]), isDark, p: const EdgeInsets.all(8), r: 15)
              )
            )), 
            if (filesToDrag.isNotEmpty) 
              Positioned(
                bottom: 20, left: 0, right: 0, 
                child: SizedBox(
                  height: 60, 
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal, 
                    itemCount: filesToDrag.length, 
                    itemBuilder: (c, idx) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10), 
                      child: Draggable<File>(
                        data: filesToDrag[idx], 
                        feedback: const Icon(Icons.file_present, size: 50, color: Colors.blueAccent), 
                        child: Chip(backgroundColor: RobertColors.highlightPink, label: Text(filesToDrag[idx].path.split('/').last, style: const TextStyle(fontSize: 11, color: Colors.white, fontFamily: 'Rissa')))
                      )
                    )
                  )
                )
              )
          ]
        )
      ), 
      if (progress.value >= 0) LinearProgressIndicator(value: progress.value)
    ]); 
  }
  
  void _send(String id, File f) async { 
    await Nearby().requestConnection(userName, id, onConnectionInitiated: (id, info) { 
      Nearby().acceptConnection(id, onPayLoadRecieved: (eid, p) { 
        if (p.type == PayloadType.BYTES && utf8.decode(p.bytes!) == "OK") { Future.delayed(const Duration(milliseconds: 1500), () => Nearby().sendFilePayload(id, f.path)); } 
      }, onPayloadTransferUpdate: (eid, u) { 
        if (u.status == PayloadStatus.IN_PROGRESS) progress.value = u.bytesTransferred / u.totalBytes; 
        else if (u.status == PayloadStatus.SUCCESS) { progress.value = 1; Future.delayed(const Duration(seconds: 4), () { progress.value = -1; setState(()=>filesToDrag.remove(f)); Nearby().disconnectFromEndpoint(id); }); } 
      }); 
    }, onConnectionResult: (id, s) { 
      if (s == Status.CONNECTED) Nearby().sendBytesPayload(id, Uint8List.fromList(utf8.encode("${f.path.split('/').last}|${(f.lengthSync()/(1024*1024)).toStringAsFixed(1)}"))); 
    }, onDisconnected: (id) {}); 
  }
}

class RadarPainter extends CustomPainter { final double p; final Color c; RadarPainter(this.p, this.c); @override void paint(Canvas cv, Size s) { Paint pt = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5; for(int i=0;i<3;i++){ double r= ((p+i/3)%1)*s.width/2; pt.color=c.withOpacity(1-(p+i/3)%1); cv.drawCircle(s.center(Offset.zero), r, pt); } } @override bool shouldRepaint(RadarPainter old) => true; }

// ================= CÁC TAB KHÁC DƯỚI ĐÂY ĐÃ MINIFIED NHƯNG FULL TÍNH NĂNG VÀ ĐÚNG CÚ PHÁP =================

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
  Widget _infoRow(String title, String val, Color valColor) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Rissa')), Text(val, style: TextStyle(color: valColor, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Rissa'))])); 
  @override Widget build(BuildContext context) { 
    bool isDark = Theme.of(context).brightness == Brightness.dark; Color textColor = getAppTextColor(context); 
    return Scaffold(appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: textColor), title: Text("Cài đặt", style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 20, fontFamily: 'Rissa'))), body: ListView(padding: const EdgeInsets.all(20), children: [Row(children: [const Icon(Icons.palette, color: Colors.blueAccent), const SizedBox(width: 10), const Text("Giao diện", style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Rissa'))]), const SizedBox(height: 15), glBox(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SwitchListTile(activeColor: Colors.blueAccent, title: Text("Chế độ Tối (Dark Mode)", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Rissa')), value: isDarkModeNotifier.value, onChanged: (val) { HapticFeedback.lightImpact(); isDarkModeNotifier.value = val; }), const Divider(color: Colors.grey, height: 1), Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Màu chữ", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Rissa')), const SizedBox(height: 10), Wrap(spacing: 10, runSpacing: 10, children: [_colorBtn(null, "Mặc định"), _colorBtn(Colors.blue, "Xanh dương"), _colorBtn(Colors.greenAccent, "Ngọc"), _colorBtn(Colors.orangeAccent, "Cam"), _colorBtn(Colors.pinkAccent, "Hồng")])]))]), isDark, p: const EdgeInsets.symmetric(vertical: 10), m: const EdgeInsets.only(bottom: 30)), Row(children: [const Icon(Icons.memory, color: Colors.blueAccent), const SizedBox(width: 10), const Text("Thiết bị", style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Rissa'))]), const SizedBox(height: 15), glBox(Column(children: [_infoRow("OS", osVersion, Colors.greenAccent), _infoRow("Root", isRooted ? "Đã Root" : "An toàn", isRooted ? Colors.redAccent : Colors.greenAccent), _infoRow("USB Debug", isDevMode ? "Bật" : "Tắt", isDevMode ? Colors.orangeAccent : Colors.grey)]), isDark, p: const EdgeInsets.all(15), m: const EdgeInsets.only(bottom: 30)), Row(children: [const Icon(Icons.storage, color: Colors.blueAccent), const SizedBox(width: 10), const Text("Lưu trữ", style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Rissa'))]), const SizedBox(height: 15), glBox(Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Dung lượng Data", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Rissa')), Text(folderSizeStr, style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Rissa'))]), isDark, p: const EdgeInsets.all(15), m: const EdgeInsets.only(bottom: 10)), ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.1), foregroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 15)), icon: const Icon(Icons.delete_forever), label: const Text("Xóa dữ liệu"), onPressed: () { widget.onClearData(); Navigator.pop(context); })])); 
  } 
}

class LocketCameraTab extends StatefulWidget { final bool isActive; final List<Transaction> transactions; final Function(Transaction) onNewTransaction; const LocketCameraTab({super.key, required this.isActive, required this.transactions, required this.onNewTransaction}); @override State<LocketCameraTab> createState() => _LocketCameraTabState(); }
class _LocketCameraTabState extends State<LocketCameraTab> with WidgetsBindingObserver {
  CameraController? _c; bool _flash = false; @override void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); if (widget.isActive) _init(); }
  @override void didUpdateWidget(LocketCameraTab old) { super.didUpdateWidget(old); if (widget.isActive && !old.isActive) _init(); else if (!widget.isActive && old.isActive) _dispose(); }
  @override void didChangeAppLifecycleState(AppLifecycleState s) { if (s == AppLifecycleState.paused) _dispose(); else if (s == AppLifecycleState.resumed && widget.isActive) _init(); }
  @override void dispose() { WidgetsBinding.instance.removeObserver(this); _dispose(); super.dispose(); }
  void _init() async { if (cameras.isEmpty || isDesktop) return; _c = CameraController(cameras[0], ResolutionPreset.high, enableAudio: false); await _c!.initialize(); if (mounted) setState(() {}); }
  void _dispose() { _c?.dispose(); _c = null; }
  void _take() async { if (_c == null) return; final i = await _c!.takePicture(); final t = await Navigator.push(context, MaterialPageRoute(builder: (_) => LocketEditorScreen(imageFile: File(i.path)))); if (t != null) widget.onNewTransaction(t); }
  @override Widget build(BuildContext context) { if (!widget.isActive) return const Center(child: Text("Camera paused", style: TextStyle(fontFamily: 'Rissa'))); if (_c == null || !_c!.value.isInitialized) return const Center(child: CircularProgressIndicator()); return Column(children: [Expanded(child: Padding(padding: const EdgeInsets.all(10), child: ClipRRect(borderRadius: BorderRadius.circular(40), child: Stack(fit: StackFit.expand, children: [CameraPreview(_c!), Positioned(top: 20, left: 20, child: IconButton(icon: Icon(_flash ? Icons.flash_on : Icons.flash_off, color: Colors.white), onPressed: () => setState(() { _flash = !_flash; _c!.setFlashMode(_flash ? FlashMode.torch : FlashMode.off); }))) ])))), Padding(padding: const EdgeInsets.all(20), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [IconButton(icon: const Icon(Icons.photo_library, size: 30, color: Colors.white), onPressed: () async { var i = await ImagePicker().pickImage(source: ImageSource.gallery); if (i != null) { final t = await Navigator.push(context, MaterialPageRoute(builder: (_) => LocketEditorScreen(imageFile: File(i.path)))); if (t != null) widget.onNewTransaction(t); } }), GestureDetector(onTap: _take, child: Container(height: 80, width: 80, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.amber, width: 4)), child: Center(child: Container(height: 65, width: 65, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))))), IconButton(icon: const Icon(Icons.flip_camera_ios, size: 30, color: Colors.white), onPressed: _init)])), GestureDetector(onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (c) => HistoryBottomSheet(transactions: widget.transactions)), child: const Padding(padding: EdgeInsets.only(bottom: 100), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Lịch sử", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Rissa')), Icon(Icons.keyboard_arrow_down, color: Colors.white)])))]); }
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
    bool isDark = Theme.of(context).brightness == Brightness.dark; Color textColor = getAppTextColor(context); 
    return Column(children: [ Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), child: Row(children: [Text("Game Space", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Rissa'))])), Expanded(child: isLoading ? const Center(child: CircularProgressIndicator()) : apps.isEmpty ? Center(child: Text("Chưa có game tải về", style: TextStyle(color: textColor, fontSize: 16, fontFamily: 'Rissa'))) : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: apps.length, itemBuilder: (context, index) { Application app = apps[index]; return glBox(Row(children: [if (app is ApplicationWithIcon) ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.memory(app.icon, width: 60, height: 60)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(app.appName, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Rissa')), const SizedBox(height: 5), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(5)), child: Text(app.packageName, style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontFamily: 'Rissa'), maxLines: 1, overflow: TextOverflow.ellipsis))])), const SizedBox(width: 10), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, shape: const CircleBorder(), padding: const EdgeInsets.all(15)), onPressed: () => DeviceApps.openApp(app.packageName), child: const Icon(Icons.play_arrow, color: Colors.black))]), isDark, p: const EdgeInsets.all(15), m: const EdgeInsets.only(bottom: 15)); }))]); 
  } 
}

class NotiLogTab extends StatefulWidget { const NotiLogTab({super.key}); @override State<NotiLogTab> createState() => _NotiLogTabState(); }
class _NotiLogTabState extends State<NotiLogTab> { 
  List<NotiModel> notifications = []; bool isSelectionMode = false; Set<int> selectedIndexes = {}; 
  @override void initState() { super.initState(); _initNotiListener(); } 
  Future<void> _initNotiListener() async { 
    if(isDesktop)return;
    notifications = await LocalDataManager.loadNotis(); setState(() {}); 
    bool isGranted = await NotificationListenerService.isPermissionGranted(); 
    if (!isGranted) await NotificationListenerService.requestPermission(); 
    NotificationListenerService.notificationsStream.listen((event) async { 
      if (event.packageName == null || event.title == null) return; 
      if (event.title!.isEmpty && (event.content == null || event.content!.isEmpty)) return; 
      setState(() { notifications.insert(0, NotiModel(event.id.toString(), event.packageName!, event.title ?? "Không", event.content ?? "", DateTime.now())); }); 
      await LocalDataManager.saveNotis(notifications); 
    }); 
  } 
  void _deleteSelected() async { List<NotiModel> remaining = []; for (int i = 0; i < notifications.length; i++) { if (!selectedIndexes.contains(i)) remaining.add(notifications[i]); } setState(() { notifications = remaining; selectedIndexes.clear(); isSelectionMode = false; }); await LocalDataManager.saveNotis(notifications); HapticFeedback.vibrate(); } 
  @override Widget build(BuildContext context) { 
    bool isDark = Theme.of(context).brightness == Brightness.dark; Color textColor = getAppTextColor(context); 
    return Column(children: [ Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [if (isSelectionMode) ...[Text("Đã chọn ${selectedIndexes.length}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent, fontFamily: 'Rissa')), Row(children: [IconButton(icon: Icon(Icons.select_all, color: textColor), onPressed: () { setState(() { selectedIndexes = Set.from(Iterable.generate(notifications.length)); }); }), IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: _deleteSelected), IconButton(icon: Icon(Icons.close, color: textColor), onPressed: () => setState(() { isSelectionMode = false; selectedIndexes.clear(); }))])] else ...[Text("Noti Log", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Rissa')), const Icon(Icons.history, color: Colors.grey)]])), Expanded(child: notifications.isEmpty ? Center(child: Text("Nhật ký trống", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16, fontFamily: 'Rissa'))) : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: notifications.length, itemBuilder: (context, index) { NotiModel noti = notifications[index]; bool isSelected = selectedIndexes.contains(index); return GestureDetector(onLongPress: () { HapticFeedback.heavyImpact(); setState(() { isSelectionMode = true; selectedIndexes.add(index); }); }, onTap: () { if (isSelectionMode) { setState(() { if (isSelected) selectedIndexes.remove(index); else selectedIndexes.add(index); if (selectedIndexes.isEmpty) isSelectionMode = false; }); } }, child: glBox(Row(children: [if (isSelectionMode) ...[Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? Colors.redAccent : Colors.grey), const SizedBox(width: 15)], Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(noti.title, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Rissa'), maxLines: 1, overflow: TextOverflow.ellipsis)), Text(DateFormat('HH:mm').format(noti.timestamp), style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Rissa'))]), const SizedBox(height: 5), Text(noti.body, style: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Rissa'), maxLines: 2, overflow: TextOverflow.ellipsis)]))]), isDark, color: isSelected ? Colors.redAccent.withOpacity(0.2) : null, p: const EdgeInsets.all(15), m: const EdgeInsets.only(bottom: 10))); })) ]); 
  } 
}

class MusicTab extends StatefulWidget { const MusicTab({super.key}); @override State<MusicTab> createState() => _MusicTabState(); }
class _MusicTabState extends State<MusicTab> {
  final AudioPlayer _p = AudioPlayer(); bool isP = false; int cur = 0;
  @override void initState() { super.initState(); _p.onPlayerStateChanged.listen((s) => setState(() => isP = s == PlayerState.playing)); if (globalLocalSongs.value.isNotEmpty) _p.setSource(DeviceFileSource(globalLocalSongs.value[0]["path"]!)); }
  @override void dispose() { _p.dispose(); super.dispose(); }
  void _play(int i) { cur = i; _p.play(DeviceFileSource(globalLocalSongs.value[i]["path"]!)); }
  @override Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      Padding(padding: const EdgeInsets.all(20), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Music", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Rissa')), IconButton(icon: const Icon(Icons.add), onPressed: () async { var r = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.audio); if (r != null) { globalLocalSongs.value.addAll(r.paths.map((p) => {"title": p!.split('/').last, "artist": "Local", "path": p, "cover": ""})); LocalDataManager.saveLocalMusic(globalLocalSongs.value); setState((){}); } })])),
      Expanded(child: ListView.builder(itemCount: globalLocalSongs.value.length, itemBuilder: (c, i) => glBox(ListTile(title: Text(globalLocalSongs.value[i]["title"]!, maxLines: 1, style: const TextStyle(fontFamily: 'Rissa')), trailing: cur == i && isP ? const Icon(Icons.graphic_eq, color: Colors.red) : null, onTap: () => _play(i)), isDark, m: const EdgeInsets.symmetric(horizontal: 15, vertical: 5)))),
      if (globalLocalSongs.value.isNotEmpty) glBox(Padding(padding: const EdgeInsets.all(15), child: Row(children: [Expanded(child: Text(globalLocalSongs.value[cur]["title"]!, style: const TextStyle(color: Colors.white, fontFamily: 'Rissa'))), IconButton(icon: Icon(isP ? Icons.pause : Icons.play_arrow, color: Colors.white), onPressed: () => isP ? _p.pause() : _play(cur))])), isDark, color: const Color(0xFF212121), m: const EdgeInsets.symmetric(horizontal: 15).copyWith(bottom: 110), r: 50)
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
        onPanEnd: (d) { if (n.dy > MediaQuery.of(context).size.height - 150) notes.remove(n); LocalDataManager.saveNotes(notes); setState(() {}); },
        child: Container(width: n.w, height: n.h, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: RobertColors.note, borderRadius: BorderRadius.circular(10), border: Border.all(color: RobertColors.noteBorder, width: 2), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)]), child: Column(children: [
          Text("today's focus", style: TextStyle(fontSize: (n.w*0.1)*0.5, color: Colors.black54, fontFamily: 'Rissa')),
          Expanded(child: TextField(controller: TextEditingController(text: n.text)..selection=TextSelection.collapsed(offset: n.text.length), onChanged: (v){n.text=v; LocalDataManager.saveNotes(notes);}, maxLines: null, style: TextStyle(fontSize: n.w*0.1, fontFamily: 'Rissa'), decoration: const InputDecoration(border: InputBorder.none)))
        ])),
      ))),
      Positioned(bottom: 110, right: 20, child: glBox(IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: () { notes.add(NoteModel(id: "${DateTime.now().millisecondsSinceEpoch}", type: 's', text: "", dx: 50, dy: 100)); setState(() {}); }), isDark, color: Colors.blueAccent, r: 30)),
    ]));
  }
}
