import 'package:flutter/material.dart';
import 'dangnhap.dart';
import 'api_service.dart';
import 'theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Test API thay vì SQLite
  await debugAPI();

  runApp(const MyApp());
}

// ✅ DEBUG API (THAY SQLITE)
Future<void> debugAPI() async {
  print("==== API DEBUG ====");

  try {
    final videos = await ApiService.getAllVideos();
    print("🎬 VIDEOS FROM SERVER: $videos");
  } catch (e) {
    print("❌ API ERROR: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeNotifier.themeMode,
      builder: (context, currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

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

          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),

          themeMode: currentMode,

          home: const DangNhapScreen(),
        );
      },
    );
  }
}