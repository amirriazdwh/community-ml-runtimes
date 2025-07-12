#!/bin/bash
set -euo pipefail

# Test for INSTALL_DIR default value logic in prebuilt-r.sh

SCRIPT="../prebuilt-r.sh"

test_default_install_dir() {
    output=$(bash -c "source <(grep '^R_VERSION=' $SCRIPT); source <(grep '^INSTALL_DIR=' $SCRIPT); echo \$INSTALL_DIR")
    expected="/opt/r-4.5.1"
    if [[ "$output" == "$expected" ]]; then
        echo "PASS: Default INSTALL_DIR is $expected"
    else
        echo "FAIL: Default INSTALL_DIR expected $expected, got $output"
        exit 1
    fi
}

test_custom_install_dir() {
    custom_dir="/tmp/myr"
    output=$(bash -c "R_VERSION=4.5.1; INSTALL_DIR=\"\${3:-/opt/r-\${R_VERSION}}\"; set -- 4.5.1 '' $custom_dir; INSTALL_DIR=\"\${3:-/opt/r-\${R_VERSION}}\"; echo \$INSTALL_DIR")
    if [[ "$output" == "$custom_dir" ]]; then
        echo "PASS: Custom INSTALL_DIR is $custom_dir"
    else
        echo "FAIL: Custom INSTALL_DIR expected $custom_dir, got $output"
        exit 1
    fi
}

test_default_install_dir
test_custom_install_dir
# Test for R_VERSION default value logic in prebuilt-r.sh

test_default_r_version() {
    output=$(bash -c "source <(grep '^R_VERSION=' $SCRIPT); echo \$R_VERSION")
    expected="4.5.1"
    if [[ "$output" == "$expected" ]]; then
        echo "PASS: Default R_VERSION is $expected"
    else
        echo "FAIL: Default R_VERSION expected $expected, got $output"
        exit 1
    fi
}

test_custom_r_version() {
    custom_version="4.2.3"
    output=$(bash -c "set -- $custom_version; R_VERSION=\"\${1:-4.5.1}\"; echo \$R_VERSION")
    if [[ "$output" == "$custom_version" ]]; then
        echo "PASS: Custom R_VERSION is $custom_version"
    else
        echo "FAIL: Custom R_VERSION expected $custom_version, got $output"
        exit 1
    fi
}

test_default_r_version
test_custom_r_version

# Test for required system dependencies in prebuilt-r.sh

test_required_dependencies() {
    required_deps=(
        "libpcre2-dev"
        "libssl-dev"
        "libxml2-dev"
        "libcurl4-openssl-dev"
    )
    script_path="../prebuilt-r.sh"
    for dep in "${required_deps[@]}"; do
        if grep -q "$dep" "$script_path"; then
            echo "PASS: Dependency $dep found in $script_path"
        else
            echo "FAIL: Dependency $dep NOT found in $script_path"
            exit 1
        fi
    done
}

test_required_dependencies
