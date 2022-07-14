FROM node:16.15.0-alpine

WORKDIR /usr/api
COPY git-integration-api/index.js /usr/api/

RUN addgroup -g 1001 apigroup
RUN adduser -u 1001 -G apigroup -h /home/apiuser -D apiuser
USER apiuser
CMD ["node", "index.js"]