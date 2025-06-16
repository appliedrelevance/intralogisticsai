FROM debian:bullseye

USER root
WORKDIR /root/

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get -y install git python3-pip autoconf bison build-essential pkg-config bison flex autoconf automake libtool make git python3 python3-pip sqlite3 cmake sudo curl && \
    apt-get clean

# Install Python dependencies with specific versions for compatibility
RUN pip3 install flask flask-login pyserial pymodbus==2.5.3

# Create openplc user with sudo access
RUN useradd --create-home --shell /bin/bash openplc
RUN adduser openplc sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER openplc
WORKDIR /home/openplc

# Clone and install OpenPLC
RUN git clone https://github.com/thiagoralves/OpenPLC_v3.git
WORKDIR /home/openplc/OpenPLC_v3
RUN sudo ./install.sh custom

# Create startup script
RUN echo '#!/bin/bash\ncd /home/openplc/OpenPLC_v3/webserver\npython3 webserver.py' > /home/openplc/run.sh && \
    sudo chmod +x /home/openplc/run.sh

# Expose all necessary ports
EXPOSE 502 8080 20000 43628

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

CMD ["/home/openplc/run.sh"]