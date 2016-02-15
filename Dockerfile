#
# This docker image is just for development and testing purpose - please do NOT use on production
#

# Pull Base Image
FROM zhicwu/java:8

# Set Maintainer Details
MAINTAINER Zhichun Wu <zhicwu@gmail.com>

# Set Environment Variables
ENV PRESTO_VERSION=0.136
ENV PRESTO_ADMIN_VERSION=1.2
ENV BASE_URL=https://repo1.maven.org/maven2/com/facebook/presto

# Download Presto
RUN apt-get update \
	&& apt-get install -y python python-dev manpages-dev gcc \
	&& wget ${BASE_URL}/presto-server/${PRESTO_VERSION}/presto-server-${PRESTO_VERSION}.tar.gz \
		https://github.com/prestodb/presto-admin/releases/download/${PRESTO_ADMIN_VERSION}/prestoadmin-${PRESTO_ADMIN_VERSION}-online.tar.bz2 \
		${BASE_URL}/presto-cli/${PRESTO_VERSION}/presto-cli-${PRESTO_VERSION}-executable.jar \
		${BASE_URL}/presto-jdbc/${PRESTO_VERSION}/presto-jdbc-${PRESTO_VERSION}.jar \
		${BASE_URL}/presto-verifier/${PRESTO_VERSION}/presto-verifier-${PRESTO_VERSION}-executable.jar \
		${BASE_URL}/presto-benchmark-driver/${PRESTO_VERSION}/presto-benchmark-driver-${PRESTO_VERSION}-executable.jar \
	&& rm -rf /var/lib/apt/lists/*

# Install Presto
RUN chmod +x presto-*executable.jar \
	&& tar zxvf presto-server-${PRESTO_VERSION}.tar.gz \
	&& tar xvfj prestoadmin-${PRESTO_ADMIN_VERSION}-online.tar.bz2 \
	&& rm -f *.tar.* \
	&& ln -s presto-server-${PRESTO_VERSION} presto \
	&& mv *.jar presto/. \
	&& cd presto \
	&& ln -s presto-cli-${PRESTO_VERSION}-executable.jar presto \
	&& ln -s presto-verifier-${PRESTO_VERSION}-executable.jar verifier \
	&& ln -s presto-benchmark-driver-${PRESTO_VERSION}-executable.jar benchmark-driver \
	&& cd ../prestoadmin \
	&& ./install-prestoadmin.sh \
	&& cd ..

VOLUME ["/presto/etc", "/presto/data"]

EXPOSE 8080

ENTRYPOINT ["/presto/bin/launcher", "run"]
