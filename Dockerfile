ARG JAVA_VERSION=17
FROM eclipse-temurin:${JAVA_VERSION}-jdk AS jre-build

ARG JAVA_MODULES=java.base,java.logging,java.xml,java.naming,java.sql,java.net.http,java.management,java.security.jgss,java.instrument,jdk.crypto.ec,jdk.unsupported

RUN jlink \
    --add-modules "$JAVA_MODULES" \
    --strip-debug \
    --no-man-pages \
    --no-header-files \
    --compress=2 \
    --output /jre

FROM cgr.dev/chainguard/glibc-dynamic:latest

ENV JAVA_HOME=/opt/java
ENV PATH="$JAVA_HOME/bin:$PATH"
COPY --from=jre-build /jre $JAVA_HOME

USER nonroot
CMD ["java", "-version"]
