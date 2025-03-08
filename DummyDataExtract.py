import os
import pandas as pd
import numpy as np

# =============================================
# 1. Create Dummy Data
# =============================================
np.random.seed(123)
n_patients = 100
n_periods = 8

data = {
    'id': np.repeat(np.arange(1, n_patients+1), n_periods),
    'period': np.tile(np.arange(n_periods), n_patients),
    'treatment': np.random.choice([0, 1], n_patients*n_periods),
    'x1': np.random.normal(0, 1, n_patients*n_periods),
    'x2': np.random.normal(0, 1, n_patients*n_periods),
    'x3': np.random.randint(0, 2, n_patients*n_periods),
    'x4': np.random.uniform(0, 1, n_patients*n_periods),
    'age': np.repeat(np.random.randint(20, 80, n_patients), n_periods),
    'outcome': np.random.choice([0, 1], n_patients*n_periods, p=[0.85, 0.15]),
    'censored': np.random.choice([0, 1], n_patients*n_periods, p=[0.9, 0.1]),
    'eligible': np.random.choice([0, 1], n_patients*n_periods, p=[0.2, 0.8])
}

df = pd.DataFrame(data)
df['age_s'] = df['age'] + df['period']/12  # Create age_s after DataFrame creation

# =============================================
# 2. Save to CSV in Current Directory
# =============================================
# Get current working directory dynamically
current_dir = os.getcwd()  

file_name = "data_censored.csv"
file_path = os.path.join(current_dir, file_name)

# Save to CSV
df.to_csv(file_path, index=False)

print(f"CSV file saved at:\n{file_path}")