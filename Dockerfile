FROM lsiobase/ubuntu:xenial

ARG DOCKERIZE_ARCH=amd64
ARG DOCKERIZE_VERSION=v0.6.1
ARG SABNZBD_VERSION
LABEL build_version="Base-image info: Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="namekal"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV HOME="/config" \
PYTHONIOENCODING=utf-8

VOLUME /config /downloads

#install core software/tools
RUN apt update \
    && apt install -y \
 	software-properties-common && \
 add-apt-repository multiverse && \
 apt install -y \
    iputils-ping \
	net-tools \
    jq \
	wget \
	p7zip-full \
	par2-tbb \
    python-pip \
    python2.7 \
    python2.7-pysqlite2 \
	python3 \
    ufw \
    bc \
    tzdata \
    rar \
    unrar \
    zip \
	unzip && \
    ln -sf /usr/bin/python2.7 /usr/bin/python2 && \
    pip install --upgrade pip && \
    pip install --no-cache-dir \
	apprise \
	chardet \
    requests \
    setuptools \
    six && \
    curl -L https://github.com/jwilder/dockerize/releases/download/${DOCKERIZE_VERSION}/dockerize-linux-${DOCKERIZE_ARCH}-${DOCKERIZE_VERSION}.tar.gz | tar -C /usr/local/bin -xzv \
    && apt-get clean \
    && rm -rf \
	    /tmp/* \
	    /var/lib/apt/lists/* \
	    /var/tmp/*

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
 apt update && \
 apt install -y \
	python-sabyenc \
	${SABNZBD} && \
    pip install --no-cache-dir \
	pynzb \
	sabyenc \
	pynzbget && \
 echo "USER=root\nHOST=0.0.0.0\nPORT=8081\nCONFIG=/config/sabnzbd-home\n" > /etc/default/sabnzbdplus && \
 echo "**** cleanup ****" \
    && apt-get clean \
    && rm -rf \
	    /tmp/* \
	    /var/lib/apt/lists/* \
	    /var/tmp/*



# Install Transmission
RUN add-apt-repository ppa:transmissionbt/ppa \
    && apt update \
    && apt install -y transmission-cli transmission-common transmission-daemon \
    && apt-get clean \
    && rm -rf \
	    /tmp/* \
	    /var/lib/apt/lists/* \
	    /var/tmp/*

# Add Transmission extras
RUN apt update \
    && wget https://github.com/Secretmapper/combustion/archive/release.zip \
    && unzip release.zip -d /opt/transmission-ui/ \
    && rm release.zip \
    && mkdir /opt/transmission-ui/transmission-web-control \
    && curl -sL `curl -s https://api.github.com/repos/ronggang/transmission-web-control/releases/latest | jq --raw-output '.tarball_url'` | tar -C /opt/transmission-ui/transmission-web-control/ --strip-components=2 -xz \
    && ln -s /usr/share/transmission/web/style /opt/transmission-ui/transmission-web-control \
    && ln -s /usr/share/transmission/web/images /opt/transmission-ui/transmission-web-control \
    && ln -s /usr/share/transmission/web/javascript /opt/transmission-ui/transmission-web-control \
    && ln -s /usr/share/transmission/web/index.html /opt/transmission-ui/transmission-web-control/index.original.html \
    && git clone git://github.com/endor/kettu.git /opt/transmission-ui/kettu \
    && apt-get clean \
    && rm -rf \
	    /tmp/* \
	    /var/lib/apt/lists/* \
	    /var/tmp/*

# Install Openvpn & Tinyproxy
RUN apt update \
    && wget -O - https://swupdate.openvpn.net/repos/repo-public.gpg | apt-key add - \
    && echo "deb http://build.openvpn.net/debian/openvpn/stable xenial main" > /etc/apt/sources.list.d/openvpn-aptrepo.list \
    && apt install -y openvpn tinyproxy telnet \
    && apt-get clean \
    && rm -rf \
	    /tmp/* \
	    /var/lib/apt/lists/* \
	    /var/tmp/*

ADD openvpn/ /etc/openvpn/
ADD transmission/ /etc/transmission/
ADD tinyproxy /opt/tinyproxy/
ADD scripts /etc/scripts/

ENV OPENVPN_USERNAME=**None** \
    OPENVPN_PASSWORD=**None** \
    OPENVPN_PROVIDER=**None** \
    GLOBAL_APPLY_PERMISSIONS=true 

HEALTHCHECK --interval=5m CMD /scripts/healthcheck.sh

# Expose port and run
EXPOSE 9091 51413 8888
