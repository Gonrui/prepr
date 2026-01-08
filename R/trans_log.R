#' Logarithmic Transformation
#'
#' Applies a logarithmic transformation to the data with an optional offset.
#' This is a fundamental technique in data mining to reduce right-skewness
#' (e.g., for heavy-tailed distributions like income or population).
#'
#' Formula: \eqn{y = \log_b(x + \text{offset})}
#'
#' @param x A numeric vector.
#' @param base The base of the logarithm. Default is \code{exp(1)} (natural log).
#' @param offset A numeric value added to x before taking the log.
#'   Default is 1 (calculates log1p), which handles zeros naturally.
#'
#' @return A numeric vector.
#'
#' @references
#' Han, J., Kamber, M., & Pei, J. (2011). \emph{Data mining: concepts and techniques} (3rd ed.). Morgan Kaufmann.
#'
#' Bartlett, M. S. (1947). The use of transformations.
#' \emph{Biometrics}, 3(1), 39-52. \doi{10.2307/3001536}
#'
#' @export
#'
#' @examples
#' # Standard log1p transform (handles zeros)
#' trans_log(c(0, 10, 100))
#'
#' # Base 10 log with no offset (for strictly positive data)
#' trans_log(c(1, 10, 100), base = 10, offset = 0)
trans_log <- function(x, base = exp(1), offset = 1) {
  if (!is.numeric(x)) stop("Input 'x' must be a numeric vector.")

  # Defensive check: will the offset prevent NaNs?
  min_val <- min(x, na.rm = TRUE)
  if (min_val + offset <= 0) {
    warning("Negative or zero values produced after adding offset. NaNs may be generated (log of non-positive).")
  }

  return(log(x + offset, base = base))
}
