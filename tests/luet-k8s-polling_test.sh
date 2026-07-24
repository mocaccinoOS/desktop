#!/bin/sh

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMPDIR_TEST=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TEST"' EXIT HUP INT TERM

mkdir "$TMPDIR_TEST/bin"

cat >"$TMPDIR_TEST/bin/luet" <<'EOF'
#!/bin/sh
printf '%s\n' '{"packages":[]}'
EOF

cat >"$TMPDIR_TEST/bin/sleep" <<'EOF'
#!/bin/sh
exit 0
EOF

cat >"$TMPDIR_TEST/bin/stern" <<'EOF'
#!/bin/sh
exit 0
EOF

cat >"$TMPDIR_TEST/bin/kubectl" <<'EOF'
#!/bin/sh
set -eu

log=${KUBECTL_LOG:?}
state_file=${KUBECTL_STATE_FILE:?}

if [ "$1" = "apply" ]; then
    cat >/dev/null
    printf '%s\n' apply >>"$log"
    exit 0
fi

if [ "$1" = "delete" ]; then
    printf '%s\n' delete >>"$log"
    exit 0
fi

if [ "$1" = "get" ]; then
    case "$*" in
        *" -o json")
            read -r state <"$state_file" || state=Succeeded
            tail -n +2 "$state_file" >"$state_file.next"
            mv "$state_file.next" "$state_file"
            case "$state" in
                missing) exit 1 ;;
                empty) printf '%s\n' '{"status":{}}' ;;
                *) printf '{"status":{"state":"%s"}}\n' "$state" ;;
            esac
            ;;
        *)
            printf '%s\n' repobuild
            ;;
    esac
    exit 0
fi

exit 1
EOF

chmod +x "$TMPDIR_TEST/bin/luet" "$TMPDIR_TEST/bin/kubectl" "$TMPDIR_TEST/bin/sleep" "$TMPDIR_TEST/bin/stern"

cat >"$TMPDIR_TEST/states" <<'EOF'
Failed
missing
empty
Running
Succeeded
EOF

: >"$TMPDIR_TEST/kubectl.log"

PATH="$TMPDIR_TEST/bin:$PATH" \
KUBECTL_LOG="$TMPDIR_TEST/kubectl.log" \
KUBECTL_STATE_FILE="$TMPDIR_TEST/states" \
BUILD_PHASE=true \
CREATE_PHASE=false \
TRACE_LOGS_BACKGROUND=false \
NAMESPACE=test \
REPO=repo \
GITHUB_BRANCH=branch \
JOB_STATE_TIMEOUT_SECONDS=10 \
bash "$ROOT/.github/luet-k8s.sh"

expected='delete
apply
delete'
actual=$(cat "$TMPDIR_TEST/kubectl.log")
if [ "$actual" != "$expected" ]; then
    printf 'unexpected kubectl lifecycle:\n%s\n' "$actual" >&2
    exit 1
fi

printf '%s\n' 'luet-k8s polling lifecycle: ok'
