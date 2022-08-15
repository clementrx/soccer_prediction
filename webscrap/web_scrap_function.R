# web scraping function

library(rvest)
library(dplyr)
library(stringr)

yesterday = as.character(Sys.Date()-1, format = "%d.%m.")

df = NULL

web_scrap = function(url_base,
                     from,
                     to,
                     dir_save,
                     name){
  
  year = c(from:to)
  
  for(i in year){
    
    cat(paste0('Web scrap season : ', i, '\n'))
    
    url = paste0(url_base,"-",i,"-", i+1, "/results/")
    
    while(TRUE){
      dl_file <- try(download.file(as.character(url), destfile = "temp.html", quiet=TRUE),
                     silent=TRUE)
      if(!is(dl_file, 'try-error')) break
    }
    
    url_html = read_html("temp.html")
    
    # match
    match <-  url_html %>%
      html_nodes('.in-match') %>%
      html_text() 
    
    # scores
    score <- url_html %>%
      html_nodes('.h-text-center a') %>%
      html_text() 

    # date
    date <- url_html %>%
      html_nodes('.h-text-no-wrap')%>%
      html_text()%>%
      str_replace("Yesterday", yesterday)
    
    df_saison <- data.frame(Date = date,
                            Match = match,
                            Score = score)
    
    df_saison$saison = i
    
    df = rbind(df, df_saison)
    
  }
  
  write.csv(df,
            paste0(dir_save, '/', name, '.csv'),
            row.names = FALSE)
}