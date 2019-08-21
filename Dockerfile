FROM debian 


RUN apt-get update && \
	apt-get install -y wget tabix samtools unzip

# Put shell script inside container
RUN mkdir /opt/scripts
COPY dbNSFP_pipeline_build.sh /opt/scripts/

WORKDIR /data

ENTRYPOINT /bin/bash
