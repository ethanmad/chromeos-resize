# Chrome OS Partition Resizer

This script resizes partitions of a Chrome OS.
Typically, this will be used to dual/multi-boot Chrome OS and another operating system, but it can also be used to reclaim lost disk space.

Chrome OS enforces a particular disk layout and will "repair" its installation by formatting the disk and reinstalling if a partition is added or removed.
This script resizes the partitions rather than creating new partitions to avoid triggering the "repair".

[![Chrome OS device disk layout chart from The Chromium Projects "Disk Layout" page](https://www.chromium.org/_/rsrc/1284148304249/chromium-os/chromiumos-design-docs/disk-format/layout.png "Chrome OS device disk layout from The Chromium Projects \"Disk Layout\" page. The green partiton labeled \"Encrypted user data\" is where Chrome OS stores user data. The grey partitions labeled \"Unused Kernel C\" and \"Unused Rootfs C\" are ideal places to put another operating system. Click to learn more.")](https://www.chromium.org/chromium-os/chromiumos-design-docs/disk-format)

As shown in the chart, the kernel C (partition 6) and rootfs C (partition 7) partitions are unused by the device, so we can safely resize (and use) them.
The user state partition (green, labeled "Encrypted user data") is used by Chrome OS to store user files, extensions, Android apps, etc.
`chromeos-resize` redistributes space among these three partitions to the user's desire.


Using this script will **delete all data** on these partitions, **including any downloads and files Chrome OS uses**.
Back up that data if it is important to you.

## Purpose

Originally created to serve the [Chromebook Pixel 2015 (samus) Linux community](https://github.com/raphael/linux-samus) which noticed the need for Chrome OS to receive firmware updates.

Dual/multi-booting Chrome OS alongside other operating system(s) is useful for a number of reason:

(0) Only Chrome OS can provide firmware updates to Chrome OS devices.
(1) Chrome OS can run Android apps, offers excellent battery life, and works out-of-the-box without issues.
(2) Other operating systems can provide access to other types of software, a better development environment, more system control, etc.
(3) Natively installing another operating system can be more convenient or efficient than running one through e.g., [crouton](https://github.com/dnschneid/crouton) or connecting to another machine via ssh.

`chromeos-resize` can also be used to revert from a multi-boot system to one with only Chrome OS, or other variations.
If, somehow, space on the disk was lost by another resizing, this will fix it.

## Usage

_Read through this entire section before resizing._

### Considerations
Carefully consider how much space you are allocating to each partition!
If you are unhappy with your partition sizes later, you will have to go through this process and lose all data on the three partitions again.

Chrome OS needs little space for itself, so it is recommended to minimize the space allocated to Chrome OS in order to maximize the space for the other operating system.
Check how much space you are using in the user state partition by running `$ df --human --output=used /dev/sda1` at the shell.
If planning to install the Google Play Store for Android apps, no less than 3 GiB should be allocated to the user state partition.
(Chrome OS and the Play Store without any Android apps use nearly 3 GiB.)

If kernel C will be used as a boot partition (recommended), enough space for multiple kernels should be allocated to it.
The default of 64 MiB will be able to hold around eight versions of the Linux kernel--enough for most users.

After resizing the user state and kernel C partitions, all remaining space will be allocated to the rootfs C partition.
Allocating less space to the user state and kernel C partitions will result in a larger rootfs C partition, and is therefore recommended for most use cases.

### Resizing

First, [enable Developer Mode](http://www.chromium.org/chromium-os/poking-around-your-chrome-os-device#TOC-Putting-your-Chrome-OS-Device-into-Developer-Mode) on your Chrome OS device.

Next, [get to the shell](http://www.chromium.org/chromium-os/poking-around-your-chrome-os-device#TOC-Getting-to-a-command-prompt) by pressing <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>T</kbd> then typing "shell" at the prompt.
Once at the shell: download, read, and run [`cros-resize.sh`](https://github.com/ethanmad/chromeos-resize/blob/master/cros-resize.sh).

```bash
$ cd ~/Downloads/
$ curl https://raw.githubusercontent.com/ethanmad/chromeos-resize/master/cros-resize.sh
$ sudo bash cros-resize.sh
```

Note that the script names partitions differently than does this document:

- `STATE` is the user state or "stateful" partition,
- `KERN-C` is the kernel C partition,
- `ROOT-C` is the rootfs C partition.

## Authors

- Ethan Madison: <ethan@ethanmad.com>
- Eric Hegnes:   <eric.hegnes@gmail.com>


## License

This work is released under the [GPL v3](http://www.gnu.org/licenses/gpl-3.0.html).

    Copyright (c) 2016 Ethan Madison and Eric Hegnes

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.


## Thanks

Thanks to Jay Lee and the authors of [chrubuntu-script](https://github.com/jay0lee/chrubuntu-script) for providing the inspiration and base for this project.
