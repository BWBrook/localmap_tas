testthat::test_that("tasveg class helpers derive stable ids and lookup paths", {
  testthat::expect_equal(
    localmap:::resolve_tasveg_class_id("demo", c(demo_tasveg_class = "x")),
    "demo_tasveg_class"
  )
  testthat::expect_equal(
    localmap:::resolve_tasveg_class_id("jc", c(other = "x")),
    "jc_tasveg_class"
  )
  testthat::expect_equal(
    localmap:::tasveg_class_lookup_path(
      output_dir = "outputs/demo",
      class_id = "demo_tasveg_class",
      vector_path = NULL
    ),
    file.path("outputs/demo", "analysis", "vector", "demo_tasveg_class_lookup.csv")
  )
})
