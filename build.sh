#!/usr/bin/env bash

hexo clean
hexo g
hexo d
git add source
git ci -m"update"
git ps
