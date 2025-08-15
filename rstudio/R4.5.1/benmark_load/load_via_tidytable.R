library(tidytable)

df <- fread("file.csv") %>% as_tidytable()

df %>%
  filter(x > 5) %>%
  group_by(y) %>%
  summarise(avg = mean(z))
