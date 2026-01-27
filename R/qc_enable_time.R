#' QC-enabling: derive timestamp diagnostics (no assessment)
#'
#' This function does NOT judge quality and does NOT write metrics/flags/decision.
#' It only derives timestamp diagnostics to make QC assessment possible.
#'
#' @param bundle qc_bundle
#' @param time_col Name of timestamp column in `bundle$raw`.
#' @param unit Granularity label (e.g., "session", "day"). Stored in derived for downstream assessment.
#' @return Updated qc_bundle
#' @export
qc_enable_time <- function(bundle, time_col = "time", unit = "session") {
  stopifnot(inherits(bundle, "qc_bundle"))

  raw <- bundle$raw
  if (!is.data.frame(raw)) {
    stop("`bundle$raw` must be a data.frame-like object for qc_enable_time().", call. = FALSE)
  }

  has_col <- time_col %in% names(raw)
  if (!has_col) {
    # derive only a minimal record; no flags here
    time_derived <- list(
      time_col = time_col,
      unit = unit,
      exists = FALSE
    )
    bundle <- qc_set(bundle, "qc_enable", "derived",
                     modifyList(bundle$derived, list(time = time_derived)))
    bundle <- qc_log_event(bundle, "qc_enable", "qc_enable_time",
                           params = list(time_col = time_col, unit = unit),
                           note = "time column not found; derived recorded")
    return(bundle)
  }

  t <- raw[[time_col]]

  # Convert to numeric where possible without altering raw:
  # - POSIXct -> numeric seconds
  # - Date -> numeric days
  # - numeric stays numeric
  t_num <- NULL
  t_class <- class(t)

  if (inherits(t, "POSIXt")) {
    t_num <- as.numeric(t)
  } else if (inherits(t, "Date")) {
    t_num <- as.numeric(t)
  } else if (is.numeric(t) || is.integer(t)) {
    t_num <- as.numeric(t)
  } else {
    # attempt coercion; if fails, keep NA
    t_num <- suppressWarnings(as.numeric(t))
  }

  na_n <- sum(is.na(t_num))
  dup_n <- if (all(is.na(t_num))) NA_integer_ else sum(duplicated(t_num), na.rm = TRUE)

  # monotonicity: ignore NAs for check
  t_non_na <- t_num[!is.na(t_num)]
  is_mono <- if (length(t_non_na) <= 1) NA else all(diff(t_non_na) >= 0)

  # dt summary (only if enough points)
  dt <- if (length(t_non_na) <= 1) numeric(0) else diff(t_non_na)
  dt_summary <- if (length(dt) == 0) {
    list(n = 0L, min = NA_real_, median = NA_real_, max = NA_real_)
  } else {
    list(
      n = length(dt),
      min = min(dt),
      median = stats::median(dt),
      max = max(dt)
    )
  }

  time_derived <- list(
    time_col = time_col,
    unit = unit,
    exists = TRUE,
    time_class = t_class,
    n = length(t_num),
    na_n = na_n,
    dup_n = dup_n,
    monotonic_non_na = is_mono,
    dt_summary = dt_summary
  )

  bundle <- qc_set(bundle, "qc_enable", "derived",
                   modifyList(bundle$derived, list(time = time_derived)))

  bundle <- qc_log_event(
    bundle,
    stage = "qc_enable",
    fn = "qc_enable_time",
    params = list(time_col = time_col, unit = unit, n = length(t_num), na_n = na_n, dup_n = dup_n),
    note = "derived timestamp diagnostics"
  )

  bundle
}
# Placeholder for qc_enable_time
