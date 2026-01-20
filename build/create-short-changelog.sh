#!/bin/bash
#
# Copies the current version from the changelog to a format that can be displayed on addon download pages

INPUT=changelog.md
if [ ! -f "$INPUT" ]; then
    echo "$INPUT does not exist"
	exit 1
fi



OUTPUT="changelog.short.md"
IFS=''

max_versions=1
versions=0
while read line; do
	if [[ "$line" == "## v"* ]]; then
		((versions=versions+1))
		if [ $versions -gt $max_versions ]; then
			break;
		fi
	fi

    if [ $versions -eq 0 ]; then
        continue;
    fi

	echo "$line";
done <$INPUT >>$OUTPUT

echo "[View Full Changelog](https://github.com/parnic/ice-hud/blob/$(git rev-parse HEAD)/changelog.md)" >> $OUTPUT;

echo "Wrote changelog up to $max_versions version(s) to $OUTPUT";

# `git add`ing this is required to make the packager not exclude it.
echo 
echo git add $OUTPUT
git add $OUTPUT 2> /dev/null

exit 0
