test_that("Yeo-Johnson works on negative values", {
  x <- c(-10, -5, 0, 5, 10)
  res <- trans_yeojohnson(x)
  # Check if it runs and returns finite values
  expect_true(all(is.finite(res)))
  expect_type(res, "double")
})

test_that("Yeo-Johnson lambda=1 identity-like check", {
  # If lambda=1, pos part is x, neg part is x
  x <- c(2) # ((2+1)^1 - 1)/1 = 2
  res <- trans_yeojohnson(x, lambda = 1)
  expect_equal(as.numeric(res), 2)
})

test_that("Yeo-Johnson rejects non-numeric input", {
  expect_error(trans_yeojohnson("text"), "must be a numeric vector")
})

test_that("Yeo-Johnson handles lambda = 0 (Log case for positive values)", {
  # When lambda = 0, the positive part becomes log(x + 1).
  x <- c(0, exp(1)-1) # 0, e-1

  res <- trans_yeojohnson(x, lambda = 0)

  # log(0+1) = 0
  # log((e-1)+1) = log(e) = 1
  expect_equal(as.numeric(res), c(0, 1))
})

test_that("Yeo-Johnson handles lambda = 2 (Log case for negative values)", {
  # When lambda=2, the negative part becomes -log(-x+1).
  x <- c(0, -(exp(1)-1)) # 0, -(e-1)

  res <- trans_yeojohnson(x, lambda = 2)

  # -log(-0+1) = 0
  # -log(-(-(e-1)) + 1) = -log(e) = -1
  expect_equal(as.numeric(res), c(0, -1))
})
