#!/bin/bash

# Make sure curl is installed
apt -qqy install curl
clear

#Ensure bulwarkd is active
  if systemctl is-active --quiet bulwarkd; then
  	sudo systemctl start bulwarkd
fi
echo "Setting Up Staking Address.."

#Simple check to make sure the bulwarkd sync process is finished, so it isn't interrupted and forced to start over later.'
echo "Checking Bulwarkd status. The script will begin setting up staking once bulwarkd has finished syncing. Please allow this process to finish."
until su -c "bulwark-cli mnsync status 2>/dev/null | grep '\"IsBlockchainSynced\" : true' > /dev/null" $USER; do
  echo -ne "Current block: "`su -c "bulwark-cli getinfo" $USER | grep blocks | awk '{print $3}' | cut -d ',' -f 1`'\r'
  sleep 1
done

#Ensure the .conf exists
touch $HOME/.bulwark/bulwark.conf

#If the line does not already exist, adds a line to bulwark.conf to instruct the wallet to stake

sed 's/staking=0/staking=1/' <$HOME/.bulwark/bulwark.conf

if grep -Fxq "staking=1" $HOME/.bulwark/bulwark.conf; then
  	echo "Staking Already Active"
  else
  	echo "staking=1" >> $HOME/.bulwark/bulwark.conf
fi

#Generates new address and assigns it a variable
STAKINGADDRESS=$(bulwark-cli getnewaddress)

#Ask for a password and apply it to a variable and confirm it.
ENCRYPTIONKEY=1
ENCRYPTIONKEYCONF=2
until [ $ENCRYPTIONKEY = $ENCRYPTIONKEYCONF ]; do
	read -e -s -p "Please enter a password to encrypt your new staking address/wallet with, you will not see what you type appear. (KEEP THIS SAFE, THIS CANNOT BE RECOVERED) : " ENCRYPTIONKEY
	read -e -s -p "Please confirm your password : " ENCRYPTIONKEYCONF
		if [ $ENCRYPTIONKEY != $ENCRYPTIONKEYCONF ]; then
			echo "Your passwords do not match, please try again."
		else
			echo "Password set."
		fi
done


#Encrypt the new address with the requested password
BIP38=$(bulwark-cli bip38encrypt $STAKINGADDRESS $ENCRYPTIONKEY)
echo "Address successfully encrypted!"

#Encrypt the wallet with the same password
bulwark-cli encryptwallet $ENCRYPTIONKEY && echo "Wallet successfully encrypted!" || { echo "Encryption failed!"; exit; }

#Wait for bulwarkd to close down after wallet encryption
echo "Waiting for bulwarkd to restart..."
until  ! systemctl is-active --quiet bulwarkd; do
    sleep 0.5
done

#Open up bulwarkd again
sudo systemctl start bulwarkd

#Unlocks the wallet for a long time period
bulwark-cli walletpassphrase $ENCRYPTIONKEY 9999999999 true

#Make decrypt script
sudo curl https://raw.githubusercontent.com/KaneoHunter/shn/master/decrypt.sh > /usr/local/bin/decrypt.sh
sudo chown $USER:$USER /usr/local/bin/decrypt.sh
sudo chmod 700 /usr/local/bin/decrypt.sh


#Output more
cat << EOL
Your wallet has now been set up for staking, please send the coins you wish to
stake to ${STAKINGADDRESS}. Once your wallet is synced your coins should begin
staking automatically.

To check on the status of your staked coins you can run
"bulwark-cli getstakingstatus" and "bulwark-cli getinfo".

You can import the private key for this address in to your QT wallet using
the BIP38 tool under settings, just enter the information below with the
password you chose at the start. We recommend you take note of the following
lines to assist with recovery if ever needed.

${BIP38}

If your bulwarkd restarts, and you need to unlock your wallet again, use
the included script by running "decrypt.sh" to unlock your
wallet securely.

After the installation script ends, we will wipe all history and have no
storage record of your password, encrypted key, or addresses.
Any funds you lose access to are your own responsibility and the Bulwark team
will be unable to assist with their recovery. We therefore suggesting saving a
physical copy of this information.

If you have any concerns, we encourage you to contact us via any of our
social media channels.

EOL

read -e -p "Please confirm you have written down your password and encrypted key somewhere
safe by typing \"I have read the above and agree\" : " CONFIRMATION

until [  "$CONFIRMATION" = "I have read the above and agree"  ]; do
  if [  "$CONFIRMATION" != "I have read the above and agree"  ]; then
    read -e -p "Please confirm you have written down your password and encrypted key somewhere
    safe by typing \"I have read the above and agree\" : " CONFIRMATION

echo "Thank you for setting up staking, now finishing setup.."

unset CONFIRMATION ENCRYPTIONKEYCONF ENCRYPTIONKEY BIP38 STAKINGADDRESS

cat /dev/null > $HOME/.bash_history && history -c

clear

echo "Staking operational."
