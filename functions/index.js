const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineSecret } = require('firebase-functions/params');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const jwt = require('jsonwebtoken');
const K = require('./constants');

initializeApp();
const db = getFirestore();

const opts = { region: K.REGION };
const VIDEOSDK_API_KEY = defineSecret(K.SECRETS.API_KEY);
const VIDEOSDK_SECRET = defineSecret(K.SECRETS.SECRET);
const withSecrets = { ...opts, secrets: [VIDEOSDK_API_KEY, VIDEOSDK_SECRET] };

const fail = (code, msg) => new HttpsError(code, msg);
const requireAuth = (req) => {
  if (!req.auth) throw fail(K.ERR.UNAUTHENTICATED, K.MSG.SIGN_IN);
  return req.auth.uid;
};
const sessionRef = (id) => db.collection(K.COL.SESSIONS).doc(String(id));
const astrologerRef = (id) => db.collection(K.COL.ASTROLOGERS).doc(String(id));
const userRef = (id) => db.collection(K.COL.USERS).doc(String(id));
const presenceRef = (sid, who) => sessionRef(sid).collection(K.COL.PRESENCE).doc(who);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const isParticipant = (s, uid) => s.userId === uid || s.astrologerId === uid;

const wire = (id, s) => ({
  id,
  userId: s.userId,
  userName: s.userName,
  astrologerId: s.astrologerId,
  astrologerName: s.astrologerName,
  astrologerAvatar: s.astrologerAvatar,
  type: s.type,
  status: s.status,
  durationSec: s.durationSec || 0,
  cost: s.cost || 0,
  pricePerMin: s.pricePerMin,
});

async function getRole(uid) {
  const snap = await userRef(uid).get();
  return snap.exists ? { role: snap.data().role || K.ROLE.USER, data: snap.data() } : { role: null, data: null };
}

// ---------------------------------------------------------------- VideoSDK helpers
function videoSdkCredentials() {
  const key = VIDEOSDK_API_KEY.value();
  const secret = VIDEOSDK_SECRET.value();
  if (!key || !secret || key === K.SECRET_PLACEHOLDER || secret === K.SECRET_PLACEHOLDER) {
    throw fail(K.ERR.FAILED_PRECONDITION, K.MSG.CALLS_NOT_CONFIGURED);
  }
  return { key, secret };
}
const mintToken = ({ key, secret }) =>
  jwt.sign({ apikey: key, permissions: K.VIDEOSDK_PERMISSIONS, version: 2 }, secret, {
    algorithm: K.JWT_ALGORITHM, expiresIn: K.JWT_EXPIRY,
  });
async function createRoom(token) {
  const r = await fetch(K.VIDEOSDK_ROOMS_URL, {
    method: 'POST', headers: { Authorization: token, ...K.JSON_HEADERS }, body: K.EMPTY_BODY,
  });
  const j = await r.json().catch(() => ({}));
  if (!r.ok || !j.roomId) throw fail(K.ERR.UNAVAILABLE, K.MSG.ROOM_FAILED);
  return j.roomId;
}
/** Stores the room on the session only if none exists yet, so both parties always share one room. */
async function claimRoom(ref, roomId) {
  return db.runTransaction(async (t) => {
    const s = await t.get(ref);
    if (s.data().meetingId) return s.data().meetingId;
    t.update(ref, { meetingId: roomId });
    return roomId;
  });
}

// ---------------------------------------------------------------- astrologer account
const cleanList = (v) => Array.isArray(v) ? v.map((x) => String(x).trim()).filter(Boolean) : null;
const validList = (l) => l && l.length >= 1 && l.length <= K.LIMITS.LIST_MAX && l.every((x) => x.length <= K.LIMITS.ITEM_MAX);

