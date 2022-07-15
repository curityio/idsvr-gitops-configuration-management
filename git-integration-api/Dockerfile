FROM azul/zulu-openjdk-alpine:11.0.14-jre

WORKDIR /usr/api
COPY build/libs/api-0.0.1-SNAPSHOT-all.jar /usr/api/

RUN addgroup -g 1001 apigroup
RUN adduser -u 1001 -G apigroup -h /home/apiuser -D apiuser
USER apiuser
CMD ["java", "-jar", "/usr/api/api-0.0.1-SNAPSHOT-all.jar"]