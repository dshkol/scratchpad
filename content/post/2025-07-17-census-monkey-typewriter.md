---
title: "A million monkeys doing data blogging - agentic social science with Claude Code and friends"
author: "Dmitry Shkolnik"
date: '2025-07-21'
summary: "An experiment in using LLMs to automate social science writing. Here's what I learned about LLM-assisted social science blogging."
slug: census-monkey-typewriter
categories:
  - blog
  - experimental
  - ai
tags:
  - census
  - demographics
  - llm
  - ai
---

_“Let us imagine a million monkeys typing ten hours a day at random. There is almost no doubt that one of them would write exactly the complete works of Bossuet; if not, at least a good psalm, and if not, at least a few lines.”_ - Émile Borel — Mécanique Statistique et Irréversibilité (1913)

[Census Monkey Typewriter](https://github.com/dshkol/census-monkey-typewriter) is an experiment to see how easy it would be to set up some kind of semi-automated and semi-supervised social science research and writing in the style of blog posts and circa 2019-era 'data journalism'. The goal was to create a process for an agent or a series of agents to run an analysis workflow end-to-end, from hypothesis creation to analysis plan to execution with narrative building, critique, and effective visual communication. Admittedly, the project was also intended as a parody of data blogging with the non-sense hypothesis dial turned up but after a few weeks of iteration the results have been pretty interesting, and I've learned a lot about how to approach this kind of problem going forward, and there's a few ideas I want to keep exploring in the near future. 

## System overview at a high-level

The overall setup is pretty simple. Everything more or less functions through agentic CLI systems -- primarily Claude Code with some Gemini CLI sprinkled on the side -- and a host of instructional markdown contents to use for context and prompting. The system uses a mix of Opus 4, Sonnet 4, and Gemini Pro 2.5 depending on instructions and availability. I use the Claude Max plan and the free tier of Gemini CLI. 

There is a stateful workflow that maintains context across sessions through version-controlled instruction files. Context is refined through a combination of agent-derived meta learnings ('reflect on what worked well and what did not') and feedback from the user (me). Additional context is built up over time through failure and success, with more details, refinements, and learnings about edge-cases. You can make the case that this is a lofi RLHF system where the agent reads accumulated learnings before each task.

The workflow has two main phases:

### Hypothesis generation

The agent proposes research questions based on available US census data and several preseeded domains that tend to use that kind of data and pose questions interesting to me (e.g. demographics x information theory). The overall prompt was constructed by first giving o3 a description of the task and asking it to generate a Deep Research prompt to survey recent developments in social/geographic science relying on US census data. The results of that wall of text are sent back to o3 to generate a concise prompt describing a role and requirements for the `hypothesis-generator-agent`. In the latest version, the role preamble looks like this:

```text

### Role

You are **CENSUS‑HYPOTHESIS‑GENERATOR v2.0**, a large‑language‑model agent curated by the Principal Data Scientist.
Your remit spans urban geography, demographic change, migration, linguistics, socio‑economics, information theory, and allied fields.
You propose **novel, testable research hypotheses grounded *exclusively* in U.S. Census Bureau datasets that are freely accessible via the Bureau’s API and alignable with TIGER/ Tigris geographies**.
The work is exploratory, partly whimsical, and aimed at curious lay readers and technically minded peers alike.

The **only data products you may draw on are:**

* **Decennial Census** (100 % and sample/PL tables, 2010 & 2020)
* **American Community Survey** (1‑year & 5‑year, any table)
* **Population Estimates Program (PEP)** – annual county/metro/state totals & components
* **ACS Migration Flows** – county‑to‑county and metro flows

*No other external or auxiliary datasets are permitted.*
```

And so on. The entire generator prompt is about 200 lines of about 2600 tokens. It produces structured hypotheses like these:

```

## Linguistic Entropy as Predictor of Economic Dynamism *(BUCKET: Exploratory)*

**Abstract (≤ 60 words)**  
Counties with higher linguistic diversity (measured through languages spoken at home) may exhibit greater economic resilience and innovation. Using Shannon entropy of language distributions, we test whether linguistic heterogeneity correlates with business formation rates, income growth, and occupation diversity, controlling for immigrant share and education levels.

**Structured specification**

{
  "novelty_rating":       "medium",
  "feasibility_rating":   "high",
  "complexity_rating":    "medium",
  "complexity_source":    "computational",
  "whimsy_rating":        "low",
  "geographic_level":     "county",
  "primary_metrics":      ["language Shannon entropy", "income growth rate", "occupation diversity"],
  "metric_portfolio":     ["linguistic diversity index", "median income change", "business patterns proxy"],
  "proposed_method":      "instrumental variables regression",
  "methodological_innovation": "refugee resettlement as IV for language diversity",
  "temporal_design":      "panel",
  "temporal_boundaries":  ["2010 Census", "2020 Census"],
  "natural_experiment_potential": "refugee resettlement programs",
  "robustness_checks":    ["immigrant share controls", "education controls", "alternative entropy measures"],
  "expected_runtime":     "<1 hr",
  "ethical_flags":        []
}

**Narrative plan**

1. **Data sources** – ACS 5-year Tables B16001 (language spoken at home), B19013 (median income), B24010 (occupations), B05002 (nativity)
2. **Methodology** – Calculate Shannon entropy from detailed language categories. Instrument with historical refugee resettlement patterns to address endogeneity. Test relationship with economic outcomes.
3. **Why it matters / what could go wrong** – Links cultural diversity to economic outcomes. Challenge: selection bias. Solution: instrumental variables approach.

**Key references**
• Ottaviano, G. & Peri, G. (2006) *The economic value of cultural diversity*. DOI: 10.1016/j.jue.2005.06.004
• Page, S. (2007) *The Difference: How the Power of Diversity Creates Better Groups*
```

The generator prompt instructs the agent to pick one of three analysis buckets: serious, exploratory, and whimsical. Serious is trying to find and evaluate a hypothesis that might have some real-world utility, whether in policy, or as the basis for some academic research. Exploratory downweights the applications while trying to adopt novel or complex cross-domain methods in theory, but in practice seems to gravitate to entropy measurement. Whimsical is meant to be some combination of trivial nonsense and Ignoble research -- these tend to turn out best. In the spirit of my old blog posts, the hypotheses generator agent has an intentional bias towards spatial data and spatial analyses.

Agents are instructed to use the heaviest reasoning model they have access to when generating hypotheses. Mostly this is Opus 4 with instructions to `think very hard` or `ultrathink` depending on how much of these tokens I have available in that session (per Anthropic documentation, these are intentional cues). All the agents have access to Gemini CLI via an MCP hook, but it's mostly Opus 4. Hypothesis creation is done in batches (create 5/10/15 etc via a custom CC hook). 

### Analysis execution

After a batch of hypotheses is created, we can switch to analysis execution mode. This is where the agentic approach via Claude Code really shines in my opinion. The agent starts by selecting several of the new hypotheses and designing an analysis plan based on prior instructions. The agent is instructed to reference several different prompt context files:

* claude.md - this is the central constitution of the agent with details about role, workflow and directory structure, model selection, instructions how to interact with other prompting docs, and custom CC commands. (~100 lines, 1500 tokens)
* claude-visuals.md - this is a set of high level instructions about how to use visuals in the narrative flow, global aesthetic standards (plot types, palettes, etc). (~75 lines, 1100 tokens)
* workflow-learnings.md - after every session, Claude is instructed to reflect and document on what worked and what didn't and document specific technical and non-technical feedback. Code issues, edge-cases, Census variable details, inference patterns, and a host of other refinements based on a combination of unit-testing, self-reflection, and human feedback. (1500 lines, 15000 tokens)

Everything is executed via R + RMarkdown. There's a few reasons for this, not the least of which was nostalgia for an old workflow. My old blog posts (and this site) relied on a combination of Rmd notebooks published to a Hugo static website via the `blogdown` package. This follows the same approach. More practically, I already knew there were excellent tools for working with US census data in R via the great `tidycensus` package, which has great documentation and lots of examples for an LLM to reference. Narrative style and tone was calibrated using a combination of direct feedback ('don't sound like an AI; stop being so breathless and eager') and asking an agent to deconstruct and adopt the general style and tone of several inputs (my old blog posts, archived articles from fivethirtyeight and thepudding, etc). This isn't necessarily used as training data so much as refinement data.

