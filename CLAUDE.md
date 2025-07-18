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

- `/content/` - Blog posts organized by year (2017, 2018) and in `/post/` for recent content
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

### Build Process

The site uses R blogdown's integrated workflow:
- `.Rmd` files are knitted to `.html` by blogdown
- Hugo combines content with Kiss theme to generate static site
- Generated assets (plots, widgets) automatically placed in `/static/`
- No manual build scripts - everything handled by blogdown/Hugo

### R Project Configuration

- RStudio project with `BuildType: Website` in `.Rproj`
- Uses 2-space indentation, UTF-8 encoding
- Workspace settings configured for blogdown development
- No package management framework (renv/packrat) - relies on user's R installation

## Content Focus

The blog specializes in:
- Spatial data analysis and mapping tutorials
- Canadian demographic analysis using census data
- Data visualization techniques in R
- Urban planning and geographic insights
- R package development (especially `cancensus`)

## Key Analysis Patterns

### Signature Visualization Style

The blog posts demonstrate sophisticated visualization techniques:

- **Lollipop charts** using `ggalt::geom_lollipop()`
- **Professional theming** with `theme_minimal()` and custom modifications
- **Spatial mapping** with `sf::geom_sf()`
- **Color schemes** using `viridis` palettes, especially "magma" for spatial data
- **Label management** with `ggrepel::geom_label_repel()`

### Census Data Analysis

- Heavy use of `cancensus` package for Canadian Census data
- Focus on linguistic diversity, demographic patterns, and spatial clustering
- Analysis typically at Census Tract (CT) or Census Metropolitan Area (CMA) levels
- Integration of spatial analysis with demographic insights

### R Markdown Best Practices

- Mix of narrative text with R code chunks
- Figures automatically saved to `/static/post/filename_files/figure-html/`
- Use of caching for performance (`cache=TRUE`)
- Professional attribution in plots and captions

The project relies on R's blogdown ecosystem rather than traditional web development build tools.