# Define Firmware Version: v8.2.0.0
export PRJ_VERSION = 0x08020000

# Include .XSA in image dir
export GEN_XSA_IMAGE = 1

# Define release
ifndef RELEASE
export RELEASE = all
endif
