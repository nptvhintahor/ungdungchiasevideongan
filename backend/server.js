const express = require("express");
const mysql = require("mysql2");
const bodyParser = require("body-parser");
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const cors = require("cors");
const { createServer } = require("http");
const { WebSocketServer } = require("ws");
const { parse } = require("url");

const app = express();

app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// ================= 1. DEBUG =================
app.use((req, res, next) => {
  console.log(`\n🔔 [${new Date().toLocaleTimeString()}] ${req.method} ${req.url}`);
  if (req.body && typeof req.body === "object" && Object.keys(req.body).length > 0) {
    console.log("📦 Data Body:", req.body);
  }
  next();
});

// ================= 2. DATABASE =================
const pool = mysql
  .createPool({
    host: "localhost",
    user: "root",
    password: "",
    database: "tiktok_clone",
    waitForConnections: true,
    connectionLimit: 10,
  })
  .promise();

pool
  .getConnection()
  .then((conn) => {
    console.log("✅ MySQL Connected successfully via Pool!");
    conn.release();
  })
  .catch((err) => {
    console.error("❌ MySQL Connection Error:", err.message);
  });

// ================= 3. MULTER – VIDEO =================
const videoStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = "./uploads/videos/";
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  },
});

const upload = multer({
  storage: videoStorage,
  limits: { fileSize: 100 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = [".mp4", ".mov", ".avi"];
    const ext = path.extname(file.originalname).toLowerCase();
    if (allowed.includes(ext)) cb(null, true);
    else cb(new Error("Only video files allowed"));
  },
});

// ================= 4. MULTER – AVATAR =================
const avatarStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = "./uploads/avatars/";
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, `avatar_${Date.now()}${ext}`);
  },
});

const uploadAvatar = multer({
  storage: avatarStorage,
  limits: { fileSize: 2 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = [".jpg", ".jpeg", ".png", ".webp"];
    const ext = path.extname(file.originalname).toLowerCase();
    if (allowed.includes(ext)) cb(null, true);
    else cb(new Error("Only image files allowed"));
  },
});

// ================= 5. AUTH =================

