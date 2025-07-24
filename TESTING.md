# Census Monkey Typewriter - Testing Framework

This document describes the comprehensive testing framework for Census Monkey Typewriter analyses to prevent deployment issues and ensure quality.

## Overview

The testing framework consists of three phases:
1. **Pre-deployment validation** - Catch issues before commit
2. **Build testing** - Ensure clean builds
3. **Post-deployment verification** - Validate live site

## Scripts

### `scripts/validate_analysis.R`
Validates individual R Markdown files for:
- ✅ Required YAML frontmatter fields
- ✅ No slug parameters (prevents path issues)
- ✅ AI-Generated Analysis Notice present
- ✅ Data file paths exist
- ✅ Static image paths exist
- ✅ R code can be parsed

**Usage:**
```bash
Rscript scripts/validate_analysis.R content/analyses/filename.Rmd
```

### `scripts/test_build.R`
Tests the complete build pipeline:
- ✅ Clean build environment
- ✅ Successful blogdown::build_site()
- ✅ HTML files generated
- ✅ Public URLs created
- ✅ R-generated figures copied
- ✅ AI warnings in HTML
- ✅ No broken image references

**Usage:**
```bash
Rscript scripts/test_build.R
```

### `scripts/verify_deployment.R`
Verifies the live deployed site:
- ✅ Analysis pages accessible (200 status)
- ✅ AI warnings present
- ✅ Content structure intact
- ✅ All images load correctly
- ✅ CSS/JS resources available

**Usage:**
```bash
Rscript scripts/verify_deployment.R [base_url]
# Default: https://www.dshkol.com
```

### `scripts/run_all_tests.R`
Runs all tests in sequence for comprehensive validation.

**Usage:**
```bash
Rscript scripts/run_all_tests.R
```

## Local Development Workflow

### 1. Install Pre-commit Hook (Recommended)
```bash
cp scripts/pre-commit-hook.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### 2. Before Committing
```bash
# Validate specific file
Rscript scripts/validate_analysis.R content/analyses/new-analysis.Rmd

# Or run all tests
Rscript scripts/run_all_tests.R
```

### 3. Adding New Analyses

**Required YAML frontmatter:**
```yaml
---
title: "Analysis Title"
author: "Census Monkey Typewriter"
date: '2025-07-20'
summary: "Brief description"
categories:
  - analyses
  - exploratory  # or 'serious'
tags:
  - tag1
  - tag2
# NO SLUG PARAMETER - causes path issues
---

> **⚠️ AI-Generated Analysis Notice**: This analysis was produced by an AI system...
```

**File naming convention:**
- Format: `YYYY-MM-DD-descriptive-name.Rmd`
- No spaces or special characters
- Hugo will create URLs like `/analyses/YYYY-MM-DD-descriptive-name/`

**Data file references:**
```r
# Use relative paths to static directory
data <- read_csv("../../static/analyses/analysis-name-data/file.csv")
models <- readRDS("../../static/analyses/analysis-name-data/models.rds")
```

**Static image references:**
```markdown
![Description](/analyses/analysis-name-figures/image.png)
```

## CI/CD Integration

### GitHub Actions
The `.github/workflows/test-analyses.yml` workflow automatically:
- ✅ Runs on pushes to `content/analyses/**`
- ✅ Validates all R Markdown files
- ✅ Tests build process
- ✅ Verifies deployment (post-deploy)
- ✅ Comments on PRs with results

### Manual Deployment Verification
After deploying, run:
```bash
Rscript scripts/verify_deployment.R
```

## Common Issues Caught by Tests

### ❌ Broken Image Paths
- **Problem**: R-generated figures use wrong relative paths
- **Detection**: `verify_deployment.R` checks all image URLs
- **Prevention**: `validate_analysis.R` checks static image paths

### ❌ Missing AI Warnings
- **Problem**: Analyses missing required AI disclosure
- **Detection**: All scripts check for "AI-Generated Analysis Notice"
- **Prevention**: Pre-commit hook catches before commit

### ❌ Data File Issues
- **Problem**: Missing data files break R execution
- **Detection**: `validate_analysis.R` checks file existence
- **Prevention**: Validate before committing

### ❌ YAML Issues
- **Problem**: Slug parameters cause Hugo/blogdown path mismatch
- **Detection**: `validate_analysis.R` flags slug parameters
- **Prevention**: Remove slugs, use filename-based URLs

### ❌ Build Failures
- **Problem**: R Markdown won't render
- **Detection**: `test_build.R` tests complete pipeline
- **Prevention**: Local testing before push

## Best Practices

1. **Always run validation** before committing new analyses
2. **No slug parameters** in YAML frontmatter
3. **Include AI warnings** in every analysis
4. **Use absolute paths** for static images
5. **Test locally** with `scripts/run_all_tests.R`
6. **Verify deployment** after going live

## Dependencies

**R packages required:**
```r
install.packages(c(
  "blogdown", "tidyverse", "tidycensus", "sf", "viridis", 
  "scales", "knitr", "kableExtra", "ggrepel", "fixest",
  "yaml", "rmarkdown", "httr", "xml2", "rvest"
))
```

**System requirements:**
- R 4.5+
- Pandoc (for R Markdown rendering)
- Hugo 0.148.1+ (for site building)

## Troubleshooting

### "pandoc not found"
```bash
# Install via Homebrew
brew install pandoc

# Or use RStudio's bundled pandoc
export PATH="/Applications/RStudio.app/Contents/Resources/app/resources/pandoc:$PATH"
```

### "Broken image paths"
- Check that static images exist in `static/analyses/`
- Use absolute paths starting with `/analyses/`
- Regenerate HTML after fixing paths

### "Build failures"
- Check data file paths point to existing files
- Ensure all R packages are installed
- Remove any `slug:` parameters from YAML

---

This testing framework prevents the manual back-and-forth debugging we experienced and ensures reliable deployment of Census Monkey Typewriter analyses.