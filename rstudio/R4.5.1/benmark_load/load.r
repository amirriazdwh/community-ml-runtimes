# Load necessary library
library(readr)
 
# Define the file path
file_path <- "/dbfs/home/bdp_008752/commands/data/2025/customer.csv"
 
# Load the CSV file
data <- read.csv(file_path)
 
# Display the data
print(data)
