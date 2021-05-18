# IPv6 Tunnel

## Overview

This configures an IPv6 tunnel via systemd.

Recommended for Hurricane Electric / Tunnel Broker only.

## Configuration

This requires a configuration file ending in `.conf` under `/etc/tunnelbroker/` matching the form of `tunnel.conf.example`.

## Installation

```sh
install -m 644 -t /etc/systemd/system/ service/ipv6-tunnel@.service
install -m 744 -Dt /etc/tunnelbroker/ tunnel.sh
```

## Usage

Assuming the configuration file is named `he.conf`, start the service with `systemctl start ipv6-tunnel@he.service`.

For hacking at the script, something like `sudo bash -c "source he.conf; ./tunnel.sh up"` works well after adding `export`s to `he.conf`.
