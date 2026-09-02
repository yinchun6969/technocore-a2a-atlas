# Technocore A2A Atlas

[中文](README.md)

A role-aware integration entry point for the **Technocore A2A v5.5.3 Action Center** signed
three-agent workflow and the **Atlas v3.9 Action Center Pixel Quest** observer dashboard.
This is a release candidate for upgrading existing DID/A2A nodes. Bare hosts
and new identities are routed to the separate bilingual local-first wizard so
the integration installer never invents, copies, or uploads a private key.

## Live acceptance evidence

- Workflow: `wf-1788182002-f0269bdf77`
- Stages: `WORKFLOW_TASK → BUILD_RESULT → CHALLENGE → REVISED_RESULT → COMPLETE`
- State: `ARTIFACT_VERIFIED`
- Evidence verified, no missing stages, no structured errors
- Merkle root: `c4153f36437243b3f143bcb68d0b8714ea09c77c24aec0bc8d7d8db388d9b596`

This verifies the signed stage bundle's internal consistency. It does not prove
continuous agent uptime or the truth of an external research conclusion.

## Deployment map

| Node | A2A role | Atlas |
| --- | --- | --- |
| Love8 | Scout / dispatch and terminal signature | No |
| Aizong | Builder / build and revision | No |
| AI2AI | Reviewer / challenge, evidence verification, human action inbox | v3.9 alert build |
| Phone/computer | SSH and browser control plane | SSH port forwarding |

Atlas remains loopback-only on `127.0.0.1:8787`. A phone or computer accesses
it through an SSH tunnel; it does not impersonate three server agents.

## Existing-node quick start

Run the non-mutating check on each existing A2A VPS:

```bash
sudo bash install.sh --check --role auto --atlas auto
```

After reviewing the detected role and every preflight result:

```bash
sudo bash install.sh --apply --role auto --atlas auto
```

The installer checks out immutable Git commits, verifies the exact HEAD, and
dispatches only the components allowed for the detected role. Check mode never
changes managed files, services, keys, rooms, or state. Apply mode operates on
one node only and never SSHes into the other two nodes.

On AI2AI, the installer also enables the local Human Action Center. Only
receipt-, Merkle-, artifact-hash-, and cross-validation-gated results enter the
P0/P1/P2 inbox. Action alerts are immediate, routine stages are folded into a
daily digest, and Atlas keeps a red Action required badge visible. Telegram
approval records intent only; it never creates a PR, changes a host, or posts
publicly. Commands: `/inbox`, `/alert act-ID`, `/ack act-ID`,
`/approve-pr act-ID`, `/snooze act-ID`, and `/close act-ID`.

## New identity path

When no A2A runtime exists, the installer stops with `ONBOARDING_REQUIRED`.
Use the pinned bilingual DID wizard to import an existing Ed25519 key or create
one locally with mode `0600`. Private-key bytes are never printed, uploaded, or
committed. Full three-host bare-metal orchestration remains a later milestone
until cross-host transaction and rollback tests are complete.

```bash
bash onboard.sh --check --lang en
bash onboard.sh --apply --lang en
```

## Phone and desktop access

```bash
ssh -N -L 8787:127.0.0.1:8787 USER@AI2AI_HOST
```

Then open `http://127.0.0.1:8787/` on the same device.

## Safety contract

- immutable A2A, Atlas, and DID-wizard source commits;
- no private-key reads, copies, or output;
- fail closed on role mismatch;
- Atlas only on the AI2AI Reviewer node;
- no mailbox cursor rewind and no synthetic `COMPLETE`;
- component-specific backups and rollback paths remain intact.

## Local checks

```bash
bash tests/test_release.sh
```

The production release still requires a clean three-Ubuntu-node installation
matrix, repeat-install tests, network-failure recovery, and Android/desktop SSH
tunnel acceptance.
