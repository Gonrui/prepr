test_that("Mean Normalization works on standard input", {
  x <- c(1, 2, 3)
  # Mean = 2, Range = 3 - 1 = 2
  # (1-2)/2 = -0.5
  # (2-2)/2 = 0
  # (3-2)/2 = 0.5
  res <- norm_mean(x)
  expect_equal(res, c(-0.5, 0, 0.5))
  expect_equal(mean(res), 0)
})

test_that("Mean Normalization handles Zero Range", {
  x <- c(5, 5, 5)
  # Range is 0. Expect warning and zeros.
  expect_warning(res <- norm_mean(x), "Range is zero")
  expect_equal(res, c(0, 0, 0))
})

test_that("Mean Normalization handles NA", {
  x <- c(1, 3, NA)
  # Mean=2, Range=2. (1-2)/2 = -0.5
  res <- norm_mean(x, na.rm = TRUE)

  # Verify that the numerical values are correct.
  expect_equal(res[1], -0.5)

  # Verify whether NA is retained.
  expect_true(is.na(res[3]))
})

test_that("Mean Normalization checks input", {
  # Validate input type check
  expect_error(norm_mean("text"), "must be a numeric vector")
})
