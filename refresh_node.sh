#!/bin/bash

BOOTSTRAPURL="https://github.com/bulwark-crypto/Bulwark/releases/download/1.3.0/bootstrap.dat.xz"
BOOTSTRAPARCHIVE="bootstrap.dat.xz"

clear
echo "This script will refresh your masternode."
read -p "Press Ctrl-C to abort or any other key to continue. " -n1 -s
clear

sudo systemctl stop bulwarkd

echo "Refreshing node, please wait."

sleep 5

sudo rm -Rf /home/bulwark/.bulwark/blocks
sudo rm -Rf /home/bulwark/.bulwark/database
sudo rm -Rf /home/bulwark/.bulwark/chainstate
sudo rm -Rf /home/bulwark/.bulwark/peers.dat

sudo cp /home/bulwark/.bulwark/bulwark.conf /home/bulwark/.bulwark/bulwark.conf.backup
sudo sed -i '/^addnode/d' /home/bulwark/.bulwark/bulwark.conf

echo "Installing bootstrap file..."
wget $BOOTSTRAPURL && xz -cd $BOOTSTRAPARCHIVE > /home/bulwark/.bulwark/bootstrap.dat && rm $BOOTSTRAPARCHIVE

sudo systemctl start bulwarkd

clear

echo "Your masternode is syncing. Please wait for this process to finish."
echo "This can take up to a few hours. Do not close this window." && echo ""

until [ -n "$(bulwark-cli getconnectioncount 2>/dev/null)"  ]; do
  sleep 1
done

until su -c "bulwark-cli mnsync status 2>/dev/null | grep '\"IsBlockchainSynced\" : true' > /dev/null" bulwark; do
  echo -ne "Current block: "`su -c "bulwark-cli getinfo" bulwark | grep blocks | awk '{print $3}' | cut -d ',' -f 1`'\r'
  sleep 1
done

clear

cat << EOL

Now, you need to start your masternode. Please go to your desktop wallet and
enter the following line into your debug console:

startmasternode alias false <mymnalias>

where <mymnalias> is the name of your masternode alias (without brackets)

EOL

read -p "Press Enter to continue after you've done that. " -n1 -s

clear

sleep 1
bulwark-cli startmasternode local false
sleep 1
clear
bulwark-cli masternode status
sleep 5

echo "" && echo "Masternode refresh completed." && echo ""
