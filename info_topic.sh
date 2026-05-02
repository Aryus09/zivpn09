#!/bin/bash

TOKEN="8543854114:AAG3yHrbR42ao8LMc-LzNlK4M356j8dcsMY"
CHAT_ID="-1003370284743"
THREAD_ID="7805"

HOST=$(hostname)
IP=$(curl -s ifconfig.me)
DATE=$(date)

# ================= ISP =================
ISP=$(curl -s http://ip-api.com/json/$IP | jq -r '.isp // "N/A"')
ORG=$(curl -s http://ip-api.com/json/$IP | jq -r '.org // "N/A"')

# ================= SPEEDTEST =================


# ================= CPU =================
CPU_USAGE=$(top -bn1 | awk -F',' '/Cpu/ {print 100 - $4}' | awk '{printf("%.0f"), $1}')
CPU_CORES=$(nproc)
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | xargs)

# ================= RAM =================
RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
RAM_PERCENT=$(free | awk '/Mem:/ {printf("%.0f"), $3/$2 * 100.0}')

# ================= DISK =================
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}')



# ================= NETWORK MONITOR (FIX FINAL) =================
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
[ -z "$INTERFACE" ] && INTERFACE="eth0"

RX_START=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
TX_START=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)

sleep 5

RX_END=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
TX_END=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)

# hitung selisih
RX_DIFF=$((RX_END - RX_START))
TX_DIFF=$((TX_END - TX_START))

# anti minus
[ $RX_DIFF -lt 0 ] && RX_DIFF=0
[ $TX_DIFF -lt 0 ] && TX_DIFF=0

# convert ke Mbps
RX_AVG=$(echo "scale=2; $RX_DIFF * 8 / 5 / 1000000" | bc)
TX_AVG=$(echo "scale=2; $TX_DIFF * 8 / 5 / 1000000" | bc)

# total traffic
RX_TOTAL=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
TX_TOTAL=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)

RX_TOTAL_GB=$(echo "scale=2; $RX_TOTAL / 1024 / 1024 / 1024" | bc)
TX_TOTAL_GB=$(echo "scale=2; $TX_TOTAL / 1024 / 1024 / 1024" | bc)
RX_AVG=${RX_AVG:-0}
TX_AVG=${TX_AVG:-0}


# ================= MESSAGE =================
MESSAGE="🚀 *LAPORAN VPS*

🖥 Server : $HOST
🌍 IP : $IP
🏢 ISP : $ISP
🏛 Org : $ORG
📅 $DATE

📊 *NETWORK (5s AVG)*
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
