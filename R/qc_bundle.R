# =========================
# QC core: qc_bundle object
# =========================

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

  # 可选：仅做温和提醒，不做强制转换/修复
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

  # 初始化后明确追加一条日志（append-only）
  bundle <- qc_log_add(bundle, stage = "init", fn = "qc_init", detail = "initialize qc_bundle")
  bundle
}

# -------------------------
# Audit log (append-only)
# -------------------------

#' Initialize QC audit log (internal)
#'
#' @return A data.frame representing an append-only audit log.
#' @keywords internal
qc_log_init <- function() {
  data.frame(
    time = as.POSIXct(character(), tz = "UTC"),  # 用 POSIXct，便于排序/比较
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
    time = as.POSIXct(Sys.time(), tz = "UTC"),
    stage = as.character(stage),
    fn = as.character(fn),
    detail = as.character(detail),
    stringsAsFactors = FALSE
  )
  bundle$log <- rbind(bundle$log, entry)
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

  # 保证有名字
  if (is.null(names(params)) || any(names(params) == "")) {
    nm <- names(params)
    if (is.null(nm)) nm <- rep("", length(params))
    nm[nm == ""] <- paste0("p", which(nm == ""))
    names(params) <- nm
  }

  fmt_one <- function(x) {
    # 绝不把大对象原样写进 log
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

    # 兜底：只写 class
    paste0("<", paste(class(x), collapse = "/"), ">")
  }

  parts <- vapply(names(params), function(nm) {
    paste0(nm, "=", fmt_one(params[[nm]]))
  }, character(1))

  out <- paste(parts, collapse = "; ")
  if (nchar(out) > max_chars) out <- paste0(substr(out, 1, max_chars - 3), "...")
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
  param_txt <- qc_param_summary(params)
  detail <- paste(
    c(param_txt, if (nzchar(note)) paste0("note=", shQuote(note)) else NULL),
    collapse = " | "
  )
  qc_log_add(bundle, stage = stage, fn = fn, detail = detail)
}

# -------------------------
# Stage guardrails (internal)
# -------------------------

#' Check whether a stage is allowed to write specific fields (internal)
#'
#' @param stage Character. One of: "init", "qc_enable", "qc_assess", "qc_decide", "post_validate".
#' @return Normalized stage name.
#' @keywords internal
qc_stage_normalize <- function(stage) {
  stage <- as.character(stage)
  allowed <- c("init", "qc_enable", "qc_assess", "qc_decide", "post_validate")
  if (!stage %in% allowed) stop("Unknown stage: ", stage, call. = FALSE)
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

  # 全局规则：init 之后禁止覆盖 raw
  if ("raw" %in% fields && stage != "init") {
    stop("Write denied: `raw` is read-only after initialization.", call. = FALSE)
  }

  stage_allowed <- list(
    init = c("raw", "meta", "derived", "metrics", "flags", "decision", "reasons", "log"),
    qc_enable = c("derived", "meta", "log"),
    qc_assess = c("metrics", "flags", "log"),
    qc_decide = c("decision", "reasons", "log"),
    post_validate = c("log")  # 未来如需 processing-induced diagnostics 再扩展
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
#' 强制走写权限检查，避免未来误用（尤其是你自己）
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

# -------------------------
# QC-enabling: timestamp diagnostics (no assessment)
# -------------------------

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
  t_class <- class(t)

  # 不改 raw：仅在局部转换用于派生
  if (inherits(t, "POSIXt")) {
    t_num <- as.numeric(t)
  } else if (inherits(t, "Date")) {
    t_num <- as.numeric(t)
  } else if (is.numeric(t) || is.integer(t)) {
    t_num <- as.numeric(t)
  } else {
    t_num <- suppressWarnings(as.numeric(t))
  }

  na_n <- sum(is.na(t_num))
  t_non_na <- t_num[!is.na(t_num)]

  dup_n <- if (length(t_non_na) == 0) NA_integer_ else sum(duplicated(t_non_na))
  is_mono <- if (length(t_non_na) <= 1) NA else all(diff(t_non_na) >= 0)

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

# -------------------------
# Dummy enabling step for testing logs (internal)
# -------------------------

#' Dummy QC enabling step for testing logs (internal)
#'
#' 重要：绝不覆盖整个 derived，只写入 derived$dummy
#'
#' @keywords internal
qc_enable_dummy <- function(bundle, unit = "day", window = 60L) {
  stopifnot(inherits(bundle, "qc_bundle"))

  # 只更新一个模块，避免覆盖 derived$time 等其他模块
  new_derived <- modifyList(
    bundle$derived,
    list(dummy = list(unit = unit, window = window))
  )
  bundle <- qc_set(bundle, "qc_enable", "derived", new_derived)

  bundle <- qc_log_event(
    bundle,
    stage = "qc_enable",
    fn = "qc_enable_dummy",
    params = list(unit = unit, window = window),
    note = "dummy enabling step"
  )

  bundle
}

# -------------------------
# Print / summary methods
# -------------------------

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

  # Meta（优先展示关键字段）
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
  if (is.null(x$decision)) cat("- Decision: <none>\n") else cat("- Decision: <present>\n")

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
#'
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
