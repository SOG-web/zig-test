# ============================================================
# Reps Server Dockerfile
# ============================================================
# Multi-stage build for optimized production image

# ============================================================
# Stage 1: Builder
# ============================================================
FROM debian:bookworm-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    curl \
    xz-utils \
    ca-certificates \
    libssl-dev \
    make \
    && rm -rf /var/lib/apt/lists/*

# Install Zig
ARG ZIG_VERSION=0.15.1
RUN curl -L "https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz" | tar -xJ -C /usr/local && \
    ln -s "/usr/local/zig-x86_64-linux-${ZIG_VERSION}/zig" /usr/local/bin/zig

# Set working directory
WORKDIR /app

# Copy dependency files first (for better caching)
COPY build.zig build.zig.zon ./

# Copy scripts and schemas for model generation
COPY scripts/ ./scripts/
COPY schemas/ ./schemas/
COPY Makefile ./

# Copy source code
COPY src ./src

# Generate models and build the application
RUN make generate-models && make build

# ============================================================
# Stage 2: Runtime
# ============================================================
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy built binary from builder
COPY --from=builder /app/zig-out/bin/vendor_server /app/vendor_server

# Expose port
EXPOSE 8081

# Run the application
CMD ["/app/vendor_server"]