#!/bin/bash
# Selects the fastest Gentoo binpackage mirrors from the live, global mirror
# list and writes the top 4 fastest into a dedicated binrepos.conf drop-in.
# Idempotent - only ever touches its own file.

set -u

MIRROR_XML_URL="https://api.gentoo.org/mirrors/distfiles.xml"
BINPKG_PATH="releases/amd64/binpackages/23.0/x86-64/"
INDEX_FILE="Packages"
TIMEOUT=2.5
PARALLEL=100
FALLBACK="https://distfiles.gentoo.org/"
BINREPOS_DIR="/etc/portage/binrepos.conf"
REPO_FILE="${BINREPOS_DIR}/zz-mocaccino-fastest-binhost.conf"
REPO_NAME_PREFIX="mocaccino-fastest-binhost"
BASE_PRIORITY=10000
MIRROR_COUNT=4

# Hostnames that must never be selected (exact host match).
BLACKLIST=(
    "us.mirrors.cicku.me"
)

if ! command -v curl >/dev/null 2>&1; then
    echo "curl not available in this layer, skipping binhost mirror selection"
    exit 0
fi

XML=$(curl -s --max-time 5 "$MIRROR_XML_URL" 2>/dev/null || true)

FASTEST_MIRRORS=()

if [ -n "$XML" ]; then
    MIRRORS=$(echo "$XML" | grep -oP '<uri protocol="https"[^>]*>\K[^<]+' | sed 's:/*$:/:' | sort -u)

    # Drop blacklisted hosts (entries are normalized to end with "/")
    for bad in "${BLACKLIST[@]}"; do
        MIRRORS=$(echo "$MIRRORS" | grep -viF "://${bad}/" || true)
    done

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
            # Get up to $MIRROR_COUNT unique fastest mirrors
            mapfile -t FASTEST_MIRRORS < <(sort -n "$RESULTS" | head -n "$MIRROR_COUNT" | awk '{print $2}')
        fi
        rm -f "$RESULTS"
    fi
fi

# Fallback if no mirrors were found
if [ ${#FASTEST_MIRRORS[@]} -eq 0 ]; then
    FASTEST_MIRRORS=("$FALLBACK")
fi

mkdir -p "$BINREPOS_DIR"
> "$REPO_FILE"

echo "Configured binhost mirrors (in priority order):"

current_priority=$BASE_PRIORITY
for i in "${!FASTEST_MIRRORS[@]}"; do
    mirror="${FASTEST_MIRRORS[$i]}"
    binhost_url="${mirror%/}/${BINPKG_PATH}"
    repo_section="${REPO_NAME_PREFIX}-$((i + 1))"

    {
        echo "[${repo_section}]"
        echo "priority = ${current_priority}"
        echo "sync-uri = ${binhost_url}"
        echo ""
    } >> "$REPO_FILE"

    echo "  $((i + 1)). Priority ${current_priority}: ${binhost_url}"
    current_priority=$((current_priority - 10))
done