# ============================================================
# Baleen bubble plot: whale presence + MFA overlap
# Works for HAT and NFC
# ============================================================

library(dplyr)
library(tidyr)
library(ggplot2)
library(lubridate)
library(scales)
library(ggnewscale)
library(cowplot)
library(grid)

# ------------------------------------------------------------
# USER SETTINGS
# ------------------------------------------------------------
site <- "HAT"   # "HAT" or "NFC"

species_colors <- c(
  "Humpback" = "#CC79A7",
  "Minke"    = "#FA5F55",
  "NARW"     = "#E69F00",
  "Sei"      = "#800000",
  "Fin"      = "#009E73",
  "Blue"     = "#08519C"
)

species_order <- c("Humpback", "Minke", "NARW", "Sei", "Fin", "Blue")

# ------------------------------------------------------------
# DIRECTORIES / FILE PATHS
# ------------------------------------------------------------
if (site == "HAT") {
  out_dir   <- "Z:/Atlantic_Baleen_Sonar/HAT/Plots"
  whale_file <- "L:/.shortcut-targets-by-id/1e--9nfwJzzjRqjIBLTB1DaMydkPBrHlf/HAT/HAT/Baleen and minke outputs/HAT R code/data/BALEEN_DAILYPRESENCE_ALLSPECIES_NAVFAC_FINAL_080125.csv"
  mfa_file   <- "Z:/MBARC_Reports/Atlantic Synthesis Reports/Anthropogenic/Final Tables/HAT/HAT_anthro_mfa.csv"
  output_file <- file.path(out_dir, "ALL_SPECIES_BUBBLE_MFA.png")
} else if (site == "NFC") {
  out_dir   <- "Z:/Atlantic_Baleen_Sonar/NFC/Plots"
  whale_file <- "L:/.shortcut-targets-by-id/1NHK8ZRtCbvo4cicsapyJzWLfPTWFfpQ0/NAVFAC_REPORT_FIGURES/NFC/data/BALEEN_DAILYPRESENCE_ALLSPECIES_NAVFAC_NFC_090925.csv"
  mfa_file   <- "Z:/MBARC_Reports/Atlantic Synthesis Reports/Anthropogenic/Final Tables/NFC/NFC_anthro_mfa.csv"
  output_file <- file.path(out_dir, "ALL_SPECIES_BUBBLE_MFA.png")
} else {
  stop("site must be 'HAT' or 'NFC'")
}

setwd(out_dir)

# ------------------------------------------------------------
# LOAD DATA
# ------------------------------------------------------------
whale <- read.csv(whale_file) %>%
  mutate(date = ymd(date))
whale <- whale %>%
  select(-ends_with("poss_occur"))

mfa_raw <- read.csv(mfa_file) %>%
  mutate(
    start = ymd_hms(Start_UTC),
    end   = ymd_hms(End_UTC)
  )

# Expand MFA date ranges to daily presence
mfa_daily <- mfa_raw %>%
  rowwise() %>%
  mutate(date = list(seq.Date(as.Date(start), as.Date(end), by = "day"))) %>%
  unnest(date) %>%
  ungroup() %>%
  distinct(date) %>%
  mutate(MFA = 1)

# ------------------------------------------------------------
# LONG FORMAT
# ------------------------------------------------------------
allsp_long <- whale %>%
  pivot_longer(
    cols = ends_with("_occur"),
    names_to = "species_full",
    values_to = "presence"
  ) %>%
  mutate(
    species_abbr = sub("_occur", "", species_full),
    species = recode(
      species_abbr,
      "NARW" = "NARW",
      "SEWH" = "Sei",
      "HUWH" = "Humpback",
      "MIWH" = "Minke",
      "FIWH" = "Fin",
      "BLWH" = "Blue"
    ),
    month = month(date),
    year  = year(date)
  )

# ------------------------------------------------------------
# JOIN MFA
# ------------------------------------------------------------
combined <- allsp_long %>%
  left_join(mfa_daily, by = "date") %>%
  mutate(
    MFA = ifelse(is.na(MFA), 0, MFA),
    overlap = presence * MFA
  )

