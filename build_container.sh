#!/bin/bash

set -ex

# create the container containing paraview
docker buildx build -t spack/paraview -f Dockerfile --target build .
