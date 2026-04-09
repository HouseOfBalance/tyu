import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Import các module của bạn vào đây
// import '../main.dart'; // Chứa MainScreen thật
// import '../security/biometric_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool loading = false;
  bool isGlow = false; // Trigger Glow cho nút Login

  // 🔥 UPGRADE 2: SHAKE ANIMATION
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    
    // Setup Shake Effect (rung lắc ngang 5 lần)
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    // 🔥 UPGRADE 4: AUTO LOGIN BẰNG BIOMETRIC
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerBiometric();
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    userCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _triggerBiometric() async {
    // Tự động bật FaceID/Vân tay ngay khi mở màn hình
    // bool success = await BiometricService().authenticate();
    // if (success) { _goToRealApp(); }
  }

  void _handleLogin() async {
    setState(() { loading = true; isGlow = true; });
    HapticFeedback.lightImpact();

    await Future.delayed(const Duration(seconds: 1)); // Giả lập call API/DB
    setState(() { loading = false; isGlow = false; });

    // 🔥 UPGRADE 3: FAKE LOGIN MODE
    if (userCtrl.text == "admin" && passCtrl.text == "2026") {
      // 🔐 ĐÚNG PASS -> VÀO APP THẬT
      HapticFeedback.mediumImpact();
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
      print("🔓 VÀO APP THẬT");
      
    } else if (passCtrl.text == "0000") {
      // 😈 PASS GIẢ (Ví dụ: bị ép mở máy) -> VÀO APP FAKE
      HapticFeedback.lightImpact();
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FakeMainScreen()));
      print("🎭 VÀO APP GIẢ (CHỈ CÓ MÁY TÍNH / GIAO DIỆN TRỐNG)");

    } else {
      // ❌ SAI PASS -> RUNG LẮC (SHAKE)
      HapticFeedback.heavyImpact();
      _shakeCtrl.forward(from: 0.0);
      passCtrl.clear(); // Xóa pass nhập sai
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🌌 BACKGROUND: Gradient tối bí ẩn
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF070B11), Color(0xFF13202E)], // Darker vibe
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          /// 🧊 MAIN UI BỌC TRONG ANIMATION RUNG LẮC
          Center(
            child: AnimatedBuilder(
              animation: _shakeAnim,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnim.value, 0), // Trượt trục X
                  child: child,
                );
              },
              child: _buildGlassCard(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGlassCard() {
    return glBox(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// 😈 LOGO: HIDDEN TRIGGER
            GestureDetector(
              onLongPress: () {
                HapticFeedback.vibrate();
                // Bật menu ẩn hoặc Developer Mode
                print("🚨 SECRET MENU TRIGGERED");
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(10),
                  boxShadow: [BoxShadow(color: const Color(0xFF66FCF1).withAlpha(20), blurRadius: 20)],
                ),
                child: const Icon(Icons.security, size: 50, color: Color(0xFF66FCF1)),
              ),
            ),
            const SizedBox(height: 16),
            const Text("CO-OP VAULT", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2.0, fontFamily: 'Rissa')),
            const SizedBox(height: 32),

            /// USERNAME INPUT
            _buildInput(controller: userCtrl, hint: "Codename", icon: Icons.person_outline),
            const SizedBox(height: 16),

            /// PASSWORD INPUT
            _buildInput(controller: passCtrl, hint: "Passcode", icon: Icons.lock_outline, obscure: true),
            const SizedBox(height: 30),

            /// 🔥 UPGRADE 1: GLOW ANIMATION BUTTON
            GestureDetector(
              onTap: loading ? null : _handleLogin,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isGlow ? const Color(0xFF66FCF1).withAlpha(80) : Colors.white.withAlpha(20),
                  border: Border.all(color: isGlow ? const Color(0xFF66FCF1) : Colors.white24, width: 1.5),
                  boxShadow: isGlow ? [const BoxShadow(color: Color(0xFF66FCF1), blurRadius: 20)] : [],
                ),
                child: Center(
                  child: loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF66FCF1), strokeWidth: 2))
                      : const Text("ACCESS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            /// BIOMETRIC BUTTON
            GestureDetector(
              onTap: _triggerBiometric,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
                child: const Icon(Icons.fingerprint, size: 28, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput({required TextEditingController controller, required String hint, required IconData icon, bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, letterSpacing: 1.2),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white54),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

/// GLASS BOX REUSE (Với config chuẩn)
Widget glBox({required Widget child}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        width: 320, // Fix cứng width cho đẹp trên mọi màn hình
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(10), // Độ trong suốt 10%
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withAlpha(30), width: 1.5),
          gradient: LinearGradient(
            colors: [Colors.white.withAlpha(20), Colors.white.withAlpha(0)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 40, spreadRadius: -10)],
        ),
        child: child,
      ),
    ),
  );
}