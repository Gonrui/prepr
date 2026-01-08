#' Yeo-Johnson Transformation
#'
#' A power transformation similar to Box-Cox but supports both positive and negative values.
#' Automatically estimates the optimal lambda using MLE.
#'
#' @param x A numeric vector.
#' @param lambda A numeric value or "auto".
#' @return A numeric vector with attribute "lambda".
#' @references Yeo, I.-K., & Johnson, R. A. (2000). A new family of power transformations to improve normality or symmetry. Biometrika.
#' @importFrom stats optimize var
#' @export
trans_yeojohnson <- function(x, lambda = "auto") {
  if (!is.numeric(x)) stop("Input 'x' must be a numeric vector.")

  # Internal helper for the transformation formula
  yj_trans <- function(x_vec, lam) {
    res <- numeric(length(x_vec))
    non_neg <- x_vec >= 0 & !is.na(x_vec)
    neg     <- x_vec < 0  & !is.na(x_vec)

    # Formula for non-negative values
    if (any(non_neg)) {
      if (abs(lam) < 1e-5) {
        res[non_neg] <- log(x_vec[non_neg] + 1)
      } else {
        res[non_neg] <- ((x_vec[non_neg] + 1)^lam - 1) / lam
      }
    }

    # Formula for negative values
    if (any(neg)) {
      if (abs(lam - 2) < 1e-5) {
        res[neg] <- -log(-x_vec[neg] + 1)
      } else {
        res[neg] <- -((-x_vec[neg] + 1)^(2 - lam) - 1) / (2 - lam)
      }
    }

    # Handle NAs
    res[is.na(x_vec)] <- NA
    return(res)
  }

  # Optimization Logic
  log_likelihood <- function(lam, x_data) {
    x_clean <- x_data[!is.na(x_data)]
    n <- length(x_clean)
    x_t <- yj_trans(x_clean, lam)
    var_t <- stats::var(x_t) * (n - 1) / n
    # Jacobian adjustment
    log_jac <- sum(sign(x_clean) * log(abs(x_clean) + 1))
    ll <- - (n / 2) * log(var_t) + (lam - 1) * log_jac
    return(ll)
  }

  if (identical(lambda, "auto")) {
    opt <- stats::optimize(log_likelihood, c(-2, 2), x_data = x, maximum = TRUE)
    best_lambda <- opt$maximum
  } else {
    best_lambda <- lambda
  }

  res <- yj_trans(x, best_lambda)
  attr(res, "lambda") <- best_lambda
  return(res)
}
