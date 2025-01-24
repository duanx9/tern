% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/analyze_vars_in_cols.R
\name{analyze_vars_in_cols}
\alias{analyze_vars_in_cols}
\title{Summary numeric variables in columns}
\usage{
analyze_vars_in_cols(
  lyt,
  vars,
  ...,
  .stats = c("n", "mean", "sd", "se", "cv", "geom_cv"),
  .labels = c(n = "n", mean = "Mean", sd = "SD", se = "SE", cv = "CV (\%)", geom_cv =
    "CV \% Geometric Mean"),
  row_labels = NULL,
  do_summarize_row_groups = FALSE,
  split_col_vars = TRUE,
  .indent_mods = NULL,
  nested = TRUE,
  na_level = NULL,
  .formats = NULL
)
}
\arguments{
\item{lyt}{(\code{layout})\cr input layout where analyses will be added to.}

\item{vars}{(\code{character})\cr variable names for the primary analysis variable to be iterated over.}

\item{...}{additional arguments for the lower level functions.}

\item{.stats}{(\code{character})\cr statistics to select for the table.}

\item{.labels}{(named \code{character})\cr labels for the statistics (without indent).}

\item{row_labels}{(\code{character})\cr as this function works in columns space, usual \code{.labels}
character vector applies on the column space. You can change the row labels by defining this
parameter to a named character vector with names corresponding to the split values. It defaults
to \code{NULL} and if it contains only one \code{string}, it will duplicate that as a row label.}

\item{do_summarize_row_groups}{(\code{flag})\cr defaults to \code{FALSE} and applies the analysis to the current
label rows. This is a wrapper of \code{\link[rtables:summarize_row_groups]{rtables::summarize_row_groups()}} and it can accept \code{labelstr}
to define row labels. This behavior is not supported as we never need to overload row labels.}

\item{split_col_vars}{(\code{flag})\cr defaults to \code{TRUE} and puts the analysis results onto the columns.
This option allows you to add multiple instances of this functions, also in a nested fashion,
without adding more splits. This split must happen only one time on a single layout.}

\item{.indent_mods}{(named \code{integer})\cr indent modifiers for the labels. Defaults to 0, which corresponds to the
unmodified default behavior. Can be negative.}

\item{nested}{(\code{flag})\cr whether this layout instruction be applied within the existing layout structure \emph{if
possible} (\code{TRUE}, the default) or as a new top-level element (\code{FALSE}). Ignored if it would nest a split
underneath analyses, which is not allowed.}

\item{na_level}{(\code{string})\cr string used to replace all \code{NA} or empty values in the output.}

\item{.formats}{(named \code{character} or \code{list})\cr formats for the statistics.}
}
\value{
A layout object suitable for passing to further layouting functions, or to \code{\link[rtables:build_table]{rtables::build_table()}}.
Adding this function to an \code{rtable} layout will summarize the given variables, arrange the output
in columns, and add it to the table layout.
}
\description{
\ifelse{html}{\href{https://lifecycle.r-lib.org/articles/stages.html#experimental}{\figure{lifecycle-experimental.svg}{options: alt='[Experimental]'}}}{\strong{[Experimental]}}

Layout-creating function which can be used for creating column-wise summary tables.
This function sets the analysis methods as column labels and is a wrapper for
\code{\link[rtables:analyze_colvars]{rtables::analyze_colvars()}}. It was designed principally for PK tables.
}
\note{
This is an experimental implementation of \code{\link[rtables:summarize_row_groups]{rtables::summarize_row_groups()}} and
\code{\link[rtables:analyze_colvars]{rtables::analyze_colvars()}} that may be subjected to changes as \code{rtables} extends its
support to more complex analysis pipelines on the column space. For the same reasons,
we encourage to read the examples carefully and file issues for cases that differ from
them.

Here \code{labelstr} behaves differently than usual. If it is not defined (default as \code{NULL}),
row labels are assigned automatically to the split values in case of \code{rtables::analyze_colvars}
(\code{do_summarize_row_groups = FALSE}, the default), and to the group label for
\code{do_summarize_row_groups = TRUE}.
}
\examples{
library(dplyr)

# Data preparation
adpp <- tern_ex_adpp \%>\% h_pkparam_sort()

lyt <- basic_table() \%>\%
  split_rows_by(var = "STRATA1", label_pos = "topleft") \%>\%
  split_rows_by(
    var = "SEX",
    label_pos = "topleft",
    child_label = "hidden"
  ) \%>\% # Removes duplicated labels
  analyze_vars_in_cols(vars = "AGE")
result <- build_table(lyt = lyt, df = adpp)
result

# By selecting just some statistics and ad-hoc labels
lyt <- basic_table() \%>\%
  split_rows_by(var = "ARM", label_pos = "topleft") \%>\%
  split_rows_by(
    var = "SEX",
    label_pos = "topleft",
    child_labels = "hidden",
    split_fun = drop_split_levels
  ) \%>\%
  analyze_vars_in_cols(
    vars = "AGE",
    .stats = c("n", "cv", "geom_mean"),
    .labels = c(
      n = "aN",
      cv = "aCV",
      geom_mean = "aGeomMean"
    )
  )
result <- build_table(lyt = lyt, df = adpp)
result

# Changing row labels
lyt <- basic_table() \%>\%
  analyze_vars_in_cols(
    vars = "AGE",
    row_labels = "some custom label"
  )
result <- build_table(lyt, df = adpp)
result

# Pharmacokinetic parameters
lyt <- basic_table() \%>\%
  split_rows_by(
    var = "TLG_DISPLAY",
    split_label = "PK Parameter",
    label_pos = "topleft",
    child_label = "hidden"
  ) \%>\%
  analyze_vars_in_cols(
    vars = "AVAL"
  )
result <- build_table(lyt, df = adpp)
result

# Multiple calls (summarize label and analyze underneath)
lyt <- basic_table() \%>\%
  split_rows_by(
    var = "TLG_DISPLAY",
    split_label = "PK Parameter",
    label_pos = "topleft"
  ) \%>\%
  analyze_vars_in_cols(
    vars = "AVAL",
    do_summarize_row_groups = TRUE # does a summarize level
  ) \%>\%
  split_rows_by("SEX",
    child_label = "hidden",
    label_pos = "topleft"
  ) \%>\%
  analyze_vars_in_cols(
    vars = "AVAL",
    split_col_vars = FALSE # avoids re-splitting the columns
  )
result <- build_table(lyt, df = adpp)
result

}
\seealso{
\code{\link[=analyze_vars]{analyze_vars()}}, \code{\link[rtables:analyze_colvars]{rtables::analyze_colvars()}}.
}
