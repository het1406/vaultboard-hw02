# Test matrix — observed status, November 20, 2026 ET

No Android release runtime test is marked passed. Action and expectation are described in the original assignment and README release checklist.

| ID | Action | Expected | Observed / status |
|---|---|---|---|
| T01 | Cold launch | Correct behavior under assignment requirements | NOT RUN — Android/device or production setup pending |
| T02 | Valid registration | Correct behavior under assignment requirements | NOT RUN — Android/device or production setup pending |
| T03 | Five-field profile | Correct behavior under assignment requirements | NOT RUN — Android/device or production setup pending |
| T04 | Existing-user login | Correct behavior under assignment requirements | NOT RUN — Android/device or production setup pending |
| T05 | Invalid email | Correct behavior under assignment requirements | PASS — widget invalid-email feedback |
| T06 | Weak password | Correct behavior under assignment requirements | NOT RUN — Android/device or production setup pending |
| T07 | Password mismatch | Correct behavior under assignment requirements | PASS — widget confirmation mismatch |
| T08 | Logout | Correct behavior under assignment requirements | NOT RUN — Android/device or production setup pending |
| T09 | Relaunch | Correct behavior under assignment requirements | NOT RUN — Android/device or production setup pending |
| T10 | Create message | Correct behavior under assignment requirements | PARTIAL — emulator SDK create passed; Android pending |
| T11 | Read messages | Correct behavior under assignment requirements | PARTIAL — emulator SDK read passed; Android pending |
| T12 | Second-client stream | Correct behavior under assignment requirements | PARTIAL — two SDK clients passed; Android second-device pending |
| T13 | Edit own message | Correct behavior under assignment requirements | PARTIAL — emulator same-document update passed |
| T14 | Delete own message | Correct behavior under assignment requirements | PARTIAL — emulator delete preserved unrelated post |
| T15 | Signed-out read | Correct behavior under assignment requirements | PASS — signed-out SDK permission denied |
| T16 | Other user edit | Correct behavior under assignment requirements | PASS — cross-user SDK update denied |
| T17 | Other user delete | Correct behavior under assignment requirements | PASS — cross-user SDK deletion denied |
| T18 | Forged author | Correct behavior under assignment requirements | PASS — forged UID denied |
| T19 | Rapid double tap | Correct behavior under assignment requirements | NOT RUN — Android/device or production setup pending |
| T20 | Repeat/retry | Correct behavior under assignment requirements | PARTIAL — concurrent/repeated receipt transaction passed; process restart pending |
| T21 | Empty board | Correct behavior under assignment requirements | NOT RUN — Android/device or production setup pending |
| T22 | Offline behavior | Correct behavior under assignment requirements | NOT VERIFIED — disableNetwork did not force transaction failure; real outage needed |
| T23 | Reconnect | Correct behavior under assignment requirements | NOT RUN — actual outage and reconnect pending |
| T24 | Emulator isolation | Correct behavior under assignment requirements | PARTIAL — demo project and localhost enforced; production comparison pending |
| T25 | Rules tests | Correct behavior under assignment requirements | PASS — rules suite; see captured output |
| T26 | Release install | Correct behavior under assignment requirements | NOT RUN — Android/device or production setup pending |
| T27 | Release CRUD | Correct behavior under assignment requirements | NOT RUN — Android/device or production setup pending |
| T28 | Session after reboot | Correct behavior under assignment requirements | NOT RUN — Android/device or production setup pending |
| T29 | Clear app data | Correct behavior under assignment requirements | NOT RUN — Android/device or production setup pending |
| T30 | Stream disposal | Correct behavior under assignment requirements | PARTIAL — StreamBuilder cancellation test; app navigation pending |
