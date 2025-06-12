# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a personal blog/static website built with **R blogdown** and **Hugo**, focused on spatial data analysis, Canadian census data, and data visualization. The site serves as a technical blog for data science content, particularly spatial analysis and urban planning insights.

## Architecture

- **Framework**: R blogdown + Hugo static site generator
- **Theme**: Kiss (minimal Hugo theme in `/themes/kiss/`)
- **Content**: R Markdown files (`.Rmd`) that generate HTML
- **Deployment**: Static site hosted at https://dshkol.com

### Key Directories

- `/content/` - Blog posts organized by year and in `/post/` for recent content
- `/static/` - Generated figures, images, and JavaScript widgets from R analysis
- `/themes/kiss/` - Complete Hugo theme with layouts, CSS, and JavaScript
- `/config.toml` - Hugo site configuration and theme settings

## Development Workflow

### Creating New Posts

1. Create new `.Rmd` file in `/content/post/` with YAML frontmatter:
   ```yaml
   ---
   title: "Post Title"
   author: "Dmitry Shkolnik"
   date: 'YYYY-MM-DD'
   summary: "Brief summary for social media cards"
   slug: "post-slug"
   twitterImg: post/filename_files/meta_card_pic.png
   image: post/filename_files/meta_card_pic.png
   categories: [blog, tutorial, spatial]
   tags: [cancensus, r, spatial, tutorial]
   ---
   ```

2. Write content mixing R code chunks with narrative text
3. Use `blogdown::serve_site()` to preview locally
4. R code chunks automatically generate figures saved to `/static/post/`

### Common R Packages Used

- `cancensus` - Canadian census data (co-created by site author)
- `cansim` - Statistics Canada data
- `sf` - Spatial data handling
- `spdep` - Spatial dependencies and analysis
- `ggplot2` - Data visualization
- `dplyr` - Data manipulation
- `htmlwidgets`, `mapdeck` - Interactive visualizations

### Build Process

The site uses R blogdown's integrated workflow:
- `.Rmd` files are knitted to `.html` by blogdown
- Hugo combines content with Kiss theme to generate static site
- Generated assets (plots, widgets) automatically placed in `/static/`
- No manual build scripts - everything handled by blogdown/Hugo

### Theme Customization

The Kiss theme is customized via:
- `/config.toml` - Site-wide settings, social links, analytics
- `/static/css/custom.css` - Custom CSS overrides
- Theme supports OpenGraph/Twitter cards, RSS, Disqus comments

### R Project Configuration

- RStudio project with `BuildType: Website` in `.Rproj`
- Uses 2-space indentation, UTF-8 encoding
- Workspace settings configured for blogdown development

## Content Focus

The blog specializes in:
- Spatial data analysis and mapping tutorials
- Canadian demographic analysis using census data
- Data visualization techniques in R
- Urban planning and geographic insights
- R package development (especially `cancensus`)

## Key Commands

Since this is an R blogdown project, development happens primarily in R/RStudio:

```r
# Start local development server
blogdown::serve_site()

# Create new post
blogdown::new_post("Title", ext = ".Rmd")

# Build site
blogdown::build_site()

# Stop server
blogdown::stop_server()
```

The project relies on R's blogdown ecosystem rather than traditional web development build tools.

## cancensus Package Deep Understanding

The `cancensus` package is central to this blog's content and provides comprehensive access to Canadian Census data. Understanding its architecture is crucial for working with the spatial analysis content.

### Core Functionality & Architecture

**Main Purpose**: Provides R access to Canadian Census data via the CensusMapper API, enabling retrieval, analysis, and visualization of demographic and geographic data.

**Key Functions**:
- `get_census()` - Primary data retrieval function supporting multiple formats (tabular, sf spatial, sp spatial)
- `list_census_vectors()` - Discover available census variables with hierarchical metadata
- `find_census_vectors()` - Search census variables using exact, semantic, or keyword search
- `list_census_regions()` - Query available geographic regions
- `get_intersecting_geometries()` - Find census regions intersecting custom geometries

### Data Structures & API Integration

**API Architecture**:
- Requires CensusMapper API key for authentication (`set_cancensus_api_key()`)
- Supports Canadian Census datasets from 1996-2021 (dataset codes like "CA21", "CA16")
- Uses HTTP POST requests with JSON payloads
- Implements caching system (`set_cancensus_cache_path()`) to minimize API calls
- Returns data as CSV or GeoJSON depending on spatial requirements

**Geographic Hierarchies**: National → Provincial (PR) → Census Metropolitan Area (CMA) → Census Division (CD) → Census Subdivision (CSD) → Census Tract (CT) → Dissemination Area (DA) → Enumeration Area (EA) → Dissemination Block (DB)

**Variable Hierarchies**: Parent-child relationships with metadata including units, labels, types, and hierarchical relationships

### Typical Usage Pattern

```r
# Authentication and setup
set_cancensus_api_key("your_key")
set_cancensus_cache_path("/path/to/cache")

# Data discovery
vectors <- find_census_vectors("income", dataset = "CA21")
regions <- list_census_regions(dataset = "CA21", level = "CMA")

# Data retrieval with spatial geometry
census_data <- get_census(
  dataset = "CA21",
  regions = list(CMA = c("59933")), # Toronto CMA
  vectors = c("v_CA21_434", "v_CA21_435"),
  level = "CT", # Census Tract level
  geo_format = "sf"
)
```

