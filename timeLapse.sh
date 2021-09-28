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

#
# We build a file list dynamically as ffmpeg expects a squential list of pictures
# and fails if it does not get them.  You will almost certainly want to delete 
# anmolies like your washing or if you get a failure to remove a day.
#
FILE=`ls -ltr | grep -vE "timelapse|pictures" | tail -1 | awk '{print $9}' | sed "s/\.jpg//g"`

#
# If there is no file then we are creating the very first pictrure
#
if [ -z ${FILE} ] ;
then
	#
	# Setting the quality width, height & quality to 30 seems the 
	# best balance for HD camera for longer projects.
	#
	raspistill -o 1.jpg -w 1024 -h 768 -q 30

else
	#
	# We still expect squential file naming so add one and remove 
	# the previous timelapse video as it will fail if already present
	#
	NEW_FILE=$(($FILE+1))
	rm -f timelapse.mp4

	#
	# Should breakout into a funtion for reuse to tune 
	# height, width and quality, I hope I can do this before
	# DevCon but stick with good comments for now.
	#
	raspistill -o ${NEW_FILE}.jpg -w 1024 -h 768 -q 30

	sleep 10
	
	#
	# Build the file list of files that exist as gaps will cause ffmpeg to 
	# fail with a warning.
	#
	ls | grep -E "[0-9].jpg" | sort -n  | sed "s/^/file /g" > pictures.txt

	#
	# Use nice to lower priority although it should not be doing anything else but did cause 
	# CPU to spike otherwise.
	###########     Concat     Rel Path   Pics List    Set Codec & Video formats C:V
	nice -15 ffmpeg -f concat -safe 0 -i pictures.txt -c:v libx264 -pix_fmt yuv420p timelapse.mp4

	#
	# Remove the previous
	#
	rm -f timelapse_banner.mp4

	#
	# Add on the banner
	#
	ffmpeg -i timelapse.mp4 -vf "drawtext=text='Project ${PROJECT_NAME} to $month the $dayofmonth at $esc_time':x=(w-text_w)/2:y=h-th-40:fontsize=30:fontcolor=red" -c:a copy timelapse_banner.mp4

	#
	# Create a static version of the file that would not be written to so
	# can easily be viewed from a web browser.
	#
	cp timelapse_banner.mp4 timelapse_banner_static.mp4
	rm pictures.txt
fi
exit 0


