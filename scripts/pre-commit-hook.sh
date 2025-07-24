#!/bin/bash

# Pre-commit hook for Census Monkey Typewriter analyses
# Add to .git/hooks/pre-commit to run automatically

echo "🔍 Running pre-commit validation for Census Monkey Typewriter analyses..."

# Check if any .Rmd files in content/analyses are being committed
changed_rmd_files=$(git diff --cached --name-only | grep "content/analyses/.*\.Rmd$")

if [ -z "$changed_rmd_files" ]; then
    echo "✅ No analysis files changed, skipping validation"
    exit 0
fi

echo "📝 Found changed analysis files:"
echo "$changed_rmd_files"

# Validate each changed .Rmd file
validation_failed=false
for rmd_file in $changed_rmd_files; do
    echo "🔍 Validating $rmd_file..."
    if ! Rscript scripts/validate_analysis.R "$rmd_file"; then
        validation_failed=true
    fi
done

if [ "$validation_failed" = true ]; then
    echo ""
    echo "❌ PRE-COMMIT VALIDATION FAILED"
    echo "Please fix the validation errors before committing."
    echo ""
    echo "To bypass this check (not recommended), run:"
    echo "git commit --no-verify"
    exit 1
fi

echo ""
echo "✅ PRE-COMMIT VALIDATION PASSED"
echo "All analysis files validated successfully!"

exit 0