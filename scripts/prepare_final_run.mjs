import fs from 'node:fs';
import crypto from 'node:crypto';
import {initializeApp} from 'firebase/app';
import {getAuth,signInWithEmailAndPassword} from 'firebase/auth';
import {getFirestore,doc,deleteDoc} from 'firebase/firestore';
if(process.argv[2]!=='--production')throw new Error('Explicit --production required');
const c=JSON.parse(fs.readFileSync('android/app/google-services.json'));
const app=initializeApp({projectId:c.project_info.project_id,apiKey:c.client[0].api_key[0].current_key,appId:c.client[0].client_info.mobilesdk_app_id});
const auth=getAuth(app),db=getFirestore(app);
const path='../evidence/private-test-accounts.json';const a=JSON.parse(fs.readFileSync(path));
// Only the two exact synthetic messages created during this task are removed.
await signInWithEmailAndPassword(auth,a.bob.email,a.bob.password);await deleteDoc(doc(db,'messages','production-live-probe'));
await signInWithEmailAndPassword(auth,a.alice.email,a.alice.password);await deleteDoc(doc(db,'messages','qIFruZxzf2GbmCePENKO'));
a.alicePrevious=a.alice;a.alice={email:`vaultboard-final-${Date.now()}@example.test`,password:crypto.randomBytes(12).toString('hex')};fs.writeFileSync(path,JSON.stringify(a),{mode:0o600});
console.log('Removed only two known synthetic messages; preserved receipts. Prepared new registration credentials locally.');
