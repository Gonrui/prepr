#' Box-Cox Transformation
#'
#' Applies the Box-Cox transformation to normalize the data distribution.
#' It automatically handles non-positive values by shifting the data.
#' The optimal lambda parameter is estimated using Maximum Likelihood Estimation (MLE).
#'
#' Formula:
#' \eqn{y(\lambda) = \frac{x^\lambda - 1}{\lambda}} if \eqn{\lambda \neq 0};
#' \eqn{\ln(x)} if \eqn{\lambda = 0}.
#'
#' @param x A numeric vector.
#' @param lambda A numeric value for the transformation power.
#'   If \code{"auto"} (default), the optimal lambda is estimated within the interval [-2, 2].
#' @param force_pos Logical. If \code{TRUE} (default), automatically shifts data to be positive
#'   if non-positive values are present.
#'
#' @return A numeric vector with the transformed values.
#'   The used \code{lambda} and \code{shift} amount are attached as attributes:
#'   \code{attr(res, "lambda")} and \code{attr(res, "shift")}.
#'
#' @references
#' Box, G. E. P., & Cox, D. R. (1964). An analysis of transformations.
#' \emph{Journal of the Royal Statistical Society: Series B (Methodological)}, 26(2), 211-243.
#'
#' @importFrom stats optimize var
#' @export
#'
#' @examples
#' # 1. Create skewed data (Chi-square distribution)
#' x <- rchisq(100, df = 2)
#'
#' # 2. Apply Box-Cox
#' x_trans <- trans_boxcox(x)
#'
#' # 3. Check parameters
#' attr(x_trans, "lambda")
#'
#' # 4. Works with negative values (Auto-shift)
#' x_neg <- x - 10
#' trans_boxcox(x_neg)
trans_boxcox <- function(x, lambda = "auto", force_pos = TRUE) {
  # 1. Input Validation
  if (!is.numeric(x)) {
    stop("Input 'x' must be a numeric vector.")
  }

  # 2. Handle Non-Positive Values (Auto-Shift)
  shift <- 0
  min_val <- min(x, na.rm = TRUE)

  if (min_val <= 0) {
    if (force_pos) {
      # Shift to make all values > 0. We add a small constant (e.g., 1 or abs(min) + 1)
      # Standard practice: x - min(x) + 1 (so the smallest value becomes 1)
      shift <- abs(min_val) + 1
      x <- x + shift
      # We don't warn here because it's an expected feature, but documenting it is important.
    } else {
      stop("Box-Cox requires positive values. Set 'force_pos = TRUE' or handle negative values manually.")
    }
  }

  # 3. Define Log-Likelihood Function for Optimization
  # This function calculates how "likely" a given lambda is correct
  log_likelihood <- function(lam, x_data) {
    # Remove NAs for calculation
    x_clean <- x_data[!is.na(x_data)]
    n <- length(x_clean)

    if (abs(lam) < 1e-5) {
      x_trans <- log(x_clean)
    } else {
      x_trans <- (x_clean^lam - 1) / lam
    }

    # Variance of transformed data
    var_trans <- stats::var(x_trans) * (n - 1) / n

    # Log-likelihood (ignoring constants)
    # sum(log(x)) is the Jacobian term
    ll <- - (n / 2) * log(var_trans) + (lam - 1) * sum(log(x_clean))
    return(ll)
  }

  # 4. Find Optimal Lambda (if auto)
  if (identical(lambda, "auto")) {
    # We search for lambda in range [-2, 2] which covers most practical cases
    # We use maximum = TRUE because we want to MAXIMIZE likelihood
    opt_res <- stats::optimize(log_likelihood, c(-2, 2), x_data = x, maximum = TRUE)
    best_lambda <- opt_res$maximum
  } else {
    if (!is.numeric(lambda) || length(lambda) != 1) {
      stop("'lambda' must be 'auto' or a single numeric value.")
    }
    best_lambda <- lambda
  }

  # 5. Apply Transformation
  if (abs(best_lambda) < 1e-5) {
    res <- log(x)
  } else {
    res <- (x^best_lambda - 1) / best_lambda
  }

  # 6. Attach Attributes
  attr(res, "lambda") <- best_lambda
  attr(res, "shift")  <- shift

  return(res)
}
