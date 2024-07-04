#!/bin/bash

#wget https://raw.githubusercontent.com/maemune/Unix/main/UbuntuContainer_init.sh && nano ./UbuntuContainer_init.sh && chmod u+x ./UbuntuContainer_init.sh && ./UbuntuContainer_init.sh

# Setting you info
GITHUB_KEYS_URL="https://github.com/maemune.keys"
PASSWORD=""

# Update
#sudo perl -p -i.bak -e 's%(deb(?:-src|)\s+)https?://(?!archive\.canonical\.com|security\.ubuntu\.com)[^\s]+%$1http://ftp.riken.jp/Linux/ubuntu/%' /etc/apt/sources.list
# 24.04
#sudo sed -i.bak -r 's@http://(jp\.)?archive\.ubuntu\.com/ubuntu/?@https://ftp.udx.icscoe.jp/Linux/ubuntu/@g' /etc/apt/sources.list.d/ubuntu.sources
apt-get update
apt -y install openssh-server curl unzip qemu-guest-agent

# Timezone Setup
timedatectl set-timezone Asia/Tokyo

# noPasswd ubuntu
echo 'ubuntu ALL=NOPASSWD: ALL' | EDITOR='tee -a' visudo

# Firewall Allow
ufw allow 22
echo 'y' | ufw enable

# SSH Setup
SSH_CONFIG="/etc/ssh/sshd_config"
SSH_CONFIG_BACKUP="/etc/ssh/sshd_config.bk"
SSH_PORT_NUMBER="22"

function change_setting () {
  TARGET=$1
  KEYWORD=$2
  VALUE=$3

  EXIST=`grep "^${KEYWORD}" ${TARGET}`
  EXIST_COMMENT=`grep "^#${KEYWORD}" ${TARGET}`

  if [ ${#EXIST} -ne 0 ]; then
    sed -i '/^'${KEYWORD}'/c '${KEYWORD}' '${VALUE}'' ${TARGET}
  elif [ ${#EXIST_PERMIT_COMMENT} -ne 0 ]; then
    sed -i '/^#'${KEYWORD}'/c '${KEYWORD}' '${VALUE}'' ${TARGET} 
  else
    echo -e "${KEYWORD} ${VALUE}" >> ${TARGET}
  fi
}
if [ -f ${SSH_CONFIG_BACKUP} ]; then
  echo "SSH setting is already done."
else
  cp -i ${SSH_CONFIG} ${SSH_CONFIG_BACKUP}
  
  # Port
  change_setting ${SSH_CONFIG} Port ${SSH_PORT_NUMBER}
  grep "^Port" ${SSH_CONFIG}
  
  # PermitRootLogin
  change_setting ${SSH_CONFIG} PermitRootLogin no
  grep "^PermitRootLogin" ${SSH_CONFIG}

  # PasswordAuthentication
  change_setting ${SSH_CONFIG} PasswordAuthentication no
  grep "^PasswordAuthentication" ${SSH_CONFIG}

  # ChallengeResponseAuthentication
  change_setting ${SSH_CONFIG} ChallengeResponseAuthentication no
  grep "^ChallengeResponseAuthentication" ${SSH_CONFIG}

  # PermitEmptyPasswords
  change_setting ${SSH_CONFIG} PermitEmptyPasswords no
  grep "^PermitEmptyPasswords" ${SSH_CONFIG}

  # SyslogFacility
  change_setting ${SSH_CONFIG} SyslogFacility AUTHPRIV
  grep "^SyslogFacility" ${SSH_CONFIG}

  # LogLevel
  change_setting ${SSH_CONFIG} LogLevel VERBOSE
  grep "^LogLevel" ${SSH_CONFIG}

  # TCP Port Forwarding
  #change_setting ${SSH_CONFIG} AllowTcpForwarding no
  #grep "^AllowTcpForwarding" ${SSH_CONFIG}

  # AllowStreamLocalForwarding
  #change_setting ${SSH_CONFIG} AllowStreamLocalForwarding no
  #grep "^AllowStreamLocalForwarding" ${SSH_CONFIG}

  # GatewayPorts
  #change_setting ${SSH_CONFIG} GatewayPorts no
  #grep "^GatewayPorts" ${SSH_CONFIG}

  # PermitTunnel
  #change_setting ${SSH_CONFIG} PermitTunnel no
  #grep "^PermitTunnel" ${SSH_CONFIG}
fi

# UserCreate
adduser -q --gecos "" --disabled-password ubuntu
usermod -aG sudo ubuntu
echo -e "${PASSWORD}\n${PASSWORD}\n" | passwd ubuntu

# User SSH Setup
mkdir -p /home/ubuntu/.ssh
curl ${GITHUB_KEYS_URL} > /home/ubuntu/.ssh/authorized_keys
chmod 755 /home/ubuntu/.ssh
chown -R ubuntu:ubuntu /home/ubuntu/
chmod 600 /home/ubuntu/.ssh/authorized_keys
systemctl restart sshd.service

su ubuntu
crontab -l > {tmpfile}
echo "*/5 * * * * curl ${GITHUB_KEYS_URL} > /home/ubuntu/.ssh/authorized_keys && chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys && chmod 600 /home/ubuntu/.ssh/authorized_keys
0 3 */2 * * /home/ubuntu/Update.sh" >> {tmpfile}
crontab {tmpfile}
rm {tmpfile}
exit

echo '#!/bin/bash
apt-get update
apt -y full-upgrade
apt -y autoremove
' > /home/ubuntu/Ubuntu_Update.sh && chmod u+x /home/ubuntu/Ubuntu_Update.sh && /home/ubuntu/Ubuntu_Update.sh

lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv

# Logout
reboot now
