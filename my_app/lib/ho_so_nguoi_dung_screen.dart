import 'package:flutter/material.dart';
import 'api_service.dart';
import 'video_player_widget.dart';
import 'video_detail_screen.dart';

class HoSoNguoiDungScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String currentUserEmail;

  const HoSoNguoiDungScreen({
    super.key,
    required this.user,
    required this.currentUserEmail,
  });

  @override
  State<HoSoNguoiDungScreen> createState() => _HoSoNguoiDungScreenState();
}

class _HoSoNguoiDungScreenState extends State<HoSoNguoiDungScreen> {
  List<Map<String, dynamic>> videos = [];
  bool isLoading = true;
  int totalLikes = 0;
  int totalFriends = 0;
  String? avatarUrl;

  String relationshipStatus = 'none';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final targetEmail = widget.user['email'];

      final friendsList = await ApiService.getFriendsList(widget.currentUserEmail);
      final pendingList = await ApiService.getPendingRequests(widget.currentUserEmail);
      final likes = await ApiService.getTotalLikes(targetEmail);
      final friends = await ApiService.getTotalFriends(targetEmail);
      final userInfo = await ApiService.getUserInfo(targetEmail);

      if (!mounted) return;

      String status = 'none';
      if (friendsList.any((f) => f['email'] == targetEmail)) {
        status = 'friends';
      } else if (pendingList.any((r) => r['email'] == targetEmail)) {
        status = 'pending';
      }

      List<Map<String, dynamic>> videoList = [];
      if (status == 'friends') {
        videoList = await ApiService.getVideosByEmail(targetEmail);
      }

      // Lấy avatar từ getUserInfo (đã chuẩn hoá URL đầy đủ trong ApiService)
      String? avatar = userInfo?['avatarUrl'] as String?;
      if (avatar == null || avatar.isEmpty) {
        final raw = widget.user['avatar_url'] as String?;
        if (raw != null && raw.isNotEmpty) {
          avatar = raw.startsWith('http') ? raw : '${ApiService.baseUrl}$raw';
        }
      }

      setState(() {
        relationshipStatus = status;
        videos = videoList;
        totalLikes = likes;
        totalFriends = friends;
        avatarUrl = avatar;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Lỗi load profile: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleFriendAction() async {
    if (relationshipStatus != 'none') return;
    try {
      await ApiService.sendFriendRequest(
        widget.currentUserEmail,
        widget.user['email'],
      );
      if (mounted) {
        setState(() => relationshipStatus = 'pending');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã gửi lời mời kết bạn!")),
        );
      }
    } catch (e) {
      debugPrint("❌ Lỗi gửi yêu cầu: $e");
    }
  }

  void _confirmUnfriend() {
    final String name = widget.user['name'] ?? widget.user['email'].split('@')[0];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person_remove_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 10),
            Text("Huỷ kết bạn", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Text(
          "Bạn có chắc muốn huỷ kết bạn với $name không?",
          style: const TextStyle(color: Colors.white60, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Huỷ", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _unfriend();
            },
            child: const Text("Xác nhận",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _unfriend() async {
    try {
      final success = await ApiService.unfriend(
        widget.currentUserEmail,
        widget.user['email'],
      );
      if (!mounted) return;
      if (success) {
        setState(() {
          relationshipStatus = 'none';
          totalFriends = (totalFriends - 1).clamp(0, 999999);
          videos = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã huỷ kết bạn!"), backgroundColor: Colors.redAccent),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Huỷ kết bạn thất bại. Thử lại sau."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Lỗi huỷ kết bạn: $e");
    }
  }

  // Avatar thật từ server, fallback về pravatar nếu chưa có
  Widget _buildProfileAvatar() {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 48,
        backgroundColor: Colors.grey[900],
        backgroundImage: NetworkImage(avatarUrl!),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 48,
      backgroundColor: Colors.grey[900],
      backgroundImage: NetworkImage(
          "https://i.pravatar.cc/150?u=${widget.user['email']}"),
    );
  }

  @override
  Widget build(BuildContext context) {
    String name = widget.user['name'] ?? widget.user['email'].split('@')[0];
    bool isMe = widget.currentUserEmail == widget.user['email'];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        color: Colors.pinkAccent,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  _buildProfileAvatar(),
                  const SizedBox(height: 12),
                  Text(
                    "@${widget.user['email'].split('@')[0]}",
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatItem("Bạn bè", totalFriends.toString()),
                      _buildDivider(),
                      _buildStatItem("Lượt thích", totalLikes.toString()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildActionButton(),
                    ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      widget.user['bio'] ?? "Chưa có tiểu sử",
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white12, height: 1),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Icon(Icons.grid_on, color: Colors.white),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Colors.pinkAccent)),
              )
            else if (relationshipStatus != 'friends' && !isMe)
              SliverFillRemaining(child: _buildLockedState())
            else if (videos.isEmpty)
              SliverFillRemaining(child: _buildEmptyState())
            else
              SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final video = videos[index];
                    final videoUrl = ApiService.getVideoUrl(video['path']);
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoDetailScreen(
                              videoPath: video['path'],
                              videoId: video['id'],
                              currentUserEmail: widget.currentUserEmail,
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRect(
                            child: VideoPlayerWidget(
                              videoPath: videoUrl,
                              isActive: false,
                              videoId: video['id'],
                              currentUserEmail: widget.currentUserEmail,
                            ),
                          ),
                          Positioned(
                            left: 0, right: 0, bottom: 0, height: 36,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.black54, Colors.transparent],
                                ),
                              ),
                            ),
                          ),
                          _buildViewCount(video['views'] ?? 0),
                        ],
                      ),
                    );
                  },
                  childCount: videos.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 1.5,
                  mainAxisSpacing: 1.5,
                  childAspectRatio: 0.6,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (relationshipStatus == 'friends') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text("Bạn bè"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                disabledForegroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: _confirmUnfriend,
            icon: const Icon(Icons.person_remove_rounded, size: 16),
            label: const Text("Huỷ"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      );
    } else if (relationshipStatus == 'pending') {
      return SizedBox(
        width: double.infinity,
        height: 45,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white12),
          child: const Text("Đã gửi lời mời", style: TextStyle(color: Colors.white70)),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: 45,
        child: ElevatedButton(
          onPressed: _handleFriendAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text("Kết bạn", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }
  }

  Widget _buildLockedState() {
    String message;
    IconData icon;
    if (relationshipStatus == 'pending') {
      icon = Icons.hourglass_top_rounded;
      message = "Đang chờ chấp nhận lời mời\nkết bạn để xem video";
    } else {
      icon = Icons.lock_rounded;
      message = "Kết bạn để xem\nvideo của người này";
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white24, size: 56),
          const SizedBox(height: 14),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String count) {
    return Column(
      children: [
        Text(count,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 15, width: 1, color: Colors.white24,
      margin: const EdgeInsets.symmetric(horizontal: 30),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.video_library_outlined, color: Colors.white12, size: 60),
          SizedBox(height: 10),
          Text("Chưa có video nào", style: TextStyle(color: Colors.white24)),
        ],
      ),
    );
  }

  Widget _buildViewCount(int views) {
    return Positioned(
      left: 5, bottom: 5,
      child: Row(
        children: [
          const Icon(Icons.play_arrow_outlined, color: Colors.white, size: 16),
          Text(views.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}