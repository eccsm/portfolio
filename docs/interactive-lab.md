# Portfolio and Interactive Lab

Astro answers “What have I built and worked on?” Flutter answers “How do these engineering ideas behave?”

```text
Astro static portfolio (Firebase Hosting)
  └─ user gesture → Flutter multi-view overlay / Interactive Lab
       ├─ Local Intelligence → existing MLC LLM + WebGPU browser inference
       └─ Semantic Decisions → Jev Guessr
            validation → {category, description}
              → POST /api/jev-guessr → Firebase Function → TypeSafe
                                      server-only key       │
              ← validated domain response ←────────────────┘
            → Dart thresholds, scoring and round state
```

The Flutter registry is `flutter_app/lib/labs/lab_registry.dart`. Local Intelligence retains the original `ChatContainer`, model controls, WebLLM bridge, downloads, and fallback behavior. Résumé context loads only when that experiment opens; Jev and the lab home do not depend on it. Existing résumé widgets remain available in source. Closing an experiment returns to the lab; closing the overlay returns to Astro.

The existing deployment builds Flutter into `site/public/assets/flutter/<git hash>/`, then builds Astro into `site/dist`. No model download occurs just by loading Astro. Existing COOP/COEP headers and WebLLM asset loading remain in place. Flutter already fetches résumé JSON and public GitHub/contribution APIs; local inference does not require an API credential.

## Jev boundary

```text
                    State
              ┌──────┼──────┐
            Choice  Noul   Score
              └──────┼──────┘
              Application policy
```