# Create a unified grouping variable for plotting
# HAT uses REGION; NFC is one combined site
combined <- combined %>%
  mutate(
    plot_group = case_when(
      site == "HAT" ~ as.character(REGION),
      site == "NFC" ~ site,
      TRUE ~ NA_character_
    )
  )

# ------------------------------------------------------------
# SUMMARY
# ------------------------------------------------------------
bubble_data <- combined %>%
  group_by(species, plot_group, year, month) %>%
  summarise(
    whale_days   = sum(presence, na.rm = TRUE),
    overlap_days = sum(overlap, na.rm = TRUE),
    mfa_days     = sum(MFA, na.rm = TRUE),
    total_days   = n(),
    .groups = "drop"
  ) %>%
  mutate(
    pct_whale = whale_days / total_days,
    pct_mfa   = mfa_days / total_days
  )

effort_only <- combined %>%
  group_by(species, plot_group, year, month) %>%
  summarise(
    whale_days = sum(presence, na.rm = TRUE),
    mfa_days   = sum(MFA, na.rm = TRUE),
    total_days = n(),
    .groups = "drop"
  ) %>%
  filter(whale_days == 0 & mfa_days == 0 & total_days > 0)

# ------------------------------------------------------------
# FORMATTING
# ------------------------------------------------------------
bubble_data <- bubble_data %>%
  mutate(
    month_abbr = factor(month.abb[month], levels = month.abb),
    year = factor(year, levels = rev(sort(unique(year)))),
    species = factor(species, levels = species_order),
    plot_group = factor(plot_group)
  )

effort_only <- effort_only %>%
  mutate(
    month_abbr = factor(month.abb[month], levels = month.abb),
    year = factor(year, levels = levels(bubble_data$year)),
    species = factor(species, levels = species_order),
    plot_group = factor(plot_group, levels = levels(bubble_data$plot_group))
  )

if (site == "HAT") {
  bubble_data <- bubble_data %>%
    mutate(plot_group = factor(plot_group, levels = c("HAT A", "HAT B")))
  
  effort_only <- effort_only %>%
    mutate(plot_group = factor(plot_group, levels = c("HAT A", "HAT B")))
}

# ------------------------------------------------------------
# BUILD BUBBLE PLOT
# ------------------------------------------------------------
bubble_plot <- ggplot()

for (sp in species_order) {
  sp_data <- bubble_data %>% filter(species == sp)
  
  bubble_plot <- bubble_plot +
    ggnewscale::new_scale_fill() +
    geom_point(
      data = sp_data,
      aes(
        x = month_abbr,
        y = year,
        size = pct_mfa,
        fill = pct_whale
      ),
      shape = 21,
      color = "black",
      stroke = 0.3
    ) +
    geom_text(
      data = sp_data,
      aes(
        x = month_abbr,
        y = year,
        label = ifelse(overlap_days > 0, overlap_days, "")
      ),
      size = 2.5,
      fontface = "bold"
    ) +
    scale_fill_gradient(
      low = "#F7F7F7",
      high = species_colors[sp],
      limits = c(0, 1),
      labels = percent,
      name = paste(sp, "% Whale Days"),
      guide = guide_colorbar(order = which(species_order == sp))
    )
}

# effort-only markers
bubble_plot <- bubble_plot +
  geom_text(
    data = effort_only,
    aes(x = month_abbr, y = year),
    label = "x",
    size = 2,
    color = "gray40"
  )

# ------------------------------------------------------------
# HAT TRANSITION LINE ONLY
# ------------------------------------------------------------
if (site == "HAT") {
  transition_lines_df <- data.frame(
    x = c(1, 2, 2),
    xend = c(2, 2, 12),
    y = c(3.5, 3.5, 4.5),
    yend = c(3.5, 4.5, 4.5)
  )
  
  bubble_plot <- bubble_plot +
    geom_segment(
      data = transition_lines_df,
      aes(
        x = factor(x, levels = 1:12, labels = month.abb),
        xend = factor(xend, levels = 1:12, labels = month.abb),
        y = y,
        yend = yend
      ),
      inherit.aes = FALSE,
      color = "black",
      linewidth = 0.5
    )
}

