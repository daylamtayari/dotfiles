# Networking Aliases

# General
alias myip="curl https://ipinfo.io/ip --silent"
alias speedtest="curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -"

# ifconfig
alias lip="ifconfig | grep -e 'eth0' -e 'enX0' -A1 | tail -n1 | awk '{print \$2}' | cut -f1  -d'/'"
alias vip="ifconfig | grep 'tun0' -A1 | tail -n1 | awk '{print \$2}' | cut -f1  -d'/'"
