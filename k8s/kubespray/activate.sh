#!/bin/bash

docker build -t kubespray:dev . && \
    docker run -it --rm -v $(pwd):/repo kubespray:dev /bin/bash
