library("shiny")
library("move2")
library("ggplot2")

## ---- helpers -------------------------------------------------------------

# background maps, as "service:type" for basemaps::basemap_gglayer()
# list follows the moveVis App. Not included: Mapbox Terrain (elevation encoded
# as colours, not a map), ESRI Antarctic Imagery and Arctic Ocean Base (polar
# projections, cannot be shown in Web Mercator)
# maps without API key
map_choices_free <- list(
  "OpenStreetMap" = c(
    "OSM Streets" = "osm:streets",
    "OSM Streets DE" = "osm:streets_de",
    "OSM Topographic" = "osm:topographic"),
  "ESRI" = c(
    "ESRI NatGeo World Map" = "esri:natgeo_world_map",
    "ESRI USA Topo Maps" = "esri:usa_topo_maps",
    "ESRI World Imagery" = "esri:world_imagery",
    "ESRI World Physical Map" = "esri:world_physical_map",
    "ESRI World Shaded Relief" = "esri:world_shaded_relief",
    "ESRI World Street Map" = "esri:world_street_map",
    "ESRI World Terrain Base" = "esri:world_terrain_base",
    "ESRI World Topo Map" = "esri:world_topo_map",
    "ESRI World Dark Gray Base" = "esri:world_dark_gray_base",
    "ESRI World Light Gray Base" = "esri:world_light_gray_base",
    "ESRI World Hillshade Dark" = "esri:world_hillshade_dark",
    "ESRI World Hillshade" = "esri:world_hillshade",
    "ESRI World Ocean Base" = "esri:world_ocean_base",
    "ESRI World Navigation Charts" = "esri:world_navigation_charts")
)

# maps that need an API key
map_choices_key <- list(
  "Stamen and Stadia" = c(
    "Stamen Toner" = "osm_stamen:toner",
    "Stamen Toner BG" = "osm_stamen:toner_bg",
    "Stamen Terrain" = "osm_stamen:terrain",
    "Stamen Terrain BG" = "osm_stamen:terrain_bg",
    "Stamen Watercolor" = "osm_stamen:watercolor",
    "Stadia Alidade Smooth" = "osm_stadia:alidade_smooth",
    "Stadia Alidade Smooth Dark" = "osm_stadia:alidade_smooth_dark",
    "Stadia Outdoors" = "osm_stadia:outdoors",
    "Stadia OSM Bright" = "osm_stadia:osm_bright"),
  "Thunderforest" = c(
    "Thunderforest Cycle" = "osm_thunderforest:cycle",
    "Thunderforest Transport" = "osm_thunderforest:transport",
    "Thunderforest Landscape" = "osm_thunderforest:landscape",
    "Thunderforest Outdoors" = "osm_thunderforest:outdoors",
    "Thunderforest Transport Dark" = "osm_thunderforest:transport_dark",
    "Thunderforest Spinal" = "osm_thunderforest:spinal",
    "Thunderforest Pioneer" = "osm_thunderforest:pioneer",
    "Thunderforest Mobile Atlas" = "osm_thunderforest:mobile_atlas",
    "Thunderforest Neighbourhood" = "osm_thunderforest:neighbourhood",
    "Thunderforest Atlas" = "osm_thunderforest:atlas"),
  "Mapbox" = c(
    "Mapbox Streets" = "mapbox:streets",
    "Mapbox Outdoors" = "mapbox:outdoors",
    "Mapbox Light" = "mapbox:light",
    "Mapbox Dark" = "mapbox:dark",
    "Mapbox Satellite" = "mapbox:satellite",
    "Mapbox Hybrid" = "mapbox:hybrid"),
  "MapTiler" = c(
    "MapTiler Aquarelle" = "maptiler:aquarelle",
    "MapTiler Backdrop" = "maptiler:backdrop",
    "MapTiler Basic" = "maptiler:basic",
    "MapTiler Bright" = "maptiler:bright",
    "MapTiler Dataviz" = "maptiler:dataviz",
    "MapTiler Landscape" = "maptiler:landscape",
    "MapTiler Ocean" = "maptiler:ocean",
    "MapTiler Outdoor" = "maptiler:outdoor",
    "MapTiler Satellite" = "maptiler:satellite",
    "MapTiler Streets" = "maptiler:streets",
    "MapTiler Toner" = "maptiler:toner",
    "MapTiler Topo" = "maptiler:topo",
    "MapTiler Winter" = "maptiler:winter"),
  "Carto" = c(
    "Carto Light" = "carto:light",
    "Carto Light No Labels" = "carto:light_no_labels",
    "Carto Dark" = "carto:dark",
    "Carto Dark No Labels" = "carto:dark_no_labels",
    "Carto Voyager" = "carto:voyager",
    "Carto Voyager No Labels" = "carto:voyager_no_labels",
    "Carto Voyager Labels Under" = "carto:voyager_labels_under")
)