Claude is instructed to build everything first in R files before committing to Rmd files. I found that the agent struggles with unit testing inside a markdown file and would otherwise produce a ton of `cat()` junk. By building everything in R first, the agent can repeatedly test every line of code to check that it works and while also adding sanity checks for data quality. After working through issues, the agent will move the code in chunks to an Rmd file and assemble the narrative content. The agent is encouraged to make use of in-line data rendering to insert values directly into the narrative flow. Code chunks are expected to be hidden to conform to a 'data journalism' style.

Mistakes are made; sometimes really stupid ones. In early iterations the agent tended to default to a combination of defensive programming and eagerness to please by constantly reverting to fake or simulated data when hitting issues like missing data or methodological issues. I assume this is how Anthropic finetuned these models, which makes sense when you're writing software but is a critical error when doing data analysis. It took a fair bit of explicit instructions against this to get the agent to focus on understanding available variables and what their structure was when hitting data roadblocks, and to think more critically about methods. Another frequent early issue was the agent uncritically accepting non-sense results -- absurd figures like TFR rates for states exceeding 6. This was partially mitigated by requiring the agent to just do a sense check on numbers ('does this look remotely realistic based on what you generally know?'). This approach works reasonably well, which is unsurprising if you've ever asked a large general purpose model like Sonnet a generic question without enabling web lookups or tool use -- they tend to do quite well! 

