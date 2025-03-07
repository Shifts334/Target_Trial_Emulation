# Load necessary libraries
library(TrialEmulation)

# 1. Setup
# Define estimands (Per-Protocol and Intention-to-Treat)
trial_pp <- trial_sequence(estimand = "PP")  # Per-Protocol
trial_itt <- trial_sequence(estimand = "ITT")  # Intention-to-Treat

# Create directories to save files
trial_pp_dir <- file.path(tempdir(), "trial_pp")
dir.create(trial_pp_dir)
trial_itt_dir <- file.path(tempdir(), "trial_itt")
dir.create(trial_itt_dir)

# 2. Data Preparation
# Load example data (dummy data from the package)
data("data_censored")
head(data_censored)

# Set data for Per-Protocol and Intention-to-Treat estimands
trial_pp <- trial_pp |>
  set_data(
    data = data_censored,
    id = "id",
    period = "period",
    treatment = "treatment",
    outcome = "outcome",
    eligible = "eligible"
  )

trial_itt <- set_data(
  trial_itt,
  data = data_censored,
  id = "id",
  period = "period",
  treatment = "treatment",
  outcome = "outcome",
  eligible = "eligible"
)

# 3. Weight Models and Censoring
# 3.1 Censoring due to treatment switching (only for Per-Protocol)
trial_pp <- trial_pp |>
  set_switch_weight_model(
    numerator = ~ age,
    denominator = ~ age + x1 + x3,
    model_fitter = stats_glm_logit(save_path = file.path(trial_pp_dir, "switch_models"))
  )

# 3.2 Other informative censoring (for both PP and ITT)
trial_pp <- trial_pp |>
  set_censor_weight_model(
    censor_event = "censored",
    numerator = ~ x2,
    denominator = ~ x2 + x1,
    pool_models = "none",
    model_fitter = stats_glm_logit(save_path = file.path(trial_pp_dir, "censor_models"))
  )

trial_itt <- set_censor_weight_model(
  trial_itt,
  censor_event = "censored",
  numerator = ~ x2,
  denominator = ~ x2 + x1,
  pool_models = "numerator",
  model_fitter = stats_glm_logit(save_path = file.path(trial_itt_dir, "censor_models"))
)

# 4. Calculate Weights
trial_pp <- trial_pp |> calculate_weights()
trial_itt <- calculate_weights(trial_itt)

# Inspect weight models
show_weight_models(trial_itt)
show_weight_models(trial_pp)

# 5. Specify Outcome Model
trial_pp <- set_outcome_model(trial_pp)
trial_itt <- set_outcome_model(trial_itt, adjustment_terms = ~ x2)

# 6. Expand Trials
trial_pp <- set_expansion_options(
  trial_pp,
  output = save_to_datatable(),
  chunk_size = 500  # Number of patients per expansion iteration
)

trial_itt <- set_expansion_options(
  trial_itt,
  output = save_to_datatable(),
  chunk_size = 500
)

# 6.1 Create Sequence of Trials Data
trial_pp <- expand_trials(trial_pp)
trial_itt <- expand_trials(trial_itt)

# 7. Load or Sample from Expanded Data
trial_itt <- load_expanded_data(trial_itt, seed = 1234, p_control = 0.5)

# 8. Fit Marginal Structural Model (MSM)
trial_itt <- fit_msm(
  trial_itt,
  weight_cols = c("weight", "sample_weight"),
  modify_weights = function(w) {
    q99 <- quantile(w, probs = 0.99)  # Winsorization of extreme weights
    pmin(w, q99)
  }
)

# Model summary
trial_itt@outcome_model

# 9. Inference
# Predict survival probabilities or cumulative incidences
preds <- predict(
  trial_itt,
  newdata = outcome_data(trial_itt)[trial_period == 1, ],
  predict_times = 0:10,
  type = "survival"
)

# Plot survival differences over time
plot(preds$difference$followup_time, preds$difference$survival_diff,
     type = "l", xlab = "Follow up", ylab = "Survival difference")
lines(preds$difference$followup_time, preds$difference$'2.5%', type = "l", col = "red", lty = 2)
lines(preds$difference$followup_time, preds$difference$'97.5%', type = "l", col = "red", lty = 2)