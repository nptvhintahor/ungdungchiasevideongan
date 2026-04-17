import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'video_player_widget.dart';
import 'video_detail_screen.dart';
import 'caidatriengtu.dart';
import 'upload_video_screen.dart';
import 'dangnhap.dart';
import 'ketban.dart';
import 'chiase.dart';

class TaiKhoanScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const TaiKhoanScreen({super.key, required this.currentUser});

  @override
  State<TaiKhoanScreen> createState() => _TaiKhoanScreenState();
}

class _TaiKhoanScreenState extends State<TaiKhoanScreen> {
  List<Map<String, dynamic>> myVideos = [];
  List<Map<String, dynamic>> likedVideos = [];
  List<Map<String, dynamic>> sharedVideos = [];

  bool isLoading = true;
  bool isFirstLoad = true;
  int totalLikes = 0;
  int selectedTab = 0;

  int friendCount = 0;
  int requestCount = 0;

  late String displayName;
  String bio = "Chưa có tiểu sử";
  String birthDate = "01/01/2000";

  @override
  void initState() {
    super.initState();
    displayName = widget.currentUser['email'].split('@')[0];
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    if (isFirstLoad) setState(() => isLoading = true);

    final email = widget.currentUser['email'];
    final userData = await DatabaseHelper.instance.getUserInfo(email);
    final allVids = await DatabaseHelper.instance.getAllVideos();
    final myVids = allVids.where((v) => v['user_email'] == email).toList();
    final likedVids = await DatabaseHelper.instance.getLikedVideos(email);
    final likes = await DatabaseHelper.instance.getTotalLikes(email);
    final sharedVids = await DatabaseHelper.instance.getSharedVideos(email); 
    final friends = await DatabaseHelper.instance.getTotalFriends(email);
    final requests = await DatabaseHelper.instance.getFriendRequests(email);

    if (!mounted) return;

    setState(() {
      if (userData != null) {
        displayName = userData['name'] ?? email.split('@')[0];
        bio = userData['bio'] ?? "Chưa có tiểu sử";
        birthDate = userData['dob'] ?? "01/01/2000";
      }
      myVideos = myVids;
      likedVideos = likedVids;
      sharedVideos = sharedVids;
      totalLikes = likes;
      friendCount = friends;
      requestCount = requests;
      isLoading = false;
      isFirstLoad = false;
    });
  }

