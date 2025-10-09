FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install system dependencies (excluding nodejs/npm - we'll install newer versions)
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    python3 \
    python3-pip \
    openjdk-17-jdk \
    openjdk-17-jre \
    bash \
    ca-certificates \
    unzip \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

# Set Java environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Install Go
RUN curl -L https://go.dev/dl/go1.21.6.linux-amd64.tar.gz | tar -C /usr/local -xzf -
ENV PATH="/usr/local/go/bin:${PATH}"

# Add Go bin to PATH for installed Go tools
ENV PATH="/root/go/bin:${PATH}"

# Install SCIP tools
RUN go install github.com/sourcegraph/scip-go/cmd/scip-go@latest

# Install Node.js SCIP tools
RUN npm install -g @sourcegraph/scip-typescript @sourcegraph/scip-python

# Install Java SCIP indexer using coursier
RUN curl -fLo /usr/local/bin/coursier https://git.io/coursier-cli && \
    chmod +x /usr/local/bin/coursier && \
    /usr/local/bin/coursier bootstrap --standalone -o /usr/local/bin/scip-java \
    com.sourcegraph:scip-java_2.13:0.11.1 --main com.sourcegraph.scip_java.ScipJava && \
    chmod +x /usr/local/bin/scip-java

# Verify installations and show versions
RUN echo "=== Tool versions ===" && \
    node --version && \
    go version && \
    python3 --version && \
    java -version && \
    echo "=== SCIP tools verification ===" && \
    which scip-go && scip-go --help > /dev/null && echo "✅ scip-go working" && \
    which scip-typescript && scip-typescript --help > /dev/null && echo "✅ scip-typescript working" && \
    which scip-python && scip-python --help > /dev/null && echo "✅ scip-python working" && \
    which scip-java && scip-java --help > /dev/null && echo "✅ scip-java working" && \
    echo "=== All SCIP tools ready ==="

# Git refuses to run commands in "unsafe" directories
# The safe.directory config tells git to trust this directory
RUN git config --global --add safe.directory '*'

# Set default shell to bash for compatibility
SHELL ["/bin/bash", "-c"]
