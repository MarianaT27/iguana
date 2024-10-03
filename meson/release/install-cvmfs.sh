#!/usr/bin/env bash

# automation for deploying new releases
# this script is for maintainers, not users; users should
# follow installation documentation instead

set -e
set -u

msg() {
  echo """
==================================================================================
$@
=================================================================================="""
}

print_var() {
  echo "$@" | sed 's/:/\n  /g'
}

print_dep_vars() {
  echo """
PKG_CONFIG_PATH:
  $(print_var ${PKG_CONFIG_PATH-})

CMAKE_PREFIX_PATH:
  $(print_var ${CMAKE_PREFIX_PATH-})"""
}

sourceDir=$(realpath $(dirname ${BASH_SOURCE[0]:-$0})/../..)
version=$($sourceDir/meson/detect-version.sh $sourceDir)
msg "Detected version $version"

if [ $# -ne 3 ]; then
  echo """
  USAGE: $0 [BUILD_DIR] [INSTALL_PREFIX] [TEST_HIPO_FILE]

    BUILD_DIR          build directory
    INSTALL_PREFIX     install to [INSTALL_PREFIX]
    TEST_HIPO_FILE     a sample HIPO file, for running tests
  """
  print_dep_vars
  exit 2
fi
buildDir=$1
installDir=$(realpath $2)
testFile=$(realpath $3)
nativeFile=$sourceDir/meson/release/native/release.ini
echo """
sourceDir  = $sourceDir
buildDir   = $buildDir
installDir = $installDir
testFile   = $testFile
nativeFile = $nativeFile"""
[ ! -f "$testFile" ] && echo "ERROR: test file does not exist" >&2 && exit 1
print_dep_vars
printf "\nProceed with installation? [y/N] "
read proceed
case $proceed in
  y|Y|yes)
    echo "Proceeding with installation..."
    ;;
  *)
    echo "Abort."
    exit 1
    ;;
esac

msg "meson setup"
meson setup $buildDir $sourceDir \
  --native-file=$nativeFile      \
  --prefix=$installDir           \
  -Drcdb:home=$RCDB_HOME         \
  -Dtest_data_file=$testFile
msg "meson install"
meson install -C $buildDir
msg "meson test"
meson test -C $buildDir

msg "Done installation"
echo """
  prefix:      $installDir
"""
msg "Next steps:"
echo """
- [ ] temporarily set the linker path with one of:
  - bash: export LD_LIBRARY_PATH=$installDir/lib:\$LD_LIBRARY_PATH
  - tcsh: setenv LD_LIBRARY_PATH $installDir/lib:\$LD_LIBRARY_PATH
- [ ] try running installed binaries: $installDir/bin/
- [ ] update clas12-env
- [ ] module switch, then test
"""
