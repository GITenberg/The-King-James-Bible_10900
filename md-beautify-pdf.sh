#!/bin/bash
# Simple script to add latex hinting to markdown for fancy PDF generation using pandoc
# Uses the two markdown books output from the adoc-convert-md.sh script to create a latex
# hinted markdown file suitable for conversion to PDF
# Usage: md-beautify-pdf.sh [-p] [-c] TheOldTestament.md TheNewTestament.md

# Process script options
GENERATE_PDF=false
CLEANUP=true
while getopts ":pc" opt; do
  case ${opt} in
    p ) # Generate PDF with pandoc
			GENERATE_PDF=true
      ;;
    c ) # Don't cleanup all generated files (default is true)
			CLEANUP=false
      ;;
    \? ) echo "Usage: md-beautify-pdf.sh [-p] [-c] TheOldTestament.md TheNewTestament.md"
      ;;
  esac
done

# Source markdown files
shift $(( OPTIND - 1 ))
oldtestament=$1
newtestament=$2

# Intermediate markdown with Latex formatting
bible=TheKingJamesBible.md

# Add Old/New Testament parts
echo -e '\\tableofcontents\n\n\\part{The Old Testament}\n' >> ${oldtestament}.$$ 
echo -e '\\part{The New Testament}\n' >> ${newtestament}.$$ 
echo -e '\\addtocontents{toc}{\\protect\\mbox{}\\protect\\hrulefill\\par}\n\\addtocontents{toc}{\\protect\\begin{multicols}{2}}\n' | tee -a ${oldtestament}.$$ ${newtestament}.$$ >/dev/null

# Add content
cat $oldtestament >> ${oldtestament}.$$
cat $newtestament >> ${newtestament}.$$

# Close part columns
echo -e '\\End{multicols}\n\\addtocontents{toc}{\\protect\\end{multicols}}' | tee -a ${oldtestament}.$$ ${newtestament}.$$ >/dev/null

# Merge parts
cat ${oldtestament}.$$ ${newtestament}.$$ > $bible

# Add "inner" column definition
perl -i -p0e 's/(^\p{PosixPrint}+\v={2,}\v\s+?)/\1\\Begin\{multicols\}\{2\}\n\n/gms' $bible
perl -i -p0e 's/(^\p{PosixPrint}+\v={2,}\v\s+?)/\\End\{multicols\}\n\n\1/gms' $bible

# Nuke stray multicol tag, this is hacky but I gave up on the lookbehind regex :)
perl -i -p0e 's/(\}\s+)\\End\{multicols\}/\1/gms' $bible

# Add "lettrine" drop caps to first word of first paragraph in each chapter
perl -i -pe 's/^\d+:1\s+(\w)(\w*)\b/`\\lettrine\{\1\}\{\2\}`\{=latex\}/g' $bible

# Adjust chapter headings
perl -i -p0e 's/^(\p{PosixPrint}+)\v={2,}/\\chapter\{\1\}/gms' $bible

# Adjust section headings
perl -i -p0e 's/^(\p{PosixPrint}+)\s(Chapter\s\d+)\v\-{2,}/\\section\{\\uppercase\{\2\}\}\\label\{\1 \2\}/gms' $bible

# Generate PDF
# Note the use of the lualatex engine for PDF generation. The xelatex engine
# encounters memory issues due to the massive size of the book.
if [ "$GENERATE_PDF" = true ]; then
  pandoc -s TheKingJamesBible.md md-metadata-pdf.yaml --pdf-engine=lualatex -o TheKingJamesBible.pdf
fi

## Clean up
if [ "$CLEANUP" == true ]; then
	rm ${oldtestament}.$$ ${newtestament}.$$ TheKingJamesBible.md 
fi
