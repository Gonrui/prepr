test_that("L2 Norm scales to unit length", {
  x <- c(3, 4) # 3-4-5 triangle
  res <- norm_l2(x)

  # Result should be 3/5=0.6, 4/5=0.8
  expect_equal(res, c(0.6, 0.8))
  # Norm should be 1
  expect_equal(sqrt(sum(res^2)), 1)
})

test_that("L2 Norm handles zero vector", {
  x <- c(0, 0, 0)
  expect_warning(res <- norm_l2(x), "L2 norm is zero")
  expect_equal(res, c(0, 0, 0))
})

test_that("norm_l2 rejects non-numeric input", {
  expect_error(norm_l2("text"), "must be a numeric vector")
})
