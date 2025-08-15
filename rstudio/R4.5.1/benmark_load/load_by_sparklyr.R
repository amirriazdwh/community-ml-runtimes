library(sparklyr)

sc <- spark_connect(master = "https://dev02dhde-gateway.dev04cdp.axpq-jlhv.cloudera.site/dev02dhde/cdp-proxy/livy_for_spark3",
                    version = "2.4.0",
                    method = "livy", config = livy_config(
                      username = "bdp_008752",
                      password = rstudioapi::askForPassword("Livy password:")))

