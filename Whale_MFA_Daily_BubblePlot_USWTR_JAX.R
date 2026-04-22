# ============================================================
# Baleen whale + MFA overlap plots (ALL SITES)
# ============================================================

library(dplyr)
library(tidyr)
library(ggplot2)
library(lubridate)
library(scales)
library(ggnewscale)
library(cowplot)
library(grid)

species_colors <- c(
  "Humpback" = "#CC79A7",
  "Minke"    = "#FA5F55",
  "NARW"     = "#E69F00",
  "Sei"      = "#800000",
  "Fin"      = "#009E73",
  "Blue"     = "#08519C"
)

# ------------------------------------------------------------
# USER SETTINGS
# ------------------------------------------------------------
site <- "JAX"   # "USWTR"

species_order <- c("Humpback", "Minke", "NARW", "Sei", "Fin", "Blue")

# ------------------------------------------------------------
# PATHS
# ------------------------------------------------------------
if (site == "JAX") {
  
  whale_file <- "L:/.shortcut-targets-by-id/1NHK8ZRtCbvo4cicsapyJzWLfPTWFfpQ0/NAVFAC_REPORT_FIGURES/JAX/data/BALEEN_DAILYPRESENCE_ALLSPECIES_NAVFAC_JAX_090925.csv"
  mfa_dir <- "Z:/MBARC_Reports/Atlantic Synthesis Reports/Anthropogenic/Final Tables/JAX"
  out_dir   <- "Z:/Atlantic_Baleen_Sonar/JAX/Plots"
  mfa_files <- list(
    "JAX A" = file.path(mfa_dir, "JAX_A_MFA_hr_bins.csv"),
    "JAX B" = file.path(mfa_dir, "JAX_B_MFA_hr_bins.csv"),
    "JAX C" = file.path(mfa_dir, "JAX_C_MFA_hr_bins.csv"),
    "JAX D" = file.path(mfa_dir, "JAX_D_MFA_hr_bins.csv")
  )
  
} else if (site == "USWTR") {
  
  whale_file <- "L:/.shortcut-targets-by-id/1NHK8ZRtCbvo4cicsapyJzWLfPTWFfpQ0/NAVFAC_REPORT_FIGURES/USWTR/data/BALEEN_DAILYPRESENCE_ALLSPECIES_NAVFAC_USWTR_090925.csv"
  mfa_dir <- "Z:/MBARC_Reports/Atlantic Synthesis Reports/Anthropogenic/Final Tables/USWTR"
  out_dir   <- "Z:/Atlantic_Baleen_Sonar/USWTR/Plots"
  mfa_files <- list(
    "USWTR A" = file.path(mfa_dir, "USWTR_A_MFA_hr_bins.csv"),
    "USWTR B" = file.path(mfa_dir, "USWTR_B_MFA_hr_bins.csv"),
    "USWTR C" = file.path(mfa_dir, "USWTR_C_MFA_hr_bins.csv"),
    "USWTR D" = file.path(mfa_dir, "USWTR_D_MFA_hr_bins.csv"),
    "USWTR E" = file.path(mfa_dir, "USWTR_E_MFA_hr_bins.csv")
  )
}

setwd(out_dir)


# ------------------------------------------------------------
# LOAD WHALE
# ------------------------------------------------------------
whale <- read.csv(whale_file) %>%
  mutate(date = ymd(date)) %>%
  select(-ends_with("poss_occur"))

# ------------------------------------------------------------
# MFA PROCESSING (FIXED)
# ------------------------------------------------------------
process_mfa_hr <- function(file, group_name){
  
  read.csv(file) %>%
    mutate(
      datetime = mdy_hms(paste(start_date, start_time)),
      date = as.Date(datetime),
      MFA_flag = ifelse(Manual_Review > 0, 1, 0)
    ) %>%
    group_by(date) %>%
    summarise(MFA = max(MFA_flag), .groups="drop") %>%
    mutate(raw_group = group_name)
}

mfa_daily <- bind_rows(
  lapply(names(mfa_files), function(pg){
    process_mfa_hr(mfa_files[[pg]], pg)
  })
)

# ------------------------------------------------------------
# LONG FORMAT
# ------------------------------------------------------------
combined <- whale %>%
  pivot_longer(
    cols = ends_with("_occur"),
    names_to = "species_full",
    values_to = "presence"
  ) %>%
  mutate(
    species_abbr = sub("_occur","",species_full),
    species = recode(species_abbr,
                     "NARW"="NARW","SEWH"="Sei","HUWH"="Humpback",
                     "MIWH"="Minke","FIWH"="Fin","BLWH"="Blue"),
    month = month(date),
    year  = year(date)
  )

# ------------------------------------------------------------
# JOIN MFA
# ------------------------------------------------------------
combined <- combined %>%
  left_join(mfa_daily, by="date") %>%
  mutate(
    MFA = ifelse(is.na(MFA),0,MFA),
    overlap = presence*MFA
  )

