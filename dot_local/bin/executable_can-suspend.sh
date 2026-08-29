#!/usr/bin/env sh
# can-suspend.sh — defer suspend while an SSH session is active.
# Pattern from hypridle.md wiki.
# Exit 0 = OK to suspend.
# Exit non-zero = defer (hypridle retries per condition_retry seconds).
ss -tn state established '( sport = :ssh )' | grep -q . && exit 1
exit 0