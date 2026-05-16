import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'api_service.dart';

class UploadVideoScreen extends StatefulWidget {
  final String userEmail;
  const UploadVideoScreen({super.key, required this.userEmail});

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  File? videoFile;
  VideoPlayerController? _previewController;
  bool isUploading = false;
  String _uploadStatus = "";

  // ================= CHỌN VIDEO =================
  Future<void> pickVideo() async {
    try {
      final picked = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (picked != null) {
        await _previewController?.dispose();

        setState(() {
          videoFile = File(picked.path);
          _uploadStatus = "";
        });

        _previewController = VideoPlayerController.file(videoFile!);
        await _previewController!.initialize();

        if (!mounted) return;

        setState(() {});
        _previewController!.setLooping(true);
        _previewController!.setVolume(1.0);
        _previewController!.play();
      }
    } catch (e) {
      debugPrint("❌ Lỗi chọn video: $e");
      if (mounted) _showSnackBar("Không thể chọn video. Vui lòng thử lại.");
    }
  }

  // ================= ĐĂNG VIDEO =================
  Future<void> uploadVideo() async {
    if (videoFile == null) {
      _showSnackBar("Vui lòng chọn video trước!");
      return;
    }

    setState(() {
      isUploading = true;
      _uploadStatus = "Đang tải lên...";
    });

    _previewController?.pause();

    try {
      bool success = await ApiService.uploadVideo(
        file: videoFile!,
        userEmail: widget.userEmail,
      );

      if (success && mounted) {
        // ✅ Bước 1: Báo upload xong, đang chờ server xử lý
        setState(() => _uploadStatus = "Đang xử lý video...");
        _showSnackBar("✅ Đã tải lên! Đang xử lý...");

        // ✅ Bước 2: Chờ server encode xong (tránh spinner mãi khi vào lại)
        await Future.delayed(const Duration(seconds: 4));

        if (mounted) Navigator.pop(context, true);
      } else if (mounted) {
        setState(() {
          isUploading = false;
          _uploadStatus = "";
        });
        _showSnackBar("❌ Đăng tải thất bại. Vui lòng kiểm tra lại server!");
      }
    } catch (e) {
      debugPrint("🚨 Lỗi tại màn hình Upload: $e");
      if (mounted) {
        setState(() {
          isUploading = false;
          _uploadStatus = "";
        });
        _showSnackBar("Lỗi hệ thống: Không thể kết nối tới server.");
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _previewController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Tải lên Video",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            children: [
              // Preview
              GestureDetector(
                onTap: () {
                  if (_previewController != null &&
                      _previewController!.value.isInitialized) {
                    setState(() {
                      _previewController!.value.isPlaying
                          ? _previewController!.pause()
                          : _previewController!.play();
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: size.height * 0.55,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white12, width: 1),
                  ),
                  child: videoFile != null &&
                          _previewController != null &&
                          _previewController!.value.isInitialized
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AspectRatio(
                                aspectRatio:
                                    _previewController!.value.aspectRatio,
                                child: VideoPlayer(_previewController!),
                              ),
                              if (!_previewController!.value.isPlaying)
                                const Icon(Icons.play_circle_fill,
                                    color: Colors.white54, size: 60),
                            ],
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.video_library_outlined,
                                color: Colors.white24, size: 80),
                            SizedBox(height: 10),
                            Text("Chưa chọn video",
                                style: TextStyle(color: Colors.white38)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 30),

              // Trạng thái upload
              if (isUploading && _uploadStatus.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.pinkAccent),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _uploadStatus,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Nút chọn video
              _buildButton(
                onPressed: isUploading ? null : pickVideo,
                icon: Icons.add_photo_alternate_outlined,
                label: "CHỌN VIDEO TỪ MÁY",
                color: Colors.white10,
              ),

              const SizedBox(height: 15),

              // Nút đăng tải
              _buildButton(
                onPressed: (isUploading || videoFile == null)
                    ? null
                    : uploadVideo,
                icon: Icons.cloud_upload_rounded,
                label: isUploading ? _uploadStatus : "ĐĂNG LÊN NGAY",
                color: Colors.pinkAccent,
                isLoading: isUploading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Icon(icon),
        label: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(0.3),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }
}