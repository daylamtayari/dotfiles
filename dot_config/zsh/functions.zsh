# Functions

function ndir() {
    mkdir -p $1; cd $1
}

function calcpps() {
  ips=$1
  ports=$2
  hours=$3
  total_scans=$((ips*ports))
  total_seconds=$((hours*3600))

  if [ $# -eq 3 ]; then
    pps=$(echo "scale=2; $total_scans / $total_seconds" | bc)
    echo "[*] Recommended to not exceed 5,000 pps for large scopes and 1,000 packets for smaller scopes"
    echo "[*] Taking the IP addresses, ports, and time available, recommended pps is:"
    echo "[+] Approximate packets per second (pps) SYN scans: $((pps * 2))"
    echo "[+] Approximate packets per second (pps) CONNECT scans: $((pps * 3))"
  elif [ $# -eq 2 ]; then
    pinnedppsminutes=$((total_scans / (1000 * 60)))
    pinnedppshours=$((total_scans / (1000 * 3600)))
    echo "[+] With 1000 pps the provided IPs and ports would take: approximately $pinnedppshours hour and $pinnedppsminutes minutes with no retries"
    echo "naabu has 3 retries by default and nmap -T4 has 6 retries."
  else
    echo "calcpps takes arg1 as IPs to scan, arg2 as amount of ports, a blank or arg3 or amount of time in hours to get a packets per second rate"
  fi
}
