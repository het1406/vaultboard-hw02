# Technical case files

## The Ghost Editor

1. Demonstrations exercised cooperative users and visible controls, not adversarial direct database requests. Passing those happy paths cannot establish authorization.
2. Flutter button visibility guides the user. Firestore Rules evaluate every untrusted client request independently of the UI.
3. `allow read, write: if request.auth != null` grants every account write access to every matching message, without checking its owner.
4. For update/delete use `request.auth != null && request.auth.uid == resource.data.authorUid`. For create compare request.auth.uid with request.resource.data.authorUid. Updates must additionally restrict changed fields to text/editedAt, validate text and require server request time. The full production rules also validate profiles and receipts.
5. Before the fix, an authenticated REST client could overwrite or delete other authors' messages, forge ownership, and damage the board without ever seeing the Flutter edit button.
6. After the fix, cross-user writes receive permission-denied; the document remains intact. Hiding controls remains useful but is no longer the security boundary.
7. Stricter schema validation and immutable ownership improve integrity but require maintaining rules alongside the schema and testing migrations. Names cannot currently be changed retrospectively.
8. The actual emulator tests passed cross-user update/delete denial, forged UID denial, and authorized CRUD. See `rules_test/security.test.mjs` and the evidence report. This is direct SDK evidence independent of Flutter.

## The Runaway Dupes

1. Calling `.add()` or generating a fresh ID for each retry creates separate documents for one intended submission; a lost acknowledgement can make a committed post look failed.
2. Ordinary supported Firestore writes can queue locally offline. A transaction instead needs server connectivity and fails offline.
3. Queued writes synchronize when connectivity returns. Two writes with two IDs remain two records. A later new retry can add a third.
4. Disabling the button only protects one current UI instance. It does not survive process death, network ambiguity, or a retry later.
5. Button guards reduce taps; stable IDs collapse writes to one address; a transaction plus immutable receipt recognizes completion atomically. A stable ID alone can recreate a deleted document if blindly set later.
6. For a small team, this implementation chooses one pending payload per UID, a stable ID, and a transaction writing a receipt with the message. The shared service keeps this complexity out of widgets.
7. Trade-offs are extra reads/writes, permanent receipt storage, one pending submission at a time, unencrypted local draft text, and explicit reconnect retry. Clearing app storage can lose an unsent payload. Old acknowledged receipts must not be pruned without changing the retry guarantee.
8. Run simultaneous transactions with one ID, replay the ID, delete the message, then replay it again. Disable networking for a transaction and retry with that ID after reconnecting. A naive comparison can perform two fresh-ID adds and count two documents.
9. Actual tests confirm one message after concurrent/repeated submission and zero after a late replay following deletion. A first run exposed permission-denied in the competing transaction; a server receipt verification fixed it, and the repeated test passed. This is SDK/emulator evidence, not proof of Android rapid-tap or process-restart behavior; those runtime checks remain pending.
