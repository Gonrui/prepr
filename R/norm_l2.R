#' L2 Normalization (Unit Vector)
#'
#' Scales the vector so that its Euclidean norm (L2 norm) is 1.
#' This technique is often used in text mining and high-dimensional clustering,
#' and is related to spatial sign preprocessing in robust statistics.
#'
#' Formula: \eqn{x' = \frac{x}{\sqrt{\sum x^2}}}
#'
#' @param x A numeric vector.
#' @param na.rm Logical. Remove NAs for norm calculation? Default is \code{TRUE}.
#' @return A numeric vector with an L2 norm of 1.
#'
#' @references
#' Serneels, S., De Nages, E., & Van Espen, P. J. (2006). Spatial sign preprocessing: a simple way to impart moderate robustness to multivariate estimators.
#' \emph{Journal of Chemical Information and Modeling}, 46(3), 1402-1409. \doi{10.1021/ci050498u}
#'
#' Han, J., Kamber, M., & Pei, J. (2011). \emph{Data mining: concepts and techniques} (3rd ed.). Morgan Kaufmann.
#'
#' @export
#'
#' @examples
#' # Convert a vector to unit length
#' x <- c(3, 4)
#' norm_l2(x) # Returns c(0.6, 0.8)
norm_l2 <- function(x, na.rm = TRUE) {
  if (!is.numeric(x)) stop("Input 'x' must be a numeric vector.")

  # Calculate L2 Norm
  l2_norm <- sqrt(sum(x^2, na.rm = na.rm))

  # Handle Zero Vector case to prevent division by zero
  if (l2_norm == 0) {
    warning("L2 norm is zero (input is a zero vector). Returning original vector.")
    return(x)
  }

  return(x / l2_norm)
}
