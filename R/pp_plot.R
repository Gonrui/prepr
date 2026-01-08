#' Visualize Distribution: Before vs After
#'
#' Creates a comparison plot to visualize the effect of a transformation.
#' It displays histograms and density curves for both the original and transformed data.
#'
#' @param x Numeric vector. The original data.
#' @param y Numeric vector. The transformed data.
#' @param title String. The main title of the plot.
#'
#' @return A \code{ggplot} object.
#' @import ggplot2
#' @export
#'
#' @examples
#' # 1. Generate skewed data
#' x <- rchisq(1000, df = 2)
#'
#' # 2. Transform it
#' y <- trans_boxcox(x)
#'
#' # 3. Visualize
#' pp_plot(x, y, title = "Box-Cox Transformation Effect")
pp_plot <- function(x, y, title = "Distribution Comparison") {

  # 1. Check inputs
  if (!is.numeric(x) || !is.numeric(y)) {
    stop("Both x and y must be numeric vectors.")
  }

  if (length(x) != length(y)) {
    stop("x and y must have the same length.")
  }

  # 2. Prepare Data for ggplot (Manual reshaping to avoid dependency on tidyr)
  # We construct a data.frame with: Value, Group (Original/Transformed)
  df_x <- data.frame(Value = x, Group = "Original")
  df_y <- data.frame(Value = y, Group = "Transformed")
  plot_data <- rbind(df_x, df_y)

  # Ensure the order is Original -> Transformed
  plot_data$Group <- factor(plot_data$Group, levels = c("Original", "Transformed"))

  # 3. Plotting
  p <- ggplot(plot_data, aes(x = Value, fill = Group)) +
    # Histogram with density scaling (y = ..density..)
    geom_histogram(aes(y = after_stat(density)), bins = 30, alpha = 0.6, color = "white") +
    # Density curve overlay
    geom_density(alpha = 0.2, linewidth = 1) +
    # Faceting: Split into two panels, allow different x/y scales
    facet_wrap(~Group, scales = "free") +
    # Styling
    theme_minimal() +
    scale_fill_manual(values = c("Original" = "#bdc3c7", "Transformed" = "#2ecc71")) +
    labs(title = title, x = NULL, y = "Density") +
    theme(legend.position = "none",
          plot.title = element_text(hjust = 0.5, face = "bold"))

  return(p)
}
