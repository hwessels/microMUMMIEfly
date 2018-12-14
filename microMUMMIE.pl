#!/usr/bin/perl
use strict;
use TempFilename;
use File::Basename;
use File::Spec;
use File::chdir;

# add the full microMUMMIE path; else it cannot copy the files in line 26
my $mummie_path = "/data/ohler/harm/github/microMUMMIEfly/withouttgsn";

my $VERBOSE=1;

my $WANT_BULGE=0;
my $WANT_CONSERVATION=0;
my $TARGETSCAN_VARIANCE=3.0;
my $TARGETSCAN_BG_MEAN=0.0;
my $TARGETSCAN_FG_MEAN=3.0;
my $dir_path = dirname(File::Spec->rel2abs(__FILE__));

die "microMUMMIE.pl <mature-miRNAs.txt> <genome.2bit> <paralyzer-output-dir> <library-name> <out.gff> <posterior-decoding:0/1> <UTRs.txt> <Path of directory where you want to write all analysis in the end>\n"
  unless @ARGV==8;
my ($mature,$twoBitFile,$dataDir,$libraryName,$outfile,$wantPost,$UTR_FILE,$dir)=@ARGV;
my $DASH_G=$wantPost ? "-I" : "-g";

System("date");

`cp $UTR_FILE $mummie_path/bin/site.hmm $mummie_path/bin/bg.hmm $mummie_path/bin/peak.hmm $mummie_path/bin/flank-trained.hmm $mummie_path/files/metamodel.txt $mummie_path/files/submodels.txt $mummie_path/files/cons.schema $mummie_path/files/nocons.schema $mummie_path/bin/hmm-edit $mummie_path/bin/random-HMM $mummie_path/bin/baum-welch $mummie_path/bin/model-combiner $dir`;

my $groupsFile="$dataDir/$libraryName.groups.csv";


$CWD=$dir;
print "
# -------------------------------------------
# EXTRACTING SEEDS FROM MATURE MICRO-RNA LIST
# -------------------------------------------
";

System(" perl $mummie_path/scripts/get-seeds.pl $mature seeds.fasta");

print "
# -------------------------------------------
# BUILDING THE SITE SUBMODEL
# -------------------------------------------
";

System("perl $mummie_path/scripts/make-42state-site.pl seeds.fasta .33 .33 .33 4 cons.schema 7 bg.hmm site.hmm '' N N");

print "
# -------------------------------------------
# COMBINING SUBMODELS INTO FULL MODEL
# -------------------------------------------
";

System("model-combiner metamodel.txt submodels.txt PARCLIP.hmm");
if($WANT_CONSERVATION)
  {
  System("./hmm-edit PARCLIP.hmm MEAN all -- 1 $TARGETSCAN_BG_MEAN");
  System("./hmm-edit PARCLIP.hmm VAR  all -- 1 $TARGETSCAN_VARIANCE");
  System("./hmm-edit PARCLIP.hmm MEAN 3   -- 1 $TARGETSCAN_FG_MEAN");
  }
else {
    System("./hmm-edit PARCLIP.hmm DTRK targetscan");
}


print "
# -------------------------------------------
# PREPARING INPUT FILES
# -------------------------------------------
";

System("rm -rf $dir/chunks") if -e "chunks";
System("rm -rf $dir/chunks2") if -e "chunks2";

System("mkdir $dir/chunks $dir/chunks2");

System("perl $mummie_path/scripts/par2fastb.pl $twoBitFile $dataDir $dir/chunks $UTR_FILE $libraryName");

System("perl $mummie_path/scripts/assemble-transcripts.pl chunks chunks2 ; rm -r $dir/chunks ; mv $dir/chunks2 $dir/chunks");



print "
# -------------------------------------------
# RUN THE MODEL
# -------------------------------------------
";

