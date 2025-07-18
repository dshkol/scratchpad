# The Dead-Language Archipelago: Mapping the Last Speakers of Extinct Tongues
# An analysis of where speakers of nearly-extinct or ancient languages cluster in America

# Load required libraries
library(tidyverse)
library(tidycensus)
library(sf)
library(viridis)
library(scales)
library(gt)
library(tigris)
library(spdep)  # For spatial statistics

# Set up tidycensus
Sys.setenv(CENSUS_API_KEY = 'e26f52be2ec1508bd2eddb89a6a2c20917316ea8')
census_api_key(Sys.getenv("CENSUS_API_KEY"))

# Configure tigris for better performance
options(tigris_use_cache = TRUE)

# Define fossil language variables based on our exploration
fossil_vars <- c(
  yiddish = "B16001_021",  # Yiddish, Pennsylvania Dutch or other West Germanic
  hebrew = "B16001_108",   # Hebrew  
  greek = "B16001_024",    # Greek
  other_indoeur = "B16001_063",  # Other Indo-European languages (may include Latin, Sanskrit)
  navajo = "B16001_120",   # Navajo
  other_native = "B16001_123",  # Other Native languages of North America
  other_unspec = "B16001_126"   # Other and unspecified languages
)

# Also get total population for calculating location quotients
total_pop_var <- "B16001_001"  # Total population 5 years and over

# Step 1: Get national-level data to identify truly rare languages
cat("Getting national-level language data...\n")
national_langs <- get_acs(
  geography = "us",
  variables = fossil_vars,
  year = 2022,
  survey = "acs5"
) %>%
  mutate(
    language = case_when(
      variable == "B16001_021" ~ "Yiddish/Pennsylvania Dutch",
      variable == "B16001_108" ~ "Hebrew",
      variable == "B16001_024" ~ "Greek", 
      variable == "B16001_063" ~ "Other Indo-European",
      variable == "B16001_120" ~ "Navajo",
      variable == "B16001_123" ~ "Other Native North American",
      variable == "B16001_126" ~ "Other/Unspecified",
      TRUE ~ variable
    )
  ) %>%
  arrange(estimate)

cat("\nNational speakers of fossil languages:\n")
national_langs %>%
  select(language, estimate, moe) %>%
  print()

# Step 2: Get tract-level data for the entire US
# Given the rarity, we'll look nationally but focus on tracts with any speakers
cat("\nGetting tract-level data for fossil languages (this may take a while)...\n")

# First test with a few states known for diversity
test_states <- c("MA", "NY", "CA", "NM", "AZ")

fossil_tracts <- map_df(test_states, function(st) {
  cat("Processing", st, "...\n")
  
  tracts <- get_acs(
    geography = "tract",
    state = st,
    variables = c(fossil_vars, total = total_pop_var),
    year = 2022,
    survey = "acs5",
    geometry = TRUE
  )
  
  return(tracts)
})

# Pivot to wide format manually - need to handle geometry carefully
# First get unique tract info with geometry
tract_geoms <- fossil_tracts %>%
  select(GEOID, NAME, geometry) %>%
  distinct()

# Now pivot the data without geometry
fossil_data_wide <- fossil_tracts %>%
  st_drop_geometry() %>%
  select(GEOID, variable, estimate) %>%
  pivot_wider(names_from = variable, values_from = estimate, values_fill = 0) %>%
  rename(
    total_pop = total
  )

# Join back together
fossil_tracts <- tract_geoms %>%
  left_join(fossil_data_wide, by = "GEOID")

# Step 3: Calculate location quotients for each language
# LQ = (local share / national share)
# First get total US population 5+ years
total_us_pop <- 313455330  # Approximate from 2022 ACS

national_shares <- national_langs %>%
  mutate(
    national_share = estimate / total_us_pop,
    variable_clean = case_when(
      variable == "yiddish" ~ "yiddish_share",
      variable == "hebrew" ~ "hebrew_share",
      variable == "greek" ~ "greek_share",
      variable == "other_indoeur" ~ "other_indoeur_share",
      variable == "navajo" ~ "navajo_share",
      variable == "other_native" ~ "other_native_share",
      variable == "other_unspec" ~ "other_unspec_share"
    )
  ) %>%
  select(variable, national_share)

