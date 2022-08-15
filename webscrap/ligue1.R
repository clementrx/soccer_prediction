source(paste0(currt_direct, "/webscrap/web_scrap_function.R"))

web_scrap(url_base = 'https://www.betexplorer.com/soccer/france/ligue-1',
          from = 2010,
          to = 2022,
          dir_save = paste0(currt_direct, '/data/'), 
          name = 'ligue1_2010_2022')
          
       