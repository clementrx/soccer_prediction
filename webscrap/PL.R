source(paste0(currt_direct, "/webscrap/web_scrap_function.R"))

web_scrap(url_base = 'https://www.betexplorer.com/soccer/england/premier-league',
          from = 2010,
          to = 2022,
          dir_save = paste0(currt_direct, '/data/'), 
          name = 'PL_2010_2022')
