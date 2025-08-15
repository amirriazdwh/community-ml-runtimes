#https://docs.cloudera.com/machine-learning/cloud/spark/topics/ml-installing-sparklyr.html

library(sparklyr)

# Set Spark configuration
config <- spark_config()
config$spark.executor.cores <- 1
config$spark.executor.memory <- "2g"

# Connect to Spark
sc <- spark_connect(master = "yarn", config = config)

# Run a sample query
dbs <- DBI::dbGetQuery(sc, "SHOW DATABASES")
print(dbs)