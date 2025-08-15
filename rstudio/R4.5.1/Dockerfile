FROM ubuntu:22.04

# Ensure docker_parts exists
RUN [ -d /tmp/docker_parts ] || mkdir -p /tmp/docker_parts

# 01: Environment Variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Dubai \
    R_VERSION=4.5.1 \
    RSTUDIO_VERSION=2025.05.1-513 \
    CRAN=https://cloud.r-project.org/ \
    R_HOME=/usr/local/lib/R \
    R_LIBS_USER=/usr/local/lib/R/site-library \
    R_ENABLE_JIT=3 \
    R_COMPILE_PKGS=1 \
    MALLOC_ARENA_MAX=2 \
    OMP_NUM_THREADS=1 \
    R_MAX_VSIZE=32G \
    R_MAX_SIZE=32000000000 \
    PATH="/usr/local/lib/R/bin:${PATH}" \
    JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"

############################
# setup system locally
############################
RUN apt-get update && \
apt-get install -y --no-install-recommends locales && \
locale-gen en_US.UTF-8 && \
update-locale LANG=en_US.UTF-8 && \
apt-get clean && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
LANGUAGE=en_US:en \
LC_ALL=en_US.UTF-8

####################
# setup apt-utils 
####################
RUN apt-get update && \
apt-get install -y --no-install-recommends apt-utils && \
rm -rf /var/lib/apt/lists/*

##########################
# 02: System Dependencies
##########################
COPY docker_parts/02_system_dependencies.sh /tmp/docker_parts/02_system_dependencies.sh
RUN test -f /tmp/docker_parts/02_system_dependencies.sh && chmod +x /tmp/docker_parts/02_system_dependencies.sh && /tmp/docker_parts/02_system_dependencies.sh

#########################################################################################
# LaTeX support for building R packages with PDF vignettes and manuals
#########################################################################################
RUN apt-get update && apt-get install -y --no-install-recommends \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-fonts-extra \
    texlive-fonts-recommended \
    texlive-font-utils \
    fonts-inconsolata \
    tex-gyre \
    lmodern \
    texinfo \
    ghostscript \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Ensure correct fonts for PDF documentation
RUN if [ ! -f /usr/share/texlive/texmf-dist/tex/latex/inconsolata/inconsolata.sty ] && [ ! -f /usr/share/texlive/texmf-dist/tex/latex/zi4/zi4.sty ]; then \
    apt-get update && \
    apt-get install -y --no-install-recommends texlive-base perl && \
    tlmgr init-usertree && \
    tlmgr install inconsolata && \
    apt-get clean && rm -rf /var/lib/apt/lists/* ; \
    fi

# Install Python 3
RUN apt-get update && apt-get install -y python3 python3-pip && \
    if [ ! -e /usr/bin/python ]; then ln -s /usr/bin/python3 /usr/bin/python; fi
####################################
# 03: Create cdsw User
####################################
COPY docker_parts/03_create_user.sh /tmp/docker_parts/03_create_user.sh
RUN test -f /tmp/docker_parts/03_create_user.sh && chmod +x /tmp/docker_parts/03_create_user.sh && /tmp/docker_parts/03_create_user.sh

####################################
# 03a: Install Java
####################################
COPY docker_parts/03a_install_java.sh /tmp/docker_parts/03a_install_java.sh
RUN test -f /tmp/docker_parts/03a_install_java.sh && chmod +x /tmp/docker_parts/03a_install_java.sh && /tmp/docker_parts/03a_install_java.sh

############################
# 04: Install R from source
############################
COPY docker_parts/04_install_r.sh /tmp/docker_parts/04_install_r.sh
COPY docker_parts/Rprofile.site.base /tmp/docker_parts/Rprofile.site.base
COPY docker_parts/Renviron.site.template /tmp/docker_parts/Renviron.site.template
RUN test -f /tmp/docker_parts/04_install_r.sh && chmod +x /tmp/docker_parts/04_install_r.sh && /tmp/docker_parts/04_install_r.sh

# 06: Banking packages
# COPY docker_parts/06_install_banking_packages.sh /tmp/docker_parts/06_install_banking_packages.sh
# RUN test -f /tmp/docker_parts/06_install_banking_packages.sh && chmod +x /tmp/docker_parts/06_install_banking_packages.sh && /tmp/docker_parts/06_install_banking_packages.sh

#############################################
# Ensure R shared libraries are discoverable
#############################################
RUN echo "/usr/local/lib/R/lib" > /etc/ld.so.conf.d/R.conf && ldconfig

############################################
# 05: Global R options and memory tuning
############################################
COPY docker_parts/05_set_r_memory.sh /tmp/docker_parts/05_set_r_memory.sh
RUN test -f /tmp/docker_parts/05_set_r_memory.sh && mv /tmp/docker_parts/05_set_r_memory.sh /etc/profile.d/set_r_memory.sh && chmod 755 /etc/profile.d/set_r_memory.sh

########################################################
# 07: RStudio server installation and configuration
########################################################
COPY docker_parts/07_rstudio_install.sh /tmp/docker_parts/07_rstudio_install.sh
COPY docker_parts/rstudio-config.R /tmp/docker_parts/rstudio-config.R
#COPY docker_parts/config-handling.R /tmp/docker_parts/config-handling.R
RUN test -f /tmp/docker_parts/07_rstudio_install.sh && chmod +x /tmp/docker_parts/07_rstudio_install.sh && /tmp/docker_parts/07_rstudio_install.sh

# Ensure the profiles.d directory exists
RUN mkdir -p /usr/local/lib/R/etc/profiles.d && \
    cp /tmp/docker_parts/rstudio-config.R /usr/local/lib/R/etc/profiles.d/ && \
    chown -R root:rstudio-users /usr/local/lib/R/etc/profiles.d && \
    chmod 755 /usr/local/lib/R/etc/profiles.d && \
    chmod 644 /usr/local/lib/R/etc/profiles.d/rstudio-config.R

###########################################################################################
# Create RStudio-specific log directories with proper permissions (after RStudio install)
##########################################################################################
RUN mkdir -p /var/log/rstudio-server /var/log/rstudio-sessions && \
    chown -R root:rstudio-users /var/log/rstudio-server /var/log/rstudio-sessions && \
    chmod -R 775 /var/log/rstudio-server /var/log/rstudio-sessions && \
    touch /var/log/r_profile_memory.log && \
    chown root:rstudio-users /var/log/r_profile_memory.log && \
    chmod 664 /var/log/r_profile_memory.log

#############################################
# 08: RStudio rserver.conf configuration
#############################################
COPY docker_parts/08_rserver.conf /etc/rstudio/rserver.conf

RUN chown root:rstudio-users /etc/rstudio/rserver.conf && \
    chmod 640 /etc/rstudio/rserver.conf

###############################################################
# 08: RStudio rsession.conf configuration (OPTIMIZED VERSION)
###############################################################
COPY docker_parts/08_rsession.conf /etc/rstudio/rsession.conf
RUN chown root:rstudio-users /etc/rstudio/rsession.conf && \
    chmod 640 /etc/rstudio/rsession.conf


# 08: Post-installed packages for data science workflows
# COPY docker_parts/08_r_postinstall_packages.sh /tmp/docker_parts/08_r_postinstall_packages.sh
# RUN test -f /tmp/docker_parts/08_r_postinstall_packages.sh && chmod +x /tmp/docker_parts/08_r_postinstall_packages.sh && /tmp/docker_parts/08_r_postinstall_packages.sh 

######################################################################
# Ensure R environment variables are writable by all RStudio users
######################################################################
RUN touch /usr/local/lib/R/etc/Renviron.site && \
    chmod 664 /usr/local/lib/R/etc/Renviron.site && \
    chown root:rstudio-users /usr/local/lib/R/etc/Renviron.site

#####################################
# 09: RStudio startup script
###################################
COPY docker_parts/09_start_rstudio.sh /usr/local/bin/start_rstudio.sh
RUN test -f /usr/local/bin/start_rstudio.sh && chmod +x /usr/local/bin/start_rstudio.sh

############################################
# Final cleanup to reduce image size
############################################
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

############################################
# Healthcheck to ensure RStudio is running
############################################
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s \
  CMD wget --quiet --tries=1 --spider http://localhost:8787/ || exit 1

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
################################
# Final container setup
################################
EXPOSE 8787
CMD ["/usr/local/bin/start_rstudio.sh"]