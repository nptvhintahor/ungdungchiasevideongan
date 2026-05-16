import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'tiktok_screen.dart';

class DangNhapScreen extends StatefulWidget {
  const DangNhapScreen({super.key});

  @override
  State<DangNhapScreen> createState() => _DangNhapScreenState();
}

class _DangNhapScreenState extends State<DangNhapScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool rememberMe = false;
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadSavedLogin();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loadSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email');
    final savedPassword = prefs.getString('password');
    if (savedEmail != null && savedPassword != null && savedEmail.isNotEmpty) {
      emailController.text = savedEmail;
      passwordController.text = savedPassword;
      if (mounted) setState(() => rememberMe = true);
      await _doLogin(savedEmail, savedPassword);
    }
  }

  Future<void> _doLogin(String email, String password) async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final res = await ApiService.loginUser(email, password);
      if (!mounted) return;
      setState(() => isLoading = false);
      if (res != null && res.isNotEmpty) {
        res['email'] ??= email;
        if (rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('email', email);
          await prefs.setString('password', password);
        }
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => TikTokScreen(currentUser: res)),
        );
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('email');
        await prefs.remove('password');
        if (mounted) _showSnack("Sai tài khoản hoặc mật khẩu");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showSnack("Không kết nối được server");
    }
  }

  void login() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showSnack("Vui lòng nhập email và mật khẩu");
      return;
    }
    _doLogin(email, password);
  }

  void register() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showSnack("Vui lòng nhập email và mật khẩu");
      return;
    }
    setState(() => isLoading = true);
    try {
      final success = await ApiService.registerUser(email, password);
      if (!mounted) return;
      setState(() => isLoading = false);
      if (success) {
        _showSnack("Đăng ký thành công! Hãy đăng nhập.");
      } else {
        _showSnack("Đăng ký thất bại. Email có thể đã tồn tại.");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showSnack("Không kết nối được server");
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A1A2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // ── Background blobs ──
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Colors.pinkAccent.withOpacity(0.18),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Colors.purpleAccent.withOpacity(0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 60),

                      // ── Logo & Title ──
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF2D55), Color(0xFFBF5AF2)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.pinkAccent.withOpacity(0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 42,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "Chào mừng trở lại",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0D0D0D),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Đăng nhập để tiếp tục",
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF9E9E9E),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // ── Email ──
                      _buildLabel("Email"),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: emailController,
                        hint: "example@email.com",
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 20),

                      // ── Password ──
                      _buildLabel("Mật khẩu"),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: passwordController,
                        hint: "Nhập mật khẩu",
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscurePassword,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFFBDBDBD),
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Remember me ──
                      GestureDetector(
                        onTap: () => setState(() => rememberMe = !rememberMe),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: rememberMe
                                    ? Colors.pinkAccent
                                    : Colors.transparent,
                                border: Border.all(
                                  color: rememberMe
                                      ? Colors.pinkAccent
                                      : const Color(0xFFBDBDBD),
                                  width: 1.8,
                                ),
                              ),
                              child: rememberMe
                                  ? const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 14)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "Lưu đăng nhập",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF616161),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Login button ──
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF2D55), Color(0xFFBF5AF2)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pinkAccent.withOpacity(0.30),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: isLoading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5, color: Colors.white),
                                  )
                                : const Text(
                                    "Đăng nhập",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Divider ──
                      Row(
                        children: [
                          const Expanded(
                              child: Divider(color: Color(0xFFEEEEEE), thickness: 1.2)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              "hoặc",
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Expanded(
                              child: Divider(color: Color(0xFFEEEEEE), thickness: 1.2)),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ── Register button ──
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          onPressed: isLoading ? null : register,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF2D55),
                            side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            backgroundColor: Colors.white,
                          ),
                          child: const Text(
                            "Tạo tài khoản mới",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: Color(0xFF222222),
        letterSpacing: 0.1,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF0D0D0D), // ✅ Chữ đen đậm rõ khi nhập
        fontWeight: FontWeight.w500,
      ),
      cursorColor: Color(0xFFFF2D55),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFFBDBDBD),
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFFBDBDBD), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5), // ✅ dùng const hex thay vì Colors.grey[220]
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF2D55), width: 1.8),
        ),
      ),
    );
  }
}