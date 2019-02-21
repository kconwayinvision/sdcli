FROM golang:1.11.5 AS BASE

ENV APT_MAKE_VERSION=4.1-9.1 \
    APT_GCC_VERSION=4:6.3.0-4 \
    APT_GIT_VERSION=1:2.11.0-3+deb9u4 \
    GOLANGCI_VERSION=v1.12.2 \
    APT_NODE_VERSION=11.10.0-1nodesource1

# Install apt dependencies
RUN apt-get update && \
    apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    make=${APT_MAKE_VERSION} \
    gcc=${APT_GCC_VERSION} \
    git=${APT_GIT_VERSION} \
    bc \
    jq && \
    apt-get upgrade -y

#############################################################

FROM BASE AS DEPS

# Install dep
RUN curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh

# Install gocov tools
RUN go get github.com/axw/gocov/... && \
    go install github.com/axw/gocov/gocov && \
    go get github.com/AlekSi/gocov-xml && \
    go install github.com/AlekSi/gocov-xml && \
    go get github.com/wadey/gocovmerge && \
    go install github.com/wadey/gocovmerge

# Install lint
RUN curl -sfL https://install.goreleaser.com/github.com/golangci/golangci-lint.sh | bash -s -- -b ${GOPATH}/bin ${GOLANGCI_VERSION}

# Install NPM
RUN curl -sfL https://deb.nodesource.com/setup_11.x | bash - && \
    apt-get install -y nodejs=${APT_NODE_VERSION}

# Install the bitbucket SSH host
RUN mkdir -p /home/sdcli/.ssh
RUN echo 'bitbucket.org ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==' >> /home/sdcli/.ssh/known_hosts

#####################################################

FROM DEPS

RUN groupadd -r sdcli -g 1000 \
    && useradd --no-log-init -r -g sdcli -u 1000 sdcli \
    && chown -R sdcli:sdcli /opt \
    && chown -R sdcli:sdcli /go \
    && chown -R sdcli:sdcli /home/sdcli

USER sdcli

COPY ./commands/* /usr/bin/

ENTRYPOINT [ "sdcli" ]