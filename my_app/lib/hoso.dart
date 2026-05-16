import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class HoSoScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  const HoSoScreen({super.key, required this.currentUser});

  @override
  State<HoSoScreen> createState() => _HoSoScreenState();
}

class _HoSoScreenState extends State<HoSoScreen> {
  final ImagePicker _picker = ImagePicker();

  File? _avatarFile;
  String? _avatarUrl;

  late TextEditingController _nameController;
  late TextEditingController _bioController;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final email = widget.currentUser['email'];
      final data = await ApiService.getUserInfo(email);
      if (data != null && mounted) {
        setState(() {
          _nameController.text = data['name'] ?? email.split('@')[0];
          _bioController.text = data['bio'] ?? '';
          _avatarUrl = data['avatarUrl'];
        });
      }
    } catch (e) {
      debugPrint("❌ LoadProfile Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();

    if (name.isEmpty) {
      _showSnack('Tên không được để trống', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final email = widget.currentUser['email'];

      // Upload avatar nếu có chọn ảnh mới
      if (_avatarFile != null) {
        final url = await ApiService.uploadAvatar(file: _avatarFile!, email: email);
        if (url != null) {
          setState(() => _avatarUrl = url);
        } else {
          _showSnack('Lỗi upload ảnh, thử lại sau', isError: true);
          setState(() => _isSaving = false);
          return;
        }
      }

      // Lưu thông tin profile
      await ApiService.updateUserProfile(email, name, '', bio);

      if (mounted) {
        _showSnack('Đã lưu hồ sơ thành công!');
        // ✅ Trả về avatarUrl mới nhất để TaiKhoanScreen cập nhật ngay
        Navigator.pop(context, {
          'updated': true,
          'avatarUrl': _avatarUrl,
        });
      }
    } catch (e) {
      _showSnack('Lỗi lưu hồ sơ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked != null && mounted) {
        setState(() => _avatarFile = File(picked.path));
      }
    } catch (e) {
      _showSnack('Lỗi chọn ảnh: $e', isError: true);
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Thay đổi ảnh đại diện',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Chọn từ album'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Chụp ảnh mới'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_avatarFile != null || _avatarUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Xóa ảnh đại diện',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _avatarFile = null;
                      _avatarUrl = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider _getAvatarImage() {
    if (_avatarFile != null) return FileImage(_avatarFile!);
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) return NetworkImage(_avatarUrl!);
    return const AssetImage('assets/default_avatar.png');
  }

  bool get _hasAvatar => _avatarFile != null || (_avatarUrl != null && _avatarUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text('Sửa hồ sơ',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pinkAccent),
                  ),
                )
              : TextButton(
                  onPressed: _saveProfile,
                  child: const Text('Lưu',
                      style: TextStyle(
                          color: Colors.pinkAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Avatar ──
                  GestureDetector(
                    onTap: _showImageOptions,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [
                              Colors.purpleAccent,
                              Colors.orangeAccent,
                              Colors.pinkAccent,
                            ]),
                          ),
                          child: CircleAvatar(
                            radius: 52,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 48,
                              backgroundColor: const Color(0xFFF3F3F3),
                              backgroundImage: _hasAvatar ? _getAvatarImage() : null,
                              child: !_hasAvatar
                                  ? const Icon(Icons.person_rounded, size: 52, color: Colors.grey)
                                  : null,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _showImageOptions,
                    child: const Text('Thay đổi ảnh đại diện',
                        style: TextStyle(color: Colors.pinkAccent)),
                  ),
                  const SizedBox(height: 24),

                  // ── Tên (phần @) ──
                  _buildLabel('Tên hiển thị (@)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.black87), // ✅ chữ nhập đậm
                    decoration: _inputDecoration(hint: 'Nhập tên của bạn', prefix: '@'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),

                  // ── Tiểu sử ──
                  _buildLabel('Tiểu sử'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioController,
                    style: const TextStyle(color: Colors.black87), // ✅ chữ nhập đậm
                    decoration: _inputDecoration(hint: 'Viết gì đó về bạn...'),
                    maxLines: 4,
                    maxLength: 150,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 32),

                  // ── Nút Lưu ──
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Lưu hồ sơ',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
    );
  }

  InputDecoration _inputDecoration({required String hint, String? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38),       // ✅ hint rõ hơn
      prefixText: prefix,
      prefixStyle: const TextStyle(color: Colors.black87),     // ✅ dấu @ đậm
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.pinkAccent, width: 1.5),
      ),
    );
  }
}