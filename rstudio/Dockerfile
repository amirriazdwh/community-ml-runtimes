###########################################################################
#  
#  CLOUDERA COMMUNITY RUNTIMES
#
# (C) Cloudera, Inc. 2024
#  All rights reserved.
#
#  Applicable Open Source License: Apache 2.0
#
#  NOTE: Cloudera open source products are modular software products
#  made up of hundreds of individual components, each of which was
#  individually copyrighted.  Each Cloudera open source product is a
#  collective work under U.S. Copyright Law. Your license to use the
#  collective work is as provided in your written agreement with
#  Cloudera.  Used apart from the collective work, this file is
#  licensed for your use pursuant to the open source license
#  identified above.
#
#  This code is provided to you pursuant a written agreement with
#  (i) Cloudera, Inc. or (ii) a third-party authorized to distribute
#  this code. If you do not have a written agreement with Cloudera nor
#  with an authorized and properly licensed third party, you do not
#  have any rights to access nor to use this code.
#
#  Absent a written agreement with Cloudera, Inc. (“Cloudera”) to the
#  contrary, A) CLOUDERA PROVIDES THIS CODE TO YOU WITHOUT WARRANTIES OF ANY
#  KIND; (B) CLOUDERA DISCLAIMS ANY AND ALL EXPRESS AND IMPLIED
#  WARRANTIES WITH RESPECT TO THIS CODE, INCLUDING BUT NOT LIMITED TO
#  IMPLIED WARRANTIES OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY AND
#  FITNESS FOR A PARTICULAR PURPOSE; (C) CLOUDERA IS NOT LIABLE TO YOU,
#  AND WILL NOT DEFEND, INDEMNIFY, NOR HOLD YOU HARMLESS FOR ANY CLAIMS
#  ARISING FROM OR RELATED TO THE CODE; AND (D)WITH RESPECT TO YOUR EXERCISE
#  OF ANY RIGHTS GRANTED TO YOU FOR THE CODE, CLOUDERA IS NOT LIABLE FOR ANY
#  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, PUNITIVE OR
#  CONSEQUENTIAL DAMAGES INCLUDING, BUT NOT LIMITED TO, DAMAGES
#  RELATED TO LOST REVENUE, LOST PROFITS, LOSS OF INCOME, LOSS OF
#  BUSINESS ADVANTAGE OR UNAVAILABILITY, OR LOSS OR CORRUPTION OF
#  DATA.
#
#
############################################################################
# Start with a Base CML Runtime
# Note: This particular image will use the Python base image, not R as expected. There is a
# complication with CML that prevents editors and applications from launching if the CML
# version of python isn't present. This should be fixed in a future release.
FROM docker.repository.cloudera.com/cloudera/cdsw/ml-runtime-pbj-workbench-r4.3-standard:2024.02.1-b4

# Backup existing /etc/R/Renviron.site if it exists
RUN if [ -f /etc/R/Renviron.site ]; then cp /etc/R/Renviron.site /tmp/Renviron.site.bak; fi

# Remove conflicting R 4.3.x packages to avoid clashes with R 4.4.0
RUN apt-get remove -y r-base-core r-base-dev 2>/dev/null || true

# Updated the images with apt-get
RUN apt-get update && \
    apt-get install -y \
        software-properties-common \
        dirmngr \
        gdebi-core \
        curl \
        wget \
        make \
        lsb-release \
        libssl-dev \
        libcurl4-openssl-dev \
        libxml2-dev \
        build-essential \
        gfortran \
        libreadline-dev \
        libx11-dev \
        libxt-dev \
        libpng-dev \
        libjpeg-dev \
        libcairo2-dev \
        libsqlite3-dev \
        libbz2-dev \
        liblzma-dev \
        libpcre2-dev \
        libtiff5-dev \
        ca-certificates && \
    #  Clean up apt cache to reduce image size
        apt-get autoremove -y && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*

# Setup R Repos can cause conflict with R4.4 therefore removing
# RUN apt-get install -y --no-install-recommends software-properties-common dirmngr gdebi-core
# RUN curl https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc > /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
# RUN add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"

# Build and install R 4.4.0 from source
RUN curl -O https://cran.r-project.org/src/base/R-4/R-4.4.0.tar.gz && \
    tar -xzf R-4.4.0.tar.gz && \
    cd R-4.4.0 && \
    ./configure --enable-R-shlib --with-blas --with-lapack && \
    make -j$(nproc) && \
    make install && \
    cd .. && rm -rf R-4.4.0 R-4.4.0.tar.gz

