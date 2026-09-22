import {onRequest} from 'firebase-functions/v2/https';
import {defineSecret, defineString} from 'firebase-functions/params';
import {createHandler} from './jev.mjs';

const apiKey = defineSecret('TYPESAFE_API_KEY');
const enabled = defineString('JEV_API_ENABLED', {default: 'false'});
const model = defineString('JEV_MODEL', {default: 'jev-latest'});

export const jevGuessr = onRequest({
  region: 'us-central1', secrets: [apiKey], cors: false,
  timeoutSeconds: 15, maxInstances: 2, concurrency: 8,
}, (req, res) => createHandler({
  key: () => apiKey.value(), enabled: () => enabled.value() === 'true', model: model.value(),
})(req, res));
