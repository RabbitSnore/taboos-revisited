################################################################################

# Taboos and Self-Censorship, Revisited

################################################################################

# Set up environment -----------------------------------------------------------

packages <- c("tidyverse",
              "lme4",
              "lmerTest",
              "osfr",
              "performance",
              "lcmm",
              "cowplot",
              "ggbeeswarm")

lapply(packages, library, character.only = TRUE)

# Load data --------------------------------------------------------------------

# Retrieve data from OSF

if (!dir.exists("data")) {
  
  dir.create("data")
  
}

if (!file.exists("data/Taboos Data_share.csv")) {
  
  osf_retrieve_file("65eb2a55e5e51c0983bc53cf") %>% 
    osf_download(
      path = "data"
    )
  
}

# Load data

taboo <- read_csv("data/Taboos Data_Share.csv")

## Add ID column

taboo$id <- 1:nrow(taboo)

# Data wrangling ---------------------------------------------------------------

# Long form data

colnames(taboo) <- str_replace(colnames(taboo), "Rel_1", "Rel__1")

taboo_long <- taboo %>% 
  pivot_longer(
    cols      = c(ends_with("FT__1"), ends_with("Rel__1")),
    names_to  = c("statement", "measure"),
    names_pattern = "(.*)_(.*__1)",
    values_to = "value"
  ) %>% 
  mutate(
    measure = case_when(
      measure == "FT__1"         ~ "belief",
      measure == "Rel__1" ~ "self_censor"
    )
  ) %>% 
  pivot_wider(
    id_cols     = c("id", "statement"),
    names_from  = "measure",
    values_from = "value"
  )

taboo_long_rev <- taboo_long %>% 
  mutate(
    belief = case_when(
      statement == "AcBlack" ~ 100 - belief,
      TRUE                   ~ belief
    )
  )

# Mean centering

taboo_long_mc <- taboo_long_rev %>% 
  group_by(statement) %>% 
  mutate(
    belief_mc = as.numeric(scale(belief, scale = FALSE))
  ) %>% 
  ungroup()

# Analysis ---------------------------------------------------------------------

# Unconditional model

lmm_sc_00 <- lmer(self_censor
                  ~ 1
                  + (1 | id)
                  + (1 | statement),
                  data = taboo_long_rev,
                  control = lmerControl(
                    optimizer = "bobyqa"
                  ))

icc_sc_00 <- icc(lmm_sc_00, by_group = TRUE)

# Belief and self-censorship

lmm_sc_01 <- lmer(self_censor
                  ~ 1
                  + belief
                  + (1 + belief | id)
                  + (1 + belief | statement),
                  data = taboo_long_rev,
                  control = lmerControl(
                    optimizer = "bobyqa"
                  ))

r2_sc_01 <- r2_nakagawa(lmm_sc_01)

# Removing random slopes

lmm_sc_red <- lmer(self_censor
                   ~ 1
                   + belief
                   + (1 | id)
                   + (1 | statement),
                   data = taboo_long_rev,
                   control = lmerControl(
                     optimizer = "bobyqa"
                   ))

r2_sc_red <- r2_nakagawa(lmm_sc_red)

# Polynomial regression

lmm_sc_pl <- lmer(self_censor
                  ~ 1
                  + poly(belief, 2)
                  + (1 + poly(belief, 2) | id)
                  + (1 + poly(belief, 2) | statement),
                  data = taboo_long_rev %>% 
                    filter(complete.cases(.)),
                  control = lmerControl(
                    optimizer = "bobyqa"
                  ))

r2_sc_pl <- r2_nakagawa(lmm_sc_pl)

# Latent class analysis

taboo_long_rev$id_1 <- as.numeric(taboo_long_rev$id)

set.seed(777)

## Linear classes

if (!file.exists("output/taboos_lcmm_sc_06.rds")) {
  
  lcmm_sc_01   <- hlme(fixed   = self_censor ~ belief,
                       random  = ~ statement,
                       subject = "id_1",
                       ng      = 1,
                       data    = taboo_long_rev)
  
  lcmm_sc_02   <- hlme(fixed   = self_censor ~ belief,
                       random  = ~ statement,
                       subject = "id_1",
                       ng      = 2,
                       mixture = ~ belief,
                       data    = taboo_long_rev,
                       B       = lcmm_sc_01)
  
  lcmm_sc_03   <- hlme(fixed   = self_censor ~ belief,
                       random  = ~ statement,
                       subject = "id_1",
                       ng      = 3,
                       mixture = ~ belief,
                       data    = taboo_long_rev,
                       B       = lcmm_sc_01)
  
  lcmm_sc_04   <- hlme(fixed   = self_censor ~ belief,
                       random  = ~ statement,
                       subject = "id_1",
                       ng      = 4,
                       mixture = ~ belief,
                       data    = taboo_long_rev,
                       B       = lcmm_sc_01)
  
  lcmm_sc_05   <- hlme(fixed   = self_censor ~ belief,
                       random  = ~ statement,
                       subject = "id_1",
                       ng      = 5,
                       mixture = ~ belief,
                       data    = taboo_long_rev,
                       B       = lcmm_sc_01, 
                       maxiter = 5000000,
                       convB   = .01,
                       convL   = .01,
                       convG   = .01)
  
  lcmm_sc_06   <- hlme(fixed   = self_censor ~ belief,
                       random  = ~ statement,
                       subject = "id_1",
                       ng      = 6,
                       mixture = ~ belief,
                       data    = taboo_long_rev,
                       B       = lcmm_sc_01)
  
  ### Save output
  
  saveRDS(lcmm_sc_01,
          "output/taboos_lcmm_sc_01.rds")
  saveRDS(lcmm_sc_02,
          "output/taboos_lcmm_sc_02.rds")
  saveRDS(lcmm_sc_03,
          "output/taboos_lcmm_sc_03.rds")
  saveRDS(lcmm_sc_04,
          "output/taboos_lcmm_sc_04.rds")
  saveRDS(lcmm_sc_05,
          "output/taboos_lcmm_sc_05.rds")
  saveRDS(lcmm_sc_06,
          "output/taboos_lcmm_sc_06.rds")
  
} else {
  
  lcmm_sc_01 <- readRDS("output/taboos_lcmm_sc_01.rds")
  lcmm_sc_02 <- readRDS("output/taboos_lcmm_sc_02.rds")
  lcmm_sc_03 <- readRDS("output/taboos_lcmm_sc_03.rds")
  lcmm_sc_04 <- readRDS("output/taboos_lcmm_sc_04.rds")
  lcmm_sc_05 <- readRDS("output/taboos_lcmm_sc_05.rds")
  lcmm_sc_06 <- readRDS("output/taboos_lcmm_sc_06.rds")
  
}

