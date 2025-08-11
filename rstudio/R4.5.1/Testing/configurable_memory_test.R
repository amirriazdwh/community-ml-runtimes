#!/usr/bin/env Rscript
# ================================================================
# CONFIGURABLE MEMORY BREAKING POINT TEST WITH R_MAX_SIZE & R_MAX_VSIZE
# ================================================================
# Purpose: Test different R memory configurations for breaking points
# Features:
#   - Configure R_MAX_SIZE (total memory limit)
#   - Configure R_MAX_VSIZE (vector memory limit) 
#   - Automated testing with multiple configurations
#   - Detailed memory usage reporting
#   - Comparative analysis between settings
#  docker exec rstudio-optimized Rscript /home/cdsw/configurable_memory_test.R 25G 20G
# Usage Options:
#   1. Interactive mode: Rscript configurable_memory_test.R
#   2. Single test: Rscript configurable_memory_test.R [R_MAX_SIZE] [R_MAX_VSIZE]
#   3. Batch mode: Rscript configurable_memory_test.R batch
#
# Examples:
#   Rscript configurable_memory_test.R 10G 8G
#   Rscript configurable_memory_test.R 20971520000 16777216000
#   Rscript configurable_memory_test.R batch
#  export R_MAX_SIZE=5G      # Consistent performance
# export R_MAX_VSIZE=20G 
# ================================================================

suppressPackageStartupMessages({
  library(data.table)
  library(parallel)
})

# ================================================================
# ARGUMENT PARSING AND CONFIGURATION
# ================================================================

args <- commandArgs(trailingOnly = TRUE)

# Default memory settings
DEFAULT_R_MAX_SIZE <- "20G"
DEFAULT_R_MAX_VSIZE <- "16G"

# Parse command line arguments
R_MAX_SIZE <- if (length(args) >= 1) args[1] else DEFAULT_R_MAX_SIZE
R_MAX_VSIZE <- if (length(args) >= 2) args[2] else DEFAULT_R_MAX_VSIZE

# Test configuration
NUM_CORES <- detectCores()
TEST_DIR <- "/tmp/memory_config_test"
if (!dir.exists(TEST_DIR)) dir.create(TEST_DIR, recursive = TRUE)

# Progressive test sizes (millions of rows)
TEST_SIZES <- c(1, 2.5, 5, 7.5, 10, 15, 20, 30, 40, 50, 75, 100)

# ================================================================
# UTILITY FUNCTIONS
# ================================================================

format_bytes <- function(bytes) {
  if (is.na(bytes) || bytes == 0) return("0 B")
  if (bytes >= 1e12) sprintf("%.2f TB", bytes/1e12)
  else if (bytes >= 1e9) sprintf("%.2f GB", bytes/1e9)
  else if (bytes >= 1e6) sprintf("%.2f MB", bytes/1e6)
  else if (bytes >= 1e3) sprintf("%.2f KB", bytes/1e3)
  else sprintf("%.0f B", bytes)
}

get_memory_info <- function() {
  gc_result <- gc(verbose = FALSE)
  used_mb <- sum(gc_result[, "used"])
  max_mb <- sum(gc_result[, "max used"])
  
  list(
    used_mb = used_mb,
    max_mb = max_mb,
    used_bytes = used_mb * 1024^2,
    max_bytes = max_mb * 1024^2
  )
}

convert_memory_string <- function(mem_str) {
  mem_str <- toupper(trimws(mem_str))
  if (grepl("G$", mem_str)) {
    return(list(
      bytes = as.numeric(gsub("G$", "", mem_str)) * 1024^3,
      display = mem_str
    ))
  } else if (grepl("M$", mem_str)) {
    return(list(
      bytes = as.numeric(gsub("M$", "", mem_str)) * 1024^2,
      display = mem_str
    ))
  } else {
    return(list(
      bytes = as.numeric(mem_str),
      display = paste0(mem_str, "B")
    ))
  }
}

print_section <- function(title, char = "=") {
  cat("\n", rep(char, 80), "\n")
  cat(title, "\n")
  cat(rep(char, 80), "\n")
}

print_subsection <- function(title) {
  cat("\n", rep("-", 60), "\n")
  cat(title, "\n")
  cat(rep("-", 60), "\n")
}

