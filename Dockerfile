FROM docker.io/debian:10-slim
WORKDIR /download
RUN apt-get update && apt-get install -y curl unzip

# Install kubectl
RUN curl -sLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl" \
    && chmod +x kubectl
RUN curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip" && unzip awscliv2.zip


FROM docker.io/debian:10-slim
LABEL image.original.author="Mike Petersen <mike@odania-it.de>"
LABEL image.author="Joseph Jones"

ADD *.sh /usr/local/bin/
COPY --from=0 /download/kubectl /usr/local/bin/kubectl
WORKDIR /tmp/download
COPY --from=0 /download/aws /tmp/download/aws

RUN adduser --system user && apt-get update && apt-get install -y jq && ./aws/install
USER user
WORKDIR /home/user
ENV PATH /usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/user/.local/bin

CMD [ "/usr/local/bin/run.sh" ]
