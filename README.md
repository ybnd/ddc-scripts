# ddc-scripts

Some scripts for basic monitor control over DDC

- `dim.sh` – set brightness of all displays at once

- `swim.sh` – switch monitor input source

  Note: there can be some flickering just after switching (intensity varies, sometimes it’s pretty bad) but this seems to go away pretty quickly. Jury is still out on whether this is bad for the monitor(s), so use at your own risk.



### Setup

1. Install [ddcutil](https://github.com/rockowitz/ddcutil/), [i2c-tools](https://i2c.wiki.kernel.org/index.php/I2C_Tools), [jq](https://stedolan.github.io/jq/)
   On Manjaro/Arch, all of these are available via `pacman` or the AUR
   
2. Double check which VCP codes your monitor(s) actually support with `ddcutil capabilities`. The following codes are required (along with their default values as set in `common.sh`)

    * Brightness 🡒 VCP 10

    * Input source 🡒 VCP 60

3. Run any of the scripts listed above. A configuration file will be generated at `~/.config/ddc-scripts`.

    ```json
    {
      "about": "configuration file for https:/github.com/ybnd/ddc-scripts",
      "vcp": {
        "brightness": 10,			// you can adjust these if necessary
        "input_source": 60
      },
      "aliases": {					// you can define value aliases here
      },
      "displays": {					// auto-detected connected displays
        "6": {						// numbers correspond to i2c buses, i.e. /dev/i2c-6
          "name": "Display 6",
        },
        "9": {
          "name": "Display 9",
        }
      }
    }
    ```

#### Value aliases

Add aliases to make specific values easier to remember. For instance, you can assign easy-to-remember names for input sources based on what you connect to them:

```sh
$ ddcutil capabilities
Model: ...
MCCS version: ...
Commands:
   ...
VCP Features:
   ...
   Feature: 60 (Input Source)
      Values:
         0f: DisplayPort-1		# Let's say this is a computer
         10: DisplayPort-2
         11: HDMI-1				# ...and this is a TV
         12: HDMI-2
   ...
```

 In `~/.config/ddc-scripts`, configure the following aliases

```json
  "aliases": {
    "computer": "0f",
    "tv": "11"
  },
```

Now you can use these with `swim.sh`

```sh
$ swim tv
Display 1: 0f 🡒 11
$ swim computer
Display 1: 11 🡒 0f
```

