library(data.table)
library(DT)


setDTthreads(16)
# Fast and memory-efficient way to read large CSV files
my_data <- fread("payment_schedule_2023_2024_advanced.csv", verbose = TRUE)
datatable(head(my_data, 1000))  


setDTthreads(1)
system.time(fread("payment_schedule_2023_2024_advanced.csv"))


setDTthreads(16)
system.time(fread("payment_schedule_2023_2024_advanced.csv",verbose = TRUE))


Sys.setenv(OMP_NUM_THREADS = "16")
Sys.setenv(OMP_THREAD_LIMIT = "16")
setDTthreads(16)
system.time(fread("payment_schedule_2023_2024_advanced.csv",verbose = TRUE))