The analysis plan encourages the agent to switch into the role of a critical peer-reviewer after drafting a narrative, and then incorporate that feedback back into a revised narrative. This has been hit and miss and I need to find a better way of making this an actual adversarial process, but I see the potential here. If I spend more time on this project I would probably focus my energy here. 

At the end of each working session or when context compression is imminent, the agent is instructed to reflect on what worked and what didn't and document those meta-learnings into the growing `workflow-learnings.md` doc. This doc is quite long and is probably a really inefficient use of tokens but the result of continuous refinement has been impressive. After a number of iterations, the system developed consistent patterns: specific visualization aesthetics, preferred statistical approaches, even recurring narrative structures. 

## Example workflow

Let's demonstrate an example. I already had some hypotheses prepared from a recent run, so I asked Claude to work through the linguistic entropy hypotheses I shared above. 

[Here's an example session log for the initial run](https://gist.github.com/dshkol/09d4db4ed28c73026103246bdaf52656). At the bottom it noted a 7 hour run time, but in practice this was more like 5-10 minutes. The log has good examples of the way the agent independently resolved data issues (NA values, incorrect labels, etc) towards a conclusion. There's some issues here but it's not a bad start. The central argument that linguistically diverse counties will be more prosperous is clearly subject to identification challenges -- immigrants are more likely to settle in prosperous regions and the agent admits and acknowledges that inferring causation is difficult, despite some attempt to mitigate by using additional specifications that include immigrant share as a control. The limitations section is more clear about the causality challenges in this research design. I'm also surprised it didn't generate a map given that at least part of the argument is about geographic patterns of these prosperous/linguisticly diverse regions -- by now, the agent should have been trained to add a map when making a spatial argument. 

I provide some feedback: 

```text
> This is quite good. Some feedback: as you noted, it's difficult to establish causation here and the idea that immigrants would concentrate in prosperous areas is logical. You should consider how you would address this critique using Census data alone - e.g. what kind of identification approach you would take or maybe cite some prior art here. Second, you are discussing geographic patterns in data, so you should consider making a map. Given that you are showing the relationship between two variables -- two dimensions -- you could consider a bivariate choropleth. There's a package in R called biscale that could help, as well as helpful examples online for bivariate choropleth in ggplot2.
```

Up to now it's unlikely to have encountered code for a bivariate choropleth in ggplot2 but I expect this will be sufficient context for it to learn and add to its toolkit going forward. 

`* gesticulating`

...

`* germinating` 

Still a few issues. I provide more feedback:

```text
> Feedback on your second shot here: why is the 'geographic patterns revealed' section buried in the causation section? Shouldn't it come right after the table in the section 'geographic patterns of 
  language...'? As you iterate make sure not to just tack things on but slot them in where appropriate. Second: in that table 'america's most linguistically diverse counties', there's a column 'region' and all the values are 'Other' -- why? That seems wrong. Check it. Third: in the bivariate choropleth, many counties appear to be missing and not rendered. Spatially they look likely to be less linguistically diverse - is there a division by zero issue in the entropy calculation? Can you think of a better way of representing these counties instead of dropping them?
```

But first I'm about to run out of context in Claude Code so I need to compress (summarize and clear context). This tends to reduce the capability of the agent immediately after as it tries to gather context back together. It also looks like I'm about to run out of Opus 4 tokens and will switch to Sonnet 4 -- that won't help, so I make sure to give very clear directions. Fortunately at this point we're going to be less focused on methods and more on coding. 

After a bit more back and forth ironing out the issues with the bivariate map, we end up in a pretty good place. We've developed a workaround for very small and zero entropy counties that allows them to be visualized still. 

Satisfied, I ask for self-reflection and takeaways to update `workflow-learnings.md`. 

```text
> What did you learn today? Think hard, self reflect and document session meta learnings. Update workflow-learnings.md with relevant learnings for the next session.

✻ Thinking…

  The user is asking me to reflect on what I learned today and document session meta-learnings. Let me think through the key lessons from this session:

  1. Data Issues and Debugging:
    - I encountered three significant issues with the linguistic entropy analysis that required systematic debugging
    - State extraction failed because I didn't account for two-word state names like "New Hampshire" 
    - The region classification table showed all "Other" because the state column was all NAs
    - The bivariate map had missing counties because 326 small counties (<5,000 pop) were excluded from the original analysis but not properly handled in visualization
  2. User Feedback Integration:
    - The user provided very specific, actionable feedback on three distinct issues
    - They emphasized the importance of not just "tacking things on" but properly organizing content
    - They challenged me to think about why counties were missing from the map and find a better solution
  3. Systematic Problem Solving:
    - I had to create multiple diagnostic scripts to understand the root causes
    - Each issue required a different approach: regex fixing for states, data pipeline correction for regions, complete data coverage for mapping
    - The map issue was particularly complex because it involved understanding the difference between analysis coverage (2,904 counties) vs. complete US coverage (3,222 counties)
  4. Quality Standards Application:
    - This was a good test of whether the automated quality checks I established actually prevent issues
    - Some issues (like section organization) were caught, but data quality issues slipped through
    - I need better data validation standards
  5. Iterative Enhancement Process:
    - The user's feedback led to systematic improvements rather than surface-level fixes
    - Each fix revealed deeper understanding of the data and analysis
    - The final result was substantially better than the initial version
  6. Technical Learnings:
    - State name extraction from Census data requires careful regex handling
    - Bivariate maps need complete coverage planning from the start
    - Small county handling is a common issue in county-level Census analysis

  I noticed that the tigris package provides more comprehensive county data compared to typical American Community Survey (ACS) datasets, which impacts data coverage and mapping approaches.
```

That's a substantial amount of learning from relatively few feedback prompts on my end (2 substantive and a few minor ones). These general learnings were encapsulated in much more prescriptive detail for use in the following sessions and documented in the expanding `workflow-learnings.md` context.

```text
  ⎿  Updated WORKFLOW-LEARNINGS.md with 102 additions                                                                                                                                                         
       1363    
       1364    **This process revision must be consulted at the start of every analysis session to prevent repeating the systematic failures documented above.**
       1365    
       1366 +  ### 2025-07-21: Data Quality Control & User Feedback Integration Session
       1367 +  **Scope**: Linguistic entropy analysis enhancement, systematic debugging of data quality issues, user-driven iterative improvement  
       1368 +  **Duration**: Extended session focused on addressing three specific user feedback points  
       1369 +  **Outcome**: Successfully resolved state extraction, region classification, and map coverage issues through systematic debugging
       1370 +  
       1371 +  #### User Feedback Integration Excellence
       1372 +  **Specific, Actionable Feedback Processing**
       1373 +  - User provided three precise issues: section organization, region table showing "Other", missing counties in map
       1374 +  - Each issue required different diagnostic approach: content reorganization, data pipeline correction, visualization completeness
       1375 +  - **Critical lesson**: User feedback often reveals fundamental data quality issues masked by surface-level success
       1376 +  - **Response quality**: Systematic debugging with diagnostic scripts rather than quick fixes
       1377 +  
       1378 +  **Content Organization Principles**
       1379 +  - **User insight**: "Don't just tack things on but slot them in where appropriate"
       1380 +  - **Implementation**: Moved geographic patterns map from causation section to proper location after economic mechanisms
       1381 +  - **Standard**: Always consider logical narrative flow, not just chronological addition of content
       1382 +  - **Quality check**: Does new content enhance existing sections or require separate treatment?
       1383 +  
       1384 +  #### Data Quality Issues That Slipped Through Automated Checks
       1385 +  **State Extraction Failures**
       1386 +  - **Root cause**: Regex `str_extract(NAME, "[A-Z]{2}$")` failed on two-word state names like "New Hampshire"
       1387 +  - **Manifestation**: All 2,904 counties showed `state = NA`, causing region classification to default to "Other"
       1388 +  - **Systematic fix**: Updated regex to `str_extract(NAME, ", (.+)$", group = 1)` with full state name lookup table
       1389 +  - **Learning**: Geographic data extraction needs comprehensive testing across all state name formats
       1390 +  
       1391 +  **Map Coverage Completeness**
       1392 +  - **Issue discovered**: 326 counties missing from bivariate map due to population < 5,000 exclusion from analysis
       1393 +  - **User challenge**: "many counties appear to be missing... is there a division by zero issue?"
       1394 +  - **Root cause**: Analysis included 2,904 counties but tigris provides 3,222 total US counties
       1395 +  - **Solution**: Complete coverage approach with estimated values for small counties
       1396 +  - **Key insight**: Visualization coverage should be planned independently from analysis sample constraints
       1397 +  
       1398 +  #### Census Data Architecture Deeper Understanding
       1399 +  **Population Threshold Implications**
       1400 +  - **Discovery**: ACS data availability varies by county population, creating systematic coverage gaps
       1401 +  - **Impact**: Small rural counties systematically excluded from linguistic diversity analysis
       1402 +  - **Visualization challenge**: Maps appear incomplete without handling excluded counties
       1403 +  - **Best practice**: Always check total universe (tigris counties) vs. analysis sample (ACS counties) coverage
       1404 +  
       1405 +  **Geographic Data Integration Complexities**
       1406 +  - **State variable issues**: Census NAME field format varies, requiring robust extraction logic
       1407 +  - **Bivariate mapping challenges**: Missing data requires thoughtful default value assignment
       1408 +  - **Coverage transparency**: Map captions should acknowledge estimated values for excluded counties
       1409 +  - **Quality standard**: 100% geographic coverage for national-scale visualizations
       1410 +  
       1411 +  #### Systematic Debugging Methodology
       1412 +  **Multi-Script Diagnostic Approach**
       1413 +  - **Problem identification**: Created `diagnose-issues.R` to systematically check data quality
       1414 +  - **Root cause analysis**: Separate scripts for state extraction (`fix-state-extraction.R`) and map coverage (`debug-map-coverage.R`)
       1415 +  - **Iterative refinement**: Multiple diagnostic cycles to understand data pipeline failures
       1416 +  - **Documentation**: Each debugging script preserved for future reference and learning
       1417 +  
       1418 +  **Data Validation Standards**
       1419 +  - **State extraction verification**: Always check `table(data$state, useNA = "always")` after geographic variable creation
       1420 +  - **Coverage analysis**: Compare analysis sample size to expected universe (tigris county count)
       1421 +  - **Missing data patterns**: Investigate systematic exclusions rather than assuming random missingness
       1422 +  - **Map rendering validation**: Check for missing counties in geographic visualizations
       1423 +  
       1424 +  #### Technical Implementation Learnings
       1425 +  **Complete Map Coverage Strategy**
       1426 +  - **Approach**: Include ALL counties from tigris, assign estimated values to excluded counties
       1427 +  - **Transparency**: Clear caption noting small counties have estimated values
       1428 +  - **Coverage metric**: Report both analysis coverage (2,904) and map coverage (3,222) 
       1429 +  - **Visual quality**: Prevents distracting gaps that suggest analysis incompleteness
       1430 +  
       1431 +  **Data Pipeline Quality Control**
       1432 +  - **State lookup table**: Comprehensive mapping from full state names to abbreviations
       1433 +  - **Default value assignment**: Principled approach for missing counties (shannon_entropy = 0.001, median_income = $35,000)
       1434 +  - **Geometry preservation**: Maintain spatial relationships while handling missing analysis data
       1435 +  - **Bivariate classification**: Handle zero/very low values to prevent classification failures
       1436 +  
       1437 +  #### Process Improvements for Future Sessions
       1438 +  **Enhanced Data Quality Checks**
       1439 +  - **MANDATORY state variable validation**: `table(data$state, useNA = "always")` before any geographic analysis
       1440 +  - **Coverage verification**: Compare analysis sample to expected geographic universe
       1441 +  - **Map completeness check**: Verify no missing counties before creating choropleth visualizations
       1442 +  - **User feedback integration**: Systematic debugging rather than surface-level corrections
       1443 +  
       1444 +  **Geographic Analysis Standards**
       1445 +  - **Complete coverage planning**: Design visualizations to handle excluded counties from analysis start
       1446 +  - **State extraction robustness**: Use comprehensive state name lookup rather than regex-only approaches
       1447 +  - **Transparency in methodology**: Document any estimated values or excluded data in captions
       1448 +  - **Regional classification accuracy**: Verify geographic categorizations after state variable creation
       1449 +  
       1450 +  #### Success Metrics From Session
       1451 +  **Problem Resolution Effectiveness**
       1452 +  - **Section organization**: Successfully moved geographic patterns to logical narrative location
       1453 +  - **Region table**: Fixed from all "Other" to accurate California, New York Metro, DC Metro classifications
       1454 +  - **Map coverage**: Achieved 100% county coverage (3,222) vs. previous 89.9% (2,896)
       1455 +  - **User satisfaction**: All three specific feedback points addressed systematically
       1456 +  
       1457 +  **Data Quality Control Implementation**
       1458 +  - **Diagnostic methodology**: Created systematic debugging approach for future geographic data issues
       1459 +  - **Documentation completeness**: All fixes preserved in commented scripts for future reference
       1460 +  - **Validation standards**: Established geographic data quality checks to prevent similar issues
       1461 +  - **Technical debt resolution**: Fixed underlying data pipeline issues rather than cosmetic corrections
       1462 +  
       1463 +  #### Key Learning: User Feedback as Quality Control
       1464 +  Despite implementing automated quality check standards, fundamental data quality issues (state extraction failure, missing counties) slipped through initial review. **User feedback provided 
            + essential quality control that revealed systematic problems masked by surface-level functionality**. This session demonstrates that **iterative improvement based on specific user feedback 
     often
            +  leads to deeper understanding and better final products** than initial automated checks alone.
       1465 +  
       1466 +  The three specific issues raised by the user led to discovering and fixing fundamental data pipeline problems that would have affected future analyses. This reinforces the value of detailed 
            + user review and systematic response to feedback.
       1467 +  
```

The final result is [here](/analyses/2025-07-20-linguistic-entropy/) and the full session log is [here](https://gist.github.com/dshkol/09d4db4ed28c73026103246bdaf52656). 

## Iterative context refinement

The most important component in this workflow is the ever-growing `workflow-learnings.md` document with tactical session learnings. We can think of it as an example of iterative context development as an alternative to front-loading prescriptive context. There's a couple of concepts at play here tackling the initial cold start problem: 

* **Curriculum Learning**: This is the idea that you train a learning model starting with easy examples and gradually moving to more complex ones. The easy examples build a foundation that allow the model to be more resilient in handling more complex cases. This is essentially how humans tend to learn as well. The `workflow-learnings.md` doc implements the curriculum and each session can be thought of as a progressively more challenging lesson that assumes that the model has internalized all the previous lessons (sessions) up to now. We started with easy tasks (the early sessions) where the initial analyses were simpler. The feedback in those sessions was about basic code structure, file organization, and simple visualization choices. We then moved on to more complex sessions. As the core competencies were established, the tasks became more complex (e.g., advanced statistical methods, fixing subtle data errors, narrative refinement). The feedback became more nuanced (e.g., avoiding AI-ish writing patterns, implementing a "Critic" agent concept). Through this process we're basically boostrapping an increasingly complex and robust context base. 
* **Active Learning**: An RL strategy where the learning algorithm itself chooses the data from which it wants to learn, typically by identifying examples it is most uncertain about. Here, we are implicitly doing active learning with a human in the loop. The agent doesn't fully choose the tasks independently, but the failures on new, challenging tasks are the most informative "data points." When the agent fails to handle a new edge case (like a missing data year or an entropy divide-by-zero issue), it has revealed a point of maximum "uncertainty" or incompetence in its policy. The corrective feedback is the "label" that provides the most learning value, precisely because it addresses a demonstrated failure point.

## Takeaways

So is the analysis any good? This isn't superintelligence but it's not bad as a start. Would this pass peer review and get published? Of course not. There's mistakes in methods, and mistakes in data. Some of which are subtle and hard to catch when you're not building the analysis yourself. There are definitely mistakes in the demo analyses below and in the example we walked through. But I don't think it's a far stretch to think we're not that far off here, and clever use of different agent roles can further reduce data and method errors. And, as always: whatever models we have today are the worst models we will ever have going forward.

As it stands now, the system needs fundamental improvements to be more than a curiosity. Better state management, more robust error handling, better ways of catching data errors. An effective critic agent -- or several -- could improve robustness here. It's also possible fine-tuning could capture some of the accumulated context, though I suspect the flexibility of RAG is hard to beat.

## The Analyses

Here's what came out of this experiment - analyses that made it through the full pipeline:

### 1. [Tech Hub Hollowing: The Demographic Paradox of Innovation Centers](/analyses/2025-07-20-tech-hub-hollowing/)
Tracking how tech booms create their own demographic undermining.

### 2. [Language Diversity Fuels Economic Innovation: Evidence from American Counties](/analyses/2025-07-20-linguistic-entropy/)
Testing whether linguistic diversity measured through Shannon entropy correlates with economic dynamism at the county level.

### 3. [The Linguistic Archipelago: When Language Isolation Drives Success](/census-monkey-typewriter/analyses/linguistic-archipelago.html)
Border counties where Spanish dominance correlates with higher incomes, challenging integration assumptions.

### 4. [Temporal Demographic Momentum: The Mathematics of Population Change](/census-monkey-typewriter/analyses/temporal-demographic-momentum-v2.html)
Exploring how demographic momentum creates predictable population trajectories despite changing fertility patterns.

### 5. [Seasonal Demographic Pulse: The Rhythm of American Migration](/census-monkey-typewriter/analyses/seasonal-demographic-pulse-v2.html)
Mapping the dramatic population swings in seasonal migration hotspots with enhanced methodology.

### 6. [Bimodal Commute: When Geography Creates Two Different Cities](/census-monkey-typewriter/analyses/bimodal-commute.html)
Identifying metropolitan areas where commute patterns reveal fundamentally different urban experiences.

### 7. [Empty Nester Housing Inefficiency: When Big Houses Meet Small Households](/census-monkey-typewriter/analyses/empty-nester-housing-inefficiency.html)
Geographic clustering of housing/household size mismatches and their economic implications.

### 8. [The Fertility Frontier: Where Large Families Still Thrive](/census-monkey-typewriter/analyses/fertility-frontier.html)
Identifying modern high-fertility clusters beyond traditional religious communities.

### 9. [Geographic NIMBY Detection: The Spatial Signature of Housing Resistance](/analyses/2025-07-20-geographic-nimby-detection/)
Using demographic proxies to map development resistance patterns.

### 10. [The Grandparent Dividend: Multi-Generational Households and Economic Advantage](/census-monkey-typewriter/analyses/grandparent-dividend.html)
How co-resident grandparents affect household economics across different geographies.

### 11. [Infrastructure Inequality Gradient: The Digital Divide's Hidden Geography](/census-monkey-typewriter/analyses/infrastructure-inequality-gradient.html)
Broadband access patterns that cut across traditional geographic categories.

### 12. [The 3 AM Population: Night Owls and Geographic Settlement Patterns](/census-monkey-typewriter/analyses/3am-population.html)
Mapping communities where late-night activity reveals unique demographic and economic patterns.

### 13. [Age Structure Archipelago: When Demographics Create Geographic Islands](/census-monkey-typewriter/analyses/age-structure-singularity-enhanced.html)
Identifying counties with extreme age concentrations that create distinct demographic islands.

### 14. [Monoculture Coast: The Geography of Ethnic Concentration](/census-monkey-typewriter/analyses/monoculture-coast.html)
Tracking where single ancestry groups achieve geographic dominance and the patterns this creates.

### 15. [Vertical City: The Rise of High-Density Living](/census-monkey-typewriter/analyses/vertical-city.html)
Mapping America's transition toward vertical living and its demographic implications.

### 16. [Vowel Valley, Consonant County: The Phonetic Geography of America](/census-monkey-typewriter/analyses/vowel-valley-consonant-county.html)
A whimsical exploration of whether place names' phonetic patterns correlate with demographic characteristics.

### 17. [The 3am Population: Night Shift Workers and Urban Vitality](/analyses/2025-07-20-3am-population/)
Mapping America's night shift economy reveals hidden patterns of 24-hour work concentrations and their impact on community demographics.

### 18. [The Bimodal Commute: Unmasking Super-Commuters and Local Workers](/analyses/2025-07-20-bimodal-commute/)
Gaussian mixture models reveal counties with two distinct commuter populations: local workers and super-commuters traveling vast distances.

### 19. [America's Seasonal Pulse: The Hidden Rhythms of Demographic Life](/analyses/2025-07-20-seasonal-demographic-pulse/)
Counties with extreme seasonal population swings reveal America's hidden rhythms of vacation economies and seasonal work patterns.

### 20. [The 'Nothing Ever Changes' Index: Discovering America's Most Static County](/analyses/2025-07-20-nothing-ever-changes/)
Quantifying demographic stability across 2,865 counties reveals Poweshiek County, Iowa as America's most unchanging place.

### 21. [Dead Language Archipelago: The Fading Linguistic Landscape](/census-monkey-typewriter/analyses/dead-language-archipelago.R)
Failed attempt at mapping heritage language decline (kept as a methodological lesson).
