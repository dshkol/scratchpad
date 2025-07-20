---
title: "Census Monkey Typewriter: Agentic Social Science Research"
author: "Dmitry Shkolnik"
date: '2025-07-17'
summary: "An experiment in using LLMs as research partners for demographic analysis. Some hypotheses panned out; many didn't. Here's what I learned about AI-assisted social science research."
slug: census-monkey-typewriter
categories:
  - blog
  - experimental
  - ai
tags:
  - census
  - demographics
  - spatial-analysis
  - claude-code
  - ai-research
---

I spent the last few months building a system to treat Claude as a demographic research partner. The goal was straightforward: could an LLM generate interesting hypotheses about spatial patterns in census data, then actually execute the analysis to test them? The short answer is yes, with significant caveats.

## The System

The core architecture is deceptively simple. I built a stateful workflow that maintains context across sessions through version-controlled instruction files. Think of it as RLHF implemented through RAG - the agent reads its accumulated learnings before each task, and I update those files when things go wrong (which happened frequently).

The workflow has two main phases:
1. Hypothesis generation - Claude proposes research questions based on available census variables
2. Analysis execution - It writes R code to test those hypotheses, first as scripts, then as polished R Markdown

What made this interesting wasn't the individual components but the emergent behavior. After dozens of iterations, the system developed consistent patterns: specific visualization aesthetics, preferred statistical approaches, even recurring narrative structures. It's a bespoke system trained on my feedback, fragile and overfit to my preferences, but occasionally capable of genuine insights.

## What Actually Worked

The surprise was how often the counterintuitive hypotheses held up. When Claude suggested that linguistic isolation might correlate with economic success rather than hardship, I was skeptical. But the data showed clear patterns in border counties and established ethnic enclaves where non-English dominance coincided with higher median incomes.

The system excelled at finding non-obvious geographic patterns. The "seasonal demographic pulse" analysis revealed migration patterns I'd never considered - snowbird counties with 30%+ population swings between seasons, creating fascinating economic dynamics. The infrastructure inequality work uncovered "internet deserts" that don't align with traditional rural/urban divides.

## What Failed Spectacularly

For every interesting finding, there were multiple failures. The "Dead Language Archipelago" analysis crashed and burned - turns out the census doesn't track dying languages with enough granularity. Several hypotheses about causation fell apart when we couldn't control for confounding variables. The system would often propose analyses requiring data that simply doesn't exist at the geographic resolution needed.

More fundamentally, the agent struggled with knowing when to stop. It would chase increasingly tenuous correlations, building elaborate statistical castles on foundations of sand. I had to build in explicit "skepticism prompts" to make it question its own findings.

## Technical Lessons

The most valuable learning was about context engineering. You can't front-load all the necessary instructions - the system needs to fail first, then you encode the lessons. My `WORKFLOW-LEARNINGS.md` file grew from 2KB to 45KB over three months, each addition addressing a specific failure mode.

R and the tidyverse proved perfect for this experiment. The functional programming style meant Claude could compose analyses from well-understood building blocks. The census data packages (`tidycensus`, `sf`) provided consistent interfaces that reduced errors.

But the system remains frustratingly brittle. Change the prompt structure slightly and visualization quality degrades. Ask for a new type of analysis and it might forget basic principles established over dozens of sessions. It's a reminder that these models don't truly "learn" from our interactions - they're just very good at following instructions.

## The Analyses

Here's what came out of this experiment - ten analyses that made it through the full pipeline:

### 1. [The Linguistic Archipelago: When Language Isolation Drives Success](/census-monkey-typewriter/analyses/linguistic-archipelago.html)
Border counties where Spanish dominance correlates with higher incomes, challenging integration assumptions.

### 2. [Seasonal Demographic Pulse: The Rhythm of American Migration](/census-monkey-typewriter/analyses/seasonal-demographic-pulse.html)
Mapping the dramatic population swings in seasonal migration hotspots.

### 3. [Empty Nester Housing Inefficiency: When Big Houses Meet Small Households](/census-monkey-typewriter/analyses/empty-nester-housing-inefficiency.html)
Geographic clustering of housing/household size mismatches and their economic implications.

### 4. [The Fertility Frontier: Where Large Families Still Thrive](/census-monkey-typewriter/analyses/fertility-frontier.html)
Identifying modern high-fertility clusters beyond traditional religious communities.

### 5. [Geographic NIMBY Detection: The Spatial Signature of Housing Resistance](/census-monkey-typewriter/analyses/geographic-nimby-detection.html)
Using demographic proxies to map development resistance patterns.

### 6. [The Grandparent Dividend: Multi-Generational Households and Economic Advantage](/census-monkey-typewriter/analyses/grandparent-dividend.html)
How co-resident grandparents affect household economics across different geographies.

### 7. [The Loneliness Gradient: Mapping Social Isolation in American Communities](/census-monkey-typewriter/analyses/loneliness-gradient.html)
Single-person household concentrations as a proxy for social isolation.

### 8. [Tech Hub Hollowing: The Demographic Paradox of Innovation Centers](/census-monkey-typewriter/analyses/tech-hub-hollowing.html)
Tracking how tech booms create their own demographic undermining.

### 9. [Dead Language Archipelago: The Fading Linguistic Landscape](/census-monkey-typewriter/analyses/dead-language-archipelago.R)
Failed attempt at mapping heritage language decline (kept as a methodological lesson).

### 10. [Infrastructure Inequality Gradient: The Digital Divide's Hidden Geography](/census-monkey-typewriter/analyses/infrastructure-inequality-gradient.html)
Broadband access patterns that cut across traditional geographic categories.

## What This Means

This experiment convinced me that LLMs can be valuable research partners, but not in the way most people imagine. They're not going to replace social scientists or discover fundamental new theories. Instead, they're useful for generating non-obvious questions and handling the mechanical aspects of analysis.

The real value was in the human-AI iteration loop. Claude would propose something absurd, I'd explain why it wouldn't work, and through that process we'd often land on a testable middle ground I wouldn't have considered alone. It's a tool for expanding the hypothesis space, not for automated discovery.

## Next Steps

The system needs fundamental improvements to be more than a curiosity. Better state management, more robust error handling, and some way to accumulate learnings that doesn't involve me manually editing markdown files. I'm exploring whether fine-tuning could capture some of the accumulated context, though I suspect the flexibility of RAG is hard to beat.

More importantly, I want to extend this beyond census data. The core pattern - hypothesis generation, iterative testing, accumulated learning - could apply to any domain with structured data and clear feedback loops. But that's a project for another day.

For now, this remains what it is: a successful failure, a working prototype of something not quite ready for prime time, and a collection of demographic analyses that occasionally surprise even me.

---

*The Census Monkey Typewriter system is available on GitHub, though I wouldn't recommend using it without significant modification. The analyses use official census data but should be considered exploratory research, not definitive findings.*