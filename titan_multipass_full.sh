#!/bin/bash

# === CONFIG ===
INSTALL_DIR="/opt/titanagent"
TITAN_URL="https://pcdn.titannet.io/test4/bin/agent-linux.zip"
TITAN_API="https://test4-api.titannet.io"
IMAGE="20.04"

# === MÀU SẮC ===
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# === KIỂM TRA VÀ CÀI SNAP + MULTIPASS ===
check_dependencies() {
  echo -e "${CYAN}🔍 Kiểm tra Snap & Multipass...${NC}"

  if ! command -v snap >/dev/null 2>&1; then
    echo -e "${GREEN}⚙️ Cài đặt Snap...${NC}"
    sudo apt update && sudo apt install -y snapd
    sudo systemctl enable --now snapd.socket
  fi

  if ! command -v multipass >/dev/null 2>&1; then
    echo -e "${GREEN}⚙️ Cài đặt Multipass...${NC}"
    sudo snap install multipass
  fi

  echo -e "${GREEN}✅ Đã cài đặt đầy đủ Snap & Multipass.${NC}"
}

# === TẠO NODE TITAN ===
create_nodes() {
  read -p "🔑 Nhập Titan Agent Key của bạn: " titan_key
  read -p "🔢 Nhập số lượng node muốn tạo: " node_count

  for i in $(seq 1 $node_count); do
    name="titan-node-$i"

    if multipass info $name >/dev/null 2>&1; then
      echo -e "${RED}⚠️ VM $name đã tồn tại, bỏ qua.${NC}"
      continue
    fi

    read -p "🌐 Nhập proxy cho node $name (để trống nếu không dùng): " proxy_url

    echo -e "\n${CYAN}🚀 Tạo VM: $name...${NC}"
    multipass launch $IMAGE --name $name --memory 2G --disk 10G --cpus 2

    echo -e "${CYAN}⚙️ Cài Titan Agent trong $name...${NC}"
    multipass exec $name -- bash -c "
      sudo apt update &&
      sudo apt install -y wget unzip &&
      sudo mkdir -p $INSTALL_DIR &&
      cd $INSTALL_DIR &&
      sudo wget -q $TITAN_URL &&
      sudo unzip -o agent-linux.zip &&
      sudo chmod +x agent &&
      echo '[Unit]' | sudo tee /etc/systemd/system/titanagent.service > /dev/null &&
      echo 'Description=Titan Agent' | sudo tee -a /etc/systemd/system/titanagent.service > /dev/null &&
      echo 'After=network.target' | sudo tee -a /etc/systemd/system/titanagent.service > /dev/null &&
      echo '' | sudo tee -a /etc/systemd/system/titanagent.service > /dev/null &&
      echo '[Service]' | sudo tee -a /etc/systemd/system/titanagent.service > /dev/null &&
      echo "Environment=HTTP_PROXY=$proxy_url" | sudo tee -a /etc/systemd/system/titanagent.service > /dev/null &&
      echo "Environment=http_proxy=$proxy_url" | sudo tee -a /etc/systemd/system/titanagent.service > /dev/null &&
      echo "ExecStart=$INSTALL_DIR/agent --working-dir=$INSTALL_DIR --server-url=$TITAN_API --key=$titan_key" | sudo tee -a /etc/systemd/system/titanagent.service > /dev/null &&
      echo 'Restart=always' | sudo tee -a /etc/systemd/system/titanagent.service > /dev/null &&
      echo '' | sudo tee -a /etc/systemd/system/titanagent.service > /dev/null &&
      echo '[Install]' | sudo tee -a /etc/systemd/system/titanagent.service > /dev/null &&
      echo 'WantedBy=multi-user.target' | sudo tee -a /etc/systemd/system/titanagent.service > /dev/null &&
      sudo systemctl daemon-reexec &&
      sudo systemctl daemon-reload &&
      sudo systemctl enable titanagent &&
      sudo systemctl start titanagent
    "

    echo -e "${GREEN}✅ $name đã chạy Titan Agent.${NC}"
  done
}

# === XOÁ TẤT CẢ NODE ===
delete_all_nodes() {
  echo -e "${RED}🚨 Xóa tất cả các node Multipass...${NC}"
  all_nodes=$(multipass list --format csv | tail -n +2 | cut -d',' -f1 | grep '^titan-node-')

  if [ -z "$all_nodes" ]; then
    echo -e "${CYAN}📭 Không có node nào để xóa.${NC}"
    return
  fi

  for node in $all_nodes; do
    multipass delete "$node"
  done

  sleep 2
  multipass purge
  echo -e "${GREEN}✅ Đã xóa tất cả node.${NC}"
}

# === XEM DANH SÁCH NODE ===
list_nodes() {
  echo -e "${CYAN}📋 Danh sách node Multipass:${NC}"
  multipass list
}

# === TRUY CẬP VÀO NODE ===
access_node() {
  read -p "💻 Nhập tên node muốn vào (VD: titan-node-1): " node_name
  echo -e "${CYAN}🔁 Truy cập vào $node_name...${NC}"
  multipass shell "$node_name"
}

# === XOÁ NODE ===
delete_node() {
  read -p "🗑️ Nhập tên node muốn xoá (VD: titan-node-1): " node_name
  multipass delete "$node_name"
  sleep 2
  multipass purge
  echo -e "${GREEN}✅ Đã xoá node $node_name.${NC}"
}

# === Hướng dẫn tạo tài khoản Titan ===
guide_create_account() {
  echo -e "\n${CYAN}🔐 Hướng dẫn tạo tài khoản Titan:${NC}"
  echo -e "1. Truy cập link: ${GREEN}https://test4.titannet.io/Invitelogin?code=2zNL3u${NC}"
  echo -e "2. Đăng ký tài khoản và lấy key trong trang Dashboard"
}

# === MENU GIAO DIỆN ===
while true; do
  echo -e "\n${CYAN}========= TITAN MULTIPASS MANAGER =========${NC}"
  echo -e "1️⃣  Cài đặt & chuẩn bị môi trường"
  echo -e "2️⃣  Tạo node Titan bằng Multipass"
  echo -e "3️⃣  Xem danh sách node"
  echo -e "4️⃣  Truy cập vào node"
  echo -e "5️⃣  Xoá node"
  echo -e "6️⃣  Xoá tất cả node"
  echo -e "7️⃣  Hướng dẫn tạo tài khoản Titan"
  echo -e "0️⃣  Thoát"
  echo -e "${CYAN}===========================================${NC}"
  read -p "🔀 Chọn một tùy chọn (0-7): " choice

  case "$choice" in
    1) check_dependencies ;;
    2) create_nodes ;;
    3) list_nodes ;;
    4) access_node ;;
    5) delete_node ;;
    6) delete_all_nodes ;;
    7) guide_create_account ;;
    0) echo -e "${GREEN}👋 Tạm biệt!${NC}"; exit 0 ;;
    *) echo -e "${RED}❌ Lựa chọn không hợp lệ!${NC}" ;;
  esac

done
