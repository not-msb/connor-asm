#!/bin/sh

set -e

if [ "$1" == "clear" ]
then
    rm -f main
    exit
fi

fasm main.fasm main

if [ "$1" == "run" ]
then
    ./main
    exit
fi
