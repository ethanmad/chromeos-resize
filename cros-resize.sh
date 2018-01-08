#!/bin/bash

# Authors: Ethan Madison <ethan@ethanmad.com>
#          Eric Hegnes <eric.hegnes@gmail.com>

# Description: This program resizes Chrome OS partitions without
#              altering the enforced partition layout/scheme.
#              Typically used to accomodate a second operating system.

# License: GPLv3
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

set -e

error() {
    echo -e "\E[1;31m${1}\e[0m" >&2;
}

warn() {
    echo -e "\E[1;33m${1}\e[0m" >&2;
}

NUM_REGEX='^[0-9]+([.][0-9]+)?$'
DISK=$(rootdev -d -s)

# Initial disclaimer
echo "Got $DISK as the target drive."
warn "WARNING! All data on this device will be wiped out! Continue at your own \
risk!"
read -p "Press [Enter] to proceed on $DISK or CTRL+C to quit"
echo

# Check if developer mode is enabled
FW_TYPE="$(crossystem mainfw_type)"
if [ ! "$FW_TYPE" = "developer" ] ; then
    error "ERROR: Your Chromebook is not running a developer BIOS!"
    echo -e "You need to run \`# chromeos-firmwareupdate --mode=todev\`
and then re-run this script."
    exit
fi

POWERD_STATUS="$(initctl status powerd)"
if [ ! "$POWERD_STATUS" = "powerd stop/waiting" ] ; then
  echo "Stopping powerd to keep display from timing out..."
  initctl stop powerd > /dev/null
fi
echo

# Calculate total available space
STATE_START=$(cgpt show -i 1 -n -b -q $DISK)
ROOT_C_END=$(sudo cgpt show $DISK | grep "Sec GPT table" | awk '{print $1}')

AVAILABLE_SZ=$((ROOT_C_END - STATE_START))
AVAILABLE_SZ_MB=$((AVAILABLE_SZ * 512 / 1024 / 1024))
AVAILABLE_SZ_GB=$(awk "BEGIN {printf \"%.2f\",${AVAILABLE_SZ_MB} / 1024}")

# Prompt and read desired sizes
echo "To resize the KERN-C and ROOT-C partitions, we will shrink the STATE
partition (Chrome OS's data partition). You will specify how much size to
allocate to the STATE partition and KERN-C, and the rest of the space will be
allocated to ROOT-C.
There are $AVAILABLE_SZ_MB MiB ($AVAILABLE_SZ_GB GiB) available to work with.
The sum of the following two partition sizes must be less than this amount."
echo
STATE_SZ_DEFAULT=5120
read -e -p "How big should the STATE partition be in MiB (default(equivalent of 5GiB): \
$STATE_SZ_DEFAULT)? " -i $STATE_SZ_DEFAULT STATE
if ! [[ $STATE =~ $NUM_REGEX ]]; then
   error "ERROR: Not a valid number."
   exit 1
fi
echo

echo "KERN-C is where you can store kernels and should be mounted at /boot.
More space means you can keep more copies of kernels for rolling back, in case
something goes wrong."
echo
KERN_C_SZ_DEFAULT=64
read -e -p "How big should the KERN-C partition be in MiB (default: \
$KERN_C_SZ_DEFAULT)? " -i $KERN_C_SZ_DEFAULT KERN
if ! [[ $KERN =~ $NUM_REGEX ]]; then
   error "ERROR: Not a valid number."
   exit 1
fi
echo

echo "You chose to allocate $STATE MiB for the state partition and $KERN MiB for
the KERN-C partition. ROOT-C will be allocated to the remaining space available
space. The size of the STATE and KERN-C partitions must be integers."
echo
read -e -p "Is everything correct? [y/N] " -i "N" CONTINUE
if [[ $CONTINUE != "y" ]]  && [[ $CONTINUE != "Y" ]]; then
    error "You said the values were wrong."
    exit 1
fi
echo

# Calculate starting sector(s) and size(s)
STATE_START=$(cgpt show -i 1 -n -b -q $DISK)
STATE_SZ=$((STATE * 1024 * 2))
KERN_C_START=$((STATE_START + STATE_SZ))
KERN_C_SZ=$((KERN * 1024 * 2))
ROOT_C_START=$((KERN_C_START + KERN_C_SZ))
ROOT_C_SZ=$((ROOT_C_END - ROOT_C_START))

# Fail if new sizes are too big
if [ $AVAILABLE_SZ -lt $((KERN_C_SZ + ROOT_C_SZ)) ]; then
    error "ERROR: Chosen space allocation is larger than available space."
    exit 1
fi

STATE_SZ_MB=$STATE
STATE_SZ_GB=$(awk "BEGIN {printf \"%.2f\",${STATE_SZ_MB} / 1024}")
KERN_C_SZ_MB=$KERN
KERN_C_SZ_GB=$(awk "BEGIN {printf \"%.2f\",${KERN_C_SZ_MB} / 1024}")
ROOT_C_SZ_MB=$((ROOT_C_SZ * 512 / 1024 / 1024))
ROOT_C_SZ_GB=$(awk "BEGIN {printf \"%.2f\",${ROOT_C_SZ_MB} / 1024}")

echo "STATE will be allocated $STATE_SZ sectors, $STATE_SZ_MB MiB, or $STATE_SZ_GB GiB."
echo "KERN-C will be allocated $KERN_C_SZ sectors, or $KERN_C_SZ_MB MiB, or $KERN_C_SZ_GB, GiB."
echo "ROOT-C will be allocated $ROOT_C_SZ sectors, or $ROOT_C_SZ_MB MiB, or $ROOT_C_SZ_GB GiB."
warn "Afer this point, your disk will be repartitioned and wiped."
echo
read -e -p "Does this look good? [y/N] " -i "N" CONTINUE
if [[ $CONTINUE != "y" ]] && [[ $CONTINUE != "Y" ]]; then
    error "You said the values were wrong."
    exit 1
fi
echo

# Unmount stateful partition
echo "Unmounting stateful partition..."
STATEFUL_MOUNT=/dev/mapper/encstateful
mountpoint -q $STATEFUL_MOUNT && umount -A -l $STATEFUL_MOUNT

# Modify GPT table
echo "Editing partition table..."
cgpt add -i 1 -b $STATE_START -s $STATE_SZ -l STATE $DISK
cgpt add -i 6 -b $KERN_C_START -s $KERN_C_SZ -l KERN-C $DISK
sudo cgpt add -i 7 -b $ROOT_C_START -s $ROOT_C_SZ -l ROOT-C $DISK

# Zero out STATE partition
STATE_SEEK=$((STATE_START / 1024 / 2))
STATE_COUNT=$((STATE_SZ / 1024 / 2))
echo "Zeroing stateful partition..."
dd if=/dev/zero of=$DISK bs=1048576 seek=$STATE_SEEK count=$STATE_COUNT \
status=progress
echo

echo "Now reboot and allow Chrome OS to repair itself.  You may have to run
this program again with the same values before they stick."
