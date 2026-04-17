import 'package:flutter/material.dart';
import 'video_player_widget.dart';
import 'database_helper.dart';
import 'upload_video_screen.dart';
import 'taikhoan.dart';

class TikTokScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  const TikTokScreen({super.key, required this.currentUser});

  @override
  State<TikTokScreen> createState() => _TikTokScreenState();
}

class _TikTokScreenState extends State<TikTokScreen> {
  List<Map<String, dynamic>> videos = [];
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isLoading = true;
  int _refreshKey = 0; // Thêm key để làm mới danh sách khi cần

  @override
  void initState() {
    super.initState();
    loadVideos();
  }

  Future<void> loadVideos() async {
    // Đợi một chút để Database kịp cập nhật nếu vừa quay về từ màn hình khác
    await Future.delayed(const Duration(milliseconds: 200));
    
    final data = await DatabaseHelper.instance.getAllVideos();
    if (!mounted) return;
    setState(() {
      videos = data;
      _isLoading = false;
      _refreshKey++; // Tăng key để build lại PageView với dữ liệu mới
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : videos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Chưa có video nào", style: TextStyle(color: Colors.white)),
                      const SizedBox(height: 20),
                      ElevatedButton(onPressed: loadVideos, child: const Text("Tải lại")),
                    ],
                  ),
                )
              : PageView.builder(
                  key: ValueKey(_refreshKey), // Ép PageView vẽ lại khi dữ liệu thay đổi
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: videos.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    bool active = index == _currentIndex;

                    // Chỉ khởi tạo video hiện tại và lân cận để tối ưu RAM
                    if ((index - _currentIndex).abs() > 1) {
                      return const SizedBox.shrink();
                    }

                    return VideoPlayerWidget(
                      // Key quan trọng để Flutter nhận diện sự thay đổi của item
                      key: ValueKey("${video['id']}_${video['likes']}_$_refreshKey"), 
                      videoPath: video['path'],
                      isActive: active,
                      videoId: video['id'], // Truyền ID để hiện Like/Comment
                      currentUserEmail: widget.currentUser['email'], // Truyền Email để check đã like chưa
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white.withOpacity(0.5),
        onPressed: () async {
          await Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => UploadVideoScreen(userEmail: widget.currentUser['email']))
          );
          loadVideos(); // Tải lại sau khi upload thành công
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: Colors.black,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey,
      currentIndex: 0,
      onTap: (index) async {
        if (index == 1) {
          // Khi chuyển sang màn hình Tôi và quay lại
          await Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => TaiKhoanScreen(currentUser: widget.currentUser))
          );
          // Load lại để đồng bộ số Like nếu user đã thao tác bên màn hình Tài khoản
          loadVideos(); 
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Trang chủ"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Tôi"),
      ],
    );
  }
}
