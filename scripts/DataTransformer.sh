#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

# VARIABLES

timestamp='"'$(date "+%Y%m%d-%H%M%S")'"'
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
transformed_data_folder=${script_dir}"/../transformed_data/"
gathered_folder=${script_dir}"/../gathered_files/"
logfile=${script_dir}"/../logs/log.txt"

# FUNCTIONS

: "
function loop_club_data
input:      1: the subfolder that needs to be looped (f.e. 'ClubDesKOM', 'CyclingVlaanderen', ...)
            2: the type of JSON-data that we want to transform (f.e. 'activities' or 'info')
            3: all columns that will be added to the CSV-file
            4: the JSON-keys that we want to keep in the CSV
"
loop_club_data(){
    local subfolder="${1}"
    local type="${2}"
    local header="${3}"
    local keys="${4}"
    local all_files="${gathered_folder}${subfolder}/"

    # get all last json-files with 'tail'
    last_21_files=$(find "${all_files}"*"${type}"*.json | tail -21)
    
    counter=1

    for file in ${last_21_files}
    do
        filename=$( echo "${file}" | rev | cut -d'/' -f1 | rev | cut -d'_' -f1 )"_${type}.csv" 
        timestamp='"'$( echo "${file}" | rev | cut -d'/' -f1 | rev | cut -d'_' -f3 | cut -d. -f1)'"'
        club_transformed_file="${transformed_data_folder}${filename}"

        # Add header if this is the first file.
        if [ "${counter}" -eq "1" ];then
            echo "${header}" > "$club_transformed_file" 2>> "${logfile}"
        fi

        # Extra
        # Break if more than 21 files are included. We only need files from the last seven days. 7 x 3 = 21
        if [ "${counter}" -eq "21" ];then
            break
        fi

        # Activities-file
        # File check + correct type + no error message in file ==> write to csv
        if [ -f "$club_transformed_file" ] && [ "${type}" = "activities" ];then
            if ! grep -q '"message":"error"' "$file" ; then
                jq -r "try .[]? += {datum: ${timestamp}} | .[]? | ${keys} | @csv" \
                    >> "${club_transformed_file}" \
                    <  "${file}" 2>> "${logfile}"
            fi
        fi

        # Info-file
        # File check + correct type + no error message in file ==> write to csv
        if [ -f "$club_transformed_file" ] && [ "${type}" = "info" ];then
            jq -r "try . += {datum: ${timestamp}} | ${keys} | @csv" \
                    >> "${club_transformed_file}" \
                    < "${file}" 2>> "${logfile}"
        fi
        counter=$((counter +1))
    done
}

cd "${script_dir}" || exit

activities_columns="[.athlete.firstname, .athlete.lastname, .name, .distance, .elapsed_time, .moving_time, .sport_type, .total_elevation_gain, .workout_type, .datum]"
activities_headers="firstname,lastname,name,distance,elapsed_time,moving_time,sport_type,total_elevation_gain,workout_type,date"

info_columns="[.name, .member_count, .following_count, .club_type, .datum]"
info_headers="name,member_count,following_count,club_type,date"

for dir in ../gathered_files/*; do
    subfolder_name=$( echo "${dir}" | cut -d/ -f3 ) 2>> "${logfile}"
    loop_club_data "${subfolder_name}"  "activities" "${activities_headers}" "${activities_columns}"
    loop_club_data "${subfolder_name}"  "info" "${info_headers}" "${info_columns}"
done
