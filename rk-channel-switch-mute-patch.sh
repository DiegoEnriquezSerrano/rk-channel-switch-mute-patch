#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Error: This script requires root privileges. Please run with sudo." >&2
    exit 1
fi

function get_input_device_event_name() {
    echo "Info: Finding RK RGB Keyboard event name.." >&2;

	cat /proc/bus/input/devices | awk '/[RK]([1-9]|[1-9][0-9]|100)[RGB]/{for(a=0;a>=0;a++){getline;{if(/Handlers/==1){ print $4;exit 0;}}}}';
}

function get_input_device_id() {
  echo "Info: Finding device id.." >&2;

  local device_id;

  device_id="$(cat /sys/class/input/"${DEVICE_EVENT_NAME}"/device/modalias | cut -d"-" -f1 | sed 's/input://')";

  echo "$device_id"
}

function remap_key() {
  echo "Info: Creating key remapping.." >&2;

  sudo touch /etc/udev/hwdb.d/61-keyboard-local.hwdb
  sudo tee /etc/udev/hwdb.d/61-keyboard-local.hwdb > /dev/null << END
evdev:input:${DEVICE_ID}*
 KEYBOARD_KEY_7007f=reserved
END
}

DEVICE_EVENT_NAME=$(get_input_device_event_name)
DEVICE_ID=$(get_input_device_id)

remap_key

echo "Info: Saving new rules..";

sudo systemd-hwdb update;
sudo udevadm trigger;

echo "Info: Finished!";
