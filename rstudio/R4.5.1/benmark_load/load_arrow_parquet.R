# Load the arrow package
library(arrow)

# Read the Parquet file
parquet_file <- "payment_schedule_2023_2024_advanced.parquet"
my_data_parquet <- read_parquet(parquet_file)

# Preview the data
View(my_data_parquet)
