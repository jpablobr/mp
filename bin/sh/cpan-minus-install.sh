#!/bin/sh

curl -L http://cpanmin.us | \
  perl - --sudo App::cpanminus