### Integration with Spatial Workflows

- Native support for `sf` (simple features) and `sp` spatial formats
- Seamless integration with ggplot2, leaflet, mapdeck for visualization
- Supports both cartographic (simplified) and digital (high-resolution) boundaries
- Built for tidyverse workflows with pipe-friendly functions

### Performance & Advanced Features

- Local caching system with configurable paths
- Data recall and correction mechanisms for updated Statistics Canada data
- Quota management and API usage tracking
- StatCan direct data access functions bypassing CensusMapper API
- Interactive exploration tools (`explore_census_vectors()`, `explore_census_regions()`)

**Package Dependencies**: 
- Core: dplyr, httr, jsonlite, rlang, digest
- Spatial: sf, sp (suggested)
- Visualization: ggplot2, leaflet, mapdeck (suggested)

**Maintainership**: Co-created by Jens von Bergmann (CensusMapper API) and Dmitry Shkolnik (R package maintainer), ensuring tight integration between API and R interface.

## Key Development Workflows and Testing Patterns

### R Markdown Development Workflow
When replicating or creating new analyses, follow this iterative approach:

1. **Start with isolated testing**: Create standalone `.R` scripts to test key components before integrating into R Markdown
2. **Use defensive programming**: Always check for variable existence and data availability before proceeding
3. **Implement progressive enhancement**: Build basic analysis first, then add advanced visualizations
4. **Test rendering incrementally**: Use `knitr::knit()` to convert to markdown when pandoc unavailable

### Advanced Visualization Replication Standards
The blog posts demonstrate sophisticated visualization techniques that should be maintained:

**Essential Visualization Packages**:
- `ggalt` - For signature lollipop charts with `geom_lollipop()`
- `ggrepel` - For sophisticated label placement with `geom_label_repel()`
- `viridis` - For colorblind-friendly palettes, especially "magma" option for spatial data
- `sf` - For spatial mapping with `geom_sf()`

**Signature Plot Aesthetics**:
```r
# Lollipop chart styling
geom_lollipop(point.colour = "darkred", point.size = 4, horizontal = TRUE)

# Professional theming pattern
theme_minimal() + 
theme(panel.grid.major.y = element_blank()) + 
theme(axis.line.y = element_line(color = "#2b2b2b", size = 0.15)) + 
theme(plot.title = element_text(face = "bold", hjust = 0.5)) + 
theme(plot.subtitle = element_text(hjust = 0.5))

# Spatial mapping with viridis
scale_fill_viridis_c("Language Diversity Index", option = "magma")
```

### Census Data Version Translation Patterns
When updating analyses from older census years:

**Vector Discovery Process**:
1. Use `find_census_vectors()` with broad search terms first
2. Filter using `child_census_vectors()` to get hierarchical relationships
3. Filter out aggregates: `!grepl("Multiple responses|Single responses|Official|Non-official", label)`
4. Limit to manageable subsets for performance: `slice_head(n = 50)`

**Common Vector Patterns**:
- 2016: `v_CA16_1355` (language total) → 2021: `v_CA21_2200`
- Always verify vector labels match expected concepts
- Use `type == "total"` to avoid male/female breakdowns

### Error Handling and Debugging Patterns
Key issues encountered and solutions:

**API Parameter Validation**:
- Remove `level` parameter from `list_census_regions()` - filter afterward
- Avoid `geo_format = "sf"` in test calls unless spatial data needed
- Use `quiet = TRUE` to reduce API message noise

**Data Processing Robustness**:
```r
# Always check data existence before processing
if(exists("language_vectors") && length(language_vectors) > 0) {
  # Proceed with analysis
} else {
  stop("Required data not available")
}

# Handle edge cases in calculations
proportions <- proportions[!is.na(proportions) & proportions > 0]
if(length(proportions) == 0) return(NA)
```

### Performance Optimization for Large Datasets
**Spatial Data Handling**:
- Use `st_drop_geometry()` before heavy computations: `st_geometry(data) <- NULL`
- Process spatial joins efficiently: `st_join(data, left = FALSE)`
- Cache API results and use batch retrieval for multiple regions

**Memory Management**:
- Limit vector sets to essential categories (50-100 vectors max)
- Use strategic filtering to reduce data size early in pipeline
- Process large CMAs separately if needed to avoid timeouts

### Documentation and Reproducibility Standards
**Caption and Attribution Consistency**:
Always include proper attribution matching blog style:
```r
caption = "Dmitry Shkolnik @dshkol\nCensus 2021 data from Statistics Canada retrieved through cancensus R package\nLinguistic diversity calculated using the method introduced in Greenberg (1956)"
```

**Methodological Documentation**:
- Document vector translations between census years
- Explain any methodological adaptations needed for new data
- Maintain mathematical consistency (e.g., Greenberg's LDI formula)

### Package Installation Strategy
Use conditional installation for enhanced packages:
```r
if(!require(ggalt)) install.packages("ggalt")
if(!require(ggrepel)) install.packages("ggrepel")
if(!require(viridis)) install.packages("viridis")
```

These patterns ensure analyses maintain the high standard of technical sophistication and visual quality characteristic of the blog's spatial analysis content.