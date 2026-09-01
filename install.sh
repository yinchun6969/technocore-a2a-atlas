#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=versions.env
source "$ROOT/versions.env"

MODE=check
ROLE=auto
WITH_ATLAS=auto

die() { echo "ERROR: $*" >&2; exit 1; }
usage() {
  cat <<'EOF'
Usage: sudo bash install.sh [--check|--apply]
                            [--role auto|love8|aizong|ai2ai]
                            [--atlas auto|yes|no]

Default is a non-mutating check. This release candidate upgrades an existing
Technocore A2A node. It never copies or prints private keys.
EOF
}
while (($#)); do
  case "$1" in
    --check) MODE=check ;;
    --apply) MODE=apply ;;
    --role) shift; ROLE="${1:-}" ;;
    --atlas) shift; WITH_ATLAS="${1:-}" ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; die "unknown option: $1" ;;
  esac
  shift
done
[[ "$ROLE" =~ ^(auto|love8|aizong|ai2ai)$ ]] || die "invalid --role"
[[ "$WITH_ATLAS" =~ ^(auto|yes|no)$ ]] || die "invalid --atlas"
[[ "$(uname -s)" == Linux ]] || die "full node installation requires Linux; phones/computers may use SSH forwarding"
[[ $EUID -eq 0 ]] || die "run with sudo on the target A2A node"
for command in git python3 bash curl sha256sum; do
  command -v "$command" >/dev/null || die "$command is required"
done

read_agent() {
  python3 - "$1" <<'PY'
from pathlib import Path
import shlex, sys
values={}
for line in Path(sys.argv[1]).read_text().splitlines():
    parts=shlex.split(line, comments=True)
    if parts and parts[0]=='export': parts=parts[1:]
    for part in parts:
        key, sep, value=part.partition('=')
        if sep and key in {'AGENT_NAME','ROLE'}: values[key]=value
print(values.get('AGENT_NAME',''))
PY
}

if [[ -f /opt/technocore-a2a/.env && ! -L /opt/technocore-a2a/.env ]]; then
  CONFIG=/opt/technocore-a2a/.env
elif [[ -f /opt/technocore-collab/.env && ! -L /opt/technocore-collab/.env ]]; then
  CONFIG=/opt/technocore-collab/.env
else
  echo "TECHNOCORE_A2A_ATLAS_PREFLIGHT=ONBOARDING_REQUIRED"
  echo "reason=no existing A2A runtime; use the bilingual DID wizard first"
  echo "wizard_ref=$DID_WIZARD_REF"
  echo "private_key=local-only;never-uploaded-or-printed"
  exit 3
fi

DETECTED_ROLE="$(read_agent "$CONFIG")"
[[ "$DETECTED_ROLE" =~ ^(love8|aizong|ai2ai)$ ]] || die "unsupported AGENT_NAME in $CONFIG"
if [[ "$ROLE" == auto ]]; then ROLE="$DETECTED_ROLE"; fi
[[ "$ROLE" == "$DETECTED_ROLE" ]] || die "requested role $ROLE does not match installed node $DETECTED_ROLE"
if [[ "$WITH_ATLAS" == auto ]]; then
  [[ "$ROLE" == ai2ai ]] && WITH_ATLAS=yes || WITH_ATLAS=no
fi
[[ "$ROLE" == ai2ai || "$WITH_ATLAS" == no ]] || die "Atlas may run only on the AI2AI Reviewer node"

stage="$(mktemp -d /tmp/technocore-a2a-atlas.XXXXXX)"
[[ "$stage" == /tmp/technocore-a2a-atlas.* ]] || die "unsafe staging directory"
trap 'rm -rf -- "$stage"' EXIT

checkout_ref() {
  local ref="$1" destination="$2"
  git -c init.defaultBranch=main init -q "$destination"
  git -C "$destination" remote add origin "$TECHNOCORE_SOURCE_REPO"
  git -C "$destination" fetch -q --depth=1 origin "$ref"
  git -C "$destination" checkout -q --detach FETCH_HEAD
  [[ "$(git -C "$destination" rev-parse HEAD)" == "$ref" ]] || die "source commit mismatch"
}

checkout_ref "$A2A_REF" "$stage/a2a"
echo "TECHNOCORE_A2A_ATLAS_PREFLIGHT=PASS"
echo "role=$ROLE; a2a=$A2A_VERSION; a2a_ref=$A2A_REF"
echo "atlas=$WITH_ATLAS; atlas_version=$ATLAS_VERSION; atlas_ref=$ATLAS_REF"
echo "identity=existing; private_key=untouched; default_mode=$MODE"

bash "$stage/a2a/deploy/a2a-v5/install-a2a-suite-v5.5.sh" "--$MODE"
case "$ROLE" in
  ai2ai)
    bash "$stage/a2a/deploy/a2a-v5/install-verifiable-evidence-v5.5.2.sh" "--$MODE"
    ;;
  aizong)
    bash "$stage/a2a/deploy/a2a-v5/install-aizong-cursor-poll-v3.6.sh" "--$MODE"
    ;;
  love8)
    bash "$stage/a2a/deploy/a2a-v5/install-love8-outbound-dedupe-v3.7.sh" "--$MODE"
    bash "$stage/a2a/deploy/a2a-v5/install-love8-inbound-cursor-v3.8.sh" "--$MODE"
    ;;
esac

if [[ "$WITH_ATLAS" == yes ]]; then
  checkout_ref "$ATLAS_REF" "$stage/atlas"
  if [[ -e /opt/technocore-atlas || -e /etc/technocore-atlas.conf ]]; then
    if [[ "$MODE" == check ]]; then
      bash -n "$stage/atlas/deploy/atlas/upgrade-v3.sh"
      echo "ATLAS_PLAN=upgrade-existing-to-v3.9; check-only"
    else
      bash "$stage/atlas/deploy/atlas/upgrade-v3.sh"
    fi
  else
    if [[ "$MODE" == check ]]; then
      bash "$stage/atlas/deploy/atlas/install.sh" --check
    else
      bash "$stage/atlas/deploy/atlas/install.sh"
    fi
  fi
fi

if [[ "$MODE" == check ]]; then
  echo "CHECK_ONLY: no managed files, services, keys, rooms or state changed"
else
  echo "TECHNOCORE_A2A_ATLAS_INSTALLED"
  echo "role=$ROLE; a2a=$A2A_VERSION; atlas=$WITH_ATLAS"
  echo "next=run role status; verify a real five-stage signed workflow"
fi
