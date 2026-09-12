# ADR-0001: SwiftData schema changes must be lightweight-migratable, tested against real previous-release stores, and never crash the launch

- **Status:** Accepted (2026-09-11)
- **Context:** 1.2.0 crashed at launch for every user upgrading from 1.1.x. Commit `6440fdc` renamed
  `UserData.phone: String` to `var email: String` with no default value and no `@Attribute(originalName:)`.
  SwiftData lightweight migration cannot add a mandatory attribute without a default to existing rows:
  `NSCocoaErrorDomain 134110 — entity=UserData, attribute=email, "Validation error missing attribute values on
  mandatory destination attribute"` → `ModelContainer` init threw → `fatalError` in `TabiApp`. Fresh installs never
  hit it (no rows to validate), so simulator/reinstall testing could not catch it. There was no migration test,
  no fixture of the shipped schema, two containers opened the same store, and every data-layer failure was a
  `fatalError`.

## Decision

1. **Every stored property change must be inferable by lightweight migration.**
   - New stored properties are `Optional` **or** carry a default value (`var kind: String = "dummy"`).
   - Never rename, retype, change optionality of, or drop-and-re-add a property without a `MigrationStage`.
   - Relationship changes (new inverse, to-one → to-many, delete rule) count as schema changes: prove them.
2. **One container, opened through `TabiSchema`** (`Tabi Split/Infrastructure/SwiftData/TabiSchema.swift`).
   `TabiSchema.loadOrRecover()` opens the store; if that fails, it moves `default.store{,-wal,-shm}` to
   `Application Support/Recovery/<timestamp>/` and creates a fresh store (then in-memory as the last resort).
   Launch never `fatalError`s on data. This is acceptable because the local store is a **mirror of the server**
   (Home rebuilds it from `GET /event` on refresh); the only loss is unsynced scratch data. Home shows a toast
   (`SwiftDataService.consumeRecoveryNotice()`) when this happened. `SwiftDataService` owns the container;
   `TabiApp` injects the same instance.
3. **Fixture-based migration tests are the gate** (`Tabi Split Tests/StoreMigrationTests.swift`).
   `Tabi Split Tests/Fixtures/store-v<version>/default.store` holds a store written by that release's schema
   with **at least one row of every `@Model`** (mandatory-attribute failures only surface on rows).
   `testOpensStoreFromV…` opens each fixture with the current schema and checks the rows. Any PR that touches
   `Infrastructure/Model/` or `Infrastructure/SwiftData/` must keep these green and add a case for a new fixture
   when the previous release shipped a different schema.
4. **Release checklist** (also in `docs/prd/overview.md` §10):
   - Commit the `MARKETING_VERSION` bump in `project.yml`; tag `v<version>` on the archived commit.
   - Generate and commit the fixture for the version being shipped
     (`testGenerateFixtureForCurrentSchema`, see `Tabi Split Tests/Fixtures/README.md`).
   - Install the TestFlight build **over** the current App Store build on one device before submitting.
5. **`VersionedSchema` / `SchemaMigrationPlan` is deliberately not adopted yet.** Stores created without a
   versioned schema must be matched to a `VersionedSchema` by entity hashes; a reconstruction that does not match
   exactly fails with "Cannot use staged migration with an unknown model version" and would trigger the
   recovery wipe for everyone. Adopt only when a non-lightweight change is genuinely needed, and only when both
   the previous-release fixtures **and** the current one open through the plan in `StoreMigrationTests`.

## Consequences

- Schema evolution is additive-only by default; renames become "add new + stop reading old".
- A migration bug now shows up as a failing unit test before merge, and as a recovered (empty, re-synced) store
  instead of a crash if it ever reaches users.
- Each release adds one fixture folder (~200 KB).
- Follow-ups tracked in `docs/prd/overview.md` §9: give `Expense.creator` an inverse; make the non-optional
  to-one relationships (`Expense.coverer`, `ExpensePerson.user`) safe on user deletion; drop the `NoteData`
  dev leftovers via an explicit stage.
