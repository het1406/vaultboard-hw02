# Student-supplied expectations

Received from Het Jani on November 22, 2026 (Eastern Time), after the original implementation tests. These statements are preserved as supplied for a subsequent comparison; they are not backdated as pre-development predictions.

1. **Close and reopen:** I think I would still be signed in because Firebase Authentication usually keeps session tokens saved locally on the device unless you explicitly sign out. I think my posted messages would still show up on the board because they are stored in Cloud Firestore rather than only in memory.

2. **Restart the phone:** I think I would still be signed in after a reboot since local auth state normally survives a restart, though the splash screen will run Firebase initialization again on cold launch. I’m not sure if anything in-flight would be lost if the phone restarted right mid-action, but saved messages and accounts should still be there.

3. **Clear the app’s stored data:** I think my login would get wiped out and send me back to the sign-in flow because clearing app storage removes local cached session data on the device. My messages already posted online would still exist in Firestore because they live on the server, not just in local app storage.

4. **Post without internet:** I think the app would either show an error or queue/hold the write locally if Firestore offline persistence is active, while a network-dependent check or request might fail or wait. I’m not completely sure how my exact retry/idempotency logic behaves when there is zero connection until I see it run.

5. **Reconnect:** I think the pending message would either sync up once the connection comes back or succeed when retried with the same submission ID. I think duplicates could not happen because using a stable message ID or receipt check is supposed to make repeated attempts map to the same logical post instead of creating a second document.
