#' Robust Standardization (Median-MAD)
#'
#' Standardizes a numeric vector using robust statistics: median and
#' median absolute deviation (MAD). This method is less sensitive to outliers
#' compared to Z-score standardization.
#'
#' Formula: \eqn{x' = \frac{x - \text{median}(x)}{\text{mad}(x)}}
#'
#' @param x A numeric vector.
#' @param na.rm Logical. Should NA values be removed? Default is \code{TRUE}.
#' @param constant A scale factor for MAD calculation. Default is 1.4826,
#'   which ensures consistency with the standard deviation for normal distributions.
#'
#' @return A numeric vector.
#'   If MAD is 0 (e.g., more than 50% of the data are identical), the function
#'   returns a centered vector (x - median) and issues a warning.
#'
#' @references
#' Huber, P. J. (1981). \emph{Robust Statistics}. Wiley. ISBN: 978-0-471-41805-4.
#'
#' Hampel, F. R. (1974). The influence curve and its role in robust estimation.
#' \emph{Journal of the American Statistical Association}, 69(346), 383-393.
#'
#' @export
#'
#' @examples
#' # Data with an outlier
#' x <- c(1, 2, 3, 4, 100)
#'
#' # Z-score is heavily affected by the outlier
#' norm_zscore(x)
#'
#' # Robust scaler handles it better
#' norm_robust(x)
norm_robust <- function(x, na.rm = TRUE, constant = 1.4826) {
  # 1. Input Validation
  if (!is.numeric(x)) {
    stop("Input 'x' must be a numeric vector.")
  }

  # 2. Calculate Robust Statistics
  med_val <- stats::median(x, na.rm = na.rm)
  mad_val <- stats::mad(x, center = med_val, constant = constant, na.rm = na.rm)

  # 3. Handle Edge Case: Zero MAD
  if (is.na(mad_val) || mad_val == 0) {
    warning("MAD is zero (low variability). Returning centered vector (x - median).")
    return(x - med_val)
  }

  # 4. Core Calculation
  res <- (x - med_val) / mad_val

  return(res)
}
