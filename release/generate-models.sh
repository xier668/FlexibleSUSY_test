#!/bin/sh -e

# creates models for public release

collier_lib_dir=
collier_inc_dir=
himalaya_lib_dir=
himalaya_inc_dir=
loop_libraries=
looptools_lib_dir=
looptools_inc_dir=
models=
number_of_jobs=1
directory=.
MATH=math
tsil_lib_dir=
tsil_inc_dir=

#_____________________________________________________________________
help() {
cat <<EOF
Usage: ./`basename $0` [options]
Options:

  --directory=              Output directory (default: ${directory})
  --help,-h                 Print this help message
  --number-of-jobs=         Number of parallel makefile jobs (default: ${number_of_jobs})
  --with-collier-libdir=    Path to search for COLLIER libraries
  --with-collier-incdir=    Path to search for COLLIER modules
  --with-himalaya-libdir=   Path to search for Himalaya library
  --with-himalaya-incdir=   Path to search for Himalaya header
  --with-loop-libraries=    Comma separated list of loop libraries to be enabled
                            (for example \`collier', \`looptools', \`fflite')
  --with-looptools-libdir=  Path to search for LoopTools libraries
  --with-looptools-incdir=  Path to search for LoopTools headers
  --with-math-cmd=          Mathematic kernel (default: ${MATH})
  --with-models=            Comma separated list of models to be generated
  --with-tsil-libdir=       Path to search for TSIL library
  --with-tsil-incdir=       Path to search for TSIL header
EOF
}

if test $# -gt 0 ; then
    while test ! "x$1" = "x" ; do
        case "$1" in
            -*=*) optarg=`echo "$1" | sed 's/[-_a-zA-Z0-9]*=//'` ;;
            *) optarg= ;;
        esac

        case $1 in
            --directory=*)             directory=$optarg ;;
            --help|-h)                 help; exit 0 ;;
            --number-of-jobs=*)        number_of_jobs=$optarg ;;
            --with-collier-libdir=*)   collier_lib_dir=$optarg ;;
            --with-collier-incdir=*)   collier_inc_dir=$optarg ;;
            --with-himalaya-incdir=*)  himalaya_inc_dir=$optarg ;;
            --with-himalaya-libdir=*)  himalaya_lib_dir=$optarg ;;
            --with-loop-libraries=*)   loop_libraries=$optarg ;;
            --with-looptools-libdir=*) looptools_lib_dir=$optarg ;;
            --with-looptools-incdir=*) looptools_inc_dir=$optarg ;;
            --with-math-cmd=*)         MATH=$optarg ;;
            --with-models=*)           models=$optarg ;;
            --with-tsil-libdir=*)      tsil_lib_dir=$optarg ;;
            --with-tsil-incdir=*)      tsil_inc_dir=$optarg ;;
            *)  echo "Invalid option '$1'. Try $0 --help" ; exit 1 ;;
        esac
        shift
    done
fi

echo "Using $number_of_jobs parallel jobs"

# use default models if no models specified
models="${models:-\
CMSSM,\
CMSSMSemiAnalytic,\
MSSM,\
MSSMatMGUT,\
MSSMNoFV,\
MSSMNoFVatMGUT,\
CMSSMNoFV,\
NUHMSSM,\
lowMSSM,\
MSSMRHN,\
NMSSM,\
NUTNMSSM,\
NUTSMSSM,\
lowNMSSM,\
lowNMSSMTanBetaAtMZ,\
SMSSM,\
UMSSM,\
E6SSM,\
MRSSM2,\
TMSSM,\
SM,\
HSSUSY,\
SplitMSSM,\
THDMII,\
THDMIIMSSMBC,\
HTHDMIIMSSMBC,\
HGTHDMIIMSSMBC,\
MSSMEFTHiggs,\
NMSSMEFTHiggs,\
E6SSMEFTHiggs,\
MRSSMEFTHiggs,\
CNMSSM,\
CE6SSM,\
MSSMNoFVatMGUTHimalaya,\
MSSMNoFVHimalaya,\
NUHMSSMNoFVHimalaya,\
}"

echo "Building models: ${models}"

models_space=$(echo $models | tr ',' ' ')

# creating models
for m in ${models_space}; do
    ./createmodel --name=${m} --force  --with-math-cmd=${MATH}
done

./configure \
    --with-collier-libdir="${collier_lib_dir}" \
    --with-collier-incdir="${collier_inc_dir}" \
    --with-himalaya-libdir="${himalaya_lib_dir}" \
    --with-himalaya-incdir="${himalaya_inc_dir}" \
    --with-loop-libraries="${loop_libraries}" \
    --with-looptools-libdir="${looptools_lib_dir}" \
    --with-looptools-incdir="${looptools_inc_dir}" \
    --with-models=${models} \
    --with-math-cmd=${MATH} \
    --with-tsil-libdir="${tsil_lib_dir}" \
    --with-tsil-incdir="${tsil_inc_dir}"

make showbuild

make -j${number_of_jobs}

# packing models
for m in ${models_space}; do
    echo "packing ${m} ..."
    make pack-${m}-src
done

# moving models
[ -z "${directory}" ] && directory=.

[ ! -d "${directory}" ] && mkdir -p "${directory}"

if [ "x${directory}" != "x." ]; then
    for m in ${models_space}; do
        mv ${m}.tar.gz ${directory}/
    done
fi
