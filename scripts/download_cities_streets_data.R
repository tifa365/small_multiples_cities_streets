# load libraries
library(tidyverse)
library(osmdata)
library(sf)
# Load the package required to read JSON files.
library(jsonlite)
library(ggtext)
library(exactextractr)
library(fasterize)
library(ggtext)
library(tidygeocoder)
library(glue)
library(purrr)
library(geosphere)
library(classInt)
library(patchwork)
library(glue)

# Activating the S2 library for more accurate spherical geometry computations in the 'sf' package
sf::sf_use_s2(TRUE)

# EPSG 4326 is actually the standard spatial reference system for geographical coordinates worldwide
epsg <- 4326

# List of cities in chunks of 5, so easier to count and arrange on the plot
# Get list of city names from cities.txt file
cities <- readLines("cities.txt")

# Give the input file name to the function.
city_coordinates <- fromJSON("city_coordinates.json")
  
# Create function to download street data for each city and draw plots
create_plot_for_city <- function(city_name) {
  # Split the city name at the comma and get the first part
  city_name_only <- strsplit(city_name,",")[[1]][1]

  # Establish title and path of combined plot
  file_path <- "plots/combined_plot.png"

  # Check if the main plot already exists
  if (file.exists(file_path)) {
    print(paste("Plot already exists:", file_path))
  } else {
    # Create a folder to save city data
    dir.create("city_data_streets", showWarnings = FALSE)
    
    # If plot is not already existing, get coordinates
    city_coordinates <- city_coordinates[[city_name]]
    print(city_coordinates)

    # Check if city coordinates are already in the JSON file
    if (city_name_only %in% names(city_coordinates)) {
      # Get coordinates from JSON file
      coordinates <- city_coordinates[[city_name_only]]
      print(paste0("City coordinates retrieved from file: ", city_name_only,". ", 
                   "Geocoordinates: ", coordinates,". ",
                   "Now downloading OpenStreetMap street data. Please be patient."))
      # Create sf object from coordinates
      city <- st_as_sf(data.frame(long = coordinates[1], lat = coordinates[2]), 
                       coords = c('long', 'lat'), crs = 4326) %>%
        st_transform(32632)
    } else {
        source('scripts/get_city_geocoordinates.R')
      }

    max_tries <-5 # Maximum number of download retry attempts if we hit the OpenStreetMap API limit

    # Create a R for-loop to restart download process if API throws an error and or hits a limit
    for (i in seq_len(max_tries)) {
      # tryCatch is used to catch any errors while downloading and force restart
      tryCatch({
        # Download data for big streets
        if (file.exists(glue("city_data_streets/{city_name_only}_big_streets.rds"))) {
          big_streets <-
            readRDS(glue("city_data_streets/{city_name_only}_big_streets.rds"))
          print(paste0("Large streets already downloaded for ", city_name_only))
        } else {
          big_streets <- getbb(city_name) %>%
            opq(timeout =100) %>%
            add_osm_feature(
              key = "highway",
              value = c("motorway", "primary", "motorway_link", "primary_link")
            ) %>%
            osmdata_sf()
          big_streets <- big_streets$osm_lines %>%
            st_transform(epsg)
          print(paste("Small streets downloaded for", city_name_only))

          # Save big streets data to an RDS file in city_data_streets folder
          saveRDS(big_streets,
                  file = glue("city_data_streets/{city_name_only}_big_streets.rds"))
        }

        # Download data for medium streets
        if (file.exists(glue(
          "city_data_streets/{city_name_only}_medium_streets.rds"
        ))) {
          medium_streets <-
            readRDS(glue(
              "city_data_streets/{city_name_only}_medium_streets.rds"
            ))
          print(paste("Medium streets already downloaded for", city_name_only))
        } else {
          medium_streets <- getbb(city_name) %>%
            opq(timeout = 100) %>%
            add_osm_feature(
              key = "highway",
              value = c(
                "secondary",
                "tertiary",
                "secondary_link",
                "tertiary_link"
              )
            ) %>%
            osmdata_sf()
          medium_streets <- medium_streets$osm_lines %>%
            st_transform(epsg)
          print(paste("Medium streets downloaded for", city_name_only))

          # Save medium streets data to an RDS file
          saveRDS(
            medium_streets,
            file = glue(
              "city_data_streets/{city_name_only}_medium_streets.rds"
            ))
        }

        # Download data for small streets
        if (file.exists(glue("city_data_streets/{city_name_only}_small_streets.rds"))) {
          small_streets <-
            readRDS(glue(
              "city_data_streets/{city_name_only}_small_streets.rds"
            ))
          print(paste("Small streets already downloaded for", city_name_only))
          print(
            paste0(
              "Done downloading small streets for ",
              city_name_only,
              "."
            )
          )
        } else {
          small_streets <- getbb(city_name) %>%
            opq(timeout = 100) %>%
            add_osm_feature(
              key = "highway",
              value = c(
                "residential",
                "living_street",
                "unclassified",
                "service",
                "footway"
              )
            ) %>%
            osmdata_sf()
          small_streets <- small_streets$osm_lines %>%
            st_transform(epsg)

          # Save small streets data to an RDS file
          saveRDS(
            small_streets,
            file = glue(
              "city_data_streets/{city_name_only}_small_streets.rds"
            ))
          print(paste("Small streets downloaded for", city_name_only))
        }

        # If the download is successful, break the loop
        break
      },
      error = function(e) {
        # If the download fails, print the error message
        print(paste("Download attempt", i, "failed:", e$message))

        # If this was the last attempt, stop with an error
        if (i == max_tries) {
          stop("Maximum number of download attempts exceeded")
        }

        # Otherwise, wait a bit before the next attempt
        Sys.sleep(5)
      })
    }

    print(
      paste0(
        "Done downloading small, medium and large streets for ",
        city_name_only,
        "."
      )
    )
  }
}

# Run function
purrr::map(cities, create_plot_for_city)