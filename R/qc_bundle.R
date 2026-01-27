#' Initialize a QC bundle
#'
#' Create a `qc_bundle` object that carries raw data and QC metadata containers.
#' This function performs no QC and does not modify the raw data.
#'
#' @param data Raw data (data.frame / tibble / other).
#' @param meta A list of metadata describing `data`.
#' @param validate Logical. If TRUE, warn when `data` is not data.frame-like.
#' @return An object of class `qc_bundle`.
#' @export
qc_init <- function(data, meta = list(), validate = FALSE) {
  if (missing(data)) stop("`data` must be provided.", call. = FALSE)
  if (!is.list(meta)) stop("`meta` must be a list.", call. = FALSE)

  if (validate && !is.data.frame(data)) {
    warning(
      "`data` is not a data.frame-like object. QC functions may expect named columns.",
      call. = FALSE
    )
  }

  bundle <- list(
    raw = data,
    meta = meta,
    derived = list(),
    metrics = list(),
    flags = list(),
    decision = NULL,
    reasons = character(),
    log = qc_log_init()
  )
  class(bundle) <- c("qc_bundle", "list")

  bundle <- qc_log_add(bundle, stage = "init", fn = "qc_init", detail = "initialize qc_bundle")
  bundle
}


#' Initialize QC audit log (internal)
#'
#' @return A data.frame representing an append-only audit log.
#' @keywords internal
qc_log_init <- function() {
  data.frame(
    time = character(),
    stage = character(),
    fn = character(),
    detail = character(),
    stringsAsFactors = FALSE
  )
}


#' Append a QC log entry (internal)
#'
#' @param bundle qc_bundle
#' @param stage Stage name (e.g., "qc_enable", "qc_assess", "qc_decide").
#' @param fn Function name that produced the entry.
#' @param detail Free-form detail string (e.g., parameter summary).
#' @return Updated qc_bundle
#' @keywords internal
qc_log_add <- function(bundle, stage, fn, detail = "") {
  stopifnot(inherits(bundle, "qc_bundle"))
  entry <- data.frame(
    time = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    stage = as.character(stage),
    fn = as.character(fn),
    detail = as.character(detail),
    stringsAsFactors = FALSE
  )
  bundle$log <- rbind(bundle$log, entry)
  bundle
}


# ---- Stage guardrails (internal) ----

#' Check whether a stage is allowed to write specific fields (internal)
#'
#' @param stage Character. One of: "init", "qc_enable", "qc_assess", "qc_decide", "post_validate".
#' @return Normalized stage name.
#' @keywords internal
qc_stage_normalize <- function(stage) {
  stage <- as.character(stage)
  allowed <- c("init", "qc_enable", "qc_assess", "qc_decide", "post_validate")
  if (!stage %in% allowed) {
    stop("Unknown stage: ", stage, call. = FALSE)
  }
  stage
}

