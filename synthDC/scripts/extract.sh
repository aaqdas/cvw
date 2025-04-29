#!/bin/bash

SRC="../runs/wallypipelinedcore_rv64gc_orig_freepdk15nm_1000_MHz_2025-04-22-12-27__dc75fb787/mapped/wallypipelinedcore.sv"
# Run the Python script with the provided arguments
python3 extract.py --src $SRC --module alu
python3 extract.py --src $SRC --module cache