#!/bin/bash

if [ -z $1 ]
then
    echo -e "\033[1;31m ERROR: this script requires a repository name parameter. \033[0m"
    exit $E_MISSING_POS_PARAM
fi

if [ -z $2 ]
then
    echo -e "\033[1;31m ERROR: this script requires a target name parameter. \033[0m"
    exit $E_MISSING_POS_PARAM
fi

echo "▸ Adding redirect from the docc static archive root"

output_path="docs"

sed -e "s/__SLUG__/${1}/g" \
    -e "s/__TARGET__/${2}/g" \
    "scripts/docc-files/index.html.template" > ${output_path}/index.html

echo "▸ Rewrote ${output_path}/index.html to:"

cat ${output_path}/index.html

echo "▸ Copy theme settings to static archive"

cp scripts/docc-files/theme-settings.json docs
