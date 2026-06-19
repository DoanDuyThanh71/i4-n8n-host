# =============================================================
# setup-n8n.ps1 - i4M D Lab - Cài n8n 24/7 Localhost (Windows)
# Chạy lệnh: powershell -ExecutionPolicy Bypass -File setup-n8n.ps1
# =============================================================

$ErrorActionPreference = "Stop"
$INSTALL_DIR = "$env:USERPROFILE\n8n-i4m"
$COMPOSE_VERSION = "2.14.2"

function Write-Step($msg) { Write-Host "`n[STEP] $msg" -ForegroundColor Cyan }
function Write-OK($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-WARN($msg) { Write-Host "  [!!] $msg" -ForegroundColor Yellow }
function Write-ERR($msg)  { Write-Host " [ERR] $msg" -ForegroundColor Red; exit 1 }

# ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║     i4M D Lab - Cài Đặt n8n 24/7 Localhost     ║" -ForegroundColor Magenta
Write-Host "║              Phiên bản: $COMPOSE_VERSION                  ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# ─────────────────────────────────────────────────────────────
Write-Step "1/6 - Kiểm tra Docker Desktop..."

if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
    Write-WARN "Docker chưa được cài. Đang mở trang tải Docker Desktop..."
    Start-Process "https://www.docker.com/products/docker-desktop/"
    Write-ERR "Hãy cài Docker Desktop xong rồi chạy lại script này!"
}

# Kiểm tra Docker daemon có chạy không
$dockerRunning = docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-WARN "Docker Desktop chưa khởi động. Đang mở Docker Desktop..."
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe" -ErrorAction SilentlyContinue
    Write-Host "  Đang chờ Docker khởi động (tối đa 60 giây)..." -ForegroundColor Yellow
    $waited = 0
    do {
        Start-Sleep -Seconds 5
        $waited += 5
        Write-Host "  ... $waited giây" -ForegroundColor Gray
        $dockerRunning = docker info 2>&1
    } while ($LASTEXITCODE -ne 0 -and $waited -lt 60)

    if ($LASTEXITCODE -ne 0) {
        Write-ERR "Docker vẫn chưa chạy sau 60 giây. Hãy mở Docker Desktop thủ công và chạy lại script."
    }
}
Write-OK "Docker đang chạy!"

# ─────────────────────────────────────────────────────────────
Write-Step "2/6 - Tạo thư mục cài đặt tại: $INSTALL_DIR"

if (Test-Path $INSTALL_DIR) {
    Write-WARN "Thư mục $INSTALL_DIR đã tồn tại. Sẽ sử dụng lại."
} else {
    New-Item -ItemType Directory -Path $INSTALL_DIR | Out-Null
    Write-OK "Tạo thư mục thành công: $INSTALL_DIR"
}

# Tạo các thư mục dữ liệu
$subDirs = @("n8n_data", "shared_videos", "binaryData")
foreach ($dir in $subDirs) {
    $path = Join-Path $INSTALL_DIR $dir
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
    }
    Write-OK "Thư mục dữ liệu: $dir"
}

# ─────────────────────────────────────────────────────────────
Write-Step "3/6 - Tạo file Dockerfile..."

$dockerfileContent = @"
# i4M D Lab - n8n + FFmpeg Custom Image
# Multi-stage: lấy ffmpeg static binary
FROM mwader/static-ffmpeg:6.0 AS ffmpeg

# Base: n8n chính thức
FROM n8nio/n8n:2.14.2

USER root

# Tích hợp ffmpeg & ffprobe vào n8n
COPY --from=ffmpeg /ffmpeg  /usr/local/bin/ffmpeg
COPY --from=ffmpeg /ffprobe /usr/local/bin/ffprobe

# Cấp quyền thực thi
RUN chmod +x /usr/local/bin/ffmpeg /usr/local/bin/ffprobe

USER node
"@

$dockerfileContent | Out-File -FilePath (Join-Path $INSTALL_DIR "Dockerfile") -Encoding utf8 -Force
Write-OK "Đã tạo Dockerfile"

# ─────────────────────────────────────────────────────────────
Write-Step "4/6 - Tạo file docker-compose.yml..."

$composeContent = @"
services:
  n8n:
    build: .
    container_name: n8n_i4m
    restart: always
    ports:
      - "5678:5678"
    dns:
      - 8.8.8.8
      - 1.1.1.1
    environment:
      - NODE_OPTIONS=--max-old-space-size=2048
      - N8N_HOST=localhost
      - N8N_SECURE_COOKIE=false
      - GENERIC_TIMEZONE=Asia/Ho_Chi_Minh
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=http://localhost:5678
      - EXECUTIONS_DATA_PRUNE=true
      - EXECUTIONS_DATA_MAX_AGE=24
      - EXECUTIONS_DATA_SAVE_ON_SUCCESS=all
      - EXECUTIONS_DATA_SAVE_ON_ERROR=all
    volumes:
      - ./n8n_data:/home/node/.n8n
      - ./shared_videos:/data/shared_videos
      - ./binaryData:/home/node/.n8n/binaryData
"@

$composeContent | Out-File -FilePath (Join-Path $INSTALL_DIR "docker-compose.yml") -Encoding utf8 -Force
Write-OK "Đã tạo docker-compose.yml"

# ─────────────────────────────────────────────────────────────
Write-Step "5/6 - Build image và khởi động n8n (lần đầu ~10-15 phút)..."
Write-Host "  Đang tải image n8n + ffmpeg về máy... Xin đợi." -ForegroundColor Yellow

Set-Location $INSTALL_DIR

docker compose up --build -d

if ($LASTEXITCODE -ne 0) {
    Write-ERR "Có lỗi khi chạy docker compose. Xem log bằng: docker compose logs"
}
Write-OK "n8n đã được khởi động!"

# ─────────────────────────────────────────────────────────────
Write-Step "6/6 - Chờ n8n sẵn sàng và mở trình duyệt..."

Write-Host "  Đang chờ n8n khởi động xong..." -ForegroundColor Yellow
$ready = $false
$tries = 0
do {
    Start-Sleep -Seconds 3
    $tries++
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5678" -TimeoutSec 3 -UseBasicParsing -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) { $ready = $true }
    } catch {}
    if ($tries % 5 -eq 0) { Write-Host "  ... $($tries * 3) giây" -ForegroundColor Gray }
} while (-not $ready -and $tries -lt 40)

if ($ready) {
    Start-Process "http://localhost:5678"
    Write-OK "n8n đã sẵn sàng! Trình duyệt đã được mở."
} else {
    Write-WARN "n8n khởi động lâu hơn dự kiến. Tự mở: http://localhost:5678"
    Start-Process "http://localhost:5678"
}

# ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║           ✅  CÀI ĐẶT HOÀN TẤT!                ║" -ForegroundColor Green
Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║  🌐 Địa chỉ  : http://localhost:5678            ║" -ForegroundColor Green
Write-Host "║  📂 Thư mục  : $env:USERPROFILE\n8n-i4m         ║" -ForegroundColor Green
Write-Host "║  🔄 Auto-run : Bật cùng Docker Desktop (24/7)   ║" -ForegroundColor Green
Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║  LỆNH QUẢN LÝ (chạy trong thư mục n8n-i4m):    ║" -ForegroundColor Green
Write-Host "║   Xem log   : docker compose logs -f            ║" -ForegroundColor Green
Write-Host "║   Dừng      : docker compose down               ║" -ForegroundColor Green
Write-Host "║   Bật lại   : docker compose up -d              ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
