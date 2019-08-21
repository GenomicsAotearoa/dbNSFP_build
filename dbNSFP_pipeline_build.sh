#!/bin/bash
## small bash script to download and reformat dbNSFP for pipeline 
## Miles Benton
## created: 2018-01-13
## modified: 2019-08-21

# Set to dbNSFP version to download and build
version="4.0a"
#TODO: add an option to 'scrape' this from the url to always return latest version
# define thread number for parallel processing where able
THREADS=6

# Download dbNSFP database
wget -O dbNSFP${version}.zip "ftp://dbnsfp:dbnsfp@dbnsfp.softgenetics.com/dbNSFP${version}.zip"

# Uncompress
unzip dbNSFP${version}.zip

# grab header
zcat dbNSFP${version}_variant.chr1.gz | head -n 1 | bgzip > header.gz

### this section will produce data for hg38 capable pipelines
## hg38 version

# Create a single file version
# NOTE: bgzip parameter -@ X represents number of threads
cat dbNSFP${version}_variant.chr{1..22}.gz dbNSFP${version}_variant.chrX.gz dbNSFP${version}_variant.chrY.gz dbNSFP${version}_variant.chrM.gz | zgrep -v '#chr' | bgzip -@ ${THREADS} > dbNSFPv${version}_custom.gz
#TODO: there must be a 'nicer' way of ordering the input into the cat (to include the X,Y and M chrs without explicitly stating them)

# add header back into file
cat header.gz dbNSFPv${version}_custom.gz > dbNSFPv${version}_custombuild.gz

# Create tabix index
tabix -s 1 -b 2 -e 2 dbNSFPv${version}_custombuild.gz

# test annotation
# java -jar ~/install/snpEff/SnpSift.jar dbnsfp -v -db /mnt/dbNSFP/hg19/dbNSFPv${version}_custombuild.gz test/chr1_test.vcf > test/chr1_test_anno.vcf
#TODO: provide actual unit test files for testing purposes, i.e. a section of public data with known annotation rates.
#TODO: the above is currently a placeholder but it had it's intended purpose in terms of identifying incorrect genome build. 

# clean up
#TODO: add clean up step to rm all intermediate files after testing confirmed working (i.e. correct annotation 'rates')
#/END hg38
###

### this section will produce data for hg19 capable pipelines
## hg19 version
# for hg19 (coordinate data is located in columns 8 [chr] and 9 [position])
# this takes output from above, filters out any variants with no hg19 coords and then sorts on hg19 chr and position, and then bgzips output
# NOTE: bgzip parameter -@ X represents number of threads
zcat dbNSFPv${version}_custombuild.gz | awk '$8 != "."' | awk 'BEGIN{FS=OFS="\t"} {$1=$8 && $2=$9; NF--}1'| LC_ALL=C sort --parallel=${THREADS} -S 20G -T . -V -k 1,1 -k 2,2 | bgzip -@ ${THREADS} > dbNSFPv${version}.hg19.custombuild.gz
# NOTE: to try and overcome disk space limits giving sort 20Gb of RAM

# Create tabix index
tabix -s 1 -b 2 -e 2 dbNSFPv${version}.hg19.custombuild.gz

# test hg19 annotation
# java -jar ~/install/snpEff/SnpSift.jar dbnsfp -v -db /mnt/dbNSFP/hg19/dbNSFPv${version}.hg19.custombuild.gz test/chr1_test.vcf > test/chr1_test_anno.vcf

# clean up
#TODO: add clean up step to rm all intermediate files after testing confirmed working (i.e. correct annotation 'rates')
#/END hg38
###