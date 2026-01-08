test_that("Box-Cox calculates lambda automatically", {
  # Log-normal data needs lambda = 0 to become normal
  set.seed(123)
  x <- exp(rnorm(100)) # e^x is log-normal

  res <- trans_boxcox(x)

  # The optimal lambda should be close to 0
  lambda <- attr(res, "lambda")
  expect_true(abs(lambda) < 0.2)

  # The result should be numeric
  expect_type(res, "double")
})

test_that("Box-Cox handles manual lambda", {
  x <- c(1, 10, 100)
  # Force lambda = 1 (Linear transform: x-1)
  res <- trans_boxcox(x, lambda = 1)

  expect_equal(as.numeric(res), c(0, 9, 99))
  expect_equal(attr(res, "lambda"), 1)
})

test_that("Box-Cox handles negative values (Auto-shift)", {
  x <- c(-2, 0, 2)
  # Shift logic: min is -2. shift should be |-2| + 1 = 3.
  # x becomes: 1, 3, 5
  res <- trans_boxcox(x, force_pos = TRUE)

  expect_equal(attr(res, "shift"), 3)
  # Ensure no NAs produced
  expect_false(any(is.na(res)))
})

test_that("Box-Cox throws error for negative values if force_pos=FALSE", {
  x <- c(-1, 1)
  expect_error(trans_boxcox(x, force_pos = FALSE), "requires positive values")
})

test_that("Box-Cox handles NA values", {
  x <- c(1, 10, NA)
  res <- trans_boxcox(x, lambda = 1)
  expect_true(is.na(res[3]))
  expect_equal(res[1], 0)
})

test_that("Box-Cox checks input types", {
  expect_error(trans_boxcox("text"), "must be a numeric vector")
})

test_that("Box-Cox handles explicit lambda = 0 (Log transform)", {
  x <- c(exp(1), exp(2)) # e^1, e^2

  res <- trans_boxcox(x, lambda = 0)

  # Key point: Add `as.numeric()` to remove attributes before comparing values.
  expect_equal(as.numeric(res), c(1, 2))

  # Check attributes separately
  expect_equal(attr(res, "lambda"), 0)
})

test_that("Box-Cox rejects invalid lambda input", {
  x <- 1:10
  # Intentionally feeding garbage parameters
  expect_error(trans_boxcox(x, lambda = "invalid_string"), "must be 'auto' or a single numeric")
  expect_error(trans_boxcox(x, lambda = c(1, 2)), "must be 'auto' or a single numeric")
})

test_that("Internal log-likelihood handles tiny lambda (Near Zero)", {
  x <- c(1, 10, 100)

  # Use ':::' to access the internal unexported function 'boxcox_loglik'.
  # We explicitly pass lambda = 0 to force the execution of the 'if (abs(lam) < 1e-5)' branch.
  # This ensures 100% test coverage for numerical stability logic.
  ll_zero <- prepr:::boxcox_loglik(0, x)

  # Verify that it returns a valid numeric result (no error, no NA)
  expect_true(is.numeric(ll_zero))
  expect_false(is.na(ll_zero))

  # Also verify the standard branch (lambda = 1) still works
  ll_one <- prepr:::boxcox_loglik(1, x)
  expect_true(is.numeric(ll_one))
})
