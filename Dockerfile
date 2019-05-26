FROM jenkins/jenkins:lts

MAINTAINER Shalabh Jaiswal

USER root

# install maven
ARG MAVEN_VERSION=3.6.1
ARG USER_HOME_DIR="/root"
ARG SHA="2528c35a99c30f8940cc599ba15d34359d58bec57af58c1075519b8cd33b69e7"
ARG BASE_URL=http://mirror.reverse.net/pub/apache/maven/maven-3/${MAVEN_VERSION}/binaries

RUN mkdir -p /maven /maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-$MAVEN_VERSION-bin.tar.gz \
  && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha256sum -c - \
  && tar -xzf /tmp/apache-maven.tar.gz -C /maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

#COPY mvn-entrypoint.sh /usr/local/bin/mvn-entrypoint.sh
#COPY settings-docker.xml /maven/ref/

VOLUME "$USER_HOME_DIR/.m2"

# install Gradle
ENV GRADLE_HOME /gradle
ENV GRADLE_VERSION 5.2.1

ARG GRADLE_DOWNLOAD_SHA256=748c33ff8d216736723be4037085b8dc342c6a0f309081acf682c9803e407357
RUN set -o errexit -o nounset \
	&& echo "Downloading Gradle" \
	&& wget --no-verbose --output-document=gradle.zip "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
	\
	&& echo "Checking download hash" \
	&& echo "${GRADLE_DOWNLOAD_SHA256} *gradle.zip" | sha256sum --check - \
	\
	&& echo "Installing Gradle" \
	&& unzip gradle.zip \
	&& rm gradle.zip \
	&& mv "gradle-${GRADLE_VERSION}" "${GRADLE_HOME}/" \
	&& ln --symbolic "${GRADLE_HOME}/bin/gradle" /usr/bin/gradle 


RUN set -o errexit -o nounset \
	&& echo "Testing Gradle installation" \
	&& gradle --version

# install Ant
ENV ANT_VERSION=1.10.1
ENV ANT_HOME=/ant

# change to tmp folder
WORKDIR /tmp

# Download and extract apache ant to opt folder
RUN wget --no-check-certificate --no-cookies http://archive.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz \
    && wget --no-check-certificate --no-cookies http://archive.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz.md5 \
    && echo "$(cat apache-ant-${ANT_VERSION}-bin.tar.gz.md5) apache-ant-${ANT_VERSION}-bin.tar.gz" | md5sum -c \
    && tar -zvxf apache-ant-${ANT_VERSION}-bin.tar.gz -C /opt/ \
    && ln -s /opt/apache-ant-${ANT_VERSION} /ant \
    && rm -f apache-ant-${ANT_VERSION}-bin.tar.gz \
    && rm -f apache-ant-${ANT_VERSION}-bin.tar.gz.md5

# add executables to path
RUN update-alternatives --install "/usr/bin/ant" "ant" "/ant/bin/ant" 1 && \
    update-alternatives --set "ant" "/ant/bin/ant" 

USER jenkins
