---
title: "Language Diversity in Canada - 2021 Census Update"
author: "Dmitry Shkolnik"
date: "2025-06-11"
output: 
  html_document:
    toc: true
    toc_float: true
    theme: flatly
    highlight: tango
    fig_width: 10
    fig_height: 8
---



## Introduction

This analysis replicates the 2017 "Language Diversity in Canada" blog post using 2021 Census data. We'll explore linguistic diversity patterns across Canadian metropolitan areas using the Language Diversity Index (LDI) and examine how these patterns may have shifted between 2016 and 2021.

## The Language Diversity Index

The Language Diversity Index, introduced by Greenberg (1956), calculates the probability that any two speakers in a population will speak different languages:

$$
LDI = 1 - \sum (P_i)^2
$$

Where $P_i$ is the proportion of speakers of language $i$. A higher LDI indicates greater linguistic diversity, with a theoretical maximum of 1.

## Setup and Data Acquisition


``` r
# Load required libraries
library(cancensus)
library(dplyr)
library(ggplot2)
library(sf)
```

```
## Error in library(sf): there is no package called 'sf'
```

``` r
library(knitr)
library(DT)

# Set dataset for 2021 Census
dataset <- "CA21"

# Check if API key is set
if(is.null(get_cancensus_api_key())) {
  cat("Note: cancensus API key not set. Some functionality may be limited.")
}
```

```
## Error in get_cancensus_api_key(): could not find function "get_cancensus_api_key"
```

## Finding 2021 Language Vectors

Let's identify the equivalent language vectors in the 2021 census data:


``` r
# Search for language vectors in 2021 census
language_search <- find_census_vectors("language spoken most often", dataset = dataset, type = "total")

# Display the results
kable(language_search[1:10, c("vector", "type", "label")], 
      caption = "Top 10 Language-related Vectors in 2021 Census")
```



Table: Top 10 Language-related Vectors in 2021 Census

|vector      |type  |label                                                                                                             |
|:-----------|:-----|:-----------------------------------------------------------------------------------------------------------------|
|v_CA21_2200 |Total |Total - Language spoken most often at home for the total population excluding institutional residents - 100% data |
|v_CA21_2203 |Total |Single responses                                                                                                  |
|v_CA21_2206 |Total |Official languages                                                                                                |
|v_CA21_2209 |Total |English                                                                                                           |
|v_CA21_2212 |Total |French                                                                                                            |
|v_CA21_2215 |Total |Non-official languages                                                                                            |
|v_CA21_2218 |Total |Indigenous languages                                                                                              |
|v_CA21_2221 |Total |Algonquian languages                                                                                              |
|v_CA21_2224 |Total |Blackfoot                                                                                                         |
|v_CA21_2227 |Total |Cree-Innu languages                                                                                               |


``` r
# Find the main language vector for 2021
language_total <- find_census_vectors("Total - Language spoken most often at home", 
                                    dataset = dataset, type = "total") %>%
  filter(grepl("Total.*Language spoken most often at home.*population", label, ignore.case = TRUE)) %>%
  slice(1)

print(paste("Main language vector:", language_total$vector, "-", language_total$label))
```

```
## [1] "Main language vector: v_CA21_2200 - Total - Language spoken most often at home for the total population excluding institutional residents - 100% data"
```

``` r
# Get all child vectors (specific languages)
if(nrow(language_total) > 0) {
  language_children <- child_census_vectors(language_total$vector) %>%
    filter(type == "total")  # Only get totals, not male/female breakdowns
  
  # Combine total and children vectors
  language_vectors <- bind_rows(language_total, language_children) %>%
    pull(vector)
  
  cat("Found", length(language_vectors), "language vectors for analysis\n")
} else {
  stop("Could not find main language vector. Check vector search.")
}
```

```
## Found 1 language vectors for analysis
```

## Testing Data Retrieval

Let's test with a small region first to ensure our approach works:


