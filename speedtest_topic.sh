#!/bin/bash

TOKEN="8543854114:AAG3yHrbR42ao8LMc-LzNlK4M356j8dcsMY"
CHAT_ID="-1003370284743"
THREAD_ID="7805"

HOST=$(hostname)
IP=$(curl -s ifconfig.me)
DATE=$(date)

# ================= ISP =================
ISP=$(curl -s http://ip-api.com/json/$IP | jq -r '.isp')
ORG=$(curl -s http://ip-api.com/json/$IP | jq -r '.org')

# ================= SPEEDTEST =================
RESULT=$(speedtest --accept-license --accept-gdpr -f json 2>/dev/null)

if echo "$RESULT" | grep -q "ping"; then
  PING=$(echo "$RESULT" | jq -r '.ping.latency')
  DOWNLOAD=$(echo "$RESULT" | jq -r '.download.bandwidth')
  UPLOAD=$(echo "$RESULT" | jq -r '.upload.bandwidth')

  DOWNLOAD_Mbps=$(echo "scale=2; $DOWNLOAD * 8 / 1000000" | bc)
  UPLOAD_Mbps=$(echo "scale=2; $UPLOAD * 8 / 1000000" | bc)
else
  PING="0"
  DOWNLOAD_Mbps="0"
  UPLOAD_Mbps="0"
fi

# ================= CPU =================
CPU_USAGE=$(top -bn1 | awk -F',' '/Cpu/ {print 100 - $4}' | awk '{printf("%.0f"), $1}')
CPU_CORES=$(nproc)
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}')

# ================= RAM =================
RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
RAM_PERCENT=$(free | awk '/Mem:/ {printf("%.0f"), $3/$2 * 100.0}')

# ================= DISK =================
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}')

# ================= NLOAD STYLE =================
INTERFACE=$(ip -o -4 route show to default | awk '{print $5}' | head -n1)

RX_TOTAL_BYTES=$(cat /proc/net/dev | awk -v iface="$INTERFACE" '$0 ~ iface {print $2}')
TX_TOTAL_BYTES=$(cat /proc/net/dev | awk -v iface="$INTERFACE" '$0 ~ iface {print $10}')

RX_START=$RX_TOTAL_BYTES
TX_START=$TX_TOTAL_BYTES

sleep 5

RX_END=$(cat /proc/net/dev | awk -v iface="$INTERFACE" '$0 ~ iface {print $2}')
TX_END=$(cat /proc/net/dev | awk -v iface="$INTERFACE" '$0 ~ iface {print $10}')

RX_AVG=$(echo "scale=2; ($RX_END - $RX_START) * 8 / 5 / 1000000" | bc)
TX_AVG=$(echo "scale=2; ($TX_END - $TX_START) * 8 / 5 / 1000000" | bc)

RX_TOTAL_GB=$(echo "scale=2; $RX_TOTAL_BYTES / 1024 / 1024 / 1024" | bc)
TX_TOTAL_GB=$(echo "scale=2; $TX_TOTAL_BYTES / 1024 / 1024 / 1024" | bc)

# ================= MESSAGE =================

MESSAGE="🚀 *LAPORAN VPS*

🖥 Server : $HOST
🌍 IP : $IP
🏢 ISP : $ISP
🏛 Org : $ORG
📅 $DATE

📡 *SPEEDTEST*
Ping      : ${PING} ms
Download  : ${DOWNLOAD_Mbps} Mbps
Upload    : ${UPLOAD_Mbps} Mbps

📊 *NLOAD MONITOR (5s AVG)*
AVG RX    : ${RX_AVG} Mbps
AVG TX    : ${TX_AVG} Mbps
Total RX  : ${RX_TOTAL_GB} GB
Total TX  : ${TX_TOTAL_GB} GB

⚙ *SYSTEM*
CPU Usage : ${CPU_USAGE}%
CPU Core  : ${CPU_CORES} Core
Load Avg  : ${LOAD_AVG}
RAM       : ${RAM_USED}MB / ${RAM_TOTAL}MB (${RAM_PERCENT}%)
Disk Root : ${DISK_USAGE}"

curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
-d chat_id="$CHAT_ID" \
-d message_thread_id="$THREAD_ID" \
-d text="$MESSAGE" \
-d parse_mode="Markdown"