# services for which basemaps sends the API key
key_services <- c("osm_stamen", "osm_stadia", "osm_thunderforest", "mapbox", "maptiler", "carto")

# where to get a key, per service
key_sites <- c(
  osm_stamen = "https://stadiamaps.com/",
  osm_stadia = "https://stadiamaps.com/",
  osm_thunderforest = "https://www.thunderforest.com/",
  mapbox = "https://www.mapbox.com/",
  maptiler = "https://www.maptiler.com/",
  carto = "https://carto.com/basemaps/apikey/"
)

# map area for the zoom slider: 0 shows all data, each step zooms in (positive)
# or out (negative) on the centre of the data by a factor of 1.5, limited to
# the extent of Web Mercator
zoom_bb <- function(bb, zoom) {
  lim <- 20037508.34
  f <- 1.5^(-zoom)
  cx <- (bb[["xmin"]] + bb[["xmax"]]) / 2
  cy <- (bb[["ymin"]] + bb[["ymax"]]) / 2
  hw <- (bb[["xmax"]] - bb[["xmin"]]) / 2 * f
  hh <- (bb[["ymax"]] - bb[["ymin"]]) / 2 * f
  bb[c("xmin", "xmax")] <- pmin(pmax(c(cx - hw, cx + hw), -lim), lim)
  bb[c("ymin", "ymax")] <- pmin(pmax(c(cy - hh, cy + hh), -lim), lim)
  bb
}

# CARTO now needs a key ("?key=" in the tile URL), but basemaps 0.1.1 has no
# key parameter for it: add it to basemaps' service table, unless a newer
# basemaps version already has one
enable_carto_key <- function() {
  loadNamespace("basemaps")
  api <- getOption("basemaps.map_api")
  carto <- api$map_service == "carto"
  if (any(carto) && all(is.na(api$url_map_token[carto]))) {
    api[carto, "url_map_token"] <- "?key="
    options(basemaps.map_api = api)
  }
}

# CARTO answers a missing or wrong key with a watermark tile instead of an
# error: the key is rejected when its tile is identical to one with a dummy key
carto_key_ok <- function(map_type, key) {
  api <- getOption("basemaps.map_api")
  endpoint <- api$url_endpoint[api$map_service == "carto" & api$map_type == map_type]
  files <- c(tempfile(fileext = ".png"), tempfile(fileext = ".png"))
  on.exit(unlink(files))
  ok <- tryCatch({
    utils::download.file(paste0(endpoint, "0/0/0.png?key=", utils::URLencode(key, reserved = TRUE)),
                         files[1], mode = "wb", quiet = TRUE)
    utils::download.file(paste0(endpoint, "0/0/0.png?key=invalid"), files[2], mode = "wb", quiet = TRUE)
    TRUE
  }, error = function(e) FALSE)
  # if the check itself fails, let basemaps try anyway
  if (!ok) return(TRUE)
  unname(tools::md5sum(files[1]) != tools::md5sum(files[2]))
}

# credit line required by the map providers
map_credits <- c(
  osm = "\u00a9 OpenStreetMap contributors",
  osm_stamen = "\u00a9 Stadia Maps \u00a9 Stamen Design \u00a9 OpenMapTiles \u00a9 OpenStreetMap contributors",
  osm_stadia = "\u00a9 Stadia Maps \u00a9 OpenMapTiles \u00a9 OpenStreetMap contributors",
  osm_thunderforest = "\u00a9 Thunderforest \u00a9 OpenStreetMap contributors",
  mapbox = "\u00a9 Mapbox \u00a9 OpenStreetMap contributors",
  maptiler = "\u00a9 MapTiler \u00a9 OpenStreetMap contributors",
  esri = "Tiles \u00a9 Esri and its data providers",
  carto = "\u00a9 OpenStreetMap contributors \u00a9 CARTO"
)

