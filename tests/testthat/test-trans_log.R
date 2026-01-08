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


test_that("trans_log handles invalid input", {
  expect_error(trans_log("text"), "must be a numeric vector")
})

test_that("trans_log warns if offset is insufficient", {
  # x = -10, offset = 1 (default).
  # -10 + 1 = -9. log(-9) It is illegal (NaN).
  # This should trigger the warning on Line 36.
  expect_warning(trans_log(-10), "Negative or zero values produced")

  # Also check if NaN was actually generated
  # (R's log will usually report a warning and include NaN in the results).
  suppressWarnings({
    res <- trans_log(-10)
  })
  expect_true(is.nan(res))
})