## Polynomial mixtures

if (!file.exists("output/taboos_lcmm_sc_p6.rds")) {
  
  lcmm_sc_p1   <- hlme(fixed   = self_censor ~ poly(belief, 2),
                       random  = ~ statement,
                       subject = "id_1",
                       ng      = 1,
                       data    = taboo_long_rev %>% 
                         filter(complete.cases(.)))
  
  lcmm_sc_p2   <- hlme(fixed   = self_censor ~ poly(belief, 2),
                       random  = ~ statement,
                       subject = "id_1",
                       ng      = 2,
                       mixture = ~ poly(belief, 2),
                       data    = taboo_long_rev %>% 
                         filter(complete.cases(.)),
                       B       = lcmm_sc_p1)
  
  lcmm_sc_p3   <- hlme(fixed   = self_censor ~ poly(belief, 2),
                       random  = ~ statement,
                       subject = "id_1",
                       ng      = 3,
                       mixture = ~ poly(belief, 2),
                       data    = taboo_long_rev %>% 
                         filter(complete.cases(.)),
                       B       = lcmm_sc_p1)
  
  lcmm_sc_p4   <- hlme(fixed   = self_censor ~ poly(belief, 2),
                       random  = ~ statement,
                       subject = "id_1",
                       ng      = 4,
                       mixture = ~ poly(belief, 2),
                       data    = taboo_long_rev %>% 
                         filter(complete.cases(.)),
                       B       = lcmm_sc_p1)
  
  lcmm_sc_p5   <- hlme(fixed   = self_censor ~ poly(belief, 2),
                       random  = ~ statement,
                       subject = "id_1",
                       ng      = 5,
                       mixture = ~ poly(belief, 2),
                       data    = taboo_long_rev %>% 
                         filter(complete.cases(.)),
                       B       = lcmm_sc_p1)
  
  lcmm_sc_p6   <- hlme(fixed   = self_censor ~ poly(belief, 2),
                       random  = ~ statement,
                       subject = "id_1",
                       ng      = 6,
                       mixture = ~ poly(belief, 2),
                       data    = taboo_long_rev %>% 
                         filter(complete.cases(.)),
                       B       = lcmm_sc_p1)
  
  ### Save output
  
  saveRDS(lcmm_sc_p1,
          "output/taboos_lcmm_sc_p1.rds")
  saveRDS(lcmm_sc_p2,
          "output/taboos_lcmm_sc_p2.rds")
  saveRDS(lcmm_sc_p3,
          "output/taboos_lcmm_sc_p3.rds")
  saveRDS(lcmm_sc_p4,
          "output/taboos_lcmm_sc_p4.rds")
  saveRDS(lcmm_sc_p5,
          "output/taboos_lcmm_sc_p5.rds")
  saveRDS(lcmm_sc_p6,
          "output/taboos_lcmm_sc_p6.rds")
  
} else {
  
  lcmm_sc_p1 <- readRDS("output/taboos_lcmm_sc_p1.rds")
  lcmm_sc_p2 <- readRDS("output/taboos_lcmm_sc_p2.rds")
  lcmm_sc_p3 <- readRDS("output/taboos_lcmm_sc_p3.rds")
  lcmm_sc_p4 <- readRDS("output/taboos_lcmm_sc_p4.rds")
  lcmm_sc_p5 <- readRDS("output/taboos_lcmm_sc_p5.rds")
  lcmm_sc_p6 <- readRDS("output/taboos_lcmm_sc_p6.rds")
  
}



# Visualizations ---------------------------------------------------------------

# Linear plot

plot_linear <- 
ggplot(taboo_long_rev,
       aes(
         x = belief,
         y = self_censor
       )) +
  geom_point(
    shape = 1
  ) +
  geom_smooth(
    method  = "lm",
    formula = "y ~ x",
    se      = FALSE
  ) +
  labs(
    x = "Belief in Truth of Statement",
    y = "Reluctance"
  ) +
  theme_classic()

save_plot("figures/taboos_linear.png", 
          plot_linear,
          base_height = 4, base_width = 4)

# Polynomial Plot

plot_polynomial <- 
  ggplot(taboo_long_rev,
         aes(
           x = belief,
           y = self_censor
         )) +
  geom_point(
    shape = 1
  ) +
  geom_smooth(
    method  = "lm",
    formula = "y ~ x + I(x^2)",
    se      = FALSE
  ) +
  labs(
    x = "Belief in Truth of Statement",
    y = "Reluctance"
  ) +
  theme_classic()

save_plot("figures/taboos_polynomial.png", 
          plot_polynomial,
          base_height = 4, base_width = 4)

# Combined linear and quadratic plot

plot_linear_quad <- 
  ggplot(taboo_long_rev,
         aes(
           x = belief,
           y = self_censor
         )) +
  geom_point(
    shape = 1
  ) +
  geom_smooth(
    method  = "lm",
    formula = "y ~ x",
    se      = FALSE,
    color   = "#6622CC"
  ) +
  geom_smooth(
    method  = "lm",
    formula = "y ~ x + I(x^2)",
    se      = FALSE,
    color   = "#A755C2"
  ) +
  labs(
    x = "Belief in Truth of Statement",
    y = "Reluctance"
  ) +
  theme_classic()

save_plot("figures/taboos_linear-quad.png", 
          plot_linear_quad,
          base_height = 4, base_width = 4)

# Latent classes

lcmm_pred_data <- expand.grid(
  class       = 1:6,
  belief      = seq(0, 100, 20),
  self_censor = seq(0, 100, 20),
  statement   = unique(taboo_long_rev$statement)
)

lcmm_yhat  <- predictY(lcmm_sc_06, newdata = lcmm_pred_data)

lcmm_hat_data <- bind_cols(lcmm_pred_data, lcmm_yhat$pred)

