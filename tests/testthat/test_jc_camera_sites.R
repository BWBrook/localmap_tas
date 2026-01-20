testthat::test_that("derive_camera_sites_from_jc builds rd/obs from obs/op", {
  tmp_dir <- tempdir()
  site_path <- file.path(tmp_dir, "site.csv")
  obs_path <- file.path(tmp_dir, "obs.csv")
  op_path <- file.path(tmp_dir, "op.csv")
  out_path <- file.path(tmp_dir, "jc_camera_sites.csv")

  utils::write.csv(
    data.frame(
      site = c("jc_a", "jc_b"),
      lat = c(-42.0, -42.1),
      lon = c(146.0, 146.1)
    ),
    site_path,
    row.names = FALSE
  )
  utils::write.csv(
    data.frame(
      site = c("jc_a", "jc_a", "jc_b"),
      datetime = c("01/01/2020 10:00:00", "02/01/2020 10:00:00", "01/01/2020 05:00:00"),
      count = c(1, 2, 5)
    ),
    obs_path,
    row.names = FALSE
  )
  utils::write.csv(
    data.frame(
      date = c("2020-01-01", "2020-01-02", "2020-01-03"),
      jc_a = c(1, 1, 0),
      jc_b = c(0, 1, 1)
    ),
    op_path,
    row.names = FALSE
  )

  path <- localmap:::derive_camera_sites_from_jc(site_path, obs_path, op_path, out_path)
  testthat::expect_true(file.exists(path))

  derived <- readr::read_csv(path, show_col_types = FALSE, num_threads = 1)
  jc_a <- derived[derived$site == "jc_a", ]
  jc_b <- derived[derived$site == "jc_b", ]
  testthat::expect_equal(jc_a$obs, 3)
  testthat::expect_equal(jc_a$rd, 2)
  testthat::expect_equal(jc_b$obs, 5)
  testthat::expect_equal(jc_b$rd, 2)
})

testthat::test_that("derive_camera_sites_from_jc honors rd/count in site.csv", {
  tmp_dir <- tempdir()
  site_path <- file.path(tmp_dir, "site.csv")
  obs_path <- file.path(tmp_dir, "obs.csv")
  op_path <- file.path(tmp_dir, "op.csv")
  out_path <- file.path(tmp_dir, "jc_camera_sites_direct.csv")

  utils::write.csv(
    data.frame(
      site = c("jc_a", "jc_b"),
      lat = c(-42.0, -42.1),
      lon = c(146.0, 146.1),
      count = c(10, 20),
      rd = c(7, 8)
    ),
    site_path,
    row.names = FALSE
  )
  utils::write.csv(
    data.frame(
      site = c("jc_a", "jc_a", "jc_b"),
      datetime = c("01/01/2020 10:00:00", "02/01/2020 10:00:00", "01/01/2020 05:00:00"),
      count = c(1, 2, 5)
    ),
    obs_path,
    row.names = FALSE
  )
  utils::write.csv(
    data.frame(
      date = c("2020-01-01", "2020-01-02"),
      jc_a = c(1, 1),
      jc_b = c(1, 1)
    ),
    op_path,
    row.names = FALSE
  )

  path <- localmap:::derive_camera_sites_from_jc(site_path, obs_path, op_path, out_path)
  testthat::expect_true(file.exists(path))

  derived <- readr::read_csv(path, show_col_types = FALSE, num_threads = 1)
  jc_a <- derived[derived$site == "jc_a", ]
  jc_b <- derived[derived$site == "jc_b", ]
  testthat::expect_equal(jc_a$obs, 10)
  testthat::expect_equal(jc_a$rd, 7)
  testthat::expect_equal(jc_b$obs, 20)
  testthat::expect_equal(jc_b$rd, 8)
})
