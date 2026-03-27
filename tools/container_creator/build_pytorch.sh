#!/bin/bash

set -eo pipefail

source /opt/intel/oneapi/setvars.sh
export USE_XPU=ON
export USE_XCCL=ON
export BUILD_SEPARATE_OPS=ON
export BUILD_WITH_CPU=ON
export TORCH_XPU_ARCH_LIST=pvc
export USE_PTI=ON
export USE_KINETO=ON
export USE_XETLA=OFF

# Clone Github Repo sin historia completa (solo commit específico)
# Here is where and specific branch, commit, etc can be targeted
cd /opt/
git clone --depth 1 --branch v2.11.0 https://github.com/pytorch/pytorch
cd pytorch

# next steps are to integrate the asynchronous_complete_cumsum_xpu operator from 
# the torch-xpu-ops repository into the PyTorch build process by modifying the 
# CMakeLists.txt and xpu.txt files
# to point to the correct repository and commit that contains the operator implementation.

# Set the following variables to configure the torch-xpu-ops repository integration:
TORCH_XPU_OPS_REPO_URL="https://github.com/aagalleg/torch-xpu-ops"
git clone "${TORCH_XPU_OPS_REPO_URL}" ./third_party/torch-xpu-ops

COMMIT_ID=$(grep -v '^$' ./third_party/xpu.txt)

CAFFE2_OPS_FILE="./caffe2/CMakeLists.txt"
if [ ! -f "${CAFFE2_OPS_FILE}" ]; then
    echo "Required file not found: $CAFFE2_OPS_FILE"
    exit 1
fi

sed -i "s|set(TORCH_XPU_OPS_REPO_URL .*|set(TORCH_XPU_OPS_REPO_URL $TORCH_XPU_OPS_REPO_URL)|" "$CAFFE2_OPS_FILE"

git -C ./third_party/torch-xpu-ops checkout "${COMMIT_ID}"

# Patch torch-xpu-ops BuildFlags so SYCLTLA honors TORCH_XPU_ARCH_LIST
# instead of hardcoding pvc,bmg (bmg is not supported by some oneAPI versions).
BUILD_FLAGS_FILE="./third_party/torch-xpu-ops/cmake/BuildFlags.cmake"
if [ ! -f "${BUILD_FLAGS_FILE}" ]; then
    echo "Required file not found after checkout: ${BUILD_FLAGS_FILE}"
    exit 1
fi

# Patch the BuildFlags.cmake to set SYCL_OFFLINE_COMPILER_AOT_OPTIONS based on TORCH_XPU_ARCH_LIST
# This prevents the build from failing in pvc-only environments where bmg is not supported.
sed -i '/if(TORCH_XPU_ARCH_LIST STREQUAL "cri")/,/endif()/c\
  if(TORCH_XPU_ARCH_LIST STREQUAL "cri")\
      set(SYCL_OFFLINE_COMPILER_AOT_OPTIONS "-device cri")\
  elseif(TORCH_XPU_ARCH_LIST)\
      set(SYCL_OFFLINE_COMPILER_AOT_OPTIONS "-device ${TORCH_XPU_ARCH_LIST}")\
  else()\
      set(SYCL_OFFLINE_COMPILER_AOT_OPTIONS "-device pvc,bmg")\
  endif()' "${BUILD_FLAGS_FILE}"

git -C ./third_party/torch-xpu-ops add cmake/BuildFlags.cmake
if ! git -C ./third_party/torch-xpu-ops diff --cached --quiet; then
    git -C ./third_party/torch-xpu-ops \
        -c user.name="container-builder" \
        -c user.email="container-builder@local" \
        commit -m "Configure SYCL arch"
fi
NEW_COMMIT_ID=$(git -C ./third_party/torch-xpu-ops rev-parse HEAD)

# Write the new commit ID to xpu.txt
echo "${NEW_COMMIT_ID}" > ./third_party/xpu.txt


#### Create conda virtual environment (Conda in this example)
##Download and install conda forge
wget -q -O /tmp/Miniforge.sh \
    "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
chmod +x /tmp/Miniforge.sh
/tmp/Miniforge.sh -b -p /opt/miniforge
rm -rf /tmp/Miniforge.sh
source /opt/miniforge/bin/activate

##Create and activate environment
conda create -n pytorch -y
conda activate pytorch
conda install python=3.12 -y

ln -s /opt/miniforge/etc/profile.d/conda.sh ~/.conda.sh
echo ". ~/.conda.sh" >> ~/.bashrc
echo "conda activate pytorch" >> ~/.bashrc
echo "source /opt/intel/oneapi/setvars.sh" >> ~/.bashrc

##Update cmake with current conda environment path
export CMAKE_PREFIX_PATH="${CONDA_PREFIX:-$(dirname $(which conda))/../}:${CMAKE_PREFIX_PATH}"

# export environment variables for oneAPI libraries
. /opt/intel/oneapi/mkl/latest/env/vars.sh 
. /opt/intel/oneapi/pti/latest/env/vars.sh
. /opt/intel/oneapi/umf/latest/env/vars.sh 

#Install pip requirements and dependencies
pip install mkl-static mkl-include
pip install -r requirements.txt

#Build Pytorch in release mode
python setup.py install

#Clean up
rm -rf build/
