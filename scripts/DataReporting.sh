#!/bin/bash

timestamp=$(date "+%Y-%m-%d")
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# VARIABLES
: '
Onder Scripts:
'
markdown_folder="${script_dir}/../reporting_document/markdown"
pdf_folder="${script_dir}/../reporting_document/reports/pdf"
graph_folder="${script_dir}/../reporting_document/graphs"

: '
Markdown folders
'
output_md_file="${markdown_folder}/daily_report.md"
weekly_output_md_file="${markdown_folder}/weekly_report.md"
slides_md_file="${markdown_folder}/slides.md"
fillertext_path="${markdown_folder}/fillertext.txt"

: '
PDF folders
'
output_daily_pdf_file="${pdf_folder}/report-${timestamp}.pdf"
output_weekly_pdf_file="${pdf_folder}/weekly-report-${timestamp}.pdf"

: '
Slides folders
'
output_html_slides="${script_dir}/../reporting_document/slides.html"


: '
Graph folders
'
daily_graphs="${graph_folder}/daily/*.png"
weekly_graphs="${graph_folder}/weekly/*.png"

: '
Logfiles
'
logfile=${script_dir}"/../logs/log.txt"


# FUNCTIONS

: '
function create_fillertext
input   -- none
output  -- creates file with randomly generated lorem ipsum paragraphs
'
create_fillertext(){
    curl -sL "http://metaphorpsum.com/paragraphs/2/4" 2>> "${logfile}"
}

if [ ! -f "${fillertext_path}" ];then
    create_fillertext
fi

: "
function create_header
input   -- 1: title for the header (f.e. 'daily report' or 'weekly report')
        -- 2: filename for the markdown file
output  -- creates a new markdown file with only a latex header
"
create_header(){
    title=${1}
    outputfile=${2}
    echo "---
title: ${title}
author: Dylan Cluyse
layout: default
documentclass: extarticle
mainfont: Montserrat-Regular.ttf
titlefont: Montserrat-Black.ttf
fontsize: 10pt
toc: true
---" > "${outputfile}";
}

: '
CREATE HEADERS FOR MARKDOWNS
'
{
    create_header "DAILY REPORT ${timestamp}" "${output_md_file}";
    if [[ $(date +%u) -gt 6 ]]; then # only on sunday
        create_header "WEEKLY REPORT ${timestamp}" "${weekly_output_md_file}";
    fi
} 2>> "${logfile}"

: "
function create_markdown
input   -- 1: filename for the markdown file
        -- 2: folder for the graphs
        -- 3: type of graph: daily or weekly graph?

output  -- appends the full content to the header in the markdown file
        -- each graph in the daily/weekly graph folder will be looped by; a markdown image tag gets appended to the file
        -- 
"
create_markdown(){
    local output="${1}"
    local graph_folder="${2}"
    local type="${3}"

    echo "## 1. Graphs
    " >> "${output}" 2>> "${logfile}"
    for file in ${graph_folder}
    do
        file_route=$( echo "$file" | rev | cut -d/ -f1 | rev )
        graph_name=$( echo "$file_route" | cut -d. -f1 | cut -d_ -f1 )
        {
            echo && echo "![${graph_name}]($script_dir/../reporting_document/graphs/${type}/${file_route})" && echo
            echo && create_fillertext && echo
        } >> "${output}" 2>> "${logfile}"
    done

    {
        echo && echo "## 2. Bevindingen" && echo && create_fillertext && echo;
    } >> "${output}" 2>> "${logfile}"
}

create_landslides_html(){
    local markdown=${1}
    local html_file=${2}
    
    landslide "${markdown}" -d "${html_file}" --relative >> "${logfile}"
    
    sed -i '/media="print"/c\<link rel="stylesheet" media="print" href="css/print.css">' "${html_file}"
    sed -i '/media="screen, projection"/c\<link rel="stylesheet" media="screen, projection" href="css/screen.css">' "${html_file}"
    sed -i '/javascript/c\<script type="text/javascript" src="js/slides.js"></script>' "${html_file}"
}


: "
function create_slides
input   -- none

output  -- appends the full content to the header in the markdown file
        -- each graph in the weekly graph folder will be looped by; a markdown image tag gets appended to the file
"
create_slides_markdown(){
    echo "# ${timestamp}" > "${slides_md_file}"
    for file in ${weekly_graphs}
    do
        file_route=$( echo "$file" | rev | cut -d/ -f1 | rev )
        graph_name=$( echo "$file_route" | cut -d. -f1 | tr '_' ' ')
        {
            echo && echo "-----------" && echo 
            echo && echo "# ${graph_name} " && echo
            echo "![${graph_name}](graphs/weekly/${file_route})"
        } >> "${slides_md_file}" 2>> "${logfile}"
    done
}

: "
function create_report
input:      -- 1: markdown file
            -- 2: pdf-file

output:     -- generates a PDF based on a markdown file using Pandoc
"
create_pandoc_report(){
    local input="${1}"
    local output="${2}"
    cd "${markdown_folder}" || return
    pandoc "${input}" -o "${output}" --pdf-engine=xelatex 2>> "${logfile}"
}


# Generate PDF files
create_markdown "${output_md_file}" "${daily_graphs}" "daily" # daily
create_pandoc_report "daily_report.md" "${output_daily_pdf_file}"

# Generate slides with Landslide
create_slides_markdown && create_landslides_html "${slides_md_file}" "${output_html_slides}"

# On Sundays, generate weekly reports
if [[ $(date +%u) -gt 6 ]]; then # only on sunday
    create_markdown "${weekly_output_md_file}" "${weekly_graphs}" "weekly" # weekly
    create_pandoc_report "weekly_report.md" "${output_weekly_pdf_file}"
fi