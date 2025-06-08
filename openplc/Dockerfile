FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    bison \
    flex \
    autoconf \
    automake \
    libtool \
    make \
    git \
    python3 \
    python3-pip \
    sqlite3 \
    cmake \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Create openplc user
RUN useradd -m -s /bin/bash openplc

# Set working directory
WORKDIR /opt/openplc

# Clone OpenPLC Runtime v3
RUN git clone https://github.com/thiagoralves/OpenPLC_v3.git . \
    && chown -R openplc:openplc /opt/openplc

# Switch to openplc user
USER openplc

# Install OpenPLC Runtime
RUN ./install.sh linux

# Expose ports
EXPOSE 8080 502

# Create data directory
RUN mkdir -p /opt/openplc/webserver/openplc_logs

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

# Start OpenPLC Runtime
CMD ["python3", "/opt/openplc/webserver/webserver.py"]