# Patrol E2E tests

End-to-end tests for Quantus Wallet, driven by [Patrol](https://patrol.leancode.co/). Tests live under `patrol_test/`; runner scripts are in `scripts/`.

## Layout

| Path | Purpose |
|------|---------|
| `smoke/` | Quick sanity checks (minimal app setup) |
| `flows/` | Full user flows (create/import wallet, send, recovery phrase, …) |
| `support/` | Shared helpers (launchers, selectors, test env, timeouts) |

## Local runs

From `mobile-app/`:

```bash
# Android emulator
scripts/patrol_android_emulator.sh

# iOS Simulator
scripts/patrol_ios_simulator.sh
```

Run a single test:

```bash
scripts/patrol_android_emulator.sh patrol_test/smoke/hello_world_test.dart
scripts/patrol_ios_simulator.sh patrol_test/flows/create_wallet_test.dart
```

Pass zero targets to run the **whole suite** (every `*_test.dart` under `patrol_test/`).

### Test secrets (`.env.test`)

Flows that import a wallet or send funds need compile-time defines. Locally, create a gitignored `mobile-app/.env.test`:

```
TEST_IMPORT_MNEMONIC=word1 word2 ...
TEST_SEND_RECIPIENT_ADDRESS=ss58...
```

Scripts pass `--dart-define-from-file=.env.test` automatically when the file exists. See `support/test_env.dart`.

**Send flow:** the wallet for `TEST_IMPORT_MNEMONIC` must be funded on testnet; `send_flow_test.dart` checks balance before sending (`support/send_preflight.dart`).

## GitHub Actions (`E2E Mobile` workflow)

Phase 1 is **manual dispatch only** (Actions → E2E Mobile → Run workflow). Android and iOS jobs run in parallel.

Optional input `test_target` runs a single file (e.g. `patrol_test/smoke/hello_world_test.dart`); leave blank for the full suite.

### Required repository secrets

| Secret | Jobs | Purpose |
|--------|------|---------|
| `MOBILE_APP_ENV` | Both | Full `mobile-app/.env` contents (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `IOS_FIREBASE_API_KEY`, `ANDROID_FIREBASE_API_KEY`, …) |
| `GOOGLE_SERVICES_JSON` | Android | Full `google-services.json` (Gradle plugin) |
| `GOOGLE_SERVICES_PLIST` | iOS | Full `GoogleService-Info.plist` (Xcode bundle resource) |
| `E2E_TEST_ENV` | Both | Multiline `.env.test` body (`TEST_IMPORT_MNEMONIC`, `TEST_SEND_RECIPIENT_ADDRESS`, …) |

Generate Firebase config files locally with FlutterFire (`firebase.json`). Both native config files are gitignored.

After reliability is proven, the workflow can be extended to run on PRs touching `mobile-app/**` or `quantus_sdk/**`.
