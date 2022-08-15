
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Soccer game prediction

**Authors:** [Clément Rieux](https://github.com/clementrx)

The goal of this project, is to predict the outcome of a soccer match
with the results of the last 5 matches from the season. (Consequently,
we can’t predict the first 5 match. Actually, yes but it will be biased)

I re-use his vizualisation, to plot a TV show rating from his IMDB
notes.

## How it works ?

-   **Web scarpping (Part 1)** : To begin we neeed data, so we are using
    [BetExplorer](https://www.betexplorer.com/soccer/) to get all our
    data we need (history)
-   **cleaning** : Secondly, we need to clean and preprocess our data
-   **modeling** : Then try some modeling to find a good model to
    predict the results
-   **Web scrapping (part 2)** : Now we have our tools, we need data to
    predict (upcoming matchs)
-   **predict** : Predict outomes
-   **testing** : How our model is performing ?
