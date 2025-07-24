#!/usr/bin/env Rscript

# Comprehensive testing script for Census Monkey Typewriter analyses
# Runs all validation, build, and deployment tests

cat("🧪 Census Monkey Typewriter - Analysis Testing Suite\n")
cat(paste(rep("=", 50), collapse = ""), "\n\n")

# 1. Pre-deployment validation
cat("📋 PHASE 1: Pre-deployment validation\n")
analyses_dir <- "content/analyses"
rmd_files <- list.files(analyses_dir, pattern = "\\.Rmd$", full.names = TRUE)

validation_errors <- 0
for (rmd_file in rmd_files) {
  result <- system(paste("Rscript scripts/validate_analysis.R", rmd_file), ignore.stdout = FALSE)
  if (result != 0) {
    validation_errors <- validation_errors + 1
  }
}

if (validation_errors > 0) {
  cat("❌ PHASE 1 FAILED:", validation_errors, "validation errors\n")
  cat("Fix validation errors before proceeding.\n")
  quit(status = 1)
} else {
  cat("✅ PHASE 1 PASSED: All analyses validated\n\n")
}

# 2. Build testing
cat("🔨 PHASE 2: Build testing\n")
build_result <- system("Rscript scripts/test_build.R", ignore.stdout = FALSE)

if (build_result != 0) {
  cat("❌ PHASE 2 FAILED: Build errors detected\n")
  quit(status = 1)
} else {
  cat("✅ PHASE 2 PASSED: Build completed successfully\n\n")
}

# 3. Deployment verification (optional - requires deployed site)
cat("🌐 PHASE 3: Deployment verification\n")
deploy_result <- system("Rscript scripts/verify_deployment.R", ignore.stdout = FALSE)

if (deploy_result != 0) {
  cat("❌ PHASE 3 FAILED: Deployment issues detected\n")
  cat("Note: This may be expected if the site hasn't been deployed yet.\n")
} else {
  cat("✅ PHASE 3 PASSED: Deployment verified\n\n")
}

cat("🎉 ALL TESTS COMPLETED\n")

# Summary
cat("\n📊 SUMMARY:\n")
cat("✅ Validation: PASSED\n")
cat("✅ Build: PASSED\n")
if (deploy_result == 0) {
  cat("✅ Deployment: PASSED\n")
} else {
  cat("⚠️  Deployment: CHECK REQUIRED\n")
}

cat("\n🚀 Ready for deployment!\n")