app.post("/register", async (req, res) => {
  const { email, password } = req.body;
  try {
    await pool.query("INSERT INTO users(email, password) VALUES(?,?)", [
      email,
      password,
    ]);
    console.log("✅ Register thành công:", email);
    res.json({ status: "ok" });
  } catch (err) {
    console.error("❌ Register error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

app.post("/login", async (req, res) => {
  const { email, password } = req.body;
  try {
    const [rows] = await pool.query(
      "SELECT * FROM users WHERE email=? AND password=?",
      [email, password]
    );
    if (rows.length > 0) {
      console.log("✅ Login thành công:", email);
      res.json(rows[0]);
    } else {
      console.log("❌ Login thất bại");
      res.status(401).json({ error: "Sai email hoặc mật khẩu" });
    }
  } catch (err) {
    console.error("❌ Login DB error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

app.get("/user/:email", async (req, res) => {
  try {
    const [rows] = await pool.query("SELECT * FROM users WHERE email=?", [
      req.params.email,
    ]);
    res.json(rows[0] || {});
  } catch (err) {
    res.json({});
  }
});

app.post("/update-profile", async (req, res) => {
  const { email, name, dob, bio } = req.body;
  try {
    await pool.query(
      "UPDATE users SET name=?, dob=?, bio=? WHERE email=?",
      [name, dob, bio, email]
    );
    console.log("✅ Cập nhật profile:", email);
    res.json({ status: "ok" });
  } catch (err) {
    console.error("❌ Update profile error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

app.post("/change-password", async (req, res) => {
  const { email, oldPassword, newPassword } = req.body;
  try {
    const [rows] = await pool.query(
      "SELECT * FROM users WHERE email=? AND password=?",
      [email, oldPassword]
    );
    if (rows.length === 0) {
      return res.status(401).json({ error: "Mật khẩu cũ không đúng" });
    }
    await pool.query("UPDATE users SET password=? WHERE email=?", [
      newPassword,
      email,
    ]);
    console.log("✅ Đổi mật khẩu:", email);
    res.json({ status: "ok" });
  } catch (err) {
    console.error("❌ Change password error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

app.delete("/delete-account", async (req, res) => {
  const { email } = req.body;
  try {
    await pool.query("DELETE FROM video_likes WHERE user_email=?", [email]);
    await pool.query("DELETE FROM comments WHERE user_email=?", [email]);
    await pool.query("DELETE FROM shares WHERE sender=? OR receiver=?", [email, email]);
    await pool.query("DELETE FROM friends WHERE user1=? OR user2=?", [email, email]);
    await pool.query("DELETE FROM messages WHERE sender=? OR receiver=?", [email, email]);
    await pool.query("DELETE FROM videos WHERE user_email=?", [email]);
    await pool.query("DELETE FROM users WHERE email=?", [email]);
    console.log("✅ Đã xoá tài khoản:", email);
    res.json({ status: "ok" });
  } catch (err) {
    console.error("❌ Delete account error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// ================= 6. UPLOAD AVATAR =================

app.post("/upload-avatar", uploadAvatar.single("file"), async (req, res) => {
  const { email } = req.body;

  if (!req.file || !email) {
    return res.status(400).json({ error: "Thiếu file hoặc email" });
  }

  try {
    const [rows] = await pool.query(
      "SELECT avatar_url FROM users WHERE email=?",
      [email]
    );
    if (rows.length > 0 && rows[0].avatar_url) {
      const oldRelPath = rows[0].avatar_url.replace(/^\//, "");
      const oldFullPath = path.join(__dirname, oldRelPath);
      if (fs.existsSync(oldFullPath)) {
        fs.unlinkSync(oldFullPath);
        console.log("🗑️  Đã xóa avatar cũ:", oldFullPath);
      }
    }

    const avatarUrl = `/uploads/avatars/${req.file.filename}`;
    await pool.query("UPDATE users SET avatar_url=? WHERE email=?", [
      avatarUrl,
      email,
    ]);

    console.log("✅ Upload avatar:", email, "→", avatarUrl);
    res.json({ url: avatarUrl });
  } catch (err) {
    console.error("❌ Upload avatar error:", err.message);
    if (req.file) fs.unlinkSync(req.file.path);
    res.status(500).json({ error: err.message });
  }
});

// ================= 7. VIDEO =================

app.get("/videos", async (req, res) => {
  try {
    const [rows] = await pool.query("SELECT * FROM videos ORDER BY id DESC");
    res.json(rows);
  } catch (err) {
    res.status(500).json([]);
  }
});

app.get("/video/:id", async (req, res) => {
  try {
    const [rows] = await pool.query("SELECT * FROM videos WHERE id=?", [
      req.params.id,
    ]);
    if (rows.length > 0) res.json(rows[0]);
    else res.status(404).json({});
  } catch (err) {
    res.status(500).json({});
  }
});

// ================= XOÁ VIDEO =================

app.delete("/video/:id", async (req, res) => {
  const videoId = req.params.id;
  try {
    const [rows] = await pool.query("SELECT path FROM videos WHERE id=?", [videoId]);
    if (rows.length === 0) {
      return res.status(404).json({ error: "Video không tồn tại" });
    }

    const filePath = path.join(__dirname, "uploads", "videos", rows[0].path);
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
      console.log("🗑️  Đã xoá file:", filePath);
    }

    await pool.query("DELETE FROM video_likes WHERE video_id=?", [videoId]);
    await pool.query("DELETE FROM comments WHERE video_id=?", [videoId]);
    await pool.query("DELETE FROM shares WHERE video_id=?", [videoId]);
    await pool.query("DELETE FROM videos WHERE id=?", [videoId]);

    console.log("✅ Đã xoá video id:", videoId);
    res.json({ status: "ok" });
  } catch (err) {
    console.error("❌ Delete video error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

app.get("/videos/:email", async (req, res) => {
  try {
    const [rows] = await pool.query(
      "SELECT * FROM videos WHERE user_email=? ORDER BY id DESC",
      [req.params.email]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json([]);
  }
});

app.post("/upload", upload.single("video"), async (req, res) => {
  if (!req.file || !req.body.email) {
    return res.status(400).json({ error: "Missing file or email" });
  }

  try {
    const [result] = await pool.query(
      "INSERT INTO videos(path, user_email, likes) VALUES(?,?,0)",
      [req.file.filename, req.body.email]
    );
    res.json({
      status: "ok",
      id: result.insertId,
      url: `/uploads/videos/${req.file.filename}`,
    });
  } catch (err) {
    console.error("❌ DB Upload Error:", err.message);
    if (req.file) fs.unlinkSync(req.file.path);
    res.status(500).json({ error: "DB Error" });
  }
});

// ================= 8. LIKE =================

app.post("/like", async (req, res) => {
  const { videoId, email } = req.body;
  try {
    const [check] = await pool.query(
      "SELECT * FROM video_likes WHERE video_id=? AND user_email=?",
      [videoId, email]
    );
    if (check.length === 0) {
      await pool.query(
        "INSERT INTO video_likes(video_id, user_email) VALUES(?,?)",
        [videoId, email]
      );
      await pool.query(
        "UPDATE videos SET likes = likes + 1 WHERE id=?",
        [videoId]
      );
    } else {
      await pool.query(
        "DELETE FROM video_likes WHERE video_id=? AND user_email=?",
        [videoId, email]
      );
      await pool.query(
        "UPDATE videos SET likes = likes - 1 WHERE id=?",
        [videoId]
      );
    }
    res.send("ok");
  } catch (err) {
    res.status(500).send("error");
  }
});

app.get("/isLiked/:videoId/:email", async (req, res) => {
  try {
    const [rows] = await pool.query(
      "SELECT * FROM video_likes WHERE video_id=? AND user_email=?",
      [req.params.videoId, req.params.email]
    );
    res.json({ liked: rows.length > 0 });
  } catch (err) {
    res.json({ liked: false });
  }
});

app.get("/liked/:email", async (req, res) => {
  try {
    const [rows] = await pool.query(
      "SELECT v.* FROM videos v JOIN video_likes l ON v.id = l.video_id WHERE l.user_email=?",
      [req.params.email]
    );
    res.json(rows);
  } catch (err) {
    res.json([]);
  }
});

// ================= 9. COMMENT =================

app.post("/comment", async (req, res) => {
  const { videoId, email, content } = req.body;
  try {
    await pool.query(
      "INSERT INTO comments(video_id, user_email, content) VALUES(?,?,?)",
      [videoId, email, content]
    );
    res.send("ok");
  } catch (err) {
    res.status(500).send("error");
  }
});

app.get("/comments/:id", async (req, res) => {
  try {
    const [rows] = await pool.query(
      "SELECT * FROM comments WHERE video_id=? ORDER BY id DESC",
      [req.params.id]
    );
    res.json(rows);
  } catch (err) {
    res.json([]);
  }
});

// ================= 10. FRIEND =================

app.get("/friends/count/:email", async (req, res) => {
  try {
    const [rows] = await pool.query(
      "SELECT COUNT(*) as count FROM friends WHERE (user1=? OR user2=?) AND status='accepted'",
      [req.params.email, req.params.email]
    );
    res.json({ count: rows[0].count || 0 });
  } catch (err) {
    res.json({ count: 0 });
  }
});

app.get("/friends/requests/count/:email", async (req, res) => {
  try {
    const [rows] = await pool.query(
      "SELECT COUNT(*) as count FROM friends WHERE user2=? AND status='pending'",
      [req.params.email]
    );
    res.json({ count: rows[0].count || 0 });
  } catch (err) {
    res.json({ count: 0 });
  }
});

app.get("/friends/requests/:email", async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT u.email, u.name, u.bio, u.avatar_url FROM friends f
       JOIN users u ON u.email = f.user1
       WHERE f.user2=? AND f.status='pending'`,
      [req.params.email]
    );
    res.json(rows);
  } catch (err) {
    res.json([]);
  }
});

app.post("/friends/request", async (req, res) => {
  const { sender, receiver } = req.body;
  try {
    const [check] = await pool.query(
      "SELECT * FROM friends WHERE (user1=? AND user2=?) OR (user1=? AND user2=?)",
      [sender, receiver, receiver, sender]
    );
    if (check.length === 0) {
      await pool.query(
        "INSERT INTO friends(user1, user2, status) VALUES(?,?,'pending')",
        [sender, receiver]
      );
    }
    res.json({ status: "ok" });
  } catch (err) {
    res.status(500).send("error");
  }
});

app.post("/friends/accept", async (req, res) => {
  const { user, requester } = req.body;
  try {
    await pool.query(
      "UPDATE friends SET status='accepted' WHERE user1=? AND user2=? AND status='pending'",
      [requester, user]
    );
    res.json({ status: "ok" });
  } catch (err) {
    res.status(500).send("error");
  }
});

// ================= HUỶ KẾT BẠN =================
app.delete("/friends", async (req, res) => {
  const user1 = req.query.user1 || req.body?.user1;
  const user2 = req.query.user2 || req.body?.user2;

  if (!user1 || !user2) {
    return res.status(400).json({ error: "Thiếu user1 hoặc user2" });
  }

  try {
    const [result] = await pool.query(
      "DELETE FROM friends WHERE (user1=? AND user2=?) OR (user1=? AND user2=?)",
      [user1, user2, user2, user1]
    );
    console.log("✅ Đã huỷ kết bạn:", user1, "<->", user2, "| affectedRows:", result.affectedRows);
    res.json({ status: "ok" });
  } catch (err) {
    console.error("❌ Unfriend error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

app.get("/friends/:email", async (req, res) => {
  const email = req.params.email;
  try {
    const [rows] = await pool.query(
      `SELECT CASE WHEN user1=? THEN user2 ELSE user1 END AS email
       FROM friends WHERE (user1=? OR user2=?) AND status='accepted'`,
      [email, email, email]
    );
    if (rows.length === 0) return res.json([]);
    const emails = rows.map((r) => r.email);
    const placeholders = emails.map(() => "?").join(",");
    const [users] = await pool.query(
      `SELECT email, name, bio, avatar_url FROM users WHERE email IN (${placeholders})`,
      emails
    );
    res.json(users);
  } catch (err) {
    res.json([]);
  }
});

// ================= 11. SEARCH =================

app.get("/users/search", async (req, res) => {
  const { q, caller } = req.query;
  if (!q || !caller) return res.json([]);
  try {
    const [users] = await pool.query(
      `SELECT email, name, bio, avatar_url FROM users
       WHERE (email LIKE ? OR name LIKE ?) AND email != ? LIMIT 20`,
      [`%${q}%`, `%${q}%`, caller]
    );
    const [relations] = await pool.query(
      "SELECT user1, user2, status FROM friends WHERE user1=? OR user2=?",
      [caller, caller]
    );

    const result = users.map((user) => {
      const rel = relations.find(
        (r) =>
          (r.user1 === caller && r.user2 === user.email) ||
          (r.user1 === user.email && r.user2 === caller)
      );

      let relationship_status = "none";
      if (rel) {
        if (rel.status === "accepted") relationship_status = "friends";
        else if (rel.status === "pending")
          relationship_status =
            rel.user1 === caller ? "pending" : "incoming";
      }

      return { ...user, relationship_status };
    });

    res.json(result);
  } catch (err) {
    res.status(500).json([]);
  }
});

// ================= 12. SHARE =================

app.get("/shared/:email", async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT v.* FROM videos v
       JOIN shares s ON v.id = s.video_id
       WHERE s.receiver=?`,
      [req.params.email]
    );
    res.json(rows);
  } catch (err) {
    res.json([]);
  }
});

app.post("/share", async (req, res) => {
  const { sender_email, receiver_email, video_id } = req.body;
  try {
    await pool.query(
      "INSERT INTO shares(sender, receiver, video_id) VALUES(?,?,?)",
      [sender_email, receiver_email, video_id]
    );
    res.json({ status: "ok" });
  } catch (err) {
    res.status(500).json({ error: "DB Error" });
  }
});

// ================= 13. THỐNG KÊ =================

app.get("/totalLikes/:email", async (req, res) => {
  try {
    const [rows] = await pool.query(
      "SELECT SUM(likes) as total FROM videos WHERE user_email=?",
      [req.params.email]
    );
    res.json({ total: rows[0].total || 0 });
  } catch (err) {
    res.json({ total: 0 });
  }
});

// ================= 14. MESSAGES (REST) =================

// Lấy lịch sử tin nhắn giữa 2 người
app.get("/messages/:user1/:user2", async (req, res) => {
  const { user1, user2 } = req.params;
  try {
    const [rows] = await pool.query(
      `SELECT * FROM messages
       WHERE (sender=? AND receiver=?) OR (sender=? AND receiver=?)
       ORDER BY created_at ASC`,
      [user1, user2, user2, user1]
    );
    res.json(rows);
  } catch (err) {
    console.error("❌ GetMessages Error:", err.message);
    res.json([]);
  }
});

// ================= 15. WEBSOCKET SERVER =================

const server = createServer(app);
const wss = new WebSocketServer({ noServer: true });

// Map lưu các client đang kết nối: email → Set<WebSocket>
const clients = new Map();

function registerClient(email, ws) {
  if (!clients.has(email)) clients.set(email, new Set());
  clients.get(email).add(ws);
}

function removeClient(email, ws) {
  if (!clients.has(email)) return;
  clients.get(email).delete(ws);
  if (clients.get(email).size === 0) clients.delete(email);
}

function sendToUser(email, data) {
  if (!clients.has(email)) return;
  const payload = JSON.stringify(data);
  clients.get(email).forEach((ws) => {
    if (ws.readyState === 1) ws.send(payload);
  });
}

wss.on("connection", (ws) => {
  let myEmail = null;

  ws.on("message", async (raw) => {
    try {
      const msg = JSON.parse(raw.toString());

      // Đăng ký phòng chat
      if (msg.type === "join") {
        myEmail = msg.sender;
        registerClient(myEmail, ws);
        console.log(`✅ WS join: ${myEmail}`);
        return;
      }

      // Gửi tin nhắn
      if (msg.type === "message") {
        const { sender, receiver, content } = msg;
        if (!sender || !receiver || !content) return;

        // Lưu vào DB
        const [result] = await pool.query(
          "INSERT INTO messages(sender, receiver, content) VALUES(?,?,?)",
          [sender, receiver, content]
        );

        const saved = {
          type      : "message",
          id        : result.insertId,
          sender,
          receiver,
          content,
          created_at: new Date().toISOString(),
        };

        // Gửi đến receiver (nếu online)
        sendToUser(receiver, saved);
        // Gửi lại sender để đồng bộ
        sendToUser(sender, saved);

        console.log(`💬 ${sender} → ${receiver}: ${content}`);
      }
    } catch (err) {
      console.error("❌ WS message error:", err.message);
    }
  });

  ws.on("close", () => {
    if (myEmail) {
      removeClient(myEmail, ws);
      console.log(`👋 WS disconnected: ${myEmail}`);
    }
  });
});

// Upgrade HTTP → WebSocket tại path /ws/chat
server.on("upgrade", (req, socket, head) => {
  const { pathname } = parse(req.url);
  if (pathname === "/ws/chat") {
    wss.handleUpgrade(req, socket, head, (ws) => {
      wss.emit("connection", ws, req);
    });
  } else {
    socket.destroy();
  }
});

// ================= SERVER =================
const PORT = 3000;
server.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
  console.log(`🔌 WebSocket ready at ws://localhost:${PORT}/ws/chat`);
});
// Get-Process node | Stop-Process -Force