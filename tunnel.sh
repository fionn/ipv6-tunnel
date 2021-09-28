#!/bin/bash
# shellcheck disable=SC2153

set -euo pipefail

function set_dns_get_ipv4 {
    username=$1
    update_key=$2
    tunnel_id=$3

    base_url=ipv4.tunnelbroker.net
    url="https://$username:$update_key@$base_url/nic/update?hostname=$tunnel_id"
    mapfile -td " " -n 2 status_ip < <(\
       setpriv --reuid=1000 --regid=1000 --clear-groups \
       curl -4s "$url" | tr -d "\n")

    # See https://help.dyn.com/server-access-api/return-codes/ for
    # possible returned statuses.
    if [[ "${#status_ip[@]}" -lt 2 ]]; then
        echo "Failed with ${status_ip[0]}" >&2
        exit 2
    fi

    status="${status_ip[0]}"
    ip="${status_ip[1]}"

    if [[ "$status" != "good" ]] && [[ "$status" != "nochg" ]]; then
        echo "Bad response: ${status_ip[*]}" >&2
        exit 3
    elif [[ "$ip" == "127.0.0.1" ]]; then
        echo "Failed with ${status_ip[*]}; unreachable via ICMP" >&2
        exit 4
    fi

    echo "$ip"
}

function main {
    if [[ $# -ne 1 ]]; then
        echo "$0 takes exactly one argument; $# provided"
        exit 1
    fi

    export interface="${INTERFACE:-he-ipv6}"
    export username="$USERNAME"
    export update_key="$UPDATE_KEY"
    export tunnel_id="$TUNNEL_ID"
    export server_ipv4="$SERVER_IPV4"
    export client_ipv6="$CLIENT_IPV6"

    if [[ $1 == "up" ]]; then
        up
    elif [[ $1 == "down" ]]; then
        down
    else
        echo "Argument must be either \"up\" or \"down\"" >&2
        exit 1
    fi
}

function up {
    local client_ipv4
    client_ipv4="$(set_dns_get_ipv4 \
        "$username" "$update_key" "$tunnel_id")"
    # If forwarding protocol 41 use local IPv4 address instead.
    #client_ipv4="$(ip -j -4 route | jq -r .[0].prefsrc)"

    ip tunnel add "$interface" \
        mode sit \
        remote "$server_ipv4" \
        local "$client_ipv4" \
        ttl 255

    # Kernel bug workaround
    # Assuming server_ipv6=2001:470:18:8e3::1/64
    #ip tunnel 6rd dev "$interface" \
    #    6rd-prefix 2001:470:18:8e3::1/64 \
    #    6rd-relay_prefix $server_ipv4/32

    ip link set "$interface" up mtu 1480
    ip address add "$client_ipv6" dev "$interface"
    ip route add ::/0 dev "$interface"
}

function down {
    ip route del ::/0 dev "$interface"
    ip address del "$client_ipv6" dev "$interface"
    ip link set "$interface" down
    ip tunnel del "$interface"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
