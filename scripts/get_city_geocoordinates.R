# Load required packages
library(jsonlite)
library(tidygeocoder)

# Get list of city names from cities.txt file
cities <- readLines("cities.txt")

# Check if the JSON file containing city coordinates exists
if (file.exists("city_coordinates.json")) {
  city_coordinates <- fromJSON("city_coordinates.json")
} else {
  city_coordinates <- list()
}

# Loop through the list of cities
for (city_name in cities) {
  # Check if the city's coordinates are already in the JSON file
  if (city_name %in% names(city_coordinates)) {
    print(paste0("City coordinates already in file: ", city_name))
  } else {
    # If not, geocode the city and write the coordinates to the JSON file
    city <- tidygeocoder::geo(city_name) %>%
      st_as_sf(coords = c('long', 'lat'), crs = 4326) %>%
      # needs to be transformed to an epsg with meters to calculate radius
      st_transform(32632)
    city_coordinates[[city_name]] <- st_coordinates(city)[1, ]
    write_json(city_coordinates, "../city_coordinates.json", pretty = TRUE)
    print(paste0("City geocoded and saved to file: ", city_name))
  }
}

print(city_coordinates)
