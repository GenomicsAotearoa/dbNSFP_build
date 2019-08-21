# Download and Format dbNSFP 

Making a Docker container for the following workflow: 

https://gist.github.com/sirselim/dcaad07523c90b46c1c0685efbc5d04e

## Usage

The script will look for the zip file `dbNSFP4.0a.zip` and will not download it again if it is already there. You can test this container's further steps by pointing it at a directory already containing `dbNSFP4.0a.zip`. Remember if you make changes to the `Dockerfile` or script, you'll need to rebuild the container.  

```
git clone https://github.com/jduckles/dbNSFP_build
cd dbNSFP_build
INPUTDIR=/data/dbSNFP # Set this to a location with 100GB+ free
docker build -t dbnsfp .
docker run -it -v ${INPUTDIR}:/data dbnsfp

```
