# Open Street Map

MoveApps

Github repository: https://github.com/movestore/Open-Street-Map

## Description
Plot your tracks as lines and points on a background map. Choose from OpenStreetMap, ESRI and, with an API key, Stadia/Stamen, Thunderforest, Mapbox, MapTiler and Carto maps, set the map resolution and colours, and download the map as PNG or PDF.

## Documentation
This App plots all tracks of the input data as lines with their locations as points on a background map that covers the extent of the data. The background map is downloaded as map tiles from the selected provider.

The maps are split into two groups. Maps from OpenStreetMap and ESRI can be used without registration. Maps from Stadia/Stamen, Thunderforest, Mapbox, MapTiler and Carto need a personal API key, which can be obtained for free from the provider's website (a link to the website of the selected provider is shown in the App). The key is entered in the App and is never stored.

The map is drawn once when the App opens, with the stored settings (or the defaults). Afterwards, changes of the settings are only applied after clicking `Apply Changes`. The background map is only downloaded again when the map type, the API key or the resolution change; other changes (colours, legend, axis labels) only redraw the map.

For a first inspection of the different map types we recommend a low resolution, as it is much faster. The tracks are coloured by track; the colours stay the same with and without legend. The required credit of the map provider is shown below the map. The map can be downloaded as PNG and PDF file.

### Application scope
#### Generality of App usability
This App was developed for any taxonomic group.

#### Required data properties
The App should work for any kind of (location) data, in any coordinate reference system.

### Input type
`move2::move2_loc`

### Output type
`move2::move2_loc`

### Artefacts
none

The following files can be downloaded optionally (to disk):

`OpenStreetMap_<date>.png`: by clicking the `Save Map as PNG` button. Image of the map as currently shown in the App (10 x 8 inch, 300 dpi).

`OpenStreetMap_<date>.pdf`: by clicking the `Save Map as PDF` button. PDF of the map as currently shown in the App (10 x 8 inch).

### Settings
`Map source` (map_source): choose if the background map is selected from the maps that need no API key or from the maps that need an API key. Default: "No API key needed".

`Background map type` (maptype), shown for "No API key needed": choose the background map. Options: OpenStreetMap ("OSM Streets", "OSM Streets DE", "OSM Topographic") and ESRI ("ESRI NatGeo World Map", "ESRI USA Topo Maps", "ESRI World Imagery", "ESRI World Physical Map", "ESRI World Shaded Relief", "ESRI World Street Map", "ESRI World Terrain Base", "ESRI World Topo Map", "ESRI World Dark Gray Base", "ESRI World Light Gray Base", "ESRI World Hillshade Dark", "ESRI World Hillshade", "ESRI World Ocean Base", "ESRI World Navigation Charts"). Default: "OSM Streets".

`Background map type` (maptype_key), shown for "API key needed": choose the background map. Options: Stamen and Stadia ("Stamen Toner", "Stamen Toner BG", "Stamen Terrain", "Stamen Terrain BG", "Stamen Watercolor", "Stadia Alidade Smooth", "Stadia Alidade Smooth Dark", "Stadia Outdoors", "Stadia OSM Bright"), Thunderforest ("Thunderforest Cycle", "Thunderforest Transport", "Thunderforest Landscape", "Thunderforest Outdoors", "Thunderforest Transport Dark", "Thunderforest Spinal", "Thunderforest Pioneer", "Thunderforest Mobile Atlas", "Thunderforest Neighbourhood", "Thunderforest Atlas"), Mapbox ("Mapbox Streets", "Mapbox Outdoors", "Mapbox Light", "Mapbox Dark", "Mapbox Satellite", "Mapbox Hybrid"), MapTiler ("MapTiler Aquarelle", "MapTiler Backdrop", "MapTiler Basic", "MapTiler Bright", "MapTiler Dataviz", "MapTiler Landscape", "MapTiler Ocean", "MapTiler Outdoor", "MapTiler Satellite", "MapTiler Streets", "MapTiler Toner", "MapTiler Topo", "MapTiler Winter") and Carto ("Carto Light", "Carto Light No Labels", "Carto Dark", "Carto Dark No Labels", "Carto Voyager", "Carto Voyager No Labels", "Carto Voyager Labels Under"). Default: "Stadia Outdoors".

