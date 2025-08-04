#!/bin/bash

# A simple script to check installed packages

echo "Listing all installed packages:"
dpkg -l | grep '^ii' | awk '{print $2}' | sort