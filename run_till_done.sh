#!/bin/bash

while [ true ]; do
    $* && exit
    echo -ne "\nSleeping to calm down, will restart shortly\n\n"
    sleep 1m
done
