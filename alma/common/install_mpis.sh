#!/bin/bash
set -e

GCC_VERSION=$1
HPCX_PATH=$2

HCOLL_PATH=${HPCX_PATH}/hcoll
UCX_PATH=${HPCX_PATH}/ucx
INSTALL_PREFIX=/opt

# Load gcc
export PATH=/opt/${GCC_VERSION}/bin:$PATH
export LD_LIBRARY_PATH=/opt/${GCC_VERSION}/lib64:$LD_LIBRARY_PATH
set CC=/opt/${GCC_VERSION}/bin/gcc
set GCC=/opt/${GCC_VERSION}/bin/gcc

# MVAPICH2 2.3.7
MV2_VERSION="2.3.7"
MV2_DOWNLOAD_URL=http://mvapich.cse.ohio-state.edu/download/mvapich/mv2/mvapich2-${MV2_VERSION}.tar.gz
$COMMON_DIR/download_and_verify.sh $MV2_DOWNLOAD_URL "c39a4492f4be50df6100785748ba2894e23ce450a94128181d516da5757751ae"
tar -xvf mvapich2-${MV2_VERSION}.tar.gz
cd mvapich2-${MV2_VERSION}
./configure --prefix=${INSTALL_PREFIX}/mvapich2-${MV2_VERSION} --enable-g=none --enable-fast=yes && make -j$(nproc) && make install
cd ..
$COMMON_DIR/write_component_version.sh "MVAPICH2" ${MV2_VERSION}


# OpenMPI 4.1.3
OMPI_VERSION="4.1.3"
OMPI_DOWNLOAD_URL=https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-${OMPI_VERSION}.tar.gz
$COMMON_DIR/download_and_verify.sh $OMPI_DOWNLOAD_URL "9c0fd1f78fc90ca9b69ae4ab704687d5544220005ccd7678bf58cc13135e67e0"
tar -xvf openmpi-${OMPI_VERSION}.tar.gz
cd openmpi-${OMPI_VERSION}
./configure --prefix=${INSTALL_PREFIX}/openmpi-${OMPI_VERSION} --with-ucx=${UCX_PATH} --with-hcoll=${HCOLL_PATH} --enable-mpirun-prefix-by-default --with-platform=contrib/platform/mellanox/optimized && make -j$(nproc) && make install
cd ..
$COMMON_DIR/write_component_version.sh "OMPI" ${OMPI_VERSION}

# exclude openmpi, perftest from updates
sed -i "$ s/$/ openmpi perftest/" /etc/dnf/dnf.conf

# Intel MPI 2021 (Update 7)
IMPI_2021_VERSION="2021.7.0"
IMPI_2021_DOWNLOAD_URL=https://registrationcenter-download.intel.com/akdlm/irc_nas/18926/l_mpi_oneapi_p_${IMPI_2021_VERSION}.8711_offline.sh
$COMMON_DIR/download_and_verify.sh $IMPI_2021_DOWNLOAD_URL "4eb1e1487b67b98857bc9b7b37bcac4998e0aa6d1b892b2c87b003bf84fb38e9"
bash l_mpi_oneapi_p_${IMPI_2021_VERSION}.8711_offline.sh -s -a -s --eula accept
mv ${INSTALL_PREFIX}/intel/oneapi/mpi/${IMPI_2021_VERSION}/modulefiles/mpi ${INSTALL_PREFIX}/intel/oneapi/mpi/${IMPI_2021_VERSION}/modulefiles/impi
$COMMON_DIR/write_component_version.sh "IMPI_2021" ${IMPI_2021_VERSION}

# Setup module files for MPIs
mkdir -p /usr/share/Modules/modulefiles/mpi/

# MVAPICH2
cat << EOF >> /usr/share/Modules/modulefiles/mpi/mvapich2-${MV2_VERSION}
#%Module 1.0
#
#  MVAPICH2 ${MV2_VERSION}
#
conflict        mpi
module load ${GCC_VERSION}
prepend-path    PATH            /opt/mvapich2-${MV2_VERSION}/bin
prepend-path    LD_LIBRARY_PATH /opt/mvapich2-${MV2_VERSION}/lib
prepend-path    MANPATH         /opt/mvapich2-${MV2_VERSION}/share/man
setenv          MPI_BIN         /opt/mvapich2-${MV2_VERSION}/bin
setenv          MPI_INCLUDE     /opt/mvapich2-${MV2_VERSION}/include
setenv          MPI_LIB         /opt/mvapich2-${MV2_VERSION}/lib
setenv          MPI_MAN         /opt/mvapich2-${MV2_VERSION}/share/man
setenv          MPI_HOME        /opt/mvapich2-${MV2_VERSION}
EOF

# OpenMPI
cat << EOF >> /usr/share/Modules/modulefiles/mpi/openmpi-${OMPI_VERSION}
#%Module 1.0
#
#  OpenMPI ${OMPI_VERSION}
#
conflict        mpi
module load ${GCC_VERSION}
prepend-path    PATH            /opt/openmpi-${OMPI_VERSION}/bin
prepend-path    LD_LIBRARY_PATH /opt/openmpi-${OMPI_VERSION}/lib
prepend-path    MANPATH         /opt/openmpi-${OMPI_VERSION}/share/man
setenv          MPI_BIN         /opt/openmpi-${OMPI_VERSION}/bin
setenv          MPI_INCLUDE     /opt/openmpi-${OMPI_VERSION}/include
setenv          MPI_LIB         /opt/openmpi-${OMPI_VERSION}/lib
setenv          MPI_MAN         /opt/openmpi-${OMPI_VERSION}/share/man
setenv          MPI_HOME        /opt/openmpi-${OMPI_VERSION}
EOF

#IntelMPI-v2021
cat << EOF >> /usr/share/Modules/modulefiles/mpi/impi_${IMPI_2021_VERSION}
#%Module 1.0
#
#  Intel MPI ${IMPI_2021_VERSION}
#
conflict        mpi
module load /opt/intel/oneapi/mpi/${IMPI_2021_VERSION}/modulefiles/impi
setenv          MPI_BIN         /opt/intel/oneapi/mpi/${IMPI_2021_VERSION}/bin
setenv          MPI_INCLUDE     /opt/intel/oneapi/mpi/${IMPI_2021_VERSION}/include
setenv          MPI_LIB         /opt/intel/oneapi/mpi/${IMPI_2021_VERSION}/lib
setenv          MPI_MAN         /opt/intel/oneapi/mpi/${IMPI_2021_VERSION}/man
setenv          MPI_HOME        /opt/intel/oneapi/mpi/${IMPI_2021_VERSION}
EOF

# Create symlinks for modulefiles
ln -s /usr/share/Modules/modulefiles/mpi/mvapich2-${MV2_VERSION} /usr/share/Modules/modulefiles/mpi/mvapich2
ln -s /usr/share/Modules/modulefiles/mpi/openmpi-${OMPI_VERSION} /usr/share/Modules/modulefiles/mpi/openmpi
ln -s /usr/share/Modules/modulefiles/mpi/impi_${IMPI_2021_VERSION} /usr/share/Modules/modulefiles/mpi/impi-2021

# cleanup downloaded tarballs and other installation files/folders
rm -rf *.tar.gz *offline.sh
rm -rf -- */
