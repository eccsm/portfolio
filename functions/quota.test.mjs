import test from 'node:test';
import assert from 'node:assert/strict';
import {WINDOW_MS, clientIp, decide, memoryQuota, nextUtcMidnight, visitorKey} from './quota.mjs';
import {createHandler} from './jev.mjs';

const limits = {perVisitor: 3, globalPerDay: 5};
const T0 = Date.UTC(2026, 8, 29, 10, 0, 0);

test('a visitor gets N evaluations per rolling 24 hours from their first one', () => {
  let v = null;
  for (let i = 0; i < 3; i++) {
    const {status, visitorWrite} = decide(v, 0, T0 + i * 1000, limits);
    assert.equal(status.allowed, true);
    assert.equal(status.remaining, 2 - i);
    assert.equal(status.resetAt, T0 + WINDOW_MS);
    v = visitorWrite;
  }
  const denied = decide(v, 0, T0 + WINDOW_MS - 1, limits);
  assert.deepEqual([denied.status.allowed, denied.status.reason, denied.visitorWrite], [false, 'visitor', undefined]);
  const renewed = decide(v, 0, T0 + WINDOW_MS, limits);
  assert.deepEqual([renewed.status.allowed, renewed.status.remaining, renewed.status.resetAt], [true, 2, T0 + 2 * WINDOW_MS]);
});

test('the global daily cap applies to everyone until the next UTC midnight', () => {
  const {status} = decide(null, 5, T0, limits);
  assert.deepEqual([status.allowed, status.reason, status.remaining], [false, 'global', 3]);
  assert.equal(status.resetAt, nextUtcMidnight(T0));
});

test('visitor keys are keyed hashes, never raw IPs', () => {
  const req = {get: (h) => (h === 'fastly-client-ip' ? '203.0.113.7' : undefined), ip: '10.0.0.1'};
  assert.equal(clientIp(req), '203.0.113.7');
  assert.equal(clientIp({ip: '10.0.0.1'}), '10.0.0.1');
  const key = visitorKey(req, 'secret-a');
  assert.doesNotMatch(key, /203/);
  assert.equal(key, visitorKey(req, 'secret-a'));
  assert.notEqual(key, visitorKey(req, 'secret-b'));
  assert.notEqual(key, visitorKey({ip: '203.0.113.8'}, 'secret-a'));
});

const state = {category: 'FRUIT', description: 'Red fruit used in pies'};
const upstreamOk = async () => ({ok: true, json: async () => ({model: 'jev-1.13.0', answers: {
  identity: {type: 'choice', choice: 'APPLE', probabilities: {APPLE: .92, PEAR: .02, ORANGE: .02, BANANA: .02, OTHER: .02}},
  sufficiency: {type: 'noul', noul: .95},
  ambiguity: {type: 'score', score: .2},
}})});

function harness(fetchImpl, quota) {
  const call = async (req) => {
    const res = {code: 200, headers: {}, set(k, v) {this.headers[k] = v; return this;}, status(c) {this.code = c; return this;}, json(b) {this.body = b; return this;}};
    await createHandler({key: () => 'k', enabled: () => true, fetchImpl, timeoutMs: 50, quota, now: () => T0})(
      {method: 'POST', is: () => true, body: state, ip: '198.51.100.4', ...req}, res);
    return res;
  };
  return call;
}

test('handler spends quota only on valid requests and reports it', async () => {
  const quota = memoryQuota(limits, () => T0);
  const call = harness(upstreamOk, quota);
  assert.deepEqual((await call({method: 'GET'})).body, {quota: {limit: 3, remaining: 3, resetAt: null}});
  assert.equal((await call({body: {...state, target: 'APPLE'}})).code, 400);
  const first = await call({});
  assert.equal(first.code, 200);
  assert.deepEqual(first.body.quota, {limit: 3, remaining: 2, resetAt: T0 + WINDOW_MS});
  assert.equal(first.headers['RateLimit-Remaining'], '2');
  await call({});
  await call({});
  const blocked = await call({});
  assert.equal(blocked.code, 429);
  assert.equal(blocked.body.error, 'dailyLimit');
  assert.equal(blocked.headers['Retry-After'], String(WINDOW_MS / 1000));
  // Another visitor is unaffected.
  assert.equal((await call({ip: '198.51.100.5'})).code, 200);
});

test('upstream failures refund the attempt; a broken quota store fails closed', async () => {
  const quota = memoryQuota(limits, () => T0);
  const failing = harness(async () => ({ok: false, status: 500}), quota);
  assert.equal((await failing({})).code, 502);
  assert.equal((await quota.peek(visitorKey({ip: '198.51.100.4'}, 'k'))).remaining, 3);
  const broken = {take: async () => {throw new Error('firestore down');}, peek: async () => {throw new Error('x');}, refund: async () => {}};
  const call = harness(() => {throw new Error('must not call upstream');}, broken);
  assert.equal((await call({})).code, 503);
  assert.equal((await call({method: 'GET'})).code, 503);
});

test('the global cap reports busy rather than a personal limit', async () => {
  const quota = memoryQuota({perVisitor: 10, globalPerDay: 1}, () => T0);
  const call = harness(upstreamOk, quota);
  assert.equal((await call({ip: '192.0.2.1'})).code, 200);
  const res = await call({ip: '192.0.2.2'});
  assert.deepEqual([res.code, res.body.error], [429, 'busy']);
});
