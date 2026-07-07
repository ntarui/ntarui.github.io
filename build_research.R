#!/usr/bin/env Rscript
# ============================================================
# build_research.R
#
# Regenerates the publication list and working-paper list in
# research.html directly from references.bib. Uses base R only
# (no packages to install) so it runs anywhere R runs.
#
# Usage:
#   Rscript build_research.R
#
# After editing references.bib (e.g. adding a new @article or
# @techreport entry), just re-run this script and commit the
# updated research.html. Everything outside the two marked
# blocks in research.html (nav, hero, projects list, teaching
# link, footer) is left untouched.
# ============================================================

invisible(Sys.setlocale("LC_ALL", "C.UTF-8"))

bib_path  <- "references.bib"
html_path <- "research.html"

# ---------- 1. Parse the .bib file ----------
# Assumes the simple, one-field-per-line style used in
# references.bib: each field is "  name = {value}," (trailing
# comma optional on the last field of an entry).

parse_bib <- function(path) {
  lines <- readLines(path, warn = FALSE)
  entries <- list()
  current <- NULL

  entry_start <- "^@(\\w+)\\{([^,]+),\\s*$"
  field_line  <- "^\\s*([a-zA-Z]+)\\s*=\\s*\\{(.*)\\},?\\s*$"

  for (ln in lines) {
    if (grepl("^\\s*%", ln) || grepl("^\\s*$", ln)) next

    if (grepl(entry_start, ln)) {
      if (!is.null(current)) entries[[length(entries) + 1]] <- current
      m <- regmatches(ln, regexec(entry_start, ln))[[1]]
      current <- list(type = tolower(m[2]), key = m[3], fields = list())
      next
    }

    if (!is.null(current) && grepl(field_line, ln)) {
      m <- regmatches(ln, regexec(field_line, ln))[[1]]
      current$fields[[tolower(m[2])]] <- m[3]
      next
    }
    # closing "}" lines and anything else are ignored
  }
  if (!is.null(current)) entries[[length(entries) + 1]] <- current
  entries
}

# ---------- 2. Unescape the small set of LaTeX-ish macros we use ----------
unescape_bib <- function(x) {
  x <- gsub("\\{\\\\okina\\}", "\u02bb", x)              # {\okina} -> ʻ
  x <- gsub("\\\\=\\{a\\}", "\u0101", x)                 # \={a}   -> ā
  x <- gsub("\\\\=\\{i\\}", "\u012b", x)                 # \={i}   -> ī
  x <- gsub("\\\\&", "&amp;", x)                          # \&      -> &amp; (valid HTML)
  x <- gsub("[{}]", "", x)                                # drop any leftover
  x                                                        #  case-protection braces
}

# ---------- 3. Author formatting: "Last, First Middle" -> "Last, F.M." ----------
format_authors <- function(author_field) {
  people <- strsplit(author_field, "\\s+and\\s+")[[1]]
  formatted <- vapply(people, function(p) {
    parts <- strsplit(p, ",\\s*")[[1]]
    if (length(parts) < 2) return(unescape_bib(p))
    last  <- unescape_bib(trimws(parts[1]))
    first <- trimws(parts[2])
    tokens <- strsplit(gsub("-", " ", first), "\\s+")[[1]]
    initials <- paste0(substr(tokens, 1, 1), ".", collapse = "")
    paste0(last, ", ", initials)
  }, character(1))
  paste(formatted, collapse = "; ")
}

# ---------- 4. Venue string: "vol(no), pages" ----------
format_venue_details <- function(f) {
  vol <- f[["volume"]]; no <- f[["number"]]; pg <- f[["pages"]]
  if (!is.null(pg)) pg <- gsub("--", "\u2013", pg)
  out <- ""
  if (!is.null(vol)) {
    out <- vol
    if (!is.null(no)) out <- paste0(out, "(", no, ")")
    if (!is.null(pg)) out <- paste0(out, ", ", pg)
  } else if (!is.null(pg)) {
    out <- pg
  }
  out
}

link_for <- function(f) {
  if (!is.null(f[["url"]])) return(f[["url"]])
  if (!is.null(f[["doi"]])) return(paste0("https://doi.org/", f[["doi"]]))
  "#"
}

# ---------- 5. Render one @article as an <li> ----------
render_article <- function(e) {
  f <- e$fields
  yr      <- f[["year"]]
  authors <- format_authors(f[["author"]])
  title   <- unescape_bib(f[["title"]])
  journal <- unescape_bib(f[["journal"]])
  details <- format_venue_details(f)
  link    <- link_for(f)

  li <- sprintf(
    '<li><span class="yr">%s</span> %s "%s," <span class="venue"><a href="%s">%s</a></span>%s.</li>',
    yr, authors, title, link, journal,
    if (nzchar(details)) paste0(", ", details) else ""
  )
  if (!is.null(f[["note"]])) {
    li <- sub("</li>$",
              sprintf('\n    <p class="pub-note">%s.</p>\n  </li>', unescape_bib(f[["note"]])),
              li)
  }
  li
}

# ---------- 6. Render one @techreport as an <li> ----------
render_techreport <- function(e) {
  f <- e$fields
  yr      <- f[["year"]]
  authors <- format_authors(f[["author"]])
  title   <- unescape_bib(f[["title"]])
  inst    <- unescape_bib(f[["institution"]])
  num     <- f[["number"]]
  link    <- link_for(f)
  label   <- if (!is.null(num)) paste0(inst, ", ", num) else inst

  li <- sprintf(
    '<li>%s (%s). "%s." <a href="%s">%s</a>.</li>',
    authors, yr, title, link, label
  )
  if (!is.null(f[["note"]])) {
    li <- sub("</li>$",
              sprintf('\n    <p class="pub-note">%s.</p>\n  </li>', unescape_bib(f[["note"]])),
              li)
  }
  li
}

# ---------- 7. Splice generated HTML between markers ----------
replace_block <- function(html, start_marker, end_marker, inner_html) {
  pattern <- paste0("(?s)(", start_marker, ").*?(", end_marker, ")")
  replacement <- paste0(start_marker, "\n", inner_html, "\n", end_marker)
  sub(pattern, replacement, html, perl = TRUE)
}

# ============================================================
# Main
# ============================================================
entries <- parse_bib(bib_path)

articles <- Filter(function(e) e$type == "article", entries)
reports  <- Filter(function(e) e$type == "techreport", entries)

# newest first
articles <- articles[order(-as.integer(vapply(articles, function(e) e$fields[["year"]], character(1))))]
reports  <- reports[order(-as.integer(vapply(reports,  function(e) e$fields[["year"]], character(1))))]

pub_html <- paste0(
  '        <ol class="pub-list">\n',
  paste0("          ", vapply(articles, render_article, character(1)), collapse = "\n"),
  '\n        </ol>'
)

wp_html <- paste0(
  '      <ul class="pub-list">\n',
  paste0("        ", vapply(reports, render_techreport, character(1)), collapse = "\n"),
  '\n      </ul>'
)

html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
html <- replace_block(html, "<!-- BIB:PUBLICATIONS:START -->", "<!-- BIB:PUBLICATIONS:END -->", pub_html)
html <- replace_block(html, "<!-- BIB:WORKING_PAPERS:START -->", "<!-- BIB:WORKING_PAPERS:END -->", wp_html)

writeLines(html, html_path)

cat(sprintf("Wrote %d publications and %d working papers into %s\n",
            length(articles), length(reports), html_path))
