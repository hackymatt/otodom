# 🏠 Otodom Scraper

This repository contains two R scripts for scraping apartment listings from **[otodom.pl](https://www.otodom.pl/)**.  
The scripts collect ads for **rentals** and **sales** in major Polish cities.  

---

## 📦 Requirements

Make sure you have R installed. Then install required packages:

```r
install.packages(c("rvest", "dplyr", "stringr"))
````

---

## 📂 Scripts

* **`rent.R`** – scrapes rental offers
* **`sale.R`** – scrapes sale offers

Each script will create a CSV file with the results.

---

## ⚙️ Configuration

Inside each script, you can configure:

* `TIME_RANGE` – how many days back to fetch ads (default: `7`)
* `OUTPUT_FILE` – name of the CSV file where results are saved
* `INPUT_FILE` – optional file to append previous results
* `vCities` – list of cities to scrape (16 major Polish cities by default)

---

## ▶️ Usage

Run a script in R:

```r
# For rentals
source("rent.R")

# For sales
source("sale.R")
```

After execution, you’ll find the results saved in CSV format.

---

## 📊 Output

Each output file contains columns such as:

* **City** – city name
* **URL** – link to the ad
* **Title** – title of the listing
* **Price** – price in PLN
* **Address** – ad address
* (+ possibly additional details, depending on available data)

---

## ⚠️ Notes

* Otodom shows **24 ads per page**, with a maximum of **500 pages**.
* Scraping may take several minutes depending on the number of cities and ads.
* Website structure may change, which could break the scraper.

---

## 📝 License

MIT License – feel free to use and modify.
