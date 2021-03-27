ARG UNBUTU_NAME=i386/ubuntu
ARG UBUNTU_TAG=bionic-20210325
FROM ${UNBUTU_NAME}:${UBUNTU_TAG} as bionic

# # make sure we're up-to-date
# RUN 	apt-get -y update \
# 	&&	apt-get -y upgrade \
# 	&&	DEBIAN_FRONTEND=noninteractive apt-get -y -m install --fix-missing \
# 			tzdata \
# 	&&  apt-get -y autoremove \
# 	&&	apt-get clean \
# 	&&	rm -rf /var/lib/apt/lists/*

FROM bionic as base
RUN 	apt-get -y update \
	&&	DEBIAN_FRONTEND=noninteractive apt-get -y -m install --fix-missing \
			apt-utils \
			binutils \
			bsdmainutils \
			build-essential \
			ca-certificates \
			chrpath \
			corkscrew \
			cpio \
			curl \
			debianutils \
			diffstat \
			dos2unix \
			g++ \
			gawk \
			gcc \
			gdb \
			gdbserver \
			git \
			git-core \
			iputils-ping \
			java-common \
			lcov \
			libsdl1.2-dev \
			libssl-dev \
			libsystemd-dev \
			locales \
			make \
			makeself \
			nano \
			openjdk-8-jre \
			python \
			python-magic \
			python-pip \
			python-watchdog \
			python3 \
			python3-pexpect \
			python3-pip \
			sed \
			software-properties-common \
			squashfs-tools \
			tar \
			texinfo \
			tzdata \
			unzip \
			uuid \
			vim-common \
			wget \
			xz-utils \
			zip \
			zlib1g \
			zlib1g-dev \
		\
	&&  apt-get -y autoremove \
	&&	apt-get clean \
	&&	rm -rf /var/lib/apt/lists/*

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Boost build sub-image
FROM base as boost_build
ADD https://dl.bintray.com/boostorg/release/1.75.0/source/boost_1_75_0.tar.gz /src/boost.tar.gz
RUN cd /src \
	&& tar -xzf boost.tar.gz \
	&& cd boost_1_75_0 \
	&& ./bootstrap.sh --prefix=/install/boost \
	&& ./b2 install \
	&& cd / \
	&& rm -rf /src	

# CMake build sub-image
FROM base as cmake_build
ADD https://github.com/Kitware/CMake/releases/download/v3.20.0/cmake-3.20.0.tar.gz /src/cmake.tar.gz
RUN cd /src \
	&& tar -xzf cmake.tar.gz \
	&& mkdir -p cmake-3.20.0/build \
	&& cd cmake-3.20.0/build \
	&& ../configure \
	&& make \
	&& DESTDIR=/install/cmake make install \
	&& cd / \
	&& rm -rf /src	

# cmake sub-image
FROM base as cmake
COPY --from=cmake_build /install/cmake /

# GTest build sub-image
FROM cmake as gtest_build
ADD https://github.com/google/googletest/archive/release-1.8.1.tar.gz /src/
ADD files/gtest-01.patch /src/ 
RUN	cd /src \
	&& tar -xzf release-1.8.1.tar.gz \	
	&& mkdir -p /src/googletest-release-1.8.1/build \
	&& cd /src/googletest-release-1.8.1/build \
	&& patch -i /src/gtest-01.patch -d .. \
	&& cmake .. -DCMAKE_INSTALL_PREFIX=/install/gtest \
	&& cmake --build . \
	&& make install \
	&& cd / \
	&& rm -rf /src	

# Main image
FROM cmake
COPY --from=boost_build /install/boost /usr/local/
COPY --from=gtest_build /install/gtest /usr/local/
