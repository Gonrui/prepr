#' Mean Normalization
#'
#' Scales a numeric vector by centering it around its mean and scaling it by its range.
#' The resulting vector has a mean of 0 and values typically within [-1, 1].
#'
#' Formula: \eqn{x' = \frac{x - \text{mean}(x)}{\max(x) - \min(x)}}
#'
#' @param x A numeric vector.
#' @param na.rm Logical. Should NA values be removed during calculation?
#'   Default is \code{TRUE}.
#'
#' @return A numeric vector.
#'   If the range is 0 (all values are identical), returns a centered vector (zeros).
#'
#' @references
#' Han, J., Kamber, M., & Pei, J. (2011). \emph{Data mining: concepts and techniques} (3rd ed.). Morgan Kaufmann.
#'
#' @export
#'
#' @examples
#' # Result ranges from approx -0.5 to 0.5, mean is 0
#' norm_mean(c(1, 2, 3, 4, 5))
#'
#' # Handles negative values
#' norm_mean(c(-10, 0, 10))
norm_mean <- function(x, na.rm = TRUE) {
  # 1. Input Validation
  if (!is.numeric(x)) {
    stop("Input 'x' must be a numeric vector.")
  }

  # 2. Calculate Statistics
  x_mean <- mean(x, na.rm = na.rm)
  rng    <- range(x, na.rm = na.rm)
  x_min  <- rng[1]
  x_max  <- rng[2]
  x_range <- x_max - x_min

  # 3. Handle Edge Case: Zero Range (Zero Variance)
  # Division by zero risk
  if (x_range == 0) {
    warning("Range is zero (all values are identical). Returning centered vector (zeros).")
    return(x - x_mean)
  }

  # 4. Core Calculation
  res <- (x - x_mean) / x_range

  return(res)
}
