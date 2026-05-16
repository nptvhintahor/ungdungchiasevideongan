import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'api_service.dart';
import 'video_detail_screen.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoPath;
  final bool isActive;
  final int? videoId;
  final String? currentUserEmail;

  const VideoPlayerWidget({
    super.key,
    required this.videoPath,
    this.isActive = true,
    this.videoId,
    this.currentUserEmail,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  int _retryCount = 0;
  static const _maxRetry = 4;
  static const _retryDelay = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  // ================= VIDEO CONTROL =================
  Future<void> _initVideo() async {
    if (!mounted) return;

    // Reset state khi bắt đầu load
    setState(() {
      _hasError = false;
      _isInitialized = false;
    });

    await _controller?.dispose();
    _controller = null;

    try {
      // Nếu videoPath đã là URL đầy đủ (bắt đầu bằng http) thì dùng thẳng,
      // không thì mới gọi getVideoUrl() để tránh double-encode
      final String finalUrl = widget.videoPath.startsWith('http')
          ? widget.videoPath
          : ApiService.getVideoUrl(widget.videoPath);

      final ctrl = VideoPlayerController.networkUrl(Uri.parse(finalUrl));

      // Timeout 15 giây — tránh spinner mãi mãi khi server encode chưa xong
      await ctrl.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          ctrl.dispose();
          throw Exception("Timeout: server chưa sẵn sàng hoặc URL không hợp lệ");
        },
      );

      if (!mounted) {
        ctrl.dispose();
        return;
      }

      _controller = ctrl;
      _controller!.setLooping(true);
      if (widget.isActive) _controller!.play();

      setState(() {
        _isInitialized = true;
        _retryCount = 0; // reset counter khi thành công
      });
    } catch (e) {
      debugPrint("❌ VIDEO INIT ERROR (retry $_retryCount/$_maxRetry): $e");

      _controller?.dispose();
      _controller = null;

      if (!mounted) return;

      // Auto retry — server có thể đang encode video vừa upload
      if (_retryCount < _maxRetry) {
        _retryCount++;
        debugPrint("🔄 Thử lại sau ${_retryDelay.inSeconds}s... ($_retryCount/$_maxRetry)");
        await Future.delayed(_retryDelay);
        if (mounted) _initVideo();
      } else {
        // Hết retry → hiện nút thử lại thủ công
        setState(() => _hasError = true);
      }
    }
  }

  // ================= LIFECYCLE =================
  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.videoPath != widget.videoPath) {
      _retryCount = 0;
      _initVideo();
    } else {
      if (_controller != null && _isInitialized) {
        widget.isActive ? _controller!.play() : _controller!.pause();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Trạng thái lỗi sau khi hết retry
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white38, size: 42),
            const SizedBox(height: 10),
            const Text(
              "Video chưa sẵn sàng",
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 4),
            const Text(
              "Server có thể đang xử lý",
              style: TextStyle(color: Colors.white24, fontSize: 11),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                _retryCount = 0;
                _initVideo();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.white54, size: 16),
                    SizedBox(width: 6),
                    Text("Thử lại",
                        style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Đang load / retry
    if (!_isInitialized || _controller == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white24),
            if (_retryCount > 0) ...[
              const SizedBox(height: 12),
              Text(
                "Đang thử lại... ($_retryCount/$_maxRetry)",
                style: const TextStyle(color: Colors.white24, fontSize: 11),
              ),
            ],
          ],
        ),
      );
    }

    // Video đã sẵn sàng
    return Stack(
      alignment: Alignment.center,
      children: [
        // Video player
        GestureDetector(
          onTap: () async {
            if (widget.videoId != null) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoDetailScreen(
                    videoPath: widget.videoPath,
                    videoId: widget.videoId!,
                    currentUserEmail: widget.currentUserEmail ?? "",
                  ),
                ),
              );
            } else {
              setState(() {
                _controller!.value.isPlaying
                    ? _controller!.pause()
                    : _controller!.play();
              });
            }
          },
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),
        ),

        // Icon pause khi video dừng
        if (!_controller!.value.isPlaying && _isInitialized)
          const IgnorePointer(
            child: Icon(Icons.play_arrow, size: 80, color: Colors.white30),
          ),
      ],
    );
  }
}