# ------------------------------------------------------------
# GROUPING
# ------------------------------------------------------------
combined <- combined %>%
  mutate(
    plot_group = case_when(
      
      # JAX
      site == "JAX" & grepl("A$", SITE) ~ "JAX A",
      site == "JAX" & grepl("[B-D]$", SITE) ~ "JAX B-D",
      
      # USWTR
      site == "USWTR" & grepl("A$", SITE) ~ "USWTR A",
      site == "USWTR" & grepl("[B-E]$", SITE) ~ "USWTR B-E",
      
      TRUE ~ NA_character_
    )
  )

# ------------------------------------------------------------
# SUMMARY
# ------------------------------------------------------------
bubble_data <- combined %>%
  group_by(species, plot_group, year, month) %>%
  summarise(
    whale_days=sum(presence),
    overlap_days=sum(overlap),
    mfa_days=sum(MFA),
    total_days=n(),
    .groups="drop"
  ) %>%
  mutate(
    pct_whale = whale_days/total_days,
    pct_mfa   = mfa_days/total_days,
    year = factor(year, levels=sort(unique(year), decreasing=TRUE))
  )

bubble_data <- bubble_data %>%
  mutate(
    species = factor(species, levels = species_order)
  )

# ------------------------------------------------------------
# BUBBLE FUNCTION (FIXED YEAR ORDER + NA HANDLING)
# ------------------------------------------------------------
make_bubble_plot <- function(df){
  
  p <- ggplot()
  
  for(sp in species_order){
    
    sp_data <- df %>% 
      filter(species==sp, !is.na(pct_whale))
    
    p <- p +
      ggnewscale::new_scale_fill() +
      geom_point(
        data=sp_data,
        aes(x=month,y=year,size=pct_mfa,fill=pct_whale),
        shape=21,color="black"
      ) +
      geom_text(
        data=sp_data,
        aes(x=month,y=year,
            label=ifelse(overlap_days>0,overlap_days,"")),
        fontface="bold",size=2.5
      ) +
      scale_fill_gradient(
        low="white",
        high=species_colors[sp],
        limits=c(0,1),
        na.value="transparent",
        name=paste(sp,"% Whale Days")
      )
  }
  
  p +
    scale_size_continuous(range=c(1.5,10),
                          labels=percent,
                          name="% Days with MFA") +
    scale_x_continuous(breaks=1:12,labels=month.abb) +
    facet_grid(species~.,scales="free_y",space="free_y") +
    theme_minimal() +
    theme(panel.grid=element_blank(),
          axis.text.x=element_text(angle=45,hjust=1))
}

# ------------------------------------------------------------
# SAVE BUBBLE PLOTS (PDF + PNG)
# ------------------------------------------------------------
groups <- unique(bubble_data$plot_group)

for(pg in groups){
  
  p <- make_bubble_plot(
    bubble_data %>% filter(plot_group==pg)
  )
  
  fname <- paste0(site,"_",gsub(" ","_",pg),"_bubble_plot")
  
  ggsave(file.path(out_dir,paste0(fname,".pdf")),p,width=10,height=8)
  ggsave(file.path(out_dir,paste0(fname,".png")),p,width=10,height=8,dpi=300)
}

# ------------------------------------------------------------
# STACKED BAR
# ------------------------------------------------------------
stacked_data <- bubble_data %>%
  group_by(species,month) %>%
  summarise(total_overlap=sum(overlap_days),.groups="drop")

stacked_plot <- ggplot(stacked_data,
                       aes(x=month,y=total_overlap,fill=species)) +
  geom_col() +
  scale_fill_manual(values=species_colors) +
  scale_x_continuous(breaks=1:12,labels=month.abb) +
  theme_minimal(base_size=10) +
  theme(panel.grid=element_blank(),
        axis.text.x=element_text(angle=45,hjust=1))

ggsave(file.path(out_dir,paste0(site,"_stacked_bar.pdf")),
       stacked_plot,width=10,height=3.5)

ggsave(file.path(out_dir,paste0(site,"_stacked_bar.png")),
       stacked_plot,width=10,height=3.5,dpi=300)

# ------------------------------------------------------------
# LEGENDS (SEPARATE — RESTORED)
# ------------------------------------------------------------
legend_plot <- make_bubble_plot(bubble_data)

whale_legend <- cowplot::get_legend(legend_plot)

ggsave(file.path(out_dir,paste0(site,"_whale_legend.pdf")),
       whale_legend,width=5,height=10)

ggsave(file.path(out_dir,paste0(site,"_whale_legend.png")),
       whale_legend,width=5,height=10,dpi=300)

mfa_legend <- cowplot::get_legend(
  ggplot(bubble_data,aes(x=month,y=year,size=pct_mfa)) +
    geom_point() +
    scale_size_continuous(name="% Days with MFA")
)

ggsave(file.path(out_dir,paste0(site,"_mfa_legend.pdf")),
       mfa_legend,width=3,height=3)

ggsave(file.path(out_dir,paste0(site,"_mfa_legend.png")),
       mfa_legend,width=3,height=3,dpi=300)