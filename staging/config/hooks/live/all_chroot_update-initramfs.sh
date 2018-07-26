#!/bin/sh

# This is a hook for live-helper(7) to rebuild the initramfs image.
# To enable it, copy or symlink this hook into your config/chroot_local-hooks
# directory.
#
# Note: You only want to use this hook if you have modified any initramfs-script
# during the build and need to refresh the initrd.img for that purpose.

for KERNEL in /boot/vmlinuz-*
do
	VERSION="$(basename ${KERNEL} | sed -e 's|vmlinuz-||')"

	update-initramfs -k ${VERSION} -t -u
done

cat << EOF
********************
end of hook
********************
EOF
