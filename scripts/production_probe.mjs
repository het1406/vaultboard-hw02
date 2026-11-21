// Explicitly authorized synthetic production smoke tests. Never log credentials.
import fs from 'node:fs';
import crypto from 'node:crypto';
import {initializeApp} from 'firebase/app';
import {getAuth,createUserWithEmailAndPassword,signInWithEmailAndPassword} from 'firebase/auth';
import {getFirestore,doc,setDoc,getDoc,getDocs,collection,updateDoc,deleteDoc,runTransaction,onSnapshot,serverTimestamp} from 'firebase/firestore';
if(process.argv[2]!=='--production')throw new Error('Use --production explicitly');
const command=process.argv[3]||'inspect';
const config=JSON.parse(fs.readFileSync('android/app/google-services.json'));
const app=initializeApp({projectId:config.project_info.project_id,apiKey:config.client[0].api_key[0].current_key,appId:config.client[0].client_info.mobilesdk_app_id});
const auth=getAuth(app),db=getFirestore(app);
const credentialsPath='../evidence/private-test-accounts.json';
let accounts=fs.existsSync(credentialsPath)?JSON.parse(fs.readFileSync(credentialsPath)):{};
if(!accounts.bob){accounts.bob={email:`vaultboard-bob-${Date.now()}@example.test`,password:crypto.randomBytes(18).toString('base64url')};fs.writeFileSync(credentialsPath,JSON.stringify(accounts),{mode:0o600});}
const account=accounts.bob;
try{await signInWithEmailAndPassword(auth,account.email,account.password);}catch(e){if(!['auth/invalid-credential','auth/user-not-found'].includes(e.code))throw e;await createUserWithEmailAndPassword(auth,account.email,account.password);}
const uid=auth.currentUser.uid,profile=doc(db,'users',uid);
if(!(await getDoc(profile)).exists())await setDoc(profile,{uid,firstName:'Bob',lastName:'Tester',role:'member',registrationDateTime:serverTimestamp()});
console.log('Production authenticated synthetic client ready; profile fields:',Object.keys((await getDoc(profile)).data()).sort().join(', '));
const id='production-live-probe';
if(command==='signed-out'){
 const guest=initializeApp({projectId:config.project_info.project_id,apiKey:config.client[0].api_key[0].current_key,appId:config.client[0].client_info.mobilesdk_app_id},'guest');
 try{await getDocs(collection(getFirestore(guest),'messages'));throw new Error('SECURITY FAILURE signed-out read');}catch(e){if(e.code!=='permission-denied')throw e;console.log('PASS signed-out read',e.code);}
}else if(command==='create'){
 await runTransaction(db,async tx=>{const receipt=doc(db,`users/${uid}/postReceipts/${id}`);if((await tx.get(receipt)).exists())return;tx.set(doc(db,'messages',id),{text:'Live from Bob: this arrives without refreshing.',authorUid:uid,authorName:'Bob Tester',createdAt:serverTimestamp(),editedAt:null});tx.set(receipt,{messageId:id,createdAt:serverTimestamp()});});
}else if(command==='edit')await updateDoc(doc(db,'messages',id),{text:'Bob edited this message live.',editedAt:serverTimestamp()});
else if(command==='delete')await deleteDoc(doc(db,'messages',id));
else if(command==='deny'){
 const other=(await getDocs(collection(db,'messages'))).docs.find(d=>d.data().authorUid!==uid);if(!other)throw new Error('Need another author message first');
 for(const [action,fn] of [['cross-user update',()=>updateDoc(other.ref,{text:'Unauthorized',editedAt:serverTimestamp()})],['cross-user delete',()=>deleteDoc(other.ref)]]){try{await fn();throw new Error('SECURITY FAILURE '+action);}catch(e){if(e.code!=='permission-denied')throw e;console.log('PASS',action,e.code);}}
}else if(command==='watch'){
 const unsubscribe=onSnapshot(collection(db,'messages'),s=>console.log(JSON.stringify({at:new Date().toISOString(),messages:s.docs.map(d=>({id:d.id,text:d.data().text,author:d.data().authorName}))})));
 setTimeout(()=>{unsubscribe();process.exit(0)},55000);
}else if(command==='inspect'){
 const docs=await getDocs(collection(db,'messages'));console.log('Messages:',JSON.stringify(docs.docs.map(d=>({id:d.id,...d.data()}))));
}
if(command!=='watch')process.exit(0);
