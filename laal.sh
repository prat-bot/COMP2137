# System Status
echo "System Status"
echo "-------------"
echo "Users Logged In: $(who | awk '{print $1}' | sort | uniq | tr '\n' ',' | sed 's/,$//')"
echo "Disk Space:"
df -h | awk '/^\/dev/ {print $6 " " $4}'
echo "Process Count: $(ps -e | wc -l)"
echo "Load Averages: $(uptime | awk -F'average: ' '{print $2}')"
echo "Listening Network Ports: $(ss -tuln | awk '/LISTEN/ {print $5}' | cut -d':' -f2 | sort -n | uniq)"
echo "UFW Status: $(sudo ufw status | grep -w "Status" | awk '{print $2}')"
echo
