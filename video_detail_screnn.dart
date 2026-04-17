import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'video_player_widget.dart';
import 'database_helper.dart';

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

class _VideoDetailScreenState extends State<VideoDetailScreen> with WidgetsBindingObserver {
  bool isLiked = false;
  int likeCount = 0;
  bool showUI = true;
  bool isActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInteractionData();
  }

  Future<void> _loadInteractionData() async {
    final db = await DatabaseHelper.instance.database;
    final liked = await DatabaseHelper.instance.isVideoLiked(widget.videoId, widget.currentUserEmail);
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM video_likes WHERE video_id = ?', 
      [widget.videoId]
    );

    if (mounted) {
      setState(() {
        isLiked = liked;
        likeCount = Sqflite.firstIntValue(res) ?? 0;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      setState(() => isActive = false);
    } else if (state == AppLifecycleState.resumed) {
      setState(() => isActive = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> toggleLike() async {
    await DatabaseHelper.instance.toggleLike(widget.videoId, widget.currentUserEmail);
    await Future.delayed(const Duration(milliseconds: 100));
    await _loadInteractionData();
  }

  // ✅ HÀM CHIA SẺ MỚI
  void _showShareDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(15),
              child: Text("Chia sẻ với bạn bè", 
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                // Giả định bạn đã có hàm lấy danh sách bạn bè trong DatabaseHelper
                future: DatabaseHelper.instance.getFriendsList(widget.currentUserEmail),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final friends = snapshot.data!;
                  return friends.isEmpty
                    ? const Center(child: Text("Không có bạn bè để chia sẻ", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          final friend = friends[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blueGrey,
                              backgroundImage: NetworkImage("https://i.pravatar.cc/150?u=${friend['email']}"),
                            ),
                            title: Text(friend['name'] ?? friend['email'].split('@')[0], 
                              style: const TextStyle(color: Colors.white)),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () async {
                                // Gọi hàm share từ DatabaseHelper
                                await DatabaseHelper.instance.shareVideo(
                                  senderEmail: widget.currentUserEmail,
                                  receiverEmail: friend['email'],
                                  videoId: widget.videoId,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Đã chia sẻ thành công!")),
                                  );
                                }
                              },
                              child: const Text("Gửi", style: TextStyle(color: Colors.white)),
                            ),
                          );
                        },
                      );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComments() {
    final TextEditingController controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("Bình luận", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: DatabaseHelper.instance.getComments(widget.videoId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final comments = snapshot.data!;
                    return comments.isEmpty
                        ? const Center(child: Text("Chưa có bình luận nào", style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                leading: const CircleAvatar(backgroundColor: Colors.blueGrey, radius: 15, child: Icon(Icons.person, size: 15, color: Colors.white)),
                                title: Text(comments[index]['user_email'].split('@')[0],
                                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                subtitle: Text(comments[index]['content'], style: const TextStyle(color: Colors.white)),
                              );
                            },
                          );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 10,
                  left: 10, right: 10, top: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Thêm bình luận...",
                          hintStyle: const TextStyle(color: Colors.white24),
                          filled: true,
                          fillColor: Colors.white10,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: () async {
                        if (controller.text.trim().isNotEmpty) {
                          await DatabaseHelper.instance.insertComment(
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
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, 
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, true);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            VideoPlayerWidget(
              videoPath: widget.videoPath,
              isActive: isActive,
              videoId: null, 
            ),

            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context, true), 
              ),
            ),

            Positioned(
              right: 15,
              bottom: 60,
              child: Column(
                children: [
                  // Nút Like
                  GestureDetector(
                    onTap: toggleLike,
                    child: Column(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.white,
                          size: 45,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          likeCount.toString(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Nút Comment
                  GestureDetector(
                    onTap: _showComments,
                    child: const Column(
                      children: [
                        Icon(Icons.comment, color: Colors.white, size: 40),
                        SizedBox(height: 5),
                        Text(
                          "Bình luận",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // ✅ NÚT CHIA SẺ MỚI
                  GestureDetector(
                    onTap: _showShareDialog,
                    child: const Column(
                      children: [
                        Icon(Icons.share, color: Colors.white, size: 40),
                        SizedBox(height: 5),
                        Text(
                          "Chia sẻ",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
