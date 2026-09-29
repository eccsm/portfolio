// Per-visitor rolling 24-hour quota plus a global daily cap for Jev Guessr.
//
// A visitor is an HMAC of the client IP keyed with a server secret, so raw
// IPs are never stored and the key cannot be reversed or recomputed without
// the secret. Each visitor gets `perVisitor` evaluations in a 24-hour window
// that starts with their first evaluation. `globalPerDay` caps all visitors
// per UTC day and is the actual spend guard: the direct function URL lets a
// caller vary the IP header, which the global cap still bounds.
//
// `decide` is the single source of the rules; the memory store (tests,
// emulator) and the Firestore store both apply it.
import {createHmac} from 'node:crypto';

export const WINDOW_MS = 24 * 60 * 60 * 1000;
const DAY_MS = WINDOW_MS;

export function utcDay(t) {
  return new Date(t).toISOString().slice(0, 10);
}

export function nextUtcMidnight(t) {
  return (Math.floor(t / DAY_MS) + 1) * DAY_MS;
}

/** Client IP as seen through Firebase Hosting (Fastly), else the socket. */
export function clientIp(req) {
  const header = req.get?.('fastly-client-ip') ?? req.headers?.['fastly-client-ip'];
  return String(header || req.ip || 'unknown').trim();
}

export function visitorKey(req, secret) {
  return createHmac('sha256', `jev-quota:${secret}`).update(clientIp(req)).digest('base64url').slice(0, 32);
}

/**
 * Pure quota decision.
 * @param visitor stored `{count, windowStart}` or null
 * @param globalCount evaluations already counted today (UTC)
 * @returns `{status, visitorWrite?, globalWrite?}` — writes are omitted when denied.
 */
export function decide(visitor, globalCount, t, {perVisitor, globalPerDay}) {
  const fresh = !visitor || visitor.windowStart + WINDOW_MS <= t;
  const windowStart = fresh ? t : visitor.windowStart;
  const count = fresh ? 0 : visitor.count;
  const resetAt = windowStart + WINDOW_MS;
  if (count >= perVisitor) {
    return {status: {allowed: false, reason: 'visitor', limit: perVisitor, remaining: 0, resetAt}};
  }
  if (globalCount >= globalPerDay) {
    return {status: {allowed: false, reason: 'global', limit: perVisitor, remaining: perVisitor - count, resetAt: nextUtcMidnight(t)}};
  }
  return {
    status: {allowed: true, limit: perVisitor, remaining: perVisitor - count - 1, resetAt},
    visitorWrite: {count: count + 1, windowStart, expiresAt: resetAt},
    globalWrite: {count: globalCount + 1, expiresAt: nextUtcMidnight(t) + DAY_MS},
  };
}

/** Read-only view for the status endpoint. */
export function peek(visitor, t, {perVisitor}) {
  if (!visitor || visitor.windowStart + WINDOW_MS <= t) return {limit: perVisitor, remaining: perVisitor, resetAt: null};
  return {limit: perVisitor, remaining: Math.max(0, perVisitor - visitor.count), resetAt: visitor.windowStart + WINDOW_MS};
}

/** In-memory store with the same contract as `firestoreQuota`. */
export function memoryQuota(limits, now = Date.now) {
  const visitors = new Map();
  const days = new Map();
  return {
    async peek(key) {
      return peek(visitors.get(key), now(), limits);
    },
    async take(key) {
      const t = now();
      const {status, visitorWrite, globalWrite} = decide(visitors.get(key), days.get(utcDay(t)) ?? 0, t, limits);
      if (visitorWrite) {
        visitors.set(key, visitorWrite);
        days.set(utcDay(t), globalWrite.count);
      }
      return status;
    },
    async refund(key) {
      const v = visitors.get(key);
      if (v?.count > 0) visitors.set(key, {...v, count: v.count - 1});
      const day = utcDay(now());
      if (days.get(day) > 0) days.set(day, days.get(day) - 1);
    },
  };
}

/**
 * Firestore store. Documents carry `expiresAt` (a Timestamp) so a TTL policy
 * on that field deletes them once they no longer matter.
 */
export function firestoreQuota(db, limits, {Timestamp, FieldValue}, now = Date.now) {
  const visitorRef = (key) => db.collection('jevQuota').doc(key);
  const dayRef = (t) => db.collection('jevQuotaDaily').doc(utcDay(t));
  const plain = (snap) => (snap.exists ? {count: snap.get('count'), windowStart: snap.get('windowStart')} : null);
  return {
    async peek(key) {
      return peek(plain(await visitorRef(key).get()), now(), limits);
    },
    async take(key) {
      return db.runTransaction(async (tx) => {
        const t = now();
        const [visitor, day] = await Promise.all([tx.get(visitorRef(key)), tx.get(dayRef(t))]);
        const {status, visitorWrite, globalWrite} = decide(plain(visitor), day.exists ? day.get('count') : 0, t, limits);
        if (visitorWrite) {
          tx.set(visitorRef(key), {...visitorWrite, expiresAt: Timestamp.fromMillis(visitorWrite.expiresAt)});
          tx.set(dayRef(t), {...globalWrite, expiresAt: Timestamp.fromMillis(globalWrite.expiresAt)});
        }
        return status;
      });
    },
    async refund(key) {
      const t = now();
      await Promise.all([
        visitorRef(key).update({count: FieldValue.increment(-1)}),
        dayRef(t).update({count: FieldValue.increment(-1)}),
      ]);
    },
  };
}
