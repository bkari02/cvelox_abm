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

## Running the model and analyzing trajectories

All necessary code to run data analysis and to simulate the model is provided within multiple jupyter notebooks. Documentation and comments can be found within the notebooks. An overview of what the notebooks are meant for is given here:

- [Model Submission](Model_Submission.ipynb) notebook: This notebook includes the model code. (It does not run the model, just defines it)
- [Model Trajectory Visualization](<Model Trajectory Visualization.ipynb>) notebook: This notebook includes runs the calibrated and uncalibrated model versions and plots the reuslting trajectories in the notebook. Plots are also saved to files into the `model_outputs` folder.
- [Model Validation](Model_Validation.ipynb) notebook: This notebook runs the model validation. It splits the observation data into two sets and uses one to estimate parameters. Then it runs the calibrated and uncalibrated model versions, computes errors compared to the other observation set. Plots are printed in the notebook and saved int the `validation_data` folder.
- [Sobol Sensitivity Analysis](Sobol_sensitivity_analysis.ipynb) notebook: This notebook runs the Sobol' sensitivity analysis. Parameter ranges and sample size are defined and the model is run (may take several hours for large sample sizes). From the model results Sobol' indices are computed and visualized. Plots are printed in the notebook and saved int the `sensitivity_results` folder.
- [Trajectory Analysis](trajectory_analysis.ipynb) notebook: This notebook is basically just a wrapper for running the trajectory processing and analysis in R. It executes the R scripts and visualizes the figures in the notebook (does not work on Safari). 


## Attribution

#### Model
This presented model code in `Model_Submission.ipynb` is an adaption of the code by Thierry Hoinville, 2018, as part of the following work:

Hoinville T, Wehner R., Optimal multiguidance integration in insect navigation 
Proceedings of the National Academy of Sciences, 115 (11), 2824-2829 (2018).
DOI: [10.1073/pnas.1721668115](https://doi.org/10.1073/pnas.1721668115)


#### Tracking Data
The tracking data used here is part of the Ant Ontogeny Dataset from the following work:

Lars Haalck et al., CATER: Combined Animal Tracking & Environment Reconstruction.
Science Advances, 9 (16), eadg2094 (2023).
DOI:[10.1126/sciadv.adg2094](https://doi.org/10.1126/sciadv.adg2094)
