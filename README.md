# Cấu Hình Back-up & Vận Hành n8n (VPS và Localhost)

Thư mục này chứa toàn bộ cấu hình n8n đang chạy thực tế trên VPS của bạn (phiên bản `2.14.2` tích hợp sẵn `ffmpeg` và `ffprobe`), kèm theo bản tối ưu hóa để bạn chạy thử nghiệm ở local máy cá nhân.

---

## 📂 1. Danh Sách File Cấu Hình

1. **[docker-compose-prod.yml](file:///d:/PJ/VPS/n8n/docker-compose-prod.yml)**: 
   * **Bản sao lưu gốc từ VPS**. 
   * Sử dụng chế độ mạng trực tiếp (`network_mode: "host"`), tên miền chính thức `https://n8n.n8n71.com` và các đường dẫn tuyệt đối trực tiếp của hệ thống Linux VPS (`/opt/n8n/n8n_data`, `/var/www/html/reup_videos`).

2. **[docker-compose.yml](file:///d:/PJ/VPS/n8n/docker-compose.yml)**:
   * **Bản chạy trên máy Local cá nhân**.
   * Đã được chuyển đổi sang cổng ánh xạ (`ports: 5678:5678`), tên miền local (`http://localhost:5678`) và đường dẫn volume tương đối (`./n8n_data`, `./shared_videos`, `./binaryData`) để chạy được ngay trên Windows/macOS thông qua Docker Desktop.

3. **[Dockerfile](file:///d:/PJ/VPS/n8n/Dockerfile)**:
   * File build image tùy chỉnh để tích hợp thư viện static **FFmpeg & FFprobe (v6.0)** vào n8n bản gốc, phục vụ cho các tiến trình tự động tải và cắt ghép video.

4. **[clean_n8n.sh](file:///d:/PJ/VPS/n8n/clean_n8n.sh)**:
   * Tập lệnh tự động dọn dẹp dung lượng rác và video tạm thừa của n8n trên VPS (được kích hoạt chạy tự động 30 phút/lần qua Cron Job) nhằm giữ ổ cứng VPS luôn an toàn ở mức dưới 90%.

---

## 💻 2. Hướng Dẫn Chạy Trên Localhost (Windows / macOS)

Để chạy thử nghiệm hoặc phục hồi dữ liệu n8n trên máy tính cá nhân của bạn, hãy thực hiện các bước sau:

### ⚡ Bước 1: Khởi động Docker Desktop
Hãy đảm bảo phần mềm **Docker Desktop** đã được bật và đang chạy bình thường trên máy tính cá nhân của bạn.

### 🚀 Bước 2: Chạy n8n Local
Mở terminal (PowerShell, Command Prompt hoặc Terminal trên macOS) ngay tại thư mục local này (`d:\PJ\VPS\n8n`) và gõ lệnh sau:

```bash
docker compose up -d --build
```

Lệnh này sẽ:
1. Tự động tải bản n8n `2.14.2` và build tích hợp FFmpeg vào image.
2. Ánh xạ dữ liệu chạy n8n vào thư mục `./n8n_data` ngay trên máy tính của bạn.
3. Chạy container ngầm trong nền.

Sau khi khởi động thành công, bạn có thể truy cập n8n local tại: 👉 **http://localhost:5678**

---

## 💾 3. Cách Đẩy Lên GitHub Để Sao Lưu
Thư mục gốc đã có sẵn file `.gitignore` để loại bỏ dữ liệu nhạy cảm (như SQLite database chứa API Keys của bạn và các video đã tải). Để đẩy cấu hình thông minh này lên GitHub:

```bash
git init
git add .
git commit -m "feat: backup VPS n8n configurations and cleanup script"
git branch -M main
git remote add origin <URL_KHO_GITHUB_CỦA_BẠN>
git push -u origin main
```
