source(paste0(currt_direct, "/webscrap/web_scrap_function.R"))

web_scrap(url_base = 'https://www.betexplorer.com/soccer/spain/laliga',
          from = 2016,
          to = 2022,
          dir_save = paste0(currt_direct, '/data/'), 
          name = 'laliga_2016_2022')
