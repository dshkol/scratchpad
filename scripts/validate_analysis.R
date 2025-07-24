#!/usr/bin/env Rscript

# Comprehensive validation script for R Markdown analyses
# Usage: Rscript scripts/validate_analysis.R content/analyses/filename.Rmd

library(yaml)
library(rmarkdown)
library(blogdown)

validate_analysis <- function(rmd_file) {
  cat("🔍 Validating:", basename(rmd_file), "\n")
  errors <- c()
  warnings <- c()
  
  # 1. YAML Frontmatter Validation
  cat("  📋 Checking YAML frontmatter...\n")
  yaml_content <- rmarkdown::yaml_front_matter(rmd_file)
  
  # Required fields
  required_fields <- c("title", "author", "date", "summary", "categories", "tags")
  missing_fields <- setdiff(required_fields, names(yaml_content))
  if (length(missing_fields) > 0) {
    errors <- c(errors, paste("Missing required YAML fields:", paste(missing_fields, collapse = ", ")))
  }
  
  # No slug allowed (causes path issues)
  if ("slug" %in% names(yaml_content) && yaml_content$slug != "") {
    errors <- c(errors, "Remove 'slug' parameter - causes Hugo/blogdown path mismatch")
  }
  
  # AI warning check
  content <- readLines(rmd_file)
  ai_warning_present <- any(grepl("AI-Generated Analysis Notice", content))
  if (!ai_warning_present) {
    errors <- c(errors, "Missing AI-Generated Analysis Notice warning")
  }
  
  # 2. Data File Path Validation
  cat("  📁 Checking data file paths...\n")
  data_patterns <- c(
    'read_csv\\("([^"]+)"\\)',
    'readRDS\\("([^"]+)"\\)',
    'read\\.csv\\("([^"]+)"\\)'
  )
  
  rmd_content <- paste(content, collapse = "\n")
  for (pattern in data_patterns) {
    matches <- regmatches(rmd_content, gregexpr(pattern, rmd_content, perl = TRUE))[[1]]
    if (length(matches) > 0) {
      for (match in matches) {
        file_path <- gsub('.*"([^"]+)".*', '\\1', match)
        if (startsWith(file_path, "../../static/")) {
          # Convert to actual file path
          actual_path <- gsub("../../static/", "static/", file_path)
          if (!file.exists(actual_path)) {
            errors <- c(errors, paste("Data file not found:", actual_path))
          }
        }
      }
    }
  }
  
  # 3. Static Image Path Validation
  cat("  🖼️  Checking static image paths...\n")
  image_patterns <- c(
    '!\\[.*?\\]\\(([^)]+)\\)',
    'include_graphics\\("([^"]+)"\\)'
  )
  
  for (pattern in image_patterns) {
    matches <- regmatches(rmd_content, gregexpr(pattern, rmd_content, perl = TRUE))[[1]]
    if (length(matches) > 0) {
      for (match in matches) {
        if (grepl("include_graphics", match)) {
          image_path <- gsub('.*"([^"]+)".*', '\\1', match)
        } else {
          image_path <- gsub('.*\\(([^)]+)\\).*', '\\1', match)
        }
        
        if (startsWith(image_path, "/analyses/")) {
          # Convert to static file path
          static_path <- gsub("^/analyses/", "static/analyses/", image_path)
          if (!file.exists(static_path)) {
            errors <- c(errors, paste("Static image not found:", static_path))
          }
        }
      }
    }
  }
  
  # 4. R Code Validation
  cat("  ⚙️  Validating R code execution...\n")
  tryCatch({
    # Check if the R code can be parsed
    parsed <- parse(rmd_file)
  }, error = function(e) {
    errors <<- c(errors, paste("R code parsing error:", e$message))
  })
  
  # 5. Output Results
  cat("\n")
  if (length(errors) > 0) {
    cat("❌ VALIDATION FAILED\n")
    for (error in errors) {
      cat("  🚨", error, "\n")
    }
    return(FALSE)
  } else {
    cat("✅ VALIDATION PASSED\n")
    if (length(warnings) > 0) {
      for (warning in warnings) {
        cat("  ⚠️ ", warning, "\n")
      }
    }
    return(TRUE)
  }
}

# Main execution
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  cat("Usage: Rscript validate_analysis.R <path_to_rmd_file>\n")
  quit(status = 1)
}

rmd_file <- args[1]
if (!file.exists(rmd_file)) {
  cat("❌ File not found:", rmd_file, "\n")
  quit(status = 1)
}

success <- validate_analysis(rmd_file)
if (!success) {
  quit(status = 1)
}