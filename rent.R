# ===============================
# Otodom Scraper
# ===============================
# Required packages:
#   install.packages(c("rvest", "dplyr", "stringr"))
# ===============================

library(rvest)
library(dplyr)
library(stringr)

# -------------------------------
# Configuration
# -------------------------------
TIME_RANGE <- 7   # how many days back to fetch ads
OUTPUT_FILE <- "otodom_cities_rent.csv"       # output file
INPUT_FILE  <- "otodom_cities_rent_old.csv"   # previous dataset (if exists)

# List of cities to scrape
vCities <- c(
  "bialystok","bydgoszcz","gdansk","katowice","kielce",
  "krakow","lublin","lodz","olsztyn","opole",
  "poznan","rzeszow","szczecin","warszawa","wroclaw","zielona-gora"
)

# -------------------------------
# Helper functions
# -------------------------------

# Get number of ads for a given city and url
FindNoofAds <- function(url) {
  scraping_wiki <- read_html(url)
  
  number <- scraping_wiki %>%
    html_nodes("div.offers-index.pull-left.text-nowrap strong") %>%
    html_text()
  
  error <- scraping_wiki %>%
    html_nodes("div.search-location-extended-warning") %>%
    html_text()
  
  # if no error and number of ads exists
  if (length(error) == 0 && length(number) > 0) {
    start <- str_locate(number, "\n ")[2]
    number <- as.numeric(str_remove(str_trim(str_sub(number, start + 1)), " "))
  } else {
    number <- 0
  }
  
  return(number)
}

# Scrape details of a single ad
ScreapAd <- function(url_ad, city) {
  scraping_wiki <- read_html(url_ad)
  
  typead <- scraping_wiki %>%
    html_nodes("a.css-195qsqd.e9ta1i02") %>%
    xml_text() %>%
    .[1]
  
  datecreated <- scraping_wiki %>%
    html_nodes("script#__NEXT_DATA__") %>%
    xml_text() %>%
    {str_sub(., str_locate(., "dateCreated")[2] + 4,
                str_locate(., "dateModified")[1] - 4)}
  
  cena <- scraping_wiki %>%
    html_nodes("strong.css-srd1q3.edo911a17") %>%
    html_text() %>%
    {str_sub(., 1, str_locate(., " z ")[1] - 1)}
  
  address <- scraping_wiki %>%
    html_nodes("a.css-1qz7z11.eom7om61") %>%
    xml_text()
  
  # Extract details (labels + values)
  szczegoly <- scraping_wiki %>%
    html_nodes("div.css-o4i8bk.ecjfvbm2") %>% 
    html_text()
  
  val <- scraping_wiki %>%
    html_nodes("div.css-1ytkscc.ecjfvbm0") %>% 
    html_text()
  
  lab <- str_replace(szczegoly, val, "")
  lab[is.na(lab)] <- "Empty"
  
  # Base ad information
  base_info <- data.frame(
    City = city,
    URL = url_ad,
    Type = typead,
    ID = 0,
    Date = datecreated,
    Price = cena,
    Address = address,
    Title = 0,
    stringsAsFactors = FALSE
  )
  
  # Add extra details if available
  if (length(lab) > 0) {
    extra_info <- as.data.frame(as.list(val), stringsAsFactors = FALSE)
    names(extra_info) <- lab
    base_info <- cbind(base_info, extra_info)
  }
  
  return(base_info)
}

# Scrape all ads from multiple pages for a city
runScrapping <- function(start_page, city, last_page, TIME_RANGE) {
  urls <- paste0(
    "https://www.otodom.pl/wynajem/mieszkanie/", city,
    "/?page=", start_page:last_page,
    "&search%5Bcreated_since%5D=", TIME_RANGE
  )
  
  df <- data.frame()
  
  for (page in seq_along(urls)) {
    print(paste("Scrapping page", page, "of", last_page, "for", city))
    
    scraping_wiki_main <- read_html(urls[page])
    ads <- scraping_wiki_main %>%
      html_nodes("h3 a") %>%
      html_attr("href")
    
    for (i in seq_along(ads)) {
      print(paste("  Scrapping item", i, "of", length(ads)))
      new <- ScreapAd(ads[i], city)
      df <- bind_rows(df, new)
    }
  }
  return(df)
}

# -------------------------------
# Main Script
# -------------------------------
df <- data.frame()

for (city in vCities) {
  print(paste("Scrapping", city))
  
  url <- paste0(
    "https://www.otodom.pl/wynajem/mieszkanie/", city,
    "/?page=1&search%5Bcreated_since%5D=", TIME_RANGE
  )
  
  liczba_ogloszen <- FindNoofAds(url)
  print(paste("Found", liczba_ogloszen, "ads"))
  
  last_page <- min(ceiling(liczba_ogloszen / 24), 500)
  
  if (last_page > 0) {
    city_df <- runScrapping(1, city, last_page, TIME_RANGE)
    df <- bind_rows(df, city_df)
  }
}

# -------------------------------
# Save Results
# -------------------------------
# If previous dataset exists, merge with it
if (file.exists(INPUT_FILE)) {
  old_df <- read.csv(INPUT_FILE, check.names = FALSE)
  df <- bind_rows(old_df, df)
}

# Keep only first 22 columns and remove duplicates by ID
df <- df %>%
  select(1:min(22, ncol(.))) %>%
  distinct(ID, .keep_all = TRUE)

write.csv(df, OUTPUT_FILE, row.names = FALSE)
print(paste("Saved results to", OUTPUT_FILE))
