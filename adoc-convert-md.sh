#!/bin/bash
# Simple script to convert asciidoc format King James Bible into basic markdown format
# These files can subsequently processed by the md-beautify-pdf.sh script to create
# a more traditional looking bible layout PDF (two column, drop caps, headers/footers, etc)
# Usage: adoc-convert-md.sh [-c] book.asciidoc

# Process script options
CLEANUP=true
while getopts ":c" opt; do
  case ${opt} in
    c ) # Don't cleanup all generated files (default is true)
			CLEANUP=false
      ;;
    \? ) echo "Usage: adoc-convert-md.sh [-c] book.asciidoc"
      ;;
  esac
done

# Input file, usually "book.asciidoc"
shift $(( OPTIND - 1 ))
inputfile=$1

# Create temp file
cp $inputfile ${inputfile}.$$

# Strip chapter navigation tables as they get mutiliated by markdown conversion
# TODO: Is there a asciidoc equivalent of 'minitoc'? It would make the original generation of
#       these bible book level navigation tables so much easier.
perl -i -p0e 's/(^== (?!Copyright\v)(\p{PosixPrint}+\v)).*?(^=== \p{PosixPrint}+ Chapter 1\v)/\1\n\n\3/gms' ${inputfile}.$$

# Split into Old and New Testament markdown files as Markdown does not support multiple
# "titles" like asciidoc
perl -ne 'print if (/= The Old Testament/ .. /= The New Testament/)' ${inputfile}.$$ > TheOldTestament.$$
perl -ne 'print if (/= The New Testament/ .. eof)' ${inputfile}.$$ > TheNewTestament.$$

# Strip title level section headings
perl -i -pe 's/(^= \p{PosixPrint}+\v)//g' TheOldTestament.$$ TheNewTestament.$$

# Convert each testament to XML DocBook format
echo "Converting Old Testament to DocBook format"
asciidoc -b docbook -o TheOldTestament.xml.$$ TheOldTestament.$$
echo "Converting New Testament to DocBook format"
asciidoc -b docbook -o TheNewTestament.xml.$$ TheNewTestament.$$

# Do final conversion to Markdown format
# +RTS -K100000000 -RTS increase pandoc stack size to avoid errors
echo "Converting Old Testament to Markdown format"
#pandoc +RTS -K100000000 -RTS -f docbook -t markdown_strict TheOldTestament.xml.$$ TheOldTestament.$$ -o TheOldTestament.md
pandoc +RTS -K100000000 -RTS -f docbook -t markdown_strict TheOldTestament.xml.$$ -o TheOldTestament.md
echo "Converting New Testament to Markdown format"
#pandoc +RTS -K100000000 -RTS -f docbook -t markdown_strict TheNewTestament.xml.$$ TheNewTestament.$$ -o TheNewTestament.md
pandoc +RTS -K100000000 -RTS -f docbook -t markdown_strict TheNewTestament.xml.$$ -o TheNewTestament.md

## TODO
# Convert or parse metadata.yaml to md-metadata-pdf.yaml on the fly

# Clean up
if [ "$CLEANUP" == true ]; then
  rm TheOldTestament.xml.$$ TheOldTestament.$$ TheNewTestament.xml.$$ TheNewTestament.$$ ${inputfile}.$$
fi
