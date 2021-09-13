#!/usr/bin/env bash

### Check GCC and Clang versions on Tuffix, and upgrade if needed - Usually a one-time occurrence
###  The procedure should be removed once Tuffix is configured out-of-the-box with correct versions
CheckVersion()
{
  RequiredGccVersion=11
  RequiredClangVersion=12

  buffer=( $(lsb_release -d ) )
  Distribution="${buffer[1]}"

  buffer=( $(lsb_release -r ) )
  Release="${buffer[1]}"

  #  See Parameter Expansion section of Bash man page for "%%"'s' Remove matching suffix pattern
  #  behavior (https://linux.die.net/man/1/bash)

  buffer=( $(g++ --version ) )
  gccVersion="${buffer[3]%%.*}"

  # This is pretty fragile, but version 10 and 12 display the version slightly differently
  buffer=( $(clang++ --version ) )
  if [[ ${buffer[1],,} = "version" ]]; then
    clangVersion="${buffer[2]%%.*}"
  elif [[ ${buffer[2],,} = "version" ]]; then
    clangVersion="${buffer[3]%%.*}"
  fi


  # ${parameter,,} ==> lower case
  # ${parameter^^} ==> upper case

  if [[ "${Distribution,,}" = "ubuntu"  &&  "${Release,,}" = "20.04" ]]; then
    if [[ "${gccVersion,,}" -lt "${RequiredGccVersion,,}"  ||  "${clangVersion,,}" -lt "${RequiredClangVersion,,}" ]]; then

      echo -e "\nGCC version ${RequiredGccVersion} and Clang version ${RequiredClangVersion} are required, but you're using GCC version ${gccVersion} and Clang version ${clangVersion}\n\nWould like to upgrade now?  This may require a system reboot. (yes or no)"
      read shall_I_upgrade

      if [[ "${shall_I_upgrade,,}x" = "yesx"  ||  "${shall_I_upgrade,,}x" = "yx" ]]; then
        echo -e "\nUpgrading could be a long and extensive process.\n\n ****  Make sure you have backups of all your data!\n\n Are you really sure?"
        read shall_I_upgrade
        if [[ "${shall_I_upgrade,,}x" = "yesx"  ||  "${shall_I_upgrade,,}x" = "yx" ]]; then

          echo -e "Yes.  Okay, attempting to upgrade now.  The upgrade requires super user privileges and you may be prompted for your password.\n"

          sudo /bin/bash -svx -- <<-"EOF"   # the "-" after the "<<" allow leading tabs (but not spaces), the quoted EOF means literal input, i.e., do not substitute parameters

						# Move gcc 9 and clang 10 to gcc 11 and clang 12 on Ubuntu 20.04 LTS

						# Someday, Ubuntu 20.04 standard packages will be updated to include the new versions, but for now ...
						add-apt-repository -y ppa:ubuntu-toolchain-r/test

						apt -y update
						apt -y upgrade

						apt -y install gcc-11 g++-11
						update-alternatives  --install /usr/bin/gcc gcc /usr/bin/gcc-11 11  --slave /usr/bin/g++         g++         /usr/bin/g++-11        \
																																								--slave /usr/bin/gcc-ar      gcc-ar      /usr/bin/gcc-ar-11     \
																																								--slave /usr/bin/gcc-nm      gcc-nm      /usr/bin/gcc-nm-11     \
																																								--slave /usr/bin/gcc-ranlib  gcc-ranlib  /usr/bin/gcc-ranlib-11 \
																																								--slave /usr/bin/gcov        gcov        /usr/bin/gcov-11       \
																																								--slave /usr/bin/gcov-dump   gcov-dump   /usr/bin/gcov-dump-11  \
																																								--slave /usr/bin/gcov-tool   gcov-tool   /usr/bin/gcov-tool-11

						update-alternatives  --install /usr/bin/gcc gcc /usr/bin/gcc-9   9  --slave /usr/bin/g++         g++         /usr/bin/g++-9         \
																																								--slave /usr/bin/gcc-ar      gcc-ar      /usr/bin/gcc-ar-9      \
																																								--slave /usr/bin/gcc-nm      gcc-nm      /usr/bin/gcc-nm-9      \
																																								--slave /usr/bin/gcc-ranlib  gcc-ranlib  /usr/bin/gcc-ranlib-9  \
																																								--slave /usr/bin/gcov        gcov        /usr/bin/gcov-9        \
																																								--slave /usr/bin/gcov-dump   gcov-dump   /usr/bin/gcov-dump-9   \
																																								--slave /usr/bin/gcov-tool   gcov-tool   /usr/bin/gcov-tool-9

						apt -y install clang-12 clang-tools-12 clang-12-doc libclang-common-12-dev libclang-12-dev libclang1-12 clang-format-12 clang-tidy-12 python3-clang-12 clangd-12
						apt -y install lldb-12 lld-12
						apt -y install libc++-12-dev libc++abi-12-dev
						apt -y autoremove

						update-alternatives  --install /usr/bin/clang clang /usr/bin/clang-12 12  --slave /usr/bin/clang++            clang++            /usr/bin/clang++-12              \
																																											--slave /usr/bin/clang-format       clang-format       /usr/bin/clang-format-12         \
																																											--slave /usr/bin/clang-format-diff  clang-format-diff  /usr/bin/clang-format-diff-12    \
																																											--slave /usr/bin/clang-tidy         clang-tidy         /usr/bin/clang-tidy-12           \
																																											--slave /usr/bin/clang-tidy-diff    clang-tidy-diff    /usr/bin/clang-tidy-diff-12.py

						update-alternatives  --install /usr/bin/clang clang /usr/bin/clang-10 10  --slave /usr/bin/clang++            clang++            /usr/bin/clang++-10              \
																																											--slave /usr/bin/clang-format       clang-format       /usr/bin/clang-format-10         \
																																											--slave /usr/bin/clang-format-diff  clang-format-diff  /usr/bin/clang-format-diff-10    \
																																											--slave /usr/bin/clang-tidy         clang-tidy         /usr/bin/clang-tidy-10           \
																																											--slave /usr/bin/clang-tidy-diff    clang-tidy-diff    /usr/bin/clang-tidy-diff-10.py
						sudo update-alternatives --auto gcc
						sudo update-alternatives --auto clang

						EOF

        exit

        fi # upgrade? 2
      fi  # upgrade? 1

      echo -e "No.  Okay, but your program may not compile, link, or execute properly\n"
    fi  # gccVersion || clangVersion
  fi  # Distribution && Release
}