One request to `https://api.typesafe.ai/v1/systemone` includes all three independent questions. The adapter follows the [official API reference](https://docs.typesafe.ai/api), checked 2026-09-22. Choice includes OTHER and its full distribution. Noul returns sufficiency probability. Score uses four ordered ambiguity criteria and accepts fractional scores. Confidence and distributions are exposed when returned, without inventing missing fields. Returned model identity and measured timings are distinct from configured model aliases.

Dart handles deterministic rules. Jev handles semantic judgments. Dart owns final behavior. A win requires a matching choice, selected probability ≥ 0.80 and sufficiency ≥ 0.80. Score influences points, never selects a winner. Points are 1000 minus 100 per additional evaluated attempt, 100 times ambiguity, and characters beyond 120, clamped to 100–1000. Unsuccessful rounds score zero. Invalid submissions and service failures do not consume attempts. These rules live together in `domain.dart`.

Only category and trimmed description leave the browser. The secret target, attempts, points, identity and UI state are never transported. The server fixes questions and models: callers cannot turn the endpoint into an arbitrary model proxy. It rejects extra fields, invalid categories, empty/control-character input, descriptions over 500 UTF-16 code units, and bodies above 4 KiB. The upstream request aborts after 10 seconds; the client stops waiting after 15 seconds. Raw upstream errors, credentials and response extensions are never forwarded or logged. No prompt storage or description analytics are added.

Target matching is intentionally simple: case folding and ASCII punctuation/space removal, then substring matching. This catches direct plurals and `a.p.p.l.e`, but can reject words containing a target (for example `dogwood`). It is an MVP rule, not comprehensive cheating detection. The server cannot validate a secret word it never receives.

## Configuration

| Variable | Classification | Default / purpose |
|---|---|---|
| `ENABLE_JEV_GUESSR` | PUBLIC, Flutter compile time | `false`; removes Jev from the registry when disabled |
| `JEV_PROVIDER` | PUBLIC, Flutter compile time | `mock`; `typesafe` calls the same-origin endpoint |
| `JEV_API_ENABLED` | SERVER ONLY, non-secret Firebase parameter | `false`; explicit server kill switch |
| `JEV_MODEL` | SERVER ONLY, non-secret Firebase parameter | `jev-latest`; requested model alias |
| `TYPESAFE_API_KEY` | SECRET / SERVER ONLY | Firebase Secret Manager; never a Dart define or Astro variable |

The root build forwards only the two explicit public Jev variables. Invalid provider values fail the build; the Flutter registry also fails closed. CI production reads the two public repository variables. PR previews force mock mode. Existing analytics and IndexNow configuration is unchanged. Never put a reusable credential in `PUBLIC_*`, `--dart-define`, or a file under `site/public` or `flutter_app/web`.

## Local development (PowerShell, repository root)

```powershell
npm --prefix site ci
Push-Location flutter_app
flutter pub get
Pop-Location
$env:ENABLE_JEV_GUESSR='true'
$env:JEV_PROVIDER='mock'
node scripts/build.mjs
node site/scripts/serve-dist.mjs
```

Open the URL printed by the server and choose **Explore Interactive Lab**. The custom Flutter bootstrap is an embedded multi-view host: use this integrated build for browser development rather than assuming `flutter run -d chrome` starts a standalone page. After a Dart edit, repeat the root build and reload.

Mock mode needs no Firebase process, credentials, or network inference. It is prominently labeled synthetic. Fixture keywords are `pie`, `bell`, `citrus`, `peel`, `bark`, `purr`, `hop`, `hoof`; one category-matching keyword yields a clear result, otherwise the provider yields uncertainty. It never reads the target. The developer panel omits fake model names and API latency.

For live local development, install Node 22 and Firebase CLI, then:

```powershell
npm --prefix functions ci
# Create functions/.secret.local containing TYPESAFE_API_KEY=<your key>.
# Create functions/.env.local containing JEV_API_ENABLED=true and JEV_MODEL=jev-latest.
$env:ENABLE_JEV_GUESSR='true'
$env:JEV_PROVIDER='typesafe'
node scripts/build.mjs
firebase emulators:start --only hosting,functions --project resume-63067
```

Visit `http://localhost:5000`. Both local files are ignored. Use the hosting emulator so `/api/jev-guessr` reaches the function; the static development server does not proxy API requests.

## Deployment and public traffic

The Firebase project needs Functions support, a billing-enabled plan and permissions for the operator deploying functions. The existing Hosting GitHub action does **not** deploy functions. Provision the server separately before enabling live Jev in the public build:

```powershell
firebase functions:secrets:set TYPESAFE_API_KEY --project resume-63067
# Set JEV_API_ENABLED=true and JEV_MODEL=jev-latest in functions/.env.resume-63067
firebase deploy --only functions:jevGuessr --project resume-63067
```

Then set repository variables `ENABLE_JEV_GUESSR=true`, `JEV_PROVIDER=typesafe` and deploy Hosting through the existing workflow. Until provisioned, keep the feature disabled or choose mock. A disabled API returns a sanitized unavailable response. Hosting forwards only the fixed `/api/jev-guessr` path; the function accepts only JSON POSTs and supplies no cross-origin permission.

The function caps instances at 2 and concurrency at 8. These are concurrency controls, **not a per-visitor rate limit or spend cap**. Firebase HTTP functions do not provide a simple built-in per-IP quota. For public live use, apply provider account quotas/budget controls; if sustained abuse requires per-IP throttling, [Google Cloud Armor rate limiting](https://cloud.google.com/armor/docs/rate-limiting-overview) requires a load balancer/serverless NEG and ingress restrictions (including the direct function URL). That infrastructure is intentionally outside this small demo. Origin/CORS is not authentication. Upstream 429 responses are safely surfaced for manual retry. No automatic retry multiplies paid requests.

## Checks

```powershell
Push-Location flutter_app
dart format --output=none --set-exit-if-changed lib/labs test/jev_guessr_test.dart
flutter analyze
flutter test
Pop-Location
npm --prefix functions run check
npm --prefix functions test
npm --prefix site run test:site
node scripts/build.mjs
node scripts/check-client-secrets.mjs
```

Astro has no configured formatter, lint or standalone typecheck command. Its production build and existing Node test suite are the repository checks. Normal tests use synthetic fixtures and injected HTTP clients, never the real Jev API.

## Content maintenance

Rigoryn is the displayed current identity, including metadata, headings and shared JSON. `/projects/archmet/` is deliberately retained as the canonical existing URL; no redirect or invented repository URL is needed. Legacy route-test fixtures retain the old slug. Archimet (the separately named interpretation layer) and AMF compatibility history remain as supported by the original content. Status badges, Current Status sections, planned modules and roadmap capability lists were removed. Existing design claims remain explicitly framed as design rather than assertions of shipped functionality. Employment dates and historical migration facts remain intact.
