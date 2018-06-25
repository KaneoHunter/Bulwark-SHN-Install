#!/usr/bin/env sh

read -e -s -p "Please enter your Bulwark wallet password : " PASSWORD

OUTCOME=bulwark-cli walletpassphrase ${PASSWORD} 99999999 true

clear

echo "${OUTCOME}"

unset PASSWORD OUTCOME

cat /dev/null > ~/.bash_history && history -c