CheckVersion

#
# Script file to compile all C++ source files in or under the
# current directory.  This has been used in the OpenSUSE and Ubuntu
# environments with the GCC and Clang compilers and linkers
executableFileName="${1:-project}"

# Find and display all the C++ source files to be compiled ...
# temporarily ignore spaces when globing words into file names
temp=$IFS
  IFS=$'\n'
  sourceFiles=( $(find ./ -name "*.cpp") ) # create array of source files
IFS=$temp

echo "compiling ..."
for fileName in "${sourceFiles[@]}"; do
  echo "  $fileName"
done
echo ""


#define options
GccOptions="  -Wall -Wextra -pedantic        \
              -Wdelete-non-virtual-dtor      \
              -Wduplicated-branches          \
              -Wduplicated-cond              \
              -Wextra-semi                   \
              -Wfloat-equal                  \
              -Winit-self                    \
              -Wlogical-op                   \
              -Wnoexcept                     \
              -Wnon-virtual-dtor             \
              -Wold-style-cast               \
              -Wstrict-null-sentinel         \
              -Wsuggest-override             \
              -Wswitch-default               \
              -Wswitch-enum                  \
              -Woverloaded-virtual           \
              -Wuseless-cast                 "

#             -Wzero-as-null-pointer-constant"


ClangOptions=" -stdlib=libc++ -Weverything        \
               -Wno-comma                         \
               -Wno-unused-template               \
               -Wno-sign-conversion               \
               -Wno-exit-time-destructors         \
               -Wno-global-constructors           \
               -Wno-missing-prototypes            \
               -Wno-weak-vtables                  \
               -Wno-padded                        \
               -Wno-double-promotion              \
               -Wno-c++98-compat-pedantic         \
               -Wno-c++11-compat-pedantic         \
               -Wno-c++14-compat-pedantic         \
               -Wno-c++17-compat-pedantic         \
               -fdiagnostics-show-category=name   \
                                                  \
               -Wno-zero-as-null-pointer-constant \
               -Wno-ctad-maybe-unsupported        "

CommonOptions="-g0 -O3 -DNDEBUG -pthread -std=c++20 -I./ -DUSING_TOMS_SUGGESTIONS -D__func__=__PRETTY_FUNCTION__"




ClangCommand="clang++ $CommonOptions $ClangOptions"
echo $ClangCommand
clang++ --version
if $ClangCommand -o "${executableFileName}_clang++.exe"  "${sourceFiles[@]}"; then
  echo -e "\nSuccessfully created  \"${executableFileName}_clang++.exe\""
else
  exit 1
fi

echo ""

GccCommand="g++ $CommonOptions $GccOptions"
echo $GccCommand
g++ --version
if $GccCommand  -o "${executableFileName}_g++.exe"  "${sourceFiles[@]}"; then
   echo -e "\nSuccessfully created  \"${executableFileName}_g++.exe\""
else
   exit 1
fi