`API key for the selected map provider` (api_key), shown for "API key needed": your personal API key of the provider of the selected map. A link to the website where the key can be obtained is shown below the field. For security reasons the key is not stored with the settings and has to be entered again each time the App is opened. No default.

`Resolution of background map` (zoomin): resolution of the background map, relative to the extent of the data. Options: "very low", "low", "high", "very high". Each step doubles the number of map tiles along each side of the map. Default: "very low".

`Colour palette` (track_pal): colour palette for the tracks. Options: "Glasbey", "Set1", "Set2", "Set3", "Dark2", "Paired", "Accent". If there are more tracks than the palette has colours, evenly spread colours are used instead. Default: "Glasbey".

`Show legend with track names` (legend): choose if the track names are shown in a legend. Default: not shown.

`Label direction` (xlab_angle): direction of the labels of the x-axis (longitude). Options: "horizontal", "45°", "vertical". Rotating the labels helps when they overlap. Default: "horizontal".

`Number of labels` (xlab_n): number of labels on the x-axis. Options: "automatic", 2 to 8. With "automatic", fewer labels are used for narrow maps (2 for maps much taller than wide, 3 for about square maps, 5 for wide maps). Default: "automatic".

`Apply Changes`: click to apply the changed settings to the map.

`Store settings`: click to store the current settings of the App for future Workflow runs.

`Restore default settings`: click to restore to the default setting values of the App.

### Changes in output data
The input data remains unchanged.

### Errors and null handling
**Setting `API key for the selected map provider`:** If a map that needs an API key is selected and no key is entered, the tracks are shown without background map and a message asks to enter the key. This also happens after reopening the App with stored settings, as the key is not stored: enter the key and click `Apply Changes`.

**Wrong API key:** If CARTO does not accept the key, a message states this and the tracks are shown without background map. If another provider does not accept the key, or the background map cannot be downloaded for other reasons (e.g. the map server cannot be reached), the tracks are shown without background map and a message with the details is shown. Check the key or choose another map type.

**Setting `Resolution of background map`:** For data covering a large area, a high resolution would require very many map tiles. The resolution is then reduced automatically to stay below 400 tiles, and a message informs about it.

**Input data:** Locations with empty coordinates are not plotted. Tracks with only one location are shown as a point without line. All locations remain in the output data.

**Scale bar:** The map is drawn in Web Mercator projection, in which distances are increasingly stretched towards the poles. The scale bar is therefore only correct close to the middle latitude of the map; for maps covering a wide range of latitudes it can be inaccurate at the top and bottom of the map.

### Technical details
- The background maps are downloaded with the `basemaps` package (`basemap_gglayer()`), and the map is drawn with `ggplot2`, `sf` and `ggspatial` (scale bar).
- The map is drawn in Web Mercator projection (EPSG:3857), the projection of the map tiles. The axes show longitude and latitude. The data are transformed for plotting only; the output data keep their original projection.
- The zoom level of the map tiles is calculated from the extent of the data: at "high" resolution the longer side of the map is covered by about 4 tiles. The number of tiles is limited to 400.
- `basemaps` (version 0.1.1) does not send an API key to Carto, although CARTO now requires one. The App adds the key parameter to the Carto entries of the `basemaps` service list. Because CARTO answers a wrong key with a watermark image instead of an error, the App compares one tile downloaded with the given key with one downloaded with a dummy key to detect a rejected key.
- Map tiles are cached during a session. For maps that need an API key they are always downloaded again, so that tiles from an earlier, wrong key are not reused.
- Track colours are taken from `pals` (Glasbey) or `RColorBrewer`; with more tracks than palette colours, colours with evenly spread hues (golden angle) and alternating lightness are generated.
- For local testing, the API key field can be pre-filled from the environment variable `MAP_API_KEY` (e.g. set in a `.Renviron` file that is excluded from git). On MoveApps this variable is not set, so the field is empty.