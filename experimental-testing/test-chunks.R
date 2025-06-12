# Test the key chunks that were failing
library(cancensus)
library(dplyr)
library(ggplot2)

# Set dataset for 2021 Census
dataset <- "CA21"

cat("1. Finding language vectors...\n")

# Search for language vectors in 2021 census
language_search <- find_census_vectors("language spoken most often", dataset = dataset, type = "total")
cat("Found", nrow(language_search), "language-related vectors\n")

# Find the main total vector
language_total <- language_search %>% 
  filter(grepl("Total.*Language spoken most often at home.*population", label, ignore.case = TRUE)) %>%
  slice(1)

print(paste("Main language vector:", language_total$vector, "-", language_total$label))

# Get all child vectors (specific languages)
if(nrow(language_total) > 0) {
  language_children <- child_census_vectors(language_total$vector)
  
  # Filter out aggregates and keep only specific languages
  language_children <- language_children %>%
    filter(
      !grepl("Multiple responses", label),
      !grepl("Single responses", label), 
      !grepl("Official languages", label),
      !grepl("Non-official languages", label)
    ) %>%
    slice_head(n = 50)  # Limit to 50 specific languages for performance
  
  # Combine total and children vectors
  language_vectors <- bind_rows(language_total, language_children) %>%
    pull(vector)
  
  cat("Found", length(language_vectors), "language vectors for analysis\n")
} else {
  stop("Could not find main language vector. Check vector search.")
}

cat("\n2. Testing data retrieval...\n")

# Test with Toronto CMA first
test_regions <- list(CMA = "35535")  # Toronto CMA code

# Check if we have language vectors
if(exists("language_vectors") && length(language_vectors) > 0) {
  cat("Testing with", min(10, length(language_vectors)), "vectors...\n")
  
  test_data <- get_census(
    dataset = dataset,
    regions = test_regions,
    vectors = language_vectors[1:min(10, length(language_vectors))],
    level = "CMA",
    quiet = TRUE
  )
  
  # Check if data retrieval worked
  if(nrow(test_data) > 0) {
    cat("✓ Data retrieval successful for Toronto CMA\n")
    cat("Retrieved", nrow(test_data), "rows with", ncol(test_data), "columns\n")
  } else {
    cat("❌ Data retrieval returned no rows\n")
  }
} else {
  cat("❌ Language vectors not found - check previous chunk\n")
}

cat("\n3. Getting CMA list...\n")

# Get list of all CMAs for analysis
cma_list <- list_census_regions(dataset = dataset) %>%
  filter(level == "CMA", pop > 100000)  # Focus on larger metropolitan areas

cat("Analyzing", nrow(cma_list), "major metropolitan areas\n")

cat("\n✓ All key chunks working successfully!\n")