import test from 'node:test';
import assert from 'node:assert/strict';
import {safeState, requestFor, mapResponse, createHandler} from './jev.mjs';

const state = {category: 'FRUIT', description: 'Red fruit used in pies'};
const fixture = () => ({model: 'jev-1.13.0', answers: {
  identity: {type: 'choice', choice: 'APPLE', confidence: .9, probabilities: {APPLE: .92, PEAR: .02, ORANGE: .02, BANANA: .02, OTHER: .02}},
  sufficiency: {type: 'noul', noul: .95},
  ambiguity: {type: 'score', score: .2, confidence: .8, probabilities: {'0': .8, '1': .2, '2': 0, '3': 0}},
}});
test('only bounded minimal state is accepted', () => {
  assert.deepEqual(safeState(state), state);
  for (const bad of [null, {}, {...state, target: 'APPLE'}, {...state, category: 'OTHER'}, {...state, category: ['FRUIT']}, {...state, description: ' '}, {...state, description: 'x'.repeat(501)}, {...state, description: '\u0000'}]) assert.equal(safeState(bad), null);
});
test('one request has three independent questions and OTHER in both categories', () => {
  for (const category of ['FRUIT', 'ANIMAL']) {
    const request = requestFor({...state, category}, 'jev-latest');
    assert.deepEqual(Object.keys(request.state), ['category', 'description']);
    assert.deepEqual(Object.values(request.questions).map(q => q.type), ['choice', 'noul', 'score']);
    assert.ok(request.questions.identity.criteria.OTHER);
    assert.equal(request.questions.ambiguity.criteria.length, 4);
    assert.match(request.questions.sufficiency.instructions, category === 'FRUIT' ? /PEAR/ : /HORSE/);
  }
});
test('response mapping preserves probabilities and rejects malformed output', () => {
  const mapped = mapResponse(fixture(), 'FRUIT', 123);
  assert.equal(mapped.identity.probability, .92);
  assert.equal(mapped.sufficiency.probability, .95);
  assert.equal(mapped.ambiguity.score, .2);
  assert.equal(mapped.apiLatencyMs, 123);
  for (const mutate of [b => b.answers.identity.probabilities.APPLE = 2, b => b.answers.identity.choice = 'DOG', b => b.answers.sufficiency.noul = NaN, b => b.answers.ambiguity.score = 4, b => b.answers.identity.type = 'noul']) {
    const body = fixture(); mutate(body); assert.throws(() => mapResponse(body, 'FRUIT', 1));
  }
});
async function invoke(fetchImpl, overrides = {}, enabled = true) {
  const res = {code: 200, headers: {}, set(k,v) {this.headers[k]=v; return this;}, status(c) {this.code=c; return this;}, json(body) {this.body=body; return this;}};
  await createHandler({key: () => 'server-only-test-key', enabled: () => enabled, fetchImpl, timeoutMs: 5})(
    {method: 'POST', is: () => true, body: state, ...overrides}, res);
  return res;
}
test('transport sends credential only upstream and returns allowlisted results', async () => {
  const res = await invoke(async (url, init) => {
    assert.equal(url, 'https://api.typesafe.ai/v1/systemone');
    assert.equal(init.headers.Authorization, 'Bearer server-only-test-key');
    assert.deepEqual(JSON.parse(init.body).state, state);
    assert.ok(init.signal);
    return {ok: true, json: async () => ({...fixture(), secret: 'server-only-test-key'})};
  });
  assert.equal(res.code, 200);
  assert.equal(res.headers['Cache-Control'], 'no-store');
  assert.ok(!JSON.stringify(res.body).includes('server-only-test-key'));
});
test('invalid, disabled, failure, timeout and throttled requests are safe', async () => {
  const forbidden = () => {throw new Error('must not call');};
  assert.equal((await invoke(forbidden, {}, false)).code, 503);
  assert.equal((await invoke(forbidden, {method: 'GET'})).code, 405);
  assert.equal((await invoke(forbidden, {is: () => false})).code, 415);
  assert.equal((await invoke(forbidden, {rawBody: {length: 5000}})).code, 413);
  assert.equal((await invoke(forbidden, {body: {...state, target: 'APPLE'}})).code, 400);
  assert.deepEqual((await invoke(async () => {throw new Error('private upstream details');})).body, {error: 'upstreamFailure'});
  assert.equal((await invoke(async () => ({ok: false, status: 429}))).code, 429);
  assert.equal((await invoke(async () => ({ok: false, status: 401}))).code, 502);
  assert.equal((await invoke(async () => ({ok: true, json: async () => ({})}))).code, 502);
  const timer = setTimeout(() => {}, 30);
  const timed = await invoke((_url, {signal}) => new Promise((_, reject) => signal.addEventListener('abort', () => reject(signal.reason))));
  clearTimeout(timer);
  assert.equal(timed.code, 502);
});
