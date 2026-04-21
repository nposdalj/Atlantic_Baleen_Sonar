# ============================================================
# NAVFAC Bubble Plot: Whale Presence + MFA Overlap
# ============================================================

# --- 0. Load Libraries ---
library(dplyr)
library(tidyr)
library(ggplot2)
library(lubridate)
library(scales)
library(ggnewscale)
library(cowplot)

species_colors <- c(
  "Humpback" = "#CC79A7",
  "Minke" = "#FA5F55",
  "NARW" = "#E69F00",
  "Sei" = "#800000",
  "Fin" = "#009E73",
  "Blue" = "#08519C"
)

species_order <- c("Humpback", "Minke", "NARW", "Sei", "Fin", "Blue")

# --- 1. Load Data ---

setwd("Z:/Atlantic_Baleen_Sonar/HAT/Plots")

# Whale daily presence (your final compiled dataset)
whale <- read.csv("L:/.shortcut-targets-by-id/1e--9nfwJzzjRqjIBLTB1DaMydkPBrHlf/HAT/HAT/Baleen and minke outputs/HAT R code/data/BALEEN_DAILYPRESENCE_ALLSPECIES_NAVFAC_FINAL_080125.csv") %>%
  mutate(date = ymd(date))

# MFA presence
mfa_raw <- read.csv("Z:/MBARC_Reports/Atlantic Synthesis Reports/Anthropogenic/Final Tables/HAT/HAT_anthro_mfa.csv") %>%
  mutate(
    start = ymd_hms(Start_UTC),
    end   = ymd_hms(End_UTC)
  )

# --- Expand to daily presence ---
mfa_daily <- mfa_raw %>%
  rowwise() %>%
  mutate(date = list(seq.Date(as.Date(start), as.Date(end), by = "day"))) %>%
  unnest(date) %>%
  ungroup() %>%
  distinct(date) %>%   # important: avoid duplicates if events overlap
  mutate(MFA = 1)

# --- 2. Convert Whale Data to Long Format (same as your script) ---

allsp_long <- whale %>% 
  pivot_longer(
    cols = ends_with("_occur"),
    names_to = "species_full",
    values_to = "presence"
  ) %>%
  mutate(
    species_abbr = sub("_occur", "", species_full),
    species = recode(species_abbr,
                     "NARW" = "NARW",
                     "SEWH" = "Sei",
                     "HUWH" = "Humpback",
                     "MIWH" = "Minke",
                     "FIWH" = "Fin",
                     "BLWH" = "Blue"),
    month = month(date),
    year = year(date)
  )

# --- 3. Join MFA + Create Overlap Variable ---

combined <- allsp_long %>%
  left_join(mfa_daily, by = "date") %>%
  mutate(
    MFA = ifelse(is.na(MFA), 0, MFA),
    overlap = presence * MFA
  )

# --- 4. Monthly Summary Metrics ---

bubble_data <- combined %>%
  group_by(species, REGION, year, month) %>%   # 👈 MUST include REGION
  summarise(
    whale_days = sum(presence, na.rm = TRUE),
    overlap_days = sum(overlap, na.rm = TRUE),
    mfa_days = sum(MFA, na.rm = TRUE),
    total_days = n(),
    .groups = "drop"
  ) %>%
  mutate(
    pct_whale = whale_days / total_days,
    pct_mfa = mfa_days / total_days
  )

effort_only <- combined %>%
  group_by(species, year, month) %>%
  summarise(
    whale_days = sum(presence, na.rm = TRUE),
    mfa_days = sum(MFA, na.rm = TRUE),
    total_days = n(),
    .groups = "drop"
  ) %>%
  filter(whale_days == 0 & mfa_days == 0 & total_days > 0) %>%
  mutate(
    month_abbr = factor(month.abb[month], levels = month.abb),
    year = factor(year, levels = levels(bubble_data$year)),
    species = factor(species, levels = species_order)
  )

# ============================================================
# --- 5. Formatting for Plot ---
# ============================================================

