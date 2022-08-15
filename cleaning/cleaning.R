
library(dplyr)
library(stringr)
library(data.table)
library(lubridate)
library(purrr)
library(tidyverse)


cleaning = function(df){
  
  Equipe <- data.frame(do.call('rbind', strsplit(as.character(df$Match),"-",fixed=TRUE)))[,1:2]
  
  colnames(Equipe) <- c("Equipe_Domicile", "Equipe_Exterieur")
  data_final <- cbind(df,Equipe)
  
  # score webcrapp avec "AWA" apres le score
  df$Score <- gsub("A*","",df$Score)
  df$Score <- gsub("W.","",df$Score)
  Score <- data.frame(do.call('rbind', strsplit(as.character(df$Score),":",fixed=TRUE)))[,1:2]
  colnames(Score) <- c("Score_Domicile", "Score_exterieur")
  data_final <- cbind(data_final,Score)
  
  # On retire les espaces avant et apres les noms d equipe 
  data_final$Equipe_Domicile <- gsub("[[:space:]]", "", data_final$Equipe_Domicile)
  data_final$Equipe_Exterieur <- gsub("[[:space:]]", "", data_final$Equipe_Exterieur)
  
  # separation des buts
  data_final$Score_Domicile <- as.numeric(data_final$Score_Domicile)
  data_final$Score_exterieur <- as.numeric(data_final$Score_exterieur)
  
  data_final = data_final %>% 
    mutate(nchar = nchar(Date))
  
  data_final$Date = ifelse(data_final$nchar < 8,
                      paste0(data_final$Date, as.character(data_final$saison)),
                      data_final$Date)
  
  data_final$Date = as.Date(data_final$Date ,"%d.%m.%Y")
  
  data_final = data_final %>%
    mutate(month = month(Date),
           year = year(Date),
           date2 = fifelse(saison == year & month %in% c(1,2,3,4,5,6,7),
                           Date %m+% years(1),
                           Date)) %>%
    select(-c(month, year, Date)) %>% 
    rename(date = date2)
  
  data_final
  
}

preprocess = function(df){
  
  df = df %>% arrange(date)
  
  df = df %>% 
    mutate(result = ifelse(Score_Domicile > Score_exterieur,
                           'win',
                           ifelse(Score_Domicile == Score_exterieur,
                                  'nul',
                                  'lose')))
  
  equipe_domicile = df %>% select(date, saison, Equipe_Domicile, Score_Domicile, Score_exterieur, result) %>% 
    mutate(domicile = 1) %>% 
    rename(but_marq = Score_Domicile,
           but_enc = Score_exterieur)
  
  equipe_exterieur = df %>% select(date, saison, Equipe_Exterieur,Score_Domicile, Score_exterieur, result) %>% 
    mutate(result = case_when(
      result ==  'lose' ~ "win",
      result ==  'win' ~ "lose",
      result ==  'nul' ~ "nul"
    ),
    domicile = 0) %>% 
    rename(Equipe_Domicile = Equipe_Exterieur,
           but_marq = Score_exterieur,
           but_enc = Score_Domicile)
  
  df_agg = rbind(equipe_domicile, equipe_exterieur) %>% 
    arrange(date)
  
  df_agg = df_agg %>% 
    mutate(points = case_when(
      result ==  'lose' ~ 0,
      result ==  'win' ~ 3,
      result ==  'nul' ~ 1
    )) %>% 
    
    group_by(Equipe_Domicile, saison) %>% 
    
    mutate(Point_class = cumsum(points),
           
           result_last1_match = lag(result),
           result_last2_match = lag(result_last1_match),
           result_last3_match = lag(result_last2_match),
           result_last4_match = lag(result_last3_match),
           result_last5_match = lag(result_last4_match),
           
           but_marq_last1_match = lag(but_marq),
           but_marq_last2_match = lag(but_marq_last1_match),
           but_marq_last3_match = lag(but_marq_last2_match),
           but_marq_last4_match = lag(but_marq_last3_match),
           but_marq_last5_match = lag(but_marq_last4_match),
           
           but_enc_last1_match = lag(but_enc),
           but_enc_last2_match = lag(but_enc_last1_match),
           but_enc_last3_match = lag(but_enc_last2_match),
           but_enc_last4_match = lag(but_enc_last3_match),
           but_enc_last5_match = lag(but_enc_last4_match)
    ) %>% 
    ungroup() %>% 
    
    mutate(point_avt_match = Point_class - points,
           but_marq_last_5_match = but_marq_last1_match + but_marq_last2_match + but_marq_last3_match + but_marq_last4_match + but_marq_last5_match,
           but_enc_last_5_match = but_enc_last1_match + but_enc_last2_match + but_enc_last3_match + but_enc_last4_match + but_enc_last5_match,
           
           no_lose = ifelse(result == 'lose',
                            0,
                            1)
    ) %>% 
    
    select(-c(but_marq_last1_match, but_marq_last2_match, but_marq_last3_match, but_marq_last4_match, but_marq_last5_match,
              but_enc_last1_match, but_enc_last2_match, but_enc_last3_match, but_enc_last4_match, but_enc_last5_match)) %>% 
    
    group_by(Equipe_Domicile, saison) %>%
    
    mutate(no_lose_strek = accumulate(no_lose, ~ifelse(.y == 0, .y, .x + .y))) %>% 
    ungroup() %>% 
    mutate(no_lose_strek = no_lose_strek - no_lose)
  
  df_agg_domicile = df_agg %>% filter(domicile == 1) %>% 
    select(-c(but_marq, but_enc, result, domicile, points, Point_class, no_lose))

    colnames(df_agg_domicile) <- paste(colnames(df_agg_domicile), "dom", sep = "_")
  
  df_agg_ext = df_agg %>% filter(domicile == 0) %>% 
    select(-c(but_marq, but_enc, result, domicile, points, Point_class, no_lose))
  
  colnames(df_agg_ext) <- paste(colnames(df_agg_ext), "ext", sep = "_")
  
  df_final = df %>% 
    left_join(df_agg_domicile, by = c("date" = "date_dom", "saison" = "saison_dom", 'Equipe_Domicile' = 'Equipe_Domicile_dom')) %>% 
    left_join(df_agg_ext, by = c("date" = "date_ext", "saison" = "saison_ext", 'Equipe_Exterieur' = 'Equipe_Domicile_ext'))
  
  df_final
  
}










