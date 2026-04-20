# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Site overview

Jekyll static site using the `minima` theme, deployed to GitHub Pages at `https://lee-it.co.uk`. The `github-pages` gem pins Jekyll and plugin versions to match GitHub Pages.

## Commands

```bash
# Install dependencies
bundle install

# Serve locally with live reload
bundle exec jekyll serve --livereload

# Build only
bundle exec jekyll build
```

The built site outputs to `_site/` (gitignored).

## Structure

- `_config.yml` — site title, author, theme (`minima`/`classic` skin), header nav pages, and plugins
- `_posts/` — blog posts named `YYYY-MM-DD-title.md` with `layout: post` front matter
- `about.md`, `portfolio.md` — static pages with `layout: page`; listed in `header_pages` in `_config.yml`
- `index.md` — home page

## Adding content

**New post:** create `_posts/YYYY-MM-DD-slug.md` with front matter:
```yaml
---
layout: post
title: "Post Title"
date: YYYY-MM-DD
---
```

**New page:** create a `.md` file at root with `layout: page` and `permalink:`, then add the filename to `header_pages` in `_config.yml` to show it in the nav.
