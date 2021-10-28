#!/bin/bash

export LD_LIBRARY_PATH=/usr/lib/memccache:${LD_LIBRARY_PATH}
/usr/local/bin/memccache $@
