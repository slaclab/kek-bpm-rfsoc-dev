# Define Firmware Version: v9.1.0.0
export PRJ_VERSION = 0x09010000

# Include .XSA in image dir
export GEN_XSA_IMAGE = 1

# Define release
ifndef RELEASE
export RELEASE = all
endif
