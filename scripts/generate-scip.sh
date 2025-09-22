#!/bin/bash
# scripts/generate-scip.sh

echo "=== Processing $PROJECT_COUNT changed projects ==="

if [[ $PROJECT_COUNT -eq 0 ]]; then
  echo "No projects with changes detected. Skipping SCIP index generation."
  echo "success_count=0" >> $GITHUB_OUTPUT
  echo "total_count=0" >> $GITHUB_OUTPUT
  echo "failed_projects=" >> $GITHUB_OUTPUT
  echo "skipped=true" >> $GITHUB_OUTPUT
  exit 0
fi

# Initialize counters
success_count=0
total_count=0
failed_projects=""

# Function to detect project language and generate index
generate_scip_index() {
  local dir=$1
  echo "Processing directory: $dir"
  
  cd "$dir"
  local project_success=false
  
  # Check for Go projects
  if [[ -f "go.mod" ]]; then
    echo "  -> Detected Go project"
    echo "  -> Generating Go SCIP index..."
    if scip-go --output=index.scip; then
      project_success=true
    else
      echo "  -> Failed to generate Go index"
      failed_projects="$failed_projects\n- $dir (Go)"
    fi
    ((total_count++))
  fi
  
  # Check for Node.js/TypeScript projects
  if [[ -f "package.json" ]]; then
    echo "  -> Detected Node.js/TypeScript project"
    
    # Install dependencies if needed (with error handling)
    echo "  -> Installing dependencies..."
    if [[ -f "package-lock.json" ]]; then
      npm ci || echo "  -> npm ci failed, continuing..."
    elif [[ -f "yarn.lock" ]]; then
      if ! command -v yarn &> /dev/null; then
        npm install -g yarn || echo "  -> Failed to install yarn"
      fi
      yarn install --frozen-lockfile || yarn install || echo "  -> yarn install failed, continuing..."
    elif [[ -f "pnpm-lock.yaml" ]]; then
      if ! command -v pnpm &> /dev/null; then
        npm install -g pnpm || echo "  -> Failed to install pnpm"
      fi
      pnpm install --frozen-lockfile || pnpm install || echo "  -> pnpm install failed, continuing..."
    else
      npm install || echo "  -> npm install failed, continuing..."
    fi
    
    echo "  -> Generating TypeScript SCIP index..."
    if scip-typescript index --output=index.scip; then
      project_success=true
    else
      echo "  -> Failed to generate TypeScript index"
      failed_projects="$failed_projects\n- $dir (TypeScript)"
    fi
    ((total_count++))
  fi
  
  # Check for Python projects
  if [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]] || [[ -f "requirements.txt" ]] || [[ -f "Pipfile" ]]; then
    echo "  -> Detected Python project"
    
    # Install dependencies if requirements file exists
    if [[ -f "requirements.txt" ]]; then
      echo "  -> Installing Python requirements..."
      pip3 install -r requirements.txt || echo "  -> Failed to install Python dependencies, continuing..."
    elif [[ -f "pyproject.toml" ]]; then
      echo "  -> Installing Python project..."
      pip3 install . || echo "  -> Failed to install Python project, continuing..."
    fi
    
    echo "  -> Generating Python SCIP index..."
    if scip-python index --output=index.scip; then
      project_success=true
    else
      echo "  -> Failed to generate Python index"
      failed_projects="$failed_projects\n- $dir (Python)"
    fi
    ((total_count++))
  fi
  
  # Check for Java/Maven projects
  if [[ -f "pom.xml" ]]; then
    echo "  -> Detected Maven project"
    echo "  -> Generating Java SCIP index..."
    if scip-java index --output=index.scip; then
      project_success=true
    else
      echo "  -> Failed to generate Java index"
      failed_projects="$failed_projects\n- $dir (Maven)"
    fi
    ((total_count++))
  fi
  
  # Check for Java/Gradle projects
  if [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
    echo "  -> Detected Gradle project"
    echo "  -> Generating Java SCIP index..."
    if scip-java index --output=index.scip; then
      project_success=true
    else
      echo "  -> Failed to generate Java index"
      failed_projects="$failed_projects\n- $dir (Gradle)"
    fi
    ((total_count++))
  fi
  
  # Check if index was created
  if [[ -f "index.scip" ]]; then
    echo "  -> ✅ Successfully generated index.scip ($(stat -c%s index.scip 2>/dev/null || stat -f%z index.scip 2>/dev/null || echo "unknown") bytes)"
    if $project_success; then
      ((success_count++))
    fi
  else
    echo "  -> ❌ No index.scip generated"
  fi
  
  cd - > /dev/null
}

# Process changed projects using process substitution to avoid subshell
while read -r project_dir; do
  if [[ -n "$project_dir" ]]; then
    echo "=== Processing project: $project_dir ==="
    # Continue processing even if one project fails
    if ! generate_scip_index "$project_dir"; then
      echo "  -> ⚠️  Project processing failed but continuing with others..."
    fi
  fi
done <<< "$CHANGED_PROJECTS"

# Export results for use in comment
echo "success_count=$success_count" >> $GITHUB_OUTPUT
echo "total_count=$total_count" >> $GITHUB_OUTPUT
{
  echo "failed_projects<<EOF"
  echo -e "$failed_projects"
  echo "EOF"
} >> $GITHUB_OUTPUT
echo "skipped=false" >> $GITHUB_OUTPUT

echo "=== Summary ==="
echo "Processed $total_count projects, $success_count successful"
