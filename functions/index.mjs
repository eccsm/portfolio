import {initializeApp} from 'firebase-admin/app';
import {FieldValue, Timestamp, getFirestore} from 'firebase-admin/firestore';
import {onRequest} from 'firebase-functions/v2/https';
import {defineInt, defineSecret, defineString} from 'firebase-functions/params';
import {createHandler} from './jev.mjs';
import {firestoreQuota} from './quota.mjs';

const apiKey = defineSecret('TYPESAFE_API_KEY');
const enabled = defineString('JEV_API_ENABLED', {default: 'false'});
const model = defineString('JEV_MODEL', {default: 'jev-latest'});
const perVisitor = defineInt('JEV_DAILY_LIMIT', {default: 20});
const globalPerDay = defineInt('JEV_GLOBAL_DAILY_LIMIT', {default: 1000});

initializeApp();
let quota;

// invoker 'public' is explicit so every deploy (re)applies the allUsers
// run.invoker binding Hosting's rewrite needs; a service first created by a
// failed deploy otherwise keeps answering 403. Input validation, the kill
// switch, the quotas and instance caps remain the actual guards.
export const jevGuessr = onRequest({
  region: 'us-central1', secrets: [apiKey], cors: false, invoker: 'public',
  timeoutSeconds: 15, maxInstances: 2, concurrency: 8,
}, (req, res) => {
  quota ??= firestoreQuota(getFirestore(), {
    perVisitor: perVisitor.value(), globalPerDay: globalPerDay.value(),
  }, {Timestamp, FieldValue});
  return createHandler({
    key: () => apiKey.value(), enabled: () => enabled.value() === 'true', model: model.value(), quota,
  })(req, res);
});
