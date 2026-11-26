// Production end-to-end tests. No mocks: real Firebase Auth (phone OTP with the official test numbers),
// real Firestore + security rules, real Cloud Functions, real Cloud Scheduler, real VideoSDK API.
//
//   ADMIN_TOKEN=$(gcloud auth print-access-token --account=<owner>) node test/prod/prod_e2e.mjs
//
// ADMIN_TOKEN (project owner) is used only to (a) plant a stale session for the scheduler test and
// (b) clean up test data at the end. Everything else runs as the signed-in test users.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { randomUUID } from 'node:crypto';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const gs = JSON.parse(readFileSync(join(root, 'android/app/google-services.json'), 'utf8'));
const P = gs.project_info.project_id;
const KEY = gs.client[0].api_key[0].current_key;
const REGION = 'asia-south1';
const ADMIN = process.env.ADMIN_TOKEN;
// Firebase *test* phone numbers + their fixed OTP come from the environment, never from the repo:
//   TEST_PHONES="+91xxxxxxxxxx,+91xxxxxxxxxx,+91xxxxxxxxxx,+91xxxxxxxxxx" TEST_OTP=<code>
// Use four numbers reserved for these tests: the script deletes the accounts it signs in with.
const PHONES = (process.env.TEST_PHONES || '').split(',').map((x) => x.trim()).filter(Boolean);
const OTP = process.env.TEST_OTP;
if (PHONES.length < 4 || !OTP) {
  console.error('Set TEST_PHONES (4 comma-separated Firebase test numbers) and TEST_OTP before running.');
  process.exit(2);
}
const FS = `https://firestore.googleapis.com/v1/projects/${P}/databases/(default)/documents`;
const FN = `https://${REGION}-${P}.cloudfunctions.net`;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ---------- tiny helpers ----------
const enc = (v) =>
  v === null ? { nullValue: null }
  : typeof v === 'string' ? { stringValue: v }
  : typeof v === 'boolean' ? { booleanValue: v }
  : Number.isInteger(v) ? { integerValue: String(v) }
  : { doubleValue: v };
const encFields = (o) => Object.fromEntries(Object.entries(o).map(([k, v]) => [k, enc(v)]));
const dec = (v) =>
  'stringValue' in v ? v.stringValue : 'integerValue' in v ? Number(v.integerValue) : 'doubleValue' in v ? v.doubleValue
  : 'booleanValue' in v ? v.booleanValue : 'timestampValue' in v ? v.timestampValue : 'nullValue' in v ? null
  : 'arrayValue' in v ? (v.arrayValue.values || []).map(dec) : v;
const decDoc = (d) => ({ _id: d.name.split('/').pop(), ...Object.fromEntries(Object.entries(d.fields || {}).map(([k, v]) => [k, dec(v)])) });