#' Assert write permission for qc_bundle fields (internal)
#'
#' @param bundle qc_bundle
#' @param stage stage name
#' @param fields character vector of field names that are about to be written
#' @keywords internal
qc_stage_assert_write <- function(bundle, stage, fields) {
  stopifnot(inherits(bundle, "qc_bundle"))
  stage <- qc_stage_normalize(stage)
  fields <- as.character(fields)

  # Global rule: never overwrite raw after init
  if ("raw" %in% fields && stage != "init") {
    stop("Write denied: `raw` is read-only after initialization.", call. = FALSE)
  }

  # Field-level permissions by stage
  stage_allowed <- list(
    init = c("raw", "meta", "derived", "metrics", "flags", "decision", "reasons", "log"),
    qc_enable = c("derived", "meta", "log"),
    qc_assess = c("metrics", "flags", "log"),
    qc_decide = c("decision", "reasons", "log"),
    post_validate = c("log") # can extend later for processing-induced diagnostics
  )

  allowed_fields <- stage_allowed[[stage]]
  denied <- setdiff(fields, allowed_fields)
  if (length(denied) > 0) {
    stop(
      "Write denied for stage `", stage, "`: ",
      paste0("`", denied, "`", collapse = ", "),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

#' Safe setter for qc_bundle fields (internal)
#'
#' @param bundle qc_bundle
#' @param stage stage name
#' @param field single field name
#' @param value value to assign
#' @return updated qc_bundle
#' @keywords internal
qc_set <- function(bundle, stage, field, value) {
  field <- as.character(field)
  qc_stage_assert_write(bundle, stage, field)
  bundle[[field]] <- value
  bundle
}

#' Summarize parameters into a short string (internal)
#'
#' Avoid printing large objects into logs. Only keep lightweight summaries.
#'
#' @param params A named list of parameters.
#' @param max_chars Maximum characters in the output string.
#' @return A single character string.
#' @keywords internal
qc_param_summary <- function(params, max_chars = 200) {
  if (is.null(params)) return("")
  if (!is.list(params)) params <- list(value = params)

  # Ensure names exist
  if (is.null(names(params)) || any(names(params) == "")) {
    names(params) <- ifelse(is.null(names(params)) | names(params) == "",
                            paste0("p", seq_along(params)),
                            names(params))
  }

  fmt_one <- function(x) {
    # Never dump raw data / big objects
    if (is.data.frame(x)) return("<data.frame>")
    if (is.matrix(x)) return("<matrix>")
    if (is.list(x) && length(x) > 10) return(paste0("<list:", length(x), ">"))

    if (is.character(x)) {
      if (length(x) == 0) return('""')
      if (length(x) == 1) return(shQuote(substr(x, 1, 50)))
      return(paste0("c(", length(x), ")"))
    }
    if (is.numeric(x) || is.integer(x)) {
      if (length(x) == 0) return("numeric(0)")
      if (length(x) == 1) return(format(x))
      return(paste0("c(", length(x), ")"))
    }
    if (is.logical(x)) {
      if (length(x) == 1) return(ifelse(isTRUE(x), "TRUE", "FALSE"))
      return(paste0("c(", length(x), ")"))
    }

    # fallback: class label only
    paste0("<", paste(class(x), collapse = "/"), ">")
  }

  parts <- vapply(names(params), function(nm) {
    paste0(nm, "=", fmt_one(params[[nm]]))
  }, character(1))

  out <- paste(parts, collapse = "; ")
  if (nchar(out) > max_chars) {
    out <- paste0(substr(out, 1, max_chars - 3), "...")
  }
  out
}

#' Log a standardized QC event (internal)
#'
#' @param bundle qc_bundle
#' @param stage Stage name
#' @param fn Function name
#' @param params Named list of parameters to summarize
#' @param note Optional note string
#' @return Updated qc_bundle
#' @keywords internal
qc_log_event <- function(bundle, stage, fn, params = list(), note = "") {
  stopifnot(inherits(bundle, "qc_bundle"))
  stage <- as.character(stage)
  fn <- as.character(fn)

  param_txt <- qc_param_summary(params)
  detail <- paste(
    c(param_txt, if (nzchar(note)) paste0("note=", shQuote(note)) else NULL),
    collapse = " | "
  )

  qc_log_add(bundle, stage = stage, fn = fn, detail = detail)
}

#' Dummy QC enabling step for testing logs (internal)
#' @keywords internal
qc_enable_dummy <- function(bundle, unit = "day", window = 60L) {
  stopifnot(inherits(bundle, "qc_bundle"))

  # 允许写 derived（Day3 guardrails）
  bundle <- qc_set(bundle, "qc_enable", "derived", list(unit = unit, window = window))

  # 记录日志（Day4）
  bundle <- qc_log_event(
    bundle,
    stage = "qc_enable",
    fn = "qc_enable_dummy",
    params = list(unit = unit, window = window),
    note = "dummy enabling step"
  )

  bundle
}

#' Print method for qc_bundle
#'
#' @param x qc_bundle
#' @param ... ignored
#' @export
print.qc_bundle <- function(x, ...) {
  stopifnot(inherits(x, "qc_bundle"))

  cat("<qc_bundle>\n")

  # Raw
  raw <- x$raw
  raw_cls <- paste(class(raw), collapse = "/")
  if (is.data.frame(raw)) {
    cat(sprintf("- Raw: %s [%d x %d]\n", raw_cls, nrow(raw), ncol(raw)))
  } else {
    cat(sprintf("- Raw: %s\n", raw_cls))
  }

  # Meta (show a few key fields if present)
  meta <- x$meta
  if (is.list(meta) && length(meta) > 0) {
    keys <- intersect(c("id", "tz", "fs_expected", "channels"), names(meta))
    if (length(keys) > 0) {
      meta_txt <- paste(vapply(keys, function(k) {
        val <- meta[[k]]
        if (length(val) == 0) return(paste0(k, "=<empty>"))
        if (is.character(val) && length(val) == 1) return(paste0(k, "=", val))
        if (is.numeric(val) && length(val) == 1) return(paste0(k, "=", format(val)))
        paste0(k, "=<", paste(class(val), collapse = "/"), ">")
      }, character(1)), collapse = ", ")
      cat(sprintf("- Meta: %s\n", meta_txt))
    } else {
      cat(sprintf("- Meta: %d fields\n", length(meta)))
    }
  } else {
    cat("- Meta: <empty>\n")
  }

  # Derived / metrics / flags
  n_derived <- if (is.list(x$derived)) length(x$derived) else 0
  n_metrics <- if (is.list(x$metrics)) length(x$metrics) else 0
  n_flags <- if (is.list(x$flags)) length(x$flags) else 0

  cat(sprintf("- Derived: %d module(s)\n", n_derived))
  cat(sprintf("- Metrics: %d module(s)\n", n_metrics))
  cat(sprintf("- Flags: %d module(s)\n", n_flags))

  # Decision
  if (is.null(x$decision)) {
    cat("- Decision: <none>\n")
  } else {
    cat("- Decision: <present>\n")
  }

  # Log
  n_log <- if (is.data.frame(x$log)) nrow(x$log) else 0
  cat(sprintf("- Log: %d entr%s\n", n_log, ifelse(n_log == 1, "y", "ies")))

  invisible(x)
}

#' Summary method for qc_bundle
#'
#' @param object qc_bundle
#' @param ... ignored
#' @export
summary.qc_bundle <- function(object, ...) {
  stopifnot(inherits(object, "qc_bundle"))

  raw <- object$raw
  out <- list(
    raw_class = class(raw),
    raw_dim = if (is.data.frame(raw)) c(nrow(raw), ncol(raw)) else NULL,
    meta_n = if (is.list(object$meta)) length(object$meta) else 0,
    derived_n = if (is.list(object$derived)) length(object$derived) else 0,
    metrics_n = if (is.list(object$metrics)) length(object$metrics) else 0,
    flags_n = if (is.list(object$flags)) length(object$flags) else 0,
    decision_present = !is.null(object$decision),
    reasons_n = length(object$reasons),
    log_n = if (is.data.frame(object$log)) nrow(object$log) else 0
  )
  class(out) <- "summary.qc_bundle"
  out
}

#' Print method for summary.qc_bundle
#' @param x summary.qc_bundle
#' @param ... ignored
#' @export
print.summary.qc_bundle <- function(x, ...) {
  cat("<summary.qc_bundle>\n")
  cat(sprintf("- Raw: %s\n", paste(x$raw_class, collapse = "/")))
  if (!is.null(x$raw_dim)) {
    cat(sprintf("- Raw dim: [%d x %d]\n", x$raw_dim[1], x$raw_dim[2]))
  }
  cat(sprintf("- Meta fields: %d\n", x$meta_n))
  cat(sprintf("- Derived modules: %d\n", x$derived_n))
  cat(sprintf("- Metrics modules: %d\n", x$metrics_n))
  cat(sprintf("- Flags modules: %d\n", x$flags_n))
  cat(sprintf("- Decision present: %s\n", ifelse(isTRUE(x$decision_present), "TRUE", "FALSE")))
  cat(sprintf("- Reasons: %d\n", x$reasons_n))
  cat(sprintf("- Log entries: %d\n", x$log_n))
  invisible(x)
}

