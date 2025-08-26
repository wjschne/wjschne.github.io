# from https://themockup.blog/posts/2022-11-08-use-r-to-generate-a-quarto-blogpost/
new_post <- function(
  title,
  file = "index.qmd",
  description = "",
  author = "W. Joel Schneider",
  date = Sys.Date(),
  draft = FALSE,
  title_limit = 40,
  open_file = TRUE
) {
  # convert to kebab case and remove non space or alphanumeric characters
  title_kebab <- stringr::str_to_lower(title) |>
    stringr::str_remove_all("[^[:alnum:][:space:]]") |>
    stringr::str_replace_all(" ", "-")

  # warn if a very long slug
  if (nchar(title_kebab) >= title_limit) {
    cli::cli_alert_warning(
      "Warning: Title slug is longer than {.val {title_limit}} characters!"
    )
  }

  # generate the slug as draft, prefix with _ which prevents
  # quarto from rendering/recognizing the folder
  if (draft) {
    slug <- glue::glue("posts/_{date}-{title_kebab}")
    cli::cli_alert_info(
      "Appending a '_' to folder name to avoid render while a draft, remove '_' when finished."
    )
  } else {
    slug <- glue::glue("posts/{date}-{title_kebab}")
  }

  # create and alert about directory
  fs::dir_create(
    path = slug
  )
  cli::cli_alert_success("Folder created at {.file {slug}}")

  # wrap description at 77 characters
  description <- stringr::str_wrap(description, width = 77) |>
    stringr::str_replace_all("[\n]", "\n  ")

  # start generating file
  new_post_file <- glue::glue("{slug}/{file}")

  # build yaml core
  new_post_core <- c(
    "---",
    glue::glue('title: "{title}"'),
    "description: |",
    glue::glue('  {description}'),
    glue::glue("author: {author}"),
    glue::glue("date: {date}")
  )

  # add draft if draft
  if (draft) {
    new_post_text <- c(
      new_post_core,
      "draft: true",
      "---\n"
    )
  } else {
    new_post_text <- c(
      new_post_core,
      "---\n"
    )
  }

  # finalize new post text
  new_post_text <- paste0(
    new_post_text,
    collapse = "\n"
  )

  # create file and alert
  fs::file_create(new_post_file)
  cli::cli_alert_success("File created at {.file {new_post_file}}")

  # print new post information
  cat(new_post_text)

  if (yesno::yesno2("Are you ready to write that to disk?")) {
    writeLines(
      text = new_post_text,
      con = new_post_file
    )

    rstudioapi::documentOpen(new_post_file, line = length(new_post_text))
  }
}

new_post(
  "Making a custom arrowhead for ggplot2 using ggarrow",
  description = "The ggarrow package allows any polygon to be an arrowhead.",
  draft = FALSE
)
