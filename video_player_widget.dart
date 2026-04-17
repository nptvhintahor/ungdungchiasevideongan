import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'database_helper.dart';
import 'video_detail_screen.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoPath;
  final bool isActive;
  final int? videoId;
  final String? currentUserEmail;

  const VideoPlayerWidget({
    super.key,
    required this.videoPath,
    this.isActive = true,
    this.videoId,
    this.currentUserEmail,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  String? _currentPath;

  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _initVideo(widget.videoPath);
    _loadInteractionData();
  }

  Future<void> _loadInteractionData() async {
    if (widget.videoId == null || widget.currentUserEmail == null) return;

    final liked = await DatabaseHelper.instance.isVideoLiked(widget.videoId!, widget.currentUserEmail!);
    final db = await DatabaseHelper.instance.database;
    final res = await db.query('videos', where: 'id = ?', whereArgs: [widget.videoId]);

    if (mounted && res.isNotEmpty) {
      setState(() {
        _isLiked = liked;
        _likeCount = res.first['likes'] as int;
      });
    }
  }

  Future<void> _handleLike() async {
    if (widget.videoId == null || widget.currentUserEmail == null) return;
    await DatabaseHelper.instance.toggleLike(widget.videoId!, widget.currentUserEmail!);
    await _loadInteractionData();
  }

  Future<void> _initVideo(String path) async {
    if (_currentPath == path && _isInitialized) return;
    _currentPath = path;
    await _disposeController();

    try {
      final controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      
      if (!mounted || _currentPath != path) {
        await controller.dispose();
        return;
      }

      _controller = controller;
      _controller!.setLooping(true);
      _controller!.setVolume(widget.isActive ? 1.0 : 0.0);

      if (widget.isActive) {
        await _controller!.play();
      }

      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint("Video Error: $e");
    }
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      _initVideo(widget.videoPath);
      _loadInteractionData();
    } else if (_controller != null && _isInitialized) {
      if (widget.isActive) {
        _controller!.play();
        _controller!.setVolume(1.0);
      } else {
        _controller!.pause();
        _controller!.setVolume(0.0);
      }
    }
  }

  Future<void> _disposeController() async {
    _isInitialized = false;
    if (_controller != null) {
      final oldController = _controller;
      _controller = null;
      await oldController!.pause();
      await oldController.dispose();
    }
  }

  @override
  void dispose() {
    _currentPath = null;
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      // ClipRRect đảm bảo video không bao giờ tràn ra khỏi bo góc hoặc khung Container
      child: ClipRRect(
        child: !_isInitialized || _controller == null
            ? (widget.isActive 
                ? const Center(child: CircularProgressIndicator(color: Colors.white24, strokeWidth: 2)) 
                : Container(color: Colors.black)) 
            : Stack(
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (widget.videoId != null) {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoDetailScreen(
                              videoPath: widget.videoPath,
                              videoId: widget.videoId!,
                              currentUserEmail: widget.currentUserEmail ?? "",
                            ),
                          ),
                        );

                        if (result == true) {
                          _loadInteractionData();
                        }
                      } else {
                        if (_controller!.value.isPlaying) {
                          _controller!.pause();
                        } else {
                          _controller!.play();
                        }
                      }
                    },
                    // Giải pháp cho video nằm gọn trong khung
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: FittedBox(
                            // BoxFit.cover giúp video lấp đầy khung mà không bị hở, phần thừa sẽ bị cắt đi
                            fit: BoxFit.cover, 
                            child: SizedBox(
                              width: _controller!.value.size.width,
                              height: _controller!.value.size.height,
                              child: VideoPlayer(_controller!),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  if (widget.videoId != null && widget.isActive)
                    Positioned(
                      right: 15,
                      bottom: 100,
                      child: Column(
                        children: [
                          _buildSideAction(
                            icon: Icons.favorite,
                            color: _isLiked ? Colors.red : Colors.white,
                            label: _likeCount.toString(),
                            onTap: _handleLike,
                          ),
                          const SizedBox(height: 25),
                          _buildSideAction(
                            icon: Icons.message,
                            color: Colors.white,
                            label: "Bình luận",
                            onTap: () => _showCommentModal(context),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildSideAction({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Icon(icon, color: color, size: 40),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showCommentModal(BuildContext context) {
    final TextEditingController _commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                future: DatabaseHelper.instance.getComments(widget.videoId ?? 0),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final comments = snapshot.data!;
                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.blueGrey, radius: 15),
                        title: Text(comments[index]['user_email'].split('@')[0], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        subtitle: Text(comments[index]['content'], style: const TextStyle(color: Colors.white)),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 10, left: 10, right: 10, top: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Thêm bình luận...",
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: () async {
                      if (_commentController.text.trim().isNotEmpty) {
                        await DatabaseHelper.instance.insertComment(
                          widget.videoId!,
                          widget.currentUserEmail!,
                          _commentController.text.trim(),
                        );
                        _commentController.clear();
                        if (mounted) setState(() {});
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
    );
  }
}