# ================================================================
# MEMORY CONFIGURATION SETUP
# ================================================================

setup_memory_environment <- function() {
  print_subsection("⚙️  CONFIGURING R MEMORY ENVIRONMENT")
  
  # Parse memory values
  max_size_info <- convert_memory_string(R_MAX_SIZE)
  max_vsize_info <- convert_memory_string(R_MAX_VSIZE)
  
  cat("Memory Configuration:\n")
    cat("  parallel Version: ", as.character(packageVersion("parallel")), "
")
  cat("  R_MAX_VSIZE: ", max_vsize_info$display, " (", format_bytes(max_vsize_info$bytes), ")\n")
  
  # Set environment variables
  Sys.setenv(R_MAX_SIZE = R_MAX_SIZE)
  Sys.setenv(R_MAX_VSIZE = R_MAX_VSIZE)
  
  # Try to apply memory limits
  tryCatch({
    # Attempt to set memory limit if function exists
    if (exists("memory.limit") && .Platform$OS.type == "windows") {
      max_size_mb <- max_size_info$bytes / (1024^2)
      old_limit <- memory.limit()
      memory.limit(max_size_mb)
      cat("  Windows memory.limit() set to:", format_bytes(max_size_mb * 1024^2), "\n")
    } else {
      cat("  Using environment variables for memory control\n")
    }
  }, error = function(e) {
    cat("  Memory limit setting:", e$message, "\n")
  })
  
  # Display current memory state
  mem_info <- get_memory_info()
  cat("  Current R memory usage:", format_bytes(mem_info$used_bytes), "\n")
  cat("  Peak R memory usage:", format_bytes(mem_info$max_bytes), "\n")
  
  # System memory info (if available)
  tryCatch({
    if (file.exists("/proc/meminfo")) {
      meminfo <- readLines("/proc/meminfo", n = 3)
      total_mem <- as.numeric(gsub(".*?([0-9]+).*", "\\1", meminfo[1])) * 1024
      free_mem <- as.numeric(gsub(".*?([0-9]+).*", "\\1", meminfo[2])) * 1024
      cat("  System total memory:", format_bytes(total_mem), "\n")
      cat("  System free memory:", format_bytes(free_mem), "\n")
    }
  }, error = function(e) {})
  
  cat("\n")
  return(list(max_size = max_size_info, max_vsize = max_vsize_info))
}

# ================================================================
# DATASET TEST FUNCTION
# ================================================================

test_memory_capacity <- function(size_millions, test_num, total_tests, memory_config) {
  print_subsection(sprintf("🚀 TEST %d/%d - %.1fM ROWS", test_num, total_tests, size_millions))
  
  num_rows <- as.integer(size_millions * 1e6)
  csv_file <- file.path(TEST_DIR, sprintf("test_%.1fM.csv", size_millions))
  
  # Pre-test memory state
  mem_start <- get_memory_info()
  cat("📊 Pre-test memory: ", format_bytes(mem_start$used_bytes), "\n")
  
  result <- tryCatch({
    # Phase 1: Data Generation
    cat("⏳ Phase 1: Generating", format(num_rows, big.mark = ","), "rows...\n")
    gen_start <- Sys.time()
    
    # Create realistic dataset with multiple data types
    test_dataset <- data.table(
      id = 1:num_rows,
      timestamp = as.POSIXct("2025-01-01") + sample(0:(365*24*3600), num_rows, replace = TRUE),
      category = sample(LETTERS[1:25], num_rows, replace = TRUE),
      subcategory = sample(paste0("Sub", 1:100), num_rows, replace = TRUE),
      value_double = rnorm(num_rows, 100, 25),
      value_uniform = runif(num_rows, 0, 1000),
      value_exponential = rexp(num_rows, 0.1),
      text_short = sample(paste0("txt", 1:1000), num_rows, replace = TRUE),
      text_long = paste0("data_", sample(100000:999999, num_rows, replace = TRUE), "_extended"),
      factor_small = sample(paste0("F", 1:10), num_rows, replace = TRUE),
      factor_large = sample(paste0("Factor", 1:500), num_rows, replace = TRUE),
      logical_flag = sample(c(TRUE, FALSE), num_rows, replace = TRUE),
      integer_count = sample(1:10000, num_rows, replace = TRUE),
      numeric_amount = runif(num_rows, 1, 1000000),
      score_1 = rnorm(num_rows, 50, 15),
      score_2 = rnorm(num_rows, 75, 20),
      percentage = runif(num_rows, 0, 100),
      rate = runif(num_rows, 0.01, 100.0),
      index_num = sample(1:num_rows, num_rows, replace = FALSE),
      status = sample(c("active", "inactive", "pending", "archived", "deleted"), num_rows, replace = TRUE)
    )
    
    gen_time <- as.numeric(Sys.time() - gen_start, units = "secs")
    obj_size <- as.numeric(object.size(test_dataset))
    
    mem_after_gen <- get_memory_info()
    memory_increase <- mem_after_gen$used_bytes - mem_start$used_bytes
    
    cat("✅ Generation SUCCESS!\n")
    cat("   Time: ", round(gen_time, 2), " seconds\n")
    cat("   Object size: ", format_bytes(obj_size), "\n")
    cat("   Memory increase: ", format_bytes(memory_increase), "\n")
    cat("   Total memory: ", format_bytes(mem_after_gen$used_bytes), "\n")
    
    # Phase 2: File Writing
    cat("⏳ Phase 2: Writing to CSV (", NUM_CORES, " threads)...\n")
    write_start <- Sys.time()
    fwrite(test_dataset, csv_file, nThread = NUM_CORES)
    write_time <- as.numeric(Sys.time() - write_start, units = "secs")
    
    file_size <- file.info(csv_file)$size
    write_throughput <- file_size / write_time
    
    cat("✅ Write SUCCESS!\n")
    cat("   Time: ", round(write_time, 2), " seconds\n")
    cat("   File size: ", format_bytes(file_size), "\n")
    cat("   Write throughput: ", format_bytes(write_throughput), "/second\n")
    
    # Clear dataset from memory
    rm(test_dataset)
    gc(verbose = FALSE)
    
    # Phase 3: File Reading (The Critical Test)
    cat("⏳ Phase 3: Reading CSV (", NUM_CORES, " threads)...\n")
    mem_before_read <- get_memory_info()
    
    read_start <- Sys.time()
    loaded_dataset <- fread(csv_file, nThread = NUM_CORES)
    read_time <- as.numeric(Sys.time() - read_start, units = "secs")
    
    mem_after_read <- get_memory_info()
    read_memory_increase <- mem_after_read$used_bytes - mem_before_read$used_bytes
    
    cat("✅ Read SUCCESS!\n")
    cat("   Time: ", round(read_time, 2), " seconds\n")
    cat("   Read throughput: ", round(nrow(loaded_dataset) / read_time, 0), " rows/second\n")
    cat("   Data loaded: ", format(nrow(loaded_dataset), big.mark = ","), " rows × ", ncol(loaded_dataset), " columns\n")
    cat("   Memory for loaded data: ", format_bytes(read_memory_increase), "\n")
    
    # Phase 4: Data Operations Performance
    cat("⏳ Phase 4: Testing data operations performance...\n")
    
    # Complex aggregation
    agg_start <- Sys.time()
    aggregation_result <- loaded_dataset[, .(
      row_count = .N,
      avg_value = mean(value_double),
      sum_amount = sum(numeric_amount),
      min_score = min(score_1),
      max_score = max(score_2),
      median_rate = median(rate)
    ), by = .(category, status)]
    agg_time <- as.numeric(Sys.time() - agg_start, units = "secs")
    
    # Multi-condition filtering
    filter_start <- Sys.time()
    filtered_data <- loaded_dataset[
      value_double > 100 & 
      logical_flag == TRUE & 
      status %in% c("active", "pending") &
      percentage > 50
    ]
    filter_time <- as.numeric(Sys.time() - filter_start, units = "secs")
    
    # Complex sorting
    sort_start <- Sys.time()
    setorder(loaded_dataset, -numeric_amount, category, value_double)
    sort_time <- as.numeric(Sys.time() - sort_start, units = "secs")
    
    # Join operation (self-join)
    join_start <- Sys.time()
    summary_by_cat <- loaded_dataset[, .(avg_amount = mean(numeric_amount)), by = category]
    joined_data <- loaded_dataset[summary_by_cat, on = "category"]
    join_time <- as.numeric(Sys.time() - join_start, units = "secs")
    
    cat("✅ Operations SUCCESS!\n")
    cat("   Aggregation: ", round(agg_time, 3), " sec (", nrow(aggregation_result), " groups)\n")
    cat("   Filtering: ", round(filter_time, 3), " sec (", format(nrow(filtered_data), big.mark = ","), " rows)\n")
    cat("   Sorting: ", round(sort_time, 3), " sec\n")
    cat("   Joining: ", round(join_time, 3), " sec\n")
    
    # Final memory assessment
    mem_final <- get_memory_info()
    total_memory_used = mem_final$used_bytes - mem_start$used_bytes
    peak_memory = mem_final$max_bytes
    
    cat("📊 Final Memory Assessment:\n")
    cat("   Total memory increase: ", format_bytes(total_memory_used), "\n")
    cat("   Peak memory usage: ", format_bytes(peak_memory), "\n")
    cat("   Memory efficiency: ", round(obj_size / total_memory_used * 100, 1), "%\n")
    
    # Cleanup
    rm(loaded_dataset, aggregation_result, filtered_data, summary_by_cat, joined_data)
    gc(verbose = FALSE)
    file.remove(csv_file)
    
    cat("🏆 TEST COMPLETED SUCCESSFULLY!\n")
    
    # Return comprehensive results
    list(
      test_number = test_num,
      size_millions = size_millions,
      num_rows = num_rows,
      success = TRUE,
      
      # Timing metrics
      generation_time = gen_time,
      write_time = write_time,
      read_time = read_time,
      agg_time = agg_time,
      filter_time = filter_time,
      sort_time = sort_time,
      join_time = join_time,
      
      # Size metrics
      object_size = obj_size,
      file_size = file_size,
      
      # Memory metrics
      memory_increase = memory_increase,
      read_memory_increase = read_memory_increase,
      total_memory_used = total_memory_used,
      peak_memory = peak_memory,
      
      # Performance metrics
      write_throughput = write_throughput,
      read_rate = nrow(loaded_dataset) / read_time,
      memory_efficiency = obj_size / total_memory_used,
      
      # Operation results
      aggregation_groups = nrow(aggregation_result),
      filtered_rows = nrow(filtered_data),
      
      # Configuration
      r_max_size = R_MAX_SIZE,
      r_max_vsize = R_MAX_VSIZE
    )
    
  }, error = function(e) {
    cat("\n❌ TEST FAILED!\n")
    cat("💥 Error: ", e$message, "\n")
    
    mem_error <- get_memory_info()
    cat("📊 Memory at failure: ", format_bytes(mem_error$used_bytes), "\n")
    
    # Cleanup on error
    tryCatch({
      if (exists("test_dataset")) rm(test_dataset)
      if (exists("loaded_dataset")) rm(loaded_dataset)
      if (exists("aggregation_result")) rm(aggregation_result)
      if (exists("filtered_data")) rm(filtered_data)
      if (exists("summary_by_cat")) rm(summary_by_cat)
      if (exists("joined_data")) rm(joined_data)
      gc(verbose = FALSE)
      if (file.exists(csv_file)) file.remove(csv_file)
    }, error = function(cleanup_error) {
      cat("Cleanup error: ", cleanup_error$message, "\n")
    })
    
    list(
      test_number = test_num,
      size_millions = size_millions,
      num_rows = num_rows,
      success = FALSE,
      error_message = e$message,
      breaking_point = TRUE,
      r_max_size = R_MAX_SIZE,
      r_max_vsize = R_MAX_VSIZE
    )
  })
  
  return(result)
}

# ================================================================
# MAIN EXECUTION FUNCTION
# ================================================================

run_memory_configuration_test <- function() {
  print_section("🔥 ENHANCED MEMORY BREAKING POINT TEST 🔥")
  
  cat("Test Environment:\n")
  cat("  Container: 28GB RAM, ", NUM_CORES, " CPU cores\n")
  cat("  R Version: ", R.version.string, "\n")
  cat("  data.table Version: ", as.character(packageVersion("data.table")), "\n")
  cat("  Test Directory: ", TEST_DIR, "\n")
  
  # Setup memory configuration
  memory_config <- setup_memory_environment()
  
  cat("Test Plan:\n")
  cat("  Dataset sizes: ", paste(TEST_SIZES, "M", sep = "", collapse = ", "), "\n")
  cat("  Columns per dataset: 20 (mixed types)\n")
  cat("  Operations tested: generation, write, read, aggregate, filter, sort, join\n")
  
  # Execute tests
  print_section("🧪 EXECUTING PROGRESSIVE MEMORY TESTS")
  
  all_results <- list()
  successful_tests <- 0
  
  for (i in seq_along(TEST_SIZES)) {
    size_millions <- TEST_SIZES[i]
    
    cat("\n📋 Starting test ", i, " of ", length(TEST_SIZES), "\n")
    
    result <- test_memory_capacity(size_millions, i, length(TEST_SIZES), memory_config)
    all_results[[i]] <- result
    
    if (result$success) {
      successful_tests <- successful_tests + 1
      cat("✅ Test ", i, " PASSED! Continuing...\n")
    } else {
      cat("🛑 BREAKING POINT REACHED at test ", i, "!\n")
      break
    }
    
    # Brief pause
    Sys.sleep(1)
  }
  
  # Generate comprehensive results analysis
  print_section("📊 COMPREHENSIVE RESULTS ANALYSIS")
  
  cat("Memory Configuration Summary:\n")
  cat("  R_MAX_SIZE: ", R_MAX_SIZE, "\n")
  cat("  R_MAX_VSIZE: ", R_MAX_VSIZE, "\n")
  cat("  Tests Executed: ", length(all_results), "\n")
  cat("  Tests Successful: ", successful_tests, "\n")
  cat("  Success Rate: ", round(successful_tests / length(all_results) * 100, 1), "%\n\n")
  
  if (successful_tests > 0) {
    cat("✅ SUCCESSFUL TESTS PERFORMANCE SUMMARY:\n")
    cat(sprintf("%-4s %-8s %-12s %-8s %-8s %-10s %-12s %-10s %-8s\n",
                "Test", "Size", "Rows", "Gen(s)", "Read(s)", "Rate(r/s)", "File Size", "Memory", "Eff(%)"))
    cat(rep("-", 95), "\n")
    
    total_gen_time <- 0
    total_read_time <- 0
    max_memory <- 0
    
    for (i in 1:successful_tests) {
      r <- all_results[[i]]
      total_gen_time <- total_gen_time + r$generation_time
      total_read_time <- total_read_time + r$read_time
      max_memory <- max(max_memory, r$peak_memory)
      
      cat(sprintf("%-4d %-8s %-12s %-8.1f %-8.1f %-10.0f %-12s %-10s %-8.1f\n",
                  r$test_number,
                  paste0(r$size_millions, "M"),
                  format(r$num_rows, big.mark = ","),
                  r$generation_time,
                  r$read_time,
                  r$read_rate,
                  format_bytes(r$file_size),
                  format_bytes(r$total_memory_used),
                  r$memory_efficiency * 100))
    }
    
    # Performance analysis
    cat("\n📈 PERFORMANCE ANALYSIS:\n")
    
    max_success <- all_results[[successful_tests]]
    cat("  Maximum Successful Dataset:\n")
    cat("    Size: ", max_success$size_millions, "M rows (", format(max_success$num_rows, big.mark = ","), ")\n")
    cat("    File Size: ", format_bytes(max_success$file_size), "\n")
    cat("    Peak Memory: ", format_bytes(max_success$peak_memory), "\n")
    cat("    Memory Efficiency: ", round(max_success$memory_efficiency * 100, 1), "%\n")
    
    # Average performance metrics
    avg_gen_time <- total_gen_time / successful_tests
    avg_read_time <- total_read_time / successful_tests
    avg_read_rate <- mean(sapply(all_results[1:successful_tests], function(x) x$read_rate))
    
    cat("  Average Performance (across all successful tests):\n")
    cat("    Generation time: ", round(avg_gen_time, 2), " seconds\n")
    cat("    Read time: ", round(avg_read_time, 2), " seconds\n")
    cat("    Read rate: ", round(avg_read_rate, 0), " rows/second\n")
    cat("    Peak memory usage: ", format_bytes(max_memory), "\n")
    
    # Scaling analysis
    if (successful_tests >= 3) {
      cat("  Scaling Analysis:\n")
      
      first_test <- all_results[[1]]
      last_test <- all_results[[successful_tests]]
      
      size_ratio <- last_test$num_rows / first_test$num_rows
      time_ratio <- last_test$read_time / first_test$read_time
      memory_ratio <- last_test$peak_memory / first_test$peak_memory
      
      cat("    Size increase: ", round(size_ratio, 1), "x\n")
      cat("    Time increase: ", round(time_ratio, 1), "x\n")
      cat("    Memory increase: ", round(memory_ratio, 1), "x\n")
      cat("    Scaling efficiency: ", round(size_ratio / time_ratio, 2), " (>1.0 = sub-linear scaling)\n")
    }
  } else {
    cat("❌ NO SUCCESSFUL TESTS!\n")
    cat("  The current memory configuration appears to be insufficient.\n")
  }
  
  # Breaking point analysis
  if (length(all_results) > successful_tests) {
    failed_test <- all_results[[successful_tests + 1]]
    
    cat("\n💥 BREAKING POINT ANALYSIS:\n")
    cat("  Breaking Point: ", failed_test$size_millions, "M rows (", format(failed_test$num_rows, big.mark = ","), ")\n")
    cat("  Error: ", failed_test$error_message, "\n")
    
    if (successful_tests > 0) {
      last_success <- all_results[[successful_tests]]
      margin_rows <- failed_test$num_rows - last_success$num_rows
      margin_percent <- (margin_rows / last_success$num_rows) * 100
      
      cat("  Last Successful: ", last_success$size_millions, "M rows\n")
      cat("  Safety Margin: ", format(margin_rows, big.mark = ","), " rows (", round(margin_percent, 1), "%)\n")
    }
  } else {
    cat("\n🟢 NO BREAKING POINT FOUND!\n")
    cat("  All tested sizes completed successfully.\n")
    cat("  Consider testing larger datasets or this configuration is very robust.\n")
  }
  
  # Configuration recommendations
  print_section("💡 CONFIGURATION RECOMMENDATIONS")
  
  if (successful_tests > 0) {
    max_peak_memory_gb <- max(sapply(all_results[1:successful_tests], function(x) x$peak_memory)) / 1024^3
    
    # Conservative recommendations (with safety margins)
    recommended_max_size <- ceiling(max_peak_memory_gb * 1.5)  # 50% safety margin
    recommended_max_vsize <- ceiling(max_peak_memory_gb * 1.3)  # 30% safety margin
    
    cat("Based on peak memory usage of ", format_bytes(max_peak_memory_gb * 1024^3), ":\n\n")
    
    cat("🎯 OPTIMAL SETTINGS:\n")
    cat("  R_MAX_SIZE: ", recommended_max_size, "G\n")
    cat("  R_MAX_VSIZE: ", recommended_max_vsize, "G\n")
    cat("  Maximum safe dataset: ~", max_success$size_millions, "M rows\n")
    cat("  Expected file size limit: ~", format_bytes(max_success$file_size), "\n\n")
    
    cat("⚡ PERFORMANCE SETTINGS:\n")
    cat("  For maximum performance, use:\n")
    cat("  export R_MAX_SIZE=", recommended_max_size, "G\n")
    cat("  export R_MAX_VSIZE=", recommended_max_vsize, "G\n")
    cat("  export OMP_NUM_THREADS=", NUM_CORES, "\n\n")
    
    cat("🔒 CONSERVATIVE SETTINGS:\n")
    cat("  For guaranteed stability:\n")
    cat("  export R_MAX_SIZE=", ceiling(recommended_max_size * 0.8), "G\n")
    cat("  export R_MAX_VSIZE=", ceiling(recommended_max_vsize * 0.8), "G\n\n")
    
  } else {
    cat("❌ CURRENT CONFIGURATION INSUFFICIENT!\n")
    cat("Try these settings:\n")
    cat("  export R_MAX_SIZE=25G\n")
    cat("  export R_MAX_VSIZE=20G\n")
    cat("  Ensure container has adequate RAM allocation\n\n")
  }
  
  cat("🧪 TEST VARIATIONS:\n")
  cat("To test different configurations, run:\n")
  cat("  Rscript configurable_memory_test.R 25G 20G\n")
  cat("  Rscript configurable_memory_test.R 15G 12G\n")
  cat("  Rscript configurable_memory_test.R 30G 25G\n")
  
  print_section("🎯 MEMORY CONFIGURATION TEST COMPLETED")
  
  return(all_results)
}

# ================================================================
# BATCH TESTING WITH MULTIPLE CONFIGURATIONS
# ================================================================

run_batch_memory_tests <- function() {
  print_section("🧪 BATCH TESTING WITH MULTIPLE MEMORY CONFIGURATIONS")
  
  # Define test configurations
  test_configs <- list(
    list(name = "Conservative", R_MAX_SIZE = "8G", R_MAX_VSIZE = "6G"),
    list(name = "Moderate", R_MAX_SIZE = "12G", R_MAX_VSIZE = "10G"),
    list(name = "Aggressive", R_MAX_SIZE = "20G", R_MAX_VSIZE = "16G"),
    list(name = "Maximum", R_MAX_SIZE = "25G", R_MAX_VSIZE = "20G")
  )
  
  batch_results <- list()
  
  for (i in seq_along(test_configs)) {
    config <- test_configs[[i]]
    
    cat("\n", rep("=", 80), "\n")
    cat("🔧 CONFIGURATION", i, "OF", length(test_configs), ":", config$name, "\n")
    cat("R_MAX_SIZE:", config$R_MAX_SIZE, ", R_MAX_VSIZE:", config$R_MAX_VSIZE, "\n")
    cat(rep("=", 80), "\n")
    
    # Temporarily set configuration
    old_R_MAX_SIZE <- R_MAX_SIZE
    old_R_MAX_VSIZE <- R_MAX_VSIZE
    
    R_MAX_SIZE <<- config$R_MAX_SIZE
    R_MAX_VSIZE <<- config$R_MAX_VSIZE
    
    # Run test with this configuration
    config_results <- run_memory_configuration_test()
    
    # Store results
    batch_results[[config$name]] <- list(
      config = config,
      results = config_results
    )
    
    # Restore original configuration
    R_MAX_SIZE <<- old_R_MAX_SIZE
    R_MAX_VSIZE <<- old_R_MAX_VSIZE
    
    cat("\n⏸️  Pausing between configurations...\n")
    Sys.sleep(3)
  }
  
  # Comparative analysis
  print_section("📊 BATCH TEST COMPARATIVE ANALYSIS")
  
  cat("Configuration Performance Summary:\n")
  cat(sprintf("%-12s %-10s %-10s %-15s %-12s %-10s\n", 
              "Config", "R_MAX_SIZE", "R_MAX_VSIZE", "Max Success", "File Size", "Read Rate"))
  cat(rep("-", 80), "\n")
  
  for (config_name in names(batch_results)) {
    batch_result <- batch_results[[config_name]]
    config <- batch_result$config
    results <- batch_result$results
    
    # Find maximum successful test
    successful <- Filter(function(x) x$success, results)
    if (length(successful) > 0) {
      max_success <- successful[[which.max(sapply(successful, function(x) x$num_rows))]]
      cat(sprintf("%-12s %-10s %-10s %-15s %-12s %-10.0f\n",
                  config_name,
                  config$R_MAX_SIZE,
                  config$R_MAX_VSIZE,
                  paste0(format(max_success$num_rows, big.mark = ","), " rows"),
                  format_bytes(max_success$file_size),
                  max_success$read_rate))
    } else {
      cat(sprintf("%-12s %-10s %-10s %-15s %-12s %-10s\n",
                  config_name,
                  config$R_MAX_SIZE,
                  config$R_MAX_VSIZE,
                  "FAILED",
                  "N/A",
                  "N/A"))
    }
  }
  
  return(batch_results)
}

# ================================================================
# INTERACTIVE CONFIGURATION SETUP
# ================================================================

setup_interactive_config <- function() {
  print_section("⚙️  INTERACTIVE MEMORY CONFIGURATION SETUP")
  
  cat("Current configuration:\n")
  cat("  R_MAX_SIZE:", R_MAX_SIZE, "\n")
  cat("  R_MAX_VSIZE:", R_MAX_VSIZE, "\n\n")
  
  cat("Quick configuration options:\n")
  cat("  1. Conservative (8G/6G) - Safe for most systems\n")
  cat("  2. Moderate (12G/10G) - Balanced performance\n")
  cat("  3. Aggressive (20G/16G) - High performance\n")
  cat("  4. Maximum (25G/20G) - Maximum available\n")
  cat("  5. Custom - Enter your own values\n")
  cat("  6. Current - Use current settings\n\n")
  
  repeat {
    choice <- readline("Select configuration (1-6): ")
    
    if (choice == "1") {
      R_MAX_SIZE <<- "8G"
      R_MAX_VSIZE <<- "6G"
      break
    } else if (choice == "2") {
      R_MAX_SIZE <<- "12G"
      R_MAX_VSIZE <<- "10G"
      break
    } else if (choice == "3") {
      R_MAX_SIZE <<- "20G"
      R_MAX_VSIZE <<- "16G"
      break
    } else if (choice == "4") {
      R_MAX_SIZE <<- "25G"
      R_MAX_VSIZE <<- "20G"
      break
    } else if (choice == "5") {
      R_MAX_SIZE <<- readline("Enter R_MAX_SIZE (e.g., 20G): ")
      R_MAX_VSIZE <<- readline("Enter R_MAX_VSIZE (e.g., 16G): ")
      break
    } else if (choice == "6") {
      break
    } else {
      cat("Invalid choice. Please enter 1-6.\n")
    }
  }
  
  cat("\nFinal configuration:\n")
  cat("  R_MAX_SIZE:", R_MAX_SIZE, "\n")
  cat("  R_MAX_VSIZE:", R_MAX_VSIZE, "\n")
}

# ================================================================
# ENHANCED MAIN EXECUTION WITH MULTIPLE MODES
# ================================================================

if (!interactive()) {
  # Handle different execution modes
  if (length(args) > 0 && args[1] == "batch") {
    # Batch mode - test multiple configurations
    cat("🧪 Starting BATCH MODE testing...\n")
    batch_results <- run_batch_memory_tests()
    
  } else if (length(args) > 0 && args[1] == "interactive") {
    # Interactive mode
    setup_interactive_config()
    results <- run_memory_configuration_test()
    
  } else {
    # Single configuration mode
    cat("🔥 Enhanced Memory Breaking Point Test Starting...\n")
    cat("Configuration: R_MAX_SIZE=", R_MAX_SIZE, ", R_MAX_VSIZE=", R_MAX_VSIZE, "\n")
    
    # Run the test
    results <- run_memory_configuration_test()
  }
  
} else {
  cat("\n🧪 CONFIGURABLE MEMORY TEST READY!\n")
  cat("Current configuration: R_MAX_SIZE=", R_MAX_SIZE, ", R_MAX_VSIZE=", R_MAX_VSIZE, "\n\n")
  
  cat("Available functions:\n")
  cat("  • run_memory_configuration_test() - Single test with current config\n")
  cat("  • run_batch_memory_tests() - Test multiple configurations\n")
  cat("  • setup_interactive_config() - Interactive configuration setup\n\n")
  
  cat("Quick usage examples:\n")
  cat("  # Test with specific values:\n")
  cat("  R_MAX_SIZE <- '15G'; R_MAX_VSIZE <- '12G'\n")
  cat("  results <- run_memory_configuration_test()\n\n")
  
  cat("  # Batch test multiple configurations:\n")
  cat("  batch_results <- run_batch_memory_tests()\n\n")
  
  cat("Command line usage:\n")
  cat("  Rscript configurable_memory_test.R 20G 16G    # Single test\n")
  cat("  Rscript configurable_memory_test.R batch      # Multiple configs\n")
  cat("  Rscript configurable_memory_test.R interactive # Interactive mode\n")
}
