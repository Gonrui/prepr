#' Mode-Range Normalization (Original)
#'
#' A robust normalization method designed for longitudinal behavioral data with a "routine plateau".
#'
#' @description
#' Unlike Z-Score or Min-Max, this algorithm identifies the "Mode Range" (the most frequent value range)
#' and maps it to 0. This effectively suppresses the noise of daily routine (e.g., stable step counts)
#' and amplifies anomalies (e.g., frailty or sudden activity).
#'
#' It maps:
#' \itemize{
#'   \item \strong{Mode Range}: \eqn{[k_L, k_R] \to 0} (Baseline/Routine)
#'   \item \strong{Left Tail}: \eqn{[min, k_L) \to [-1, 0)} (Decline/Frailty)
#'   \item \strong{Right Tail}: \eqn{(k_R, max] \to (0, 1]} (Surge/Hyperactivity)
#' }
#'
#' @param x A numeric vector. Best suited for integer/discrete data (e.g., daily steps, heart rate bins).
#' @param tau A numeric value (0 to 1). The threshold ratio for defining the mode plateau.
#'   Bins with \code{freq >= tau * max_freq} are considered part of the routine. Default is 0.8.
#'
#' @return A numeric vector in the range [-1, 1].
#'
#' @references
#' Gong, R. (2026). A Mode-Centric Normalization Method for Detecting Health Anomalies in Longitudinal Geriatric Data.
#' \emph{arXiv preprint}. (Submitted)
#'
#' @export
#'
#' @examples
#' # Scenario: An older adult's daily step counts over 10 days
#' # Day 1-7: Routine (~3000 steps). Day 8: Fall (200 steps). Day 9-10: Recovery.
#' steps <- c(3000, 3100, 3000, 2900, 3050, 3000, 3100, 200, 1500, 3000)
#'
#' # Apply Mode-Range Normalization
#' # Routine days become 0. The fall becomes -1.
#' norm_mode_range(steps, tau = 0.8)
norm_mode_range <- function(x, tau = 0.8) {
  # 1. Input Validation
  if (!is.numeric(x)) stop("Input 'x' must be a numeric vector.")

  # 2. Edge Case: Flat data (No variation)
  rng <- range(x, na.rm = TRUE)
  if (rng[1] == rng[2]) return(rep(0, length(x)))

  # 3. Identify Mode Range (The "Routine Plateau")
  # table() is robust for integer-like behavioral data
  tab <- table(x)
  f_max <- max(tab)

  # Select values that appear frequently enough (>= tau * max_freq)
  mode_vals <- as.numeric(names(tab)[tab >= tau * f_max])

  # Defensive fallback: if tau > 1 or logic fails, pick the single absolute mode
  if (length(mode_vals) == 0) {
    mode_vals <- as.numeric(names(tab)[which.max(tab)])
  }

  k_L <- min(mode_vals)
  k_R <- max(mode_vals)
  k_min <- rng[1]
  k_max <- rng[2]

  # 4. Define Ranges (with epsilon protection)
  eps <- .Machine$double.eps
  L_range <- max(k_L - k_min, eps)
  R_range <- max(k_max - k_R, eps)

  # 5. Apply Transformation
  res <- numeric(length(x))

  # Left Tail (Decline)
  idx_left <- x < k_L
  if (any(idx_left)) {
    res[idx_left] <- - (k_L - x[idx_left]) / L_range
  }

  # Right Tail (Surge)
  idx_right <- x > k_R
  if (any(idx_right)) {
    res[idx_right] <- (x[idx_right] - k_R) / R_range
  }

  # Mode Range is implicitly 0 (initialized)

  return(res)
}
