FROM curity.azurecr.io/curity/idsvr:7.2.0

# For the purposes of this code example we install the curl tool
# This enables HTTP calls during post commit scripts
USER root
RUN apt-get update
RUN apt-get install curl -y
USER idsvr
