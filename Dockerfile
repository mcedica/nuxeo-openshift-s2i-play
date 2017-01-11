# vim:set ft=dockerfile:
FROM       openjdk:8-jdk
MAINTAINER Nuxeo <packagers@nuxeo.com>

# Create Nuxeo user
ENV NUXEO_USER 1001
ENV NUXEOUSER nuxeo
RUN useradd -m -d /home/$NUXEOUSER -s /bin/bash $NUXEO_USER



# Set the labels that are used for OpenShift to describe the builder image.
LABEL io.k8s.description="Nuxeo Webserver" \
    io.k8s.display-name="Nuxeo 8.10" \
    io.openshift.expose-services="8080:http" \
    io.openshift.tags="builder,webserver,nuxeo" \
    # this label tells s2i where to find its mandatory scripts
    # (run, assemble, save-artifacts)
io.openshift.s2i.scripts-url="image:///usr/libexec/s2i"




# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true


ENV NUXEO_VERSION 8.10
ENV NUXEO_MD5 29e67a19bba54099093b51d892926be1
ENV NUXEO_HOME /opt/nuxeo/server

# Add distribution
RUN curl -fsSL "http://cdn.nuxeo.com/nuxeo-${NUXEO_VERSION}/nuxeo-server-${NUXEO_VERSION}-tomcat.zip" -o /tmp/nuxeo-distribution-tomcat.zip \
    && echo "$NUXEO_MD5 /tmp/nuxeo-distribution-tomcat.zip" | md5sum -c - \
    && mkdir -p /tmp/nuxeo-distribution $(dirname $NUXEO_HOME) \
    && unzip -q -d /tmp/nuxeo-distribution /tmp/nuxeo-distribution-tomcat.zip \
    && DISTDIR=$(/bin/ls /tmp/nuxeo-distribution | head -n 1) \
    && mv /tmp/nuxeo-distribution/$DISTDIR $NUXEO_HOME \
    && sed -i -e "s/^org.nuxeo.distribution.package.*/org.nuxeo.distribution.package=docker/" $NUXEO_HOME/templates/common/config/distribution.properties \
    && rm -rf /tmp/nuxeo-distribution* \
    && chmod +x $NUXEO_HOME/bin/*ctl $NUXEO_HOME/bin/*.sh


ENV PATH $NUXEO_HOME/bin:$PATH

WORKDIR $NUXEO_HOME

EXPOSE 8080
EXPOSE 8787

COPY ["run", "assemble", "save-artifacts", "usage",  "/usr/libexec/s2i/"]
CMD ["/usr/libexec/s2i/usage"]
