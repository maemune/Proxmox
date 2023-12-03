#!/bin/bash
#wget https://raw.githubusercontent.com/maemune/Proxmox/main/init-setup.sh && nano ./init-setup.sh && chmod u+x ./init-setup.sh && ./init-setup.sh

echo '#!/bin/bash
apt-get update
apt -y full-upgrade
apt -y autoremove
' > /root/Update.sh && chmod u+x /root/Update.sh

crontab -l > {tmpfile}
echo "0 */12 * * * /root/Update.sh" >> {tmpfile}
crontab {tmpfile}
rm {tmpfile}

/root/Update.sh
cp /etc/default/grub /etc/default/grub.AutoBackup
sed -i -e 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on"/g' /etc/default/grub
update-grub

reboot now
