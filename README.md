# Chrome OS Partition Resizer

This script aids with resizing the `STATE`, `KERN-C`, and `ROOT-C` partitions of a Chrome OS device.
Typically, this will be used to dual-boot Chrome OS and another operating system, but it can also be used to reclaim lost disk space.


Chrome OS enforeces a particular partition layout and will "repair" its installation (i.e., format the disk and reinstall itself) if a partition is added or removed.
This script resizes the `STATE`, `KERN-C`, and `ROOT-C` partitions rather than creating new partitions.

The `KERN-C` (`/dev/sda6`) and `ROOT-C` (`/dev/sda7`) partitions can be repurposed for a new operating system (where `ROOT-C` is the root partition and `KERN-C` is the boot partition) by allocating more space to them.

Using this script will **delete all data** on the `STATE`, `KERN-C`, and `ROOT-C` partitions, **including any downloads and files Chrome OS uses**. Back up that data if it is important to you.

By resizing the three partitions, space will (in most use cases) be taken from the `STATE` partition (which is where Chrome OS stores its data) and be reallocated to the `KERN-C` and `ROOT-C` partitions.

Chrome OS needs little space for itself, and there is little reason to use Crouton when natively installing another operating system, so it is recommended to minimize the space allocated to Chrome OS in order to maximize the space for the other operating system.
The default of 5 GiB may be excessive for the `STATE` partition; users may find themselves with leftover space even with a 3 GiB or smaller partition.

If `KERN-C` will be used as a boot partition, enough space for multiple kernels should be allocated to it.
The default of 64 MiB will be able to hold around eight versions of the Linux kernel--enough for most users.

All remaining space on the disk will be allocated to `ROOT-C` after `STATE` and `KERN-C` have been resized.
Allocating less space to `STATE` and `KERN-C` will result in a larger `ROOT-C` partition, and is therefore recommended for most use cases.


## Usage

First, [enable Developer Mode](http://www.chromium.org/chromium-os/poking-around-your-chrome-os-device#TOC-Putting-your-Chrome-OS-Device-into-Developer-Mode) on your Chrome OS device.

Next, [get to the shell](http://www.chromium.org/chromium-os/poking-around-your-chrome-os-device#TOC-Getting-to-a-command-prompt) by pressing <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>T</kbd> then typing "shell" at the prompt.
Once at the shell: download, read, and run [`cros-resize.sh`](https://github.com/ethanmad/chromeos-resize/blob/master/cros-resize.sh).

```bash
$ cd ~/Downloads/
$ curl https://raw.githubusercontent.com/ethanmad/chromeos-resize/master/cros-resize.sh
$ sudo bash cros-resize.sh
```

## Authors

Ethan Madison: <ethan@ethanmad.com><br>
Eric Hegnes:   <eric.hegnes@gmail.com>


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
