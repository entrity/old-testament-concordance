#!/bin/bash

# Load List of Old Testament Books
IFS=$'\n' read -r -d '' -a OT_BOOKS < ot-books.txt
>&2 echo "OT_BOOKS=(${#OT_BOOKS[@]})"
# >&2 printf '%s\n' "${OT_BOOKS[@]}"

if [[ $BASH_SOURCE == $0 ]]; then
	set -euo pipefail
fi

# Strong's word number for Hebrew word, e.g. 519
WORD_NO="H${1:-519}"

INTERLINEAR_HEBREW_BIBLE_CSV=OpenHebrewBible-master/007-BHS-8-layer-interlinear/BHSA-8-layer-interlinear.csv
KJV_CSV=kjv.csv
KJV_MAPPED_TO_BHS_CSV=OpenHebrewBible-master/008-BHS-mapping-KJV/KJV-OT-mapped-to-BHS.csv

to_tsv() { csvformat -d , -D $'\t'; }

nix_newlines() { tr -d $'\n'; }

xlate() {
	local book_idx=$(( $1 - 1))
	local chapter=$2
	local verse=$3
	echo -n "${OT_BOOKS[$book_idx]} $chapter:$verse"
}

get_instances_from_hebrew_bible() {
	csvgrep --columns "extendedStrongNumber" --regex "^${WORD_NO}$" --tabs "$INTERLINEAR_HEBREW_BIBLE_CSV" | sed 1d
}

build_header_row() {
	echo -ne "KJV ref,KJV text"
	echo -ne ","
	head -n 1 "$INTERLINEAR_HEBREW_BIBLE_CSV" | csvformat --tabs -D ,
}

get_kjv() {
	local kjv_ref
	kjv_ref=$(xlate "$1" "$2" "$3") # book, chapter, verse
	csvgrep --no-header-row --columns a --regex "^${kjv_ref}$" "$KJV_CSV" \
	| sed -E -e 1d -e 's/\s+/ /g'
}

quick_get_kjv() {
	sed -n "${1}p" "$KJV_MAPPED_TO_BHS_CSV" | csvcut --tabs -c 5 \
	| grep -P "[^〉]+〈${WORD_NO}＝[^〉]+〉" --color=always \
	| sed -E -e 's/〈[^〉]+〉//g'
}

build_data_row() {
	<<<"${csv_line}" grep -oP '〔\d+｜\d+｜\d+｜\d+〕' | sed -E 's/[^0-9]/	/g' | {
		IFS=$'\t' read -r verse_id book chapter verse
		# >&2 echo " ${verse_id}... ${book}... ${chapter}... ${verse}..."
		xlate "${book}" "${chapter}" "${verse}"
		echo -n ','
		quick_get_kjv "$verse_id" | sed -E 's/\t+/ /g' | csvformat --tabs -D ,
	} | nix_newlines
	echo -n ','
	echo "${csv_line}"
}

buld_hebrew_words_regex() {
	get_instances_from_hebrew_bible | csvcut -c 10 | tr $'\n' '|'
}

debug_count() {
	COUNT=$(( COUNT + 1 ))
	{
		echo -en "\033[s"
		echo -n "COUNT $COUNT"
		echo -en "\033[u"
	} >&2
}

build_csv() {
	local outfile="${WORD_NO}.tsv"
	{
		build_header_row
		COUNT=0
		while IFS= read -r csv_line; do
			build_data_row "${csv_line}"
			debug_count
		done < <(get_instances_from_hebrew_bible)
	} | to_tsv > "${outfile}"
	>&2 echo "wrote to ${outfile}"
}

if [[ $BASH_SOURCE == $0 ]]; then
	{
		get_instances_from_hebrew_bible | wc -l | nix_newlines
		echo " instances of word in old testament..."
	} >&2
	# buld_hebrew_words_regex
	build_csv
fi
>&2 echo DONE
