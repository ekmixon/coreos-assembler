FROM registry.fedoraproject.org/fedora:35
WORKDIR /root/containerbuild

COPY ./src/print-dependencies.sh ./src/deps*.txt ./src/vmdeps*.txt ./src/build-deps.txt /root/containerbuild/src/
COPY ./build.sh /root/containerbuild/
RUN ./build.sh configure_yum_repos
RUN ./build.sh install_rpms  # nocache 20211102

# Allow Prow to work
RUN mkdir -p /go && chown 0777 /go

COPY ./ /root/containerbuild/
RUN ./build.sh write_archive_info
RUN ./build.sh make_and_makeinstall
RUN ./build.sh configure_user

# clean up scripts (it will get cached in layers, but oh well)
WORKDIR /srv/
RUN chown builder: /srv
RUN rm -rf /root/containerbuild /go

# allow writing to /etc/passwd from arbitrary UID
# https://docs.openshift.com/container-platform/4.8/openshift_images/create-images.html
RUN chmod g=u /etc/passwd

# run as `builder` user
USER builder
ENTRYPOINT ["/usr/bin/dumb-init", "/usr/bin/coreos-assembler"]
