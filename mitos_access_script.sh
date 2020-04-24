#!/bin/bash
script=bar.txt
input1=$1
input2=$2
input3=$3
input4=$4
webpage=http://mitos.bioinf.uni-leipzig.de/index.py
len=${#input}
echo 'key <tab>' > $script
echo 'key <tab>' >> $script
echo 'key <tab>' >> $script
echo 'key <tab>' >> $script
echo 'key <tab>' >> $script
for i in `echo $input1|fold -w1` 
do
    echo 'key '$i >> $script
done
echo 'key <tab>' >> $script
for i in `echo $input2|fold -w1` 
do
    echo 'key '$i >> $script
done
echo 'key <tab>' >> $script
for i in `echo $input3|fold -w1` 
do
    echo 'key '$i >> $script
done
echo 'key <tab>' >> $script
echo 'key ^[[B' >> $script
echo 'key ^[[B' >> $script
echo 'key ^[[B' >> $script
echo 'key ^J' >> $script
echo 'key <tab>' >> $script
echo 'key ^J' >> $script
for i in `echo $input4|fold -w1` 
do
    echo 'key '$i >> $script
done
echo 'key ^J' >> $script
echo 'key ^J' >> $script
echo 'key <tab>' >> $script
echo 'key ^J' >> $script
WAIT PROBLEM



echo 'key <tab>' >> $script
echo 'key ^J' >> $script
echo 'key <tab>' >> $script
echo 'key ^J' >> $script
echo 'key Q' >> $script
echo 'key y' >> $script

lnyx $webpage -accept_all_cookies -cmd_script=bar.txt