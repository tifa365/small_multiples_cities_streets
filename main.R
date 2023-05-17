# Download the street data (small, medium, large) for all cities in cities.txt
source("scripts/download_cities_streets_data.R")

# Create single streets plots for each city and combine into one, save to /plots folder
source("scripts/visualize_cities_streets.R")
