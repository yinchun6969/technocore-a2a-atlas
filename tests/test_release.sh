#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
bash -n "$ROOT/install.sh"
bash -n "$ROOT/onboard.sh"
grep -Eq '^A2A_REF="[0-9a-f]{40}"$' "$ROOT/versions.env"
grep -Eq '^ATLAS_REF="[0-9a-f]{40}"$' "$ROOT/versions.env"
grep -Eq '^DID_WIZARD_REF="[0-9a-f]{40}"$' "$ROOT/versions.env"
grep -Fq 'private_key=untouched' "$ROOT/install.sh"
grep -Fq 'install-verifiable-evidence-v5.5.2.sh' "$ROOT/install.sh"
grep -Fq 'install-human-action-center-v1.sh' "$ROOT/install.sh"
grep -Fq 'human_action_center=enabled' "$ROOT/install.sh"
grep -Fq 'install-love8-inbound-cursor-v3.8.sh' "$ROOT/install.sh"
grep -Fq 'install-aizong-cursor-poll-v3.6.sh' "$ROOT/install.sh"
grep -Fq 'Atlas may run only on the AI2AI Reviewer node' "$ROOT/install.sh"
grep -Fq 'private_key=local-only;0600;never-uploaded-or-printed' "$ROOT/onboard.sh"
grep -Fq 'DID_WIZARD_REF' "$ROOT/onboard.sh"
echo 'RELEASE_CONTRACT_TESTS=PASS'
