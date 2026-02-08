# Publish aux4 Package Action

A GitHub Action to build and publish aux4 packages to hub.aux4.io with automatic GitHub releases.

## Usage

```yaml
name: Publish Package

on:
  push:
    branches:
      - main
  workflow_dispatch:
    inputs:
      level:
        description: 'Release level'
        required: true
        default: 'patch'
        type: choice
        options:
          - patch
          - minor
          - major

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: aux4/publish-package-action@v1
        with:
          level: ${{ inputs.level || 'patch' }}
          aux4_token: ${{ secrets.AUX4_ACCESS_TOKEN }}
          github_token: ${{ secrets.GITHUB_TOKEN }}
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `level` | Release level (patch, minor, major) | No | `patch` |
| `aux4_token` | aux4 access token for publishing to hub.aux4.io | Yes | - |
| `github_token` | GitHub token for creating releases | Yes | - |
| `working_directory` | Working directory containing the package | No | `.` |
| `publisher_image` | Docker image for aux4 publisher | No | `aux4/publisher:latest` |

## Outputs

| Output | Description |
|--------|-------------|
| `version` | The new package version |
| `scope` | The package scope |
| `name` | The package name |

## What it does

1. Pulls latest changes from the branch
2. Increments the version in `.aux4` based on the level
3. Builds the package using `aux4 pkger build`
4. Publishes to hub.aux4.io using `aux4 pkger publish`
5. Commits the version change and creates a git tag
6. Pushes changes and tags to the repository
7. Creates a GitHub Release with the package artifact

## Requirements

- The repository must have an `.aux4` file with `scope`, `name`, and `version` fields
- The `AUX4_ACCESS_TOKEN` secret must be configured
- The workflow must have `contents: write` permission

## License

MIT
