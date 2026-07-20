#!/bin/bash
# Selects the fastest Gentoo binpackage mirror from the live, global mirror
# list and writes it into a dedicated binrepos.conf drop-in. Idempotent -
# only ever touches its own file. Never modifies make.conf or any other
# binrepos.conf entry (e.g. the shipped gentoobinhost.conf stays as-is).

set -u

MIRROR_XML_URL="https://api.gentoo.org/mirrors/distfiles.xml"
BINPKG_PATH="releases/amd64/binpackages/23.0/x86-64/"
INDEX_FILE="Packages"
TIMEOUT=2.5
PARALLEL=100
FALLBACK="https://distfiles.gentoo.org/"
BINREPOS_DIR="/etc/portage/binrepos.conf"
REPO_FILE="${BINREPOS_DIR}/zz-mocaccino-fastest-binhost.conf"
REPO_NAME="mocaccino-fastest-binhost"
PRIORITY=10000

if ! command -v curl >/dev/null 2>&1; then
    echo "curl not available in this layer, skipping binhost mirror selection"
    exit 0
fi

XML=$(curl -s --max-time 5 "$MIRROR_XML_URL" 2>/dev/null || true)

FASTEST=""
if [ -n "$XML" ]; then
    MIRRORS=$(echo "$XML" | grep -oP '<uri protocol="https"[^>]*>\K[^<]+' | sed 's:/*$:/:' | sort -u)
    if [ -n "$MIRRORS" ]; then
        RESULTS=$(mktemp)

        probe() {
            local mirror="$1"
            local url="${mirror%/}/${BINPKG_PATH}${INDEX_FILE}"
            local out
            out=$(curl -o /dev/null -s -w "%{http_code} %{time_total}" \
                -I -L --max-time "$TIMEOUT" --connect-timeout "$TIMEOUT" "$url" 2>/dev/null)
            local rc=$?
            local code="${out%% *}"
            local time="${out##* }"
            if [[ $rc -eq 0 && "$code" == "200" ]]; then
                echo "$time $mirror" >> "$RESULTS"
            fi
        }
        export -f probe
        export BINPKG_PATH INDEX_FILE TIMEOUT RESULTS

        echo "$MIRRORS" | xargs -P "$PARALLEL" -I{} bash -c 'probe "$@"' _ {}

        if [ -s "$RESULTS" ]; then
            FASTEST=$(sort -n "$RESULTS" | head -n1 | awk '{print $2}')
        fi
        rm -f "$RESULTS"
    fi
fi

[ -z "$FASTEST" ] && FASTEST="$FALLBACK"
BINHOST_URL="${FASTEST%/}/${BINPKG_PATH}"

mkdir -p "$BINREPOS_DIR"
{
    echo "[${REPO_NAME}]"
    echo "priority = ${PRIORITY}"
    echo "sync-uri = ${BINHOST_URL}"
} > "$REPO_FILE"

echo "Selected fastest binhost: ${BINHOST_URL} (priority ${PRIORITY})"