lcmm_hat_data <- lcmm_hat_data %>% 
  mutate(
    prediction = case_when(
      class == 1 ~ Ypred_class1,
      class == 2 ~ Ypred_class2,
      class == 3 ~ Ypred_class3,
      class == 4 ~ Ypred_class4,
      class == 5 ~ Ypred_class5,
      class == 6 ~ Ypred_class6
    )
  )

lcmm_class_data <- predictClass(lcmm_sc_06, newdata = taboo_long_rev)

taboo_long_poly <- taboo_long_rev # For later use

taboo_long_rev <- taboo_long_rev %>% 
  left_join(lcmm_class_data, by = "id_1")

lcmm_class_summary <- taboo_long_rev %>% 
  group_by(class) %>% 
  summarise(
    mean_belief   = mean(belief, na.rm = TRUE),
    sd_belief     = sd(belief, na.rm = TRUE),
    median_belief = median(belief, na.rm = TRUE),
    min_belief    = min(belief, na.rm = TRUE),
    max_belief    = max(belief, na.rm = TRUE),
    frequency     = n()/10
  ) %>% 
  filter(complete.cases(.))

plot_predict_class <- 
ggplot(lcmm_hat_data,
       aes(
         x = belief,
         y = prediction,
         group = as.factor(class),
         color = as.factor(class)
       )) +
  geom_line(
    linewidth = 1
  ) +
  geom_vline(
    data = lcmm_class_summary,
    aes(
      xintercept = mean_belief,
      color      = as.factor(class)
    ),
    linetype  = "dashed",
    alpha     = .25,
    linewidth = 1
  ) +
  labs(
    x = "Belief in Truth of Statement",
    y = "Reluctance",
    color = "Latent Class"
  ) +
  scale_color_manual(
    values = c("#60AFFF",
               "#43BCCD",
               "#F86624",
               "#EA3546",
               "#662E9B",
               "#7EBC89")
  ) +
  theme_classic()

save_plot("figures/taboos_predict-class.png", 
          plot_predict_class,
          base_height = 4, base_width = 6)

# Polynomial latent classes

lcmm_poly_pred_data <- expand.grid(
  class       = 1:3,
  belief      = seq(0, 100, 10),
  self_censor = seq(0, 100, 10),
  statement   = unique(taboo_long_rev$statement)
)

lcmm_poly_yhat  <- predictY(lcmm_sc_p3, newdata = lcmm_poly_pred_data)

lcmm_poly_hat_data <- bind_cols(lcmm_poly_pred_data, lcmm_poly_yhat$pred)

lcmm_poly_hat_data <- lcmm_poly_hat_data %>% 
  mutate(
    prediction = case_when(
      class == 1 ~ Ypred_class1,
      class == 2 ~ Ypred_class2,
      class == 3 ~ Ypred_class3
    )
  )

lcmm_poly_class_data <- predictClass(lcmm_sc_p3, 
                                     newdata = filter(taboo_long_poly, 
                                                      complete.cases(taboo_long_poly)))

taboo_long_poly <- taboo_long_poly %>% 
  left_join(lcmm_poly_class_data, by = "id_1")

lcmm_poly_class_summary <- taboo_long_poly %>% 
  group_by(class) %>% 
  summarise(
    mean_belief   = mean(belief, na.rm = TRUE),
    sd_belief     = sd(belief, na.rm = TRUE),
    median_belief = median(belief, na.rm = TRUE),
    min_belief    = min(belief, na.rm = TRUE),
    max_belief    = max(belief, na.rm = TRUE),
    frequency     = n()/10
  ) %>% 
  filter(complete.cases(.))

plot_poly_predict_class <- 
  ggplot(lcmm_poly_hat_data,
         aes(
           x = belief,
           y = prediction,
           group = as.factor(class),
           color = as.factor(class)
         )) +
  geom_line(
    linewidth = 1
  ) +
  geom_vline(
    data = lcmm_poly_class_summary,
    aes(
      xintercept = mean_belief,
      color      = as.factor(class)
    ),
    linetype  = "dashed",
    alpha     = .25,
    linewidth = 1
  ) +
  labs(
    x = "Belief in Truth of Statement",
    y = "Reluctance",
    color = "Latent Class"
  ) +
  scale_y_continuous(
    limits = c(0, 100)
  ) +
  scale_color_manual(
    values = c("#60AFFF",
               "#43BCCD",
               "#F86624")
  ) +
  theme_classic()

save_plot("figures/taboos_poly-predict-class.png", 
          plot_poly_predict_class,
          base_height = 4, base_width = 6)


# Individual level effects (linear)

belief_means <- taboo_long_rev %>% 
  group_by(id) %>% 
  summarise(
    mean = mean(belief, na.rm = TRUE)
  ) %>% 
  arrange(mean)

taboo_long_rev$id <- factor(taboo_long_rev$id,
                            levels = belief_means$id)

plot_idio_effects <- 
ggplot(taboo_long_rev,
       aes(
         x = belief,
         y = self_censor,
         color = as.factor(class)
       )) +
  facet_wrap(~ id,
             nrow = 20) +
  geom_point(
    shape = 1
  ) +
  geom_vline(
    xintercept = 50,
    linetype   = "dashed",
    alpha      = .50
  ) +
  geom_hline(
    yintercept = 50,
    linetype   = "dashed",
    alpha      = .50
  ) +
  geom_smooth(
    method  = "lm",
    formula = "y ~ x",
    se      = FALSE
  ) +
  scale_y_continuous(
    limits = c(0, 100)
  ) +
  scale_x_continuous(
    limits = c(0, 100),
    breaks = c(0, 50, 100)
  ) +
  scale_color_manual(
    values = c("#60AFFF",
               "#43BCCD",
               "#F86624",
               "#EA3546",
               "#662E9B")
  ) +
  guides(
    color = "none"
  ) +
  labs(
    x = "Belief in Truth of Statement",
    y = "Reluctance"
  ) +
  theme(
    strip.background = element_blank(),
    strip.text.x     = element_blank()
  )

save_plot("figures/taboos_idio-effects.png", 
          plot_idio_effects,
          base_height = 16, base_width = 18)

# Individual level effects (polynomial)

taboo_long_poly$id <- factor(taboo_long_poly$id,
                             levels = belief_means$id)