System("rm predictions-var*.gff");
my @vars=(0.5,   0.25,  0.2,  0.15,  0.1,  0.01);
my @sens=(0.12,  0.17,  0.2,  0.27,  0.42, 0.62);
my @SNR= (15.7, 12.04,  9.95, 7.07,  5.09, 2.24);
my $N=@vars;
for(my $i=0 ; $i<$N ; ++$i) {
  my $var=$vars[$i];  my $sens=$sens[$i];  my $snr=$SNR[$i];
  print "Running at variance $var\n";
  System("./hmm-edit PARCLIP.hmm VAR all 0 $var");
  System("$mummie_path/bin/parse $DASH_G 5-45 -p -d PARCLIP.hmm $dir/chunks > chunk-preds.gff");
  System("perl $mummie_path/scripts/identify-miRNAs.pl chunk-preds.gff seeds.fasta > identify.tmp");
  System("perl $mummie_path/scripts/combine-miRNA-predictions.pl identify.tmp > chunk-preds.gff");
  System("perl $mummie_path/scripts/get-chrom-coords_try.pl chunk-preds.gff > predictions-var$var.gff");
  addScores("predictions-var$var.gff",$sens,$snr);
  System("perl $mummie_path/scripts/match_coordinates.pl predictions-var$var.gff chunks predictions-var$var-genomic.gff");
  `cut -f 1,4,5,6,7,8,9 predictions-var$var-genomic.gff > tmp.gff`;
 # `cat $groupsFile | perl -wp -ne 's/,/\t/g'| awk -F"\t" 'BEGIN{OFS="\t"}{print $1,$3,$4,$8,$10,$2,$5}' |  perl -ne'\$.==1?next:print' | intersectBed -wao -a tmp.gff -b stdin | awk -F'\t' '$15 != 0' | awk -F"\t" 'BEGIN{OFS=FS}{print $1,$14,$11,$2,$3,$4,$13,$7,$9,$10}'|  awk 'BEGIN{print "Chromosome\tAlinged_to\tGroupID\tPrediction_start\tPrediction_end\tScore\tStrand\tInfo\tGroup_start\tGroup_end"}1'  | perl -wp  -ne 's/ /\t/g' > predictions-var$var-map.gff`;
 `cat $groupsFile | perl -wp -ne 's/,/\t/g' | while read -r col1 col2 col3 col4 col5 col6 col7 col8 col9 col10 col11 col12 col13 col14 col15 col16 col17 col18 col19 col20 col21 col22; do echo \$col1 \$col3 \$col4 \$col8 \$col10 \$col2 \$col5; done | perl -wp  -ne 's/ /\t/g' | perl -ne'\$.==1?next:print' | intersectBed -wao -a tmp.gff -b stdin | perl -e 'while(<>){ \@line = split(/\t/, \$_); if( \$line[14]=~ 0 ) { next;} else  { print "\$_"; } }' | while read -r col1 col2 col3 col4 col5 col6 col7 col8 col9 col10 col11 col12 col13 col14 col15; do echo \$col1 \$col14 \$col11 \$col2 \$col3 \$col4 \$col13 \$col7 \$col9 \$col10; done | perl  -ple 'print q{Chromosome Alinged_to GroupID Prediction_start Prediction_end Score Strand Info Group_start Group_end} if \$. == 1; close ARGV if eof' | perl -wp  -ne 's/ /\t/g' > predictions-var$var-map.gff`;
`cut -f 2 predictions-var$var-map.gff | sort | uniq -c > alignment_stats_var$var`;
}

`ls predictions-var*.gff > filename`;
`cat filename | grep -v genomic | grep -v map > filename1`;
`cat filename | grep genomic > filename2`;
`cat filename | grep map > filename3`;
System("for fn in `cat filename1`; do cat \$fn; done > $outfile");
System("for fn in `cat filename2`; do cat \$fn | perl -ni.bak -e'print unless m/^Chromosome/' ; done > $outfile-genomic.gff");
System("for fn in `cat filename3`; do cat \$fn | perl -ni.bak -e'print unless m/^Chromosome/' ; done > $outfile-map.gff");
`cut -f 2 $outfile-map.gff | sort | uniq -c > alignment_stats_$outfile-genomic`;


print "
# -------------------------------------------
# DONE.  OUTPUT IS IN: $outfile
# -------------------------------------------
";








#if running from the output folder the initially copied files can be removed
`rm -r chunks identify.tmp PARCLIP.hmm seeds.fasta hmm-edit tmp.gff chunk-preds.gff site.hmm bg.hmm peak.hmm flank-trained.hmm metamodel.txt submodels.txt cons.schema nocons.schema mm-edit random-HMM baum-welch model-combiner $UTR_FILE filename filename1 filename2 filename3 *clusters.gff`;

sub addScores
  {
    my ($filename,$sens,$snr)=@_;
    my $tempName=TempFilename::generate();
    open(IN,$filename) || die "can't open file: $filename\n";
    open(OUT,">$tempName") || die "can't write to file: $tempName\n";
    while(<IN>) {
      chomp;
      print OUT "${_}sens=$sens;SNR=$snr;\n";
    }
    close(OUT);
    close(IN);
    System("mv $tempName $filename");
  }


sub System
{
    my ($cmd)=@_;
    if($VERBOSE) { print "$cmd\n" }
    system($cmd);
}