exports.saveAstrologerProfile = onCall(opts, async (req) => {
  const uid = requireAuth(req);
  const { role } = await getRole(uid);
  if (role !== K.ROLE.ASTROLOGER) throw fail(K.ERR.PERMISSION_DENIED, K.MSG.NOT_AN_ASTROLOGER);
  const d = req.data || {};
  const name = String(d.name || '').trim();
  const expertise = cleanList(d.expertise);
  const languages = cleanList(d.languages);
  const experience = Number(d.experience);
  const pricePerMin = Number(d.pricePerMin);
  const about = String(d.about || '').trim();
  const avatar = String(d.avatar || '').trim();
  const L = K.LIMITS;
  if (name.length < L.NAME_MIN || name.length > L.NAME_MAX || !validList(expertise) || !validList(languages) ||
      !Number.isInteger(experience) || experience < 0 || experience > L.EXP_MAX ||
      !(pricePerMin >= L.PRICE_MIN && pricePerMin <= L.PRICE_MAX) || about.length > L.ABOUT_MAX ||
      avatar.length > L.URL_MAX || (avatar && !/^https:\/\//.test(avatar))) {
    throw fail(K.ERR.INVALID_ARGUMENT, K.MSG.INVALID_PROFILE);
  }
  const ref = astrologerRef(uid);
  const existing = await ref.get();
  const base = { uid, name, expertise, languages, experience, pricePerMin, about, avatar: avatar || K.DEFAULT_AVATAR(uid) };
  if (existing.exists) await ref.update(base);
  else await ref.set({ ...base, rating: 0, reviews: 0, status: K.AVAIL.OFFLINE, createdAt: FieldValue.serverTimestamp() });
  await userRef(uid).update({ name });
  return { id: uid };
});

exports.setAvailability = onCall(opts, async (req) => {
  const uid = requireAuth(req);
  const { role } = await getRole(uid);
  if (role !== K.ROLE.ASTROLOGER) throw fail(K.ERR.PERMISSION_DENIED, K.MSG.NOT_AN_ASTROLOGER);
  const ref = astrologerRef(uid);
  const status = await db.runTransaction(async (t) => {
    const snap = await t.get(ref);
    if (!snap.exists) throw fail(K.ERR.FAILED_PRECONDITION, K.MSG.NO_ASTROLOGER_PROFILE);
    if (snap.data().status === K.AVAIL.BUSY) throw fail(K.ERR.FAILED_PRECONDITION, K.MSG.FINISH_FIRST);
    const next = req.data?.online ? K.AVAIL.ONLINE : K.AVAIL.OFFLINE;
    t.update(ref, { status: next });
    return next;
  });
  return { status };
});

// ---------------------------------------------------------------- user: initiate a consultation
exports.startSession = onCall(opts, async (req) => {
  const uid = requireAuth(req);
  const { astrologerId, type } = req.data || {};
  if (!K.TYPES.includes(type)) throw fail(K.ERR.INVALID_ARGUMENT, K.MSG.INVALID_TYPE);
  if (astrologerId === uid) throw fail(K.ERR.PERMISSION_DENIED, K.MSG.SELF_BOOKING);
  const { role, data: user } = await getRole(uid);
  if (role !== K.ROLE.USER) throw fail(K.ERR.PERMISSION_DENIED, K.MSG.NOT_A_USER);
  const aSnap = await astrologerRef(astrologerId).get();
  if (!aSnap.exists) throw fail(K.ERR.NOT_FOUND, K.MSG.ASTROLOGER_NOT_FOUND);
  const a = aSnap.data();
  if (!a.uid) throw fail(K.ERR.NOT_FOUND, K.MSG.ASTROLOGER_NOT_FOUND); // only real astrologer accounts can be booked
  if (a.status !== K.AVAIL.ONLINE) throw fail(K.ERR.FAILED_PRECONDITION, K.MSG.ASTROLOGER_UNAVAILABLE(a.name, a.status));

  // Check-and-create must be atomic, otherwise a double tap starts two billable sessions.
  const ref = db.collection(K.COL.SESSIONS).doc();
  const activeQuery = db.collection(K.COL.SESSIONS)
    .where(K.FIELD.USER_ID, K.OP.EQ, uid)
    .where(K.FIELD.STATUS, K.OP.IN, [K.STATUS.WAITING, K.STATUS.ONGOING])
    .limit(1);
  await db.runTransaction(async (t) => {
    const active = await t.get(activeQuery);
    if (!active.empty) throw fail(K.ERR.FAILED_PRECONDITION, K.MSG.ALREADY_ACTIVE);
    t.set(ref, {
      userId: uid, userName: user.name || '', userDob: user.dob || null, userBirthTime: user.birthTime || null,
      userBirthPlace: user.birthPlace || null,
      astrologerId, astrologerName: a.name, astrologerAvatar: a.avatar, type,
      status: K.STATUS.WAITING, pricePerMin: a.pricePerMin, durationSec: 0, cost: 0,
      createdAt: FieldValue.serverTimestamp(), startedAt: null, endedAt: null, meetingId: null,
    });
  });
  return { id: ref.id };
});

// ---------------------------------------------------------------- astrologer: accept / decline
exports.respondToSession = onCall(withSecrets, async (req) => {
  const uid = requireAuth(req);
  const { role } = await getRole(uid);
  if (role !== K.ROLE.ASTROLOGER) throw fail(K.ERR.PERMISSION_DENIED, K.MSG.NOT_AN_ASTROLOGER);
  const sRef = sessionRef(req.data?.sessionId);
  const accept = req.data?.accept === true;
  const aRef = astrologerRef(uid);

  const result = await db.runTransaction(async (t) => {
    const [sSnap, aSnap] = await Promise.all([t.get(sRef), t.get(aRef)]);
    if (!sSnap.exists || sSnap.data().astrologerId !== uid) throw fail(K.ERR.NOT_FOUND, K.MSG.SESSION_NOT_FOUND);
    const s = sSnap.data();
    if (s.status !== K.STATUS.WAITING) throw fail(K.ERR.FAILED_PRECONDITION, K.MSG.REQUEST_GONE);
    let patch;
    if (accept) {
      if (!aSnap.exists || aSnap.data().status !== K.AVAIL.ONLINE) {
        throw fail(K.ERR.FAILED_PRECONDITION, aSnap.exists && aSnap.data().status === K.AVAIL.BUSY ? K.MSG.FINISH_FIRST : K.MSG.MUST_BE_ONLINE);
      }
      patch = { status: K.STATUS.ONGOING, startedAt: FieldValue.serverTimestamp() };
      t.update(aRef, { status: K.AVAIL.BUSY });
    } else {
      patch = { status: K.STATUS.REJECTED, endedAt: Timestamp.now(), durationSec: 0, cost: 0 };
    }
    t.update(sRef, patch);
    return { s, status: patch.status };
  });

  if (accept) {
    await presenceRef(sRef.id, K.PRESENCE_DOC.ASTROLOGER).set({ online: true, typing: false, updatedAt: FieldValue.serverTimestamp() });
    if (result.s.type !== 'chat') { // best effort: pre-create the shared room so both sides join the same one
      try { const c = videoSdkCredentials(); await claimRoom(sRef, await createRoom(mintToken(c))); } catch (_) { /* getVideoSdkRoom retries */ }
    }
  }
  return wire(sRef.id, { ...result.s, status: result.status });
});

// ---------------------------------------------------------------- end / cancel (either party); billing is server side
async function finish(ref, uid) {
  return db.runTransaction(async (t) => {
    const snap = await t.get(ref);
    if (!snap.exists || (uid && !isParticipant(snap.data(), uid))) throw fail(K.ERR.NOT_FOUND, K.MSG.SESSION_NOT_FOUND);
    const s = snap.data();
    const aRef = astrologerRef(s.astrologerId);
    const aSnap = await t.get(aRef);
    if ([K.STATUS.COMPLETED, K.STATUS.CANCELLED, K.STATUS.REJECTED].includes(s.status)) return wire(snap.id, s);
    const now = Timestamp.now();
    let patch;
    if (s.status === K.STATUS.ONGOING && s.startedAt) {
      const durationSec = Math.max(0, Math.round(now.seconds - s.startedAt.seconds));
      patch = { status: K.STATUS.COMPLETED, endedAt: now, durationSec, cost: Math.ceil(durationSec / 60) * s.pricePerMin };
      if (aSnap.exists && aSnap.data().uid && aSnap.data().status === K.AVAIL.BUSY) t.update(aRef, { status: K.AVAIL.ONLINE });
    } else {
      patch = { status: K.STATUS.CANCELLED, endedAt: now, durationSec: 0, cost: 0 };
    }
    t.update(snap.ref, patch);
    return wire(snap.id, { ...s, ...patch });
  });
}
exports.endSession = onCall(opts, async (req) => {
  const uid = requireAuth(req);
  return finish(sessionRef(req.data?.sessionId), uid);
});

// ---------------------------------------------------------------- VideoSDK token + room (secret never reaches the client)
exports.getVideoSdkRoom = onCall(withSecrets, async (req) => {
  const uid = requireAuth(req);
  const creds = videoSdkCredentials();
  const ref = sessionRef(req.data?.sessionId);
  const snap = await ref.get();
  if (!snap.exists || !isParticipant(snap.data(), uid)) throw fail(K.ERR.NOT_FOUND, K.MSG.SESSION_NOT_FOUND);
  if (snap.data().status !== K.STATUS.ONGOING) throw fail(K.ERR.FAILED_PRECONDITION, K.MSG.SESSION_NOT_ACTIVE);
  const token = mintToken(creds);
  let meetingId = snap.data().meetingId;
  if (!meetingId) meetingId = await claimRoom(ref, await createRoom(token));
  return { token, meetingId };
});

// ---------------------------------------------------------------- housekeeping: close abandoned sessions
exports.expireStaleSessions = onSchedule({ ...opts, schedule: K.STALE_SCHEDULE }, async () => {
  const waitCut = Timestamp.fromMillis(Date.now() - K.STALE_WAITING_MS);
  const liveCut = Timestamp.fromMillis(Date.now() - K.STALE_ONGOING_MS);
  const [w, o] = await Promise.all([
    db.collection(K.COL.SESSIONS).where(K.FIELD.STATUS, K.OP.EQ, K.STATUS.WAITING).where(K.FIELD.CREATED_AT, K.OP.LT, waitCut).get(),
    db.collection(K.COL.SESSIONS).where(K.FIELD.STATUS, K.OP.EQ, K.STATUS.ONGOING).where(K.FIELD.STARTED_AT, K.OP.LT, liveCut).get(),
  ]);
  await Promise.all([...w.docs, ...o.docs].map((d) => finish(d.ref, null)));
});
