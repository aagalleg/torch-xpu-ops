ARG BASE_IMAGE
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-c"] 

ENV LANG=C.UTF-8

# Add Intel oneAPI repository
RUN no_proxy="" wget -qO- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | \
    gpg --dearmor -o /usr/share/keyrings/oneapi-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | \
    tee /etc/apt/sources.list.d/oneAPI.list

RUN no_proxy="" apt-get update -y && \
    no_proxy="" apt-get install -y --no-install-recommends --fix-missing \
    apt-utils \
    build-essential \
    clinfo \
    curl \
    tmux \
    htop \
    vim \
    git \
    gnupg2 \
    gpg-agent \
    rsync \
    unzip \
    zip \
    tar \
    gzip \
    dpkg-dev \
    ca-certificates \
    ssh \
    openssh-server \
    wget \
    cmake \
    make \
    nano \
    gh \
    intel-deep-learning-essentials-2025.3 \
    intel-ocloc \
    intel-opencl-icd \
    intel-level-zero-gpu \
    level-zero \
    libze-dev \
    libze-intel-gpu1 \
    libze1 \
    software-properties-common \
    openssh-client \
    net-tools \
    file \
    pkg-config \
    libarchive13 \
    libopenmpi-dev \
    openmpi-bin \
    libgtk2.0-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Intel Graphics Compiler libraries
RUN no_proxy="" apt-get update -y && \
    no_proxy="" apt-get install -y --no-install-recommends \
    intel-igc-cm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create symlink for libigc.so.1 compatibility (Ubuntu 24.04 uses libigc.so.2)
RUN if [ -f /usr/lib/x86_64-linux-gnu/libigc.so.2 ]; then \
        ln -sf /usr/lib/x86_64-linux-gnu/libigc.so.2 /usr/lib/x86_64-linux-gnu/libigc.so.1; \
    elif [ -f /usr/lib/libigc.so.2 ]; then \
        ln -sf /usr/lib/libigc.so.2 /usr/lib/libigc.so.1; \
    fi && \
    if [ -f /usr/lib/x86_64-linux-gnu/libigdfcl.so.2 ]; then \
        ln -sf /usr/lib/x86_64-linux-gnu/libigdfcl.so.2 /usr/lib/x86_64-linux-gnu/libigdfcl.so.1; \
    elif [ -f /usr/lib/libigdfcl.so.2 ]; then \
        ln -sf /usr/lib/libigdfcl.so.2 /usr/lib/libigdfcl.so.1; \
    fi

# Build PyTorch from source with XPU support
COPY build_pytorch.sh /usr/local/bin/build_pytorch.sh
RUN chmod +x /usr/local/bin/build_pytorch.sh
RUN /usr/local/bin/build_pytorch.sh

# Clean up to reduce image size
RUN source /opt/miniforge/bin/activate && \
    conda clean -a -y && \
    # Remove conda package cache directories
    rm -rf /opt/miniforge/pkgs/* && \
    rm -rf /root/.cache/pip && \
    rm -rf /root/.conda/pkgs && \
    # Clean temporary files
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    # Remove build artifacts and logs
    find /root -name "*.pyc" -delete && \
    find /root -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true && \
    # Clean apt cache (already done but ensure completeness)
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
    