# Setup the Xilinx software and licensing in KEK
source /tools/Xilinx/Vivado/2023.1/settings64.sh
source /tools/Xilinx/Model_Composer/2023.1/settings64.sh

export LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LIBRRY_PATH

export XILINX_MATLAB_ROOT_PATH=/home/nomaru/local/src/Matlab/MatlabR2021a
export PATH=$XILINX_MATLAB_ROOT_PATH/bin:$XILINX_MATLAB_ROOT_PATH/sys/java/jre/glnxa64/jre/bin:$PATH

# https://www.mathworks.com/help/compiler/mcr-path-settings-for-run-time-deployment.html#mw_8b4e2361-7e0d-4eb9-b3d3-55762966f1b0
export LD_LIBRARY_PATH="\
$LD_LIBRARY_PATH:\
/usr/lib/x86_64-linux-gnu:\
$XILINX_MATLAB_ROOT_PATH/runtime/glnxa64:\
$XILINX_MATLAB_ROOT_PATH/bin/glnxa64:\
$XILINX_MATLAB_ROOT_PATH/sys/os/glnxa64:\
$XILINX_MATLAB_ROOT_PATH/extern/bin/glnxa64:\
$XILINX_MATLAB_ROOT_PATH/sys/opengl/lib/glnxa64:\
$XILINX_MATLAB_ROOT_PATH/sys/java/jre/glnxa64/jre/lib/amd64"
