# Tell build process to exit if there are any errors.
set -euo pipefail
# if shit breaks i at least know where it is
set -x


#
# Fix SSH priv ports
#
echo 'net.ipv4.ip_unprivileged_port_start=0' > /etc/sysctl.d/50-unprivileged-ports.conf
