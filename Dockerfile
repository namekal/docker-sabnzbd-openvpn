FROM lsiobase/ubuntu:xenial

# set version label
ARG BUILD_DATE
ARG VERSION
ARG SABNZBD_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="namekal"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV HOME="/config" \
PYTHONIOENCODING=utf-8

VOLUME /config /downloads /incomplete-downloads /data

RUN \
 echo "***** add sabnzbd repositories ****" && \
 apt-key adv --keyserver hkp://keyserver.ubuntu.com:11371 --recv-keys 0x98703123E0F52B2BE16D586EF13930B14BB9F05F && \
 echo "deb http://ppa.launchpad.net/jcfp/nobetas/ubuntu xenial main" >> /etc/apt/sources.list.d/sabnzbd.list && \
 echo "deb-src http://ppa.launchpad.net/jcfp/nobetas/ubuntu xenial main" >> /etc/apt/sources.list.d/sabnzbd.list && \
 echo "deb http://ppa.launchpad.net/jcfp/sab-addons/ubuntu xenial main" >> /etc/apt/sources.list.d/sabnzbd.list && \
 echo "deb-src http://ppa.launchpad.net/jcfp/sab-addons/ubuntu xenial main" >> /etc/apt/sources.list.d/sabnzbd.list && \
 echo "**** install packages ****" && \
 if [ -z ${SABNZBD_VERSION+x} ]; then \
	SABNZBD="sabnzbdplus"; \
 else \
	SABNZBD="sabnzbdplus=${SABNZBD_VERSION}"; \
 fi && \
 apt-get update && \
 apt-get install -y \
 	software-properties-common && \
 add-apt-repository multiverse && \
 apt-get update && \
 apt-get install -y \
 	openvpn \
	curl \
	wget \
	p7zip-full \
	par2-tbb \
	python-sabyenc \
    python-pip \
	${SABNZBD} \
	unrar \
	unzip && \
pip install --no-cache-dir \
	apprise \
	chardet \
	pynzb \
	requests \
	sabyenc \
	setuptools \
	pynzbget \
	six && \
 wget https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64.deb && \
 dpkg -i dumb-init*.deb && \
 rm -rf dumb-init*.deb && \
 curl -L https://github.com/jwilder/dockerize/releases/download/v0.6.1/dockerize-linux-amd64-v0.6.1.tar.gz | tar -C /usr/local/bin -xzv && \
 echo "USER=root\nHOST=0.0.0.0\nPORT=8081\nCONFIG=/config/sabnzbd-home\n" > /etc/default/sabnzbdplus && \
 echo "**** cleanup ****" && \
 apt-get clean && \
 rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/* && \
 service sabnzbdplus start

# add local files
COPY root/ /

ADD openvpn/ /etc/openvpn/

# ports and volumes
EXPOSE 8081 9090

CMD ["dumb-init", "/etc/openvpn/start.sh"]
