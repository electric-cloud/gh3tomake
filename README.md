# gh3tomake
PERL script to convert Green Hills 3.1 .BLD build definition files to Makefiles.

########
# This converter takes Green Hills 3.x .BLD build definition files and converts them into makefiles
# that can be run with emake. It does so by first running a build and capturing all the commands
# that are issued to complete the build. It then parses those commands to create targets in the
# desired makefile. The name of the .bld file is mandatory as the first argument. The default
# output file is "Makefile" but can be optionally specified as the second argument.
#######
# v1.0 - Juan Jimenez - 3/13/15
#               Initial version
# v1.1 - Juan Jimenez - 3/24/15
#               Modified to handle 'cat xxx' conditions in command lines
# v1.2 - Juan Jimenez - 4/14/15
#               Modified to leave dblink steps out of the makefile and let build do them.
#               Modified to add SHELL=CMD.EXE to allow gmake --win32 to run the makefile.
#               Added clean target to call build -clean
# v1.3 - Juan Jimenez - 4/21/15
#               Modified to remove execution of deletion of temp files
#               Modified to handle UNIT.MAP as cause of serialization
# v1.4 - Juan Jimenez - 4/24/15
#               Incorporates changes made by Zach at Raytheon
#               Modified final step to let build.exe do both link and dblink.
#######

#########
# Usage
#########

Copyright (c) 2015 by Electric Cloud, Inc. All rights reserved.
usage:  gh3tomake [input] [output]
        where:  [input] is the Green Hills 3.x build file to convert (defaults to 'default.bld')
                [output] is the optional name of the output makefile (defaults to 'Makefile')
