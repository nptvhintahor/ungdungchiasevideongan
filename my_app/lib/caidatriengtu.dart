import 'package:flutter/material.dart';
import 'theme_notifier.dart';
import 'dangnhap.dart';
import 'api_service.dart';

class CaiDatRiengTuScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  const CaiDatRiengTuScreen({super.key, required this.currentUser});

  @override
  State<CaiDatRiengTuScreen> createState() => _CaiDatRiengTuScreenState();
}

class _CaiDatRiengTuScreenState extends State<CaiDatRiengTuScreen> {
  bool isNotificationOn = true;
  bool _isPasswordVisible = false;

  late String email;
  late String password;

  @override
  void initState() {
    super.initState();
    email = widget.currentUser['email'] ?? '';
    password = widget.currentUser['password'] ?? '';
  }

  // ─── Màu theo theme ──────────────────────────────────────────
  Color _bg(bool isDark) => isDark ? const Color(0xFF121212) : const Color(0xFFF7F7F7);
  Color _cardBg(bool isDark) => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color _titleColor(bool isDark) => isDark ? Colors.white : Colors.black87;
  Color _subtitleColor(bool isDark) => isDark ? Colors.white60 : Colors.black45;
  Color _sectionColor(bool isDark) => isDark ? Colors.white38 : Colors.grey;
  Color _dividerColor(bool isDark) => isDark ? Colors.white12 : Colors.black12;
  Color _fieldFill(bool isDark) => isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
  Color _fieldText(bool isDark) => isDark ? Colors.white : Colors.black87;
  Color _fieldHint(bool isDark) => isDark ? Colors.white38 : Colors.black38;
  Color _appBarBg(bool isDark) => isDark ? const Color(0xFF1A1A1A) : Colors.white;
  Color _arrowColor(bool isDark) => isDark ? Colors.white38 : Colors.black38;
  Color _handleBar(bool isDark) => isDark ? Colors.white24 : Colors.grey.shade300;

