#' Compare models across domains
#'
#' The LOO difference plot shows how the ELPD of two different models
#' changes when a predictor is varied. This can be useful for identifying
#' opportunities for model stacking or expansion.
#'
#' @param y A vector of observations. See Details.
#' @param loo_1,loo_2 Objects returned by [loo()].
#' @param group A grouping variable (a vector or factor) the same length
#'   as `y`. Each value in group is interpreted as the group level pertaining
#'   to the corresponding value of `y`.
#' @param size,alpha Point size and opacity passed to [ggplot2::geom_jitter()].
#' @param jitter Amount of horizontal jitter passed as the `width` argument
#'   to [ggplot2::geom_jitter()].
#' @param sort_by_group If `TRUE`, observations are ordered by `group`
#'   and the x-axis is replaced by a sequential index. The supplied `y` values
#'   are therefore not used as x coordinates. Plotting by index can be useful
#'   when categories have very different sample sizes.
#'
#' @template bayesvis-reference
#'
#' @return A [ggplot2::ggplot()] object.
#'
#' @examples
#' log_lik <- example_loglik_matrix()
#'
#' shift <- seq(-0.5, 0.5, length.out = ncol(log_lik))
#' log_lik_2 <- sweep(log_lik, 2, shift, FUN = "+")
#'
#' loo_1 <- loo(log_lik)
#' loo_2 <- loo(log_lik_2)
#'
#' plot_loo_difference(
#'   seq_len(ncol(log_lik)),
#'   loo_1,
#'   loo_2
#' )
#' @export
plot_loo_difference <-
  function(
    y,
    loo_1,
    loo_2,
    group = NULL,
    size = 1,
    alpha = 1,
    jitter = 0,
    sort_by_group = FALSE
  ) {
    if (!requireNamespace("ggplot2", quietly = TRUE)) {
      stop(
        "Please install 'ggplot2' to use `plot_loo_difference()`.",
        call. = FALSE
      )
    }

    checkmate::assert_flag(sort_by_group)
    checkmate::assert_class(loo_1, "loo")
    checkmate::assert_class(loo_2, "loo")

    elpd_1 <- pointwise(loo_1, "elpd_loo")
    elpd_2 <- pointwise(loo_2, "elpd_loo")

    if (length(elpd_1) != length(elpd_2)) {
      stop(
        "`loo_1` and `loo_2` must contain the same number of observations.",
        call. = FALSE
      )
    }

    checkmate::assert_vector(
      y,
      len = length(elpd_1)
    )

    if (!is.null(group)) {
      checkmate::assert_vector(
        group,
        len = length(y)
      )
    }

    elpd_diff <- elpd_1 - elpd_2

    if (sort_by_group) {
      if (is.null(group)) {
        stop(
          "`group` must be supplied when `sort_by_group = TRUE`.",
          call. = FALSE
        )
      }

      ordering <- order(group)
      elpd_diff <- elpd_diff[ordering]
      group <- group[ordering]
      y <- seq_along(elpd_diff)
    }

    plot_data <- data.frame(
      y = y,
      elpd_diff = elpd_diff
    )
    if (!is.null(group)) {
      plot_data$group <- factor(group)
    }

    plot <- ggplot2::ggplot(
      data = plot_data,
      mapping = ggplot2::aes(x = y, y = elpd_diff)
    ) +
      ggplot2::geom_hline(yintercept = 0) +
      ggplot2::labs(
        x = if (sort_by_group) "Index" else "y",
        y = expression(ELPD[i][1] - ELPD[i][2])
      )

    if (is.null(group)) {
      plot <- plot +
        ggplot2::geom_jitter(
          width = jitter,
          height = 0,
          alpha = alpha,
          size = size
        )
    } else {
      plot <- plot +
        ggplot2::geom_jitter(
          ggplot2::aes(color = group),
          width = jitter,
          height = 0,
          alpha = alpha,
          size = size
        ) +
        ggplot2::labs(color = "Groups")
    }

    plot
  }
