# Set number of threads
Sys.setenv(ARROW_NUM_THREADS = "16")

# Load arrow package
library(arrow)

# File path
parquet_file <- "payment_schedule_2023_2024_advanced.parquet"

# Verbose-style diagnostics
cat("Reading Parquet file:", parquet_file, "\n")
cat("Arrow version:", as.character(packageVersion("arrow")), "\n")
cat("Available CPU cores:", arrow::cpu_count(), "\n")
cat("Threads set via ARROW_NUM_THREADS:", Sys.getenv("ARROW_NUM_THREADS"), "\n")

# Start timing
start_time <- Sys.time()

# Read the Parquet file
my_data_parquet <- read_parquet(parquet_file)

# End timing
end_time <- Sys.time()
elapsed <- end_time - start_time

# Summary
cat("Read completed in", round(elapsed, 2), "seconds\n")
cat("Rows:", nrow(my_data_parquet), "Columns:", ncol(my_data_parquet), "\n")
cat("Column names:", paste(names(my_data_parquet), collapse = ", "), "\n")