# Recreate /etc/R if it was wiped
RUN mkdir -p /etc/R

# Step 3: Restore the backup
RUN if [ -f /tmp/Renviron.site.bak ]; then \
        mkdir -p /etc/R && \
        cp /tmp/Renviron.site.bak /etc/R/Renviron.site; \
    fi

# Install psmisc for RStudio Server
RUN apt-get update && apt-get install -y psmisc && apt-get clean

# Install RStudio Server 
RUN wget https://download2.rstudio.org/server/focal/amd64/rstudio-server-2025.05.1-513-amd64.deb && \
    gdebi -n rstudio-server-2025.05.1-513-amd64.deb && \
    rm rstudio-server-2025.05.1-513-amd64.deb

# Configure RStudio to work in CML
# RStudio needs some changes made to the default configuration to work in CML, e.g.
# port and host info. This is set in the two additonal files that are added to the image.
# Tightened permissions (755 instead of 777 for security)

RUN chown -R cdsw:cdsw /var/lib/rstudio-server && chmod -R 755 /var/lib/rstudio-server
COPY rserver.conf /etc/rstudio/rserver.conf
RUN chown root:root /etc/rstudio/rserver.conf && chmod 644 /etc/rstudio/rserver.conf
RUN mkdir -p /etc/R && touch /etc/R/Renviron.site
COPY rstudio-cml /usr/local/bin/rstudio-cml
RUN chmod +x /usr/local/bin/rstudio-cml

# Create a Symlink to the default editor launcher
# This is the main requirement to get CML to launch a different editor. Create a symlink
# from the editors launcher to /usr/local/bin/ml-runtime-editor
RUN ln -s /usr/local/bin/rstudio-cml /usr/local/bin/ml-runtime-editor

#  Replaced RUN export with ENV for persistent PATH
ENV PATH="$PATH:/home/cdsw/R/x86_64-pc-linux-gnu-library/4.4"
USER root

# MLX-50 Allow the engine image to be run as user cdsw upon startup.
# To do this we must 'chmod 777' /etc related directories.
# Safer permissions (755 instead of 777)
RUN for i in /etc /var /etc/alternatives /var/lib/dpkg/ /home /runtime-addons; do \
 if [ -d ${i} ]; then chmod 755 ${i}; fi; \
 done

# DSE-11162 Base engine changes to support runtime addons.
# To do this, we must 'chown cdsw' some directories.
# Make root directory read/writable by cdsw user
RUN chown cdsw /

# Change permissions to allow env variables to be pushed to Renviron.site file
# when the rstudio-cml startup file is run
# RUN chmod -R 666 /etc/R/Renviron.site

# Add permissions to cdsw user recursively to the common directories that gets touched as part
# of the engine startup process.
RUN for i in /bin /var /etc /opt /var/lib/dpkg/ /sbin /usr /home /runtime-addons; do \
 if [ -d ${i} ]; then \
   chown cdsw ${i}; \
   find ${i} -type d -exec chown cdsw {} +; \
 fi; \
 done

 # Disable HTML documentation updates
RUN echo 'options(htmltools.dir.version = FALSE)' >> /usr/local/lib/R/etc/Rprofile.site

# Set the ENV and LABEL details for this  Runtime
# The final requirement is to set various labels and environment variables that CML needs
# to pick up the Runtime's details. Here the editor is to RStudio
ENV ML_RUNTIME_EDITOR="RStudio" \
    ML_RUNTIME_EDITION="RStudio 2025 Community Runtime" \
    ML_RUNTIME_SHORT_VERSION="2025.05" \
    ML_RUNTIME_MAINTENANCE_VERSION="1" \
    ML_RUNTIME_FULL_VERSION="2025.05.1" \
    ML_RUNTIME_DESCRIPTION="RStudio Server 2025.05.1" \
    ML_RUNTIME_KERNEL="R 4.4"

LABEL com.cloudera.ml.runtime.editor=$ML_RUNTIME_EDITOR \
      com.cloudera.ml.runtime.edition=$ML_RUNTIME_EDITION \
      com.cloudera.ml.runtime.full-version=$ML_RUNTIME_FULL_VERSION \
      com.cloudera.ml.runtime.short-version=$ML_RUNTIME_SHORT_VERSION \
      com.cloudera.ml.runtime.maintenance-version=$ML_RUNTIME_MAINTENANCE_VERSION \
      com.cloudera.ml.runtime.description=$ML_RUNTIME_DESCRIPTION \
      com.cloudera.ml.runtime.kernel=$ML_RUNTIME_KERNEL