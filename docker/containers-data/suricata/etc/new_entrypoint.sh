#!/bin/bash
set -e

fix_perms() {
    if [[ "${PGID}" ]]; then
        groupmod -o -g "${PGID}" suricata
    fi

    if [[ "${PUID}" ]]; then
        usermod -o -u "${PUID}" suricata
    fi

    chown -R suricata:suricata /etc/suricata
    chown -R suricata:suricata /var/lib/suricata
    chown -R suricata:suricata /var/log/suricata
    chown -R suricata:suricata /var/run/suricata
}

for src in /etc/suricata.dist/*; do
    filename=$(basename ${src})
    dst="/etc/suricata/${filename}"
    if ! test -e "${dst}"; then
        echo "Creating ${dst}."
        cp -a "${src}" "${dst}"
    fi
done

mkdir -p /var/log/suricata/fpc/
cat /etc/suricata/suricata.yaml | grep "include: selks6-addin.yaml" || echo "include: selks6-addin.yaml" >> /etc/suricata/suricata.yaml && echo 'suricata.yaml edited'

if [[ "${CREATE_DUMMY_INTERFACE}" ]]; then
    echo "Creating dummy interface"
    ip link add dummy0 type dummy && ip link set dummy0 up
fi

exec /docker-entrypoint.sh $@
