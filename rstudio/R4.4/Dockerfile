FROM docker.repository.cloudera.com/cloudera/cdsw/ml-runtime-workbench-r4.4-standard:2024.05.2-b14

# --- Add missing repositories to support libssl3, libclang-14-dev ---
RUN sed -i 's/^deb http:\/\/archive.ubuntu.com\/ubuntu\/ jammy main$/deb http:\/\/archive.ubuntu.com\/ubuntu\/ jammy main universe/' /etc/apt/sources.list && \
    echo "deb http://security.ubuntu.com/ubuntu jammy-security main universe" >> /etc/apt/sources.list && \
    echo "deb http://archive.ubuntu.com/ubuntu jammy-updates main universe" >> /etc/apt/sources.list && \
    apt-get update

# --- Install system dependencies required for RStudio and Electron runtime ---
RUN apt-get install -y --no-install-recommends \
    software-properties-common \
    dirmngr \
    gnupg \
    curl \
    wget \
    gdebi-core \
    sudo \
    psmisc \
    libssl3 \
    libapparmor1 \
    libclang-14-dev \
    make \
    libnss3 \
    libxss1 \
    libasound2 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libgtk-3-0 \
    libu2f-udev \
    libgbm1 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Install RStudio Server (Ubuntu 22.04-compatible) ---
RUN wget https://download2.rstudio.org/server/jammy/amd64/rstudio-server-2025.05.1-513-amd64.deb && \
    gdebi -n rstudio-server-2025.05.1-513-amd64.deb && \
    rm rstudio-server-2025.05.1-513-amd64.deb

# --- Ensure cdsw user exists ---
RUN id cdsw || useradd -m cdsw

# --- Setup RStudio configuration for CML ---
COPY rserver.conf /etc/rstudio/rserver.conf
COPY rstudio-cml /usr/local/bin/rstudio-cml
RUN chmod +x /usr/local/bin/rstudio-cml

# --- CML expects this symlink for launching custom editor ---
RUN ln -s /usr/local/bin/rstudio-cml /usr/local/bin/ml-runtime-editor

# --- Allow R to inherit CML environment vars (optional but recommended) ---
RUN install -d -m 755 /etc/R && \
    install -m 666 /dev/null /etc/R/Renviron.site

# --- Set runtime permissions for cdsw user ---
RUN chown -R cdsw:cdsw /var/lib/rstudio-server && chmod -R 777 /var/lib/rstudio-server

# --- Writable paths for CML runtime startup ---
RUN for i in /etc /var /etc/alternatives /var/lib/dpkg/ /home /runtime-addons; do \
 if [ -d ${i} ]; then chmod 777 ${i}; fi; \
 done

RUN for i in /bin /var /etc /opt /sbin /usr /home /runtime-addons; do \
 if [ -d ${i} ]; then \
   chown cdsw ${i}; \
   find ${i} -type d -exec chown cdsw {} +; \
 fi; \
 done

# --- CML Runtime Metadata for UI ---
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
