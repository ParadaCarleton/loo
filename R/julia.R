#' Use Julia for fast LOO calculations
#'
#' The `julia_setup` function allows for LOO calculations to be completed in
#' Julia instead of R. Julia is a just-in-time compiled language designed
#' from the ground up to achieve high performance in numerical, scientific, and
#' statistical computations without sacrificing on ease-of-use or readability.
#' Note that `julia_setup` will incur a one-time cost to compile the `loo`
#' function the first time it is run. Although we are working on improvements,
#' compilation time can be significant, and as a result, `julia_setup` may not
#' be worth it when comparing a handful of models trained on small samples. With
#' large sample sizes, many draws from the posterior distribution, or more ,
#' Julia may be significantly faster.
#'
#'
#' If you would like to avoid waiting for compilation to complete every time you
#' use LOO, you can create a precompiled binary with
#' \href{https://github.com/JuliaLang/PackageCompiler.jl}{PackageCompiler.jl}
#'
#'
#' @param cores The number of threads used when initializing Julia; we recommend
#' using one thread per CPU core (whether real or virtual). Defaults to the
#' number of CPU cores.
#'
#'
#' @export
#'

julia_start <- function(cores=getOption("mc.cores", parallel::detectCores())){
  if (!require(JuliaConnectoR)){
    stop("Unable to load JuliaConnectoR; make sure it is installed.")
  }
  Sys.setenv(JULIA_NUM_THREADS = cores)

  JULIA_MIN_VER <- "1.6.1"
  version_check <- stringr::str_glue("VERSION < v\"{JULIA_MIN_VER}\"")
  julia_err_message <- stringr::str_glue(
    "Julia has not been set up properly. ",
    "Please make sure Julia has been installed and is at least ",
    "version {JULIA_MIN_VER}."
  )

  source <- "mcmc"


  if (!JuliaConnectoR::juliaSetupOk()) {
    stop(julia_err_message)
  } else if (JuliaConnectoR::juliaEval(version_check)) {
    stop(julia_err_message)
  } else {
    # Check to make sure that ParetoSmooth package is installed; if not, install
    JuliaConnectoR::juliaExpr("
          try
            import ParetoSmooth
          catch e
            import Pkg; Pkg.install(\"ParetoSmooth\")
          end
        ")
  }
  options(loo.julia = TRUE)
}
