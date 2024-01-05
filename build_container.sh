#!/bin/bash

set -ex

# create the buildcache
mkdir -p mirror
docker buildx build -t spack/paraview -f Dockerfile --target cache -o ./mirror .

# create the container containing paraview
docker buildx build -t spack/paraview -f Dockerfile --target build .
