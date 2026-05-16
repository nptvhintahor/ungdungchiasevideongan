import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'video_player_widget.dart';
import 'api_service.dart';

class VideoDetailScreen extends StatefulWidget {
  final String videoPath;
  final int videoId;
  final String currentUserEmail;

  const VideoDetailScreen({
    super.key,
    required this.videoPath,
    required this.videoId,
    required this.currentUserEmail,
  });

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen>
    with WidgetsBindingObserver {
  bool isLiked = false;
  int likeCount = 0;
  bool isActive = true;
  bool _isDownloading = false;
  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInteractionData();
  }

  // ================= LOAD DATA =================
  Future<void> _loadInteractionData() async {
    try {
      final results = await Future.wait([
        ApiService.isVideoLiked(widget.videoId, widget.currentUserEmail),
        ApiService.getVideoById(widget.videoId), // ✅ dùng getVideoById thay getAllVideos — nhẹ hơn
      ]);

      final bool liked = results[0] as bool;
      final Map<String, dynamic>? video = results[1] as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          isLiked = liked;
          likeCount = video?['likes'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint("❌ LOAD INTERACTION ERROR: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (mounted) {
      setState(() {
        isActive = state == AppLifecycleState.resumed;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ================= LIKE =================
  Future<void> toggleLike() async {
    bool previousLiked = isLiked;
    int previousCount = likeCount;

    setState(() {
      isLiked = !isLiked;
      isLiked ? likeCount++ : likeCount--;
    });

    try {
      await ApiService.toggleLike(widget.videoId, widget.currentUserEmail);
    } catch (e) {
      if (mounted) {
        setState(() {
          isLiked = previousLiked;
          likeCount = previousCount;
        });
      }
    }
  }

  // ================= SHARE =================
  void _showShareDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: ApiService.getFriendsList(widget.currentUserEmail),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }

            final friends = snapshot.data ?? [];

            if (friends.isEmpty) {
              return const Center(
                child: Text("Không có bạn bè để chia sẻ",
                    style: TextStyle(color: Colors.grey)),
              );
            }

            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Text("Gửi đến bạn bè",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(
                            "https://i.pravatar.cc/150?u=${friend['email']}",
                          ),
                        ),
                        title: Text(
                          friend['name'] ?? friend['email'],
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent),
                          onPressed: () async {
                            await ApiService.shareVideo(
                              senderEmail: widget.currentUserEmail,
                              receiverEmail: friend['email'],
                              videoId: widget.videoId,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Đã chia sẻ thành công!")),
                              );
                            }
                          },
                          child: const Text("Gửi",
                              style: TextStyle(color: Colors.white)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ================= COMMENT =================
  void _showComments() {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 15),
              const Text("Bình luận",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const Divider(color: Colors.white24, height: 25),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: ApiService.getComments(widget.videoId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final comments = snapshot.data ?? [];
                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        final email = comment['user_email'] ?? '';
                        return ListTile(
                          // ✅ Avatar cập nhật theo tài khoản người bình luận
                          leading: FutureBuilder<Map<String, dynamic>?>(
                            future: ApiService.getUserInfo(email),
                            builder: (context, userSnapshot) {
                              final avatarUrl =
                                  userSnapshot.data?['avatarUrl'] as String?;
                              if (avatarUrl != null && avatarUrl.isNotEmpty) {
                                return CircleAvatar(
                                  backgroundImage: NetworkImage(avatarUrl),
                                  onBackgroundImageError: (_, __) {},
                                );
                              }
                              // Fallback: icon mặc định khi chưa có avatar
                              return const CircleAvatar(
                                child: Icon(Icons.person, size: 15),
                              );
                            },
                          ),
                          title: Text(email,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 11)),
                          subtitle: Text(comment['content'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14)),
                        );
                      },
                    );
                  },
                ),
              ),
              _buildCommentInput(controller, setModalState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentInput(
      TextEditingController controller, StateSetter setModalState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: const Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Thêm bình luận...",
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blueAccent),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await ApiService.insertComment(
                  widget.videoId,
                  widget.currentUserEmail,
                  controller.text.trim(),
                );
                controller.clear();
                setModalState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  // ================= XOÁ VIDEO =================
  void _confirmDeleteVideo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red, size: 24),
            SizedBox(width: 10),
            Text("Xoá video",
                style: TextStyle(color: Colors.white, fontSize: 17)),
          ],
        ),
        content: const Text(
          "Video sẽ bị xoá vĩnh viễn khỏi hệ thống và không thể khôi phục. Bạn có chắc chắn?",
          style: TextStyle(color: Colors.white60, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Huỷ", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteVideo();
            },
            child: const Text("Xoá",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVideo() async {
    _showLoadingDialog("Đang xoá video...");
    try {
      final success = await ApiService.deleteVideo(widget.videoId);
      if (!mounted) return;
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đã xoá video thành công!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Xoá thất bại. Thử lại sau."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ================= TẢI VIDEO =================
  Future<bool> _requestPermission() async {
    if (!Platform.isAndroid) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }

    final videoStatus = await Permission.videos.status;
    if (videoStatus != PermissionStatus.permanentlyDenied) {
      if (videoStatus.isGranted) return true;
      final result = await Permission.videos.request();
      if (result.isGranted) return true;
      if (result.isPermanentlyDenied && mounted) _showOpenSettingsDialog();
      return false;
    }

    final storageStatus = await Permission.storage.status;
    if (storageStatus.isGranted) return true;
    final result = await Permission.storage.request();
    if (result.isGranted) return true;
    if (result.isPermanentlyDenied && mounted) _showOpenSettingsDialog();
    return false;
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.orange, size: 22),
            SizedBox(width: 10),
            Text("Cần cấp quyền",
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: const Text(
          "Quyền đã bị từ chối vĩnh viễn.\nVui lòng vào Cài đặt → Ứng dụng → Quyền → bật quyền Video/Lưu trữ.",
          style: TextStyle(color: Colors.white60, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Huỷ", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text("Mở Cài đặt",
                style: TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadVideo() async {
    final granted = await _requestPermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Chưa được cấp quyền lưu trữ!"),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    try {
      final String videoUrl = ApiService.getVideoUrl(widget.videoPath);
      final response =
          await http.Client().send(http.Request('GET', Uri.parse(videoUrl)));
      final contentLength = response.contentLength ?? 0;

      Directory saveDir;
      if (Platform.isAndroid) {
        final dcim = Directory('/storage/emulated/0/DCIM/Videos');
        final download = Directory('/storage/emulated/0/Download');
        if (await dcim.exists()) {
          saveDir = dcim;
        } else if (await download.exists()) {
          saveDir = download;
        } else {
          await download.create(recursive: true);
          saveDir = download;
        }
      } else {
        saveDir = await getApplicationDocumentsDirectory();
      }

      final fileName =
          "video_${widget.videoId}_${DateTime.now().millisecondsSinceEpoch}.mp4";
      final file = File('${saveDir.path}/$fileName');
      final sink = file.openWrite();

      int downloaded = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloaded += chunk.length;
        if (contentLength > 0 && mounted) {
          setState(() => _downloadProgress = downloaded / contentLength);
        }
      }
      await sink.close();

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Đã lưu vào: ${saveDir.path}/$fileName"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Tải thất bại: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ================= MENU 3 CHẤM =================
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.download_rounded,
                    color: Colors.blueAccent, size: 22),
              ),
              title: const Text("Tải video về",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              subtitle: const Text("Lưu vào bộ nhớ thiết bị",
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _downloadVideo();
              },
            ),
            const Divider(
                color: Colors.white10, height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_forever_rounded,
                    color: Colors.red, size: 22),
              ),
              title: const Text("Xoá video",
                  style: TextStyle(
                      color: Colors.red,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              subtitle: const Text("Xoá vĩnh viễn khỏi hệ thống",
                  style: TextStyle(color: Colors.red, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteVideo();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ================= LOADING DIALOG =================
  void _showLoadingDialog(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const CircularProgressIndicator(color: Colors.pinkAccent),
            const SizedBox(width: 16),
            Text(msg, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    // ✅ FIX: Truyền videoPath gốc (không phải URL đầy đủ) vào VideoPlayerWidget
    // Widget sẽ tự xử lý việc build URL — tránh double-encode
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          VideoPlayerWidget(
            videoPath: widget.videoPath, // ✅ truyền path gốc, không gọi getVideoUrl() ở đây
            isActive: isActive,
            videoId: widget.videoId,
            currentUserEmail: widget.currentUserEmail,
          ),

          // Nút back
          Positioned(
            top: 50,
            left: 15,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, true),
              ),
            ),
          ),

          // Thanh tiến trình tải
          if (_isDownloading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _downloadProgress > 0 ? _downloadProgress : null,
                backgroundColor: Colors.white24,
                color: Colors.blueAccent,
                minHeight: 3,
              ),
            ),

          // Các nút action bên phải
          Positioned(
            right: 15,
            bottom: 80,
            child: Column(
              children: [
                _buildActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: likeCount.toString(),
                  color: isLiked ? Colors.red : Colors.white,
                  onTap: toggleLike,
                  iconSize: 40,
                ),
                const SizedBox(height: 25),
                _buildActionButton(
                  icon: Icons.comment,
                  label: "Bình luận",
                  onTap: _showComments,
                ),
                const SizedBox(height: 25),
                _buildActionButton(
                  icon: Icons.share,
                  label: "Chia sẻ",
                  onTap: _showShareDialog,
                ),
                const SizedBox(height: 25),
                _buildActionButton(
                  icon: Icons.more_horiz_rounded,
                  label: "Khác",
                  onTap: _showMoreOptions,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
    double iconSize = 35,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: iconSize),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}