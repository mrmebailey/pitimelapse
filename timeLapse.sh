#!/bin/bash

#
# Variables for the watermark on the video
#
month=`date +%B`
d=`date +%d%m%y`
dayofmonth=`date +%d`
t=`date +%T`
esc_time=`echo $t | sed 's/:/\\\:/g'`

#
# Apache root for easy viewing over HTTP
#
WEB_ROOT="/var/www/html"

#
# Project name comes in from command line as the first variable
#
PROJECT_NAME=${1}

display_usage() { 
	echo "This script will create a folder in the HTML Root with the project name" 
	echo -e "\nUsage: \$0 [Project Name in HTML Root to be created, no spaces...] \n" 
	} 
# if null display usage
	if [ ! -n "${PROJECT_NAME}" ]
	then
		display_usage
		exit 1
	fi
# if less than two arguments supplied, display usage 
	if [  $# -gt 1 ] 
	then 
		display_usage
		exit 1
	fi 
 
# check whether user had supplied -h or --help . If yes display usage 
	if [[ ( $# == "--help") ||  $# == "-h" ]] 
	then 
		display_usage
		exit 0
	fi 



#
# Make the project root if it does not exist
# Think about how to prevent overwriting a project
# that has just been copied from cron entry.
#
mkdir -p ${WEB_ROOT}/${PROJECT_NAME}

PROJECT_HOME=${WEB_ROOT}/${PROJECT_NAME}

cd ${PROJECT_HOME}


START_DATE=$(ls -lt | tail -1)

FILE=`ls -ltr | grep -vE "timelapse|pictures" | tail -1 | awk '{print $9}' | sed "s/\.jpg//g"`

if [ -z ${FILE} ] ;
then 
	raspistill -o 1.jpg -w 1024 -h 768 -q 30
	#raspistill -o 1.jpg 
else
	NEW_FILE=$(($FILE+1))
	rm -f timelapse.mp4

	raspistill -o ${NEW_FILE}.jpg -w 1024 -h 768 -q 30
	#raspistill -o ${NEW_FILE}.jpg 

	sleep 10
	
	ls | grep -E "[0-9].jpg" | sort -n  | sed "s/^/file /g" > pictures.txt

	nice -15 ffmpeg -f concat -safe 0 -i pictures.txt -c:v libx264 -pix_fmt yuv420p timelapse.mp4
	
	# nice -15 ffmpeg -framerate 25 -start_number 1 -i %d.jpg -c:v libx264 -c:a copy timelapse.mp4

	rm -f timelapse_banner.mp4

	ffmpeg -i timelapse.mp4 -vf "drawtext=text='Project ${PROJECT_NAME} to $month the $dayofmonth at $esc_time':x=(w-text_w)/2:y=h-th-40:fontsize=30:fontcolor=red" -c:a copy timelapse_banner.mp4

	cp timelapse_banner.mp4 timelapse_banner_static.mp4
	rm pictures.txt
fi



exit 0


