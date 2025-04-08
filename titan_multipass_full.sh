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
      echo -e "${RED}⚠️ VM $name đã tồn tại, xóa và tạo lại...${NC}"
      multipass delete $name && multipass purge
    fi

    echo -e "\n${CYAN}🚀 Tạo VM: $name...${NC}"
    multipass launch $IMAGE --name $name --memory 2G --disk 10G --cpus 2

    echo -e "${CYAN}⏳ Chờ VM $name có IP...${NC}"
    while [ -z "$(multipass info $name | grep 'IPv4' | awk '{print $2}')" ]; do
      sleep 2
    done

    echo -e "${CYAN}⚙️ Cài Titan Agent trong $name...${NC}"
    multipass exec $name -- bash -c "
      sudo apt update && sudo apt install -y wget unzip curl
      sudo mkdir -p $INSTALL_DIR && cd $INSTALL_DIR
      sudo wget -q $TITAN_URL && sudo unzip -o agent-linux.zip && sudo chmod +x agent
      echo '[Unit]' | sudo tee /etc/systemd/system/titanagent.service > /dev/null
      echo 'Description=Titan Agent' | sudo tee -a /etc/systemd/system/titanagent.service > /dev/null
      echo 'After=network.target' | sudo tee -a /etc/systemd/system/titanagent.service > /dev/null
      echo '[Service]' | sudo tee -a /etc/systemd/system/titanagent.service > /dev/null
      echo "ExecStart=$INSTALL_DIR/agent --working-dir=$INSTALL_DIR --server-url=$TITAN_API --key=$titan_key" | sudo tee -a /etc/systemd/system/titanagent.service > /dev/null
      echo 'Restart=always' | sudo tee -a /etc/systemd/system/titanagent.service > /dev/null
      echo '[Install]' | sudo tee -a /etc/systemd/system/titanagent.service > /dev/null
      echo 'WantedBy=multi-user.target' | sudo tee -a /etc/systemd/system/titanagent.service > /dev/null
      sudo systemctl daemon-reexec && sudo systemctl daemon-reload
      sudo systemctl enable titanagent && sudo systemctl restart titanagent"

    echo -e "${GREEN}✅ $name đã chạy Titan Agent.${NC}"
  done
}

# === XOÁ TẤT CẢ NODE (KHÔNG GIỚI HẠN TÊN) ===
delete_all_nodes() {
  echo -e "${RED}🚨 Xóa tất cả các node Multipass...${NC}"
  if ! command -v multipass >/dev/null 2>&1; then
    echo -e "${RED}❌ multipass chưa được cài đặt.${NC}"
    return
  fi

  all_nodes=$(multipass list --format csv | tail -n +2 | cut -d',' -f1)

  if [ -z "$all_nodes" ]; then
    echo -e "${CYAN}📝 Không có node nào để xóa.${NC}"
    return
  fi

  failed_nodes=()

  for node in $all_nodes; do
    echo -e "🛑 Dừng node: $node"
    multipass stop "$node"
    sleep 2
    multipass stop "$node" 2>/dev/null
    echo -e "🗑️ Đang xoá node: $node"
    multipass delete "$node" || failed_nodes+=("$node")
  done

  sleep 2
  echo -e "${CYAN}🧹 Dọn dẹp disk ảo...${NC}"
  multipass purge

  if [ ${#failed_nodes[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ Đã xóa tất cả node và giải phóng tài nguyên.${NC}"
  else
    echo -e "${RED}⚠️ Không thể xoá các node sau:${NC}"
    for f in "${failed_nodes[@]}"; do
      echo " - $f"
    done
  fi
}

# === XEM DANH SÁCH NODE ===
list_nodes() {
  echo -e "${CYAN}📋 Danh sách node Multipass:${NC}"
  multipass list
}

# === TRUY CẬP VÀO NODE ===
access_node() {
  read -p "💻 Nhập tên node muốn vào (VD: titan-node-1): " node_name
  echo -e "${CYAN}♻️ Truy cập vào $node_name...${NC}"
  multipass shell "$node_name"
}

# === XOÁ NODE ===
delete_node() {
  read -p "🗑️ Nhập tên node muốn xoá (VD: titan-node-1): " node_name
  multipass stop "$node_name"
  multipass delete "$node_name"
  sleep 2
  echo -e "${CYAN}🧹 Dọn dẹp disk ảo...${NC}"
  multipass purge
  echo -e "${GREEN}✅ Đã xoá node $node_name và giải phóng tài nguyên.${NC}"
}

# === XEM LOG ĐANG CHẠY CỦA NODE ===
view_node_logs() {
  read -p "📝 Nhập tên node để xem log (VD: titan-node-1): " node_name
  echo -e "${CYAN}📄 Log của Titan Agent trong $node_name:${NC}"
  multipass exec "$node_name" -- journalctl -u titanagent --no-pager -n 30
}

# === MENU GIAO DIỆN ===
while true; do
  echo -e "\n${CYAN}========= TITAN MULTIPASS MANAGER =========${NC}"
  echo -e "1️⃣  Cài đặt & chuẩn bị môi trường"
  echo -e "2️⃣  Tạo node Titan bằng Multipass"
  echo -e "3️⃣  Xem danh sách node"
  echo -e "4️⃣  Xem log Titan Agent của một node"
  echo -e "5️⃣  Xoá node"
  echo -e "6️⃣  Xoá tất cả node"
  echo -e "0️⃣  Thoát"
  echo -e "${CYAN}===========================================${NC}"
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
