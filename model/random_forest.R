library(tidymodels)

# import data
library(readr)
ligue1_2010_2022 <- read_csv("data/ligue1_2010_2022.csv")

source('cleaning/cleaning.r')

df_clean = cleaning(ligue1_2010_2022)
df_final = preprocess(df_clean)

# rm na (first 5 matchs)
df_final = df_final %>% na.omit()

# split train/test
data_split <- initial_split(df_final, 
                            strata = result)

# Create dataframes for the two sets:
train_data <- training(data_split) 
test_data <- testing(data_split)

# recipe
foot_rec <-
  recipe(result ~ .,
         data = train_data) %>%
  step_rm(date, Match, Score, saison, Equipe_Domicile, Equipe_Exterieur, Score_Domicile, Score_exterieur, nchar) %>% 
  step_naomit(everything(), skip = TRUE) %>% 
  step_novel(all_nominal(), -all_outcomes()) %>%
  step_normalize(all_numeric(), -all_outcomes()) %>% 
  step_dummy(all_nominal(), -all_outcomes()) %>%
  step_zv(all_numeric(), -all_outcomes()) %>%
  step_corr(all_predictors(), threshold = 0.7, method = "spearman") 

# check our recipe
summary(foot_rec)

prepped_data <- 
  foot_rec %>% # use the recipe object
  prep() %>% # perform the recipe on training data
  juice()

# tuning rf
tune_spec <- rand_forest(
  mtry = tune(),
  trees = 1000,
  min_n = tune()
) %>%
  set_mode("classification") %>%
  set_engine("ranger")

# creating wf
tune_wf <- workflow() %>%
  add_recipe(foot_rec) %>%
  add_model(tune_spec)

# cross valid
set.seed(234)
trees_folds <- vfold_cv(train_data, v = 3)

doParallel::registerDoParallel()

# grid
set.seed(345)
tune_res <- tune_grid(
  tune_wf,
  resamples = trees_folds,
  grid = 20
)

# result
tune_res

# How did this turn out? Let’s look at AUC.
tune_res %>%
  collect_metrics() %>%
  filter(.metric == "roc_auc") %>%
  select(mean, min_n, mtry) %>%
  pivot_longer(min_n:mtry,
               values_to = "value",
               names_to = "parameter"
  ) %>%
  ggplot(aes(value, mean, color = parameter)) +
  geom_point(show.legend = FALSE) +
  facet_wrap(~parameter, scales = "free_x") +
  labs(x = NULL, y = "AUC")

# new grid from random seach
rf_grid <- grid_regular(
  mtry(range = c(10, 30)),
  min_n(range = c(20, 30)),
  levels = 5
)

rf_grid

set.seed(456)
regular_res <- tune_grid(
  tune_wf,
  resamples = trees_folds,
  grid = rf_grid
)

regular_res

# new result
regular_res %>%
  collect_metrics() %>%
  filter(.metric == "roc_auc") %>%
  mutate(min_n = factor(min_n)) %>%
  ggplot(aes(mtry, mean, color = min_n)) +
  geom_line(alpha = 0.5, size = 1.5) +
  geom_point() +
  labs(y = "AUC")

# choose the best model
best_auc <- select_best(regular_res, "roc_auc")

final_rf <- finalize_model(
  tune_spec,
  best_auc
)

final_rf

# final workflow

final_wf <- workflow() %>%
  add_recipe(foot_rec) %>%
  add_model(final_rf)

final_res <- final_wf %>%
  last_fit(data_split)

final_res %>%
  collect_metrics()

final_model = fit(final_wf, df_final)

# test on new data (antoher leauge)
bundesliga_2010_2022 <- read_csv("data/bundesliga_2010_2022.csv")

df_bclean = cleaning(bundesliga_2010_2022)
df_finalb = preprocess(df_bclean)
test = df_finalb %>%  filter(date > '2022-05-01')


prob = augment(final_model, test) 

prob %>%
  select(date, Equipe_Domicile, Equipe_Exterieur, Score_Domicile, Score_exterieur, result, .pred_class, contains(".pred_"))