# tile zoom for a Web Mercator bbox: about 4 tiles along the longer side at
# "high" (zoomin = 0); each zoomin step doubles the tiles along each side
tile_zoom <- function(bb, zoomin) {
  world <- 2 * 20037508.34
  side <- max(bb["xmax"] - bb["xmin"], bb["ymax"] - bb["ymin"], 1)
  z <- floor(log2(4 * world / side)) + zoomin
  min(max(z, 1), 18)
}

# number of tiles needed for a bbox at zoom z
n_tiles <- function(bb, z) {
  tile <- 2 * 20037508.34 / 2^z
  (ceiling((bb["xmax"] - bb["xmin"]) / tile) + 1) * (ceiling((bb["ymax"] - bb["ymin"]) / tile) + 1)
}

max_tiles <- 400

# track colours: first n colours of the palette; with more tracks than the
# palette has colours, evenly spread HCL hues (golden angle) with alternating
# lightness instead
track_colors <- function(pal_name, n) {
  if (n <= 0) return(character(0))
  base <- if (pal_name == "Glasbey") pals::glasbey(32) else
    RColorBrewer::brewer.pal(RColorBrewer::brewer.pal.info[pal_name, "maxcolors"], pal_name)
  if (n <= length(base)) return(base[seq_len(n)])
  hues <- ((0:(n - 1)) * 137.50776405003785) %% 360
  grDevices::hcl(h = hues, c = 70, l = c(55, 75, 40)[(0:(n - 1)) %% 3 + 1])
}

## ---- UI ------------------------------------------------------------------

shinyModuleUserInterface <- function(id, label) {
  ns <- NS(id)
  fluidPage(
    titlePanel("Open Street Map"),
    sidebarLayout(
      sidebarPanel(
        h4("Background map"),
        radioButtons(ns("map_source"), label = "Map source",
                     choices = list("No API key needed" = "free", "API key needed" = "key"),
                     selected = "free", inline = TRUE),
        conditionalPanel(
          condition = "input.map_source == 'free'", ns = ns,
          selectInput(ns("maptype"), label = "Background map type",
                      choices = map_choices_free, selected = "osm:streets")
        ),
        conditionalPanel(
          condition = "input.map_source == 'key'", ns = ns,
          selectInput(ns("maptype_key"), label = "Background map type",
                      choices = map_choices_key, selected = "osm_stadia:outdoors"),
          passwordInput(ns("api_key"), label = "API key for the selected map provider",
                        value = Sys.getenv("MAP_API_KEY")),
          uiOutput(ns("key_help"))
        ),
        radioButtons(ns("zoomin"),
                     label = tagList(
                       "Resolution of background map",
                       helpText("Try out map types at a low resolution, it is faster.",
                                style = "font-weight: normal; margin: 2px 0 0;")
                     ),
                     choices = list("very low" = -2, "low" = -1, "high" = 0, "very high" = 1),
                     selected = -2),
        helpText("A very high resolution for data covering a large area downloads many tiles and can be slow."),
        sliderInput(ns("map_zoom"), label = "Zoom", min = -3, max = 3, value = 0, step = 1),
        helpText("0 shows all tracks. Positive values zoom in on the centre of the tracks, negative values show more of the surroundings."),
        hr(),
        h4("Tracks"),
        selectInput(ns("track_pal"), label = "Colour palette",
                    choices = c("Glasbey", "Set1", "Set2", "Set3", "Dark2", "Paired", "Accent"),
                    selected = "Glasbey"),
        helpText("With more tracks than the palette has colours, evenly spread colours are used instead."),
        checkboxInput(ns("legend"), label = "Show legend with track names", value = FALSE),
        hr(),
        h4("X-axis labels"),
        radioButtons(ns("xlab_angle"), label = "Label direction",
                     choices = list("horizontal" = 0, "45\u00b0" = 45, "vertical" = 90),
                     selected = 0, inline = TRUE),
        selectInput(ns("xlab_n"), label = "Number of labels",
                    choices = c("automatic" = "auto", 2:8), selected = "auto"),
        hr(),
        actionButton(ns("apply"), "Apply Changes", class = "btn-primary btn-block"),
        hr(),
        h4("Download"),
        downloadButton(ns("save_png"), "Save Map as PNG", class = "btn-sm"),
        downloadButton(ns("save_pdf"), "Save Map as PDF", class = "btn-sm"),
        width = 3),
      mainPanel(
        div(style = "color: #c0392b;", textOutput(ns("map_msg"))),
        shinycssloaders::withSpinner(plotOutput(ns("map"), height = "85vh")),
        width = 9)
    )
  )
}

