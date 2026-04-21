# lee-it.co.uk

Personal site and blog for Jordan Lee — DevOps & Cloud Infrastructure Engineer.

Built with [Jekyll](https://jekyllrb.com/) and the [Chirpy](https://github.com/cotes2333/jekyll-theme-chirpy) theme, deployed to GitHub Pages via GitHub Actions.

## Local development

```bash
bundle install
bundle exec jekyll serve --livereload
```

The site builds to `_site/` (gitignored) and is available at `http://localhost:4000`.

## Structure

| Path | Purpose |
|------|---------|
| `_posts/` | Blog posts (`YYYY-MM-DD-slug.md`) |
| `_tabs/` | Nav pages (About, Experience, Now, etc.) |
| `_data/cv.yml` | CV data used by the About and Experience pages |
| `assets/` | Images, fonts, and the generated CV PDF |
| `_config.yml` | Site config — title, author, theme, plugins |
| `.claude/` | Claude Code context files (gitignored where private) |

## Deployment

Pushing to `main` triggers the GitHub Actions workflow at `.github/workflows/pages.yml`, which builds and deploys the site. The CV PDF is regenerated automatically via a pre-push hook.
