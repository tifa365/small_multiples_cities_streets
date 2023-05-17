library(ggplot2)
library(sf)
library(dplyr)
library(patchwork)
library(readr)

# Activating the S2 library for more accurate spherical geometry computations in the 'sf' package
sf::sf_use_s2(TRUE)

# EPSG 4326 is actually the standard spatial reference system for geographical coordinates worldwide
epsg <- 4326

create_plot_for_city <- function(city_name) {
  # Define file paths for each street size
  small_streets_path <- paste0("city_data_streets/", city_name, "_small_streets.rds")
  medium_streets_path <- paste0("city_data_streets/", city_name, "_medium_streets.rds")
  big_streets_path <- paste0("city_data_streets/", city_name, "_big_streets.rds")
  
  # Read in the data
  small_streets <- readRDS(small_streets_path)
  medium_streets <- readRDS(medium_streets_path)
  big_streets <- readRDS(big_streets_path)
  
  # Read the JSON file containing city coordinates
  # If the file does not exist, create an empty list
  if (file.exists("city_coordinates.json")) {
    city_coordinates <- fromJSON("city_coordinates.json")
  } else {
    print("No geocordinates JSON file found.")
  }
  
  # Check if city coordinates are already in the JSON file
  if (city_name %in% names(city_coordinates)) {
    
    # Get coordinates from JSON file
    coordinates <- city_coordinates[[city_name]]
    print(paste0("City coordinates retrieved from file: ", city_name,". ", 
                 "Now downloading OpenStreetMap street data. Please be patient."))
    
    # Create sf object from coordinates
    city <- st_as_sf(data.frame(long = coordinates[1], lat = coordinates[2]), 
                     coords = c('long', 'lat'), crs = 32632)
  } else {
    # If city coordinates are not in the JSON file, use script to get them
    source('get_city_geocoordinates.R')
  }
  
  # Create a buffer around the city center using the coordinates retrieved or geocoded
  crop_buffer <- st_buffer(city, 7500) %>%
    st_transform(epsg)
  
  print(crop_buffer)
  
  # Crop the streets data to the buffer area
  small_streets_crop <- st_crop(small_streets, crop_buffer)
  small_streets_crop <- st_intersection(small_streets_crop, crop_buffer)
  medium_streets_crop <- st_crop(medium_streets, crop_buffer)
  medium_streets_crop <- st_intersection(medium_streets_crop, crop_buffer)
  big_streets_crop <- st_crop(big_streets, crop_buffer)
  big_streets_crop <- st_intersection(big_streets_crop, crop_buffer)

# Create the plot using ggplot
street_plot <- ggplot() +
  geom_sf(
    data = small_streets_crop,
    color = colors[1],
    lwd = .25,
    alpha = 0.8
  ) +
  geom_sf(
    data = medium_streets_crop,
    color = colors[2],
    lwd = .75,
    alpha = 0.6
  ) +
  geom_sf(data = big_streets_crop,
          color = colors[3],
          alpha = 0.4) +
  theme_void() +
  ggtitle(city_name) +
  theme(plot.title = element_text(hjust = 0.5))

# Return the plot
return(street_plot)
}

# Read city names from cities.txt file
cities <- readLines("cities.txt")

# Define colors for plots
colors <- c("#e56399", "#e5d4ce", "#de6e4b")

# Generate the plots for all cities
city_plots <- lapply(cities, create_plot_for_city)

# Use patchwork to combine the plots
combined_plot <- wrap_plots(city_plots, ncol = 5) +
  plot_annotation(
    title = "Straßenlayout deutscher Städte",
    theme = theme(
      plot.title = element_text(hjust = 0.5, size = 20, face = "bold", margin = margin(b = 20))
    )
  )

file_path <- "plots/combined_plot.png"

ggsave(file_path, width = 6, height = 9, dpi = 600)

print("Printing plot is done and plot saved into /plots folder.")