  // --- UI EDIT PROFILE ---
  void _showEditProfile() {
    final nameController = TextEditingController(text: displayName);
    final bioController = TextEditingController(text: bio);
    final dobController = TextEditingController(text: birthDate);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text("Sửa hồ sơ", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage("https://i.pravatar.cc/150?u=${widget.currentUser['email']}"),
            ),
            const SizedBox(height: 20),
            _buildInputField("Tên người dùng", nameController),
            _buildInputField("Ngày sinh", dobController, isReadOnly: true),
            _buildInputField("Tiểu sử", bioController, maxLines: 3),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await DatabaseHelper.instance.updateUserProfile(
                    widget.currentUser['email'], nameController.text, dobController.text, bioController.text,
                  );
                  setState(() {
                    displayName = nameController.text;
                    bio = bioController.text;
                    birthDate = dobController.text;
                  });
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("Lưu", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {int maxLines = 1, bool isReadOnly = false}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        readOnly: isReadOnly,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDarkMode ? Colors.white12 : Colors.black12)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ BƯỚC 1: LẤY MÀU ĐỘNG TỪ HỆ THỐNG
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final isDarkMode = theme.brightness == Brightness.dark;

    List<Map<String, dynamic>> displayVideos;
    if (selectedTab == 0) {
      displayVideos = myVideos;
    } else if (selectedTab == 1) {
      displayVideos = likedVideos;
    } else {
      displayVideos = sharedVideos;
    }

    return Scaffold(
      // backgroundColor: Colors.black, // ✅ BƯỚC 2: Xóa màu nền cố định
      appBar: AppBar(
        // backgroundColor: Colors.black, // ✅ Bọc AppBar theo theme hệ thống
        elevation: 0,
        title: Text(displayName, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.menu, color: textColor), onPressed: () => _showSettingsMenu(context))
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 15),
          CircleAvatar(
            radius: 45,
            backgroundImage: NetworkImage("https://i.pravatar.cc/150?u=${widget.currentUser['email']}"),
          ),
          const SizedBox(height: 10),
          // ✅ BƯỚC 3: Thay Colors.white bằng textColor
          Text("@${widget.currentUser['email'].split('@')[0]}",
              style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Text(bio, style: const TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatItem("Bạn bè", friendCount.toString(), textColor!),
              const SizedBox(width: 30),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => KetBanScreen(currentUser: widget.currentUser)));
                  _loadUserData(); 
                },
                child: _buildStatItem("Kết bạn", requestCount.toString(), textColor),
              ),
              const SizedBox(width: 30),
              _buildStatItem("Lượt thích", totalLikes.toString(), textColor),
            ],
          ),

          const SizedBox(height: 15),

          GestureDetector(
            onTap: _showEditProfile,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[200], // ✅ Màu nút động
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: isDarkMode ? Colors.white12 : Colors.black12),
              ),
              child: Text("Sửa hồ sơ", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              _buildTabButton(0, Icons.grid_on_sharp, isDarkMode),
              _buildTabButton(1, Icons.favorite, isDarkMode),
              _buildTabButton(2, Icons.share, isDarkMode), 
            ],
          ),

          const Divider(color: Colors.white12, height: 1),

          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: isDarkMode ? Colors.white : Colors.blue))
                : displayVideos.isEmpty
                    ? Center(child: Text(
                        selectedTab == 0 ? "Chưa có video nào" : (selectedTab == 1 ? "Chưa thích video nào" : "Chưa có video chia sẻ"), 
                        style: const TextStyle(color: Colors.grey)))
                    : GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, crossAxisSpacing: 1, mainAxisSpacing: 1, childAspectRatio: 0.7,
                        ),
                        itemCount: displayVideos.length,
                        itemBuilder: (context, index) {
                          final video = displayVideos[index];
                          return GestureDetector(
                            onTap: () async {
                              if (selectedTab == 2) {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => ChiaSeScreen(currentUser: widget.currentUser)));
                              } else {
                                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => VideoDetailScreen(
                                      videoPath: video['path'],
                                      videoId: video['id'],
                                      currentUserEmail: widget.currentUser['email'],
                                )));
                                if (result == true) _loadUserData();
                              }
                            },
                            child: Container(
                              color: isDarkMode ? Colors.grey[900] : Colors.grey[300],
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  VideoPlayerWidget(
                                    key: ValueKey(video['id']),
                                    videoPath: video['path'],
                                    isActive: false,
                                    videoId: video['id'],
                                    currentUserEmail: widget.currentUser['email'],
                                  ),
                                  const Positioned(bottom: 5, left: 5, child: Icon(Icons.play_arrow, color: Colors.white, size: 16)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: isDarkMode ? Colors.white : Colors.black,
        foregroundColor: isDarkMode ? Colors.black : Colors.white,
        child: const Icon(Icons.add, size: 30),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => UploadVideoScreen(userEmail: widget.currentUser['email'])));
          _loadUserData();
        },
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, bool isDarkMode) {
    bool isSelected = selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isSelected ? (isDarkMode ? Colors.white : Colors.black) : Colors.transparent, width: 2))),
          child: Icon(icon, color: isSelected ? (isDarkMode ? Colors.white : Colors.black) : Colors.grey),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  void _showSettingsMenu(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          ListTile(
            leading: Icon(Icons.account_circle, color: isDarkMode ? Colors.white : Colors.black),
            title: Text("Tài khoản", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            onTap: () { Navigator.pop(context); _showAccountDetailDialog(context); },
          ),
          ListTile(
            leading: Icon(Icons.security, color: isDarkMode ? Colors.white : Colors.black),
            title: Text("Quyền riêng tư", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => CaiDatRiengTuScreen(currentUser: widget.currentUser))); },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showAccountDetailDialog(BuildContext context) {
    bool isObscure = true;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          title: Text("Thông tin tài khoản", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.currentUser['email'], style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: Text(isObscure ? "••••••••" : widget.currentUser['password'], style: TextStyle(color: isDarkMode ? Colors.white : Colors.black))),
                  IconButton(
                      icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility, color: isDarkMode ? Colors.white : Colors.black),
                      onPressed: () => setStateDialog(() => isObscure = !isObscure))
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () => _logout(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("Đăng xuất", style: TextStyle(color: Colors.white)))
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DangNhapScreen()), (route) => false);
  }
}