plot_idio_effects_poly <- 
ggplot(taboo_long_poly,
       aes(
         x = belief,
         y = self_censor,
         color = as.factor(class)
       )) +
  facet_wrap(~ id,
             nrow = 20) +
  geom_point(
    shape = 1
  ) +
  geom_vline(
    xintercept = 50,
    linetype   = "dashed",
    alpha      = .50
  ) +
  geom_hline(
    yintercept = 50,
    linetype   = "dashed",
    alpha      = .50
  ) +
  geom_smooth(
    method  = "lm",
    formula = "y ~ x + I(x^2)",
    se      = FALSE
  ) +
  scale_y_continuous(
    limits = c(0, 100)
  ) +
  scale_x_continuous(
    limits = c(0, 100),
    breaks = c(0, 50, 100)
  ) +
  scale_color_manual(
    values = c("#60AFFF",
               "#43BCCD",
               "#F86624",
               "#EA3546",
               "#662E9B")
  ) +
  guides(
    color = "none"
  ) +
  labs(
    x = "Belief in Truth of Statement",
    y = "Reluctance"
  ) +
  theme(
    strip.background = element_blank(),
    strip.text.x     = element_blank(),
    axis.text        = element_text(size = 8)
  )

save_plot("figures/taboos_idio-effects-poly.png", 
          plot_idio_effects_poly,
          base_height = 13, base_width = 15)

## Displaying individual patterns with latent classes overlaid

plot_idio_class <- 
ggplot(taboo_long_poly %>% 
         filter(!is.na(class)),
       aes(
         x     = belief,
         y     = self_censor
       )) +
  facet_wrap(~ class) +
  geom_vline(
    xintercept = 50,
    linetype   = "dashed",
    alpha      = .50
  ) +
  geom_hline(
    yintercept = 50,
    linetype   = "dashed",
    alpha      = .50
  ) +
  geom_line(
    aes(
      group = id
    ),
    alpha = .20
  ) +
  geom_point(
    shape = 1,
    size  = 1
  ) +
  geom_line(
    data = lcmm_poly_hat_data,
    aes(
      x = belief,
      y = prediction,
      group = as.factor(class),
      color = as.factor(class)
    ),
    linewidth = 2
  ) +
  scale_y_continuous(
    limits = c(0, 100)
  ) +
  scale_x_continuous(
    limits = c(0, 100),
    breaks = c(0, 25, 50, 75, 100)
  ) +
  scale_color_manual(
    values = c("#60AFFF",
               "#43BCCD",
               "#F86624",
               "#EA3546",
               "#662E9B")
  ) +
  guides(
    color = "none"
  ) +
  labs(
    x = "Belief in Truth of Statement",
    y = "Reluctance"
  ) +
  theme_classic()

save_plot("figures/taboos_idio-class.png", 
          plot_idio_class,
          base_height = 3, base_width = 8)

# Perceived Risks of Expressing Views ------------------------------------------

# Unadjusted Perceived Risks

taboo_class <- taboo %>% 
  left_join(lcmm_poly_class_data, by = c("id" = "id_1"))

taboo_class_risk <- taboo_class %>% 
  pivot_longer(
    cols      = starts_with("OpenRisks"),
    names_to  = "risk",
    values_to = "risk_rating"
  )

risk_labels <- c(
  OpenRisks__1 = "Being ostracized by some peers",
  OpenRisks__2 = "Career damaging biases",
  OpenRisks__3 = "Being stigmatized or labeled pejorative terms",
  OpenRisks__4 = "Disciplinary actions",
  OpenRisks__5 = "Guilt-by-association harm", 
  OpenRisks__6 = "Being fired", 
  OpenRisks__7 = "Being attacked on social media",
  OpenRisks__8 = "Student boycotts",
  OpenRisks__9 = "Threats of physical violence"
)

summary_risk <- taboo_class_risk %>% 
  group_by(class, risk) %>% 
  summarise(
    mean  = mean(risk_rating, na.rm = TRUE),
    se    = sd(risk_rating, na.rm = TRUE)/sqrt(n()),
    ci_lb = mean - se*qnorm(.975),
    ci_ub = mean + se*qnorm(.975)
  )

plot_class_risks <- 
ggplot(taboo_class_risk,
       aes(
         x = class,
         y = risk_rating
       )) +
  facet_wrap(~ risk,
             labeller = labeller(risk = risk_labels)) +
  geom_quasirandom(
    shape = 1,
    alpha = .50
  ) +
  geom_errorbar(
    data = summary_risk,
    aes(
      y    = mean,
      ymin = ci_lb,
      ymax = ci_ub
    ),
    width     = .33,
    linewidth = 1
  ) +
  geom_line(
    data = summary_risk,
    aes(
      y     = mean,
      group = 1
    ),
    linewidth = 1
  ) +
  labs(
    x = "Latent Class",
    y = "Perceived Risk"
  ) +
  theme_classic()

save_plot("figures/taboos_class_risk.png", 
          plot_class_risks,
          base_height = 7, base_width = 9)

# Polynomial regression residuals (partialling out belief)

taboo_class_subset <- taboo_class %>% 
  select(id, ends_with("FT__1"), starts_with("OpenRisks"), class) %>% 
  filter(complete.cases(.))

lm_risk_01 <- lm(OpenRisks__1
                 ~ 1
                 + poly(SCBEvo_FT__1, 2)   
                 + poly(STEM_FT__1, 2)      
                 + poly(AcBlack_FT__1, 2)   
                 + poly(Binary_FT__1, 2)    
                 + poly(Cons_FT__1, 2)      
                 + poly(Crime_FT__1, 2)     
                 + poly(MFEvo_FT__1, 2)     
                 + poly(RaceIQ_FT__1, 2)    
                 + poly(TransSI_FT__1, 2)   
                 + poly(Divers_FT__1, 2),
                 data = taboo_class_subset)

lm_risk_02 <- lm(OpenRisks__2
                 ~ 1
                 + poly(SCBEvo_FT__1, 2)   
                 + poly(STEM_FT__1, 2)      
                 + poly(AcBlack_FT__1, 2)   
                 + poly(Binary_FT__1, 2)    
                 + poly(Cons_FT__1, 2)      
                 + poly(Crime_FT__1, 2)     
                 + poly(MFEvo_FT__1, 2)     
                 + poly(RaceIQ_FT__1, 2)    
                 + poly(TransSI_FT__1, 2)   
                 + poly(Divers_FT__1, 2),
                 data = taboo_class_subset)

