# Language Diversity in Canada - 2021 Census Test Script
# Replicating the 2017 blog post with 2021 data

# Load required libraries
library(cancensus)
library(dplyr)
library(ggplot2)

# Function to calculate Language Diversity Index
calculate_ldi <- function(proportions) {
  proportions <- proportions[!is.na(proportions)]
  proportions <- proportions[proportions > 0]
  
  if(length(proportions) == 0) return(NA)
  
  # Normalize to ensure sum = 1
  proportions <- proportions / sum(proportions)
  
  # Calculate LDI = 1 - sum(pi^2)
  ldi <- 1 - sum(proportions^2)
  return(ldi)
}

cat("=== Language Diversity in Canada - 2021 Census Analysis ===\n\n")

# Set dataset for 2021 Census
dataset <- "CA21"

cat("1. Finding language vectors in 2021 census...\n")

# Search for language vectors
language_search <- find_census_vectors("language spoken most often", dataset = dataset, type = "total")
cat("Found", nrow(language_search), "language-related vectors\n")

# Find the main total vector
language_total <- language_search %>% 
  filter(grepl("Total.*Language spoken most often at home.*population", label, ignore.case = TRUE)) %>%
  slice(1)

if(nrow(language_total) > 0) {
  cat("Main language vector:", language_total$vector, "-", substring(language_total$label, 1, 60), "...\n")
  
  # Get child vectors (specific languages)
  language_children <- child_census_vectors(language_total$vector)
  
  cat("Found", nrow(language_children), "specific language categories\n")
  
  # Filter to get only leaf nodes (actual language categories, not aggregates)
  language_leaves <- language_children %>%
    filter(!grepl("Multiple responses|Single responses|Official|Non-official", label)) %>%
    slice_head(n = 50)  # Limit to first 50 for testing
  
  cat("Using", nrow(language_leaves), "language leaf categories for analysis\n")
  
  # Get all language vectors
  language_vectors <- c(language_total$vector, language_leaves$vector)
  
} else {
  stop("Could not find main language vector")
}

cat("\n2. Getting list of major Canadian metropolitan areas...\n")

# Get major CMAs
cma_list <- list_census_regions(dataset = dataset) %>%
  filter(level == "CMA", pop > 100000)  # Focus on larger metropolitan areas

cat("Analyzing", nrow(cma_list), "major metropolitan areas\n")

cat("\n3. Retrieving language data for all CMAs...\n")

# Get language data for all major CMAs
language_data <- get_census(
  dataset = dataset,
  regions = list(CMA = cma_list$region),
  vectors = language_vectors,
  level = "CMA",
  labels = "short",
  quiet = TRUE
)

cat("Retrieved data for", nrow(language_data), "metropolitan areas with", 
    length(language_vectors), "language categories\n")

cat("\n4. Calculating Language Diversity Index...\n")

# Get language column names (excluding the total)
language_cols <- names(language_data)[grepl("^v_CA21_", names(language_data))]
total_col <- language_total$vector

# Calculate LDI for each CMA
ldi_results <- language_data %>%
  select(GeoUID, name = `Region Name`, all_of(language_cols)) %>%
  rowwise() %>%
  mutate(
    total_speakers = get(total_col),
    # Calculate proportions for specific languages (excluding total)
    language_counts = list(
      c_across(all_of(setdiff(language_cols, total_col)))
    ),
    # Calculate LDI
    ldi = calculate_ldi(unlist(language_counts) / total_speakers)
  ) %>%
  ungroup() %>%
  select(GeoUID, name, total_speakers, ldi) %>%
  arrange(desc(ldi)) %>%
  filter(!is.na(ldi))

cat("Language Diversity Index calculated for", nrow(ldi_results), "metropolitan areas\n")

cat("\n5. Results - Top 15 Most Linguistically Diverse Canadian CMAs (2021):\n")
cat("=================================================================\n")

top_15 <- ldi_results %>%
  slice_head(n = 15) %>%
  mutate(
    rank = row_number(),
    ldi_rounded = round(ldi, 4),
    total_formatted = scales::comma(total_speakers)
  )

for(i in 1:nrow(top_15)) {
  cat(sprintf("%2d. %-30s LDI: %.4f (Pop: %s)\n", 
              top_15$rank[i], 
              top_15$name[i], 
              top_15$ldi_rounded[i], 
              top_15$total_formatted[i]))
}

cat("\n6. Major Cities Comparison:\n")
cat("===========================\n")

major_cities <- c("Toronto", "Montréal", "Vancouver", "Calgary", "Edmonton", "Ottawa - Gatineau")

major_cities_ldi <- ldi_results %>%
  filter(grepl(paste(major_cities, collapse = "|"), name, ignore.case = TRUE)) %>%
  arrange(desc(ldi)) %>%
  mutate(
    rank_overall = match(GeoUID, ldi_results$GeoUID),
    ldi_rounded = round(ldi, 4)
  )

for(i in 1:nrow(major_cities_ldi)) {
  cat(sprintf("%-25s: LDI %.4f (Rank #%d overall)\n", 
              major_cities_ldi$name[i], 
              major_cities_ldi$ldi_rounded[i], 
              major_cities_ldi$rank_overall[i]))
}

cat("\n7. Summary Statistics:\n")
cat("======================\n")

summary_stats <- ldi_results %>%
  summarise(
    n_cmas = n(),
    mean_ldi = mean(ldi),
    median_ldi = median(ldi),
    min_ldi = min(ldi),
    max_ldi = max(ldi),
    sd_ldi = sd(ldi)
  )

cat("Number of CMAs analyzed:", summary_stats$n_cmas, "\n")
cat("Mean LDI:", round(summary_stats$mean_ldi, 4), "\n")
cat("Median LDI:", round(summary_stats$median_ldi, 4), "\n")
cat("Range:", round(summary_stats$min_ldi, 4), "to", round(summary_stats$max_ldi, 4), "\n")
cat("Standard Deviation:", round(summary_stats$sd_ldi, 4), "\n")

cat("\n8. Key Findings:\n")
cat("================\n")

most_diverse <- ldi_results %>% slice_max(ldi, n = 1)
cat("• Most linguistically diverse CMA:", most_diverse$name, "\n")
cat("• LDI Score:", round(most_diverse$ldi, 4), "\n")
cat("• This means a", round(most_diverse$ldi * 100, 1), "% probability that two random residents speak different mother tongues\n")

toronto_rank <- which(grepl("Toronto", ldi_results$name))
if(length(toronto_rank) > 0) {
  cat("• Toronto ranks #", toronto_rank, "in linguistic diversity nationally\n")
}

cat("\n=== Analysis Complete ===\n")
cat("This replicates the 2017 'Language Diversity in Canada' analysis using 2021 Census data\n")
cat("The workflow demonstrates advanced cancensus usage patterns:\n")
cat("- Hierarchical vector discovery and selection\n")
cat("- Multi-region data retrieval\n")
cat("- Complex data transformation and calculation\n")
cat("- Statistical analysis and ranking\n")