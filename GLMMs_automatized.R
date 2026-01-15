# Analysis script for Julia (ce3c)
# Author: Sara & Julia
# Date: 2025-10-03
# ============================================================
# Modified by: Daniela
# Date: 2025-11-14

# ---- Libraries ----
library(glmmTMB)
library(lmodel2)
library(car)
library(effects)
library(emmeans)
library(DHARMa)
library(ggeffects)
library(ggplot2)
library(patchwork)
library(interactions)
library(grid)
library(survival)
library(survminer)
library(readr)
library(readxl)
library(plyr)
library(jtools)
library(here)
library(sjPlot)
library(dplyr)
library(rlang)
# ---- Functions ----

#main effect overall
main_effects1 <- function (a){
  fml <- reformulate(a)
  effects.a <- emmeans(best_gr_model, fml)
  print(effects.a)
  print("------------------------------------")
  print(test(pairs(effects.a), joint = TRUE))
  print("------------------------------------")
  pairs(effects.a, adjust='bonferroni')
}

#main effect at each level
main_effects2 <- function (a,b){
  fml <- as.formula(paste("~", a, "|", b))
  effects.a.b <- emmeans(best_gr_model, fml)
  print(effects.a.b)
  print("------------------------------------")
  print(test(pairs(effects.a.b), joint =TRUE))
  print("------------------------------------")
  pairs(effects.a.b, adjust='bonferroni')
}

#function growth rate graph variables (pred, mod2, ylab, xlab, metric_name, data, path_png)
growth_r <- function(a, b, ylab, xlab, metric_name, data, png_path) {
  a_name <- deparse(substitute(a))
  b_name <- deparse(substitute(b))
  
  png(filename = paste0(png_path,
                        metric_name, "_", a_name, "_GLMMs.png"),
      width = 1024, height = 768)
  
  graph.growth.rate <- interactions::cat_plot(
    model = best_gr_model,
    data = data,
    pred = !!sym(a_name),
    modx = Diet,
    mod2 = !!sym(b_name),
    geom = "line",
    size = 1,
    error.width = 1,
    dodge.width = 0.5,
    panel = TRUE
  ) +
    ylab(ylab) +
    xlab(xlab) +
    scale_color_manual(
      name = "Diet",
      values = c("#740000", "#DAA520", "#4F734E")
    ) +
    theme_bw() +
    theme(
      panel.grid = element_blank(),
      panel.border = element_blank(),
      axis.line = element_line(color = "black"),
      strip.background = element_blank(),
      strip.text = element_text(face = "italic", size = 12)
    ) +
    facet_wrap(as.formula(paste("~", b_name)), labeller = ggplot2::label_value)
  
  print(graph.growth.rate)
  dev.off()
}

#function variables (a= metadata_path, b=sep, c= metric_name, d=growth_rate_ylab, e= png_path)
run <- function (metadata_path, sep, metric_name, growth_rate_ylab, png_path){
  # ---- Load Data ----
  #Bruno
  data <- read.table(metadata_path, sep = sep, header = TRUE)
  metric_col <- metric_name
  summary(data)
  
  #take out rows with NaN
  data <- data[!is.na(data[[metric_col]]), ]
  data[[metric_col]] <- data[[metric_col]] * 0.01
  # ---- Factor and Numeric Conversions ----
  data <- data %>%
    mutate(
      Temp = as.factor(temp),
      Diet = as.factor(diet),
      Pho = as.factor(P),
      W_46 = as.numeric(w_46),
      Box = as.factor(box)
    )
  
  # ---- Growth Rate Analysis ----
  # Best model selected
  best_gr_model <<- glmmTMB(formula(paste0(metric_col, " ~ Temp * Diet * Pho + W_46 + (1|Box)")) , data=data)
  print("____________________________________________________")
  print("ANOVA Results:")
  print(Anova(best_gr_model, type = 2))
  print("____________________________________________________")
  #Welch's ANOVA
  oneway.test(formula(paste0(metric_col, " ~ Temp * Diet * Pho")), data=data, var.equal = FALSE)
  
  # Summary of model coefficients
  print("____________________________________________________")
  print("GLMM Results:")
  print(summary(best_gr_model))
  print("____________________________________________________")
  
  # Residual diagnostics for best_gr_model
  par(mfrow = c(1, 1))
  
  # Simulate residuals
  residuals_gr <- simulateResiduals(fittedModel = best_gr_model, quantreg = TRUE)
  
  # Formal residual tests
  residual_tests <- testResiduals(residuals_gr)
  print(residual_tests) # Uniformity p = 0.97742 | Overdispersion p = 0.936 | Outliers p = 0.08476
  
  plotResiduals(residuals_gr, form = data$Temp,
                main = "Residuals vs Temperature") 
  plotResiduals(residuals_gr, form = data$Diet,
                main = "Residuals vs Diet") 
  plotResiduals(residuals_gr, form = data$Pho,
                main = "Residuals vs Pho") 
  plotResiduals(residuals_gr, form = data$Box,
                main = "Residuals vs Box") 
  
  # Estimated marginal means and post hoc comparisons
  # Main effect of Temperature
  print(main_effects1("Temp"))
  
  # Main effect of Diet
  print(main_effects1("Diet"))
  
  # Main effect of Pho
  print(main_effects1("Pho"))
  
  # Diet effect at each level of Temperature
  print(main_effects2("Diet","Temp"))
  
  # Temperature effect at each level of Diet
  print(main_effects2("Temp","Diet"))
  
  # Pop effect at each level of Diet
  print(main_effects2("Pho","Diet"))
  
  # Pop effect at each level of Temp
  print(main_effects2("Pho","Temp"))
  
  # Diet effect at each level of Pho
  print(main_effects2("Diet","Pho"))
  
  # Temperature effect at each level of Pho
  print(main_effects2("Temp","Pho"))
  
  # Growth rate
  print(growth_r(Pho, Temp, growth_rate_ylab, "Phosphorus", metric_name, data, png_path))
  print(growth_r(Temp, Pho, growth_rate_ylab, "Temperature Cº", metric_name, data, png_path))
  
}

#only alter this one 
#Observed_features
print(run("//wsl.localhost/Ubuntu/home/ddeodato/tese/20251004/images_results/teste/Metadata_observed_features.csv",
          ",", 
          "observed_features", 
          "Observed_features diversity (x 0.01)",
          "E:/Estágio/results/20251004/new_results/GMMLs/"))
#Shannon
print(run("//wsl.localhost/Ubuntu/home/ddeodato/tese/20251004/images_results/teste/Metadata_shannon.csv",
          ",", 
          "shannon", 
          "Shannon diversity",
          "E:/Estágio/results/20251004/new_results/GMMLs/"))
#Evenness
print(run("//wsl.localhost/Ubuntu/home/ddeodato/tese/20251004/images_results/teste/metadata_evenness.csv",
          "\t", 
          "pielou_evenness", 
          "pielou's evenness",
          "E:/Estágio/results/20251004/new_results/GMMLs/"))

#faithPD
print(run("//wsl.localhost/Ubuntu/home/ddeodato/tese/20251004/images_results/teste/metadata_faith.csv",
          "\t", 
          "faith_pd", 
          "Faith PD",
          "E:/Estágio/results/20251004/new_results/GMMLs/"))
