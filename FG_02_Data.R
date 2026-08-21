# Packages
library(readr)
library(tidyverse)
library(stringr)
library(deeplr)
library(dplyr)
library(purrr)
library(countrycode)
library(tibble)


# Load Raw Data
TS_2024 <- read.csv('/Data_Raw/TS_Raw_2024.csv')
TS_2025 <- read.csv('/TS_Raw_2025.csv')
NYT_24_25_Raw <- read.csv('/NYT_Raw.csv')

## Data Wrangling

# TS - Delete 2025s in TS_202
TS_2024 <- TS_2024 %>%
  filter(!grepl("2025", date))

# TS - Combine TS 2024 and 2025 too one dataset
TS_Raw_Combined_DE <- rbind(TS_2024, TS_2025)

#TS - Replace non-breaking spaces and double whitespaces, "mehr", and author name at the end of the texts.
TS_clean_DE <- TS_Raw_Combined_DE %>%
  mutate(text = text %>%
           str_replace_all("\u00A0", " ") %>%
           str_replace_all("\\s{2,}", " ") %>%
           str_trim() %>%
           str_remove("Von [A-Z].*?\\.(?=\\s*mehr|$)") %>%
           str_replace_all("\\.\\s*\\.", ".") %>% 
           str_remove("\\s*(?i)mehr$") %>%
           str_replace_all("\\s{2,}", " ") %>%
           str_trim())

# TS - Extract Date Information and change data type to date. Remove NAs
TS_clean_DE <- TS_clean_DE %>%
  mutate(date = as.Date(substr(date, 1, 10), format = "%d.%m.%Y")) %>% 
  drop_na(text) %>%
  filter(text != "")

# NYT Delete Duplicates, Delete Cases without Snippet, Remove lead_paragraph variable
NYT_clean_EN <- NYT_24_25_Raw %>%
  filter(!is.na(snippet), snippet != "") %>%
  distinct(headline, .keep_all = TRUE) %>% 
  select(-lead_paragraph)

# save NYT Data
write.csv(NYT_clean_EN, "NYT_clean_EN.csv")

# # Translation of TS (German -> English) with API Key by DeeplPro (One Time Use, Only with Key)

# #Sys.setenv(DEEPL_AUTH_KEY = "Key input here")
# #TS_EN <- TS_clean_DE %>%
#   rename(ts_text_de = text) %>%
#   mutate(ts_text_en = NA_character_)
#
# # Translation by Deepl Translate
# translate_batch <- function(texts) {
#   deeplr::translate(
#     texts,
#     target_lang = "EN"
#   )
# }
# batch_size <- 100
# batches <- split(
#   TS_EN$ts_text_de,
#   ceiling(seq_along(TS_EN$ts_text_de) / batch_size)
# )
#
# translations <- map(batches, translate_batch) %>% unlist()
# TS_EN$ts_text_en <- translations
#
# saveRDS(TS_EN, "TS_translated_en_v1.rds")
# write.csv(TS_EN, "TS_clean_EN.csv") # safes as csv



# PART 2 - Merging TS and NYT
# Load Data
TS_Clean <- read.csv('/TS_clean_EN.csv', row.names = 1)
NYT_Clean <- read.csv('/NYT_clean_EN.csv', row.names = 1)

# Prepare Data for Merging
TS_Clean <- TS_Clean %>%
  transmute(
    headline = headline,
    text  = ts_text_en,
    date     = as.Date(date),
    outlet   = "TS"
  )

NYT_Clean <- NYT_Clean %>%
  transmute(
    headline = headline,
    text  = snippet,
    date     = as.Date(date),
    outlet   = "NYT"
  )

# Merging (adding)
Combined_TS_NYT <- bind_rows(TS_Clean, NYT_Clean)

# sort by date
Combined_TS_NYT <- Combined_TS_NYT %>% arrange(date)

# Check text lenght
Combined_TS_NYT$char_count <- nchar(Combined_TS_NYT$text)

# remove case if text <50 character long (only n=46 cases)
Combined_TS_NYT <- Combined_TS_NYT[Combined_TS_NYT$char_count >= 50, ]

# create text full variable with headline and text merged
Combined_TS_NYT <- Combined_TS_NYT %>%
  mutate(
    text_full = str_squish(paste(headline, text, sep = " "))
  )

# save as csv
write.csv(Combined_TS_NYT, "Combined_TS_NYT.csv")



# optional Country Finder (identify countries in text variable)

# base country list using the countrycode package
countries <- countrycode::codelist %>%
  select(country.name.en, iso3c) %>%
  distinct() %>%
  filter(!is.na(iso3c)) %>%
  rename(
    iso = iso3c,
    country = country.name.en
  ) %>%
  mutate(
    country_regex = str_replace_all(country, " ", "[\\s-]+"),
    pattern = paste0("\\b", country_regex, "s?\\b")
  ) %>%
  select(iso, pattern)

# extensions for high-frequency cases
demonyms <- tibble(
  iso = c(
    "RUS", "ISR", "KOR", "PRK",
    "USA", "GBR", "DEU", "FRA", "CHN"
  ),
  pattern = c(
    "\\bRussian(s)?\\b",
    "\\bIsraeli(s)?\\b",
    "\\bSouth[\\s-]+Korean(s)?\\b",
    "\\bNorth[\\s-]+Korean(s)?\\b",
    "\\bAmerican(s)?\\b",
    "\\bBritish\\b",
    "\\bGerman(s)?\\b",
    "\\bFrench\\b",
    "\\bChinese\\b"))

# abbreviations not covered by countrycode names
abbreviations <- tibble(
  iso = c("USA", "USA", "GBR"),
  pattern = c("\\bUS\\b", "\\bUSA\\b", "\\bUK\\b"))

# final pattern table
country_patterns <- bind_rows(
  countries,
  demonyms,
  abbreviations)

# country detection function
detect_countries <- function(text, patterns) {
  if (is.na(text) || text == "") return(character(0))
  patterns$iso[
    map_lgl(
      patterns$pattern,
      ~ str_detect(text, regex(.x, ignore_case = TRUE))
    )
  ] %>% unique()}

# apply to Combined_TS_NYT using combined text
Combined_TS_NYT_C <- Combined_TS_NYT %>%
  mutate(
    country_list = map(text_full, detect_countries, patterns = country_patterns),
    country_n    = map_int(country_list, length),
    country_iso  = map_chr(
      country_list,
      ~ ifelse(length(.x) > 0, .x[1], NA_character_)
    ))

# remove list variable (country_list) because it cannot be safed as csv
Combined_TS_NYT_C <- Combined_TS_NYT_C %>%
  select(-country_list)

# safe as csv
write.csv(Combined_TS_NYT_C, "Combined_TS_NYT_C.csv")



# split into TS / NYT
TS_Input <- Combined_TS_NYT_C %>%
  filter(outlet == "TS") # includes 2414 cases with country n = 0

NYT_Input <- Combined_TS_NYT_C %>%
  filter(outlet == "NYT") # includes 2539 cases with country n = 0


write.csv(TS_Input, "TS_Input.csv")
write.csv(NYT_Input, "NYT_Input.csv")
