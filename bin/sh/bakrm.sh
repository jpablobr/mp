#!/usr/bin/env bash

find . -type f -regex "\./.*\(\.bak\|\~\)$" -exec rm -v {} \+
