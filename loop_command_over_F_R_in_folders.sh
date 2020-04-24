#!/usr/bin/env bash

#usage: ./loop_command_over_forward_reverse_reads_in_folders "[command]"
# insert command you want to loop over reads
# in the command, simply insert "forward" and "reverse" for respective reads
# example for command: "spades -1 forward -2 reverse -o spades_output"
# --> will run spades on every pair in every folder with forward (_1) and reverse (_2) reads and create a folder spades_output in every separate folder

command_name=${1?Error: no command given}
for i in */; do
	cd "$i"
	for j in *; do
    	if [[ $j == *_1* ]]; then
    		file_1=$j
    	fi

    	if [[ $j == *_2* ]]; then
    		file_2=$j
    	fi
    done
    command_execute=$(echo $command_name | sed "s/forward/$file_1/" | sed "s/reverse/$file_2/")
    $command_execute
    cd ..
done
