# Test matrix — observed status, November 20, 2026 ET

The final release SHA-256 is e052a063f73f938bd45461ec5b579b2adaa2960bc01e581617aaeec3fd003612. See the evidence PDF for actual screenshots and the exact scope of earlier-build persistence tests.

| ID | Action | Expected | Observed / status |
|---|---|---|---|
| T01 | Cold launch | Correct behavior under assignment requirements | PASS — final cold launch and splash recording |
| T02 | Valid registration | Correct behavior under assignment requirements | PASS — final Android registration |
| T03 | Five-field profile | Correct behavior under assignment requirements | PASS — real five-field production profile; Console screenshot pending |
| T04 | Existing-user login | Correct behavior under assignment requirements | PASS — final Android sign-in |
| T05 | Invalid email | Correct behavior under assignment requirements | PASS — widget invalid-email feedback |
| T06 | Weak password | Correct behavior under assignment requirements | PASS — earlier release weak-password validation |
| T07 | Password mismatch | Correct behavior under assignment requirements | PASS — widget confirmation mismatch |
| T08 | Logout | Correct behavior under assignment requirements | PASS — final sign-out returned to login |
| T09 | Relaunch | Correct behavior under assignment requirements | PASS — signed-in relaunch |
| T10 | Create message | Correct behavior under assignment requirements | PASS — final Android create + production read |
| T11 | Read messages | Correct behavior under assignment requirements | PASS — final Android board |
| T12 | Second-client stream | Correct behavior under assignment requirements | PASS — two independent authenticated clients, snapshot logs |
| T13 | Edit own message | Correct behavior under assignment requirements | PASS — final Android same-ID edit + Edited indicator |
| T14 | Delete own message | Correct behavior under assignment requirements | PASS — final delete preserved Bob message |
| T15 | Signed-out read | Correct behavior under assignment requirements | PASS — signed-out SDK permission denied |
| T16 | Other user edit | Correct behavior under assignment requirements | PASS — cross-user SDK update denied |
| T17 | Other user delete | Correct behavior under assignment requirements | PASS — cross-user SDK deletion denied |
| T18 | Forged author | Correct behavior under assignment requirements | PASS — forged UID denied |
| T19 | Rapid double tap | Correct behavior under assignment requirements | PASS — repeated Android taps yielded one document |
| T20 | Repeat/retry | Correct behavior under assignment requirements | PASS — concurrent/repeated SDK writes and production late replay |
| T21 | Empty board | Correct behavior under assignment requirements | PASS — final intentional empty board |
| T22 | Offline behavior | Correct behavior under assignment requirements | PASS — earlier APK offline pending post survived process restart |
| T23 | Reconnect | Correct behavior under assignment requirements | PASS — earlier APK reconnect/retry produced one document |
| T24 | Emulator isolation | Correct behavior under assignment requirements | PASS — demo project/local endpoints; production collections compared |
| T25 | Rules tests | Correct behavior under assignment requirements | PASS — rules suite; see captured output |
| T26 | Release install | Correct behavior under assignment requirements | PASS — signed final APK installed and launched |
| T27 | Release CRUD | Correct behavior under assignment requirements | PASS — final APK CRUD and live observer |
| T28 | Session after reboot | Correct behavior under assignment requirements | PASS — earlier APK Android reboot retained auth and messages |
| T29 | Clear app data | Correct behavior under assignment requirements | PASS — final app data cleared; new authentication required |
| T30 | Stream disposal | Correct behavior under assignment requirements | PASS — actual BoardScreen one listener and cancellation |
