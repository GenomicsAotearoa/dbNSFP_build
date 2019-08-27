# Start from a default Debian distro
FROM debian 

# Update and install packages:
# - wget/aria2c - file downloading
# - tabix - indexing the output for remote querying
# - samtools - for manipuating database 
# - unzip - decompression of DB
RUN apt-get update && \
	apt-get install -y wget aria2c tabix samtools unzip

# Put shell script inside container
RUN mkdir /opt/scripts
# Copy shell script into container
COPY dbNSFP_pipeline_build.sh /opt/scripts/

# Work in /data directory 
WORKDIR /data

# Run pipeline build script by default
ENTRYPOINT /opt/scripts/dbNSFP_pipeline_build.sh
