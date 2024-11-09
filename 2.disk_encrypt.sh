#https://github.com/johnshearing/MyEtherWalletOffline/blob/master/Air-Gap_Setup.md#setup-luks-full-disk-encryption
#https://robpol86.com/raspberry_pi_luks.html
#https://www.howtoforge.com/automatically-unlock-luks-encrypted-drives-with-a-keyfile

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Install necessary packages
apt-get install busybox cryptsetup initramfs-tools -y
apt-get install cryptsetup-initramfs -y
apt-get install expect --no-install-recommends -y

# Copy custom hooks and rebuild initramfs
cp /boot/install/initramfs-rebuild /etc/kernel/postinst.d/initramfs-rebuild
cp /boot/install/resize2fs /etc/initramfs-tools/hooks/resize2fs
chmod +x /etc/kernel/postinst.d/initramfs-rebuild
chmod +x /etc/initramfs-tools/hooks/resize2fs

echo 'CRYPTSETUP=y' | tee --append /etc/cryptsetup-initramfs/conf-hook > /dev/null
mkinitramfs -o /boot/firmware/initramfs.gz

lsinitramfs /boot/firmware/initramfs.gz | grep -P "sbin/(cryptsetup|resize2fs|fdisk|dumpe2fs|expect)"

echo 'initramfs initramfs.gz followkernel' | tee --append /boot/firmware/config.txt > /dev/null

sed -i '$s/$/ cryptdevice=\/dev\/mmcblk0p2:sdcard/' /boot/firmware/cmdline.txt

ROOT_CMD="$(sed -n 's|^.*root=\(\S\+\)\s.*|\1|p' /boot/firmware/cmdline.txt)"
sed -i -e "s|$ROOT_CMD|/dev/mapper/sdcard|g" /boot/firmware/cmdline.txt

FSTAB_CMD="$(blkid | sed -n '/dev\/mmcblk0p2/s/.*\ PARTUUID=\"\([^\"]*\)\".*/\1/p')"
sed -i -e "s|PARTUUID=$FSTAB_CMD|/dev/mapper/sdcard|g" /etc/fstab

echo 'sdcard /dev/mmcblk0p2 none luks' | tee --append /etc/crypttab > /dev/null

echo "Done. Reboot with: sudo reboot"