``` r
# Test with Toronto CMA first
test_regions <- list(CMA = "35535")  # Toronto CMA code

test_data <- get_census(
  dataset = dataset,
  regions = test_regions,
  vectors = language_vectors[1:10],  # Test with first 10 vectors
  level = "CMA",
  geo_format = "sf",
  quiet = TRUE
)
```

```
## Error in get_census(dataset = dataset, regions = test_regions, vectors = language_vectors[1:10], : The `sf` package is required to return geographies.
```

``` r
# Check if data retrieval worked
if(nrow(test_data) > 0) {
  cat("✓ Data retrieval successful for Toronto CMA\n")
  cat("Sample data structure:\n")
  str(test_data[1:5])
} else {
  stop("❌ Data retrieval failed")
}
```

```
## Error: object 'test_data' not found
```


``` r
# Get list of all CMAs for analysis
cma_list <- list_census_regions(dataset = dataset, level = "CMA") %>%
  filter(pop > 100000)  # Focus on larger metropolitan areas
```

```
## Error in list_census_regions(dataset = dataset, level = "CMA"): unused argument (level = "CMA")
```

``` r
cat("Analyzing", nrow(cma_list), "major metropolitan areas\n")
```

```
## Error: object 'cma_list' not found
```

``` r
kable(head(cma_list, 10), caption = "Major Canadian Metropolitan Areas (Sample)")
```

```
## Error: object 'cma_list' not found
```

## Full Data Retrieval


``` r
# Get language data for all major CMAs
cma_regions <- setNames(as.list(cma_list$region), cma_list$name)
```

```
## Error: object 'cma_list' not found
```

``` r
# Retrieve data for all CMAs
language_data <- get_census(
  dataset = dataset,
  regions = list(CMA = cma_list$region),
  vectors = language_vectors,
  level = "CMA",
  labels = "short",
  quiet = TRUE
)
```

```
## Error: object 'cma_list' not found
```

``` r
cat("Retrieved data for", nrow(language_data), "metropolitan areas\n")
```

```
## Error: object 'language_data' not found
```

``` r
cat("With", length(language_vectors), "language categories\n")
```

```
## With 1 language categories
```

## Calculate Language Diversity Index


``` r
# Function to calculate Language Diversity Index
calculate_ldi <- function(proportions) {
  # Remove any NA values and ensure proportions sum to 1
  proportions <- proportions[!is.na(proportions)]
  proportions <- proportions[proportions > 0]
  
  if(length(proportions) == 0) return(NA)
  
  # Normalize to ensure sum = 1
  proportions <- proportions / sum(proportions)
  
  # Calculate LDI = 1 - sum(pi^2)
  ldi <- 1 - sum(proportions^2)
  return(ldi)
}

# Prepare data for LDI calculation
# We need to extract the language count columns and calculate proportions
language_cols <- language_data %>%
  select(starts_with("v_CA21_")) %>%
  select(-any_of(c("v_CA21_1", "v_CA21_2"))) %>%  # Remove total population columns if present
  names()
```

```
## Error: object 'language_data' not found
```

``` r
# Calculate total language speakers for each CMA (should be first vector - total)
total_col <- language_vectors[1]

ldi_results <- language_data %>%
  select(GeoUID, name = `Region Name`, all_of(language_cols)) %>%
  rowwise() %>%
  mutate(
    # Calculate proportions for each language
    total_speakers = get(total_col),
    # Get proportions for all languages except the total
    language_proportions = list(
      c_across(all_of(language_cols[-1])) / total_speakers
    ),
    # Calculate LDI
    ldi = calculate_ldi(unlist(language_proportions))
  ) %>%
  ungroup() %>%
  select(GeoUID, name, total_speakers, ldi) %>%
  arrange(desc(ldi))
```

```
## Error: object 'language_data' not found
```

