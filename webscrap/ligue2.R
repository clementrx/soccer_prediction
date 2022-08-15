source(paste0(currt_direct, "/webscrap/web_scrap_function.R"))

web_scrap(url_base = 'https://www.betexplorer.com/soccer/france/ligue-2',
          from = 2010,
          to = 2022,
          dir_save = paste0(currt_direct, '/data/'), 
          name = 'ligue2_2010_2022')
