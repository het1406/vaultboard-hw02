import {readFileSync} from 'node:fs';
import {before,after,beforeEach,test} from 'node:test';
import assert from 'node:assert/strict';
import {initializeTestEnvironment,assertFails,assertSucceeds} from '@firebase/rules-unit-testing';
import {doc,setDoc,getDoc,updateDoc,deleteDoc,writeBatch,serverTimestamp,runTransaction,collection,getDocs,onSnapshot,disableNetwork,enableNetwork} from 'firebase/firestore';
let env,a,b,guest;
const profile=(uid)=>({uid,firstName:uid,lastName:'Tester',role:'member',registrationDateTime:serverTimestamp()});
const message=(uid='alice')=>({text:'Hello board',authorUid:uid,authorName:uid+' Tester',createdAt:serverTimestamp(),editedAt:null});
async function post(db,id='one',uid='alice'){
 try { return await runTransaction(db,async tx=>{
  const receipt=doc(db,`users/${uid}/postReceipts/${id}`);
  if((await tx.get(receipt)).exists())return;
  tx.set(doc(db,'messages',id),message(uid));
  tx.set(receipt,{messageId:id,createdAt:serverTimestamp()});
 }); } catch(e) { if(e.code !== 'permission-denied' || !(await getDoc(doc(db,`users/${uid}/postReceipts/${id}`))).exists()) throw e; }
}
before(async()=>{env=await initializeTestEnvironment({projectId:'demo-vaultboard',firestore:{host:'127.0.0.1',port:8080,rules:readFileSync('firestore.rules','utf8')}});a=env.authenticatedContext('alice').firestore();b=env.authenticatedContext('bob').firestore();guest=env.unauthenticatedContext().firestore();});
beforeEach(async()=>{await env.clearFirestore();await setDoc(doc(a,'users/alice'),profile('alice'));await setDoc(doc(b,'users/bob'),profile('bob'));});
after(async()=>{await env.cleanup();});
test('authorized create/read/update/delete',async()=>{await assertSucceeds(post(a));await assertSucceeds(getDoc(doc(a,'messages/one')));await assertSucceeds(updateDoc(doc(a,'messages/one'),{text:'Edited',editedAt:serverTimestamp()}));await assertSucceeds(deleteDoc(doc(a,'messages/one')));});
test('signed-out read denied',async()=>{await post(a);await assertFails(getDoc(doc(guest,'messages/one')));});
test('cross-user update and delete denied',async()=>{await post(a);await assertFails(updateDoc(doc(b,'messages/one'),{text:'Attack',editedAt:serverTimestamp()}));await assertFails(deleteDoc(doc(b,'messages/one')));});
test('forged author denied',async()=>{const batch=writeBatch(b);batch.set(doc(b,'messages/forged'),message('alice'));batch.set(doc(b,'users/bob/postReceipts/forged'),{messageId:'forged',createdAt:serverTimestamp()});await assertFails(batch.commit());});
test('profiles private, roles fixed, UID enforced',async()=>{await assertFails(getDoc(doc(b,'users/alice')));await assertFails(getDoc(doc(guest,'users/alice')));await assertFails(updateDoc(doc(a,'users/alice'),{role:'admin'}));await assertFails(setDoc(doc(a,'users/other'),profile('other')));});
test('ownership and creation timestamps immutable',async()=>{await post(a);await assertFails(updateDoc(doc(a,'messages/one'),{authorUid:'bob'}));await assertFails(updateDoc(doc(a,'messages/one'),{createdAt:serverTimestamp()}));await assertFails(updateDoc(doc(a,'messages/one'),{authorName:'Someone else'}));});
test('invalid text, extra fields, and device timestamps denied',async()=>{await post(a);for(const text of ['', '   ', 'x'.repeat(2001)]){await assertFails(updateDoc(doc(a,'messages/one'),{text,editedAt:serverTimestamp()}));}await assertFails(updateDoc(doc(a,'messages/one'),{text:'ok',editedAt:new Date(0)}));await assertFails(updateDoc(doc(a,'messages/one'),{extra:true}));});
test('receipt required, immutable, cannot exist without message',async()=>{await assertFails(setDoc(doc(a,'messages/no-receipt'),message()));await assertFails(setDoc(doc(a,'users/alice/postReceipts/orphan'),{messageId:'orphan',createdAt:serverTimestamp()}));await post(a);await assertFails(deleteDoc(doc(a,'users/alice/postReceipts/one')));});
test('concurrent repeated transaction yields one message; late retry after delete stays deleted',async()=>{await Promise.all([post(a),post(a)]);assert.equal((await getDocs(collection(a,'messages'))).size,1);await post(a);assert.equal((await getDocs(collection(a,'messages'))).size,1);await deleteDoc(doc(a,'messages/one'));await post(a);assert.equal((await getDocs(collection(a,'messages'))).size,0);assert.equal((await getDoc(doc(a,'users/alice/postReceipts/one'))).exists(),true);});
test('second client receives create, edit, delete; unrelated post remains',async()=>{await post(b,'unrelated','bob');let unsubscribe;let phase=0;await new Promise((resolve,reject)=>{const timeout=setTimeout(()=>reject(new Error('stream timeout')),15000);unsubscribe=onSnapshot(collection(b,'messages'),async s=>{try{const own=s.docs.find(d=>d.id==='one');if(phase===0){phase=1;await post(a);}else if(phase===1&&own){phase=2;await updateDoc(doc(a,'messages/one'),{text:'Live edit',editedAt:serverTimestamp()});}else if(phase===2&&own?.data().text==='Live edit'){phase=3;await deleteDoc(doc(a,'messages/one'));}else if(phase===3&&!own){assert.equal(s.size,1);assert.equal(s.docs[0].id,'unrelated');clearTimeout(timeout);resolve();}}catch(e){clearTimeout(timeout);reject(e);}},reject);});unsubscribe();});

