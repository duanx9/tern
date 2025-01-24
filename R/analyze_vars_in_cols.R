#' Summary numeric variables in columns
#'
#' @description `r lifecycle::badge("experimental")`
#'
#' Layout-creating function which can be used for creating column-wise summary tables.
#' This function sets the analysis methods as column labels and is a wrapper for
#' [rtables::analyze_colvars()]. It was designed principally for PK tables.
#'
#' @inheritParams argument_convention
#' @inheritParams rtables::analyze_colvars
#' @param row_labels (`character`)\cr as this function works in columns space, usual `.labels`
#'   character vector applies on the column space. You can change the row labels by defining this
#'   parameter to a named character vector with names corresponding to the split values. It defaults
#'   to `NULL` and if it contains only one `string`, it will duplicate that as a row label.
#' @param do_summarize_row_groups (`flag`)\cr defaults to `FALSE` and applies the analysis to the current
#'   label rows. This is a wrapper of [rtables::summarize_row_groups()] and it can accept `labelstr`
#'   to define row labels. This behavior is not supported as we never need to overload row labels.
#' @param split_col_vars (`flag`)\cr defaults to `TRUE` and puts the analysis results onto the columns.
#'   This option allows you to add multiple instances of this functions, also in a nested fashion,
#'   without adding more splits. This split must happen only one time on a single layout.
#'
#' @return
#' A layout object suitable for passing to further layouting functions, or to [rtables::build_table()].
#' Adding this function to an `rtable` layout will summarize the given variables, arrange the output
#' in columns, and add it to the table layout.
#'
#' @note This is an experimental implementation of [rtables::summarize_row_groups()] and
#'   [rtables::analyze_colvars()] that may be subjected to changes as `rtables` extends its
#'   support to more complex analysis pipelines on the column space. For the same reasons,
#'   we encourage to read the examples carefully and file issues for cases that differ from
#'   them.
#'
#'   Here `labelstr` behaves differently than usual. If it is not defined (default as `NULL`),
#'   row labels are assigned automatically to the split values in case of `rtables::analyze_colvars`
#'   (`do_summarize_row_groups = FALSE`, the default), and to the group label for
#'   `do_summarize_row_groups = TRUE`.
#'
#' @seealso [analyze_vars()], [rtables::analyze_colvars()].
#'
#' @examples
#' library(dplyr)
#'
#' # Data preparation
#' adpp <- tern_ex_adpp %>% h_pkparam_sort()
#'
#' lyt <- basic_table() %>%
#'   split_rows_by(var = "STRATA1", label_pos = "topleft") %>%
#'   split_rows_by(
#'     var = "SEX",
#'     label_pos = "topleft",
#'     child_label = "hidden"
#'   ) %>% # Removes duplicated labels
#'   analyze_vars_in_cols(vars = "AGE")
#' result <- build_table(lyt = lyt, df = adpp)
#' result
#'
#' # By selecting just some statistics and ad-hoc labels
#' lyt <- basic_table() %>%
#'   split_rows_by(var = "ARM", label_pos = "topleft") %>%
#'   split_rows_by(
#'     var = "SEX",
#'     label_pos = "topleft",
#'     child_labels = "hidden",
#'     split_fun = drop_split_levels
#'   ) %>%
#'   analyze_vars_in_cols(
#'     vars = "AGE",
#'     .stats = c("n", "cv", "geom_mean"),
#'     .labels = c(
#'       n = "aN",
#'       cv = "aCV",
#'       geom_mean = "aGeomMean"
#'     )
#'   )
#' result <- build_table(lyt = lyt, df = adpp)
#' result
#'
#' # Changing row labels
#' lyt <- basic_table() %>%
#'   analyze_vars_in_cols(
#'     vars = "AGE",
#'     row_labels = "some custom label"
#'   )
#' result <- build_table(lyt, df = adpp)
#' result
#'
#' # Pharmacokinetic parameters
#' lyt <- basic_table() %>%
#'   split_rows_by(
#'     var = "TLG_DISPLAY",
#'     split_label = "PK Parameter",
#'     label_pos = "topleft",
#'     child_label = "hidden"
#'   ) %>%
#'   analyze_vars_in_cols(
#'     vars = "AVAL"
#'   )
#' result <- build_table(lyt, df = adpp)
#' result
#'
#' # Multiple calls (summarize label and analyze underneath)
#' lyt <- basic_table() %>%
#'   split_rows_by(
#'     var = "TLG_DISPLAY",
#'     split_label = "PK Parameter",
#'     label_pos = "topleft"
#'   ) %>%
#'   analyze_vars_in_cols(
#'     vars = "AVAL",
#'     do_summarize_row_groups = TRUE # does a summarize level
#'   ) %>%
#'   split_rows_by("SEX",
#'     child_label = "hidden",
#'     label_pos = "topleft"
#'   ) %>%
#'   analyze_vars_in_cols(
#'     vars = "AVAL",
#'     split_col_vars = FALSE # avoids re-splitting the columns
#'   )
#' result <- build_table(lyt, df = adpp)
#' result
#'
#' @export
analyze_vars_in_cols <- function(lyt,
                                 vars,
                                 ...,
                                 .stats = c(
                                   "n",
                                   "mean",
                                   "sd",
                                   "se",
                                   "cv",
                                   "geom_cv"
                                 ),
                                 .labels = c(
                                   n = "n",
                                   mean = "Mean",
                                   sd = "SD",
                                   se = "SE",
                                   cv = "CV (%)",
                                   geom_cv = "CV % Geometric Mean"
                                 ),
                                 row_labels = NULL,
                                 do_summarize_row_groups = FALSE,
                                 split_col_vars = TRUE,
                                 .indent_mods = NULL,
                                 nested = TRUE,
                                 na_level = NULL,
                                 .formats = NULL) {
  checkmate::assert_string(na_level, null.ok = TRUE)
  checkmate::assert_character(row_labels, null.ok = TRUE)
  checkmate::assert_int(.indent_mods, null.ok = TRUE)
  checkmate::assert_flag(nested)
  checkmate::assert_flag(split_col_vars)
  checkmate::assert_flag(do_summarize_row_groups)

  # Automatic assignment of formats
  if (is.null(.formats)) {
    # General values
    sf_numeric <- summary_formats("numeric")
    sf_counts <- summary_formats("counts")[-1]
    formats_v <- c(sf_numeric, sf_counts)
  } else {
    formats_v <- .formats
  }

  # Check for vars in the case that one or more are used
  if (length(vars) == 1) {
    vars <- rep(vars, length(.stats))
  } else if (length(vars) != length(.stats)) {
    stop(
      "Analyzed variables (vars) does not have the same ",
      "number of elements of specified statistics (.stats)."
    )
  }

  if (split_col_vars) {
    # Checking there is not a previous identical column split
    clyt <- tail(clayout(lyt), 1)[[1]]

    dummy_lyt <- split_cols_by_multivar(
      lyt = basic_table(),
      vars = vars,
      varlabels = .labels[.stats]
    )

    if (any(sapply(clyt, identical, y = get_last_col_split(dummy_lyt)))) {
      stop(
        "Column split called again with the same values. ",
        "This can create many unwanted columns. Please consider adding ",
        "split_col_vars = FALSE to the last call of ",
        deparse(sys.calls()[[sys.nframe() - 1]]), "."
      )
    }

    # Main col split
    lyt <- split_cols_by_multivar(
      lyt = lyt,
      vars = vars,
      varlabels = .labels[.stats]
    )
  }

  if (do_summarize_row_groups) {
    if (length(unique(vars)) > 1) {
      stop("When using do_summarize_row_groups only one label level var should be inserted.")
    }

    # Function list for do_summarize_row_groups. Slightly different handling of labels
    cfun_list <- Map(
      function(stat) {
        function(u, .spl_context, labelstr, ...) {
          # Statistic
          res <- s_summary(u, ...)[[stat]]

          # Label check and replacement
          if (length(row_labels) > 1) {
            if (!(labelstr %in% names(row_labels))) {
              stop(
                "Replacing the labels in do_summarize_row_groups needs a named vector",
                "that contains the split values. In the current split variable ",
                .spl_context$split[nrow(.spl_context)],
                " the labelstr value (split value by default) ", labelstr, " is not in",
                " row_labels names: ", names(row_labels)
              )
            }
            lbl <- unlist(row_labels[labelstr])
          } else {
            lbl <- labelstr
          }

          # Cell creation
          rcell(res,
            label = lbl,
            format = formats_v[names(formats_v) == stat][[1]],
            format_na_str = na_level,
            indent_mod = ifelse(is.null(.indent_mods), 0L, .indent_mods)
          )
        }
      },
      stat = .stats
    )

    # Main call to rtables
    summarize_row_groups(
      lyt = lyt,
      var = unique(vars),
      cfun = cfun_list,
      extra_args = list(...)
    )
  } else {
    # Function list for analyze_colvars
    afun_list <- Map(
      function(stat) {
        function(u, .spl_context, ...) {
          # Main statistics
          res <- s_summary(u, ...)[[stat]]

          # Label from context
          label_from_context <- .spl_context$value[nrow(.spl_context)]

          # Label switcher
          if (is.null(row_labels)) {
            lbl <- label_from_context
          } else {
            if (length(row_labels) > 1) {
              if (!(label_from_context %in% names(row_labels))) {
                stop(
                  "Replacing the labels in do_summarize_row_groups needs a named vector",
                  "that contains the split values. In the current split variable ",
                  .spl_context$split[nrow(.spl_context)],
                  " the split value ", label_from_context, " is not in",
                  " row_labels names: ", names(row_labels)
                )
              }
              lbl <- unlist(row_labels[label_from_context])
            } else {
              lbl <- row_labels
            }
          }

          # Cell creation
          rcell(res,
            label = lbl,
            format = formats_v[names(formats_v) == stat][[1]],
            format_na_str = na_level,
            indent_mod = ifelse(is.null(.indent_mods), 0L, .indent_mods)
          )
        }
      },
      stat = .stats
    )

    # Main call to rtables
    analyze_colvars(lyt,
      afun = afun_list,
      nested = nested,
      extra_args = list(...)
    )
  }
}

# Help function
get_last_col_split <- function(lyt) {
  tail(tail(clayout(lyt), 1)[[1]], 1)[[1]]
}
