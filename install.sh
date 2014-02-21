# Create a temp directory for our work
tempbuild=`mktemp -d`
cd $tempbuild

# Determine kernel version (with and without Ubuntu-specific suffix)
mykern=${1:-$(uname -r)}
mykernver=linux-$(echo $mykern | cut -d'-' -f 1)

# Install necessary deps to build a kernel
sudo apt-get build-dep -y --no-install-recommends linux-image-$mykern

# Grab Ubuntu kernel source
wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.13.4.tar.xz
tar -xJf linux-3.13.4.tar.xz
cd linux-3.13.4

# Modified version of Benson Leung's post-Pixel Chromebook patches, fixed to work with 3.13.4
for patch in 3078491 3078481 3074391 3074441 3074421 3074401 3074431 3074411; do
  wget -O - https://github.com/raouldc/c720-touchpad-patches/raw/master/$patch.patch | patch -p1
done


# Need this
cp /usr/src/linux-headers-$mykern/Module.symvers .

# Prep tree
cp /boot/config-$mykern ./.config
make oldconfig
make prepare
make modules_prepare

# Build only the needed directories
make SUBDIRS=drivers/platform/x86 modules
make SUBDIRS=drivers/i2c/busses modules

# switch to using our new chromeos_laptop.ko module
# preserve old as .orig
sudo mv /lib/modules/$mykern/kernel/drivers/platform/x86/chromeos_laptop.ko /lib/modules/$mykern/kernel/drivers/platform/x86/chromeos_laptop.ko.orig
sudo cp drivers/platform/x86/chromeos_laptop.ko /lib/modules/$mykern/kernel/drivers/platform/x86/

# switch to using our new designware i2c modules
# preserve old as .orig
sudo mv /lib/modules/$mykern/kernel/drivers/i2c/busses/i2c-designware-core.ko /lib/modules/$mykern/kernel/drivers/i2c/busses/i2c-designware-core.ko.orig
sudo mv /lib/modules/$mykern/kernel/drivers/i2c/busses/i2c-designware-pci.ko /lib/modules/$mykern/kernel/drivers/i2c/busses/i2c-designware-pci.ko.orig
sudo mv /lib/modules/$mykern/kernel/drivers/i2c/busses/i2c-designware-platform.ko /lib/modules/$mykern/kernel/drivers/i2c/busses/i2c-designware-platform.ko.orig
sudo cp drivers/i2c/busses/i2c-designware-*.ko /lib/modules/$mykern/kernel/drivers/i2c/busses/
sudo depmod -a $mykern
echo "Finished building Chromebook modules in $tempbuild. Reboot to use them."