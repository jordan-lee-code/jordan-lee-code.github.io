Run `scripts/generate-cv.sh` to regenerate `assets/Jordan-Lee-CV.pdf`.

The CV is dynamically generated from `_data/cv.yml` — edit that file to update skills, certifications, education, experience bullets, or the profile summary. Changes will appear in both the CV PDF and the About page on next build.

The script runs `bundle exec jekyll build` then prints `_site/assets/cv.html` to PDF using headless Chromium.
