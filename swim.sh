#!/bin/bash

source "$(dirname $0)/common.sh"

ddc_adjust 'input_source' $(dealias $1)
