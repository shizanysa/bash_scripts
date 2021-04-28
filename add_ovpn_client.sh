#For add openvpn clients and static ip for clients
#Example
#./add_ovpn_client.sh clientname

#!/bin/bash
openvpn_easy_rsa=/etc/openvpn/easy-rsa
login=$1
OUT=/etc/openvpn/client/$login.ovpn

if [ -z "$1" ]; then
  echo "Please supplie client name"
  exit 1;
fi

echo -e "--- GENERATE CLIENT IP ------------------"
LAST_IP=$(cat ccd/* |awk '{print $2}'|sort -t . -k 3,3n -k 4,4n|tail -1)
echo -e "--- $LAST_IP is last ip now ---"
IP_LAST_OCT=${LAST_IP##*.}
NEW_IP_LAST_OCT=$(expr ${LAST_IP##*.} + 4)
NET=${LAST_IP%.*}
NEW_GW_LAST_OCT=$(expr ${LAST_IP##*.} + 3)
NEW_IP=$NET.$NEW_IP_LAST_OCT
NEW_GW=$NET.$NEW_GW_LAST_OCT

echo -e "--- Check $NEW_IP ------------------"

if [ "$(grep $NEW_IP -r /etc/openvpn/ccd/)" ]; then
  echo "ip $NEW_IP is already exist"
  exit 1
else 
  echo "ip $NEW_IP is free";
  echo -e "---------------------------------------"
  echo -e "--- Add static ip for client $login ---"

  echo -e "ifconfig-push $NEW_IP $NEW_GW" > /etc/openvpn/ccd/$login

  echo -e "---------------------------------------"
  echo -e "-------------- Done -------------------"

  cd /etc/openvpn/easy-rsa/
  if [ ! -f "/etc/openvpn/easy-rsa/keys/$login.crt" ]; then
    source /etc/openvpn/easy-rsa/vars && cd /etc/openvpn/easy-rsa/ && KEY_CN="$login" KEY_EMAIL="email@example" $openvpn_easy_rsa/pkitool

  echo "client
  dev tun
  proto udp
  remote server_ip 1194
  resolv-retry infinite
  nobind
  persist-key
  persist-tun
  
  script-security 2
  dhcp-option DNS 10.0.0.1
  dhcp-option DOMAIN server.example.com
  compress lzo
  verb 3
  <ca>
  $(cat /etc/openvpn/easy-rsa/keys/ca.crt)
  </ca>
  <cert>
  $(cat /etc/openvpn/easy-rsa/keys/$login.crt)
  </cert>
  <key>
  $(cat /etc/openvpn/easy-rsa/keys/$login.key)
  </key>" >> $OUT
  
    echo -e "---------------------------------------"
    echo -e "-------------- Done -------------------"
    echo -e "--- Client's ip is $NEW_IP "
  
    echo -e "Bye-bye"

  else
    exit 1  
  fi
fi
