#!/bin/bash
# DATE       AUTHOR      COMMENT
# ---------- ----------- -----------------------------------------------------
# 2014-08-19 Yosub       Initial version


MODE="soft"
if [ ! -z "$1" ]
then
    echo "There exists argument with" $1
    MODE=$1
else
    echo "No argument"
fi

echo "The mode is:" $MODE

