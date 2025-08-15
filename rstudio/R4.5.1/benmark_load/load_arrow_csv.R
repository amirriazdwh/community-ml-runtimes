# Set number of threads
Sys.setenv(ARROW_NUM_THREADS = "16")

# Install and load the arrow package if not already installed
library(arrow)

# Set the number of threads (e.g., 4 or use all available)
arrow::cpu_count()         # Check how many threads are available
arrow::set_cpu_count(16)    # Set to 4 threads (or use arrow::set_cpu_count(arrow::cpu_count()) for max)

# Read the CSV file using Arrow
my_data <- read_csv_arrow("payment_schedule_2023_2024_advanced.csv")

# Preview the first 10 rows
head(my_data, 10)