# Print national shares for reference
cat("\nNational shares of fossil languages:\n")
print(national_shares)

# Get national shares as a named vector for easier use
ns_vec <- setNames(national_shares$national_share, national_shares$variable)

# Calculate tract-level metrics
fossil_metrics <- fossil_tracts %>%
  mutate(
    # Calculate shares
    yiddish_share = yiddish / total_pop,
    hebrew_share = hebrew / total_pop,
    greek_share = greek / total_pop,
    other_indoeur_share = other_indoeur / total_pop,
    navajo_share = navajo / total_pop,
    other_native_share = other_native / total_pop,
    
    # Calculate location quotients using actual national shares
    yiddish_lq = ifelse(total_pop > 0, yiddish_share / ns_vec["yiddish"], 0),
    hebrew_lq = ifelse(total_pop > 0, hebrew_share / ns_vec["hebrew"], 0),
    greek_lq = ifelse(total_pop > 0, greek_share / ns_vec["greek"], 0),
    other_indoeur_lq = ifelse(total_pop > 0, other_indoeur_share / ns_vec["other_indoeur"], 0),
    navajo_lq = ifelse(total_pop > 0, navajo_share / ns_vec["navajo"], 0),
    other_native_lq = ifelse(total_pop > 0, other_native_share / ns_vec["other_native"], 0),
    
    # Flag high concentration tracts (LQ > 10)
    has_concentration = (yiddish_lq > 10 | hebrew_lq > 10 | 
                        greek_lq > 10 | other_indoeur_lq > 10 |
                        navajo_lq > 10 | other_native_lq > 10),
    
    # Identify dominant fossil language
    dominant_fossil = case_when(
      navajo_lq > 10 & navajo_lq > pmax(yiddish_lq, hebrew_lq, greek_lq, other_indoeur_lq, other_native_lq) ~ "Navajo",
      other_native_lq > 10 & other_native_lq > pmax(yiddish_lq, hebrew_lq, greek_lq, other_indoeur_lq, navajo_lq) ~ "Other Native",
      yiddish_lq > 10 & yiddish_lq > pmax(hebrew_lq, greek_lq, other_indoeur_lq) ~ "Yiddish",
      hebrew_lq > 10 & hebrew_lq > pmax(yiddish_lq, greek_lq, other_indoeur_lq) ~ "Hebrew",
      greek_lq > 10 & greek_lq > pmax(yiddish_lq, hebrew_lq, other_indoeur_lq) ~ "Greek",
      other_indoeur_lq > 10 ~ "Other Indo-European",
      TRUE ~ "None"
    )
  ) %>%
  filter(total_pop > 100)  # Remove very small tracts

# Step 4: Identify hot spots
cat("\nIdentifying fossil language hot spots...\n")

# Find tracts with any significant fossil language presence
hotspots <- fossil_metrics %>%
  filter(has_concentration) %>%
  arrange(desc(pmax(yiddish_lq, hebrew_lq, greek_lq, other_indoeur_lq, navajo_lq, other_native_lq, na.rm = TRUE)))

cat("Number of fossil language hot spots found:", nrow(hotspots), "\n")

if(nrow(hotspots) > 0) {
  cat("\nTop 10 fossil language concentrations:\n")
  hotspots %>%
    st_drop_geometry() %>%
    select(NAME, dominant_fossil, yiddish_lq, hebrew_lq, greek_lq, other_indoeur_lq, navajo_lq, other_native_lq) %>%
    slice(1:10) %>%
    print()
}

