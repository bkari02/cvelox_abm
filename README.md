# Cataglyphis Velox Foraging ABM
> This repository is part of a Master's Thesis to test the influence of variation in walking speed and environmental context on desert ant foraging.

This repository provides an AgentPy model for foraging movement of desert ants. The main purpose of the model is to study the influence of variation in walking speed and environmental context on path characterstics of desert ant foraging paths. Additionally a set of tools to analyse the model as well as observed and simulated movement data are offered within this repository.

Requirements
----
Python Packages
- [python](https://www.python.org/)
- [notebook](https://pypi.org/project/notebook/)
- [matplotlib](https://matplotlib.org/3.1.1/users/installing.html)
- [agentpy](https://agentpy.readthedocs.io/en/latest/)
- [salem](https://salem.readthedocs.io/en/stable/)
- [shapely](https://shapely.readthedocs.io/en/stable/installation.html)
- [rasterio](https://rasterio.readthedocs.io/en/stable/)
- [nbformat](https://pypi.org/project/nbformat/)
- [geopandas](https://geopandas.org/en/stable/)
- [pandas](https://pandas.pydata.org)
- [seaborn](https://seaborn.pydata.org)

R Packages
- [R](https://www.r-project.org)
- ggpubr
- ggplot2
- trajr
- sf
- tools
- ggstatsplot
- rstudio
- stats
- graphics
- grDevices
- utils
- datasets
- methods

## Installing / Getting started

A quick introduction of the minimal setup you need to get a hello world up &
running.

#### Python packages 
For installation of Python on your OS see [here](https://www.python.org/).
Python v3.9.12 was used for the thesis.

```shell
pip install notebook==6.4.8
pip install matplotlib==3.5.1
pip install agentpy==0.1.5
pip install salem==0.3.9
pip install shapely==2.0.1
pip install rasterio==1.3.5.post1
pip install nbformat==5.3.0
pip install geopandas==0.12.2
pip install seaborn==0.11.2
```

#### R packages
For installation of R on your OS see [here](https://cran.r-project.org).
From within R, the packages can be installed using 

```R 
packages.install(c("ggpubr", "ggplot2", "trajr", "sf", "tools", "ggstatsplot", "rstudio", "stats", "graphics", "grDevices", "utils", "datasets", "methods"))
```
