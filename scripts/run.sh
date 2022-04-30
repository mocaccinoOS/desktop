#!/bin/bash

root=$(git rev-parse --show-toplevel)
docker build -t desktop-scripts $root/scripts

script=$1
shift

set -ex

docker run -v $root:/work --workdir /work --entrypoint /bin/bash --rm desktop-scripts -c "bash scripts/$script $@"