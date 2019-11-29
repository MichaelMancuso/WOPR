#!/bin/bash

echo "In order to create an AES-256-SHA1 encrypted Linux partition:"
echo "1.  Mount/add a new drive or have an unused partition available (in this example /dev/sdb1)"
echo "2.  apt-get install cryptsetup"
echo "3.  cryptsetup luksFormat /dev/sdb1 (the partition we want to use)"
echo "4.  Use 'cryptsetup luksOpen /dev/sdb1 encrypted_partition' to create the new block device as /dev/mapper/encrypted_partition"
echo "5.  Use 'mkfs.ext4 /dev/mapper/encrypted_partition' to format the new encrypted partition."
echo "6.  Edit /etc/crypttab and add the line 'encrypted_partition /dev/sdb1 none luks'"
echo "7.  Create a mount point or use an existing directory (e.g. mkdir /mnt/crypto_test)"
echo "8.  Edit /etc/fstab and add the line '/dev/mapper/encrypted_partition /home/mpiscopo/PenTests ext4 defaults'"
echo "9.  Run the command 'update-initramfs -u -k all' (If after a kernel update something goes wrong you may need to rerun this)."
echo "10.  Reboot and enter the passphrase when asked."
