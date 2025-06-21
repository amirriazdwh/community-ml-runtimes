#!/bin/bash
set -e

echo "🛠 Installing core system dependencies..."

apt-get update && \
apt-get install -y --no-install-recommends \
  tzdata locales sudo \
  build-essential gcc g++ gfortran make \
  wget ca-certificates gdebi-core psmisc procps \
  file git less nano \
  libssl-dev libcurl4-openssl-dev libxml2-dev \
  libfontconfig1-dev libharfbuzz-dev libfribidi-dev \
  libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev \
  libicu-dev zlib1g-dev libbz2-dev liblzma-dev \
  libpcre2-dev libreadline-dev libxt-dev libcairo2-dev \
  libopenblas-dev liblapack-dev libarpack2-dev libsuitesparse-dev \
  libsasl2-modules-gssapi-mit krb5-user \
  libclang-dev lsb-release

# Set timezone and locale
ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

# Clean up
apt-get clean
rm -rf /var/lib/apt/lists/*
