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
