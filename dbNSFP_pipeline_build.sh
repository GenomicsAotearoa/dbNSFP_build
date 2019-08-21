#!/bin/bash
## small bash script to download and reformat dbNSFP for pipeline 
## Miles Benton
## created: 2018-01-13
## modified: 2019-08-21

# Set to dbNSFP version to download and build
version="4.0a"
MD5SUM=d64479862d5c69cdaad80f077a4ad791
#TODO: check MD5 Sum before proceeding
#TODO: add an option to 'scrape' this from the url to always return latest version

# define thread number for parallel processing where able
THREADS=$(cat /proc/cpuinfo |grep processor | wc -l) # Note: autodetect threads
WORKINGDIR="/data/"

# Check that working directory exists 
if [ -d ${WORKINGDIR} ] ; then 
	echo "Found outdir...we're going to need a lot of free space, does it have more than 50GB free?"
else
	echo "Please create ${WORKINGDIR} before continuing" 
	exit 
fi


download() { 
	
	# Download dbNSFP database using aria2c with 5 connections 
	aria2c -o dbNSFP${version}.zip -x 5 "ftp://dbnsfp:dbnsfp@dbnsfp.softgenetics.com/dbNSFP${version}.zip"

}

do_prep() {

	decompress
	extract_header
	custom_build_hg38
	custom_build_hg19

}

decompress() { 

echo "Uncompressing...."
# Uncompress
unzip -n dbNSFP${version}.zip
# Note: skip existing so it runs fast if re-run
}

extract_header() { 
# grab header
echo "Extracting header..."
zcat dbNSFP${version}_variant.chr1.gz | head -n 1 | bgzip > header.gz

}

custom_build_hg38() {

echo "Building hg38 version..."
### this section will produce data for hg38 capable pipelines
## hg38 version

# Create a single file version
# NOTE: bgzip parameter -@ X represents number of threads
cat dbNSFP${version}_variant.*.gz | zgrep -v '#chr' | bgzip -@ ${THREADS} > dbNSFPv${version}_custom.gz

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
}

custom_build_hg19() {
### this section will produce data for hg19 capable pipelines
## hg19 version
# for hg19 (coordinate data is located in columns 8 [chr] and 9 [position])
# this takes output from above, filters out any variants with no hg19 coords and then sorts on hg19 chr and position, and then bgzips output
# NOTE: bgzip parameter -@ X represents number of threads
zcat dbNSFPv${version}_custombuild.gz | \
  awk '$8 != "."' | \
  awk 'BEGIN{FS=OFS="\t"} {$1=$8 && $2=$9; NF--}1'| \
  LC_ALL=C sort --parallel=${THREADS} -n -S 20G -T . -k 1,1 -k 2,2 --compress-program=gzip | \
  bgzip -@ ${THREADS} > dbNSFPv${version}.hg19.custombuild.gz
# NOTE: removed target memory allocation  

# Create tabix index
tabix -s 1 -b 2 -e 2 dbNSFPv${version}.hg19.custombuild.gz
}


if [ -f ${WORKINGDIR}/dbNSFP${version}.zip ] ; then
	echo "Found file, extracting..." 	
	cd ${WORKINGDIR}
	do_prep
	
else
	echo "Didn't find file, downloading, this could take awhile"
	cd ${WORKINGDIR}
	download
	do_prep	
fi


# test hg19 annotation
# java -jar ~/install/snpEff/SnpSift.jar dbnsfp -v -db /mnt/dbNSFP/hg19/dbNSFPv${version}.hg19.custombuild.gz test/chr1_test.vcf > test/chr1_test_anno.vcf

# clean up
#TODO: add clean up step to rm all intermediate files after testing confirmed working (i.e. correct annotation 'rates')
#/END hg38
###