``` r
# Display results
cat("Language Diversity Index calculated for", nrow(ldi_results), "metropolitan areas\n")
```

```
## Error: object 'ldi_results' not found
```

## Results Visualization


``` r
# Create results table
top_diverse <- ldi_results %>%
  filter(!is.na(ldi)) %>%
  mutate(
    rank = row_number(),
    ldi_rounded = round(ldi, 4),
    total_speakers_formatted = scales::comma(total_speakers)
  ) %>%
  select(
    Rank = rank,
    `Metropolitan Area` = name,
    `Language Diversity Index` = ldi_rounded,
    `Total Speakers` = total_speakers_formatted
  )
```

```
## Error: object 'ldi_results' not found
```

``` r
# Display top 15 most diverse CMAs
kable(head(top_diverse, 15), 
      caption = "Top 15 Most Linguistically Diverse Canadian Metropolitan Areas (2021)")
```

```
## Error: object 'top_diverse' not found
```


``` r
# Create visualization
top_20 <- ldi_results %>%
  filter(!is.na(ldi)) %>%
  slice_head(n = 20)
```

```
## Error: object 'ldi_results' not found
```

``` r
ggplot(top_20, aes(x = reorder(name, ldi), y = ldi)) +
  geom_col(fill = "steelblue", alpha = 0.8) +
  coord_flip() +
  labs(
    title = "Language Diversity Index by Canadian Metropolitan Area",
    subtitle = "2021 Census Data - Top 20 Most Diverse CMAs",
    x = "Metropolitan Area",
    y = "Language Diversity Index",
    caption = "Data: Statistics Canada 2021 Census via cancensus package"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 12),
    axis.text.y = element_text(size = 10)
  )
```

```
## Error: object 'top_20' not found
```

## Summary Statistics


``` r
# Generate summary statistics
summary_stats <- ldi_results %>%
  filter(!is.na(ldi)) %>%
  summarise(
    n_cmas = n(),
    mean_ldi = mean(ldi),
    median_ldi = median(ldi),
    min_ldi = min(ldi),
    max_ldi = max(ldi),
    sd_ldi = sd(ldi)
  )
```

```
## Error: object 'ldi_results' not found
```

``` r
cat("Summary Statistics for Language Diversity Index (2021):\n")
```

```
## Summary Statistics for Language Diversity Index (2021):
```

``` r
cat("Number of CMAs analyzed:", summary_stats$n_cmas, "\n")
```

```
## Error: object 'summary_stats' not found
```

``` r
cat("Mean LDI:", round(summary_stats$mean_ldi, 4), "\n")
```

```
## Error: object 'summary_stats' not found
```

``` r
cat("Median LDI:", round(summary_stats$median_ldi, 4), "\n")
```

```
## Error: object 'summary_stats' not found
```

``` r
cat("Range:", round(summary_stats$min_ldi, 4), "to", round(summary_stats$max_ldi, 4), "\n")
```

```
## Error: object 'summary_stats' not found
```

``` r
cat("Standard Deviation:", round(summary_stats$sd_ldi, 4), "\n")
```

```
## Error: object 'summary_stats' not found
```

## Comparison with Major Cities


``` r
# Focus on Canada's largest metropolitan areas
major_cities <- c("Toronto", "Montréal", "Vancouver", "Calgary", "Edmonton", "Ottawa - Gatineau")

major_cities_ldi <- ldi_results %>%
  filter(grepl(paste(major_cities, collapse = "|"), name, ignore.case = TRUE)) %>%
  arrange(desc(ldi)) %>%
  mutate(rank_overall = match(name, top_diverse$`Metropolitan Area`))
```

```
## Error: object 'ldi_results' not found
```

``` r
kable(major_cities_ldi %>%
        select(`Metropolitan Area` = name, 
               `LDI` = ldi, 
               `Overall Rank` = rank_overall), 
      caption = "Language Diversity in Canada's Major Metropolitan Areas",
      digits = 4)
```

