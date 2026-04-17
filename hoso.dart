import 'package:flutter/material.dart';

class HoSoScreen extends StatelessWidget {
  final Map<String, dynamic> currentUser;
  const HoSoScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hồ sơ")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, backgroundImage: NetworkImage("https://i.pravatar.cc/150")),
            const SizedBox(height: 10),
            Text(currentUser['email'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              title: const Text("Thông tin cơ bản"),
              subtitle: const Text("Ví dụ: tên, giới tính,..."),
              leading: const Icon(Icons.info),
            ),
          ],
        ),
      ),
    );
  }
}
