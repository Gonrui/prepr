#' Min-Max Normalization
#'
#' Scales a numeric vector to a specific range, typically [0, 1].
#' This method is sensitive to outliers.
#'
#' Formula: \eqn{x' = \frac{x - \min(x)}{\max(x) - \min(x)} \times (\text{max\_val} - \text{min\_val}) + \text{min\_val}}
#'
#' @param x A numeric vector.
#' @param min_val The minimum value of the target range. Default is 0.
#' @param max_val The maximum value of the target range. Default is 1.
#' @param na.rm Logical. Should NA values be removed during min/max calculation?
#'   Default is \code{TRUE}.
#'
#' @return A numeric vector scaled to the range [min_val, max_val].
#'
#' @references
#' Han, J., Kamber, M., & Pei, J. (2011). \emph{Data mining: concepts and techniques} (3rd ed.). Morgan Kaufmann.
#'
#' @export
#'
#' @examples
#' norm_minmax(c(1, 2, 3, 4, 5))
#' norm_minmax(c(1, 2, 3), min_val = -1, max_val = 1)
norm_minmax <- function(x, min_val = 0, max_val = 1, na.rm = TRUE) {
  # 1. Input Validation
  if (!is.numeric(x)) {
    stop("Input 'x' must be a numeric vector.")
  }

  if (min_val >= max_val) {
    stop("Error: 'min_val' must be strictly less than 'max_val'.")
  }

  # 2. Calculate Statistics
  rng <- range(x, na.rm = na.rm)
  x_min <- rng[1]
  x_max <- rng[2]

  # 3. Handle Edge Case: Zero Variance
  if (x_min == x_max) {
    warning("All values in 'x' are identical. Returning 'min_val' to avoid division by zero.")
    res <- rep(min_val, length(x))
    res[is.na(x)] <- NA # Restore NAs if any
    return(res)
  }

  # 4. Core Normalization Logic
  # Step A: Standardize to [0, 1]
  x_std <- (x - x_min) / (x_max - x_min)

  # Step B: Scale to [min_val, max_val]
  x_scaled <- x_std * (max_val - min_val) + min_val

  return(x_scaled)
}
