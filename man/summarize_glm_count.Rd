% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/summarize_glm_count.R
\name{summarize_glm_count}
\alias{summarize_glm_count}
\alias{s_glm_count}
\alias{a_glm_count}
\title{Summary for Poisson Negative Binomial.}
\usage{
s_glm_count(
  df,
  .var,
  .df_row,
  variables,
  .ref_group,
  .in_ref_col,
  distribution,
  conf_level,
  rate_mean_method,
  weights,
  scale = 1
)

a_glm_count(
  df,
  .var,
  .df_row,
  variables,
  .ref_group,
  .in_ref_col,
  distribution,
  conf_level,
  rate_mean_method,
  weights,
  scale = 1
)

summarize_glm_count(
  lyt,
  vars,
  var_labels,
  ...,
  show_labels = "visible",
  table_names = vars,
  .stats = NULL,
  .formats = NULL,
  .labels = NULL,
  .indent_mods = NULL
)
}
\arguments{
\item{df}{(\code{data.frame})\cr data set containing all analysis variables.}

\item{.var}{(\code{string})\cr single variable name that is passed by \code{rtables} when requested
by a statistics function.}

\item{.df_row}{(\code{data.frame})\cr data frame across all of the columns for the given row split.}

\item{variables}{(named \code{list} of \code{string})\cr list of additional analysis variables.}

\item{.ref_group}{(\code{data.frame} or \code{vector})\cr the data corresponding to the reference group.}

\item{.in_ref_col}{(\code{logical})\cr \code{TRUE} when working with the reference level, \code{FALSE} otherwise.}

\item{conf_level}{(\code{proportion})\cr confidence level of the interval.}

\item{lyt}{(\code{layout})\cr input layout where analyses will be added to.}

\item{vars}{(\code{character})\cr variable names for the primary analysis variable to be iterated over.}

\item{var_labels}{(\code{character})\cr character for label.}

\item{...}{additional arguments for the lower level functions.}

\item{show_labels}{(\code{string})\cr label visibility: one of "default", "visible" and "hidden".}

\item{table_names}{(\code{character})\cr this can be customized in case that the same \code{vars} are analyzed multiple times,
to avoid warnings from \code{rtables}.}

\item{.stats}{(\code{character})\cr statistics to select for the table.}

\item{.formats}{(named \code{character} or \code{list})\cr formats for the statistics.}

\item{.labels}{(named \code{character})\cr labels for the statistics (without indent).}

\item{.indent_mods}{(named \code{integer})\cr indent modifiers for the labels. Defaults to 0, which corresponds to the
unmodified default behavior. Can be negative.}
}
\value{
\itemize{
\item \code{s_glm_count()} returns a named \code{list} of 5 statistics:
\itemize{
\item \code{n}: Count of complete sample size for the group.
\item \code{rate}: Estimated event rate per follow-up time.
\item \code{rate_ci}: Confidence level for estimated rate per follow-up time.
\item \code{rate_ratio}: Ratio of event rates in each treatment arm to the reference arm.
\item \code{rate_ratio_ci}: Confidence level for the rate ratio.
\item \code{pval}: p-value.
}
}

\itemize{
\item \code{a_glm_count()} returns the corresponding list with formatted \code{\link[rtables:CellValue]{rtables::CellValue()}}.
}

\itemize{
\item \code{summarize_glm_count()} returns a layout object suitable for passing to further layouting functions,
or to \code{\link[rtables:build_table]{rtables::build_table()}}. Adding this function to an \code{rtable} layout will add formatted rows containing
the statistics from \code{s_glm_count()} to the table layout.
}
}
\description{
\ifelse{html}{\href{https://lifecycle.r-lib.org/articles/stages.html#experimental}{\figure{lifecycle-experimental.svg}{options: alt='[Experimental]'}}}{\strong{[Experimental]}}

Summarize results of a Poisson Negative Binomial Regression.
This can be used to analyze count and/or frequency data using a linear model.
}
\section{Functions}{
\itemize{
\item \code{s_glm_count()}: Statistics function that produces a named list of results
of the investigated Poisson model.

\item \code{a_glm_count()}: Formatted analysis function which is used as \code{afun} in \code{summarize_glm_count()}.

\item \code{summarize_glm_count()}: Layout-creating function which can take statistics function arguments
and additional format arguments. This function is a wrapper for \code{\link[rtables:analyze]{rtables::analyze()}}.

}}
\examples{
library(dplyr)
anl <- tern_ex_adtte \%>\% filter(PARAMCD == "TNE")
anl$AVAL_f <- as.factor(anl$AVAL)

lyt <- basic_table() \%>\%
  split_cols_by("ARM", ref_group = "B: Placebo") \%>\%
  add_colcounts() \%>\%
  analyze_vars(
    "AVAL_f",
    var_labels = "Number of exacerbations per patient",
    .stats = c("count_fraction"),
    .formats = c("count_fraction" = "xx (xx.xx\%)"),
    .label = c("Number of exacerbations per patient")
  ) \%>\%
  summarize_glm_count(
    vars = "AVAL",
    variables = list(arm = "ARM", offset = "lgTMATRSK", covariates = NULL),
    conf_level = 0.95,
    distribution = "poisson",
    rate_mean_method = "emmeans",
    var_labels = "Unadjusted exacerbation rate (per year)",
    table_names = "unadj",
    .stats = c("rate"),
    .labels = c(rate = "Rate")
  ) \%>\%
  summarize_glm_count(
    vars = "AVAL",
    variables = list(arm = "ARM", offset = "lgTMATRSK", covariates = c("REGION1")),
    conf_level = 0.95,
    distribution = "quasipoisson",
    rate_mean_method = "ppmeans",
    var_labels = "Adjusted (QP) exacerbation rate (per year)",
    table_names = "adj",
    .stats = c("rate", "rate_ci", "rate_ratio", "rate_ratio_ci", "pval"),
    .labels = c(
      rate = "Rate", rate_ci = "Rate CI", rate_ratio = "Rate Ratio",
      rate_ratio_ci = "Rate Ratio CI", pval = "p value"
    )
  )
build_table(lyt = lyt, df = anl)

}
\keyword{internal}