lm_risk_03 <- lm(OpenRisks__3
                 ~ 1
                 + poly(SCBEvo_FT__1, 2)   
                 + poly(STEM_FT__1, 2)      
                 + poly(AcBlack_FT__1, 2)   
                 + poly(Binary_FT__1, 2)    
                 + poly(Cons_FT__1, 2)      
                 + poly(Crime_FT__1, 2)     
                 + poly(MFEvo_FT__1, 2)     
                 + poly(RaceIQ_FT__1, 2)    
                 + poly(TransSI_FT__1, 2)   
                 + poly(Divers_FT__1, 2),
                 data = taboo_class_subset)

lm_risk_04 <- lm(OpenRisks__4
                 ~ 1
                 + poly(SCBEvo_FT__1, 2)   
                 + poly(STEM_FT__1, 2)      
                 + poly(AcBlack_FT__1, 2)   
                 + poly(Binary_FT__1, 2)    
                 + poly(Cons_FT__1, 2)      
                 + poly(Crime_FT__1, 2)     
                 + poly(MFEvo_FT__1, 2)     
                 + poly(RaceIQ_FT__1, 2)    
                 + poly(TransSI_FT__1, 2)   
                 + poly(Divers_FT__1, 2),
                 data = taboo_class_subset)

lm_risk_05 <- lm(OpenRisks__5
                 ~ 1
                 + poly(SCBEvo_FT__1, 2)   
                 + poly(STEM_FT__1, 2)      
                 + poly(AcBlack_FT__1, 2)   
                 + poly(Binary_FT__1, 2)    
                 + poly(Cons_FT__1, 2)      
                 + poly(Crime_FT__1, 2)     
                 + poly(MFEvo_FT__1, 2)     
                 + poly(RaceIQ_FT__1, 2)    
                 + poly(TransSI_FT__1, 2)   
                 + poly(Divers_FT__1, 2),
                 data = taboo_class_subset)

lm_risk_06 <- lm(OpenRisks__6
                 ~ 1
                 + poly(SCBEvo_FT__1, 2)   
                 + poly(STEM_FT__1, 2)      
                 + poly(AcBlack_FT__1, 2)   
                 + poly(Binary_FT__1, 2)    
                 + poly(Cons_FT__1, 2)      
                 + poly(Crime_FT__1, 2)     
                 + poly(MFEvo_FT__1, 2)     
                 + poly(RaceIQ_FT__1, 2)    
                 + poly(TransSI_FT__1, 2)   
                 + poly(Divers_FT__1, 2),
                 data = taboo_class_subset)

lm_risk_07 <- lm(OpenRisks__7
                 ~ 1
                 + poly(SCBEvo_FT__1, 2)   
                 + poly(STEM_FT__1, 2)      
                 + poly(AcBlack_FT__1, 2)   
                 + poly(Binary_FT__1, 2)    
                 + poly(Cons_FT__1, 2)      
                 + poly(Crime_FT__1, 2)     
                 + poly(MFEvo_FT__1, 2)     
                 + poly(RaceIQ_FT__1, 2)    
                 + poly(TransSI_FT__1, 2)   
                 + poly(Divers_FT__1, 2),
                 data = taboo_class_subset)

lm_risk_08 <- lm(OpenRisks__8
                 ~ 1
                 + poly(SCBEvo_FT__1, 2)   
                 + poly(STEM_FT__1, 2)      
                 + poly(AcBlack_FT__1, 2)   
                 + poly(Binary_FT__1, 2)    
                 + poly(Cons_FT__1, 2)      
                 + poly(Crime_FT__1, 2)     
                 + poly(MFEvo_FT__1, 2)     
                 + poly(RaceIQ_FT__1, 2)    
                 + poly(TransSI_FT__1, 2)   
                 + poly(Divers_FT__1, 2),
                 data = taboo_class_subset)

lm_risk_09 <- lm(OpenRisks__9
                 ~ 1
                 + poly(SCBEvo_FT__1, 2)   
                 + poly(STEM_FT__1, 2)      
                 + poly(AcBlack_FT__1, 2)   
                 + poly(Binary_FT__1, 2)    
                 + poly(Cons_FT__1, 2)      
                 + poly(Crime_FT__1, 2)     
                 + poly(MFEvo_FT__1, 2)     
                 + poly(RaceIQ_FT__1, 2)    
                 + poly(TransSI_FT__1, 2)   
                 + poly(Divers_FT__1, 2),
                 data = taboo_class_subset)

taboo_class_subset$open_risk_res_01 <- residuals(lm_risk_01)
taboo_class_subset$open_risk_res_02 <- residuals(lm_risk_02)
taboo_class_subset$open_risk_res_03 <- residuals(lm_risk_03)
taboo_class_subset$open_risk_res_04 <- residuals(lm_risk_04)
taboo_class_subset$open_risk_res_05 <- residuals(lm_risk_05)
taboo_class_subset$open_risk_res_06 <- residuals(lm_risk_06)
taboo_class_subset$open_risk_res_07 <- residuals(lm_risk_07)
taboo_class_subset$open_risk_res_08 <- residuals(lm_risk_08)
taboo_class_subset$open_risk_res_09 <- residuals(lm_risk_09)

taboo_class_risk_res <- taboo_class_subset %>% 
  pivot_longer(
    cols      = starts_with("open_risk_"),
    names_to  = "risk",
    values_to = "risk_res_rating"
  )

risk_labels_res <- c(
  open_risk_res_01 = "Being ostracized by some peers",
  open_risk_res_02 = "Career damaging biases",
  open_risk_res_03 = "Being stigmatized or labeled pejorative terms",
  open_risk_res_04 = "Disciplinary actions",
  open_risk_res_05 = "Guilt-by-association harm", 
  open_risk_res_06 = "Being fired", 
  open_risk_res_07 = "Being attacked on social media",
  open_risk_res_08 = "Student boycotts",
  open_risk_res_09 = "Threats of physical violence"
)

