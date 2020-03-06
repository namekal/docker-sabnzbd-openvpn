FROM lsiobase/ubuntu:xenial

# set version label
#ARG BUILD_DATE
#ARG VERSION
ARG SABNZBD_VERSION
LABEL build_version="Base-image info: Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="namekal"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV HOME="/config" \
PYTHONIOENCODING=utf-8

VOLUME /config /downloads

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
 apt-get install -y \
 	iputils-ping \
	net-tools \
 	openvpn \
	jq \
	wget \
	p7zip-full \
	par2-tbb \
	python-sabyenc \
    python-pip \
	python3 \
	${SABNZBD} \
	unrar \
	unzip && \
pip install --upgrade pip && \
pip install --no-cache-dir \
	apprise \
	chardet \
	pynzb \
	requests \
	sabyenc \
	setuptools \
	pynzbget \
	six && \
 echo "USER=root\nHOST=0.0.0.0\nPORT=8081\nCONFIG=/config/sabnzbd-home\n" > /etc/default/sabnzbdplus && \
 echo "**** cleanup ****" && \
 apt-get clean && \
 rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*

# add local files
COPY root/ /

ADD openvpn/ /etc/openvpn/


HEALTHCHECK --interval=5m CMD /scripts/healthcheck.sh

# ports and volumes
EXPOSE 8081
