
viz_void <- ggplot2::ggplot() + ggplot2::theme_void()

dir_logo <- getwd()
if(!exists(dir_logo)) {
  dir.create(dir_logo, recursive = TRUE)
}
path_logo <- file.path(dir_logo, paste0("logo.png"))
hexSticker::sticker(
  subplot = viz_void,
  package = "te",
  filename = path_logo,
  p_y = 1.0,
  p_color = "black",
  # p_family = "sans",
  p_size = 60,
  h_size = 1.5,
  h_color = "black",
  h_fill = "#bd93f9"
)
logo <- magick::image_read(path_logo)
magick::image_write(magick::image_scale(logo, "518"), path = path_logo)
