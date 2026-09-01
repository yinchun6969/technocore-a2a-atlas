#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=versions.env
source "$ROOT/versions.env"
MODE=check
LANGUAGE=zh

die() { echo "ERROR: $*" >&2; exit 1; }
while (($#)); do
  case "$1" in
    --check) MODE=check ;;
    --apply) MODE=apply ;;
    --lang) shift; LANGUAGE="${1:-}" ;;
    -h|--help)
      echo "Usage: bash onboard.sh [--check|--apply] [--lang zh|en]"
      exit 0
      ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done
[[ "$LANGUAGE" =~ ^(zh|en)$ ]] || die "--lang must be zh or en"
for command in git bash python3 curl; do
  command -v "$command" >/dev/null || die "$command is required"
done

stage="$(mktemp -d /tmp/technocore-onboard-entry.XXXXXX)"
[[ "$stage" == /tmp/technocore-onboard-entry.* ]] || die "unsafe staging directory"
trap 'rm -rf -- "$stage"' EXIT
git -c init.defaultBranch=main init -q "$stage/source"
git -C "$stage/source" remote add origin "$TECHNOCORE_SOURCE_REPO"
git -C "$stage/source" fetch -q --depth=1 origin "$DID_WIZARD_REF"
git -C "$stage/source" checkout -q --detach FETCH_HEAD
[[ "$(git -C "$stage/source" rev-parse HEAD)" == "$DID_WIZARD_REF" ]] || die "DID wizard source mismatch"

installer="$stage/source/projects/technocore-did-onboarding/install.sh"
[[ -f "$installer" && ! -L "$installer" ]] || die "pinned DID wizard installer absent"
bash "$installer" "--$MODE" --lang "$LANGUAGE"

echo "TECHNOCORE_ONBOARD_ENTRY_OK"
echo "mode=$MODE; language=$LANGUAGE; source_ref=$DID_WIZARD_REF"
echo "private_key=local-only;0600;never-uploaded-or-printed"
