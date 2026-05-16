import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_service.dart';

// ═══════════════════════════════════════════════════════════
//  CHAT LIST SCREEN — danh sách bạn bè để nhắn tin
// ═══════════════════════════════════════════════════════════
class ChatListScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const ChatListScreen({super.key, required this.currentUser});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _friends = [];
  bool _isLoading = true;

  static const _pink = Color(0xFFFF2D55);

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);
    try {
      final friends =
          await ApiService.getFriendsList(widget.currentUser['email']);
      if (mounted) setState(() => _friends = friends);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  String _bustCache(String url) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return url.contains('?') ? '$url&t=$ts' : '$url?t=$ts';
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bg       = isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5);
    final cardBg   = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final titleCol = isDark ? Colors.white                    : Colors.black87;
    final subCol   = isDark ? Colors.white54                  : Colors.black45;
    final divCol   = isDark ? Colors.white.withOpacity(0.08)  : Colors.black12;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: bg,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: Text(
          "Tin nhắn",
          style: TextStyle(
            color: titleCol,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF222222) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: divCol),
              ),
              child: Icon(Icons.edit_outlined,
                  color: isDark ? Colors.white70 : Colors.black54, size: 18),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _pink))
          : _friends.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1A1A1A)
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: divCol),
                        ),
                        child: Icon(Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: isDark
                                ? Colors.white24
                                : Colors.grey.shade300),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Chưa có cuộc trò chuyện",
                        style: TextStyle(
                          color: titleCol,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Kết bạn để bắt đầu nhắn tin",
                        style: TextStyle(color: subCol, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: _pink,
                  onRefresh: _loadFriends,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: _friends.length,
                    itemBuilder: (context, index) {
                      final friend    = _friends[index];
                      final email     = friend['email'] ?? '';
                      final name      = friend['name'] ?? email.split('@')[0];
                      final rawAvatar = friend['avatar_url'] as String?;
                      final avatarUrl = (rawAvatar != null &&
                              rawAvatar.isNotEmpty)
                          ? (rawAvatar.startsWith('http')
                              ? rawAvatar
                              : '${ApiService.baseUrl}$rawAvatar')
                          : null;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                currentUser: widget.currentUser,
                                friendEmail: email,
                                friendName: name,
                                friendAvatarUrl: avatarUrl,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: divCol),
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: isDark
                                        ? const Color(0xFF2A2A2A)
                                        : Colors.grey.shade100,
                                    backgroundImage: avatarUrl != null
                                        ? NetworkImage(_bustCache(avatarUrl))
                                        : null,
                                    child: avatarUrl == null
                                        ? Icon(Icons.person_rounded,
                                            size: 28,
                                            color: isDark
                                                ? Colors.white38
                                                : Colors.grey)
                                        : null,
                                  ),
                                  // Dot online
                                  Positioned(
                                    right: 1,
                                    bottom: 1,
                                    child: Container(
                                      width: 11,
                                      height: 11,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: cardBg,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              // Tên + email
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        color: titleCol,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      email,
                                      style:
                                          TextStyle(color: subCol, fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // Arrow
                              Icon(Icons.chevron_right_rounded,
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black26,
                                  size: 22),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  CHAT SCREEN — nhắn tin realtime với WebSocket
// ═══════════════════════════════════════════════════════════
class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  final String friendEmail;
  final String friendName;
  final String? friendAvatarUrl;

  const ChatScreen({
    super.key,
    required this.currentUser,
    required this.friendEmail,
    required this.friendName,
    this.friendAvatarUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController      _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  WebSocketChannel? _channel;
  bool _isConnected      = false;
  bool _isLoadingHistory = true;

  static const _pink   = Color(0xFFFF2D55);
  static const _purple = Color(0xFFBF5AF2);

  String get _myEmail => widget.currentUser['email'];
  String get _wsUrl =>
      'ws://${ApiService.baseUrl.replaceFirst('http://', '')}/ws/chat';

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _connectWebSocket();
  }

  // ── Load lịch sử tin nhắn ──────────────────────────────
  Future<void> _loadHistory() async {
    try {
      final msgs =
          await ApiService.getMessages(_myEmail, widget.friendEmail);
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(msgs);
          _isLoadingHistory = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  // ── Kết nối WebSocket ──────────────────────────────────
  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      setState(() => _isConnected = true);

      _channel!.sink.add(jsonEncode({
        'type'    : 'join',
        'sender'  : _myEmail,
        'receiver': widget.friendEmail,
      }));

      _channel!.stream.listen(
        (data) {
          final msg = jsonDecode(data) as Map<String, dynamic>;
          if (msg['type'] == 'message' && mounted) {
            // Bỏ qua tin nhắn từ chính mình vì đã thêm bằng Optimistic UI
            if (msg['sender'] != _myEmail) {
              setState(() => _messages.add(msg));
              _scrollToBottom();
            }
          }
        },
        onDone: () {
          if (mounted) setState(() => _isConnected = false);
        },
        onError: (_) {
          if (mounted) setState(() => _isConnected = false);
        },
      );
    } catch (_) {
      if (mounted) setState(() => _isConnected = false);
    }
  }

  // ── Gửi tin nhắn ──────────────────────────────────────
  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final msg = {
      'type'      : 'message',
      'sender'    : _myEmail,
      'receiver'  : widget.friendEmail,
      'content'   : text,
      'created_at': DateTime.now().toIso8601String(),
    };

    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(msg));
    }

    // Optimistic UI
    setState(() => _messages.add(msg));
    _inputController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Format giờ ────────────────────────────────────────
  String _formatTime(String? rawTime) {
    if (rawTime == null) return '';
    try {
      final dt = DateTime.parse(rawTime).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  // ── Kiểm tra có nên hiện ngày không ───────────────────
  bool _shouldShowDate(int index) {
    if (index == 0) return true;
    try {
      final curr = DateTime.parse(
          _messages[index]['created_at'] ?? '').toLocal();
      final prev = DateTime.parse(
          _messages[index - 1]['created_at'] ?? '').toLocal();
      return curr.day   != prev.day   ||
             curr.month != prev.month ||
             curr.year  != prev.year;
    } catch (_) {
      return false;
    }
  }

  String _formatDate(String? rawTime) {
    if (rawTime == null) return '';
    try {
      final dt        = DateTime.parse(rawTime).toLocal();
      final now       = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return 'Hôm nay';
      }
      if (dt.day == yesterday.day &&
          dt.month == yesterday.month &&
          dt.year == yesterday.year) {
        return 'Hôm qua';
      }
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  // ── Bubble tin nhắn ───────────────────────────────────
  Widget _buildBubble(Map<String, dynamic> msg, bool isDark, int index) {
    final isMe    = msg['sender'] == _myEmail;
    final content = msg['content'] ?? '';
    final timeStr = _formatTime(msg['created_at'] as String?);

    final isLast = index == _messages.length - 1 ||
        _messages[index + 1]['sender'] != msg['sender'];

    return Column(
      children: [
        // Ngày phân cách
        if (_shouldShowDate(index))
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF222222)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatDate(msg['created_at'] as String?),
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // Bubble
        Padding(
          padding: EdgeInsets.only(
            top: 2,
            bottom: isLast ? 8 : 2,
            left: isMe ? 60 : 12,
            right: isMe ? 12 : 60,
          ),
          child: Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar bạn bè (chỉ hiện ở tin nhắn cuối cùng của chuỗi)
              if (!isMe) ...[
                if (isLast)
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isDark
                        ? const Color(0xFF2A2A2A)
                        : Colors.grey.shade200,
                    backgroundImage: widget.friendAvatarUrl != null
                        ? NetworkImage(widget.friendAvatarUrl!)
                        : null,
                    child: widget.friendAvatarUrl == null
                        ? Icon(Icons.person_rounded,
                            size: 14,
                            color: isDark ? Colors.white38 : Colors.grey)
                        : null,
                  )
                else
                  const SizedBox(width: 28),
                const SizedBox(width: 6),
              ],

              // Nội dung bubble
              Flexible(
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isMe
                            ? const LinearGradient(
                                colors: [_pink, _purple],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isMe
                            ? null
                            : (isDark
                                ? const Color(0xFF252525)
                                : Colors.white),
                        borderRadius: BorderRadius.only(
                          topLeft:     const Radius.circular(18),
                          topRight:    const Radius.circular(18),
                          bottomLeft:  Radius.circular(isMe ? 18 : (isLast ? 4 : 18)),
                          bottomRight: Radius.circular(isMe ? (isLast ? 4 : 18) : 18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isMe
                                ? _pink.withOpacity(0.2)
                                : Colors.black
                                    .withOpacity(isDark ? 0.3 : 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        content,
                        style: TextStyle(
                          color: isMe
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                          fontSize: 14.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                    // Giờ gửi
                    if (isLast && timeStr.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 4, left: 4, right: 4),
                        child: Text(
                          timeStr,
                          style: TextStyle(
                            color: isDark ? Colors.white30 : Colors.black38,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bg       = isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5);
    final inputBg  = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final divCol   = isDark ? Colors.white.withOpacity(0.08)  : Colors.black12;
    final titleCol = isDark ? Colors.white              : Colors.black87;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: inputBg,
        surfaceTintColor: inputBg,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: titleCol, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor:
                  isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
              backgroundImage: widget.friendAvatarUrl != null
                  ? NetworkImage(widget.friendAvatarUrl!)
                  : null,
              child: widget.friendAvatarUrl == null
                  ? Icon(Icons.person_rounded,
                      size: 20,
                      color: isDark ? Colors.white38 : Colors.grey)
                  : null,
            ),
            const SizedBox(width: 10),
            // Tên + trạng thái kết nối
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.friendName,
                  style: TextStyle(
                    color: titleCol,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _isConnected ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isConnected ? "Đang hoạt động" : "Đang kết nối...",
                      style: TextStyle(
                        color:
                            _isConnected ? Colors.green : Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: divCol),
        ),
      ),
      body: Column(
        children: [
          // ── Danh sách tin nhắn ──
          Expanded(
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator(color: _pink))
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.waving_hand_rounded,
                                size: 40,
                                color: isDark
                                    ? Colors.white24
                                    : Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              "Hãy bắt đầu cuộc trò chuyện!",
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white38
                                    : Colors.black38,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) =>
                            _buildBubble(_messages[index], isDark, index),
                      ),
          ),

          // ── Input box ──
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 10,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: inputBg,
              border: Border(top: BorderSide(color: divCol)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Text field
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF252525)
                          : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _inputController,
                      maxLines: null,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14.5),
                      decoration: InputDecoration(
                        hintText: "Nhắn tin...",
                        hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white38
                                : Colors.black38,
                            fontSize: 14.5),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Nút gửi
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_pink, _purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 19),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}