import 'package:flutter/material.dart';
import 'api_service.dart';

class ChiaSeScreen extends StatefulWidget {
  final int videoId;
  final String currentUserEmail;

  const ChiaSeScreen({
    super.key,
    required this.videoId,
    required this.currentUserEmail,
  });

  @override
  State<ChiaSeScreen> createState() => _ChiaSeScreenState();
}

class _ChiaSeScreenState extends State<ChiaSeScreen> {
  List<Map<String, dynamic>> friends = [];
  List<Map<String, dynamic>> filteredFriends = [];
  bool isLoading = true;
  
  // Quản lý danh sách email đã bấm gửi
  final Set<String> _sentEmails = {};

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final list = await ApiService.getFriendsList(widget.currentUserEmail);
      if (mounted) {
        setState(() {
          friends = list;
          filteredFriends = list;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Lỗi tải bạn bè: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _filterFriends(String query) {
    setState(() {
      filteredFriends = friends
          .where((f) =>
              (f['name'] ?? "").toLowerCase().contains(query.toLowerCase()) ||
              f['email'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _shareToFriend(String receiverEmail, String receiverName) async {
    if (_sentEmails.contains(receiverEmail)) return;

    // Hiển thị phản hồi ngay lập tức trên nút bấm (Optimistic UI)
    setState(() {
      _sentEmails.add(receiverEmail);
    });

    try {
      bool success = await ApiService.shareVideo(
        senderEmail: widget.currentUserEmail,
        receiverEmail: receiverEmail,
        videoId: widget.videoId,
      );

      if (!success && mounted) {
        // Nếu lỗi thì hoàn tác trạng thái nút
        setState(() => _sentEmails.remove(receiverEmail));
        _showSnackBar("Không thể gửi đến $receiverName");
      }
    } catch (e) {
      debugPrint("❌ Lỗi chia sẻ: $e");
      if (mounted) setState(() => _sentEmails.remove(receiverEmail));
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF161722), // Màu nền tối đặc trưng TikTok
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Thanh kéo
          Container(
            width: 45,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
          ),
          
          const Text(
            "Gửi đến",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          
          // Thanh tìm kiếm
          TextField(
            onChanged: _filterFriends,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Tìm kiếm bạn bè...",
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.white24, size: 20),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),

          // Danh sách bạn bè
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
                : filteredFriends.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 10, bottom: 20),
                        itemCount: filteredFriends.length,
                        itemBuilder: (context, index) {
                          final friend = filteredFriends[index];
                          final email = friend['email'];
                          final name = friend['name'] ?? email.split('@')[0];
                          final isSent = _sentEmails.contains(email);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 5),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white10,
                              backgroundImage: NetworkImage("https://i.pravatar.cc/150?u=$email"),
                            ),
                            title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                            subtitle: Text(email, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                            trailing: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 75,
                              height: 32,
                              child: ElevatedButton(
                                onPressed: isSent ? null : () => _shareToFriend(email, name),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSent ? Colors.transparent : Colors.pinkAccent,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.white12,
                                  padding: EdgeInsets.zero,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    side: isSent ? const BorderSide(color: Colors.white10) : BorderSide.none,
                                  ),
                                ),
                                child: Text(
                                  isSent ? "Đã gửi" : "Gửi",
                                  style: TextStyle(
                                    fontSize: 13, 
                                    fontWeight: FontWeight.bold,
                                    color: isSent ? Colors.white38 : Colors.white
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.person_off_outlined, color: Colors.white10, size: 60),
        const SizedBox(height: 10),
        const Text("Không tìm thấy bạn bè", style: TextStyle(color: Colors.white24)),
      ],
    );
  }
}