summary_risk_res <- taboo_class_risk_res %>% 
  group_by(class, risk) %>% 
  summarise(
    mean  = mean(risk_res_rating),
    se    = sd(risk_res_rating)/sqrt(n()),
    ci_lb = mean - se*qnorm(.975),
    ci_ub = mean + se*qnorm(.975)
  )

plot_resid_class_risks <- 
ggplot(taboo_class_risk_res,
       aes(
         x = class,
         y = risk_res_rating
       )) +
  facet_wrap(~ risk,
             labeller = labeller(risk = risk_labels_res)) +
  geom_hline(
    yintercept = 0,
    linetype   = "dashed"
  ) +
  geom_quasirandom(
    shape = 1,
    alpha = .50
  ) +
  geom_errorbar(
    data = summary_risk_res,
    aes(
      y    = mean,
      ymin = ci_lb,
      ymax = ci_ub
    ),
    width     = .33,
    linewidth = 1
  ) +
  geom_line(
    data = summary_risk_res,
    aes(
      y     = mean,
      group = 1
    ),
    linewidth = 1
  ) +
  labs(
    x = "Latent Class",
    y = "Residual Perceived Risk (Effect of Belief Removed)"
  ) +
  theme_classic()

save_plot("figures/taboos_class_risk_residuals.png", 
          plot_resid_class_risks,
          base_height = 7, base_width = 9)

## Polynomial regressions with class as a predictor

taboo_class_subset$class <- factor(taboo_class_subset$class,
                                   levels = c("2", "1", "3"))

lm_risk_01_cl <- lm(OpenRisks__1
                    ~ 1
                    + poly(SCBEvo_FT__1, 2)   
                    + poly(STEM_FT__1, 2)      
                    + poly(AcBlack_FT__1, 2)   
                    + poly(Binary_FT__1, 2)    
                    + poly(Cons_FT__1, 2)      
                    + poly(Crime_FT__1, 2)     
                    + poly(MFEvo_FT__1, 2)     
                    + poly(RaceIQ_FT__1, 2)    
                    + poly(TransSI_FT__1, 2)   
                    + poly(Divers_FT__1, 2)
                    + class,
                    data = taboo_class_subset)

lm_risk_02_cl <- lm(OpenRisks__2
                    ~ 1
                    + poly(SCBEvo_FT__1, 2)   
                    + poly(STEM_FT__1, 2)      
                    + poly(AcBlack_FT__1, 2)   
                    + poly(Binary_FT__1, 2)    
                    + poly(Cons_FT__1, 2)      
                    + poly(Crime_FT__1, 2)     
                    + poly(MFEvo_FT__1, 2)     
                    + poly(RaceIQ_FT__1, 2)    
                    + poly(TransSI_FT__1, 2)   
                    + poly(Divers_FT__1, 2)
                    + class,
                    data = taboo_class_subset)

lm_risk_03_cl <- lm(OpenRisks__3
                    ~ 1
                    + poly(SCBEvo_FT__1, 2)   
                    + poly(STEM_FT__1, 2)      
                    + poly(AcBlack_FT__1, 2)   
                    + poly(Binary_FT__1, 2)    
                    + poly(Cons_FT__1, 2)      
                    + poly(Crime_FT__1, 2)     
                    + poly(MFEvo_FT__1, 2)     
                    + poly(RaceIQ_FT__1, 2)    
                    + poly(TransSI_FT__1, 2)   
                    + poly(Divers_FT__1, 2)
                    + class,
                    data = taboo_class_subset)

lm_risk_04_cl <- lm(OpenRisks__4
                    ~ 1
                    + poly(SCBEvo_FT__1, 2)   
                    + poly(STEM_FT__1, 2)      
                    + poly(AcBlack_FT__1, 2)   
                    + poly(Binary_FT__1, 2)    
                    + poly(Cons_FT__1, 2)      
                    + poly(Crime_FT__1, 2)     
                    + poly(MFEvo_FT__1, 2)     
                    + poly(RaceIQ_FT__1, 2)    
                    + poly(TransSI_FT__1, 2)   
                    + poly(Divers_FT__1, 2)
                    + class,
                    data = taboo_class_subset)

lm_risk_05_cl <- lm(OpenRisks__5
                    ~ 1
                    + poly(SCBEvo_FT__1, 2)   
                    + poly(STEM_FT__1, 2)      
                    + poly(AcBlack_FT__1, 2)   
                    + poly(Binary_FT__1, 2)    
                    + poly(Cons_FT__1, 2)      
                    + poly(Crime_FT__1, 2)     
                    + poly(MFEvo_FT__1, 2)     
                    + poly(RaceIQ_FT__1, 2)    
                    + poly(TransSI_FT__1, 2)   
                    + poly(Divers_FT__1, 2)
                    + class,
                    data = taboo_class_subset)

lm_risk_06_cl <- lm(OpenRisks__6
                    ~ 1
                    + poly(SCBEvo_FT__1, 2)   
                    + poly(STEM_FT__1, 2)      
                    + poly(AcBlack_FT__1, 2)   
                    + poly(Binary_FT__1, 2)    
                    + poly(Cons_FT__1, 2)      
                    + poly(Crime_FT__1, 2)     
                    + poly(MFEvo_FT__1, 2)     
                    + poly(RaceIQ_FT__1, 2)    
                    + poly(TransSI_FT__1, 2)   
                    + poly(Divers_FT__1, 2)
                    + class,
                    data = taboo_class_subset)

lm_risk_07_cl <- lm(OpenRisks__7
                    ~ 1
                    + poly(SCBEvo_FT__1, 2)   
                    + poly(STEM_FT__1, 2)      
                    + poly(AcBlack_FT__1, 2)   
                    + poly(Binary_FT__1, 2)    
                    + poly(Cons_FT__1, 2)      
                    + poly(Crime_FT__1, 2)     
                    + poly(MFEvo_FT__1, 2)     
                    + poly(RaceIQ_FT__1, 2)    
                    + poly(TransSI_FT__1, 2)   
                    + poly(Divers_FT__1, 2)
                    + class,
                    data = taboo_class_subset)

