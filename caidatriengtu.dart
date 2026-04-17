import 'package:flutter/material.dart';
import 'theme_notifier.dart'; // Import file vừa tạo

class CaiDatRiengTuScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  const CaiDatRiengTuScreen({super.key, required this.currentUser});

  @override
  State<CaiDatRiengTuScreen> createState() => _CaiDatRiengTuScreenState();
}

class _CaiDatRiengTuScreenState extends State<CaiDatRiengTuScreen> {
  bool isNotificationOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cài đặt & quyền riêng tư"), centerTitle: true),
      body: ListView(
        children: [
          // Sử dụng ValueListenableBuilder để đồng bộ trạng thái switch với Theme của app
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeNotifier.themeMode,
            builder: (context, currentMode, child) {
              return SwitchListTile(
                secondary: Icon(currentMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode),
                title: const Text("Hiển thị (Dark Mode)"),
                value: currentMode == ThemeMode.dark,
                onChanged: (value) {
                  ThemeNotifier.toggleTheme(value);
                },
              );
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text("Thông báo"),
            value: isNotificationOn,
            onChanged: (value) => setState(() => isNotificationOn = value),
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text("Bảo mật"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cài đặt bảo mật"))),
          ),
        ],
      ),
    );
  }
}
