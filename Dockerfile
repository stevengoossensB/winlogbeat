FROM golang:1.13
ARG version=7.3.2
ARG mage=1.9.0

# Install mage. Required for beats build processes.
RUN wget -qO- https://github.com/magefile/mage/releases/download/v${mage}/mage_${mage}_Linux-64bit.tar.gz | tar -C /bin -zxO mage > /bin/mage
RUN chmod 755 /bin/mage

# Install virtualenv. Required for beats build processes.
RUN apt-get update
# python 3's pip
RUN apt-get install -y python3-pip
RUN pip3 install virtualenv

#RUN go get github.com/elastic/beats
RUN mkdir -p $GOPATH/src/github.com/elastic
RUN git -C $GOPATH/src/github.com/elastic clone --depth 1 --single-branch --branch v${version} https://github.com/elastic/beats
WORKDIR $GOPATH/src/github.com/elastic/beats

# Target winlogbeat
WORKDIR $GOPATH/src/github.com/elastic/beats/winlogbeat

# Patch out the `init` function in winlogbeat to avoid this error on non-Windows systems:
#   Exiting: Failed to create new event log. No event log API is available on this system
#
# This allows us to run `winlogbeat setup` on linux systems.
RUN sed -i -e 's/^\(func .* \)\(init(.*) error {.*\)$/\1\2 return nil }\n\1_\2/' beater/winlogbeat.go

# Compile winlogbeat
RUN make

# Generate winlogbeat's dashboards/templates/fields/etc
RUN make update
