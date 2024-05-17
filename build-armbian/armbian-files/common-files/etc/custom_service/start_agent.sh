#!/bin/bash

aa=$(netstat -tunlp | grep 17777 | grep -v grep)
if  [ ! -n "$aa" ]; then
    str=$"/n"
    cd /etc/custom_service
    ./arm_linux_agent  >/dev/null 2>&1
    sstr=$(echo -e $str)
    echo "$sstr"
fi