lm_risk_08_cl <- lm(OpenRisks__8
                    ~ 1
                    + poly(SCBEvo_FT__1, 2)   
                    + poly(STEM_FT__1, 2)      
                    + poly(AcBlack_FT__1, 2)   
                    + poly(Binary_FT__1, 2)    
                    + poly(Cons_FT__1, 2)      
                    + poly(Crime_FT__1, 2)     
                    + poly(MFEvo_FT__1, 2)     
                    + poly(RaceIQ_FT__1, 2)    
                    + poly(TransSI_FT__1, 2)   
                    + poly(Divers_FT__1, 2)
                    + class,
                    data = taboo_class_subset)

lm_risk_09_cl <- lm(OpenRisks__9
                    ~ 1
                    + poly(SCBEvo_FT__1, 2)   
                    + poly(STEM_FT__1, 2)      
                    + poly(AcBlack_FT__1, 2)   
                    + poly(Binary_FT__1, 2)    
                    + poly(Cons_FT__1, 2)      
                    + poly(Crime_FT__1, 2)     
                    + poly(MFEvo_FT__1, 2)     
                    + poly(RaceIQ_FT__1, 2)    
                    + poly(TransSI_FT__1, 2)   
                    + poly(Divers_FT__1, 2)
                    + class,
                    data = taboo_class_subset)

## Linear Regression Residuals

lm_risk_01b <- lm(OpenRisks__1
                  ~ 1
                  + SCBEvo_FT__1   
                  + STEM_FT__1      
                  + AcBlack_FT__1   
                  + Binary_FT__1    
                  + Cons_FT__1      
                  + Crime_FT__1     
                  + MFEvo_FT__1     
                  + RaceIQ_FT__1    
                  + TransSI_FT__1   
                  + Divers_FT__1,
                  data = taboo_class_subset)

lm_risk_02b <- lm(OpenRisks__2
                  ~ 1
                  + SCBEvo_FT__1   
                  + STEM_FT__1      
                  + AcBlack_FT__1   
                  + Binary_FT__1    
                  + Cons_FT__1      
                  + Crime_FT__1     
                  + MFEvo_FT__1     
                  + RaceIQ_FT__1    
                  + TransSI_FT__1   
                  + Divers_FT__1,
                  data = taboo_class_subset)

lm_risk_03b <- lm(OpenRisks__3
                  ~ 1
                  + SCBEvo_FT__1   
                  + STEM_FT__1      
                  + AcBlack_FT__1   
                  + Binary_FT__1    
                  + Cons_FT__1      
                  + Crime_FT__1     
                  + MFEvo_FT__1     
                  + RaceIQ_FT__1    
                  + TransSI_FT__1   
                  + Divers_FT__1,
                  data = taboo_class_subset)

lm_risk_04b <- lm(OpenRisks__4
                  ~ 1
                  + SCBEvo_FT__1   
                  + STEM_FT__1      
                  + AcBlack_FT__1   
                  + Binary_FT__1    
                  + Cons_FT__1      
                  + Crime_FT__1     
                  + MFEvo_FT__1     
                  + RaceIQ_FT__1    
                  + TransSI_FT__1   
                  + Divers_FT__1,
                  data = taboo_class_subset)

lm_risk_05b <- lm(OpenRisks__5
                  ~ 1
                  + SCBEvo_FT__1   
                  + STEM_FT__1      
                  + AcBlack_FT__1   
                  + Binary_FT__1    
                  + Cons_FT__1      
                  + Crime_FT__1     
                  + MFEvo_FT__1     
                  + RaceIQ_FT__1    
                  + TransSI_FT__1   
                  + Divers_FT__1,
                  data = taboo_class_subset)

lm_risk_06b <- lm(OpenRisks__6
                  ~ 1
                  + SCBEvo_FT__1   
                  + STEM_FT__1      
                  + AcBlack_FT__1   
                  + Binary_FT__1    
                  + Cons_FT__1      
                  + Crime_FT__1     
                  + MFEvo_FT__1     
                  + RaceIQ_FT__1    
                  + TransSI_FT__1   
                  + Divers_FT__1,
                  data = taboo_class_subset)

lm_risk_07b <- lm(OpenRisks__7
                  ~ 1
                  + SCBEvo_FT__1   
                  + STEM_FT__1      
                  + AcBlack_FT__1   
                  + Binary_FT__1    
                  + Cons_FT__1      
                  + Crime_FT__1     
                  + MFEvo_FT__1     
                  + RaceIQ_FT__1    
                  + TransSI_FT__1   
                  + Divers_FT__1,
                  data = taboo_class_subset)

lm_risk_08b <- lm(OpenRisks__8
                  ~ 1
                  + SCBEvo_FT__1   
                  + STEM_FT__1      
                  + AcBlack_FT__1   
                  + Binary_FT__1    
                  + Cons_FT__1      
                  + Crime_FT__1     
                  + MFEvo_FT__1     
                  + RaceIQ_FT__1    
                  + TransSI_FT__1   
                  + Divers_FT__1,
                  data = taboo_class_subset)

lm_risk_09b <- lm(OpenRisks__9
                  ~ 1
                  + SCBEvo_FT__1   
                  + STEM_FT__1      
                  + AcBlack_FT__1   
                  + Binary_FT__1    
                  + Cons_FT__1      
                  + Crime_FT__1     
                  + MFEvo_FT__1     
                  + RaceIQ_FT__1    
                  + TransSI_FT__1   
                  + Divers_FT__1,
                  data = taboo_class_subset)

taboo_class_subset$open_risk_res_01b <- residuals(lm_risk_01b)
taboo_class_subset$open_risk_res_02b <- residuals(lm_risk_02b)
taboo_class_subset$open_risk_res_03b <- residuals(lm_risk_03b)
taboo_class_subset$open_risk_res_04b <- residuals(lm_risk_04b)
taboo_class_subset$open_risk_res_05b <- residuals(lm_risk_05b)
taboo_class_subset$open_risk_res_06b <- residuals(lm_risk_06b)
taboo_class_subset$open_risk_res_07b <- residuals(lm_risk_07b)
taboo_class_subset$open_risk_res_08b <- residuals(lm_risk_08b)
taboo_class_subset$open_risk_res_09b <- residuals(lm_risk_09b)

taboo_class_risk_res_b <- taboo_class_subset %>% 
  pivot_longer(
    cols      = c(
      open_risk_res_01b,
      open_risk_res_02b,
      open_risk_res_03b,
      open_risk_res_04b,
      open_risk_res_05b,
      open_risk_res_06b,
      open_risk_res_07b,
      open_risk_res_08b,
      open_risk_res_09b
    ),
    names_to  = "risk",
    values_to = "risk_res_rating_linear"
  )

