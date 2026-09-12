# SwiftData store fixtures

Each `store-v<version>/default.store` is a SQLite store written by that App Store
release's schema (plus `-wal`/`-shm` side files when present). `StoreMigrationTests`
opens every fixture with the *current* schema; a failure there is the launch crash
users would hit after updating.

Before each release, generate the fixture for the version you are shipping:

```sh
xcodegen generate
xcodebuild test -project "Tabi Split.xcodeproj" -scheme "Tabi Split (Dev)" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO \
  -only-testing:"Tabi Split Tests/StoreMigrationTests/testGenerateFixtureForCurrentSchema" \
  TEST_RUNNER_TABI_GENERATE_FIXTURE=1 TEST_RUNNER_TABI_FIXTURE_DIR="$PWD/Tabi Split Tests/Fixtures"
# optional: fold the WAL into the main file
sqlite3 "Tabi Split Tests/Fixtures/store-v<version>/default.store" "PRAGMA wal_checkpoint(TRUNCATE);" \
  && rm -f "Tabi Split Tests/Fixtures/store-v<version>/default.store-wal" "Tabi Split Tests/Fixtures/store-v<version>/default.store-shm"
```

Then add a `testOpensStoreFromV<version>` case and commit the folder.
`store-v1.1.5` was produced from commit `737dbbf` (the 1.1.5–1.1.8 schema).
