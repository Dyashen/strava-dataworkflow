#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail

: '
Directories
'
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
gathered_files_folder=${script_dir}"/gathered_files"
transformed_data_folder=${script_dir}"/transformed_data"
logfolder=${script_dir}"/logs"
logfile="${logfolder}/log.txt"
scripts_folder=${script_dir}"/scripts/"

: '
HOPEFULLY JUST THE START
'

echo "---------------------------------"

echo " ?? Checking for script folder..."
if [ ! -d "${scripts_folder}" ];then
    echo "CRITICAL FAILURE: SCRIPTS NOT FOUND" >> "${logfile}"
    exit 1
fi

echo " ?? Checking for logfile..."
if [ ! -d "${logfolder}" ];then
    touch "${logfile}" 2>> /dev/null # first time
fi

: '
INSTALL PACKAGES IF NECESSARY
'
install_packages(){
    if ! type -P php || ! type -P php-cgi || ! type -P lighttpd || ! type -P python3 || ! type -P pip; then
        {
        apt install php-cgi lighttpd php libapache2-mod-php php-mysql pandoc python3 python-pip -y
        lighty-enable-mod fastcgi && lighty-enable-mod fastcgi-php
        pip install landslide
        } 2>> "${logfile}"
    fi
    # systemctl restart lighttpd --> not necessary
}

echo " ?? Checking for installed packages..."
install_packages >> /dev/null 2>> "${logfile}"

: '
Create directories if necessary
'
echo " ?? Checking for gathered folder..."
if [ ! -d "${gathered_files_folder}" ];then
    mkdir "${gathered_files_folder}" 2>> "${logfile}"
fi

echo " ?? Checking for CSV..."
if [ ! -d "${transformed_data_folder}" ];then
    mkdir "${transformed_data_folder}" 2>> "${logfile}"
fi

: '
LOOP THROUGH SCRIPTS
USE ABSOLUTE PATHS
'
echo " XX Gathering STRAVA DATA..."
/bin/bash "${scripts_folder}/DataGatherer.sh"

echo " XX Transforming JSONs to CSV..."
/bin/bash "${scripts_folder}/DataTransformer.sh"

echo " XX Generating graphs..."
/bin/python3 "${scripts_folder}"DataAnalyser.py 2>> "${logfile}"

echo " XX Creating PDFs..."
/bin/bash "${scripts_folder}"DataReporting.sh

echo "---------------------------------"