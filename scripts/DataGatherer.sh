#!/bin/bash
set -o nounset
set -o pipefail
set -o errexit

# VARIABLES
: '
GENERAL INFORMATION
'
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
timestamp=$(date "+%Y%m%d-%H%M%S")

: '
Folders
'
gathered_folder=${script_dir}"/../gathered_files/"
logfolder=${script_dir}"/../logs/"
sourcefile=${script_dir}"/../source/clubs.csv"
amount_of_posts=50

: '
Personal Strava Info
'
client_id="95575"
client_secret="09cd19c6ea0ab4fb9dacdab6517b0205b839e9ef"
grant_type="refresh_token"
refresh_token="77a4a9f6dcd29d88e5b06c69538adcd14985126a"

: '
Logfile
'
logfile=${logfolder}"log.txt"


: '
REQUIREMENTS FOR ACCESS TOKEN
'
url_get_access_token="https://www.strava.com/api/v3/oauth/token"

# FUNCTIONS
: '
input  -- none
output -- prints out access token
'
get_access_token(){
    curl -sL -X POST ${url_get_access_token} -d client_id=${client_id} \
                -d client_secret=${client_secret} -d grant_type=${grant_type} \
                -d refresh_token=${refresh_token} | jq -r ".access_token" 2>> "${logfile}"
}

access_token="$(get_access_token)"

: "
input   -- 1: unique club-id
        -- 2: amount of activities that need to be obtained

output  -- gathers the past n amount of activities and saves the contents in a read-only JSON-file
"
get_strava_club_data(){
    : ' 
    Info necessary to access the API
    '
    local club_id=${1}
    local amount=${2}
    url_get_club_info="https://www.strava.com/api/v3/clubs/${club_id}"
    url_get_club_activities="https://www.strava.com/api/v3/clubs/${club_id}/activities?page=1&per_page=${amount}"

    : '
    Files
    '
    local clubname=${3}
    club_info_filename="${clubname}_info_${timestamp}.json"
    club_activities_filename="${clubname}_activities_${timestamp}.json"
    clubfolder="${gathered_folder}${clubname}"

    info_file="${clubfolder}"'/'"${club_info_filename}"
    activities_file="${clubfolder}"'/'"${club_activities_filename}"


    : '
    Make new folder if the entry is new.
    '
    if [ ! -d "${clubfolder}" ];then
        mkdir "${clubfolder}" 2>> "${logfile}"
    fi

    {
    curl -s -o "${info_file}" -G "${url_get_club_info}" \
        -H "Authorization: Bearer ${access_token}" &&  chmod 444 "${info_file}";

    curl -s -o "${activities_file}" -G "${url_get_club_activities}" \
        -H "Authorization: Bearer ${access_token}" && chmod 444 "${activities_file}";
        
        } 2>> "${logfile}"
}

: '
IN CASE OF CSV --> loop through CSV-file
IN CASE OF NO CSV --> use the four pre-existing clubs
'
if [ ! -f "${sourcefile}" ]; then
    get_strava_club_data 212657 20 "CyclingVlaanderen"
    get_strava_club_data 289082 20 "ClubDesKom"
    get_strava_club_data 23199 20 "WahooUS"
    get_strava_club_data 535487 20 "WahooJapan"
else
    while IFS=, read -r id name; do
    get_strava_club_data "${id}" "${amount_of_posts}" "$( echo "${name}" | tr -d '"')"
    done < "${sourcefile}" 2>> "${logfile}"
fi