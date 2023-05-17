🔎 Uncover the intricate patterns of city street structures with #Rstats! By employing a few lines of our #Rspatial code, you can scrutinize street orientations and derive nice-looking visualizations for any city worldwide, by combining all cities into one plot in the style of "small multiples."

How-To:

! Careful, script will likely use a lot of memory and might crash with slower hardware !

1. Open cities.txt and manually add a number of German cities or use the ones already present. Best would be to use multiples of 5 because currently the code uses 5 cities per row. 
2. If the plots folder contains a "combined_plot.png" from previous projects - delete. The plot will not be overwritten.
3. Open terminal in the main folder and open R with "R". Then type 

source('main.R')

This might take a whole and should run the main script and create the plot. When done, the plot can be found in the /plots folder.   

Attributions: 

The code of this folder is in large parts based on Marco Sciani's (@shinysci) street orientation project.

Twitter: https://twitter.com/shinysci/status/1656284290198433792
Github: https://gist.github.com/marcosci/2a26e936c007e58493bf5fc8a2c25209

All map data copyrighted OpenStreetMap contributors and available from https://www.openstreetmap.org.
