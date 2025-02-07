library(shiny)
library(dplyr)
library(ggplot2)
library(ggtext)
library(tibble)
library(ragg)
library(scales)


ui <- fluidPage(
  sidebarLayout(
      mainPanel(
      plotOutput(outputId = "distPlot",width = "400px", height = "400px")
    ),
    
    sidebarPanel(
      div(style="display: inline-block; width: 200px;",
      sliderInput(
        inputId = "x",
        label = HTML("Score (<i>X</i>)"),
        min = 40,
        max = 160,
        value = 120,
        step = 1
      )),
      div(style="display: inline-block; width: 200px;",
          sliderInput(
        inputId = "my_rxx",
        label = shiny::HTML("Reliability (<i>r<sub>XX</sub></i>)"),
        min = 0,
        max = 1,
        value = .9,
        step = .01
      )),
      shiny::tags$br(),
      div(style="display: inline-block; width: 75px;",
      numericInput(
        inputId = "mu",
        label = "Mean",
        min = 0,
        max = 100,
        value = 100,
        step = 1
      )),
      div(style="display: inline-block; width: 75px;",
      numericInput(
        inputId = "sigma",
        label = "SD",
        min = 1,
        max = 15,
        value = 15, 
        step = 1
      ))
    )
    
  )
)
server <- function(input, output, session) {
  output$distPlot <- renderPlot({
    mu <- input$mu
    sigma <- input$sigma
    my_rxx <- input$my_rxx
    x <- input$x
    observe(updateSliderInput(session, "x", max = input$mu + input$sigma * 4, min = input$mu - input$sigma * 4))
    # mu = 100
    # sigma = 15
    # my_rxx  = .9
    # x = 120

p <- .95
z <- (x - mu)  / sigma
z_ci <- qnorm(1 - (1 - p) / 2)
rxx = c(seq(0,.019,.001),seq(.02,.98,.01), seq(.981,1,.001))
rxx_rev <- rev(rxx)
lb <- sigma * (z * rxx - z_ci * sqrt(rxx - rxx ^ 2)) + mu
ub <- sigma * (z * rxx_rev + z_ci * sqrt(rxx_rev - rxx_rev ^ 2)) + mu


my_see <- sigma * sqrt(my_rxx - my_rxx ^ 2)
my_moe <- z_ci * my_see
my_tau <- sigma * z * my_rxx  + mu
my_lb <- sigma * z * my_rxx - my_moe + mu
my_ub <- sigma * z * my_rxx + my_moe + mu

my_xhat <- (x - mu) * sqrt(my_rxx) + mu
my_see2 <- sqrt(1 - my_rxx) 
my_moe2 <- z_ci * my_see2
my_lb2 <- my_xhat - my_moe2
my_ub2 <- my_xhat + my_moe2

lb2 <- sigma * (z * sqrt(rxx) - z_ci * sqrt(1 - rxx )) + mu
ub2 <- sigma * (z * sqrt(rxx_rev) + z_ci * sqrt(1 - rxx_rev)) + mu


d_arrow <- tibble(Reliability = my_rxx, 
                  ci = c(my_lb, my_ub))



tibble(Reliability = c(rxx, rxx_rev),
       ci = c(lb, ub),
       ci2 = c(lb2, ub2)) %>% 
  ggplot(aes(Reliability, ci)) +
  geom_polygon(fill = "dodgerblue4", alpha = .2, aes(y = ci2)) +
  geom_polygon(fill = "dodgerblue3", alpha = .5) + 
  ggnormalviolin::geom_normalviolin(data = tibble(mu = my_tau, x = my_rxx, sigma = my_see), fill = "black", p_tail = .05, aes(x = x, mu = mu, sigma = sigma, width = .15, face_left = F), inherit.aes = F, color = NA, alpha = .3) +
  scale_x_continuous("Reliability Coefficient", breaks = seq(0,1,.2), labels = c("0", ".20", ".40", ".60", ".80", "1"), expand = expansion(add = .09)) + 
  scale_y_continuous("Score", breaks = -4:4 * sigma + mu, 
                     minor_breaks = seq(-4 * sigma + mu, 
                                        4 * sigma + mu,
                                        ifelse((sigma %% 3) == 0, 
                                               sigma / 3, 
                                               sigma / 2)) ) + 
  coord_fixed(ratio = 1 / (sigma * 8),
              ylim = c(-4 * sigma + mu, 4 * sigma + mu),
              clip = "off") +
  theme_minimal(16, "sans") +
  theme(panel.spacing.x = unit(5, "mm")) +
  geom_line(data = d_arrow) +
  geom_text(data = d_arrow,
            aes(label = scales::number(ci, .1), x = Reliability - .02),
            hjust = 1,
            family = "sans") +
  annotate(
    "richtext",
    x = my_rxx + .02,
    y = x,
    hjust = 0,
    label = paste0("*X* = ", x),
    color = "firebrick",
    family = "sans"
  ) +
  annotate(
    "text",
    x = my_rxx - .02,
    y = my_tau,
    hjust = 1,
    label = scales::number(my_tau, .1),
    family = "sans"
  ) +
  annotate("point", x = my_rxx, y = my_tau) +
  annotate("point", x = my_rxx, y = x, size = 3, color = "firebrick") + 
  ggtitle(paste0("Confidence Interval Width = ", scales::number(my_ub - my_lb, .1)))
  
    
  })
}
shinyApp(ui = ui, server = server)
