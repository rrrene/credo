#!/bin/bash

if [[ $(mix help format) ]];
then
  mix format --check-formatted
fi