# Step 5: Create visualizations
# Map of fossil language archipelago
if(nrow(hotspots) > 0) {
  # Create base map with all tracts
  base_map <- ggplot() +
    geom_sf(data = fossil_metrics, fill = "grey95", color = "grey80", size = 0.1) +
    geom_sf(data = hotspots, aes(fill = dominant_fossil), color = "black", size = 0.2) +
    scale_fill_manual(
      values = c(
        "Navajo" = "#D55E00",
        "Other Native" = "#CC79A7",
        "Yiddish" = "#E69F00",
        "Hebrew" = "#56B4E9", 
        "Greek" = "#009E73",
        "Other Indo-European" = "#F0E442",
        "None" = "grey50"
      ),
      name = "Dominant\nFossil Language"
    ) +
    theme_minimal() +
    theme(
      legend.position = "bottom",
      plot.title = element_text(size = 16, face = "bold"),
      plot.subtitle = element_text(size = 12)
    ) +
    labs(
      title = "The Dead-Language Archipelago",
      subtitle = "Census tracts with high concentrations of ancient and nearly-extinct language speakers"
    )
  
  print(base_map)
  
  # Save the map
  ggsave("fossil_language_archipelago_map.png", base_map, width = 12, height = 8, dpi = 300)
}

# Step 6: Correlation with universities
# Load university data (would need external source)
# For now, let's check correlation with education levels as proxy

edu_vars <- c(
  bachelors = "B15003_022",  # Bachelor's degree
  masters = "B15003_023",    # Master's degree  
  professional = "B15003_024", # Professional degree
  doctorate = "B15003_025"   # Doctorate degree
)

# Get education data for hotspot tracts
if(nrow(hotspots) > 0) {
  hotspot_geoids <- hotspots$GEOID
  
  # Extract state from GEOID for education data query
  hotspot_states <- unique(substr(hotspot_geoids, 1, 2))
  
  edu_data <- map_df(hotspot_states, function(st) {
    get_acs(
      geography = "tract",
      state = st,
      variables = edu_vars,
      year = 2022,
      survey = "acs5",
      output = "wide"
    ) %>%
      filter(GEOID %in% hotspot_geoids)
  })
  
  # Join with hotspots
  hotspots_edu <- hotspots %>%
    left_join(edu_data %>% select(GEOID, starts_with("B15003")), by = "GEOID") %>%
    mutate(
      advanced_degree_pct = (B15003_023E + B15003_024E + B15003_025E) / total_pop * 100
    )
  
  # Check correlation
  cat("\nCorrelation between fossil languages and education:\n")
  
  # Create scatter plot
  edu_plot <- hotspots_edu %>%
    st_drop_geometry() %>%
    pivot_longer(cols = c(yiddish_lq, hebrew_lq, greek_lq, other_indoeur_lq),
                 names_to = "language_type", values_to = "location_quotient") %>%
    filter(location_quotient > 0) %>%
    ggplot(aes(x = advanced_degree_pct, y = location_quotient)) +
    geom_point(alpha = 0.6, size = 2) +
    geom_smooth(method = "lm", se = FALSE, color = "red") +
    facet_wrap(~language_type, scales = "free_y") +
    theme_minimal() +
    labs(
      x = "% with Advanced Degrees",
      y = "Location Quotient",
      title = "Fossil Languages and Educational Attainment",
      subtitle = "Are ancient language speakers concentrated near universities?"
    )
  
  print(edu_plot)
  
  # Save the education plot
  ggsave("fossil_language_education_correlation.png", edu_plot, width = 10, height = 8, dpi = 300)
}

# Step 7: Summary statistics
cat("\n=== SUMMARY ===\n")
cat("Total census tracts analyzed:", nrow(fossil_metrics), "\n")
cat("Tracts with fossil language concentrations:", nrow(hotspots), "\n")

if(nrow(hotspots) > 0) {
  cat("\nBreakdown by language:\n")
  hotspots %>%
    st_drop_geometry() %>%
    count(dominant_fossil) %>%
    print()
}

# Save results
write_csv(
  hotspots %>% st_drop_geometry(),
  "fossil_language_hotspots.csv"
)

cat("\nAnalysis complete. Results saved to fossil_language_hotspots.csv\n")