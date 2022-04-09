#!/usr/bin/env bash

mountiso () { sudo mount -o loop -t iso9660 "$@" ; }

mountiso "$@"
