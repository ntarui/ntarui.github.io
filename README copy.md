# nori-tarui.github.io

Personal academic homepage — plain HTML/CSS, no build step, deploys straight to GitHub Pages.

## Files
- `index.html` — About, affiliations, contact
- `research.html` — Projects, publications, working papers
- `teaching.html` — Course listings by term
- `style.css` — Shared design tokens and layout

## Publish it on GitHub Pages

1. **Create the repo.** On GitHub, click **New repository**. Name it exactly
   `<your-username>.github.io` (e.g. `nori523.github.io`) — that exact name is
   what makes GitHub serve it at the root of that URL instead of a subpath.
   Leave it public, no README/template needed.

2. **Push these files.**
   ```bash
   cd site
   git init
   git add .
   git commit -m "Initial homepage"
   git branch -M main
   git remote add origin https://github.com/<your-username>/<your-username>.github.io.git
   git push -u origin main
   ```

3. **Turn on Pages.** In the repo: Settings → Pages → under "Build and
   deployment", set Source to "Deploy from a branch", branch `main`, folder
   `/ (root)`. Save.

4. **Visit it.** Within a minute or two it's live at
   `https://<your-username>.github.io`. GitHub Pages rebuilds automatically
   every time you push to `main` — no separate deploy step.

## Updating content later

**Teaching (`teaching.html`) and the About/contact info (`index.html`)** are
plain HTML — open the file, edit the text, commit, push.

**Publications and working papers (`research.html`)** are generated from
`references.bib` — don't hand-edit the list itself. Instead:

1. Add or edit an entry in `references.bib`. Each entry needs one field per
   line, e.g.:
   ```
   @article{smith2027example,
     author  = {Smith, Jane and Tarui, Nori},
     title   = {An Example Paper Title},
     journal = {Example Journal},
     year    = {2027},
     volume  = {12},
     pages   = {1--20},
     doi     = {10.xxxx/example},
     url     = {https://doi.org/10.xxxx/example}
   }
   ```
   Use `@article` for journal papers and `@techreport` for working papers
   (with `institution` and `number` fields instead of `journal`/`volume`).
2. Run:
   ```bash
   Rscript build_research.R
   ```
   This reads `references.bib` and rewrites only the two marked blocks in
   `research.html` (between `<!-- BIB:PUBLICATIONS:START/END -->` and
   `<!-- BIB:WORKING_PAPERS:START/END -->`) — everything else in the page
   (nav, projects list, page header) is left untouched.
3. Commit both `references.bib` and the regenerated `research.html`, then
   push.

`build_research.R` uses only base R — no packages to install, so it runs on
any machine with R (including a fresh install). It handles a small set of
LaTeX-ish macros used in the bib file for diacritics (`{\okina}` → ʻ, `\={a}`
→ ā, `\={i}` → ī) and formats author names as `Last, F.M.` and page ranges
with a proper en dash.

## Optional: custom domain
If you'd rather use e.g. `noritarui.com`, add a `CNAME` file to the repo root
containing just that domain, and point your domain's DNS at GitHub Pages
(A records to GitHub's IPs, or a CNAME record to `<your-username>.github.io`).
GitHub's Pages settings page will show a "Custom domain" field that automates
most of this once DNS propagates.