# ------------------------------------------------------------
# MAIN PLOT
# ------------------------------------------------------------
if (site == "HAT") {
  main_plot <- bubble_plot +
    facet_grid(species ~ plot_group, scales = "free_y", space = "free_y")
} else {
  main_plot <- bubble_plot +
    facet_grid(species ~ ., scales = "free_y", space = "free_y")
}

main_plot <- main_plot +
  scale_x_discrete(limits = month.abb, drop = FALSE) +
  scale_size_continuous(
    range = c(1.5, 10),
    limits = c(0, 1),
    labels = percent,
    name = "% Days with MFA"
  ) +
  labs(x = NULL, y = NULL, title = NULL) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.title = element_blank(),
    strip.text = element_blank(),
    legend.position = "none",
    panel.spacing.y = unit(2, "lines")
  )

# ------------------------------------------------------------
# WHALE LEGENDS
# ------------------------------------------------------------
legend_df <- expand.grid(
  species = factor(species_order, levels = species_order),
  x = 1,
  y = 1
)

whale_legend_plot <- ggplot()

for (sp in species_order) {
  whale_legend_plot <- whale_legend_plot +
    ggnewscale::new_scale_fill() +
    geom_point(
      data = legend_df[legend_df$species == sp, ],
      aes(x = x, y = y, fill = 0.5),
      shape = 21,
      size = 4,
      color = "black"
    ) +
    scale_fill_gradient(
      low = "#F7F7F7",
      high = species_colors[sp],
      limits = c(0, 1),
      labels = percent,
      name = paste(sp, "% Whale Days"),
      guide = guide_colorbar(order = which(species_order == sp))
    )
}

whale_legend_plot <- whale_legend_plot +
  theme_void() +
  theme(
    legend.position = "right",
    legend.box = "vertical",
    legend.key.height = unit(0.28, "in"),
    legend.key.width  = unit(0.18, "in"),
    legend.text  = element_text(size = 8),
    legend.title = element_text(size = 9)
  )

whale_legend <- cowplot::get_legend(whale_legend_plot)

# ------------------------------------------------------------
# MFA LEGEND
# ------------------------------------------------------------
mfa_legend_df <- data.frame(
  x = 1,
  y = 1,
  pct_mfa = c(0, 0.25, 0.5, 0.75, 1)
)

mfa_legend_plot <- ggplot(mfa_legend_df, aes(x = x, y = y, size = pct_mfa)) +
  geom_point(shape = 21, fill = "white", color = "black") +
  scale_size_continuous(
    range = c(1.5, 10),
    limits = c(0, 1),
    labels = percent,
    name = "% Days with MFA"
  ) +
  theme_void() +
  theme(
    legend.position = "right",
    legend.text  = element_text(size = 8),
    legend.title = element_text(size = 9)
  )

mfa_legend <- cowplot::get_legend(mfa_legend_plot)

# ------------------------------------------------------------
# COMBINE LEGENDS
# ------------------------------------------------------------
legend_column <- cowplot::plot_grid(
  whale_legend,
  mfa_legend,
  ncol = 2,
  rel_widths = c(1, 0.7),
  align = "h"
)

legend_column <- cowplot::ggdraw(legend_column) +
  theme(plot.margin = margin(25, 20, 25, 20))

# ------------------------------------------------------------
# FINAL FIGURE
# ------------------------------------------------------------
final_plot <- cowplot::plot_grid(
  main_plot,
  legend_column,
  ncol = 2,
  rel_widths = c(1, 0.42)
)

# ------------------------------------------------------------
# SAVE
# ------------------------------------------------------------
ggsave(
  output_file,
  plot = final_plot,
  width = 12,
  height = 9.5,
  units = "in",
  dpi = 300,
  bg = "white"
)

