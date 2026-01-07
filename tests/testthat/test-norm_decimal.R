test_that("Decimal Scaling works on standard input", {
  x <- c(5, 50, 500)
  # Max abs is 500. log10(500) is 2.69. j should be 3.
  # Values should be divided by 1000.
  expect_equal(norm_decimal(x), c(0.005, 0.05, 0.5))
})

test_that("Decimal Scaling handles negative values", {
  x <- c(-900, 50)
  # Max abs is 900. j should be 3 (div by 1000).
  expect_equal(norm_decimal(x), c(-0.9, 0.05))
})

test_that("Decimal Scaling handles edge case: All Zeros", {
  x <- c(0, 0, 0)
  expect_equal(norm_decimal(x), c(0, 0, 0))
})

test_that("Decimal Scaling handles NA", {
  x <- c(500, NA)
  res <- norm_decimal(x, na.rm = TRUE)
  expect_equal(res[1], 0.5)
  expect_true(is.na(res[2]))
})

test_that("Decimal Scaling checks input", {
  expect_error(norm_decimal("text"), "must be a numeric vector")
})
