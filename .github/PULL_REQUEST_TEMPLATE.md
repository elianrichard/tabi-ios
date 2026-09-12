# Pull Request Description

1. Description
2. Description
3. Description

## Screenshots / Video

Put your result in a photo or video fromat here

## How to Test / Run

Describe how you test / run this PR

1. Step1
2. Step2
3. Step3

## Data / config checklist

- [ ] No files under `Tabi Split/Infrastructure/Model/` or `Tabi Split/Infrastructure/SwiftData/` changed
      **— or —** every new stored property is `Optional`/defaulted, `StoreMigrationTests` is green, and a fixture
      case exists for the last shipped version (see `docs/adr/0001-swiftdata-schema-migration.md`).
- [ ] Upgrade tested: previous release installed on a simulator/device, this build installed over it, app launches
      and Home shows the right balances.
- [ ] No secret committed; `Config/Production.xcconfig` still reads the key from `Config/Secrets.xcconfig`.
- [ ] `project.yml` version bump committed if this PR is a release.

## Related JIRA Ticket

Link
