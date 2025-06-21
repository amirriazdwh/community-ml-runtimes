FROM ubuntu:22.04

# Ensure docker_parts exists
RUN [ -d /tmp/docker_parts ] || mkdir -p /tmp/docker_parts

# 01: Environment Variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    CDSW_USER=cdsw \
    CDSW_USER_ID=8536 \
    CDSW_GROUP_ID=8536 \
    R_VERSION=4.5.1 \
    RSTUDIO_VERSION=2025.05.1-513 \
    CRAN=https://cloud.r-project.org/ \
    R_HOME=/usr/local/lib/R \
    R_LIBS_USER=/usr/local/lib/R/site-library \
    R_ENABLE_JIT=3 \
    R_COMPILE_PKGS=1 \
    MALLOC_ARENA_MAX=2 \
    OMP_NUM_THREADS=1 \
    R_MAX_VSIZE=8G \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    PATH=$PATH:/usr/local/lib/R/bin

# 02: System Dependencies
COPY docker_parts/02_system_dependencies.sh /tmp/docker_parts/02_system_dependencies.sh
RUN test -f /tmp/docker_parts/02_system_dependencies.sh && chmod +x /tmp/docker_parts/02_system_dependencies.sh && /tmp/docker_parts/02_system_dependencies.sh

# Python is required by CML runtime engine
RUN apt-get update && apt-get install -y python3 python3-pip && \
    ln -s /usr/bin/python3 /usr/bin/python

# 03: Create cdsw User
COPY docker_parts/03_create_user.sh /tmp/docker_parts/03_create_user.sh
RUN test -f /tmp/docker_parts/03_create_user.sh && chmod +x /tmp/docker_parts/03_create_user.sh && /tmp/docker_parts/03_create_user.sh

# Ensure /home/cdsw exists and is correctly owned
# RUN mkdir -p /home/cdsw && chown -R 8536:8536 /home/cdsw

# 04: Install R from source
COPY docker_parts/04_install_r.sh /tmp/docker_parts/04_install_r.sh
RUN test -f /tmp/docker_parts/04_install_r.sh && chmod +x /tmp/docker_parts/04_install_r.sh && /tmp/docker_parts/04_install_r.sh

# Ensure R shared libraries are discoverable
RUN echo "/usr/local/lib/R/lib" > /etc/ld.so.conf.d/R.conf && ldconfig


# 05: Global R options and memory tuning
COPY docker_parts/05_set_r_memory.sh /tmp/docker_parts/05_set_r_memory.sh
RUN test -f /tmp/docker_parts/05_set_r_memory.sh && mv /tmp/docker_parts/05_set_r_memory.sh /etc/profile.d/set_r_memory.sh && chmod 755 /etc/profile.d/set_r_memory.sh

# 06: Banking packages
# COPY docker_parts/06_banking_packages.sh /tmp/docker_parts/06_banking_packages.sh
# RUN test -f /tmp/docker_parts/06_banking_packages.sh && chmod +x /tmp/docker_parts/06_banking_packages.sh && /tmp/docker_parts/06_banking_packages.sh

# 07: RStudio server installation and configuration
COPY docker_parts/07_rstudio_install.sh /tmp/docker_parts/07_rstudio_install.sh
RUN test -f /tmp/docker_parts/07_rstudio_install.sh && chmod +x /tmp/docker_parts/07_rstudio_install.sh && /tmp/docker_parts/07_rstudio_install.sh

# 08: RStudio rserver.conf configuration
COPY docker_parts/08_rserver.conf /etc/rstudio/rserver.conf

# 09: RStudio startup script
COPY docker_parts/09_start_rstudio.sh /usr/local/bin/start_rstudio.sh
RUN test -f /usr/local/bin/start_rstudio.sh && chmod +x /usr/local/bin/start_rstudio.sh

# CML expects ml-runtime-editor entrypoint for launching RStudio
RUN ln -s /usr/local/bin/start_rstudio.sh /usr/local/bin/ml-runtime-editor


# Final cleanup to reduce image size
RUN rm -rf /tmp/docker_parts \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*


ENV ML_RUNTIME_METADATA_VERSION=2 \
    ML_RUNTIME_EDITOR="RStudio" \
    ML_RUNTIME_EDITION="Standard" \
    ML_RUNTIME_DESCRIPTION="RStudio Server 2025.05.1 Runtime" \
    ML_RUNTIME_KERNEL="R 4.5" \
    ML_RUNTIME_FULL_VERSION=2025.06.1 \
    ML_RUNTIME_SHORT_VERSION=2025.06 \
    ML_RUNTIME_MAINTENANCE_VERSION=1 \
    ML_RUNTIME_GIT_HASH=custom-rstudio-r4.5.1

LABEL \
    com.cloudera.ml.runtime.runtime-metadata-version=$ML_RUNTIME_METADATA_VERSION \
    com.cloudera.ml.runtime.editor=$ML_RUNTIME_EDITOR \
    com.cloudera.ml.runtime.edition=$ML_RUNTIME_EDITION \
    com.cloudera.ml.runtime.description=$ML_RUNTIME_DESCRIPTION \
    com.cloudera.ml.runtime.kernel=$ML_RUNTIME_KERNEL \
    com.cloudera.ml.runtime.full-version=$ML_RUNTIME_FULL_VERSION \
    com.cloudera.ml.runtime.short-version=$ML_RUNTIME_SHORT_VERSION \
    com.cloudera.ml.runtime.maintenance-version=$ML_RUNTIME_MAINTENANCE_VERSION \
    com.cloudera.ml.runtime.git-hash=$ML_RUNTIME_GIT_HASH


# Final container setup
EXPOSE 8787
WORKDIR /home/cdsw
USER cdsw
CMD ["/usr/local/bin/start_rstudio.sh"]
# Healthcheck to ensure RStudio is running
# HEALTHCHECK --interval=30s --timeout=10s --start-period=5s \
#   CMD curl -f http://localhost:8787/ || exit 1