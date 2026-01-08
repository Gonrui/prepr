test_that("norm_mode_range basic logic works", {
  # Standard case: Mode is 2.
  x <- c(1, 2, 2, 2, 5)
  res <- norm_mode_range(x, tau = 0.9)

  expect_equal(res, c(-1, 0, 0, 0, 1))
})

test_that("norm_mode_range simulates geriatric anomaly detection", {
  # TMIG Scenario:
  # Routine: 3000 steps (freq=3)
  # Anomaly: 200 steps (Fall)
  # Anomaly: 5000 steps (Active)
  steps <- c(3000, 3000, 3000, 200, 5000)

  res <- norm_mode_range(steps, tau = 0.8)

  # Routine should be muted to 0
  expect_equal(res[1:3], c(0, 0, 0))
  # Fall should be -1
  expect_equal(res[4], -1)
  # Active should be 1
  expect_equal(res[5], 1)
})

test_that("norm_mode_range handles plateau mode", {
  # Mode is 2 and 3
  x <- c(2, 2, 3, 3, 10)
  res <- norm_mode_range(x, tau = 0.8)
  expect_equal(res[1:4], c(0, 0, 0, 0))
})

test_that("norm_mode_range handles flat data", {
  x <- c(5, 5, 5)
  expect_equal(norm_mode_range(x), c(0, 0, 0))
})

test_that("norm_mode_range rejects non-numeric", {
  expect_error(norm_mode_range("error"), "must be a numeric")
})


test_that("norm_mode_range triggers fallback when tau > 1", {
  # Scenario: User sets an overly strict tau (e.g., 1.5)
  # The mode is 2 (freq=2). The threshold required is >= 1.5 * 2 = 3.
  # No values satisfy this condition, so 'mode_vals' is initially empty.
  # This should trigger the fallback logic (Line 55) to pick the absolute mode.
  x <- c(1, 2, 2, 3)

  # The algorithm should run robustly even with invalid tau, instead of throwing an error
  res <- norm_mode_range(x, tau = 1.5)

  # Verify: The algorithm still correctly identifies 2 as the mode (mapped to 0)
  expect_equal(res[2], 0)      # 2 is correctly zeroed out
  expect_equal(res[1], -1)     # 1 is left tail
  expect_equal(res[4], 1)      # 3 is right tail
})
