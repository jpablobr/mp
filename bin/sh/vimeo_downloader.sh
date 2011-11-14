#!/bin/sh

VIMEO_URL=`echo $1 | awk -F / '{print $NF}'`

which wget
if [ $? -eq 0 ]; then
	echo "Using wget..."
	GET_CMD="wget -O -"
else
	which curl
	if [ $? -eq 0 ]; then
		echo "Using curl..."
		GET_CMD="curl -L"
	else
		echo "Could not find wget or curl"
		exit 2
	fi
fi

VIDEO_XML=`${GET_CMD} ${VIMEO_URL}`

echo $VIDEO_XML

# FLV_URL=`echo $VIDEO_XML | sed -e 's/^.*<request_signature>\([^<]*\)<.*$/\1/g'`

# echo "\nDownloading video ${FLV_URL}\n"
# # curl -C - -L -O "$FLV_URL"
# echo "Video ${FLV_URL}"
# echo `file "${FLV_URL}"`