```
## Error: object 'major_cities_ldi' not found
```

## Conclusions


``` r
# Get the most diverse CMA
most_diverse <- ldi_results %>% 
  filter(!is.na(ldi)) %>% 
  slice_max(ldi, n = 1)
```

```
## Error: object 'ldi_results' not found
```

``` r
cat("Based on 2021 Census data:\n")
```

```
## Based on 2021 Census data:
```

``` r
cat("• Most linguistically diverse Canadian metropolitan area:", most_diverse$name, "\n")
```

```
## Error: object 'most_diverse' not found
```

``` r
cat("• LDI Score:", round(most_diverse$ldi, 4), "\n")
```

```
## Error: object 'most_diverse' not found
```

``` r
cat("• This represents a", round(most_diverse$ldi * 100, 1), "% probability that two randomly selected residents speak different mother tongues\n")
```

```
## Error: object 'most_diverse' not found
```

``` r
# Toronto ranking
toronto_rank <- which(grepl("Toronto", top_diverse$`Metropolitan Area`))
```

```
## Error: object 'top_diverse' not found
```

``` r
if(length(toronto_rank) > 0) {
  cat("• Toronto ranks #", toronto_rank, "in linguistic diversity\n")
}
```

```
## Error: object 'toronto_rank' not found
```

## Technical Notes

This analysis uses the 2021 Census data accessed through the `cancensus` R package. The Language Diversity Index calculation follows Greenberg's (1956) methodology. The analysis focuses on mother tongue data to measure linguistic diversity as a proxy for population diversity.

Key differences from the original 2017 analysis:
- Uses 2021 Census dataset (CA21) instead of 2016 (CA16)
- Updated vector identification methods for 2021 data structure
- Refined data processing to handle 2021 census data format


``` r
# Document session info for reproducibility
sessionInfo()
```

```
## R version 4.5.0 (2025-04-11)
## Platform: aarch64-apple-darwin20
## Running under: macOS Sequoia 15.4.1
## 
## Matrix products: default
## BLAS:   /Library/Frameworks/R.framework/Versions/4.5-arm64/Resources/lib/libRblas.0.dylib 
## LAPACK: /Library/Frameworks/R.framework/Versions/4.5-arm64/Resources/lib/libRlapack.dylib;  LAPACK version 3.12.1
## 
## locale:
## [1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8
## 
## time zone: America/Los_Angeles
## tzcode source: internal
## 
## attached base packages:
## [1] stats     graphics  grDevices utils     datasets  methods   base     
## 
## other attached packages:
## [1] DT_0.33         ggplot2_3.5.2   dplyr_1.1.4     cancensus_0.5.7
## [5] knitr_1.50     
## 
## loaded via a namespace (and not attached):
##  [1] bit_4.6.0          jsonlite_2.0.0     gtable_0.3.6       crayon_1.5.3      
##  [5] compiler_4.5.0     tidyselect_1.2.1   parallel_4.5.0     scales_1.4.0      
##  [9] fastmap_1.2.0      readr_2.1.5        R6_2.6.1           generics_0.1.4    
## [13] curl_6.3.0         htmlwidgets_1.6.4  tibble_3.2.1       pillar_1.10.2     
## [17] RColorBrewer_1.1-3 tzdb_0.5.0         rlang_1.1.6        xfun_0.52         
## [21] bit64_4.6.0-1      cli_3.6.5          withr_3.0.2        magrittr_2.0.3    
## [25] digest_0.6.37      grid_4.5.0         vroom_1.6.5        hms_1.1.3         
## [29] lifecycle_1.0.4    vctrs_0.6.5        evaluate_1.0.3     glue_1.8.0        
## [33] farver_2.1.2       codetools_0.2-20   httr_1.4.7         tools_4.5.0       
## [37] pkgconfig_2.0.3    htmltools_0.5.8.1
```