async function http(method, url, { token, body } = {}) {
  const r = await fetch(url, {
    method,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await r.text();
  let json; try { json = JSON.parse(text); } catch { json = text; }
  return { status: r.status, json };
}

// ---------- real phone sign-in (what the app does) ----------
async function signIn(phone) {
  const send = await http('POST', `https://identitytoolkit.googleapis.com/v1/accounts:sendVerificationCode?key=${KEY}`,
    { body: { phoneNumber: phone, recaptchaToken: 'test' } });
  if (!send.json.sessionInfo) throw new Error(`sendVerificationCode failed: ${JSON.stringify(send.json)}`);
  const r = await http('POST', `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPhoneNumber?key=${KEY}`,
    { body: { sessionInfo: send.json.sessionInfo, code: OTP } });
  if (!r.json.idToken) throw new Error(`signIn failed: ${JSON.stringify(r.json)}`);
  return { phone, token: r.json.idToken, uid: r.json.localId, isNew: r.json.isNewUser };
}

const call = async (user, name, data) => {
  const r = await http('POST', `${FN}/${name}`, { token: user?.token, body: { data } });
  return r.json.error ? { error: r.json.error } : r.json.result;
};
const getDoc = async (user, path) => {
  const r = await http('GET', `${FS}/${path}`, { token: user.token });
  return r.status === 200 ? decDoc(r.json) : { _status: r.status };
};
const listCol = async (user, path) => {
  const r = await http('GET', `${FS}/${path}`, { token: user.token });
  return r.status === 200 ? (r.json.documents || []).map(decDoc) : { _status: r.status };
};
const createUserDoc = (user, id, fields) =>
  http('POST', `${FS}/users?documentId=${id}`, { token: user.token, body: { fields: encFields(fields) } });
const patchUserDoc = (user, id, fields) =>
  http('PATCH', `${FS}/users/${id}?${Object.keys(fields).map((k) => `updateMask.fieldPaths=${k}`).join('&')}`,
    { token: user.token, body: { fields: encFields(fields) } });
const setPresence = (user, sid, who, fields) =>
  http('POST', `${FS}:commit`, { token: user.token, body: { writes: [{
    update: { name: `projects/${P}/databases/(default)/documents/sessions/${sid}/presence/${who}`, fields: encFields(fields) },
    updateTransforms: [{ fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' }] }] } });
const sendMessage = (user, sid, fields, { serverTime = true } = {}) =>
  http('POST', `${FS}:commit`, {
    token: user.token,
    body: {
      writes: [{
        update: { name: `projects/${P}/databases/(default)/documents/sessions/${sid}/messages/${randomUUID()}`, fields: encFields(fields) },
        ...(serverTime ? { updateTransforms: [{ fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' }] } : {}),
        currentDocument: { exists: false },
      }],
    },
  });
async function waitFor(fn, { timeout = 45000, every = 1500, label = 'condition' } = {}) {
  const end = Date.now() + timeout; let last;
  while (Date.now() < end) { last = await fn(); if (last) return last; await sleep(every); }
  throw new Error(`timed out waiting for ${label}`);
}
const assert = (c, msg) => { if (!c) throw new Error(msg); };
const eq = (a, b, msg) => assert(JSON.stringify(a) === JSON.stringify(b), `${msg}: expected ${JSON.stringify(b)}, got ${JSON.stringify(a)}`);
const denied = (r, msg) => assert(r.status === 403, `${msg}: expected 403, got ${r.status} ${JSON.stringify(r.json).slice(0, 120)}`);
const ok = (r, msg) => assert(r.status === 200, `${msg}: expected 200, got ${r.status} ${JSON.stringify(r.json).slice(0, 160)}`);
const code = (r, c, msg) => assert(r?.error?.status === c, `${msg}: expected ${c}, got ${JSON.stringify(r).slice(0, 160)}`);

// ---------- state shared across tests ----------
let alice, bob, ravi, sita, sid, sid2; const touched = [];
const tests = [];
const test = (name, fn) => tests.push([name, fn]);

// =========================== AUTH ===========================
test('AUTH wrong OTP is rejected', async () => {
  const send = await http('POST', `https://identitytoolkit.googleapis.com/v1/accounts:sendVerificationCode?key=${KEY}`,
    { body: { phoneNumber: PHONES[0], recaptchaToken: 'test' } });
  const r = await http('POST', `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPhoneNumber?key=${KEY}`,
    { body: { sessionInfo: send.json.sessionInfo, code: '000000' } });
  assert(r.json.error?.message?.includes('INVALID_CODE'), `expected INVALID_CODE, got ${JSON.stringify(r.json).slice(0, 150)}`);
});
test('AUTH number from a non-allowed region is blocked (no SMS sent)', async () => {
  const r = await http('POST', `https://identitytoolkit.googleapis.com/v1/accounts:sendVerificationCode?key=${KEY}`,
    { body: { phoneNumber: '+14155550100', recaptchaToken: 'test' } });
  assert(r.json.error?.message?.includes('OPERATION_NOT_ALLOWED'), `expected region block, got ${JSON.stringify(r.json).slice(0, 150)}`);
});
test('AUTH sign in as two users and two astrologers via phone OTP', async () => {
  alice = await signIn(PHONES[0]);
  bob = await signIn(PHONES[1]);
  ravi = await signIn(PHONES[2]);
  sita = await signIn(PHONES[3]);
  assert(new Set([alice.uid, bob.uid, ravi.uid, sita.uid]).size === 4, 'distinct uids expected');
});

// =========================== RULES: users ===========================
test('RULES users: unauthenticated read denied', async () => {
  const r = await http('GET', `${FS}/users/${alice.uid}`);
  assert(r.status === 401 || r.status === 403, `got ${r.status}`);
});
test('RULES users: cannot create another user\'s profile', async () => {
  denied(await createUserDoc(alice, bob.uid, { name: 'x', phone: bob.phone, role: 'user', dob: null, birthTime: null, birthPlace: null }), 'create for other uid');
});
test('RULES users: create with an unknown extra field denied', async () => {
  denied(await createUserDoc(alice, alice.uid, { name: 'x', phone: alice.phone, role: 'user', isAdmin: true }), 'extra field');
});
test('RULES users: create with 80+ char name denied', async () => {
  denied(await createUserDoc(alice, alice.uid, { name: 'n'.repeat(80), phone: alice.phone, role: 'user', dob: null, birthTime: null, birthPlace: null }), 'long name');
});
test('PROFILE new user creates own profile exactly as the app does', async () => {
  // Start from a clean slate so the test is repeatable.
  await http('DELETE', `${FS}/users/${alice.uid}`, { token: ADMIN });
  await http('DELETE', `${FS}/users/${bob.uid}`, { token: ADMIN });
  await http('DELETE', `${FS}/users/${ravi.uid}`, { token: ADMIN });
  await http('DELETE', `${FS}/users/${sita.uid}`, { token: ADMIN });
  await http('DELETE', `${FS}/astrologers/${ravi.uid}`, { token: ADMIN });
  await http('DELETE', `${FS}/astrologers/${sita.uid}`, { token: ADMIN });
  denied(await createUserDoc(alice, alice.uid, { name: 'Alice Test', phone: alice.phone, role: 'admin', dob: null, birthTime: null, birthPlace: null }), 'role admin');
  denied(await createUserDoc(alice, alice.uid, { name: 'Alice Test', phone: alice.phone, dob: null, birthTime: null, birthPlace: null }), 'missing role');
  ok(await createUserDoc(alice, alice.uid, { name: 'Alice Test', phone: alice.phone, role: 'user', dob: null, birthTime: null, birthPlace: null }), 'alice create');
  ok(await createUserDoc(bob, bob.uid, { name: 'Bob Test', phone: bob.phone, role: 'user', dob: null, birthTime: null, birthPlace: null }), 'bob create');
  ok(await createUserDoc(ravi, ravi.uid, { name: 'Ravi Astro', phone: ravi.phone, role: 'astrologer', dob: null, birthTime: null, birthPlace: null }), 'ravi create');
  ok(await createUserDoc(sita, sita.uid, { name: 'Sita Astro', phone: sita.phone, role: 'astrologer', dob: null, birthTime: null, birthPlace: null }), 'sita create');
  touched.push(`users/${alice.uid}`, `users/${bob.uid}`, `users/${ravi.uid}`, `users/${sita.uid}`);
});
test('RULES users: cannot read someone else\'s profile', async () => {
  const d = await getDoc(bob, `users/${alice.uid}`);
  eq(d._status, 403, 'bob reading alice');
});
test('PROFILE owner can read own profile', async () => {
  const d = await getDoc(alice, `users/${alice.uid}`);
  eq([d.name, d.phone], ['Alice Test', alice.phone], 'profile fields');
});
test('RULES users: changing phone number denied', async () => {
  denied(await patchUserDoc(alice, alice.uid, { phone: '+910000000000' }), 'phone change');
});
test('RULES users: adding an unknown field on update denied', async () => {
  denied(await patchUserDoc(alice, alice.uid, { role: 'admin' }), 'unknown field');
});
test('PROFILE owner completes birth details', async () => {
  ok(await patchUserDoc(alice, alice.uid, { name: 'Alice Test', dob: '1994-08-15', birthTime: '06:45', birthPlace: 'Jaipur' }), 'update');
  const d = await getDoc(alice, `users/${alice.uid}`);
  eq([d.dob, d.birthTime, d.birthPlace], ['1994-08-15', '06:45', 'Jaipur'], 'saved birth details');
});
test('RULES users: cannot delete own profile', async () => {
  denied(await http('DELETE', `${FS}/users/${alice.uid}`, { token: alice.token }), 'delete');
});

// =========================== TWO ROLES: astrologer account ===========================
test('ROLES rules: role cannot be changed after sign-up', async () => {
  denied(await patchUserDoc(alice, alice.uid, { role: 'astrologer' }), 'user -> astrologer');
  denied(await patchUserDoc(ravi, ravi.uid, { role: 'user' }), 'astrologer -> user');
});
test('ROLES functions: users cannot use astrologer functions', async () => {
  code(await call(alice, 'saveAstrologerProfile', { name: 'Fake', expertise: ['x'], languages: ['x'], experience: 1, pricePerMin: 10 }), 'PERMISSION_DENIED', 'user save profile');
  code(await call(alice, 'setAvailability', { online: true }), 'PERMISSION_DENIED', 'user availability');
  code(await call(alice, 'respondToSession', { sessionId: 'x', accept: true }), 'PERMISSION_DENIED', 'user respond');
});
test('ROLES functions: astrologers cannot book consultations', async () => code(await call(ravi, 'startSession', { astrologerId: 'a1', type: 'chat' }), 'PERMISSION_DENIED', 'astrologer booking'));
test('ASTROLOGER availability needs a profile first', async () => code(await call(ravi, 'setAvailability', { online: true }), 'FAILED_PRECONDITION', 'no profile'));
test('ASTROLOGER profile validation rejects bad input', async () => {
  const good = { name: 'Ravi Astro', expertise: ['Vedic', 'Career'], languages: ['Hindi'], experience: 7, pricePerMin: 30, about: 'Hello' };
  for (const [label, patch] of [['name too short', { name: 'R' }], ['no expertise', { expertise: [] }], ['too many languages', { languages: ['a','b','c','d','e','f','g'] }],
    ['negative experience', { experience: -1 }], ['fractional experience', { experience: 2.5 }], ['zero price', { pricePerMin: 0 }], ['absurd price', { pricePerMin: 99999 }],
    ['non-https avatar', { avatar: 'http://evil.example/x.png' }], ['huge about', { about: 'x'.repeat(501) }]]) {
    code(await call(ravi, 'saveAstrologerProfile', { ...good, ...patch }), 'INVALID_ARGUMENT', label);
  }
});
test('ASTROLOGER registers profile; appears in catalogue as offline with zero rating', async () => {
  const r = await call(ravi, 'saveAstrologerProfile', { name: 'Ravi Astro', expertise: ['Vedic', 'Career'], languages: ['Hindi', 'English'], experience: 7, pricePerMin: 30, about: 'Real astrologer for E2E' });
  eq(r.id, ravi.uid, 'id is uid'); touched.push(`astrologers/${ravi.uid}`);
  const a = await getDoc(alice, `astrologers/${ravi.uid}`);
  eq([a.uid, a.name, a.status, a.rating, a.reviews, a.pricePerMin, a.experience], [ravi.uid, 'Ravi Astro', 'offline', 0, 0, 30, 7], 'profile');
  assert(a.avatar.startsWith('https://'), 'default avatar assigned');
  const r2 = await call(sita, 'saveAstrologerProfile', { name: 'Sita Astro', expertise: ['Tarot'], languages: ['English'], experience: 3, pricePerMin: 12, about: '' });
  eq(r2.id, sita.uid, 'second astrologer'); touched.push(`astrologers/${sita.uid}`);
});
test('ASTROLOGER can edit own profile; rating/status stay server controlled', async () => {
  await call(ravi, 'saveAstrologerProfile', { name: 'Ravi Astro', expertise: ['Vedic'], languages: ['Hindi'], experience: 8, pricePerMin: 30, about: 'Updated' });
  const a = await getDoc(alice, `astrologers/${ravi.uid}`);
  eq([a.experience, a.about, a.status, a.rating], [8, 'Updated', 'offline', 0], 'edited');
  denied(await http('PATCH', `${FS}/astrologers/${ravi.uid}?updateMask.fieldPaths=rating`, { token: ravi.token, body: { fields: { rating: enc(5) } } }), 'self-rating');
  denied(await http('PATCH', `${FS}/astrologers/${ravi.uid}?updateMask.fieldPaths=status`, { token: ravi.token, body: { fields: { status: enc('online') } } }), 'direct status');
});
test('BOOKING offline real astrologer is rejected', async () => code(await call(alice, 'startSession', { astrologerId: ravi.uid, type: 'chat' }), 'FAILED_PRECONDITION', 'offline'));
test('ASTROLOGER goes online', async () => {
  eq((await call(ravi, 'setAvailability', { online: true })).status, 'online', 'online');
  eq((await getDoc(alice, `astrologers/${ravi.uid}`)).status, 'online', 'visible to users');
});


// =========================== CATALOGUE (real astrologers only) ===========================
test('CATALOGUE unauthenticated read denied', async () => {
  const r = await http('GET', `${FS}/astrologers`);
  assert(r.status === 401 || r.status === 403, `got ${r.status}`);
});
test('CATALOGUE shows only real astrologer accounts (no demo / simulated entries)', async () => {
  const list = await listCol(alice, 'astrologers');
  assert(Array.isArray(list), `list failed: ${JSON.stringify(list)}`);
  assert(list.every((a) => a.uid && a.uid === a._id), 'every astrologer must be a real account (doc id == uid)');
  const ids = list.map((a) => a._id);
  assert(ids.includes(ravi.uid) && ids.includes(sita.uid), 'registered astrologers are listed');
  for (const a of list) {
    for (const f of ['name', 'avatar', 'expertise', 'languages', 'experience', 'rating', 'reviews', 'pricePerMin', 'status', 'about'])
      assert(a[f] !== undefined, `astrologer ${a._id} missing ${f}`);
    assert(['online', 'busy', 'offline'].includes(a.status), `bad status ${a.status}`);
  }
});
test('CATALOGUE reviews are readable (empty for a new astrologer)', async () => {
  const rv = await listCol(alice, `astrologers/${ravi.uid}/reviews`);
  assert(Array.isArray(rv), 'reviews readable');
});
test('CATALOGUE clients cannot change someone else\'s price, status or reviews', async () => {
  denied(await http('PATCH', `${FS}/astrologers/${ravi.uid}?updateMask.fieldPaths=pricePerMin`, { token: alice.token, body: { fields: { pricePerMin: enc(0) } } }), 'price tamper');
  denied(await http('PATCH', `${FS}/astrologers/${sita.uid}?updateMask.fieldPaths=status`, { token: ravi.token, body: { fields: { status: enc('online') } } }), 'status tamper');
  denied(await http('POST', `${FS}/astrologers/${ravi.uid}/reviews?documentId=fake`, { token: alice.token, body: { fields: encFields({ user: 'x', rating: 5, text: 'x' }) } }), 'fake review');
});

// =========================== BOOKING VALIDATION ===========================
test('BOOKING unauthenticated rejected', async () => code(await call(null, 'startSession', { astrologerId: ravi.uid, type: 'chat' }), 'UNAUTHENTICATED', 'no token'));
test('BOOKING invalid consultation type rejected', async () => code(await call(alice, 'startSession', { astrologerId: ravi.uid, type: 'fax' }), 'INVALID_ARGUMENT', 'bad type'));
test('BOOKING unknown astrologer rejected', async () => code(await call(alice, 'startSession', { astrologerId: 'nope', type: 'chat' }), 'NOT_FOUND', 'unknown'));
test('BOOKING the old demo astrologers no longer exist or connect', async () => {
  for (const id of ['a1', 'a2', 'a3', 'a4', 'a5', 'a6']) code(await call(alice, 'startSession', { astrologerId: id, type: 'chat' }), 'NOT_FOUND', `demo ${id}`);
});
test('BOOKING offline astrologer rejected with a friendly message', async () => {
  const r = await call(alice, 'startSession', { astrologerId: sita.uid, type: 'chat' });
  code(r, 'FAILED_PRECONDITION', 'offline'); assert(r.error.message.includes('Sita Astro is offline'), `message: ${r.error.message}`);
});

// ---- real two-person chat ----
let rsid;
test('REAL CHAT alice requests Ravi; request is NOT auto-accepted and Ravi sees it', async () => {
  const r = await call(alice, 'startSession', { astrologerId: ravi.uid, type: 'chat' }); rsid = r.id; touched.push(`sessions/${rsid}`);
  await sleep(7000);
  const s = await getDoc(alice, `sessions/${rsid}`);
  eq(s.status, 'waiting', 'still waiting after the simulator delay');
  const q = await http('POST', `${FS}:runQuery`, { token: ravi.token, body: { structuredQuery: { from: [{ collectionId: 'sessions' }], where: { compositeFilter: { op: 'AND', filters: [
    { fieldFilter: { field: { fieldPath: 'astrologerId' }, op: 'EQUAL', value: { stringValue: ravi.uid } } },
    { fieldFilter: { field: { fieldPath: 'status' }, op: 'EQUAL', value: { stringValue: 'waiting' } } }] } } } } });
  const reqs = q.json.filter((x) => x.document).map((x) => decDoc(x.document));
  assert(reqs.length === 1 && reqs[0]._id === rsid, `ravi should see exactly one request, got ${reqs.length}`);
  eq([reqs[0].userName, reqs[0].userDob, reqs[0].userBirthTime, reqs[0].userBirthPlace], ['Alice Test', '1994-08-15', '06:45', 'Jaipur'], 'astrologer sees client birth details');
});
test('REAL CHAT other people cannot see or answer the request', async () => {
  eq((await getDoc(sita, `sessions/${rsid}`))._status, 403, 'other astrologer read');
  eq((await getDoc(bob, `sessions/${rsid}`))._status, 403, 'other user read');
  code(await call(sita, 'respondToSession', { sessionId: rsid, accept: true }), 'NOT_FOUND', 'other astrologer accept');
  code(await call(bob, 'respondToSession', { sessionId: rsid, accept: true }), 'PERMISSION_DENIED', 'user accept');
});
test('REAL CHAT nothing connects without the astrologer: still waiting, no messages allowed, no room issued', async () => {
  eq((await getDoc(alice, `sessions/${rsid}`)).status, 'waiting', 'still waiting (no auto-accept)');
  denied(await sendMessage(alice, rsid, { text: 'hello?', from: 'user' }), 'message before accept');
  code(await call(alice, 'getVideoSdkRoom', { sessionId: rsid }), 'FAILED_PRECONDITION', 'room before accept');
  denied(await http('POST', `${FS}/sessions?documentId=forged`, { token: alice.token, body: { fields: encFields({ userId: alice.uid, status: 'ongoing', cost: 0 }) } }), 'forge session');
  denied(await http('PATCH', `${FS}/sessions/${rsid}?updateMask.fieldPaths=status`, { token: alice.token, body: { fields: { status: enc('ongoing') } } }), 'self-accept');
  denied(await http('PATCH', `${FS}/sessions/${rsid}?updateMask.fieldPaths=cost`, { token: alice.token, body: { fields: { cost: enc(0) } } }), 'modify cost');
  denied(await http('DELETE', `${FS}/sessions/${rsid}`, { token: alice.token }), 'delete');
});
test('REAL CHAT Ravi accepts: session ongoing, Ravi becomes busy, nobody else can book him', async () => {
  const r = await call(ravi, 'respondToSession', { sessionId: rsid, accept: true });
  eq(r.status, 'ongoing', 'accepted');
  const s = await getDoc(alice, `sessions/${rsid}`); assert(s.startedAt, 'startedAt');
  eq((await getDoc(alice, `astrologers/${ravi.uid}`)).status, 'busy', 'busy');
  code(await call(bob, 'startSession', { astrologerId: ravi.uid, type: 'chat' }), 'FAILED_PRECONDITION', 'booking a busy astrologer');
  code(await call(ravi, 'respondToSession', { sessionId: rsid, accept: true }), 'FAILED_PRECONDITION', 'double accept');
  code(await call(ravi, 'setAvailability', { online: false }), 'FAILED_PRECONDITION', 'cannot go offline while busy');
});
test('REAL CHAT messages flow both ways and nobody can impersonate the other side', async () => {
  ok(await sendMessage(alice, rsid, { text: 'Namaste, will I change jobs?', from: 'user' }), 'alice -> ravi');
  ok(await sendMessage(ravi, rsid, { text: 'Namaste Alice. Jupiter supports a move.', from: 'astrologer' }), 'ravi -> alice');
  denied(await sendMessage(ravi, rsid, { text: 'pretend', from: 'user' }), 'ravi as user');
  denied(await sendMessage(alice, rsid, { text: 'pretend', from: 'astrologer' }), 'alice as astrologer');
  denied(await sendMessage(sita, rsid, { text: 'intruder', from: 'astrologer' }), 'other astrologer');
  denied(await sendMessage(bob, rsid, { text: 'intruder', from: 'user' }), 'other user');
  eq((await listCol(sita, `sessions/${rsid}/messages`))._status, 403, 'intruder read');
  await sleep(4000); // a simulator reply must NOT appear for a real astrologer
  const seenByAlice = await listCol(alice, `sessions/${rsid}/messages`), seenByRavi = await listCol(ravi, `sessions/${rsid}/messages`);
  eq(seenByAlice.length, 2, 'exactly the two human messages (no simulated reply)'); eq(seenByRavi.length, 2, 'ravi sees both');
  eq(seenByRavi.map((m) => m.from).sort(), ['astrologer', 'user'], 'roles');
});
test('REAL CHAT invalid messages denied; rapid messages keep their order', async () => {
  denied(await sendMessage(alice, rsid, { text: '', from: 'user' }), 'empty');
  denied(await sendMessage(alice, rsid, { text: 'x'.repeat(1001), from: 'user' }), 'too long');
  denied(await sendMessage(alice, rsid, { text: 'hi', from: 'user', admin: true }), 'extra field');
  denied(await sendMessage(alice, rsid, { text: 'hi', from: 'user', createdAt: '2020-01-01T00:00:00Z' }, { serverTime: false }), 'client timestamp');
  for (const t of ['one', 'two', 'three']) ok(await sendMessage(alice, rsid, { text: t, from: 'user' }), `send ${t}`);
  await sleep(1500);
  const mine = (await listCol(ravi, `sessions/${rsid}/messages`)).filter((m) => m.from === 'user').sort((a, b) => a.createdAt.localeCompare(b.createdAt)).map((m) => m.text);
  eq(mine.slice(-3), ['one', 'two', 'three'], 'order');
});
test('REAL CHAT typing / presence indicators: each side writes only its own', async () => {
  ok(await setPresence(alice, rsid, 'user', { online: true, typing: true }), 'alice typing');
  eq((await getDoc(ravi, `sessions/${rsid}/presence/user`)).typing, true, 'ravi sees alice typing');
  ok(await setPresence(ravi, rsid, 'astrologer', { online: true, typing: true }), 'ravi typing');
  eq((await getDoc(alice, `sessions/${rsid}/presence/astrologer`)).typing, true, 'alice sees ravi typing');
  denied(await setPresence(ravi, rsid, 'user', { online: true, typing: false }), 'ravi writing alice presence');
  denied(await setPresence(alice, rsid, 'astrologer', { online: true, typing: false }), 'alice writing ravi presence');
  denied(await setPresence(sita, rsid, 'astrologer', { online: true, typing: false }), 'intruder presence');
  eq((await getDoc(sita, `sessions/${rsid}/presence/user`))._status, 403, 'intruder cannot read presence');
});
test('REAL CHAT Ravi ends the consultation; Alice is billed server-side; Ravi is free again', async () => {
  await sleep(2000);
  const r = await call(ravi, 'endSession', { sessionId: rsid });
  eq([r.status, r.cost], ['completed', Math.ceil(r.durationSec / 60) * 30], 'completed and billed');
  eq((await getDoc(alice, `sessions/${rsid}`)).status, 'completed', 'alice sees completed');
  eq((await getDoc(alice, `astrologers/${ravi.uid}`)).status, 'online', 'ravi back online');
  denied(await sendMessage(ravi, rsid, { text: 'late', from: 'astrologer' }), 'message after end');
  code(await call(sita, 'endSession', { sessionId: rsid }), 'NOT_FOUND', 'outsider end');
});

// ---- decline / cancel ----
test('REAL DECLINE Ravi declines a request: rejected, free, Ravi stays online, user can retry', async () => {
  const r = await call(alice, 'startSession', { astrologerId: ravi.uid, type: 'voice' }); touched.push(`sessions/${r.id}`);
  const d = await call(ravi, 'respondToSession', { sessionId: r.id, accept: false });
  eq([d.status, d.cost, d.durationSec], ['rejected', 0, 0], 'rejected');
  eq((await getDoc(alice, `sessions/${r.id}`)).status, 'rejected', 'alice sees declined');
  eq((await getDoc(alice, `astrologers/${ravi.uid}`)).status, 'online', 'ravi unaffected');
  code(await call(ravi, 'respondToSession', { sessionId: r.id, accept: true }), 'FAILED_PRECONDITION', 'accepting a declined request');
  const again = await call(alice, 'startSession', { astrologerId: ravi.uid, type: 'voice' }); touched.push(`sessions/${again.id}`);
  assert(again.id, 'alice can request again after a decline');
  const c = await call(alice, 'endSession', { sessionId: again.id });
  eq(c.status, 'cancelled', 'user cancels own waiting request');
  code(await call(ravi, 'respondToSession', { sessionId: again.id, accept: true }), 'FAILED_PRECONDITION', 'accepting a cancelled request');
});
test('REAL ACCEPT while offline is refused', async () => {
  const r = await call(alice, 'startSession', { astrologerId: ravi.uid, type: 'chat' }); touched.push(`sessions/${r.id}`);
  await call(ravi, 'setAvailability', { online: false });
  code(await call(ravi, 'respondToSession', { sessionId: r.id, accept: true }), 'FAILED_PRECONDITION', 'offline accept');
  await call(alice, 'endSession', { sessionId: r.id });
  await call(ravi, 'setAvailability', { online: true });
});

// ---- real voice/video: both parties get the SAME real VideoSDK room ----
test('REAL VIDEO both parties get a valid token for the SAME VideoSDK room (concurrent join)', async () => {
  const r = await call(alice, 'startSession', { astrologerId: ravi.uid, type: 'video' }); const vsid = r.id; touched.push(`sessions/${vsid}`);
  code(await call(ravi, 'getVideoSdkRoom', { sessionId: vsid }), 'FAILED_PRECONDITION', 'room before accept');
  eq((await call(ravi, 'respondToSession', { sessionId: vsid, accept: true })).status, 'ongoing', 'accepted');
  const [a, b] = await Promise.all([call(alice, 'getVideoSdkRoom', { sessionId: vsid }), call(ravi, 'getVideoSdkRoom', { sessionId: vsid })]);
  assert(a.token && b.token && a.meetingId, `tokens: ${JSON.stringify([a, b]).slice(0, 160)}`);
  eq(a.meetingId, b.meetingId, 'same room for both');
  eq((await getDoc(alice, `sessions/${vsid}`)).meetingId, a.meetingId, 'persisted');
  for (const tkn of [a.token, b.token]) {
    const v = await fetch(`https://api.videosdk.live/v2/rooms/validate/${a.meetingId}`, { headers: { Authorization: tkn } });
    assert(v.status === 200, `VideoSDK rejected token: ${v.status}`);
  }
  code(await call(sita, 'getVideoSdkRoom', { sessionId: vsid }), 'NOT_FOUND', 'outsider room');
  code(await call(bob, 'getVideoSdkRoom', { sessionId: vsid }), 'NOT_FOUND', 'other user room');
  await sleep(2000);
  const e = await call(alice, 'endSession', { sessionId: vsid }); // the USER can end too
  eq([e.status, e.cost > 0], ['completed', true], 'user ended video');
  eq((await getDoc(alice, `astrologers/${ravi.uid}`)).status, 'online', 'ravi free again');
});

// ---- astrologer-side history ----
test('ASTROLOGER HISTORY Ravi sees only his own consultations (completed, rejected, cancelled)', async () => {
  const run = (u, f) => http('POST', `${FS}:runQuery`, { token: u.token, body: { structuredQuery: { from: [{ collectionId: 'sessions' }], where: { fieldFilter: { field: { fieldPath: f }, op: 'EQUAL', value: { stringValue: u.uid } } } } } });
  const mine = (await run(ravi, 'astrologerId')).json.filter((x) => x.document).map((x) => decDoc(x.document));
  assert(mine.length >= 4 && mine.every((s) => s.astrologerId === ravi.uid), `ravi history ${mine.length}`);
  const st = new Set(mine.map((s) => s.status)); for (const x of ['completed', 'rejected', 'cancelled']) assert(st.has(x), `missing ${x}`);
  eq((await run(sita, 'astrologerId')).json.filter((x) => x.document).length, 0, 'sita has none');
  const peek = await run({ token: sita.token, uid: ravi.uid }, 'astrologerId');
  assert(peek.status === 403 || peek.json.every((x) => !x.document), 'sita must not read ravi\'s sessions');
});

// ---- a stuck call frees the astrologer ----
test('SCHEDULER an abandoned ongoing call is closed and the astrologer is freed', async () => {
  const old = new Date(Date.now() - 4 * 3600 * 1000).toISOString(); const id = `stuck-${randomUUID().slice(0, 8)}`; touched.push(`sessions/${id}`);
  ok(await http('PATCH', `${FS}/sessions/${id}`, { token: ADMIN, body: { fields: { userId: enc(alice.uid), userName: enc('Alice Test'), astrologerId: enc(ravi.uid), astrologerName: enc('Ravi Astro'), astrologerAvatar: enc(''),
    type: enc('chat'), status: enc('ongoing'), pricePerMin: enc(30), durationSec: enc(0), cost: enc(0), createdAt: { timestampValue: old }, startedAt: { timestampValue: old } } } }), 'plant stuck');
  ok(await http('PATCH', `${FS}/astrologers/${ravi.uid}?updateMask.fieldPaths=status`, { token: ADMIN, body: { fields: { status: enc('busy') } } }), 'ravi busy');
  const job = await fetch(`https://cloudscheduler.googleapis.com/v1/projects/${P}/locations/${REGION}/jobs/firebase-schedule-expireStaleSessions-${REGION}:run`, { method: 'POST', headers: { Authorization: `Bearer ${ADMIN}`, 'Content-Type': 'application/json', 'x-goog-user-project': P }, body: '{}' });
  assert(job.status === 200, `scheduler: ${job.status}`);
  const s = await waitFor(async () => { const d = await getDoc(alice, `sessions/${id}`); return d.status === 'completed' ? d : null; }, { label: 'stuck call closed', timeout: 90000, every: 3000 });
  assert(s.cost > 0, 'billed for the time');
  eq((await getDoc(alice, `astrologers/${ravi.uid}`)).status, 'online', 'ravi freed');
});


test('BOOKING parallel double-tap creates only ONE active session', async () => {
  const res = await Promise.all([call(alice, 'startSession', { astrologerId: ravi.uid, type: 'chat' }), call(alice, 'startSession', { astrologerId: ravi.uid, type: 'chat' })]);
  const ids = res.filter((x) => x.id).map((x) => x.id); ids.forEach((i) => touched.push(`sessions/${i}`));
  const blocked = res.filter((x) => x.error).length;
  for (const i of ids) await call(alice, 'endSession', { sessionId: i });
  eq([ids.length, blocked], [1, 1], 'one created, one blocked');
});

// =========================== HISTORY ===========================
test('HISTORY alice sees only her own completed/cancelled sessions with correct data', async () => {
  const q = (u) => http('POST', `${FS}:runQuery`, { token: u.token, body: { structuredQuery: { from: [{ collectionId: 'sessions' }], where: { fieldFilter: { field: { fieldPath: 'userId' }, op: 'EQUAL', value: { stringValue: u.uid } } } } } });
  const a = (await q(alice)).json.filter((x) => x.document).map((x) => decDoc(x.document));
  assert(a.length >= 3 && a.every((s) => s.userId === alice.uid), 'alice history');
  assert(a.some((s) => s.status === 'completed' && s.cost > 0) && a.some((s) => s.status === 'cancelled' && s.cost === 0), 'completed+cancelled present');
  const b = (await q(bob)).json.filter((x) => x.document);
  eq(b.length, 0, 'bob has no sessions');
  const cross = await http('POST', `${FS}:runQuery`, { token: bob.token, body: { structuredQuery: { from: [{ collectionId: 'sessions' }], where: { fieldFilter: { field: { fieldPath: 'userId' }, op: 'EQUAL', value: { stringValue: alice.uid } } } } } });
  assert(cross.status === 403 || cross.json.every((x) => !x.document), 'bob must not read alice\'s sessions');
});

// =========================== SCHEDULER (real Cloud Scheduler job) ===========================
test('SCHEDULER stale waiting session is closed by the real scheduled function', async () => {
  assert(ADMIN, 'ADMIN_TOKEN required');
  const old = new Date(Date.now() - 20 * 60 * 1000).toISOString();
  const id = `stale-${randomUUID().slice(0, 8)}`; touched.push(`sessions/${id}`);
  const r = await http('PATCH', `${FS}/sessions/${id}`, { token: ADMIN, body: { fields: {
    userId: enc(alice.uid), astrologerId: enc(ravi.uid), astrologerName: enc('Ravi Astro'), astrologerAvatar: enc(''), type: enc('chat'), status: enc('waiting'),
    pricePerMin: enc(25), durationSec: enc(0), cost: enc(0), createdAt: { timestampValue: old } } } });
  ok(r, 'plant stale session');
  const job = await fetch(`https://cloudscheduler.googleapis.com/v1/projects/${P}/locations/${REGION}/jobs/firebase-schedule-expireStaleSessions-${REGION}:run`,
    { method: 'POST', headers: { Authorization: `Bearer ${ADMIN}`, 'Content-Type': 'application/json', 'x-goog-user-project': P }, body: '{}' });
  assert(job.status === 200, `scheduler run failed: ${job.status} ${(await job.text()).slice(0, 150)}`);
  const s = await waitFor(async () => { const d = await getDoc(alice, `sessions/${id}`); return d.status === 'cancelled' ? d : null; }, { label: 'stale session cancelled', timeout: 90000, every: 3000 });
  eq([s.status, s.cost], ['cancelled', 0], 'stale cancelled');
});

// =========================== run ===========================
async function cleanup() {
  if (!ADMIN) return;
  for (const p of touched) {
    if (p.startsWith('sessions/')) {
      for (const sub of ['messages', 'presence']) {
        const docs = await http('GET', `${FS}/${p}/${sub}?pageSize=300`, { token: ADMIN });
        for (const m of docs.json.documents || []) await http('DELETE', `https://firestore.googleapis.com/v1/${m.name}`, { token: ADMIN });
      }
    }
    await http('DELETE', `${FS}/${p}`, { token: ADMIN });
  }
  for (const u of [alice, bob, ravi, sita]) if (u) await http('POST', `https://identitytoolkit.googleapis.com/v1/accounts:delete?key=${KEY}`, { body: { idToken: u.token } });
}

let pass = 0, fail = 0; const failures = [];
const only = process.argv[2];
for (const [name, fn] of tests) {
  if (only && !name.includes(only)) continue;
  const t0 = Date.now();
  try { await fn(); pass++; console.log(`  ✔ ${name}  (${((Date.now() - t0) / 1000).toFixed(1)}s)`); }
  catch (e) { fail++; failures.push([name, e.message]); console.log(`  ✘ ${name}\n      ${e.message}`); }
}
await cleanup().catch((e) => console.log('cleanup error', e.message));
console.log(`\n${pass} passed, ${fail} failed (${tests.length} total)`);
if (fail) { console.log('\nFAILURES:'); failures.forEach(([n, m]) => console.log(` - ${n}: ${m}`)); }
process.exit(fail ? 1 : 0);
