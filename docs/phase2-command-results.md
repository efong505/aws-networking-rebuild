# Phase 2 command execution index

Sanitized execution metadata from retained private SSM results. Successful fault commands mean that an explicit expected-failure assertion passed; they do not mean connectivity succeeded. The two DNS-association attempts failed their expectations. See phase2-evidence.md for interpretation and limitations.


| Check | UTC start | Command result |
|---|---|---|
| baseline-a | 10/28/2026 04:29:32 | Success / exit 0 |
| baseline-b | 10/28/2026 04:29:44 | Success / exit 0 |
| route-fault-a | 10/28/2026 04:30:04 | Success / exit 0 |
| route-fault-b | 10/28/2026 04:30:12 | Success / exit 0 |
| route-restored-a | 10/28/2026 04:30:45 | Success / exit 0 |
| route-restored-b | 10/28/2026 04:30:57 | Success / exit 0 |
| dns-fault-b | 10/28/2026 04:32:00 | Failed / exit 1 |
| dns-fault-confirmed-b | 10/28/2026 04:35:39 | Failed / exit 1 |
| dns-record-fault-b | 10/28/2026 04:38:45 | Success / exit 0 |
| dns-after-restore-diagnostics | 10/28/2026 04:40:08 | Success / exit 0 |
| soa-cache-comparison | 10/28/2026 04:42:57 | Success / exit 0 |
| recovery-wait-3 | 10/28/2026 04:44:26 | Success / exit 0 |
| final-probe-a | 10/28/2026 11:53:14 | Success / exit 0 |
| final-probe-b | 10/28/2026 11:53:26 | Success / exit 0 |
