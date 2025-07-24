#!/usr/bin/env Rscript

# Build validation script for R Markdown analyses
# Tests the complete build pipeline

library(blogdown)
library(yaml)

test_build <- function() {
  cat("🔨 Testing build pipeline...\n")
  errors <- c()
  
  # 1. Clean build environment
  cat("  🧹 Cleaning build environment...\n")
  if (dir.exists("public")) {
    unlink("public", recursive = TRUE)
  }
  
  # 2. Test blogdown build
  cat("  🏗️  Running blogdown::build_site()...\n")
  tryCatch({
    blogdown::build_site()
  }, error = function(e) {
    errors <<- c(errors, paste("Build failed:", e$message))
    return(NULL)
  })
  
  if (length(errors) > 0) {
    return(list(success = FALSE, errors = errors))
  }
  
  # 3. Validate HTML output
  cat("  🔍 Validating HTML output...\n")
  analyses_dir <- "content/analyses"
  if (dir.exists(analyses_dir)) {
    rmd_files <- list.files(analyses_dir, pattern = "\\.Rmd$", full.names = TRUE)
    
    for (rmd_file in rmd_files) {
      basename <- tools::file_path_sans_ext(basename(rmd_file))
      
      # Check if HTML was generated
      expected_html <- file.path(analyses_dir, paste0(basename, ".html"))
      if (!file.exists(expected_html)) {
        errors <- c(errors, paste("HTML not generated for:", basename))
        next
      }
      
      # Check if public URL exists
      expected_public <- file.path("public/analyses", basename, "index.html")
      if (!file.exists(expected_public)) {
        errors <- c(errors, paste("Public URL not created for:", basename))
        next
      }
      
      # Check for R-generated figures
      figures_dir <- file.path(analyses_dir, paste0(basename, "_files"))
      if (dir.exists(figures_dir)) {
        public_figures <- file.path("public/analyses", basename, paste0(basename, "_files"))
        if (!dir.exists(public_figures)) {
          errors <- c(errors, paste("R-generated figures not copied for:", basename))
        }
      }
      
      # Validate HTML content
      html_content <- paste(readLines(expected_html), collapse = "\n")
      
      # Check for AI warning
      if (!grepl("AI-Generated Analysis Notice", html_content)) {
        errors <- c(errors, paste("AI warning missing in HTML for:", basename))
      }
      
      # Check for broken image references
      img_refs <- regmatches(html_content, gregexpr('src="([^"]+)"', html_content))[[1]]
      for (img_ref in img_refs) {
        src_path <- gsub('src="([^"]+)"', '\\1', img_ref)
        if (startsWith(src_path, "/analyses/")) {
          full_path <- file.path("public", gsub("^/", "", src_path))
          if (!file.exists(full_path)) {
            errors <- c(errors, paste("Broken image reference:", src_path, "in", basename))
          }
        }
      }
    }
  }
  
  # 4. Return results
  if (length(errors) > 0) {
    cat("❌ BUILD VALIDATION FAILED\n")
    for (error in errors) {
      cat("  🚨", error, "\n")
    }
    return(list(success = FALSE, errors = errors))
  } else {
    cat("✅ BUILD VALIDATION PASSED\n")
    return(list(success = TRUE, errors = c()))
  }
}

# Main execution
result <- test_build()
if (!result$success) {
  quit(status = 1)
}