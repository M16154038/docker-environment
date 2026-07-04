FROM ubuntu:24.04 AS base
ENV TZ=Asia/Taipei


ARG USERNAME=m16154038      # 使用者名稱
ARG USER_UID=1000     # 固定 UID(對齊主機)
ARG USER_GID=1000     # 固定 GID

RUN userdel -r ubuntu 2>/dev/null; \
    groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME}

USER ${USERNAME}

FROM base AS common_pkg_provider

USER root

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        vim \
        git \
        curl \
        wget \
        ca-certificates \
        build-essential \
        python3 \
        python3-pip \
    && rm -rf /var/lib/apt/lists/*

FROM base AS verilator_provider

USER root

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        git \
        autoconf \
        g++ \
        flex \
        bison \
        make \
        help2man \
        perl \
        libfl2 \
        libfl-dev \
        python3 \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/verilator/verilator /opt/verilator \
    && cd /opt/verilator \
    && git checkout v5.048 \
    && autoconf \
    && ./configure \
    && make -j$(nproc) \
    && make install

FROM base AS systemc_provider

USER root


RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        git \
        g++ \
        make \
        cmake \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/accellera-official/systemc /opt/systemc-src \
    && cd /opt/systemc-src \
    && git checkout 2.3.4 \
    && mkdir build \
    && cd build \
    && cmake -DCMAKE_INSTALL_PREFIX=/opt/systemc -DCMAKE_CXX_STANDARD=17 .. \
    && make -j$(nproc) \
    && make install

# ==========  release stage ==========
FROM base AS release

USER root

# 這裡放最終環境要「用」的 apt 工具
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        vim \
        git \
        curl \
        wget \
        ca-certificates \
        build-essential \
        python3 \
        python3-pip \
        perl \
        libfl2 \
    && rm -rf /var/lib/apt/lists/*

# ② Verilator：從 verilator_provider 搬成品（集中在 /usr/local）
COPY --from=verilator_provider /usr/local /usr/local

# ③ SystemC：從 systemc_provider 搬成品（集中在 /opt/systemc）
COPY --from=systemc_provider /opt/systemc /opt/systemc


ENV SYSTEMC_HOME=/opt/systemc
ENV LD_LIBRARY_PATH=/opt/systemc/lib


USER ${USERNAME}