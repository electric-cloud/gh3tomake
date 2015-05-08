#!/usr/bin/perl
use warnings;
# use strict;
use v5.10;

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

if ((exists $ARGV[0]) && ($ARGV[0] eq '--help')) {
        say "GH3ToMake v1.4: Converts Green Hills 3 Build files to Makefiles";
        say "Copyright (c) 2015 by Electric Cloud, Inc. All rights reserved.";
        say "usage:\tgh3tomake [input] [output]";
        say "where:\t[input] is the Green Hills 3.x build file to convert (defaults to 'default.bld')";
        say "      \t[output] is the optional name of the output makefile (defaults to 'Makefile')";
        exit;
}

########
# Check to see if the build file specified, if not, use default.bld
########

my $inputBuildFile = shift || "default.bld";

########
# Check to see if input file exists
########

if (! -e $inputBuildFile) {
        die "Build file ".$inputBuildFile." does not exist.\n";
}
########
# Process the build file with BUILD.EXE to produce the dry run log.
########

say "Dry-running the build file ".$inputBuildFile." to create intermediate commands file.";
my $random = rand 1000000;
my $tempfile = 'OUT'.$random.'.TMP';
my $cmdline = 'build.exe -commands -info '.$inputBuildFile.' > '.$tempfile;
if (system $cmdline) {
        die "Failed to execute build file dry run.\n";
} 

########
# Open the intermediate file
########

open (TMPFILE, $tempfile) or die "Cannot open intermediate file.\n";
Juans-MBP-2:Green Hills jjimenez$ cat gh3tomake.pl
#!/usr/bin/perl
use warnings;
# use strict;
use v5.10;

########
# This converter takes Green Hills 3.x .BLD build definition files and converts them into makefiles
# that can be run with emake. It does so by first running a build and capturing all the commands
# that are issued to complete the build. It then parses those commands to create targets in the
# desired makefile. The name of the .bld file is mandatory as the first argument. The default
# output file is "Makefile" but can be optionally specified as the second argument.
#######
# v1.0 - Juan Jimenez - 3/13/15
#		Initial version
# v1.1 - Juan Jimenez - 3/24/15
#		Modified to handle 'cat xxx' conditions in command lines
# v1.2 - Juan Jimenez - 4/14/15
#		Modified to leave dblink steps out of the makefile and let build do them.
#		Modified to add SHELL=CMD.EXE to allow gmake --win32 to run the makefile.
#		Added clean target to call build -clean
# v1.3 - Juan Jimenez - 4/21/15
#		Modified to remove execution of deletion of temp files
#		Modified to handle UNIT.MAP as cause of serialization
# v1.4 - Juan Jimenez - 4/24/15
#		Incorporates changes made by Zach at Raytheon
#		Modified final step to let build.exe do both link and dblink.
#######

#########
# Usage
#########

if ((exists $ARGV[0]) && ($ARGV[0] eq '--help')) {
	say "GH3ToMake v1.4: Converts Green Hills 3 Build files to Makefiles";
	say "Copyright (c) 2015 by Electric Cloud, Inc. All rights reserved.";
	say "usage:\tgh3tomake [input] [output]";
	say "where:\t[input] is the Green Hills 3.x build file to convert (defaults to 'default.bld')";
	say "      \t[output] is the optional name of the output makefile (defaults to 'Makefile')";
	exit;
}

########
# Check to see if the build file specified, if not, use default.bld
########

my $inputBuildFile = shift || "default.bld";

########
# Check to see if input file exists
########

if (! -e $inputBuildFile) {
	die "Build file ".$inputBuildFile." does not exist.\n";
}
########
# Process the build file with BUILD.EXE to produce the dry run log.
########

say "Dry-running the build file ".$inputBuildFile." to create intermediate commands file.";
my $random = rand 1000000;
my $tempfile = 'OUT'.$random.'.TMP';
my $cmdline = 'build.exe -commands -info '.$inputBuildFile.' > '.$tempfile;
if (system $cmdline) {
	die "Failed to execute build file dry run.\n";
} 

