#' Z-Score Standardization
#'
#' Standardizes a numeric vector by centering it to have a mean of 0
#' and scaling it to have a standard deviation of 1.
#'
#' Formula: \eqn{z = \frac{x - \mu}{\sigma}}
#'
#' @param x A numeric vector.
#' @param na.rm Logical. Should NA values be removed during mean/sd calculation?
#'   Default is \code{TRUE}.
#'
#' @return A numeric vector.
#'   If the input vector has zero variance (all values are identical),
#'   the function returns a centered vector (all zeros) and issues a warning.
#'
#' @references
#' Han, J., Kamber, M., & Pei, J. (2011). \emph{Data mining: concepts and techniques} (3rd ed.). Morgan Kaufmann.
#'
#' @export
#'
#' @examples
#' # Standard usage
#' norm_zscore(c(1, 2, 3, 4, 5))
#'
#' # Edge case: Zero variance
#' norm_zscore(c(5, 5, 5))
norm_zscore <- function(x, na.rm = TRUE) {
  # 1. Input Validation
  if (!is.numeric(x)) {
    stop("Input 'x' must be a numeric vector.")
  }

  # 2. Calculate Statistics
  # Note: if na.rm=TRUE, mean() and sd() will automatically ignore NAs
  mean_val <- mean(x, na.rm = na.rm)
  sd_val <- stats::sd(x, na.rm = na.rm)

  # 3. Handle Edge Case: Zero Variance
  # If all values are identical, sd_val is 0. Division by 0 creates Inf or NaN.
  # In this scenario, we return a centered vector (zeros) to maintain stability.
  if (is.na(sd_val) || sd_val == 0) {
    warning("Standard deviation is zero. Returning centered vector (zeros).")
    # Return (x - mean), which results in zeros while preserving original NA positions
    return(x - mean_val)
  }

  # 4. Core Calculation
  res <- (x - mean_val) / sd_val

  return(res)
}
