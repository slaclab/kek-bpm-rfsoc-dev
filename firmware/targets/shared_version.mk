# Define Firmware Version: v6.3.0.0
export PRJ_VERSION = 0x06030000

# Include .XSA in image dir
export GEN_XSA_IMAGE = 1

# Define release
ifndef RELEASE
export RELEASE = all
endif
