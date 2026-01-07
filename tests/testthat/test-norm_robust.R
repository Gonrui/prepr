test_that("Robust Scaler works on standard input", {
  # Standard case: 1, 2, 3
  # Median = 2, MAD = 1.4826 * median(|1-2|, |2-2|, |3-2|) = 1.4826 * 1 = 1.4826
  x <- c(1, 2, 3)
  res <- norm_robust(x)

  expect_equal(median(res), 0)
  # The result should be approx (x - 2) / 1.4826
  expect_equal(res[1], (1 - 2) / 1.4826, tolerance = 1e-4)
})

test_that("Robust Scaler resists outliers (Comparison with Z-Score)", {
  # This is the KILLER FEATURE of this algorithm
  # Data with a massive outlier
  x <- c(1, 2, 3, 1000)

  res_robust <- norm_robust(x)

  # For robust scaler, the median of first 3 numbers should still be close to 0
  # even with the 1000 present.
  # Median of x is 2.5. MAD is roughly 1.5 * 1.5 = 2.22.
  # So the first few numbers won't be squashed to 0.
  expect_true(abs(res_robust[1]) > 0.1)

  # Contrast this with Z-Score (Mental Check):
  # Mean is ~250. SD is ~400.
  # (1 - 250)/400 = -0.6.
  # The robust method preserves the local structure better for the majority.
})

test_that("Robust Scaler handles Zero MAD (Edge Case)", {
  # If >50% of data are identical, MAD is 0.
  x <- c(5, 5, 5, 10) # Median is 5. Deviations: 0, 0, 0, 5. MAD is 0.

  # Expect warning and fallback to centering
  expect_warning(res <- norm_robust(x), "MAD is zero")

  # Should return x - median(5)
  expect_equal(res, c(0, 0, 0, 5))
})

test_that("Robust Scaler handles NA values", {
  x <- c(1, 2, 3, NA)

  # Default behavior: ignore NA
  res <- norm_robust(x, na.rm = TRUE)
  expect_true(is.na(res[4]))
  expect_equal(median(res, na.rm = TRUE), 0)
})
test_that("Robust Scaler checks input types", {
  # Intentionally passing in a character type, hoping it will throw an error.
  expect_error(norm_robust("invalid_text"), "must be a numeric vector")

  # Intentionally passing in a logical type, hoping it will throw an error.
  expect_error(norm_robust(TRUE), "must be a numeric vector")
})
