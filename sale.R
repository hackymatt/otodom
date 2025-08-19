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
TIME_RANGE <- 7                  # how many days back to fetch ads
OUTPUT_FILE <- "otodom_cities_sale.csv"   # output CSV file
INPUT_FILE  <- "otodom_cities_sale_old.csv" # optional input file to append (if exists)

# List of cities to scrape
vCities <- c(
  "bialystok","bydgoszcz","gdansk","katowice","kielce",
  "krakow","lublin","lodz","olsztyn","opole",
  "poznan","rzeszow","szczecin","warszawa","wroclaw","zielona-gora"
)

# -------------------------------
# Helper functions
# -------------------------------

# Function to find the number of ads for a given city and URL
FindNoofAds <- function(url) {
  scraping_wiki <- read_html(url)
  
  number <- scraping_wiki %>%
    html_nodes("div.offers-index.pull-left.text-nowrap strong") %>%
    html_text()
  
  error <- scraping_wiki %>%
    html_nodes("div.search-location-extended-warning") %>%
    html_text()
  
  # if there is no error and we got a number of ads
  if (length(error) == 0 && length(number) > 0) {
    return(as.numeric(gsub("[^0-9]", "", number)))
  } else {
    return(0)
  }
}

# Function to scrape ads for a given city
ScrapeCity <- function(city) {
  base_url <- paste0("https://www.otodom.pl/pl/oferty/wynajem/mieszkanie/", city, "?daysSinceCreated=", TIME_RANGE)
  
  n_ads <- FindNoofAds(base_url)
  if (n_ads == 0) {
    message("No ads found for ", city)
    return(NULL)
  }
  
  # Otodom shows 24 ads per page
  n_pages <- ceiling(n_ads / 24)
  if (n_pages > 500) n_pages <- 500   # Otodom limit
  
  results <- data.frame()
  
  for (i in 1:n_pages) {
    page_url <- paste0(base_url, "&page=", i)
    page <- read_html(page_url)
    
    ads <- page %>%
      html_nodes("article") 
    
    for (ad in ads) {
      link <- ad %>% html_node("a") %>% html_attr("href")
      title <- ad %>% html_node("h3") %>% html_text(trim = TRUE)
      price <- ad %>% html_node("span[aria-label='Cena']") %>% html_text(trim = TRUE)
      address <- ad %>% html_node("p") %>% html_text(trim = TRUE)
      
      results <- rbind(results, data.frame(
        City = city,
        URL = link,
        Title = title,
        Price = price,
        Address = address,
        stringsAsFactors = FALSE
      ))
    }
  }
  
  return(results)
}

# -------------------------------
# Main script
# -------------------------------

all_results <- data.frame()

for (city in vCities) {
  message("Scraping: ", city)
  city_data <- ScrapeCity(city)
  if (!is.null(city_data)) {
    all_results <- rbind(all_results, city_data)
  }
}

# Save results
if (nrow(all_results) > 0) {
  if (file.exists(INPUT_FILE)) {
    old_data <- read.csv(INPUT_FILE, stringsAsFactors = FALSE)
    all_results <- rbind(old_data, all_results)
  }
  write.csv(all_results, OUTPUT_FILE, row.names = FALSE)
  message("Saved results to ", OUTPUT_FILE)
} else {
  message("No data scraped.")
}
