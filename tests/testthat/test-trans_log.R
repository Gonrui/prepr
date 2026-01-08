test_that("Log transform works", {
  x <- c(0, exp(1)-1) # 0, e-1
  # log(0 + 1) = 0; log(e-1 + 1) = 1
  expect_equal(trans_log(x), c(0, 1))
})

test_that("Log transform handles base 10", {
  x <- c(9, 99)
  # log10(10)=1, log10(100)=2 (offset=1)
  expect_equal(trans_log(x, base = 10), c(1, 2))
})
