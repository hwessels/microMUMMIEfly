# microMUMMIEfly


 MicroMUMMIE is a specific model, implemented within the [MUMMIE](https://ohlerlab.mdc-berlin.de/files/duke/MUMMIE/) framework, for predicting microRNA binding sites using PAR-CLIP data.  Thus, while MUMMIE can be used for many different bioinformatic modeling tasks, microMUMMIE is a specific model for a specific task. Here you find the guidelines for the installation and usage of microMUMMIE specific to *Drosophila melanogaste* data. For human, please defer to this [page](https://ohlerlab.mdc-berlin.de/software/microMUMMIE_99/). 

<br>
<br>

### 1.  Installation

#### Install Base Packages

##### Install PARalyzer

 MicroMUMMIE microRNA binding site predictions depend on [PARalyzer](https://ohlerlab.mdc-berlin.de/software/PARalyzer_85/) output files. Please begin by installing PARalyzer implemented in [PARpipe](https://github.com/ohlerlab/PARpipe). To run PARpipe succesfully on fly data you will need the following files: 
 [bowtie-index](https://ohlerlab.mdc-berlin.de/files/microMUMMIEfly/PARpipefly_accessory/bwt.tar.gz), 
 [GTF](https://ohlerlab.mdc-berlin.de/files/microMUMMIEfly/PARpipefly_accessory/Drosophila_melanogaster.BDGP6.ensemblv81.mod.gtf.gz), 
 [2bit file](https://ohlerlab.mdc-berlin.de/files/microMUMMIEfly/github/microMUMMIEfly/accessory/Drosophila_melanogaster.BDGP6.dna.toplevel.2bit), 
 [repeat masker file](https://ohlerlab.mdc-berlin.de/files/microMUMMIEfly/PARpipefly_accessory/dm6_rmsk.bed.gz), 
 [repeat masker info file](https://ohlerlab.mdc-berlin.de/files/microMUMMIEfly/PARpipefly_accessory/dm6_rmsk_info), and
 [transcript isoform tracking file](https://ohlerlab.mdc-berlin.de/files/microMUMMIEfly/PARpipefly_accessory/isoforms.fpkm_tracking_rsem_S2cells_ensemblv81).
 
 
 All files except the bowtie index can remain zipped. To unzip the bowtie index:
  ```ruby
 cd Downloads
tar xvzf bwt.tar.gz /PathTo/PARpipe/files/
```
 
 PARalyzer uses Bowtie to align PAR-CLIP reads to the genome and then constructs a smooth signal curve that can be used for peak-calling to find (roughly) where an RNA-binding protein (such as Argonaute) binds. However, rather than using a peak-caller, microMUMMIE instead uses a hidden Markov model (HMM) to find the most probable miRNA seed match near the PARalyzer peak. This allows microMUMMIE to weigh multiple forms of evidence (e.g., T-to-C conversion rates, evolutionary conservation, RNA sequence) in making the most informed prediction. 

<br>

##### Install MUMMIE

 Precompiled linux binaries and custom script are available in microMUMMIEfly/bin and microMUMMIEfly/scripts and may work on your unix system. 
 
 ```ruby
 cd pathToSoftware/
 git clone https://github.com/hwessels/microMUMMIEfly.git
```

 
 if they don't, you'll need to compile the [source code](https://ohlerlab.mdc-berlin.de/files/duke/MUMMIE/mummie.tgz). Please find the instructions [here](https://ohlerlab.mdc-berlin.de/software/microMUMMIE_99/).

Here, we only provide the option to run microMUMMIE without conservation. 


Add the microMUMMIE folders to your PATH
```ruby
export PATH=${PATH}:PathTo/microMUMMIEfly/bin
export PATH=${PATH}:PathTo/microMUMMIEfly/scripts
export PERL5LIB=PathTo/microMUMMIEfly/scripts:$PERL5LIB
```



After cloning the microMUMMIEfly repository, the path containing microMUMMIE.pl should contain bin, scripts, files, accessory and testdata folders. Make sure you set permission to make all files readable.
```ruby

cd microMUMMIEfly

chmod 755 -R *

ls -ltr 

drwxr-sr-x 2 xxx user    6 Dec 14 03:10 files
drwxr-sr-x 2 xxx user   11 Dec 14 03:10 bin
drwxr-sr-x 3 xxx user   27 Dec 14 03:10 scripts
drwxr-sr-x 2 xxx user    6 Dec 14 03:10 accessory
-rwxr--r-- 1 xxx user 6860 Dec 14 03:10 microMUMMIE.pl
drwxr-sr-x 3 xxx user   47 Dec 14 03:49 testdata


```

Set the microMUMMIE path at the top of the main perl wrapper script *microMUMMIE.pl* to help all relative paths to be found.
```ruby
# add the full microMUMMIE path to help all relative paths to be found
my $mummie_path = "PathTo/microMUMMIEfly";
```


The [2bit dm6 genome genome](https://ohlerlab.mdc-berlin.de/files/microMUMMIEfly/github/microMUMMIEfly/accessory/Drosophila_melanogaster.BDGP6.dna.toplevel.2bit) needs to be placed inside PathTo/microMUMMIEfly/accessory/   

```ruby
cd Downloads
mv Drosophila_melanogaster.BDGP6.dna.toplevel.2bit PathTo/microMUMMIEfly/accessory/ 
```



 Moreover, microMUMMIE requires Bedtools. Please install [Bedtools](https://bedtools.readthedocs.io/en/latest/) and add it to your PATH.


<br>
<br>

### 2.  Run PARpipe

 Before you can predict microRNA binding sites, you need to process your AGO1 PAR-CLIP fastq reads using PARpipe. Please see the [PARalyzer instructions](https://ohlerlab.mdc-berlin.de/files/duke/PARalyzer/README.txt) for recommended parameters. Parameters used for Drosophila can be found in our recent [manuscript](https://doi.org/10.1101/395335). PARpipe produces three critical input files for microMUMMIE (prefix.clusters.csv, prefix.groups.csv and prefix.distribution). This distribution file provides smoothed T-to-C conversion profiles for each AGO binding site used by microMUMMIE. For more information about PARalyzer can be found [here](https://doi.org/10.1186/gb-2011-12-8-r79). Accessory files to run PARpipe on fly PAR-CLIP data can be downloaded from [coming soon](). 

 Once you have installed PARpipe and assigned all accessory files within parclip_pipe.sh, add parclip_pipe.sh to your workdir, cd into your data folder and execute the PARpipe:

```ruby
cd workdir
bpipe run -r parclip_pipe.sh prefix.fastq
```

Example PARpipe output data files that serve as microMUMMIE input can be found in the testdata subfolder. The required PARpipe output files (*prefix.clusters.csv, prefix.groups.csv and prefix.distribution*) of a full AGO1 PAR-CLIP data set in Drosophila S2 cell can be found on [GEO](https://www.ncbi.nlm.nih.gov/geo/) under accession number GSE109980.


<br>
<br>


### 3.  Run microMUMMIE


 The microMUMMIE.pl wrapper script calls all required steps for microRNA binding site prediction. To run microMUMMIE, cd into your run folder (= *PARpipe output folder*). Your run folder must contain the required PARpipe output files *prefix.clusters.csv*, *prefix.groups.csv* and *prefix.distribution*. 


**perl microMUMMIE.pl  mature-miRNAs.txt   genome.2bit   ParalyzerOutputDir   SamplePrefix  out.gff  posterior-decoding 0/1 coordinatefile  OutputDir**


```ruby

cd PathTo/microMUMMIEfly/testdata/

microMUMMIE='PathTo/microMUMMIEfly/microMUMMIE.pl'
MATURE_MIR_TXT='PathTo/microMUMMIEfly/testdata/top30.miRNA.txt'
TWOBIT='PathTo/microMUMMIEfly/accessory/Drosophila_melanogaster.BDGP6.dna.toplevel.2bit'
WD=$(pwd)
PREFIX=AGO1_chr4
OUT=out.gff
MODE=0 # (0 = viterbi; 1 = posterior decoding)
FEATURE='PathTo/microMUMMIEfly/accessory/dm6_ENSv81_3utr.txt'

perl $microMUMMIE $MATURE_MIR_TXT $TWOBIT $WD $PREFIX $OUT $MODE $FEATURE $WD

```

<br>

The microMUMMIE.pl input files are the following:

- mature-miRNAs.txt : *This is a 2-column text file giving the name of the miRNA in the first column and the 20-24nt mature miRNA {A, C, G, U} sequence in the second column.*
- genome.2bit : *This is the complete genome in 2bit format.*
- ParalyzerOutputDir : *Path to output directory from Paralyzer or PARpipe containing XX.distribution/clusters/groups.csv files.*
- SamplePrefix : *The name of library -- i.e., the initials XX in the file name XX.distribution/clusters/groups.csv*
- out.gff : *This is the file that the output of microMUMMIE.pl will be written into.*
- 0 : *This is an advanced option for Viterbi decoding or posterior decoding. (1=posterior decoding, 0=Viterbi decoding; posterior decoding will generally produce more predictions than Viterbi).*
- coordinatefile : *Tab-separated file containing coordinates of genomic sequences to search -- i.e.  3'UTR,  CDS or 5'UTR. Columns should be in this order: Chromosome, Start, End, GeneID, Strand, Transcript ID.*
- OutputDir: *Path of the directory where you want to save all the output files from the program so that you can run script in parellel.*



*Note also that the script generates temporary files that will be overwritten each time the script is executed. Thus, you may not run two copies of the script simultaneously in the same directory.*  

<br>


####  Run microMUMMIE with targetscan conservation

 In our original [microMUMMIE manuscript](https://doi.org/10.1038/nmeth.2489) we used targetscan microRNA binding site conservation scores to improve microRNA binding site predictions in [human](https://ohlerlab.mdc-berlin.de/software/microMUMMIE_99/). We tried to implement targetscan microRNA binding site branchlength conservation scores in a similar way for fly data using a 27way multiple sequence alignment. However, we did not find that the branchlength score helped the microRNA binding site predictions. If you wish to implement targetscan branchlength score usage microMUMMIEfly similar to [human](https://ohlerlab.mdc-berlin.de/software/microMUMMIE_99/), you can find the required 3'UTR multiple sequence alignment files [here](https://ohlerlab.mdc-berlin.de/files/microMUMMIEfly/github/microMUMMIEfly/accessory/BDGP6_ENSv81_3utr.maf).

<br>
<br>

### 4.  Interpreting the Output

<br>

Output Format

 The output will be three files according to the out.gff name, which consists of 1-based coordinates of predicted miRNA targets and their probability scores. The main out.gff file contain miRNA binding site predictions relative to the feature start (i.e. 3'UTR start). The main out.gff-genomic.gff file contains the genomic mapping information. And out.gff-map.gff filters for predictions that overlap the input prefix.groups.csv file. The output is mapped to transcript isoforms. Thus, overlapping windows (i.e. 3'UTR isoforms) may generate redundant predictions. Note that the script actually generates several sets of predictions made at different sensitivities and specificities; all out.gff files contains all of these prediction sets, parameterized indicated sensitivity and specificity values. Individual prediction sets at other parameterizations are available in the files named predictions-varNNN.gff. Higher values of NNN correspond to higher specificity/SNR/accuracy, and lower sensitivity. 

Here is a sample line from microMUMMIE's out.gff- output:
 
 ```ruby
 
head -n 1 out.gff-genomic.gff
2L	Binding	site	18701559	18701565	0.782911824	-	.	gene=CG10376_0;transcriptid=FBtr0081128;utr_start=18700604;utr_end=18701626;prediction_start=62;prediction_end=68;seq=GTACAAA;type=7mer-A1;miRNA=dme-miR-305-5p;sens=0.62;SNR=2.24;

```
 
 <br>
 
 This line can be interpreted as follows.  On chromosome 2L (chr2L), occupying 1-based coordinate interval 18701559-18701565 on the negative strand is a seed match to miRNA dme-miR-305-5p.  The corresponding DNA sequence for this RNA target site is GTACAAA. The posterior probability of this site under the microMUMMIE model is 0.7829, the estimated sensitivity is 62%, and the estimated signal-to-noise ratio (SNR) is 2.24 (these latter two statistics are interpolated from previously performed shuffling experiments). Finally, the type of seed match is 7mer-A1, which means that the match is 7nt long, but the 3'-most residue is an A even if the miRNA seed residue at this position is not a U.

<br>
<br>






##### Scores and Postprocessing

 MicroMUMMIE may perform posterior decoding, which means that multiple sites may be predicted for each PAR-CLIP cluster, and the scores assigned to individual sites are posterior probabilities. The posterior probability of a site is the probability of the HMM going through the foreground states for a site, irrespective of what other states are visited outside this putative site.  One implication of this fact is that predicted sites that partially overlap will be forced to share probability, since different states are mutually exclusive at a given site in the HMM.  However, for different types of seed matches (e.g., 6mer, 7mer, 8mer), the probabilities of each of these types of matches will be appropriately summed for any given miRNA, so that, for example, a 6mer match inside a 7mer match will not subtract from the 7mer score.

<br>
<br>

##### Sensitivity, Specificity, and Signal-to-Noise Ratio

 MicroMUMMIE can be parameterized to run at different sensitivities or specificities.  The single parameter to microMUMMIE, called the peak emission variance (PEV), controls the tradeoff between sensitivity and specificity.  Higher PEV produces higher specificity, so that the predictions you obtain should be more confident.  Lowever PEV produces higher sensitivity, so that you will receive more predictions, though not all predictions will be of the highest confidence.  The individual output files named predictions-varNNN.gff contain predictions at different PEV values; the single default output file is simply a copy of one of these files selected to have medium sensitivity and medium specificity, but you can opt for greater sensitivity by choosing a lower PEV or greater specificity by choosing a higher PEV.
<br>
When running microMUMMIE on a new data set, it is not feasible to assess the actual sensitivity, specificity, or signal-to-noise ratio (SNR, which generally correlates with specificity) without extensive simulation experiments.  Thus, to provide a rough indication of the sensitivity and specificity trends, estimates of these values are inferred by interpolating from the following table, which was generated via large-scale simulation results:

| PEV   | sensitivity | SNR     |
| :---: |   :---:     |   :---: |
| 0.5   | 0.12        | 15.7    |
| 0.25  | 0.17        | 12.04   |
| 0.2   | 0.2         | 9.95    |
| 0.15  | 0.27        | 7.07    |
| 0.1   | 0.42        |  5.09   |
| 0.01  | 0.62        | 2.24    |


