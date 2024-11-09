This tutorial was adapted from https://github.com/F1LT3R/luks-encrypt-raspberry-pi/
It is adapted to be compatible with Debian 12 (Bookworm).

# LUKS Encrypt Raspberry PI (Debian Bookworm)

## What You Will Need

1. Raspberry PI
2. SDCard w/ Raspberry PI OS Lite installed
3. Flash drive connected to the RPI (to copy data from root partition during encrypt)
4. Bash scripts of this repository

## Install OS and Update Kernel

1. Burn the Raspberry PI OS to the SDCard w/ `Balenar Etcher` or `Raspberry PI Imager`

2. Copy install scripts into `/boot/install/`

3. Boot into the Raspberry PI and run `sudo /boot/install/1.update.sh`

4. `sudo reboot`  to load the updated kernel


## Install Enc Tools and Prep `initramfs`

1. Run script `/boot/install/2.disk_encrypt.sh`

2. `sudo reboot` to drop into the initramfs shell. 


## Mount and Encrypt 
This is adapted from "3.disk_encrypt_initramfs.sh" - but this did not work for me out of the box. So let's do most things manually

1. Mount master block device to `/tmp/boot/`

    ```shell
    mkdir /tmp/boot
    mount /dev/mmcblk0p1 /tmp/boot/
    ```

2. No, step by step, type this into your terminal:

    ```shell
    e2fsck -f /dev/mmcblk0p2
    resize2fs -fM /dev/mmcblk0p2 
    ```

3. Check with `lsblk` what is your usb device. Normally it is "sda".

4. Check your "Block Count"

    ```shell
    /dev/mmcblk0p2 | grep "Block count" 
    ```

5. Remember your "BLOCK_COUNT" number XXX. Then, if your USB device was "sda" run the commands one by one below. 
LUKS will ask for a password twice.

    ```shell
    dd bs=4k count=XXX if=/dev/mmcblk0p2 of=/dev/sda
    echo YES | cryptsetup --cipher aes-cbc-essiv:sha256 luksFormat /dev/mmcblk0p2
    cryptsetup luksOpen /dev/mmcblk0p2 sdcard
    dd bs=4k count=$BLOCK_COUNT if=/dev/$1 of=/dev/mapper/sdcard
    e2fsck -f /dev/mapper/sdcard
    resize2fs -f /dev/mapper/sdcard
    ```

6. `reboot -f` to drop back into initramfs.


## Unlock and Reboot to OS

1. Mount master block device at `/tmp/boot/`

    ```shell
    mkdir /tmp/boot
    mount /dev/mmcblk0p1 /tmp/boot/
    ```

2. Open the LUKS encrypted disk, you will have to type your password again

    ```shell
    cryptsetup luksOpen /dev/mmcblk0p2 sdcard
    exit
    ```

3. `exit` to quit BusyBox and boot normally.


## Rebuild `initramfs` for Normal Boot


1. Run:

```shell
 sudo mkinitramfs -o /boot/firmware/initramfs.gz
 sudo lsinitramfs /boot/firmware/initramfs.gz |grep -P "sbin/(cryptsetup|resize2fs|fdisk|dumpe2fs|expect)"
```

3. `sudo reboot` into Raspberry PI OS.

4. You should be asked for your decryption password every time you boot.

    ```shell
    Please unlock disc sdcard: _
    ```
____

## Troubleshooting
* If initramfs in `mkdir -p /tmp/boot` complains that "Volume Not Properly Unmounted" at some point - just run the suggested fix `fsck /dev/mmcblk0p1` and if it finds problems and give you solution proposals, choose the option "Copy original to backup"
* 

