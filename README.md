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
3. Increments version based on level
4. Runs `aux4 pkger build` to create package zip
5. Runs `aux4 pkger publish` to publish to hub.aux4.io
6. Commits version change and creates git tag
7. Pushes to repository
8. Creates GitHub Release with package artifact

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
