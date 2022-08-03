FROM curity.azurecr.io/curity/idsvr:7.2.0

# Copy in multiple parameterized configuration files
RUN rm -rf /opt/idsvr/etc/init/*.xml
COPY resources/config /opt/idsvr/etc/init

# Copy in post commit scripts
COPY idsvr/post-commit-trigger-pull-request.sh /opt/idsvr/usr/bin/post-commit-scripts/

# Tools used in this tutorial
USER root
RUN apt-get update
RUN apt-get install curl -y
USER idsvr
