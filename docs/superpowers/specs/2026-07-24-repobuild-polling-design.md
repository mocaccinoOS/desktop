# Retry-safe RepoBuild polling

## Problem

`.github/luet-k8s.sh` recreates a failed `RepoBuild` and immediately polls its
status. During the Kubernetes deletion/recreation window, `kubectl get` can
temporarily return no object or an object with no `status.state`. The current
script exits under `set -e` or falls through to `unknown state`, causing the
GitHub workflow to fail before the replacement build produces a result.

## Design

Add a small `job_state` helper in `.github/luet-k8s.sh`. It reads the named
`RepoBuild` status, suppresses transient `kubectl get` errors, and normalizes
missing or empty state to `null`.

The build flow will poll this helper until the controller reports one of the
only terminal states: `Succeeded` or `Failed`. Any other state, including
`null` during creation, remains pending and is retried. The loop has a bounded
deadline and reports the final observed state if it expires.

The existing terminal behavior stays unchanged: a succeeded build is deleted;
a failed build exits non-zero.

## Regression coverage

Add a shell regression test with mocked `kubectl`, `luet`, and `sleep`. The
mock sequence covers a pre-existing failed resource, deletion, creation,
missing/empty status, `Running`, and `Succeeded`. The test asserts that the
wrapper waits through the transient states and exits successfully. It requires
no cluster, registry, or real package tree.

## Scope

Only the Desktop scheduler wrapper and its new regression test change. The
Kubernetes controller, package definitions, and Luet solver remain untouched.
