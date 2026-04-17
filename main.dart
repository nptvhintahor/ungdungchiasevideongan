import 'package:flutter/material.dart';
import 'dangnhap.dart';
import 'database_helper.dart';
import 'theme_notifier.dart'; // ✅ Đảm bảo bạn đã tạo file này

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await debugDB(); // 👈 chạy debug DB

  runApp(const MyApp());
}

Future<void> debugDB() async {
  final db = await DatabaseHelper.instance.database;

  print("==== DATABASE DEBUG ====");
  print("Path: ${db.path}");

  // In danh sách bảng
  final tables = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table'"
  );
  print("📦 Tables: $tables");

  // In dữ liệu USERS
  final users = await db.query('users');
  print("🔥 USERS: $users");

  // In dữ liệu VIDEOS
  final videos = await db.query('videos');
  print("🎬 VIDEOS: $videos");

  // In dữ liệu COMMENTS
  final comments = await db.query('comments');
  print("💬 COMMENTS: $comments");

  // In dữ liệu LIKES
  final likes = await db.query('video_likes');
  print("❤️ LIKES: $likes");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Sử dụng ValueListenableBuilder để tự động vẽ lại toàn bộ App khi đổi theme
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeNotifier.themeMode,
      builder: (context, currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          
          // ☀️ Cấu hình Giao diện Sáng
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
          ),
          
          // 🌙 Cấu hình Giao diện Tối
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          
          // ✅ Chế độ hiện tại được lấy từ ThemeNotifier
          themeMode: currentMode,
          
          home: const DangNhapScreen(),
        );
      },
    );
  }
}
