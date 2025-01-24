#' Survival Time Analysis
#'
#' @description `r lifecycle::badge("stable")`
#'
#' Summarize median survival time and CIs, percentiles of survival times, survival
#' time range of censored/event patients.
#'
#' @inheritParams argument_convention
#' @param control (`list`)\cr parameters for comparison details, specified by using the helper function
#'   [control_surv_time()]. Some possible parameter options are:
#'   * `conf_level` (`proportion`)\cr confidence level of the interval for survival time.
#'   * `conf_type` (`string`)\cr confidence interval type. Options are "plain" (default), "log", or "log-log",
#'     see more in [survival::survfit()]. Note option "none" is not supported.
#'   * `quantiles` (`numeric`)\cr vector of length two to specify the quantiles of survival time.
#'
#' @name survival_time
NULL

#' @describeIn survival_time Statistics function which analyzes survival times.
#'
#' @return
#' * `s_surv_time()` returns the statistics:
#'   * `median`: Median survival time.
#'   * `median_ci`: Confidence interval for median time.
#'   * `quantiles`: Survival time for two specified quantiles.
#'   * `range_censor`: Survival time range for censored observations.
#'   * `range_event`: Survival time range for observations with events.
#'   * `range`: Survival time range for all observations.
#'
#' @examples
#' library(dplyr)
#'
#' adtte_f <- tern_ex_adtte %>%
#'   filter(PARAMCD == "OS") %>%
#'   mutate(
#'     AVAL = day2month(AVAL),
#'     is_event = CNSR == 0
#'   )
#' df <- adtte_f %>% filter(ARMCD == "ARM A")
#'
#' @keywords internal
s_surv_time <- function(df,
                        .var,
                        is_event,
                        control = control_surv_time()) {
  checkmate::assert_string(.var)
  assert_df_with_variables(df, list(tte = .var, is_event = is_event))
  checkmate::assert_numeric(df[[.var]], min.len = 1, any.missing = FALSE)
  checkmate::assert_logical(df[[is_event]], min.len = 1, any.missing = FALSE)

  conf_type <- control$conf_type
  conf_level <- control$conf_level
  quantiles <- control$quantiles

  formula <- stats::as.formula(paste0("survival::Surv(", .var, ", ", is_event, ") ~ 1"))
  srv_fit <- survival::survfit(
    formula = formula,
    data = df,
    conf.int = conf_level,
    conf.type = conf_type
  )
  srv_tab <- summary(srv_fit, extend = TRUE)$table
  srv_qt_tab <- stats::quantile(srv_fit, probs = quantiles)$quantile
  range_censor <- range_noinf(df[[.var]][!df[[is_event]]], na.rm = TRUE)
  range_event <- range_noinf(df[[.var]][df[[is_event]]], na.rm = TRUE)
  range <- range_noinf(df[[.var]], na.rm = TRUE)
  list(
    median = formatters::with_label(unname(srv_tab["median"]), "Median"),
    median_ci = formatters::with_label(
      unname(srv_tab[paste0(srv_fit$conf.int, c("LCL", "UCL"))]), f_conf_level(conf_level)
    ),
    quantiles = formatters::with_label(
      unname(srv_qt_tab), paste0(quantiles[1] * 100, "% and ", quantiles[2] * 100, "%-ile")
    ),
    range_censor = formatters::with_label(range_censor, "Range (censored)"),
    range_event = formatters::with_label(range_event, "Range (event)"),
    range = formatters::with_label(range, "Range")
  )
}

#' @describeIn survival_time Formatted analysis function which is used as `afun` in `surv_time()`.
#'
#' @return
#' * `a_surv_time()` returns the corresponding list with formatted [rtables::CellValue()].
#'
#' @keywords internal
a_surv_time <- make_afun(
  s_surv_time,
  .formats = c(
    "median" = "xx.x",
    "median_ci" = "(xx.x, xx.x)",
    "quantiles" = "xx.x, xx.x",
    "range_censor" = "xx.x to xx.x",
    "range_event" = "xx.x to xx.x",
    "range" = "xx.x to xx.x"
  )
)

#' @describeIn survival_time Layout-creating function which can take statistics function arguments
#'   and additional format arguments. This function is a wrapper for [rtables::analyze()].
#'
#' @param .indent_mods (named `vector` of `integer`)\cr indent modifiers for the labels. Each element of the vector
#'   should be a name-value pair with name corresponding to a statistic specified in `.stats` and value the indentation
#'   for that statistic's row label.
#'
#' @return
#' * `surv_time()` returns a layout object suitable for passing to further layouting functions,
#'   or to [rtables::build_table()]. Adding this function to an `rtable` layout will add formatted rows containing
#'   the statistics from `s_surv_time()` to the table layout.
#'
#' @examples
#' basic_table() %>%
#'   split_cols_by(var = "ARMCD") %>%
#'   add_colcounts() %>%
#'   surv_time(
#'     vars = "AVAL",
#'     var_labels = "Survival Time (Months)",
#'     is_event = "is_event",
#'     control = control_surv_time(conf_level = 0.9, conf_type = "log-log")
#'   ) %>%
#'   build_table(df = adtte_f)
#'
#' @export
surv_time <- function(lyt,
                      vars,
                      ...,
                      var_labels = "Time to Event",
                      table_names = vars,
                      .stats = c("median", "median_ci", "quantiles", "range_censor", "range_event"),
                      .formats = NULL,
                      .labels = NULL,
                      .indent_mods = c(
                        "median" = 0L, "median_ci" = 1L, "quantiles" = 0L,
                        "range_censor" = 0L, "range_event" = 0L, "range" = 0L
                      )) {
  afun <- make_afun(
    a_surv_time,
    .stats = .stats,
    .formats = .formats,
    .labels = .labels,
    .indent_mods = extract_by_name(.indent_mods, .stats)
  )
  analyze(
    lyt,
    vars,
    var_labels = var_labels,
    show_labels = "visible",
    table_names = table_names,
    afun = afun,
    extra_args = list(...)
  )
}
