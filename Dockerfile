FROM rust:1.94-slim AS builder

WORKDIR /build

# Clone and build deskd
RUN apt-get update && apt-get install -y git && \
    git clone https://github.com/kgatilin/deskd.git && \
    cd deskd && cargo build --release

# Runtime image
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

# Create geniearchi user
RUN useradd -m -s /bin/bash geniearchi

# Copy deskd binary
COPY --from=builder /build/deskd/target/release/deskd /usr/local/bin/deskd

# Copy geniearchi config and channel server
COPY config/ /home/geniearchi/config/
COPY channel-server/ /home/geniearchi/channel-server/
COPY FOR_AGENTS.md /home/geniearchi/

# Set ownership
RUN chown -R geniearchi:geniearchi /home/geniearchi

USER geniearchi
WORKDIR /home/geniearchi

EXPOSE 8789

CMD ["deskd", "serve", "--socket", "/tmp/deskd.sock"]
