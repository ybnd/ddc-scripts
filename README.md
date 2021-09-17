# ddc-scripts

Some scripts for basic monitor control over DDC

- `dim.sh` – set brightness of all displays at once
- `swim.sh` – switch monitor input source



### Setup

- Install [ddcutil](https://github.com/rockowitz/ddcutil/), [i2c-tools](https://i2c.wiki.kernel.org/index.php/I2C_Tools), [jq](https://stedolan.github.io/jq/)

  On Manjaro/Arch, all of these are available via `pacman` or the AUR

* Run any of the scripts listed above. A configuration file will be generated at `~/.config/ddc-scripts`.