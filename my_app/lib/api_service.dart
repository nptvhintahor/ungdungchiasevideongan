import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:3000";
  static const Duration timeoutDuration = Duration(seconds: 10);

  /// Chuyển path tương đối → URL đầy đủ.
  /// Server lưu file vào uploads/videos/ → phải build đúng thư mục con.
  static String getVideoUrl(String path) {
    if (path.isEmpty) return "";
    if (path.startsWith('http')) return path;
    if (path.startsWith('/uploads/')) return "$baseUrl$path";
    if (path.startsWith('uploads/')) return "$baseUrl/$path";
    return "$baseUrl/uploads/videos/$path";
  }

  // ================= QUẢN LÝ USER =================

  static Future<Map<String, dynamic>?> loginUser(
      String email, String password) async {
    try {
      debugPrint("🌐 POST $baseUrl/login | email=$email");
      final res = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      ).timeout(timeoutDuration);
      debugPrint("📥 Login status: ${res.statusCode} | body: ${res.body}");
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) {
          data['email'] ??= email;
          return data;
        }
      }
    } catch (e) {
      debugPrint("❌ Login Error: $e");
    }
    return null;
  }

  static Future<bool> registerUser(String email, String password) async {
    try {
      debugPrint("🌐 POST $baseUrl/register | email=$email");
      final res = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      ).timeout(timeoutDuration);
      debugPrint("📥 Register status: ${res.statusCode} | body: ${res.body}");
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint("❌ Register Error: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getUserInfo(String email) async {
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/user/$email"))
          .timeout(timeoutDuration);
      debugPrint("📥 GetUserInfo body: ${res.body}");
      if (res.statusCode == 200) {
        final data = Map<String, dynamic>.from(jsonDecode(res.body));
        final raw = data['avatar_url'] ?? data['avatarUrl'];
        if (raw != null && (raw as String).isNotEmpty) {
          data['avatarUrl'] = raw.startsWith('http') ? raw : "$baseUrl$raw";
        } else {
          data['avatarUrl'] = null;
        }
        debugPrint("✅ avatarUrl sau chuẩn hoá: ${data['avatarUrl']}");
        return data;
      }
    } catch (e) {
      debugPrint("❌ GetUserInfo Error: $e");
    }
    return null;
  }

  static Future<void> updateUserProfile(
      String email, String name, String dob, String bio) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/update-profile"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(
            {"email": email, "name": name, "dob": dob, "bio": bio}),
      ).timeout(timeoutDuration);
    } catch (e) {
      debugPrint("❌ UpdateProfile Error: $e");
    }
  }

  static Future<String?> uploadAvatar(
      {required File file, required String email}) async {
    try {
      var request =
          http.MultipartRequest("POST", Uri.parse("$baseUrl/upload-avatar"));
      request.files.add(await http.MultipartFile.fromPath("file", file.path));
      request.fields["email"] = email;
      var streamed = await request.send().timeout(const Duration(seconds: 20));
      var response = await http.Response.fromStream(streamed);
      debugPrint(
          "📥 UploadAvatar status: ${response.statusCode} | body: ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final relativePath = data["url"] as String?;
        if (relativePath == null) return null;
        final fullUrl = relativePath.startsWith('http')
            ? relativePath
            : "$baseUrl$relativePath";
        debugPrint("✅ Avatar URL đầy đủ: $fullUrl");
        return fullUrl;
      }
    } catch (e) {
      debugPrint("❌ UploadAvatar Error: $e");
    }
    return null;
  }

  static Future<bool> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      debugPrint("🌐 POST $baseUrl/change-password | email=$email");
      final res = await http.post(
        Uri.parse("$baseUrl/change-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "oldPassword": oldPassword,
          "newPassword": newPassword,
        }),
      ).timeout(timeoutDuration);
      debugPrint(
          "📥 ChangePassword status: ${res.statusCode} | body: ${res.body}");
      if (res.statusCode == 200) return true;
      if (res.statusCode == 401 || res.statusCode == 400) return false;
    } catch (e) {
      debugPrint("❌ ChangePassword Error: $e");
    }
    return false;
  }

  static Future<bool> deleteAccount(String email) async {
    try {
      debugPrint("🌐 DELETE $baseUrl/delete-account | email=$email");
      final res = await http.delete(
        Uri.parse("$baseUrl/delete-account"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      ).timeout(timeoutDuration);
      debugPrint(
          "📥 DeleteAccount status: ${res.statusCode} | body: ${res.body}");
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("❌ DeleteAccount Error: $e");
      return false;
    }
  }

  // ================= QUẢN LÝ VIDEO =================

  static Future<List<Map<String, dynamic>>> getAllVideos() async {
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/videos"))
          .timeout(timeoutDuration);
      if (res.statusCode == 200) {
        List<dynamic> data = jsonDecode(res.body);
        return data.map((v) => Map<String, dynamic>.from(v)).toList();
      }
    } catch (e) {
      debugPrint("❌ GetAllVideos Error: $e");
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getVideoById(int videoId) async {
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/video/$videoId"))
          .timeout(timeoutDuration);
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      debugPrint("❌ GetVideoById Error: $e");
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getVideosByEmail(
      String email) async {
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/videos/$email"))
          .timeout(timeoutDuration);
      if (res.statusCode == 200) {
        List<dynamic> data = jsonDecode(res.body);
        return data.map((v) => Map<String, dynamic>.from(v)).toList();
      }
    } catch (e) {
      debugPrint("❌ GetVideosByEmail Error: $e");
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getLikedVideos(
      String email) async {
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/liked/$email"))
          .timeout(timeoutDuration);
      if (res.statusCode == 200) {
        List<dynamic> data = jsonDecode(res.body);
        return data.map((v) => Map<String, dynamic>.from(v)).toList();
      }
    } catch (e) {
      debugPrint("❌ GetLikedVideos Error: $e");
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getSharedVideos(
      String email) async {
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/shared/$email"))
          .timeout(timeoutDuration);
      if (res.statusCode == 200) {
        List<dynamic> data = jsonDecode(res.body);
        return data.map((v) => Map<String, dynamic>.from(v)).toList();
      }
    } catch (e) {
      debugPrint("❌ GetSharedVideos Error: $e");
    }
    return [];
  }

  static Future<bool> uploadVideo(
      {required File file, required String userEmail}) async {
    try {
      var request =
          http.MultipartRequest("POST", Uri.parse("$baseUrl/upload"));
      request.files.add(await http.MultipartFile.fromPath("video", file.path));
      request.fields["email"] = userEmail;
      var streamedResponse =
          await request.send().timeout(const Duration(seconds: 60));
      var response = await http.Response.fromStream(streamedResponse);
      debugPrint("📥 Server Status: ${response.statusCode}");
      debugPrint("📥 Server Body: ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ Catch Error tại ApiService: $e");
      return false;
    }
  }

  static Future<bool> deleteVideo(int videoId) async {
    try {
      debugPrint("🌐 DELETE $baseUrl/video/$videoId");
      final res = await http.delete(
        Uri.parse("$baseUrl/video/$videoId"),
      ).timeout(timeoutDuration);
      debugPrint(
          "📥 DeleteVideo status: ${res.statusCode} | body: ${res.body}");
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("❌ DeleteVideo Error: $e");
      return false;
    }
  }

  // ================= TƯƠNG TÁC =================

  static Future<void> toggleLike(int videoId, String email) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/like"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"videoId": videoId, "email": email}),
      );
    } catch (e) {
      debugPrint("❌ ToggleLike Error: $e");
    }
  }

  static Future<bool> isVideoLiked(int videoId, String email) async {
    try {
      final res =
          await http.get(Uri.parse("$baseUrl/isLiked/$videoId/$email"));
      if (res.statusCode == 200) {
        return jsonDecode(res.body)["liked"] ?? false;
      }
    } catch (e) {
      debugPrint("❌ IsLiked Error: $e");
    }
    return false;
  }

  static Future<List<Map<String, dynamic>>> getComments(int videoId) async {
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/comments/$videoId"))
          .timeout(timeoutDuration);
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint("❌ GetComments Error: $e");
    }
    return [];
  }

  static Future<void> insertComment(
      int videoId, String email, String content) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/comment"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(
            {"videoId": videoId, "email": email, "content": content}),
      ).timeout(timeoutDuration);
    } catch (e) {
      debugPrint("❌ InsertComment Error: $e");
    }
  }

  // ================= KẾT BẠN =================

  static Future<List<Map<String, dynamic>>> getFriendsList(
      String email) async {
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/friends/$email"))
          .timeout(timeoutDuration);
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint("❌ GetFriendsList Error: $e");
    }
    return [];
  }

  static Future<int> getFriendRequests(String email) async {
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/friends/requests/count/$email"))
          .timeout(timeoutDuration);
      if (res.statusCode == 200) {
        return jsonDecode(res.body)["count"] ?? 0;
      }
    } catch (e) {
      debugPrint("❌ GetFriendRequests Error: $e");
    }
    return 0;
  }

  static Future<List<Map<String, dynamic>>> getPendingRequests(
      String email) async {
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/friends/requests/$email"))
          .timeout(timeoutDuration);
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint("❌ GetPendingRequests Error: $e");
    }
    return [];
  }

  static Future<void> sendFriendRequest(
      String sender, String receiver) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/friends/request"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"sender": sender, "receiver": receiver}),
      ).timeout(timeoutDuration);
    } catch (e) {
      debugPrint("❌ SendFriendRequest Error: $e");
    }
  }

  static Future<void> acceptFriendRequest(
      String user, String requester) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/friends/accept"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user": user, "requester": requester}),
      ).timeout(timeoutDuration);
    } catch (e) {
      debugPrint("❌ AcceptFriendRequest Error: $e");
    }
  }

  /// Huỷ kết bạn — dùng query params vì Flutter http.delete không hỗ trợ body đáng tin cậy
  static Future<bool> unfriend(String user1, String user2) async {
    try {
      debugPrint("🌐 DELETE $baseUrl/friends?user1=$user1&user2=$user2");
      final uri = Uri.parse("$baseUrl/friends").replace(
        queryParameters: {"user1": user1, "user2": user2},
      );
      final res = await http.delete(uri).timeout(timeoutDuration);
      debugPrint(
          "📥 Unfriend status: ${res.statusCode} | body: ${res.body}");
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("❌ Unfriend Error: $e");
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> searchUsers(
      String query, String currentUserEmail) async {
    try {
      final res = await http.get(
        Uri.parse(
            "$baseUrl/users/search?q=$query&caller=$currentUserEmail"),
      ).timeout(timeoutDuration);
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint("❌ SearchUsers Error: $e");
    }
    return [];
  }

  // ================= CHIA SẺ VIDEO =================

  static Future<bool> shareVideo({
    required String senderEmail,
    required String receiverEmail,
    required int videoId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/share"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sender_email": senderEmail,
          "receiver_email": receiverEmail,
          "video_id": videoId,
        }),
      ).timeout(timeoutDuration);
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint("❌ ShareVideo Error: $e");
      return false;
    }
  }

  // ================= THỐNG KÊ =================

  static Future<int> getTotalLikes(String email) async {
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/totalLikes/$email"))
          .timeout(timeoutDuration);
      if (res.statusCode == 200) {
        return jsonDecode(res.body)["total"] ?? 0;
      }
    } catch (e) {
      debugPrint("❌ TotalLikes Error: $e");
    }
    return 0;
  }

  static Future<int> getTotalFriends(String email) async {
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/friends/count/$email"))
          .timeout(timeoutDuration);
      if (res.statusCode == 200) {
        return jsonDecode(res.body)["count"] ?? 0;
      }
    } catch (e) {
      debugPrint("❌ FriendsCount Error: $e");
    }
    return 0;
  }

  // ================= TIN NHẮN =================

  /// Lấy lịch sử tin nhắn giữa 2 người
  static Future<List<Map<String, dynamic>>> getMessages(
      String user1, String user2) async {
    try {
      debugPrint("🌐 GET $baseUrl/messages/$user1/$user2");
      final res = await http
          .get(Uri.parse("$baseUrl/messages/$user1/$user2"))
          .timeout(timeoutDuration);
      debugPrint("📥 GetMessages status: ${res.statusCode}");
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint("❌ GetMessages Error: $e");
    }
    return [];
  }
}