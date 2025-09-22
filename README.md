# Kusari Index Generation Action

🔍 Automatically generate Kusari SCIP (SCIP Code Intelligence Protocol) indexes for projects that have changed files in a PR or commit.

## Features

- ✅ **Smart Detection**: Only processes projects with actual changes
- ✅ **Multi-Language Support**: Go, TypeScript/JavaScript, Python, Java
- ✅ **Automatic PR Comments**: Reports generation results directly on PRs
- ✅ **Zero Configuration**: Works out of the box with sensible defaults
- ✅ **Efficient**: Skips processing when no relevant changes are detected

## Usage

### Basic Usage

```yaml
name: Generate SCIP Indexes

on:
  pull_request:
    types: [opened, synchronize, reopened]
    branches: [ main, develop ]
  workflow_dispatch:

jobs:
  generate-scip-indexes:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write  # Required for PR comments
    container:
      image: your-docker-image:latest  # Must have SCIP tools pre-installed
    steps:
    - name: Checkout repository
      uses: actions/checkout@v4
      with:
        fetch-depth: 0  # Required for git diff
        persist-credentials: false

    - name: Generate SCIP indexes
      uses: your-org/scip-index-action@v1
```

### With Custom Working Directory

```yaml
    - name: Generate SCIP indexes
      uses: your-org/scip-index-action@v1
      with:
        working-directory: ./src
```

### Using Outputs

```yaml
    - name: Generate SCIP indexes
      id: scip
      uses: your-org/scip-index-action@v1

    - name: Process results
      run: |
        echo "Projects processed: ${{ steps.scip.outputs.success-count }}"
        echo "Total projects found: ${{ steps.scip.outputs.total-count }}"
        if [[ "${{ steps.scip.outputs.skipped }}" == "true" ]]; then
          echo "Processing was skipped - no changes detected"
        fi
```

## Requirements

### Docker Image
Your container image must have the following SCIP tools pre-installed:
- `scip-go` - for Go projects
- `scip-typescript` - for TypeScript/JavaScript projects
- `scip-python` - for Python projects
- `scip-java` - for Java projects

### Permissions
```yaml
permissions:
  contents: read
  pull-requests: write  # Required for PR comments
```

### Git Configuration
```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0  # Required for git diff comparison
```

## Supported Project Types

| Language | Project Files |
|----------|---------------|
| **Go** | `go.mod` |
| **TypeScript/JavaScript** | `package.json` |
| **Python** | `setup.py`, `pyproject.toml`, `requirements.txt`, `Pipfile` |
| **Java** | `pom.xml`, `build.gradle`, `build.gradle.kts` |

## How It Works

1. **Change Detection**: Uses `git diff` to find files modified in the PR/commit
2. **Project Mapping**: For each changed file, walks up the directory tree to find the nearest project root
3. **Language Detection**: Identifies project type based on configuration files
4. **Index Generation**: Runs appropriate SCIP indexer for each project
5. **Result Reporting**: Comments on PR with generation results and links to workflow logs

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `working-directory` | Working directory to run the action from | No | `.` |

## Outputs

| Output | Description |
|--------|-------------|
| `success-count` | Number of projects successfully processed |
| `total-count` | Total number of projects found |
| `failed-projects` | List of projects that failed processing |
| `changed-projects` | List of projects that had changes |
| `skipped` | Whether processing was skipped (no changes found) |
| `index-list` | List of generated index files |
| `total-size` | Total size of generated indexes |
