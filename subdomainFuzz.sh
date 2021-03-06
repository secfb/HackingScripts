#!/bin/bash

if [ $# -lt 1 ]; then
  echo "Invalid usage: $0 <domain>"
  exit
fi

DOMAIN=$1
PROTOCOL="http"

if [[ $DOMAIN = "https://*" ]]; then
   PROTOCOL="https"
fi

DOMAIN=$(echo $DOMAIN | sed -e 's|^[^/]*//||' -e 's|/.*$||')

echo "[ ] Resolving IP-Address…"
output=$(resolveip $DOMAIN 2>&1)
status=$(echo $?)
if ! [[ $status == 0 ]] ; then
  echo "[-] ${output}"
  exit
fi

IP_ADDRESS=$(echo $output | head -n 1 |  awk '{print $NF}')
echo "[+] IP-Address: ${IP_ADDRESS}"

echo "[ ] Retrieving default site…"
charcount=$(curl -s -L "${PROTOCOL}://${DOMAIN}" -k | wc -m)
echo "[+] Chars: ${charcount}"
echo "[ ] Fuzzing…"

ffuf --fs ${charcount} --fc 400,500 \
  -w /usr/share/wordlists/SecLists/Discovery/Web-Content/raft-large-words-lowercase.txt \
  -u "${PROTOCOL}://${IP_ADDRESS}" -H "Host: FUZZ.${DOMAIN}"
