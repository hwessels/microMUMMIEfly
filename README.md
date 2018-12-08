# microMUMMIEfly

MicroMUMMIE is a specific model, implemented within the [MUMMIE](https://ohlerlab.mdc-berlin.de/files/duke/MUMMIE/) framework, for predicting microRNA binding sites using PAR-CLIP data.  Thus, while MUMMIE can be used for many different bioinformatic modeling tasks, microMUMMIE is a specific model for a specific task. Here you find the guidelines for the installation and usage of microMUMMIE specific to *Drosophila melanogaste* data. For human, please defer to this [page](https://ohlerlab.mdc-berlin.de/software/microMUMMIE_99/). 

### 1.  Installation

#### Install Base Packages

##### Install PARalyzer

MicroMUMMIE microRNA binding site predictions depend on [PARalyzer](https://ohlerlab.mdc-berlin.de/software/PARalyzer_85/) output files. Please begin by installing PARalyzer implemented in [PARpipe](https://github.com/ohlerlab/PARpipe). To run PARpipe succesfully on fly data you will need the bowtie-index, GTF, 2bit file, repeat masker files, and transcript isoform tracking file deposited [here]().
PARalyzer uses Bowtie to align PAR-CLIP reads to the genome and then constructs a smooth signal curve that can be used for peak-calling to find (roughly) where an RNA-binding protein (such as Argonaute) binds. However, rather than using a peak-caller, microMUMMIE instead uses a hidden Markov model (HMM) to find the most probable miRNA seed match near the PARalyzer peak.  This allows microMUMMIE to weigh multiple forms of evidence (e.g., T-to-C conversion rates, evolutionary conservation, RNA sequence) in making the most informed prediction. 

##### Install MUMMIE

Precompiled linux binaries and custom script are available here and may may work on your system. if they don't, you'll need to compile the [source code](https://ohlerlab.mdc-berlin.de/files/duke/MUMMIE/mummie.tgz). Please find the instructions [here](https://ohlerlab.mdc-berlin.de/software/microMUMMIE_99/).

Here, we only provide the option to run microMUMMIE without conservation. 

##### Set Environment Variables

As noted in the compilation instructions on the download page, you must add several MUMMIE directories to your path.


### 2.  Run PARpipe

Before you can predict microRNA binding sites, you need to process your AGO1 PAR-CLIP fastq reads using PARpipe. Please see the [PARalyzer instructions](https://ohlerlab.mdc-berlin.de/files/duke/PARalyzer/README.txt) for recommended parameters. Parameters used for Drosophila can be found in our recent [manuscript](https://doi.org/10.1101/395335). PARpipe produces three critical input files for microMUMMIE (prefix.clusters.csv, prefix.groups.csv and prefix.distribution). This distribution file provides smoothed T-to-C conversion profiles for each AGO binding site used by microMUMMIE. For more information about PARalyzer can be found [here](https://doi.org/10.1186/gb-2011-12-8-r79). Accessory files to run PARpipe on fly PAR-CLIP data can be downloaded from [here].

Once you have installed PARpipe and assigned all accessory files within parclip_pipe.sh, cd into your data folder and execute the PARpipe:

```ruby
cd workdir
bpipe run -r /PathToParpipe/parclip_pipe.sh prefix.fastq
```







