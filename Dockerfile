FROM debian:11

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.utf8

RUN set -x \
&& apt-get update \
&& apt-get -y install wget git curl autoconf automake build-essential libass-dev libfreetype6-dev \
  libsdl1.2-dev libtheora-dev libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev \
  libxcb-xfixes0-dev pkg-config texinfo zlib1g-dev \
&& mkdir ~/ffmpeg_sources \
&& apt-get -y install yasm \
&& cd ~/ffmpeg_sources \
&& wget http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz \
&& tar xzvf yasm-1.3.0.tar.gz \
&& cd yasm-1.3.0 \
&& ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" \
&& make -j$(cat /proc/cpuinfo | grep processor | wc -l) \
&& make install \
&& make distclean \
&& apt-get -y install libx264-dev \
&& apt-get -y install cmake mercurial \
&& echo COMPLETED PART 1

RUN set -x \
&& apt-get -y install libnuma-dev && \
cd ~/ffmpeg_sources && \
wget -O x265.tar.bz2 https://bitbucket.org/multicoreware/x265_git/get/master.tar.bz2 && \
tar xjvf x265.tar.bz2 && \
cd multicoreware*/build/linux && \
PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED=off ../../source && \
PATH="$HOME/bin:$PATH" make -j$(cat /proc/cpuinfo | grep processor | wc -l) && \
make install && \
make clean && \
cd ~/ffmpeg_sources \
&& wget -O fdk-aac.tar.gz https://github.com/mstorsjo/fdk-aac/tarball/master \
&& tar xzvf fdk-aac.tar.gz \
&& cd mstorsjo-fdk-aac* \
&& autoreconf -fiv \
&& ./configure --prefix="$HOME/ffmpeg_build" --disable-shared \
&& make -j$(cat /proc/cpuinfo | grep processor | wc -l) \
&& make install \
&& make distclean \
&& echo COMPLETED PART 2

RUN set -x \
&& echo install libmp3lame \
&& apt-get -y install libmp3lame-dev \
&& apt-get -y install libopus-dev \
&& cd ~/ffmpeg_sources \
&& wget https://github.com/webmproject/libvpx/archive/v1.13.0.tar.gz \
&& tar xzvf v1.13.0.tar.gz \
&& cd libvpx-1.13.0 \
&& PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --disable-examples --disable-unit-tests \
&& PATH="$HOME/bin:$PATH" make -j$(cat /proc/cpuinfo | grep processor | wc -l) \
&& make install \
&& make clean

#install ffmpeg
RUN cd ~/ffmpeg_sources \
&& wget http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 \
&& tar xjvf ffmpeg-snapshot.tar.bz2 \
&& cd ffmpeg \
&& PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
  --prefix="$HOME/ffmpeg_build" \
  --enable-gpl \
  --enable-libfdk-aac \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-nonfree \
  --enable-libfreetype \
  --pkg-config-flags="--static" \
  --extra-libs=-static \
  --extra-cflags=--static \
  --extra-cflags="-I$HOME/ffmpeg_build/include" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
  --extra-libs="-lpthread -lm" \
  --bindir="$HOME/bin" \
&& PATH="$HOME/bin:$PATH" make -j$(cat /proc/cpuinfo | grep processor | wc -l) \
&& make install \
&& make distclean \
&& hash -r

CMD bin/bash
