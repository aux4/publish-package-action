# Publish aux4 Package Action

A GitHub Action to build and publish aux4 packages to hub.aux4.io with automatic GitHub releases.

## Usage

### Go package example

```yaml
name: Publish Package

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      level:
        description: 'Release level'
        required: true
        default: 'patch'
        type: choice
        options: [patch, minor, major]

permissions:
  contents: write

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: actions/setup-go@v5
        with:
          go-version: '1.21'

      - name: Build
        run: aux4 build

      - uses: aux4/publish-package-action@v1
        with:
          level: ${{ inputs.level || 'patch' }}
          aux4_token: ${{ secrets.AUX4_ACCESS_TOKEN }}
          github_token: ${{ secrets.GITHUB_TOKEN }}
```

### Simple package (no build required)

```yaml
- uses: aux4/publish-package-action@v1
  with:
    level: patch
    aux4_token: ${{ secrets.AUX4_ACCESS_TOKEN }}
    github_token: ${{ secrets.GITHUB_TOKEN }}
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `level` | Release level (patch, minor, major) | No | `patch` |
| `aux4_token` | aux4 access token for publishing to hub.aux4.io | Yes | - |
| `github_token` | GitHub token for creating releases | Yes | - |
| `working_directory` | Working directory containing the repository | No | `.` |
| `package_directory` | Directory containing the package .aux4 file | No | `package` |
| `aux4_image` | Docker image for aux4 | No | `aux4/aux4:latest` |

## Outputs

| Output | Description |
|--------|-------------|
| `version` | The new package version |
| `scope` | The package scope |
| `name` | The package name |
| `paid` | Whether the package is paid (`true` if it ships a `package/plans.json`, else `false`) |

## Paid packages (`plans.json`)

A package is **paid** if and only if it ships a `package/plans.json`. When present, the
action validates it before publishing and fails the build with a clear message if it is
invalid. The latest published document is the source of truth for the package's metric
labels, limits, and public price. Stripe identifiers and checkout URLs are configured
separately; they do not define the displayed price.

```json
{
  "schemaVersion": 1,
  "metrics": {
    "clown-fish": {
      "label": "Clown fish"
    }
  },
  "plans": {
    "default": {
      "price": { "monthly": 1 },
      "limits": {
        "clown-fish": 10
      }
    }
  }
}
```

Validation rules (each rejects the publish with a clear message):

- `schemaVersion` must be `1`.
- Metric keys use lowercase letters, numbers, `-`, or `_`, with a maximum of 64 characters.
- Every metric has a non-empty human label of at most 80 characters.
- The `plans` map must contain exactly one plan in v1 (the map format is retained).
- Every plan has a positive USD monthly price in `price.monthly`.
- Every plan assigns a limit to every declared metric and cannot reference an undeclared metric.
- Limits are integers (`-1` = unlimited, `0` = disabled, positive = allowed quantity).

This is a fast-fail CI pre-flight (see `validate-plans.jq`); the hub API is the authoritative
validator. Hub stores the document immutably per version and projects the latest version for Billing.

## Directory Structure

```
your-repo/
├── .aux4              # (optional) Build commands
├── package/
│   └── .aux4          # Package metadata (scope, name, version)
│   └── dist/          # Built artifacts (binaries, etc.)
└── ...
```

The `package/.aux4` must contain:
```json
{
  "scope": "your-scope",
  "name": "your-package",
  "version": "1.0.0"
}
```

## What it does

1. Pulls latest changes
2. Reads package metadata from `package/.aux4`
3. Validates `package/plans.json` shape if present (paid packages) and sets the `paid` output
4. Increments version based on level
5. Runs `aux4 pkger build` to create package zip
6. Runs `aux4 pkger publish` to publish to hub.aux4.io
7. Commits version change and creates git tag
8. Pushes to repository
9. Creates GitHub Release with package artifact

## Workflow

Your workflow handles the build, this action handles the rest:

```
[Your Build Step] → [publish-package-action]
     ↓                      ↓
  go build              version bump
  npm build             pkger build
  cargo build           pkger publish
  etc.                  git tag
                        gh release
```

## License

MIT
