import {initializeApp} from 'firebase/app';
import {getAuth,connectAuthEmulator,createUserWithEmailAndPassword,signInWithEmailAndPassword} from 'firebase/auth';
import {getFirestore,connectFirestoreEmulator,doc,setDoc,getDoc,serverTimestamp,runTransaction} from 'firebase/firestore';
const app=initializeApp({projectId:'demo-vaultboard',apiKey:'demo-key',appId:'demo-vaultboard'});
const auth=getAuth(app);connectAuthEmulator(auth,'http://127.0.0.1:9099',{disableWarnings:true});
const db=getFirestore(app);connectFirestoreEmulator(db,'127.0.0.1',8080);
for(const firstName of ['Alice','Bob']){
 const email=firstName.toLowerCase()+'@vaultboard.test';
 let user;try{user=(await createUserWithEmailAndPassword(auth,email,'DemoOnly123!')).user;}catch(e){if(e.code!=='auth/email-already-in-use')throw e;user=(await signInWithEmailAndPassword(auth,email,'DemoOnly123!')).user;}
 const profile=doc(db,'users',user.uid);if(!(await getDoc(profile)).exists())await setDoc(profile,{uid:user.uid,firstName,lastName:'Tester',role:'member',registrationDateTime:serverTimestamp()});
 const id='seed-'+firstName.toLowerCase();
 await runTransaction(db,async tx=>{const receipt=doc(db,`users/${user.uid}/postReceipts/${id}`);if((await tx.get(receipt)).exists())return;tx.set(doc(db,'messages',id),{text:`Hello from ${firstName}. Emulator-only demonstration.`,authorUid:user.uid,authorName:firstName+' Tester',createdAt:serverTimestamp(),editedAt:null});tx.set(receipt,{messageId:id,createdAt:serverTimestamp()});});
 console.log('Verified emulator profile and message:',firstName,(await getDoc(profile)).exists(),(await getDoc(doc(db,'messages',id))).exists());
}
process.exit(0);
