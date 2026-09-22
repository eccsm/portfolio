import {readdirSync, readFileSync, statSync} from 'node:fs';
import {join, resolve} from 'node:path';

const root = resolve('site/dist');
const markers = ['TYPESAFE_API_KEY', 'server-only-test-key', 'client-secret-scan-sentinel'];
if (process.env.TYPESAFE_API_KEY) markers.push(process.env.TYPESAFE_API_KEY);
let count = 0;
function scan(dir) {
  for (const name of readdirSync(dir)) {
    const path = join(dir, name);
    if (statSync(path).isDirectory()) scan(path);
    else {
      count++;
      const bytes = readFileSync(path);
      if (markers.some(marker => bytes.includes(Buffer.from(marker)))) throw new Error(`Secret marker in client artifact: ${path}`);
      if (/Bearer\s+[A-Za-z0-9_-]{20,}/.test(bytes.toString('utf8'))) throw new Error(`Reusable bearer credential pattern in: ${path}`);
    }
  }
}
scan(root);
console.log(`Scanned ${count} generated client files: no TypeSafe secret markers or reusable bearer credential patterns.`);