########
# Open the intermediate file
########

open (TMPFILE, $tempfile) or die "Cannot open intermediate file.\n";

########
# If there is an output file specified, try to open that,
# otherwise open the default Makefile.
########

my $makefile = shift || 'Makefile';
open (MAKEFILE, '>', $makefile) or die "Cannot open output file ".$makefile.": $!.\n";

########
# Start processing the input file
########

say 'Discovering targets.';
my $targetcount = 0;		# init index into targets array
my @accum = ();			# init array to store targets to be output
my $doadareg = 0;		# true if this is an ADA build
my $unitmap_handling = 0;	# true if we have to do the UNIT.MAP fandango

while(<TMPFILE>) {
	chomp;
	# If it's an rm command to delete a file, skip it.
	if (! /^rm \-f/) {
		# replace any -$ with -$$
		s/\-\$/\-\$\$/g;
		if (/adareg/) {
			$doadareg = 1;
			$unitmap_handling = 1;
		}
		# check to see if we have a 'cat xxx' in the line, if so, replace it with 
		# an inline call to $(shell type filename.ext)
		if (/^\t`cat\s(.+)`/) {
			s/^\t`cat\s(.+)`/\t\$(shell type $1)/g;
		}
		# is this a line with a continuation slash? handle it accordingly
		if (s%(.*?)\\$% %){ 
			if (($doadareg == 0) && ($unitmap_handling == 1) && (! $accum[$targetcount])) {
				$accum[$targetcount] = "copy UNIT-ORIG.MAP UNIT.MAP && ";
			}
       	 		$accum[$targetcount] .= $1."\\\n";
		} else {
			if ($doadareg == 1) {
				$accum[$targetcount] .= $_." && del UNIT-ORIG.MAP && ren UNIT.MAP UNIT-ORIG.MAP \n";
				$doadareg = 0;
			}
			elsif (($unitmap_handling == 1) && (! /^move/)) {
				$accum[$targetcount] .= $_." && del /F UNIT.MAP \n";
			}
       	 		else {
				$accum[$targetcount] .= $_."\n";
			}      
 	 		$targetcount++;         
    	}
	}
}

say "Total targets identified: ".($targetcount-1);
say "Writing targets to file: $makefile.";

########
# Output the header comment + all: followed by the # of targets for dependency,
# followed by each target and the recipe. link ans dblink steps are skipped, as well as the
# step that deletes dblink temporary files. build is called at the end to take care of
# the final linking, in runlocal mode.
########

print MAKEFILE "# Produced by GH3ToMake v1.4 from build file: ".$inputBuildFile."\n\nSHELL=CMD.EXE\n\nall: ";

for ($i = 0; $i < $targetcount; $i++){
	$_ = $accum[$i];
	if (! /link\.exe/) {
		print MAKEFILE "t".$i." ";
	} else {
		$i++;
	}
}
print MAKEFILE "final\n\n";
print MAKEFILE "clean:\n\tbuild.exe -clean ".$inputBuildFile."\n\n";
for ($i = 0; $i < $targetcount; $i++) {
	$_ = $accum[$i];
	if (! /link\.exe/) {
		print MAKEFILE "t".$i.":\n\t";
		print MAKEFILE $accum[$i]."\n\n";
	} else {
		$i++;
	}
}
print MAKEFILE "#pragma runlocal\nfinal:\n\tcopy UNIT-ORIG.MAP UNIT.MAP && build.exe ".$inputBuildFile."\n\n";

########
# Close the files, delete the intermediate file
########

close MAKEFILE or warn "Could not close the output file.";
close TMPFILE or warn "Could not close the intermediate file.";
unlink $tempfile or warn "Could not delete the intermediate file.\n";

print "Conversion complete.\n";
exit(0);
