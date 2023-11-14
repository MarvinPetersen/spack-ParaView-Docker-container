#!/bin/bash

set -e

# create the buildcache 
docker buildx build -t spack/paraview -f Dockerfile --target cache -o ./mirror .

# create the container containing paraview
docker buildx build -t spack/paraview -f Dockerfile --target build .