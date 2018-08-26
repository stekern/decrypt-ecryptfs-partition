#! /bin/bash
#
# decrypt_ecryptfs_partition.sh
# Copyright (C) 2018 Erlend Ekern <dev@ekern.me>
#
# Distributed under terms of the MIT license.
#

# Stop execution if an error occurs
set -e

# This script is based on instructions from https://unix.stackexchange.com/a/395391

###########################################
#                                         #
# The following TWO variables must be set #
#                                         #
###########################################

# Your encrypted directory is most likely at a location similar to:
# '/media/<mountpoint>/home/.ecryptfs/<user>'
ENCRYPTED_DIR=""

# This is where the decrypted partition will be mounted, e.g. '/media/decrypted'
MOUNT_POINT=""


######################################################
#                                                    #
# The remainder of the script should not be changed! #
#                                                    #
######################################################

PRIVATE_DIR="$ENCRYPTED_DIR/.Private"
ECRYPTFS_DIR="$ENCRYPTED_DIR/.ecryptfs"
SIGNATURE_FILE="$ECRYPTFS_DIR/Private.sig"
WRAPPED_PASSPHRASE_FILE="$ECRYPTFS_DIR/wrapped-passphrase"

REQUIRED_DIRS=("$ENCRYPTED_DIR" "$PRIVATE_DIR" "$ECRYPTFS_DIR")
REQUIRED_FILES=("$SIGNATURE_FILE" "$WRAPPED_PASSPHRASE_FILE")

# Check if the required directories and files exist
for REQUIRED_DIR in "${REQUIRED_DIRS[@]}"; do
  [ ! -d "$REQUIRED_DIR" ] && echo "Directory '$REQUIRED_DIR' does not exist! Exiting ..." && exit
done

for REQUIRED_FILE in "${REQUIRED_FILES[@]}"; do
  [ ! -f "$REQUIRED_FILE" ] && echo "File '$REQUIRED_FILE' does not exist! Exiting ..." && exit
done

# sudo priviliges needed for mounting, unmounting and installing ecryptfs-utils
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

# Install ecryptfs-utils if it is not installed
[ ! "$(dpkg -s ecryptfs-utils 2>/dev/null)" ] && sudo apt install ecryptfs-utils

# Create mount point if it does not exist
[ ! -d "$MOUNT_POINT" ] && sudo mkdir -p $MOUNT_POINT

# Read the passphrase signatures
read sig1 sig2 < <(cat "$SIGNATURE_FILE" | xargs)

# Get the mount passphrase
echo -n "Enter the login password for the ecryptfs partition: "
mount_passphrase=$(ecryptfs-unwrap-passphrase "$WRAPPED_PASSPHRASE_FILE" -)
echo ""

# Load the keys into the kernel
echo "$mount_passphrase" | ecryptfs-add-passphrase --fnek 1>/dev/null

# Unmount the partition if it is mounted
while grep -qs "$MOUNT_POINT" /proc/mounts; do
  sudo umount "$MOUNT_POINT"
done

# Mount the partition
sudo mount -i -t ecryptfs -o ecryptfs_sig="$sig1",ecryptfs_fnek_sig="$sig2",ecryptfs_cipher=aes,ecryptfs_key_bytes=16 "$ENCRYPTED_DIR/.Private" "$MOUNT_POINT"

echo "Your decrypted files should now be available at '$MOUNT_POINT'."
