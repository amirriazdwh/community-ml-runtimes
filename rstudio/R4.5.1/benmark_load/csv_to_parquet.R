# Install and load the arrow package
#install.packages("arrow")
library(arrow)

# Read the CSV file
csv_file <- "payment_schedule_2023_2024_advanced.csv"
df <- read_csv_arrow(csv_file)

# Write to Parquet with Snappy compression
write_parquet(df, "payment_schedule_2023_2024_advanced.parquet", compression = "snappy")