species_order <- c("Humpback", "Minke", "NARW", "Sei", "Fin", "Blue")

# IMPORTANT: DO NOT filter out months → required for step line alignment
bubble_data <- bubble_data %>%
  mutate(
    month_abbr = factor(month.abb[month], levels = month.abb),
    month_num  = month,   # 👈 needed for transition line
    year = factor(year, levels = rev(sort(unique(year)))),
    year_num = as.numeric(year),  # 👈 numeric y for line
    species = factor(species, levels = species_order),
    REGION = factor(REGION, levels = c("HAT A", "HAT B"))
  )

# Effort-only (must match structure exactly)
effort_only <- combined %>%
  group_by(species, REGION, year, month) %>%
  summarise(
    whale_days = sum(presence, na.rm = TRUE),
    mfa_days = sum(MFA, na.rm = TRUE),
    total_days = n(),
    .groups = "drop"
  ) %>%
  filter(whale_days == 0 & mfa_days == 0 & total_days > 0) %>%
  mutate(
    month_abbr = factor(month.abb[month], levels = month.abb),
    month_num  = month,
    year = factor(year, levels = levels(bubble_data$year)),
    year_num = as.numeric(year),
    species = factor(species, levels = species_order),
    REGION = factor(REGION, levels = c("HAT A", "HAT B"))
  )

# ============================================================
# --- 6. Plot ---
# ============================================================
bubble_plot <- ggplot()

for (sp in species_order) {
  
  sp_data <- bubble_data %>% filter(species == sp)
  
  bubble_plot <- bubble_plot +
    ggnewscale::new_scale_fill() +
    
    # bubbles
    geom_point(
      data = sp_data,
      aes(x = month_abbr, y = year,
          size = pct_mfa,
          fill = pct_whale),
      shape = 21,
      color = "black",
      stroke = 0.3
    ) +
    
    # 🔥 THIS is where your overlap numbers are drawn
    geom_text(
      data = sp_data,
      aes(x = month_abbr, y = year,
          label = ifelse(overlap_days > 0, overlap_days, "")),
      size = 2.5,
      fontface = "bold"   # 👈 your final requested change
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

# --- add X for effort-only months
bubble_plot <- bubble_plot +
  geom_text(
    data = effort_only,
    aes(x = month_abbr, y = year),
    label = "x",
    size = 2,
    color = "gray40"
  )
# ============================================================
# --- ORIGINAL NAVFAC STEP LINE (NOW WORKS)
# ============================================================

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

# ============================================================
# --- MAIN PLOT (NO LEGENDS)
# ============================================================

main_plot <- bubble_plot +
  facet_grid(species ~ REGION, scales = "free_y", space = "free_y") +
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
    
    strip.text.y = element_blank(),
    strip.text.x = element_blank(),
    
    legend.position = "none",
    
    # 👇 THIS is what you want
    panel.spacing.y = unit(2, "lines")   # try 1–2 range
  )
# ============================================================
# --- WHALE LEGENDS (STACKED COLUMN)
# ============================================================

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

# ============================================================
# --- MFA LEGEND (BUBBLE SIZE)
# ============================================================

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

# ============================================================
# --- COMBINE LEGENDS (2 COLUMNS)
# ============================================================

legend_column <- cowplot::plot_grid(
  whale_legend,
  mfa_legend,
  ncol = 2,
  rel_widths = c(1, 0.7),
  align = "h"
)

legend_column <- cowplot::ggdraw(legend_column) +
  theme(plot.margin = margin(25, 20, 25, 20))

# ============================================================
# --- FINAL COMBINED FIGURE
# ============================================================

final_plot <- cowplot::plot_grid(
  main_plot,
  legend_column,
  ncol = 2,
  rel_widths = c(1, 0.42)
)

# ============================================================
# --- SAVE
# ============================================================

ggsave(
  "ALL_SPECIES_BUBBLE_MFA.png",
  plot = final_plot,
  width = 12,
  height = 9.5,
  units = "in",
  dpi = 300,
  bg = "white"
)