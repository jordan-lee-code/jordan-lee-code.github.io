# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Site overview

Jekyll static site using the Chirpy theme, deployed to GitHub Pages at `https://lee-it.co.uk`. Built and deployed via GitHub Actions (`.github/workflows/pages.yml`) rather than the standard GitHub Pages gem, to support the full Chirpy plugin set.

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

- `_config.yml` — site title, tagline, author, theme, plugins, and collection config
- `_tabs/` — nav pages (About, Experience, Tech Stack, Now, Tags, Categories, Archives); each file needs `icon`, `order`, and `title` front matter
- `_posts/` — blog posts named `YYYY-MM-DD-slug.md` with `layout: post` front matter
- `index.html` — home page using `layout: home` (must be `.html` for Chirpy's paginator)
- `assets/img/` — images including `avatar.webp`

## Adding content

**New post:** create `_posts/YYYY-MM-DD-slug.md`:
```yaml
---
layout: post
title: "Post Title"
date: YYYY-MM-DD
description: "One or two sentences summarising the post (150-160 chars). No em dashes."
categories: [Category]
tags:
  - tag-one
  - tag-two
---
```

**New nav page:** create `_tabs/page-name.md`:
```yaml
---
title: Page Title
icon: fas fa-icon-name
order: N
---
```

**Tags, Categories, Archives:** These are powered by `jekyll-archives` and use Chirpy-specific layouts (`layout: tags`, `layout: categories`, `layout: archives`). The config lives in `_config.yml` under `jekyll-archives`. Adding a new tag to a post is enough — `jekyll-archives` generates the tag page automatically. Do not set `layout: page` on `_tabs/tags.md`, `_tabs/categories.md`, or `_tabs/archives.md`; they must use their respective layout names or the pages will be blank.

## Blog post style guide

Jordan's posts are written in first person and cover technical topics from hands-on experience. When writing or editing posts, follow these rules:

**Voice and tone**
- Write as Jordan, not as a narrator. Use "I", "we" (when referring to the team at work), "my".
- Conversational but technically precise. Sound like a knowledgeable engineer talking to a peer, not a formal technical writer.
- Keep it honest and grounded. If something was annoying, say so. If something surprised you, say so.

**Punctuation and formatting**
- No em dashes. Use a regular hyphen, a comma, or restructure the sentence instead.
- No en dashes as separators. Prefer "to" (e.g. "10 to 20 teams") or a hyphen in ranges.
- Short paragraphs. Two to four sentences is the target. Break up anything longer.
- Use `code formatting` for commands, file paths, config keys, and tool names used in a technical context.
- Use numbered steps for sequential processes, bullet points for non-ordered lists.

**Structure**
- Open with the problem or the context, not a definition or background. Get to the point quickly.
- Use `##` headings to break the post into named sections. Avoid `###` unless genuinely needed.
- End with a practical takeaway or a brief reflection, not a summary of what was just said.

**Technical content**
- Keep technical detail. Don't soften or remove specifics to make it more accessible.
- Include real examples, commands, and config snippets where relevant.
- Reference tools and products by their real names.

**What to avoid**
- Em dashes (use alternatives as above)
- Phrases like "In conclusion", "In summary", "To summarise"
- Overly formal transitions like "Furthermore", "Moreover", "It is worth noting that"
- Starting sentences with "This means that" repeatedly
- Padding and filler: if a sentence doesn't add anything, cut it
