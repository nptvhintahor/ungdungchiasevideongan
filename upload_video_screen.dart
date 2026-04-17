import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'database_helper.dart';

class UploadVideoScreen extends StatefulWidget {
  final String userEmail;
  const UploadVideoScreen({super.key, required this.userEmail});

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  File? videoFile;
  bool isUploading = false;

  Future<void> pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked != null) setState(() => videoFile = File(picked.path));
  }

  Future<void> uploadVideo() async {
    if (videoFile == null) return;
    setState(() => isUploading = true);

    final dir = await getApplicationDocumentsDirectory();
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final newPath = '${dir.path}/$fileName.mp4';
    final newVideo = await videoFile!.copy(newPath);

    await DatabaseHelper.instance.insertVideo(newVideo.path, widget.userEmail);
    Navigator.pop(context, newVideo.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Video")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(onPressed: pickVideo, child: const Text("Chọn video")),
            if (videoFile != null) Text("Đã chọn: ${videoFile!.path}"),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: isUploading ? null : uploadVideo, child: const Text("Đăng tải")),
          ],
        ),
      ),
    );
  }
}