ggsave(
  filename = file.path(out_dir, paste0(site, "_bubble_plot.pdf")),
  plot = main_plot,
  width = 10,
  height = 9,
  units = "in"
)

whale_legend_plot_only <- cowplot::ggdraw(whale_legend)

ggsave(
  filename = file.path(out_dir, paste0(site, "_whale_legends.pdf")),
  plot = whale_legend_plot_only,
  width = 6,
  height = 11,   # 👈 THIS is the key fix
  units = "in"
)

mfa_legend_plot_only <- cowplot::ggdraw(mfa_legend)

ggsave(
  filename = file.path(out_dir, paste0(site, "_mfa_legend.pdf")),
  plot = mfa_legend_plot_only,
  width = 3,
  height = 3,
  units = "in"
)

ggsave(
  filename = file.path(out_dir, paste0(site, "_combined_legends.pdf")),
  plot = legend_column,
  width = 6,
  height = 11,
  units = "in"
)

# ------------------------------------------------------------
# CREATE PLOT GROUP (HAT vs NFC)
# ------------------------------------------------------------
combined <- combined %>%
  mutate(
    plot_group = case_when(
      site == "HAT" ~ as.character(REGION),
      site == "NFC" ~ site,
      TRUE ~ NA_character_
    )
  )

# ------------------------------------------------------------
# MONTHLY OVERLAP SUMMARY
# ------------------------------------------------------------
overlap_summary <- combined %>%
  group_by(species, plot_group, year, month) %>%
  summarise(
    overlap_days = sum(overlap, na.rm = TRUE),
    total_days   = n(),
    pct_overlap  = overlap_days / total_days,
    .groups = "drop"
  )

# ------------------------------------------------------------
# ===================== 1. HEATMAP ============================
# ------------------------------------------------------------

heatmap_plot <- ggplot(overlap_summary,
                       aes(x = month, y = factor(year), fill = pct_overlap)) +
  geom_tile(color = "white", linewidth = 0.2) +
  scale_fill_viridis_c(labels = percent, name = "% Overlap") +
  scale_x_continuous(breaks = 1:12, labels = month.abb) +
  
  facet_grid(species ~ plot_group) +
  
  labs(x = "Month", y = "Year") +
  
  theme_minimal(base_size = 11) +
  theme(
    panel.grid = element_blank(),
    strip.text = element_text(face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

# SAVE HEATMAP
ggsave(
  filename = file.path(out_dir, paste0(site, "_overlap_heatmap.png")),
  plot = heatmap_plot,
  width = ifelse(site == "HAT", 12, 8),
  height = 10,
  units = "in"
)

# ------------------------------------------------------------
# ===================== 2. STACKED BAR ========================
# ------------------------------------------------------------

# monthly total overlap by species
stacked_data <- overlap_summary %>%
  group_by(species, plot_group, month) %>%
  summarise(
    total_overlap = sum(overlap_days, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    species = factor(species, levels = species_order)  # 👈 ensures order + colors match
  )

stacked_plot <- ggplot(stacked_data,
                       aes(x = month, y = total_overlap, fill = species)) +
  geom_col() +
  
  # 👇 THIS is the key line
  scale_fill_manual(
    values = species_colors,
    drop = FALSE   # 👈 keeps legend consistent even if species missing in a panel
  ) +
  
  scale_x_continuous(breaks = 1:12, labels = month.abb) +
  
  facet_wrap(~ plot_group, ncol = ifelse(site == "HAT", 2, 1)) +
  
  labs(
    x = "Month",
    y = "Total Overlap Days",
    fill = "Species"
  ) +
  
  theme_minimal(base_size = 11) +
  theme(
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

# SAVE STACKED BAR
ggsave(
  filename = file.path(out_dir, paste0(site, "_overlap_stacked_bar.png")),
  plot = stacked_plot,
  width = ifelse(site == "HAT", 12, 8),
  height = 6,
  units = "in"
)