  // ─── Đăng xuất ───────────────────────────────────────────────
  void _handleLogout(bool isDark) {
    showDialog(
      context: context,
      builder: (_) => _buildConfirmDialog(
        isDark: isDark,
        icon: Icons.logout_rounded,
        iconColor: Colors.orange,
        title: 'Đăng xuất',
        message: 'Bạn có chắc chắn muốn thoát tài khoản không?',
        confirmLabel: 'Đăng xuất',
        confirmColor: Colors.orange,
        onConfirm: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DangNhapScreen()),
            (route) => false,
          );
        },
      ),
    );
  }

  // ─── Xoá tài khoản ───────────────────────────────────────────
  void _handleDeleteAccount(bool isDark) {
    showDialog(
      context: context,
      builder: (_) => _buildConfirmDialog(
        isDark: isDark,
        icon: Icons.delete_forever_rounded,
        iconColor: Colors.red,
        title: 'Xoá tài khoản',
        message: 'Hành động này không thể hoàn tác. Toàn bộ dữ liệu của bạn sẽ bị xoá vĩnh viễn.',
        confirmLabel: 'Xoá tài khoản',
        confirmColor: Colors.red,
        onConfirm: () async {
          Navigator.pop(context);
          _showLoadingDialog('Đang xoá tài khoản...');
          final success = await ApiService.deleteAccount(email);
          if (!mounted) return;
          Navigator.pop(context);
          if (success) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const DangNhapScreen()),
              (route) => false,
            );
          } else {
            _showSnack('Xoá tài khoản thất bại. Thử lại sau.', isError: true);
          }
        },
      ),
    );
  }

  // ─── Đổi mật khẩu (bottom sheet) ────────────────────────────
  void _showChangePasswordSheet(bool isDark) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool oldVisible = false;
    bool newVisible = false;
    bool confirmVisible = false;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(builder: (ctx, setModal) {
          Future<void> doChange() async {
            final oldPw = oldCtrl.text.trim();
            final newPw = newCtrl.text.trim();
            final confirmPw = confirmCtrl.text.trim();

            if (oldPw.isEmpty || newPw.isEmpty || confirmPw.isEmpty) {
              _showSnack('Vui lòng điền đầy đủ thông tin', isError: true);
              return;
            }
            if (newPw.length < 6) {
              _showSnack('Mật khẩu mới phải ít nhất 6 ký tự', isError: true);
              return;
            }
            if (newPw != confirmPw) {
              _showSnack('Mật khẩu xác nhận không khớp', isError: true);
              return;
            }

            setModal(() => isSaving = true);
            final success = await ApiService.changePassword(
              email: email,
              oldPassword: oldPw,
              newPassword: newPw,
            );
            setModal(() => isSaving = false);

            if (!mounted) return;
            if (success) {
              setState(() => password = newPw);
              Navigator.pop(ctx);
              _showSnack('Đổi mật khẩu thành công!');
            } else {
              _showSnack('Mật khẩu cũ không đúng hoặc lỗi máy chủ', isError: true);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: _cardBg(isDark),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _handleBar(isDark),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.lock_reset_rounded,
                            color: Colors.pinkAccent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text('Đổi mật khẩu',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _titleColor(isDark))),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _sheetLabel('Mật khẩu hiện tại', isDark),
                  const SizedBox(height: 8),
                  _passwordField(
                    controller: oldCtrl,
                    hint: 'Nhập mật khẩu hiện tại',
                    visible: oldVisible,
                    isDark: isDark,
                    onToggle: () => setModal(() => oldVisible = !oldVisible),
                  ),
                  const SizedBox(height: 16),

                  _sheetLabel('Mật khẩu mới', isDark),
                  const SizedBox(height: 8),
                  _passwordField(
                    controller: newCtrl,
                    hint: 'Ít nhất 6 ký tự',
                    visible: newVisible,
                    isDark: isDark,
                    onToggle: () => setModal(() => newVisible = !newVisible),
                  ),
                  const SizedBox(height: 16),

                  _sheetLabel('Xác nhận mật khẩu mới', isDark),
                  const SizedBox(height: 8),
                  _passwordField(
                    controller: confirmCtrl,
                    hint: 'Nhập lại mật khẩu mới',
                    visible: confirmVisible,
                    isDark: isDark,
                    onToggle: () => setModal(() => confirmVisible = !confirmVisible),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : doChange,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Xác nhận đổi mật khẩu',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────
  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool visible,
    required bool isDark,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      style: TextStyle(color: _fieldText(isDark)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _fieldHint(isDark)),
        filled: true,
        fillColor: _fieldFill(isDark),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.pinkAccent, width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            visible ? Icons.visibility : Icons.visibility_off,
            size: 20,
            color: isDark ? Colors.white38 : Colors.grey,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  Widget _sheetLabel(String text, bool isDark) => Text(
        text,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _subtitleColor(isDark)),
      );

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showLoadingDialog(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(color: Colors.pinkAccent),
            const SizedBox(width: 16),
            Text(msg),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmDialog({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    return AlertDialog(
      backgroundColor: _cardBg(isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _titleColor(isDark))),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: _subtitleColor(isDark), height: 1.4)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Huỷ', style: TextStyle(color: _subtitleColor(isDark))),
        ),
        TextButton(
          onPressed: onConfirm,
          child: Text(confirmLabel,
              style: TextStyle(color: confirmColor, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // ─── Section header ───────────────────────────────────────────
  Widget _sectionHeader(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 24, bottom: 6),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _sectionColor(isDark),
              letterSpacing: 1.1)),
    );
  }

  // ─── Card tile ────────────────────────────────────────────────
  Widget _cardTile({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _titleColor(isDark))),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(fontSize: 13, color: _subtitleColor(isDark)))
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: _arrowColor(isDark))
              : null),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeNotifier.themeMode,
      builder: (context, currentMode, _) {
        final isDark = currentMode == ThemeMode.dark;

        return Scaffold(
          backgroundColor: _bg(isDark),
          appBar: AppBar(
            backgroundColor: _appBarBg(isDark),
            elevation: 0,
            surfaceTintColor: _appBarBg(isDark),
            title: Text('Cài đặt & quyền riêng tư',
                style: TextStyle(
                    color: _titleColor(isDark),
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: _titleColor(isDark), size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ListView(
            children: [
              // ── TÀI KHOẢN ──────────────────────────────────────
              _sectionHeader('TÀI KHOẢN', isDark),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _cardBg(isDark),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _cardTile(
                      isDark: isDark,
                      icon: Icons.email_outlined,
                      iconColor: Colors.blue,
                      title: 'Email',
                      subtitle: email,
                    ),
                    Divider(height: 1, indent: 56, color: _dividerColor(isDark)),
                    _cardTile(
                      isDark: isDark,
                      icon: Icons.lock_outline_rounded,
                      iconColor: Colors.purple,
                      title: 'Mật khẩu',
                      subtitle: _isPasswordVisible
                          ? password
                          : '•' * password.length.clamp(6, 16),
                      trailing: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                        onPressed: () =>
                            setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                  ],
                ),
              ),

              // ── HỆ THỐNG ───────────────────────────────────────
              _sectionHeader('HỆ THỐNG', isDark),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _cardBg(isDark),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: Colors.indigo,
                          size: 20,
                        ),
                      ),
                      title: Text('Dark Mode',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _titleColor(isDark))),
                      value: isDark,
                      activeColor: Colors.pinkAccent,
                      onChanged: ThemeNotifier.toggleTheme,
                    ),
                    Divider(height: 1, indent: 56, color: _dividerColor(isDark)),
                    SwitchListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications_none_rounded,
                            color: Colors.orange, size: 20),
                      ),
                      title: Text('Thông báo',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _titleColor(isDark))),
                      value: isNotificationOn,
                      activeColor: Colors.pinkAccent,
                      onChanged: (v) => setState(() => isNotificationOn = v),
                    ),
                  ],
                ),
              ),

              // ── BẢO MẬT ────────────────────────────────────────
              _sectionHeader('BẢO MẬT', isDark),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _cardBg(isDark),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _cardTile(
                  isDark: isDark,
                  icon: Icons.lock_reset_rounded,
                  iconColor: Colors.teal,
                  title: 'Đổi mật khẩu',
                  subtitle: 'Cập nhật mật khẩu tài khoản',
                  onTap: () => _showChangePasswordSheet(isDark),
                ),
              ),

              // ── VÙNG NGUY HIỂM ─────────────────────────────────
              _sectionHeader('VÙNG NGUY HIỂM', isDark),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _cardBg(isDark),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _cardTile(
                      isDark: isDark,
                      icon: Icons.logout_rounded,
                      iconColor: Colors.orange,
                      title: 'Đăng xuất',
                      subtitle: 'Thoát khỏi tài khoản hiện tại',
                      onTap: () => _handleLogout(isDark),
                    ),
                    Divider(height: 1, indent: 56, color: _dividerColor(isDark)),
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.delete_forever_rounded,
                            color: Colors.red, size: 20),
                      ),
                      title: const Text('Xoá tài khoản',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.red)),
                      subtitle: const Text('Xoá vĩnh viễn, không thể khôi phục',
                          style: TextStyle(fontSize: 13, color: Colors.redAccent)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: Colors.red),
                      onTap: () => _handleDeleteAccount(isDark),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}