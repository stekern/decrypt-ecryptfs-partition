# decrypt-ecryptfs-partition
I recently needed to access a `$HOME` directory encrypted with ecryptfs on an external SSD, and it wasn't as straight-forward as I had expected.

After finding some solid instructions on https://unix.stackexchange.com/a/395391 I made this script to make the process easier for myself.

You'll need to modify the script if you want to use it on anything other than Ubuntu (it tries to install `ecryptfs-utils` using `apt`).

# Usage
Set the two variables `ENCRYPTED_DIR` and `MOUNT_POINT` in the script before running it.

# Tested on
Ubuntu 18.04
