import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import file main để truy cập MainScreen và AppColors
import 'main.dart';

class CinematicLogin extends StatefulWidget {
  const CinematicLogin({super.key});

  @override
  State<CinematicLogin> createState() => _CinematicLoginState();
}

class _CinematicLoginState extends State<CinematicLogin> with TickerProviderStateMixin {
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  String terminalText = "";
  final fullText = "Initializing secure environment...\nLoading core modules...\nBypassing network protocols...\nAccess Ready.";

  bool showLogin = false;
  bool loading = false;
  bool error = false;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _scanCtrl;

  @override
  void initState() {
    super.initState();
    
    // RUNG LẮC KHI SAI PASS
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    // LASER QUÉT KHI LOGIN
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    typeEffect();
  }

  void typeEffect() async {
    for (int i = 0; i < fullText.length; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (mounted) setState(() { terminalText += fullText[i]; });
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => showLogin = true);
    
    _triggerBiometric();
  }

  Future<void> _triggerBiometric() async {
    // Chỗ này sau này bạn mở comment để dùng FaceID tự động
    // bool success = await BiometricService().authenticate();
    // if (success) { Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen())); }
  }

  void login() async {
    setState(() { loading = true; error = false; });
    _scanCtrl.repeat(reverse: true); 
    HapticFeedback.lightImpact();

    await Future.delayed(const Duration(seconds: 2)); 

    setState(() { loading = false; _scanCtrl.stop(); _scanCtrl.reset(); });

    // 🕶️ AUTH LOGIC (Nhập 2026 để vào app)
    if (passCtrl.text == "2026") {
      HapticFeedback.mediumImpact();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
    } else {
      setState(() => error = true);
      HapticFeedback.heavyImpact();
      _shakeCtrl.forward(from: 0);
      passCtrl.clear();
    }
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _scanCtrl.dispose();
    userCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(seconds: 5),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF000000), Color(0xFF0A1922)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
          ),
          Positioned(
            top: 60, left: 20, right: 20,
            child: Text(terminalText, style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF66FCF1), fontSize: 14, height: 1.5)),
          ),
          if (loading)
            AnimatedBuilder(
              animation: _scanCtrl,
              builder: (context, child) {
                return Positioned(
                  top: _scanCtrl.value * MediaQuery.of(context).size.height,
                  left: 0, right: 0,
                  child: Container(height: 2, decoration: BoxDecoration(color: const Color(0xFF66FCF1), boxShadow: [BoxShadow(color: const Color(0xFF66FCF1).withOpacity(0.8), blurRadius: 20, spreadRadius: 5)])),
                );
              },
            ),
          if (showLogin)
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 800), opacity: showLogin ? 1 : 0,
                child: AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (context, child) => Transform.translate(offset: Offset(_shakeAnim.value, 0), child: child),
                  child: buildLoginPanel(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildLoginPanel() {
    return glBoxLogin(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onLongPress: () { HapticFeedback.vibrate(); },
              child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)), child: const Icon(Icons.security, size: 50, color: Color(0xFF66FCF1))),
            ),
            const SizedBox(height: 16),
            const Text("S Y S T E M   O V E R R I D E", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12)),
            const SizedBox(height: 30),
            buildInput(userCtrl, "ID / Alias", false),
            const SizedBox(height: 16),
            buildInput(passCtrl, "Passcode (2026)", true),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: loading ? null : login,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300), width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: loading ? const Color(0xFF66FCF1).withOpacity(0.2) : Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: loading ? const Color(0xFF66FCF1) : Colors.white24, width: 1.5), boxShadow: loading ? [const BoxShadow(color: Color(0xFF66FCF1), blurRadius: 15)] : []),
                child: Center(child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF66FCF1), strokeWidth: 2)) : const Text("INITIALIZE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2))),
              ),
            ),
            const SizedBox(height: 16),
            if (error) const Text("ACCESS DENIED. INTRUSION LOGGED.", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 11)),
            const SizedBox(height: 16),
            GestureDetector(onTap: _triggerBiometric, child: const Icon(Icons.fingerprint, color: Colors.white54, size: 32)),
          ],
        ),
      ),
    );
  }

  Widget buildInput(TextEditingController c, String hint, bool obscure) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
      child: TextField(
        controller: c, obscureText: obscure, style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white38, fontFamily: 'monospace'), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
      ),
    );
  }
}

Widget glBoxLogin({required Widget child}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        width: 320,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.15)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 30, spreadRadius: -5)]),
        child: child,
      ),
    ),
  );
}