import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'ho_so_nguoi_dung_screen.dart';

class KetBanScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const KetBanScreen({super.key, required this.currentUser});

  @override
  State<KetBanScreen> createState() => _KetBanScreenState();
}

class _KetBanScreenState extends State<KetBanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> searchResults = [];
  List<Map<String, dynamic>> friendsList = [];
  List<Map<String, dynamic>> friendRequests = [];

  bool isLoading = true;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  // ================= LOAD DATA =================
  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final email = widget.currentUser['email'];

      final results = await Future.wait([
        ApiService.getFriendsList(email),
        ApiService.getPendingRequests(email),
      ]);

      if (mounted) {
        setState(() {
          friendsList = List<Map<String, dynamic>>.from(results[0]);
          friendRequests = List<Map<String, dynamic>>.from(results[1]);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Lỗi load dữ liệu kết bạn: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ================= TÌM KIẾM (CÓ DEBOUNCE) =================
  void _onSearch(String value) {
    if (value.trim().isEmpty) {
      setState(() => searchResults = []);
      return;
    }

    setState(() => isSearching = true);

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final users =
            await ApiService.searchUsers(value, widget.currentUser['email']);
        if (mounted) {
          setState(() {
            searchResults = users;
            isSearching = false;
          });
        }
      } catch (e) {
        debugPrint("❌ Lỗi tìm kiếm: $e");
        if (mounted) setState(() => isSearching = false);
      }
    });
  }

  // ================= ACTIONS =================
  Future<void> _sendRequest(String targetEmail) async {
    try {
      await ApiService.sendFriendRequest(
          widget.currentUser['email'], targetEmail);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Đã gửi lời mời kết bạn!")),
        );
        _onSearch(_searchController.text);
      }
    } catch (e) {
      debugPrint("❌ Lỗi gửi yêu cầu: $e");
    }
  }

  Future<void> _acceptRequest(String requesterEmail) async {
    try {
      await ApiService.acceptFriendRequest(
          widget.currentUser['email'], requesterEmail);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎉 Đã trở thành bạn bè!")),
        );
        _loadAllData();
      }
    } catch (e) {
      debugPrint("❌ Lỗi chấp nhận: $e");
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ================= HELPER: BUILD AVATAR =================
  /// Ưu tiên avatar_url từ server, fallback về pravatar nếu chưa có
  Widget _buildAvatar(Map<String, dynamic> user) {
    final raw = user['avatar_url'] as String?;
    final String? avatarUrl = (raw != null && raw.isNotEmpty)
        ? (raw.startsWith('http') ? raw : '${ApiService.baseUrl}$raw')
        : null;

    if (avatarUrl != null) {
      return CircleAvatar(
        backgroundColor: Colors.grey[800],
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (_, __) {},
      );
    }

    // Fallback: pravatar dựa theo email
    return CircleAvatar(
      backgroundColor: Colors.grey[800],
      backgroundImage: NetworkImage(
          "https://i.pravatar.cc/150?u=${user['email']}"),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("Kết nối",
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.pinkAccent,
          labelColor: Colors.pinkAccent,
          unselectedLabelColor: Colors.grey,
          tabs: [
            const Tab(text: "Bạn bè"),
            const Tab(text: "Tìm kiếm"),
            Tab(
                text: friendRequests.isNotEmpty
                    ? "Lời mời (${friendRequests.length})"
                    : "Lời mời"),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsTab(),
                _buildSearchTab(),
                _buildRequestsTab(),
              ],
            ),
    );
  }

  Widget _buildFriendsTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: friendsList.isEmpty
          ? _buildEmptyState("Chưa có bạn bè nào", Icons.people_outline)
          : _buildUserList(friendsList, "friends"),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(15),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearch,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Nhập email hoặc tên...",
              hintStyle: const TextStyle(color: Colors.white24),
              prefixIcon:
                  const Icon(Icons.search, color: Colors.white24),
              suffixIcon: isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white54),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white10,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 15),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: searchResults.isEmpty &&
                  _searchController.text.isNotEmpty &&
                  !isSearching
              ? _buildEmptyState(
                  "Không tìm thấy người dùng", Icons.search_off)
              : searchResults.isEmpty
                  ? _buildEmptyState(
                      "Nhập để tìm bạn mới", Icons.person_search)
                  : _buildUserList(searchResults, "search"),
        ),
      ],
    );
  }

  Widget _buildRequestsTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: friendRequests.isEmpty
          ? _buildEmptyState("Không có lời mời nào", Icons.mail_outline)
          : _buildUserList(friendRequests, "requests"),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users, String type) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        String name = user['name'] ?? user['email'].split('@')[0];

        return ListTile(
          leading: _buildAvatar(user),
          title: Text(name,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(user['email'],
              style:
                  const TextStyle(color: Colors.white38, fontSize: 12)),
          trailing: _buildButton(user, type),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HoSoNguoiDungScreen(
                  user: user,
                  currentUserEmail: widget.currentUser['email'],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildButton(Map<String, dynamic> user, String type) {
    if (type == "search") {
      if (user['email'] == widget.currentUser['email'])
        return const SizedBox();

      String status = user['relationship_status'] ?? 'none';

      if (status == 'friends') {
        return const Text("Bạn bè",
            style: TextStyle(color: Colors.grey));
      } else if (status == 'pending') {
        return const Text("Đã gửi lời mời",
            style: TextStyle(color: Colors.grey));
      }

      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pinkAccent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => _sendRequest(user['email']),
        child:
            const Text("Kết bạn", style: TextStyle(color: Colors.white)),
      );
    }

    if (type == "friends") {
      return const Icon(Icons.check_circle, color: Colors.blueAccent);
    }

    if (type == "requests") {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => _acceptRequest(user['email']),
        child: const Text("Chấp nhận",
            style: TextStyle(color: Colors.white)),
      );
    }

    return const SizedBox();
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white10, size: 80),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }
}