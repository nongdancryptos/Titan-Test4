# 🚀 Titan Test4 - Multipass Auto Installer

Script tự động cài đặt và triển khai **5 node Titan Agent** trên Linux bằng Multipass. Dành cho anh em muốn tham gia test Titan Network nhanh gọn và không rối.
---
## 🌐 Tạo Tài Khoản Titan

Truy cập link bên dưới để tạo tài khoản Titan trước khi chạy script:

👉 [https://test4.titannet.io/Invitelogin?code=2zNL3u](https://test4.titannet.io/Invitelogin?code=2zNL3u)

Sau khi tạo xong tài khoản, đăng nhập để lấy **Key** của bạn, sẽ dùng ở bước cài đặt node.
## 📟 Tính năng

- Cài đặt Snap & Multipass
- Triển khai 5 node Titan riêng biệt
- Menu CLI dễ dùng: khởi chạy, SSH vào node, xoá node...
- Hỗ trợ auto setup môi trường, yêu cầu thấp

---

## 📌 Yêu cầu hệ thống

- **OS:** Ubuntu / Debian / Fedora / CentOS / RHEL
- **CPU:** Tối thiểu 2 cores (mỗi node)
- **RAM:** Tối thiểu 4GB (mỗi node)
- **Disk:** Tối thiểu 50GB trống
- **Arch:** x86_64

---

## ⚙️ Cách sử dụng

### 1. Cài Snap & Multipass (nếu chưa có)

#### Ubuntu / Debian

```bash
sudo apt update && sudo apt install snapd -y
sudo systemctl enable --now snapd.socket
```

#### Fedora

```bash
sudo dnf install snapd -y
sudo systemctl enable --now snapd.socket
```

#### CentOS / RHEL

```bash
sudo yum install snapd -y
sudo systemctl enable --now snapd.socket
```

### 2. Chạy script tự động

#### Cách 1: Chạy nhanh trực tiếp từ GitHub

```bash
bash <(curl -s https://raw.githubusercontent.com/nongdancryptos/Titan-Test4/main/titan_multipass_full.sh)
```

#### Cách 2: Tải về thủ công

```bash
wget https://github.com/nongdancryptos/Titan-Test4/raw/refs/heads/main/titan_multipass_full.sh
chmod +x titan_multipass_full.sh
./titan_multipass_full.sh
```
---- hoặc
```bash
wget https://github.com/nongdancryptos/Titan-Test4/raw/refs/heads/main/titanproxy.sh
chmod +x titanproxy.sh
./titanproxy.sh
```

---

## 🧹 Menu CLI khi chạy script

```
===== TITAN MULTIPASS MENU =====
1. Cài đặt Snap & Multipass
2. Tạo 5 node Titan
3. Xem trạng thái node
4. SSH vào một node
5. Xoá toàn bộ node
0. Thoát
```

---

## 🔑 Cách lấy KEY Titan

1. Truy cập: https://titannet.io  
2. Đăng nhập tài khoản
3. Copy KEY hiển thị trên dashboard
4. Dán vào khi script yêu cầu

---

## 📦 Lệnh quản lý Multipass

- Xem danh sách node:
  ```bash
  multipass list
  ```

- SSH vào node:
  ```bash
  multipass shell titan-node-1
  ```

- Xoá 1 node:
  ```bash
  multipass delete titan-node-1 && multipass purge
  ```

- Xoá toàn bộ node:
  ```bash
  multipass delete --all && multipass purge
  ```

---

## 🛠️ Nếu gặp lỗi?

| Vấn đề | Cách xử lý |
|--------|------------|
| Multipass không chạy | Kiểm tra VT-x/AMD-V đã bật trong BIOS chưa |
| Agent không chạy | Kiểm tra đã cấp quyền `chmod +x agent` |
| Lỗi unzip | Cài `unzip`: `sudo apt install unzip -y` |
| Lỗi khi tạo VM | Cài thêm: `sudo apt install qemu-kvm libvirt-daemon-system -y` |

---

## 💡 Tuý chỉnh số lượng node

Mở file `titan_multipass_full.sh` và sửa dòng:

```bash
for i in {1..5}
```

Thành:

```bash
for i in {1..10}
```

Để tạo 10 node chẳng hạn.

---

## 🧑‍💻 Tác giả

- GitHub: [@nongdancryptos](https://github.com/nongdancryptos)
- Telegram: [@OnTopAirdrop](https://t.me/OnTopAirdrop)

---

## ☕ Donate

Ủng hộ để mình duy trì tool miễn phí:

- **EVM:** `0x431588aff8ea1becb1d8188d87195aa95678ba0a`
- **SOLANA:** `3rYhoVL8g28iwjGQq8hKw4bvVmBGhyC8DEbKAwzmy4wn`

---

**Chúc bạn test Titan thành công và săn được nhiều phần thưởng!**
