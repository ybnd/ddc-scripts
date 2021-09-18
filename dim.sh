#!/bin/bash

source "$(dirname $0)/common.sh"

ddc_adjust 'brightness' $(dealias $1)
