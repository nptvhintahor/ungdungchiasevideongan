import 'package:flutter/material.dart';
import 'hoso.dart';
import 'caidatriengtu.dart';
import 'dangnhap.dart';

class TaiKhoanScreen extends StatefulWidget {
  const TaiKhoanScreen({super.key});

  @override
  State<TaiKhoanScreen> createState() => _TaiKhoanScreenState();
}

class _TaiKhoanScreenState extends State<TaiKhoanScreen> {
  int selectedIndex = 0;

  List<String> myVideos = [];
  List<String> likedVideos = [];

  // 🔐 trạng thái đăng nhập
  bool isLoggedIn = false;
  String email = "";
  String password = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tài khoản"),
        centerTitle: true,

        // 🔥 MENU 3 GẠCH
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "taikhoan") {
                // 🔥 mở màn đăng nhập
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DangNhapScreen(
                      onLogin: (e, p) {
                        setState(() {
                          isLoggedIn = true;
                          email = e;
                          password = p;
                        });
                      },
                      isLoggedIn: isLoggedIn,
                      email: email,
                      password: password,
                    ),
                  ),
                );
              } else if (value == "hoso") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HoSoScreen(),
                  ),
                );
              } else if (value == "caidat") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const CaiDatRiengTuScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: "taikhoan",
                child: Text("Tài khoản"),
              ),
              PopupMenuItem(
                value: "hoso",
                child: Text("Thông tin hồ sơ"),
              ),
              PopupMenuItem(
                value: "caidat",
                child: Text("Cài đặt & quyền riêng tư"),
              ),
              PopupMenuItem(
                value: "qr",
                child: Text("Mã QR của bạn"),
              ),
            ],
            icon: const Icon(Icons.menu),
          ),
        ],
      ),

      body: Column(
        children: [
          const SizedBox(height: 20),

          // 👤 Avatar
          const CircleAvatar(
            radius: 50,
            backgroundImage:
                NetworkImage("https://i.pravatar.cc/150"),
          ),

          const SizedBox(height: 10),

          // 🧑 Username
          Text(
            isLoggedIn ? email : "@user123",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          // 📊 Thống kê
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              ProfileItem(title: "Bạn bè", value: "0"),
              ProfileItem(title: "Lượt thích", value: "0"),
              ProfileItem(title: "Follower", value: "0"),
            ],
          ),

          const SizedBox(height: 20),

          // 🔥 TAB
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              tabItem(Icons.grid_on, 0),
              tabItem(Icons.favorite, 1),
            ],
          ),

          const Divider(),

          Expanded(
            child: selectedIndex == 0
                ? buildVideoGrid(myVideos)
                : buildVideoGrid(likedVideos),
          ),
        ],
      ),
    );
  }

  // 🔹 TAB
  Widget tabItem(IconData icon, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Icon(
        icon,
        size: 30,
        color:
            selectedIndex == index ? Colors.black : Colors.grey,
      ),
    );
  }

  // 🔹 GRID VIDEO
  Widget buildVideoGrid(List<String> videos) {
    if (videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Bạn chưa chia sẻ video nào"),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  myVideos.add("video1");
                });
              },
              child: const Text("Chia sẻ"),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      itemCount: videos.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.all(2),
          color: Colors.grey,
          child: const Icon(Icons.play_arrow),
        );
      },
    );
  }
}

// 📊 Widget thống kê
class ProfileItem extends StatelessWidget {
  final String title;
  final String value;

  const ProfileItem({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(title),
      ],
    );
  }
}
