#!/usr/bin/env bash

find . -type f -regex "\./.*\(\~\|\#\)$" -exec rm -fv {} \+
