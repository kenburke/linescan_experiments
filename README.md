# Linescan Experiments

Analysis and visualization of two-photon linescan experiments performed in Prairie View.

## purpose

1. Import raw imaging data and metadata from two-photon microscopy experiments performed in Prairie View.

2. Visualize raw data through convenient object-oriented structure to detect outliers and ensure experimental quality.

3. Perform analysis routines and visualize data at different stages of analysis (e.g. normalization, smoothing, peak responses over time)

## structure

The core component is the `lineScan` object. This contains all raw imaging data, as well as relevant metadata, for a set of linescans (as well as a fully-parsed hidden xmlData property with less-frequently used metadata). 

These linescans are grouped into `bouton` objects, indicating the particular bouton on which these linescans were performed (though functionally this can be generalized to any cell for different experiments). This allows methods relevant to single boutons (such as the amplitude of peak events over time through multiple linescans).

Finally, the boutons are grouped into `experiment` objects that indicate all boutons that followed a certain experimental protocol (and thus can be analyzed similarly).

```
.
??? README.md
??? data
?   ??? ***linescan data folders here***
??? broadcastState.m
??? lineScan.m
??? bouton.m
??? experiment.m
    ??? test_cluster.py
    ??? test_io.py
```

## usage

To use the package, first format your data file structure such that all Prairie View linescan folders are within the `data` folder (no reformatting is necessary).

To import only a linescan, simple navigate to the linescan folder and initiate the object

```
LS = lineScan;
```

Similarly, to import a bouton or an experiment, navigate to a folder that contains linescans or boutons, respectively, and run either

```
bout = bouton;
```
or
```
exper = experiment;
```

To initiate standard analyses, or visualize sample raw data and basic analysis plots, simply run

```
exper.analyze
```
or
```
exper.visualize
```

To visualize the entire raw linescan images from linescan #2 of bouton #1 from an experiment,

```
exper.boutons{1}.scans{2}.showImage
``` 
which plots the mean linescan image (averaged across trials) from two different channels (red and green) normalized to the baseline fluorescence:
![](https://imgur.com/LcIPaUm.png)


To visualize individual raw linescans (averaged across pixels) from linescan #2 of bouton #1 from an experiment,

```
exper.boutons{1}.scans{2}.plot_raw
```
which plots the raw traces from two different channels (red and green) with the mean/standard error and stimulus times (black vertical lines) indicated.
![](https://i.imgur.com/Owlwc4K.png)

To visualize mean dF/F responses for all linescan sets of a bouton,

```
exper.boutons{1}.plot_mean_dFF
```
![](https://imgur.com/LUphWqv.png)

To visualize trial-by-trial variability in peak dF/F responses for a given bouton,

```
exper.boutons{1}.plotPeakAmps_all
```
![](https://imgur.com/0TK77U6.png)


## testing

## contributors

Original design by Ken Burke