#!/bin/bash

# === CONFIG ===
INSTALL_DIR="/opt/titanagent"
TITAN_URL="https://pcdn.titannet.io/test4/bin/agent-linux.zip"
TITAN_API="https://test4-api.titannet.io"

# === MÀU SẮC ===
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# === KIỂM TRA VÀ CÀI DOCKER ===
check_dependencies() {
  echo -e "${CYAN}🔍 Kiểm tra Docker...${NC}"
  if ! command -v docker >/dev/null 2>&1; then
    echo -e "${GREEN}⚙️ Cài đặt Docker...${NC}"
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    echo -e "${GREEN}✅ Đã cài Docker. Vui lòng logout/login lại để kích hoạt quyền docker.${NC}"
  else
    echo -e "${GREEN}✅ Docker đã được cài đặt.${NC}"
  fi
}

# === TẠO CONTAINER TITAN ===
create_nodes() {
  read -p "🔑 Nhập Titan Agent Key của bạn: " titan_key
  read -p "🔢 Nhập số lượng node muốn tạo: " node_count

  for i in $(seq 1 $node_count); do
    name="titan-node-$i"
    echo -e "\n${CYAN}🚀 Tạo container: $name...${NC}"

    docker rm -f $name 2>/dev/null

    docker run -d \
      --name $name \
      --restart unless-stopped \
      ubuntu:20.04 \
      bash -c "apt update && apt install -y wget unzip curl && \
      mkdir -p $INSTALL_DIR && cd $INSTALL_DIR && \
      wget -q $TITAN_URL && unzip -o agent-linux.zip && chmod +x agent && \
      while true; do ./agent --working-dir=$INSTALL_DIR --server-url=$TITAN_API --key=$titan_key; sleep 10; done"

    echo -e "${GREEN}✅ Container $name đang chạy Titan Agent.${NC}"
  done
}

# === XOÁ TẤT CẢ CONTAINER ===
delete_all_nodes() {
  echo -e "${RED}🚨 Xóa tất cả container Titan...${NC}"
  all_nodes=$(docker ps -a --format '{{.Names}}' | grep '^titan-node-')

  if [ -z "$all_nodes" ]; then
    echo -e "${CYAN}📝 Không có container nào để xóa.${NC}"
    return
  fi

  for node in $all_nodes; do
    echo -e "🛑 Dừng & xoá container: $node"
    docker rm -f "$node"
  done

  echo -e "${GREEN}✅ Đã xoá tất cả container Titan.${NC}"
}

# === XEM DANH SÁCH CONTAINER ===
list_nodes() {
  echo -e "${CYAN}📋 Danh sách container Titan:${NC}"
  docker ps -a --filter "name=titan-node-"
}

# === TRUY CẬP VÀO CONTAINER ===
access_node() {
  read -p "💻 Nhập tên container muốn vào (VD: titan-node-1): " node_name
  echo -e "${CYAN}♻️ Truy cập vào $node_name...${NC}"
  docker exec -it "$node_name" bash
}

# === XOÁ CONTAINER ===
delete_node() {
  read -p "🗑️ Nhập tên container muốn xoá (VD: titan-node-1): " node_name
  docker rm -f "$node_name"
  echo -e "${GREEN}✅ Đã xoá container $node_name.${NC}"
}

# === XEM LOG ĐANG CHẠY CỦA CONTAINER ===
view_node_logs() {
  read -p "📝 Nhập tên container để xem log (VD: titan-node-1): " node_name
  echo -e "${CYAN}📄 Log của Titan Agent trong $node_name:${NC}"
  docker logs "$node_name" --tail 30
}

# === MENU GIAO DIỆN ===
while true; do
  echo -e "\n${CYAN}========= TITAN DOCKER MANAGER =========${NC}"
  echo -e "1️⃣  Cài đặt Docker nếu chưa có"
  echo -e "2️⃣  Tạo container Titan"
  echo -e "3️⃣  Xem danh sách container"
  echo -e "4️⃣  Xem log Titan Agent của một container"
  echo -e "5️⃣  Xoá một container"
  echo -e "6️⃣  Xoá tất cả container"
  echo -e "0️⃣  Thoát"
  echo -e "${CYAN}========================================${NC}"
  read -p "🔀 Chọn một tùy chọn (0-6): " choice

  case "$choice" in
    1) check_dependencies ;;
    2) create_nodes ;;
    3) list_nodes ;;
    4) view_node_logs ;;
    5) delete_node ;;
    6) delete_all_nodes ;;
    0) echo -e "${GREEN}👋 Tạm biệt!${NC}"; exit 0 ;;
    *) echo -e "${RED}❌ Lựa chọn không hợp lệ!${NC}" ;;
  esac
done