risk_labels_res_b <- c(
  open_risk_res_01b = "Being ostracized by some peers",
  open_risk_res_02b = "Career damaging biases",
  open_risk_res_03b = "Being stigmatized or labeled pejorative terms",
  open_risk_res_04b = "Disciplinary actions",
  open_risk_res_05b = "Guilt-by-association harm", 
  open_risk_res_06b = "Being fired", 
  open_risk_res_07b = "Being attacked on social media",
  open_risk_res_08b = "Student boycotts",
  open_risk_res_09b = "Threats of physical violence"
)

summary_risk_res_b <- taboo_class_risk_res_b %>% 
  group_by(class, risk) %>% 
  summarise(
    mean  = mean(risk_res_rating_linear),
    se    = sd(risk_res_rating_linear)/sqrt(n()),
    ci_lb = mean - se*qnorm(.975),
    ci_ub = mean + se*qnorm(.975)
  )

plot_resid_linear_class_risks <- 
ggplot(taboo_class_risk_res_b,
       aes(
         x = class,
         y = risk_res_rating_linear
       )) +
  facet_wrap(~ risk,
             labeller = labeller(risk = risk_labels_res_b)) +
  geom_hline(
    yintercept = 0,
    linetype   = "dashed"
  ) +
  geom_quasirandom(
    shape = 1,
    alpha = .50
  ) +
  geom_errorbar(
    data = summary_risk_res_b,
    aes(
      y    = mean,
      ymin = ci_lb,
      ymax = ci_ub
    ),
    width     = .33,
    linewidth = 1
  ) +
  geom_line(
    data = summary_risk_res_b,
    aes(
      y     = mean,
      group = 1
    ),
    linewidth = 1
  ) +
  labs(
    x = "Latent Class",
    y = "Perceived Risk (Effect of Belief Removed)"
  ) +
  theme_classic()

save_plot("figures/taboos_class_risk_linear-residuals.png", 
          plot_resid_linear_class_risks,
          base_height = 7, base_width = 9)

# Reproducing Figure 1, with modifications -------------------------------------

statement_labels <- c(
  SCBEvo	= "Sexually Coercive Behavior Has Evolutionary Benefits",
  STEM    =	"Biases Don't Account for Gender Representation in STEM",
  AcBlack =	"Academia Is Biased Against Black People (Reversed)",
  Binary  =	"Biological Sex Is Binary",
  Cons    =	"Social Sciences Discriminate Against Conservatives",
  Crime	  = "Biases Don't Account for Racial Crime Rate Differences",
  MFEvo	  = "Psychological Gender Differences Are Evolved",
  RaceIQ  =	"Genetics Contribute to Racial IQ Differences",
  TransSI	= "Transgender Identity Is Socially Influenced",
  Divers	= "Diversity Damages Workplace Performance"
)

statement_wrap_labels <- c(
  SCBEvo	= str_wrap("Sexually Coercive Behavior Has Evolutionary Benefits", 16, whitespace_only = TRUE),
  STEM    =	str_wrap("Biases Don't Account for Gender Representation in STEM", 16, whitespace_only = TRUE),
  AcBlack =	str_wrap("Academia Is Biased Against Black People (Reversed)", 16, whitespace_only = TRUE),
  Binary  =	str_wrap("Biological Sex Is Binary", 16, whitespace_only = TRUE),
  Cons    =	str_wrap("Social Sciences Discriminate Against Conservatives", 16, whitespace_only = TRUE),
  Crime	  = str_wrap("Biases Don't Account for Racial Crime Rate Differences", 16, whitespace_only = TRUE),
  MFEvo	  = str_wrap("Psychological Gender Differences Are Evolved", 16, whitespace_only = TRUE),
  RaceIQ  =	str_wrap("Genetics Contribute to Racial IQ Differences", 16, whitespace_only = TRUE),
  TransSI	= str_wrap("Transgender Identity Is Socially Influenced", 16, whitespace_only = TRUE),
  Divers	= str_wrap("Diversity Damages Workplace Performance", 16, whitespace_only = TRUE)
)

repro_fig_1 <-
ggplot(taboo_long_poly,
       aes(
         x = belief,
         y = self_censor
       )) +
  facet_wrap(~ statement,
             nrow = 5,
             labeller = labeller(statement = statement_labels)) +
  geom_point(
    shape = 1
  ) +
  geom_smooth(
    method  = "lm",
    formula = "y ~ x"
  ) +
  labs(
    y = "Reluctance to Express Belief",
    x = "Belief in Statement"
  ) +
  theme_classic()

save_plot("figures/taboos_repro-figure-1.png", 
          repro_fig_1,
          base_height = 10, base_width = 7.5)

statement_class_desc <-  taboo_long_poly %>% 
  filter(!is.na(class)) %>% 
  group_by(class, statement) %>% 
  summarise(
    mean = mean(belief, na.rm = TRUE),
    r2   = round(summary(lm(self_censor 
                            ~ 1 
                            + belief 
                            + I(belief^2)))$r.squared, 3)
  )

fig_1_classes <- 
ggplot(taboo_long_poly %>% 
         filter(!is.na(class)),
       aes(
         x = belief,
         y = self_censor
       )) +
  facet_grid(statement ~ class,
             labeller = labeller(statement = statement_wrap_labels)) +
  geom_vline(
    data = statement_class_desc,
    aes(
      xintercept = mean
    ),
    linetype = "dashed"
  ) +
  geom_point(
    shape = 1
  ) +
  geom_smooth(
    method  = "lm",
    formula = "y ~ x + I(x^2)"
  ) +
  scale_y_continuous(
    limits = c(0, 130),
    breaks = seq(0, 100, 50)
  ) +
  geom_text(
    data = statement_class_desc,
    aes(
      label = r2
    ),
    x    = 10,
    y    = 125,
    size = 3
  ) +
  labs(
    y = "Reluctance to Express Belief",
    x = "Belief in Statement"
  ) +
  theme_classic() +
  theme(strip.text = element_text(size = 8))

save_plot("figures/taboos_figure-1-redux.png", 
          fig_1_classes,
          base_height = 10, base_width = 7.5)

