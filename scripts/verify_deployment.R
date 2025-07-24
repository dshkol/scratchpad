#!/usr/bin/env Rscript

# Post-deployment verification script
# Tests live site for broken links, missing content, etc.

library(httr)
library(xml2)
library(rvest)

verify_deployment <- function(base_url = "https://www.dshkol.com") {
  cat("🌐 Verifying deployment at:", base_url, "\n")
  errors <- c()
  warnings <- c()
  
  # 1. Get list of analyses from local content
  analyses_dir <- "content/analyses"
  if (!dir.exists(analyses_dir)) {
    errors <- c(errors, "Analyses directory not found")
    return(list(success = FALSE, errors = errors))
  }
  
  rmd_files <- list.files(analyses_dir, pattern = "\\.Rmd$", full.names = FALSE)
  basenames <- tools::file_path_sans_ext(rmd_files)
  
  for (basename in basenames) {
    cat("  🔍 Testing analysis:", basename, "\n")
    
    # 2. Test main page URL
    analysis_url <- paste0(base_url, "/analyses/", basename, "/")
    
    tryCatch({
      response <- GET(analysis_url, timeout(30))
      if (status_code(response) != 200) {
        errors <- c(errors, paste("Analysis page not accessible:", analysis_url, "- Status:", status_code(response)))
        next
      }
    }, error = function(e) {
      errors <<- c(errors, paste("Failed to access:", analysis_url, "- Error:", e$message))
      next
    })
    
    # 3. Parse HTML and check content
    tryCatch({
      page_content <- content(response, "text")
      
      # Check for AI warning
      if (!grepl("AI-Generated Analysis Notice", page_content)) {
        errors <- c(errors, paste("Missing AI warning on:", basename))
      }
      
      # Check for basic content structure
      required_sections <- c("Findings", "Analysis", "Conclusion")
      found_sections <- sum(sapply(required_sections, function(section) grepl(section, page_content)))
      if (found_sections == 0) {
        warnings <- c(warnings, paste("No recognizable content sections found on:", basename))
      }
      
      # 4. Extract and test image URLs
      doc <- read_html(page_content)
      img_nodes <- html_nodes(doc, "img")
      img_srcs <- html_attr(img_nodes, "src")
      
      for (img_src in img_srcs) {
        if (!is.na(img_src) && startsWith(img_src, "/")) {
          img_url <- paste0(base_url, img_src)
          
          tryCatch({
            img_response <- HEAD(img_url, timeout(10))
            if (status_code(img_response) != 200) {
              errors <- c(errors, paste("Broken image on", basename, ":", img_src, "- Status:", status_code(img_response)))
            }
          }, error = function(e) {
            errors <- c(errors, paste("Image request failed for", basename, ":", img_src, "- Error:", e$message))
          })
        }
      }
      
      # 5. Test CSS and JS resources
      css_nodes <- html_nodes(doc, "link[rel='stylesheet']")
      css_hrefs <- html_attr(css_nodes, "href")
      
      js_nodes <- html_nodes(doc, "script[src]")
      js_srcs <- html_attr(js_nodes, "src")
      
      all_resources <- c(css_hrefs, js_srcs)
      for (resource in all_resources) {
        if (!is.na(resource) && startsWith(resource, "/")) {
          resource_url <- paste0(base_url, resource)
          
          tryCatch({
            resource_response <- HEAD(resource_url, timeout(10))
            if (status_code(resource_response) != 200) {
              warnings <- c(warnings, paste("Resource not found for", basename, ":", resource))
            }
          }, error = function(e) {
            warnings <- c(warnings, paste("Resource request failed for", basename, ":", resource))
          })
        }
      }
      
    }, error = function(e) {
      errors <<- c(errors, paste("Failed to parse HTML for:", basename, "- Error:", e$message))
    })
  }
  
  # 6. Return results
  cat("\n")
  if (length(errors) > 0) {
    cat("❌ DEPLOYMENT VERIFICATION FAILED\n")
    for (error in errors) {
      cat("  🚨", error, "\n")
    }
  } else {
    cat("✅ DEPLOYMENT VERIFICATION PASSED\n")
  }
  
  if (length(warnings) > 0) {
    cat("\n⚠️  WARNINGS:\n")
    for (warning in warnings) {
      cat("  ⚠️ ", warning, "\n")
    }
  }
  
  return(list(
    success = length(errors) == 0,
    errors = errors,
    warnings = warnings
  ))
}

# Main execution
args <- commandArgs(trailingOnly = TRUE)
base_url <- ifelse(length(args) > 0, args[1], "https://www.dshkol.com")

result <- verify_deployment(base_url)
if (!result$success) {
  quit(status = 1)
}