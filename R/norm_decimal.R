#' Decimal Scaling Normalization
#'
#' Normalizes a numeric vector by moving the decimal point of values of attribute A.
#' The number of decimal points moved depends on the maximum absolute value of A.
#'
#' Formula: \eqn{x' = \frac{x}{10^j}}
#' where \eqn{j} is the smallest integer such that \eqn{\max(|x'|) < 1}.
#'
#' @param x A numeric vector.
#' @param na.rm Logical. Should NA values be ignored when determining the scaling factor?
#'   Default is \code{TRUE}.
#'
#' @return A numeric vector with values typically in the range (-1, 1).
#'
#' @references
#' Han, J., Kamber, M., & Pei, J. (2011). \emph{Data mining: concepts and techniques} (3rd ed.). Morgan Kaufmann.
#'
#' @export
#'
#' @examples
#' # Max value is 980, so j=3 (divides by 1000) -> 0.98
#' norm_decimal(c(10, 500, 980))
#'
#' # Works with negative numbers
#' norm_decimal(c(-50, 50, 200))
norm_decimal <- function(x, na.rm = TRUE) {
  # 1. Input Validation
  if (!is.numeric(x)) {
    stop("Input 'x' must be a numeric vector.")
  }

  # 2. Find Maximum Absolute Value
  max_abs <- max(abs(x), na.rm = na.rm)

  # 3. Handle Edge Case: All zeros
  if (max_abs == 0) {
    return(x) # 0 divided by anything is 0
  }

  # 4. Calculate Scaling Factor j
  # We want max_abs / 10^j < 1  =>  max_abs < 10^j  =>  log10(max_abs) < j
  # So j = floor(log10(max_abs)) + 1
  j <- floor(log10(max_abs)) + 1

  # 5. Core Calculation
  res <- x / (10^j)

  return(res)
}
