#!/bin/bash

#
# Script to add the timestamps retrospectively but preseve the original timestamp of the file
#

LOCATION=${1}

if [ ! -n "${1}" ]
then
    echo "Need input folder containing *.jpg files"
    exit 1
fi

for file in ${LOCATION}/*.jpg
do 
    ts=`date -r $file`
    orig_ts=`date -r $file +%Y%m%d%H%M`
    convert $file -fill lime -gravity NorthEast -pointsize 40 -annotate +5+5 "\ $ts" ${file} 
    touch -t $orig_ts $file
done
