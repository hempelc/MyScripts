#!/bin/bash

R1=$1
R2=$2
seed=$3
prefix=$4

echo -e \
"Project:
-----------------------
Project name          = ${prefix}_NOVOPlasty
Type                  = mito
Genome Range          = 12000-22000
K-mer                 = 23
Max memory            = 
Extended log          = 0
Save assembled reads  = no
Seed Input            = ${seed}
Reference sequence    = 
Variance detection    = no
Heteroplasmy          = 
HP exclude list       = 
Chloroplast sequence  = 
\n
Dataset 1:\n
-----------------------
Read Length           = 100
Insert size           = 400
Platform              = illumina
Single/Paired         = PE
Combined reads        = 
Forward reads         = ${R1}
Reverse reads         = ${R2}

Optional:
-----------------------
Insert size auto      = yes
Insert Range          = 1.6
Insert Range strict   = 1.2
Use Quality Scores    = yes" > config_$prefix.txt

NOVOPlasty2.7.2.pl -c config_$prefix.txt