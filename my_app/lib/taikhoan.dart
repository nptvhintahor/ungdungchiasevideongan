import 'package:flutter/material.dart';
import 'api_service.dart';
import 'video_player_widget.dart';
import 'video_detail_screen.dart';
import 'upload_video_screen.dart';
import 'caidatriengtu.dart';
import 'ketban.dart';
import 'hoso.dart';
import 'theme_notifier.dart';
import 'chat_list_screen.dart';

class TaiKhoanScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const TaiKhoanScreen({super.key, required this.currentUser});

  @override
  State<TaiKhoanScreen> createState() => _TaiKhoanScreenState();
}

class _TaiKhoanScreenState extends State<TaiKhoanScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> myVideos = [];
  List<Map<String, dynamic>> likedVideos = [];
  List<Map<String, dynamic>> sharedVideos = [];

  bool isLoading = true;
  int friendCount = 0;
  int requestCount = 0;

  late String displayName;
  String bio = "Chưa có tiểu sử";
  String birthDate = "01/01/2000";
  String? avatarUrl;

  int selectedTab = 0;

  static const _pink   = Color(0xFFFF2D55);
  static const _purple = Color(0xFFBF5AF2);
  static const _orange = Color(0xFFFF9500);

  // ─── Theme helpers (đồng bộ với CaiDatRiengTuScreen) ─────────
  Color _bg(bool isDark)            => isDark ? const Color(0xFF121212) : const Color(0xFFF7F7F7);
  Color _cardBg(bool isDark)        => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color _titleColor(bool isDark)    => isDark ? Colors.white            : Colors.black87;
  Color _subColor(bool isDark)      => isDark ? Colors.white60          : Colors.black45;
  Color _divider(bool isDark)       => isDark ? Colors.white12          : Colors.black12;
  Color _iconBg(bool isDark)        => isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
  Color _iconColor(bool isDark)     => isDark ? Colors.white70          : Colors.black54;
  Color _border(bool isDark)        => isDark ? Colors.white12          : Colors.black12;
  Color _emptyBg(bool isDark)       => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color _emptyIcon(bool isDark)     => isDark ? Colors.white24          : Colors.grey.shade300;
  Color _emptyTitle(bool isDark)    => isDark ? Colors.white70          : Colors.black87;
  Color _emptySubtitle(bool isDark) => isDark ? Colors.white38          : Colors.black45;
  Color _tabInactive(bool isDark)   => isDark ? Colors.white24          : Colors.black38;
  Color _videoBg(bool isDark)       => isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200;
  Color _italicText(bool isDark)    => isDark ? Colors.white24          : Colors.black38;

  @override
  void initState() {
    super.initState();
    displayName = widget.currentUser['email'].split('@')[0];
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() {
      isLoading    = true;
      myVideos     = [];
      likedVideos  = [];
      sharedVideos = [];
    });
    try {
      final email   = widget.currentUser['email'];
      final results = await Future.wait([
        ApiService.getUserInfo(email),
        ApiService.getVideosByEmail(email),
        ApiService.getLikedVideos(email),
        ApiService.getSharedVideos(email),
        ApiService.getTotalFriends(email),
        ApiService.getFriendRequests(email),
      ]);

      if (!mounted) return;
      setState(() {
        final userData = results[0] as Map<String, dynamic>?;
        displayName  = userData?['name']      ?? email.split('@')[0];
        bio          = userData?['bio']        ?? "Chưa có tiểu sử";
        birthDate    = userData?['dob']        ?? "01/01/2000";
        avatarUrl    = userData?['avatarUrl'];
        myVideos     = List<Map<String, dynamic>>.from(results[1] as List);
        likedVideos  = List<Map<String, dynamic>>.from(results[2] as List);
        sharedVideos = List<Map<String, dynamic>>.from(results[3] as List);
        friendCount  = results[4] as int;
        requestCount = results[5] as int;
        isLoading    = false;
      });
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HoSoScreen(currentUser: widget.currentUser),
      ),
    ).then((result) {
      if (result is Map && result['updated'] == true) {
        final newUrl = result['avatarUrl'] as String?;
        if (avatarUrl != null && avatarUrl!.isNotEmpty) {
          NetworkImage(avatarUrl!).evict();
        }
        setState(() => avatarUrl = newUrl);
      }
      _loadUserData();
    });
  }

  void _goToChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatListScreen(currentUser: widget.currentUser),
      ),
    );
  }

  String _bustCache(String url) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return url.contains('?') ? '$url&t=$ts' : '$url?t=$ts';
  }

  String _formatCount(int count) =>
      count >= 1000000
          ? "${(count / 1000000).toStringAsFixed(1)}M"
          : count >= 1000
              ? "${(count / 1000).toStringAsFixed(1)}K"
              : "$count";

  void _openVideoDetail(Map<String, dynamic> video) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoDetailScreen(
          videoPath: video['path'],
          videoId: video['id'],
          currentUserEmail: widget.currentUser['email'],
        ),
      ),
    );
    if (res == true) _loadUserData();
  }

  void _goToUpload() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadVideoScreen(userEmail: widget.currentUser['email']),
      ),
    );
    if (res == true) _loadUserData();
  }

  // ─── Avatar ──────────────────────────────────────────────────
  Widget _buildAvatar({double radius = 50, required bool isDark}) {
    final bool hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [_pink, _purple, _orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _bg(isDark),
        ),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F3F3),
          key: ValueKey(avatarUrl),
          backgroundImage: hasAvatar ? NetworkImage(_bustCache(avatarUrl!)) : null,
          child: !hasAvatar
              ? Icon(Icons.person_rounded,
                  size: radius * 1.1,
                  color: isDark ? Colors.white38 : Colors.grey[400])
              : null,
        ),
      ),
    );
  }

  // ─── Stat item ───────────────────────────────────────────────
  Widget _buildStatItem(String label, int count,
      {bool highlight = false, required bool isDark}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatCount(count),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: highlight ? _pink : _titleColor(isDark),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: _subColor(isDark),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 28,
      width: 1,
      color: _divider(isDark),
    );
  }

  // ─── Tab button ──────────────────────────────────────────────
  Widget _tabButton(int index, IconData icon, bool isDark) {
    final bool isSelected = selectedTab == index;
    return InkWell(
      onTap: () => setState(() => selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: MediaQuery.of(context).size.width / 3,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? _pink : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? _pink : _tabInactive(isDark),
          size: 24,
        ),
      ),
    );
  }

  // ─── Empty state ─────────────────────────────────────────────
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _emptyBg(isDark),
              shape: BoxShape.circle,
              border: Border.all(color: _border(isDark)),
            ),
            child: Icon(Icons.video_collection_outlined,
                size: 52, color: _emptyIcon(isDark)),
          ),
          const SizedBox(height: 18),
          Text(
            "Chưa có nội dung",
            style: TextStyle(
              color: _emptyTitle(isDark),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Đăng video đầu tiên của bạn!",
            style: TextStyle(color: _emptySubtitle(isDark), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─── Video tile ──────────────────────────────────────────────
  Widget _buildVideoTile(Map<String, dynamic> video, bool isDark) {
    return GestureDetector(
      onTap: () => _openVideoDetail(video),
      child: ClipRect(
        child: ColoredBox(
          color: _videoBg(isDark),
          child: Stack(
            fit: StackFit.expand,
            children: [
              OverflowBox(
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: 100,
                    height: 133,
                    child: VideoPlayerWidget(
                      key: ValueKey("${video['id']}_$selectedTab"),
                      videoPath: video['path'],
                      isActive: false,
                      videoId: video['id'],
                      currentUserEmail: widget.currentUser['email'],
                    ),
                  ),
                ),
              ),
              // Gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 36,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black54],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // Like count
              Positioned(
                bottom: 5,
                left: 6,
                child: Row(
                  children: [
                    const Icon(Icons.favorite_rounded,
                        color: Colors.white, size: 15),
                    const SizedBox(width: 2),
                    Text(
                      _formatCount(video['likes'] ?? 0),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeNotifier.themeMode,
      builder: (context, currentMode, _) {
        final isDark = currentMode == ThemeMode.dark;
        final displayVideos = selectedTab == 0
            ? myVideos
            : (selectedTab == 1 ? likedVideos : sharedVideos);

        return Scaffold(
          backgroundColor: _bg(isDark),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: _bg(isDark),
            surfaceTintColor: _bg(isDark),
            centerTitle: true,
            title: Text(
              displayName,
              style: TextStyle(
                color: _titleColor(isDark),
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _iconBg(isDark),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.menu_rounded,
                        color: _iconColor(isDark), size: 20),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CaiDatRiengTuScreen(
                            currentUser: widget.currentUser),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            color: _pink,
            onRefresh: _loadUserData,
            child: isLoading && myVideos.isEmpty
                ? const Center(child: CircularProgressIndicator(color: _pink))
                : CustomScrollView(
                    slivers: [
                      // ── Profile section ──
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildAvatar(radius: 50, isDark: isDark),
                            const SizedBox(height: 14),
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _titleColor(isDark),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "@${widget.currentUser['email'].split('@')[0]}",
                              style: TextStyle(
                                fontSize: 13,
                                color: _subColor(isDark),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Stats card
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 40),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 8),
                              decoration: BoxDecoration(
                                color: _cardBg(isDark),
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: _border(isDark), width: 1),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildStatItem("Video", myVideos.length,
                                      isDark: isDark),
                                  _buildVerticalDivider(isDark),
                                  _buildStatItem("Bạn bè", friendCount,
                                      isDark: isDark),
                                  _buildVerticalDivider(isDark),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => KetBanScreen(
                                              currentUser: widget.currentUser),
                                        ),
                                      ).then((_) => _loadUserData());
                                    },
                                    child: _buildStatItem(
                                      "Yêu cầu",
                                      requestCount,
                                      highlight: requestCount > 0,
                                      isDark: isDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Bio
                            if (bio.isNotEmpty && bio != "Chưa có tiểu sử")
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  bio,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _subColor(isDark),
                                    fontSize: 13.5,
                                    height: 1.5,
                                  ),
                                ),
                              )
                            else
                              Text(
                                "Chưa có tiểu sử",
                                style: TextStyle(
                                  color: _italicText(isDark),
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),

                            const SizedBox(height: 18),

                            // Buttons
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                children: [
                                  // ── Nút Sửa hồ sơ ──
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _showEditProfile,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 11),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [_pink, _purple],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _pink.withOpacity(0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.edit_outlined,
                                                color: Colors.white, size: 15),
                                            SizedBox(width: 6),
                                            Text(
                                              "Sửa hồ sơ",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  // ── Nút Chat → ChatListScreen ──
                                  GestureDetector(
                                    onTap: _goToChat,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _iconBg(isDark),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: _border(isDark)),
                                      ),
                                      child: Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          color: _iconColor(isDark),
                                          size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),

                      // ── Tab bar ──
                      SliverAppBar(
                        pinned: true,
                        elevation: 0,
                        backgroundColor: _bg(isDark),
                        surfaceTintColor: _bg(isDark),
                        toolbarHeight: 48,
                        flexibleSpace: Container(
                          decoration: BoxDecoration(
                            color: _bg(isDark),
                            border: Border(
                              bottom: BorderSide(
                                  color: _divider(isDark), width: 1),
                            ),
                          ),
                          child: Row(
                            children: [
                              _tabButton(0, Icons.grid_on_rounded, isDark),
                              _tabButton(
                                  1, Icons.favorite_border_rounded, isDark),
                              _tabButton(2, Icons.share_outlined, isDark),
                            ],
                          ),
                        ),
                      ),

                      // ── Video grid ──
                      displayVideos.isEmpty
                          ? SliverFillRemaining(
                              child: _buildEmptyState(isDark))
                          : SliverPadding(
                              padding: const EdgeInsets.all(1),
                              sliver: SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 1.5,
                                  mainAxisSpacing: 1.5,
                                  childAspectRatio: 0.75,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => _buildVideoTile(
                                      displayVideos[index], isDark),
                                  childCount: displayVideos.length,
                                ),
                              ),
                            ),
                    ],
                  ),
          ),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [_pink, _purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _pink.withOpacity(0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: _goToUpload,
              backgroundColor: Colors.transparent,
              elevation: 0,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                "Đăng video",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}