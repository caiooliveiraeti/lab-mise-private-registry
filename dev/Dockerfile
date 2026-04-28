FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y curl ca-certificates tar && \
    rm -rf /var/lib/apt/lists/*

RUN curl https://mise.run | sh

ENV PATH="/root/.local/bin:${PATH}"

WORKDIR /workspace

COPY .mise.toml /workspace/
COPY entrypoint.sh /entrypoint.sh
COPY test-java.sh /workspace/
RUN chmod +x /entrypoint.sh /workspace/test-java.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
