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

# === KIỂM TRA & CÀI SNAP + MULTIPASS ===
check_dependencies() {
  echo -e "${CYAN}🔍 Kiểm tra Snap & Multipass...${NC}"
  if ! command -v snap >/dev/null 2>&1; then
    echo -e "${GREEN}⚙️ Cài Snap...${NC}"
    sudo apt update && sudo apt install -y snapd
    sudo systemctl enable --now snapd.socket
  fi
  if ! command -v multipass >/dev/null 2>&1; then
    echo -e "${GREEN}⚙️ Cài Multipass...${NC}"
    sudo snap install multipass
  fi
  echo -e "${GREEN}✅ Snap & Multipass đã sẵn sàng.${NC}"
}

# === TẠO NODE TITAN ===
create_nodes() {
  read -p "🔑 Nhập Titan Agent Key: " titan_key
  read -p "🔢 Số lượng node: " node_count
  for i in $(seq 1 $node_count); do
    name="titan-node-$i"
    if multipass info $name >/dev/null 2>&1; then
      echo -e "${RED}⚠️ VM $name đã tồn tại, xoá và tạo lại...${NC}"
      multipass delete $name && multipass purge
    fi
    read -p "🌐 Nhập proxy cho $name (http://user:pass@ip:port): " proxy_url
    echo -e "${CYAN}🚀 Đang tạo VM $name...${NC}"
    multipass launch $IMAGE --name $name --memory 2G --disk 10G --cpus 2

    echo -e "${CYAN}⚙️ Thiết lập proxy và cài Titan Agent...${NC}"
    multipass exec $name -- bash -c "
      echo 'export http_proxy=$proxy_url' | sudo tee -a /etc/environment /etc/profile.d/proxy.sh
      echo 'export https_proxy=$proxy_url' | sudo tee -a /etc/environment /etc/profile.d/proxy.sh
      echo 'export HTTP_PROXY=$proxy_url' | sudo tee -a /etc/environment /etc/profile.d/proxy.sh
      echo 'export HTTPS_PROXY=$proxy_url' | sudo tee -a /etc/environment /etc/profile.d/proxy.sh
      echo 'export no_proxy=localhost,127.0.0.1' | sudo tee -a /etc/environment /etc/profile.d/proxy.sh
      echo 'export NO_PROXY=localhost,127.0.0.1' | sudo tee -a /etc/environment /etc/profile.d/proxy.sh

      echo 'Acquire::http::Proxy \"$proxy_url\";' | sudo tee /etc/apt/apt.conf.d/01proxy
      echo 'Acquire::https::Proxy \"$proxy_url\";' | sudo tee -a /etc/apt/apt.conf.d/01proxy

      source /etc/environment
      sudo apt update && sudo apt install -y wget unzip curl

      sudo mkdir -p $INSTALL_DIR && cd $INSTALL_DIR
      sudo wget -q $TITAN_URL && sudo unzip -o agent-linux.zip && sudo chmod +x agent

      echo '[Unit]' | sudo tee /etc/systemd/system/titanagent.service
      echo 'Description=Titan Agent' | sudo tee -a /etc/systemd/system/titanagent.service
      echo 'After=network.target' | sudo tee -a /etc/systemd/system/titanagent.service
      echo '[Service]' | sudo tee -a /etc/systemd/system/titanagent.service
      echo 'Environment=\"HTTP_PROXY=$proxy_url\"' | sudo tee -a /etc/systemd/system/titanagent.service
      echo 'Environment=\"HTTPS_PROXY=$proxy_url\"' | sudo tee -a /etc/systemd/system/titanagent.service
      echo 'Environment=\"NO_PROXY=localhost,127.0.0.1\"' | sudo tee -a /etc/systemd/system/titanagent.service
      echo 'ExecStart=/usr/bin/env -S http_proxy=$proxy_url https_proxy=$proxy_url $INSTALL_DIR/agent --working-dir=$INSTALL_DIR --server-url=$TITAN_API --key=$titan_key' | sudo tee -a /etc/systemd/system/titanagent.service
      echo 'Restart=always' | sudo tee -a /etc/systemd/system/titanagent.service
      echo '[Install]' | sudo tee -a /etc/systemd/system/titanagent.service
      echo 'WantedBy=multi-user.target' | sudo tee -a /etc/systemd/system/titanagent.service

      sudo systemctl daemon-reexec
      sudo systemctl daemon-reload
      sudo systemctl enable titanagent
      sudo systemctl restart titanagent
    "

    echo -e "${CYAN}🌍 Kiểm tra IP public của $name (qua proxy)...${NC}"
    multipass exec $name -- curl -s ifconfig.me

    echo -e "${GREEN}✅ $name đã cài đặt Titan Agent qua proxy!${NC}"
  done
}

# === XOÁ TẤT CẢ NODE ===
delete_all_nodes() {
  echo -e "${RED}🚨 Xoá tất cả node...${NC}"
  all_nodes=$(multipass list --format csv | tail -n +2 | cut -d',' -f1 | grep '^titan-node-')
  for node in $all_nodes; do
    multipass delete "$node"
  done
  multipass purge
  echo -e "${GREEN}✅ Đã xoá toàn bộ node.${NC}"
}

# === TRUY CẬP NODE ===
access_node() {
  read -p "🔎 Tên node muốn truy cập: " node
  multipass shell "$node"
}

# === DANH SÁCH NODE ===
list_nodes() {
  echo -e "${CYAN}📋 Danh sách node:${NC}"
  multipass list
}

# === XEM TRẠNG THÁI AGENT ===
check_status_all_nodes() {
  echo -e "${CYAN}📡 Trạng thái Titan Agent:${NC}"
  all_nodes=$(multipass list --format csv | tail -n +2 | cut -d',' -f1 | grep '^titan-node-')
  for node in $all_nodes; do
    echo -e "\n🔹 $node:"
    multipass exec "$node" -- systemctl status titanagent --no-pager | head -n 10
  done
}

# === MENU ===
while true; do
  echo -e "\n${CYAN}========= TITAN MULTIPASS MANAGER =========${NC}"
  echo "1️⃣  Cài đặt môi trường"
  echo "2️⃣  Tạo node Titan (có proxy)"
  echo "3️⃣  Danh sách node"
  echo "4️⃣  Truy cập node"
  echo "5️⃣  Xoá tất cả node"
  echo "6️⃣  Trạng thái agent"
  echo "0️⃣  Thoát"
  read -p "🔢 Chọn (0-6): " choice
  case "$choice" in
    1) check_dependencies ;;
    2) create_nodes ;;
    3) list_nodes ;;
    4) access_node ;;
    5) delete_all_nodes ;;
    6) check_status_all_nodes ;;
    0) echo -e "${GREEN}👋 Thoát.${NC}"; exit 0 ;;
    *) echo -e "${RED}❌ Lựa chọn không hợp lệ.${NC}" ;;
  esac
done
