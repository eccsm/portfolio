// Root build pipeline: flutter build web -> copy into site/public -> astro build.
//
//   node scripts/build.mjs            # full build -> site/dist
//   node scripts/build.mjs --no-flutter  # site-only (launch button hides itself)
//
// The Flutter island is built into a git-hash-named subdirectory of
// site/public/assets/flutter/ with a matching --base-href, so engine files
// are content-addressed per deploy: they can be cached as immutable
// (firebase.json does), and a new deploy can never serve a stale engine.
// No Flutter service worker is generated (--pwa-strategy=none); the shell
// additionally ships a self-destructing /flutter_service_worker.js to evict
// the worker left behind by the old Flutter PWA deployment.
import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const site = join(root, 'site');
const flutterApp = join(root, 'flutter_app');
const isWindows = process.platform === 'win32';

function run(command, args, cwd) {
  console.log(`\n> ${command} ${args.join(' ')}`);
  execFileSync(command, args, { cwd, stdio: 'inherit', shell: isWindows });
}

const skipFlutter = process.argv.includes('--no-flutter');

try {
  run('node', ['scripts/indexnow-key.mjs', 'prepare'], site);

  // 1. Emit resume.json first — the Flutter build doesn't need it, but tests
  //    and local servers do, and site prebuild would emit it later anyway.
  run('node', ['scripts/emit-resume-json.mjs'], site);

  const flutterOut = join(site, 'public', 'assets', 'flutter');
  const manifest = join(site, 'src', 'generated', 'flutter-build.json');
  rmSync(flutterOut, { recursive: true, force: true });
  rmSync(manifest, { force: true });

  if (!skipFlutter) {
    // 2. Flutter island into a content-addressed subdirectory.
    const hash = execFileSync('git', ['rev-parse', '--short', 'HEAD'], {
      cwd: root,
    })
      .toString()
      .trim();
    const base = `/assets/flutter/${hash}/`;
    const outDir = join(flutterOut, hash);

    const args = [
      'build',
      'web',
      '--release',
      '--pwa-strategy=none',
      `--base-href=${base}`,
      `--output=${outDir}`,
    ];
    // Explicit allowlist of public compile-time values; never forward server secrets.
    const enableJev = process.env.ENABLE_JEV_GUESSR ?? 'false';
    const jevProvider = process.env.JEV_PROVIDER ?? 'mock';
    if (!['true', 'false'].includes(enableJev) || !['mock', 'typesafe'].includes(jevProvider)) {
      throw new Error('Invalid public Jev configuration');
    }
    args.push(`--dart-define=ENABLE_JEV_GUESSR=${enableJev}`, `--dart-define=JEV_PROVIDER=${jevProvider}`);
    // Optional; the PDF omits the phone entry when unset. Public repo — the
    // number itself must only ever exist in CI secrets / local env.
    if (process.env.RESUME_PHONE) {
      args.push(`--dart-define=RESUME_PHONE=${process.env.RESUME_PHONE}`);
    }
    run('flutter', args, flutterApp);

    // Belt and braces: never ship a service worker from the island directory.
    rmSync(join(outDir, 'flutter_service_worker.js'), { force: true });

    // 3. Manifest that FlutterIsland.astro reads at astro-build time.
    mkdirSync(dirname(manifest), { recursive: true });
    writeFileSync(manifest, JSON.stringify({ base }, null, 2) + '\n');
    console.log(`\nFlutter island at ${base}`);
  } else {
    console.log('\nSkipping Flutter build (--no-flutter); launch buttons will hide.');
  }

  // 4. Astro build (its prebuild re-emits og.png + resume.json — harmless).
  run('npm', ['run', 'build'], site);

  if (!existsSync(join(site, 'dist', 'index.html'))) {
    throw new Error('site/dist/index.html missing after build');
  }
} finally {
  try {
    run('node', ['scripts/indexnow-key.mjs', 'cleanup'], site);
  } catch {
    console.warn('\nWarning: could not clean up generated IndexNow key file from site/public.');
  }
}

console.log('\nDone: deployable output in site/dist/');
