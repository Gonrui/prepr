test_that("pp_plot returns a ggplot object", {
  x <- rnorm(100)
  y <- rnorm(100)

  p <- pp_plot(x, y)

  # Check class
  expect_s3_class(p, "ggplot")
  # Check if data is correct length (200 rows because we stacked x and y)
  expect_equal(nrow(p$data), 200)
})

test_that("pp_plot catches errors", {
  expect_error(pp_plot(1:10, 1:5), "must have the same length")
})
