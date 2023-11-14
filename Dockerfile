FROM spack/ubuntu-focal:latest AS builder

# create mirror and copy buildcache
RUN mkdir -p /mirror
COPY ./mirror/ /mirror/
RUN spack mirror add local /mirror

# RUN spack env create myenv
# RUN spack env activate myenv && spack add paraview+mpi+osmesa+python

# What we want to install and how we want to install it
# is specified in a manifest file (spack.yaml)
RUN mkdir /opt/spack-environment \
&&  (echo spack: \
&&   echo '  # add package specs to the `specs` list' \
&&   echo '  specs: [paraview+mpi+osmesa+python, openmpi+legacylaunchers fabrics=ucx schedulers=slurm]' \
&&   echo '  view: /opt/views/view' \
&&   echo '  concretizer:' \
&&   echo '    unify: true' \
&&   echo '  config:' \
&&   echo '    install_tree: /opt/software') > /opt/spack-environment/spack.yaml

WORKDIR /opt/spack-environment

# install all packages available from buildcache and dont check their signature
RUN spack env activate . && spack concretize && spack install --no-check-signature

# push the newly build packages to build cache without signature
RUN spack env activate . && spack buildcache push --unsigned /mirror

# Modifications to the environment that are necessary to run
RUN spack env activate --sh -d . > activate.sh

# output buildcache
FROM scratch AS cache
COPY --from=builder /mirror/ .

FROM spack/ubuntu-focal:latest AS build

COPY --from=builder /opt/spack-environment /opt/spack-environment
COPY --from=builder /opt/software /opt/software
COPY --from=builder /opt/views /opt/views

RUN { \
      echo '#!/bin/sh' \
      && echo '.' /opt/spack-environment/activate.sh \
      && echo 'exec "$@"'; \
    } > /entrypoint.sh \
&& chmod a+x /entrypoint.sh \
&& ln -s /opt/views/view /opt/view

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/bin/bash" ]

EXPOSE 11123
# ENTRYPOINT ["/bin/bash", "--rcfile", "/etc/profile", "-l"]