## ---- server --------------------------------------------------------------

shinyModule <- function(input, output, session, data) {
  current <- reactiveVal(data)
  enable_carto_key()
  
  # plotting copies in Web Mercator; the data passed on is not changed
  pts <- data[!sf::st_is_empty(data), ]
  pts <- sf::st_transform(pts, 3857)
  pts$track_ <- as.character(mt_track_id(pts))
  ids <- unique(pts$track_)
  
  # tracks with a single location cannot be drawn as lines
  multi <- names(which(table(pts$track_) > 1))
  lns <- NULL
  if (length(multi) > 0) {
    lns <- mt_track_lines(pts[pts$track_ %in% multi, ])
    lns$track_ <- as.character(lns[[mt_track_id_column(pts)]])
  }
  
  # extent of all data with a small margin; the zoom slider starts from it
  bb_data <- sf::st_bbox(pts)
  pad <- max(bb_data["xmax"] - bb_data["xmin"], bb_data["ymax"] - bb_data["ymin"], 1000) * 0.05
  bb_data[c("xmin", "ymin")] <- bb_data[c("xmin", "ymin")] - pad
  bb_data[c("xmax", "ymax")] <- bb_data[c("xmax", "ymax")] + pad
  
  map_dir <- file.path(tempdir(), "basemaps")
  dir.create(map_dir, showWarnings = FALSE)
  
  settings_now <- reactive({
    list(maptype = if (identical(input$map_source, "key")) input$maptype_key else input$maptype,
         api_key = input$api_key,
         zoomin = as.numeric(input$zoomin), map_zoom = as.numeric(input$map_zoom),
         legend = input$legend, track_pal = input$track_pal,
         xlab_angle = as.numeric(input$xlab_angle), xlab_n = input$xlab_n)
  })
  
  # the map is drawn once with the settings the App opens with (stored settings
  # are restored by then), afterwards only when Apply Changes is clicked.
  # bg_settings only changes when the map type, key, resolution or zoom change,
  # so other settings do not download the tiles again
  settings <- reactiveVal(NULL)
  bg_settings <- reactiveVal(NULL)
  apply_settings <- function() {
    s <- settings_now()
    settings(s)
    bg_settings(s[c("maptype", "api_key", "zoomin", "map_zoom")])
  }
  
  # help text follows the dropdown directly, it does not wait for Apply
  output$key_help <- renderUI({
    req(input$maptype_key)
    site <- key_sites[[sub(":.*", "", input$maptype_key)]]
    helpText("Get a free key at ", tags$a(href = site, target = "_blank", site),
             ". The key is not stored with the settings.")
  })
  observeEvent(req(input$maptype, input$xlab_n), apply_settings(), once = TRUE)
  observeEvent(input$apply, apply_settings(), ignoreInit = TRUE)
  
  # background layer
  background <- reactive({
    s <- bg_settings()
    req(s$maptype)
    service <- sub(":.*", "", s$maptype)
    type <- sub(".*:", "", s$maptype)
    bb <- zoom_bb(bb_data, if (is.null(s$map_zoom)) 0 else s$map_zoom)
    ext <- sf::st_as_sfc(bb)
    if (service %in% key_services && (is.null(s$api_key) || !nzchar(s$api_key))) {
      return(list(layer = NULL, service = service, bb = bb,
                  msg = "This map type needs an API key. Enter it in the sidebar; the tracks are shown without a background map."))
    }
    if (service == "carto" && !carto_key_ok(type, s$api_key)) {
      logger.info("CARTO did not accept the API key.")
      return(list(layer = NULL, service = service, bb = bb,
                  msg = "CARTO did not accept this API key. Check the key; the tracks are shown without a background map."))
    }
    z <- tile_zoom(bb, s$zoomin)
    msg <- NULL
    while (z > 1 && n_tiles(bb, z) > max_tiles) z <- z - 1
    if (z < tile_zoom(bb, s$zoomin)) {
      msg <- "The resolution was reduced, because the data covers a large area."
      logger.info("Resolution reduced to zoom %s to stay below %s tiles.", z, max_tiles)
    }
    layer <- tryCatch(
      basemaps::basemap_gglayer(ext = ext, map_service = service, map_type = type,
                                map_token = if (service %in% key_services) s$api_key else NA,
                                map_dir = map_dir, custom_zoom = z, verbose = FALSE,
                                # do not reuse tiles cached with an earlier, wrong key
                                force = service %in% key_services),
      error = function(e) {
        logger.warn("Background map could not be loaded: %s", conditionMessage(e))
        structure(conditionMessage(e), class = "map_error")
      })
    if (inherits(layer, "map_error")) {
      return(list(layer = NULL, service = service, bb = bb,
                  msg = paste("The background map could not be loaded, the tracks are shown without it.",
                              "Check the API key or try another map type. Details:", layer)))
    }
    list(layer = layer, service = service, bb = bb, msg = msg)
  })
  
  map_plot <- reactive({
    s <- settings()
    req(s)
    bg <- background()
    bb <- bg$bb
    nx <- if (s$xlab_n == "auto") {
      ratio <- (bb["xmax"] - bb["xmin"]) / (bb["ymax"] - bb["ymin"])
      if (ratio < 0.6) 2 else if (ratio < 1.2) 3 else 5
    } else as.numeric(s$xlab_n)
    # same palette always gives the same colour per track, also with legend off
    pal_name <- if (is.null(s$track_pal)) "Glasbey" else s$track_pal
    cols <- stats::setNames(track_colors(pal_name, length(ids)), ids)
    
    mp <- ggplot() +
      bg$layer +
      scale_fill_identity() +
      (if (!is.null(lns)) geom_sf(data = lns, aes(color = track_))) +
      geom_sf(data = pts, aes(color = track_), size = 1) +
      ggspatial::annotation_scale(location = "br") +
      scale_color_manual("Tracks", values = cols) +
      scale_x_continuous(breaks = scales::breaks_pretty(n = nx)) +
      coord_sf(crs = 3857, datum = 4326, expand = FALSE,
               xlim = unname(bb[c("xmin", "xmax")]), ylim = unname(bb[c("ymin", "ymax")])) +
      labs(x = NULL, y = NULL, caption = map_credits[[bg$service]]) +
      theme_linedraw() +
      theme(axis.text.x = element_text(angle = s$xlab_angle,
                                       hjust = if (s$xlab_angle == 0) 0.5 else 1,
                                       vjust = if (s$xlab_angle == 90) 0.5 else 1))
    if (!s$legend) mp <- mp + guides(color = "none")
    mp
  })
  
  output$map_msg <- renderText(background()$msg)
  
  output$map <- renderPlot(map_plot())
  
  #### map as PNG
  output$save_png <- downloadHandler(
    filename = function() paste0("OpenStreetMap_", Sys.Date(), ".png"),
    content = function(file) {
      shinybusy::show_modal_spinner(spin = "fading-circle", text = "Saving PNG ...")
      on.exit(shinybusy::remove_modal_spinner(), add = TRUE)
      ggsave(file, plot = map_plot(), device = "png", width = 10, height = 8, dpi = 300)
    }
  )
  
  #### map as PDF
  output$save_pdf <- downloadHandler(
    filename = function() paste0("OpenStreetMap_", Sys.Date(), ".pdf"),
    content = function(file) {
      shinybusy::show_modal_spinner(spin = "fading-circle", text = "Saving PDF ...")
      on.exit(shinybusy::remove_modal_spinner(), add = TRUE)
      ggsave(file, plot = map_plot(), device = "pdf", width = 10, height = 8)
    }
  )
  
  return(reactive({ current() }))
}