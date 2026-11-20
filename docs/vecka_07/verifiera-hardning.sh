#!/bin/bash
fel=0

getenforce | grep -q Enforcing && echo "GÄLLER SELinux enforcing nu" || { echo "GÄLLER INTE SELinux enforcing nu"; fel=1; }
grep -q '^SELINUX=enforcing' /etc/selinux/config && echo "GÄLLER SELinux enforcing efter omstart" || { echo "GÄLLER INTE SELinux enforcing efter omstart"; fel=1; }
ps -eZ | grep -q zonvakt_t && echo "GÄLLER zonvakt kör i zonvakt_t" || { echo "GÄLLER INTE zonvakt kör i zonvakt_t"; fel=1; }
grep -q 'port="6514"' /etc/rsyslog.d/90-logg.conf && echo "GÄLLER loggar skickas på 6514" || { echo "GÄLLER INTE loggar skickas på 6514"; fel=1; }

exit $fel
