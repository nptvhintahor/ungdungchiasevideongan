import 'package:flutter/material.dart';
import 'video_player_widget.dart';
import 'api_service.dart';
import 'upload_video_screen.dart';
import 'taikhoan.dart';

class TikTokScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const TikTokScreen({super.key, required this.currentUser});

  @override
  State<TikTokScreen> createState() => _TikTokScreenState();
}

class _TikTokScreenState extends State<TikTokScreen> {
  List<Map<String, dynamic>> myVideos = [];
  List<Map<String, dynamic>> sharedVideos = [];
  final PageController _pageController = PageController();

  int _currentIndex = 0;
  bool _isLoading = true;
  int _refreshKey = 0;

  // 0 = Video của bạn, 1 = Video chia sẻ
  int _selectedTab = 0;

  List<Map<String, dynamic>> get _currentVideos =>
      _selectedTab == 0 ? myVideos : sharedVideos;

  @override
  void initState() {
    super.initState();
    loadVideos();
  }

  // ================= LOAD VIDEO =================
  Future<void> loadVideos() async {
    try {
      if (mounted) setState(() => _isLoading = true);

      final email = widget.currentUser['email'];

      // Load cả 2 danh sách cùng lúc
      final results = await Future.wait([
        ApiService.getVideosByEmail(email),
        ApiService.getSharedVideos(email),
      ]);

      if (!mounted) return;

      setState(() {
        myVideos = results[0];
        sharedVideos = results[1];
        _isLoading = false;
        _currentIndex = 0;
        _refreshKey++;
      });

      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    } catch (e) {
      debugPrint("❌ LOAD VIDEO ERROR: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Khi đổi tab reset page về 0
  void _switchTab(int tab) {
    if (_selectedTab == tab) return;
    setState(() {
      _selectedTab = tab;
      _currentIndex = 0;
      _refreshKey++;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        children: [
          // ── Video Feed ──
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : RefreshIndicator(
                  onRefresh: loadVideos,
                  color: Colors.white,
                  backgroundColor: Colors.black,
                  child: _currentVideos.isEmpty
                      ? _buildEmpty()
                      : PageView.builder(
                          key: ValueKey("pv_${_selectedTab}_$_refreshKey"),
                          controller: _pageController,
                          scrollDirection: Axis.vertical,
                          itemCount: _currentVideos.length,
                          onPageChanged: (index) {
                            setState(() => _currentIndex = index);
                          },
                          itemBuilder: (context, index) {
                            final video = _currentVideos[index];
                            bool isActive = index == _currentIndex;

                            if ((index - _currentIndex).abs() > 1) {
                              return const SizedBox.shrink();
                            }

                            return VideoPlayerWidget(
                              key: ValueKey(
                                  "vid_${video['id']}_${_selectedTab}_$_refreshKey"),
                              videoPath: video['path'],
                              isActive: isActive,
                              videoId: video['id'],
                              currentUserEmail: widget.currentUser['email'],
                            );
                          },
                        ),
                ),

          // ── Tab Buttons phía trên ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: _buildTabBar(),
          ),
        ],
      ),

      // ================= NÚT THÊM VIDEO =================
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15)),
        child: const Icon(Icons.add, color: Colors.black, size: 30),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UploadVideoScreen(
                  userEmail: widget.currentUser['email']),
            ),
          );
          if (result == true) loadVideos();
        },
      ),

      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ================= TAB BAR =================
  Widget _buildTabBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTabButton(
          label: "Video của bạn",
          index: 0,
          icon: Icons.play_circle_outline_rounded,
        ),
        const SizedBox(width: 10),
        _buildTabButton(
          label: "Video chia sẻ",
          index: 1,
          icon: Icons.share_rounded,
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required String label,
    required int index,
    required IconData icon,
  }) {
    final bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => _switchTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.9)
              : Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white30,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.black : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= EMPTY STATE =================
  Widget _buildEmpty() {
    final bool isMyTab = _selectedTab == 0;
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.28),
        Icon(
          isMyTab ? Icons.video_library_outlined : Icons.share_outlined,
          color: Colors.white24,
          size: 90,
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            isMyTab
                ? "Bạn chưa đăng tải video nào"
                : "Bạn chưa được chia sẻ video nào",
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            isMyTab
                ? "Nhấn nút + để đăng video đầu tiên!"
                : "Khi bạn bè chia sẻ video, nó sẽ hiện ở đây",
            style: const TextStyle(color: Colors.white38, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
        if (isMyTab) ...[
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UploadVideoScreen(
                        userEmail: widget.currentUser['email']),
                  ),
                );
                if (result == true) loadVideos();
              },
              icon: const Icon(Icons.upload_rounded),
              label: const Text("Đăng video ngay"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ================= THANH ĐIỀU HƯỚNG =================
  Widget _buildBottomNav() {
    return BottomAppBar(
      color: Colors.black.withOpacity(0.8),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.white, size: 30),
              onPressed: () {
                if (_currentIndex != 0 && _pageController.hasClients) {
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              },
            ),
            const SizedBox(width: 40),
            IconButton(
              icon: const Icon(Icons.person, color: Colors.grey, size: 30),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TaiKhoanScreen(currentUser: widget.currentUser),
                  ),
                );
                if (result == true) loadVideos();
              },
            ),
          ],
        ),
      ),
    );
  }
}