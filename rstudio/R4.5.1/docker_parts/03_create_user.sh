#!/bin/bash
set -e

groupadd --gid "${CDSW_GROUP_ID}" "${CDSW_USER}"

useradd --uid "${CDSW_USER_ID}" \
        --gid "${CDSW_GROUP_ID}" \
        --create-home --shell /bin/bash "${CDSW_USER}"

echo "${CDSW_USER}:cdsw" | chpasswd

echo "${CDSW_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
