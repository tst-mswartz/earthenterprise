#!/usr/bin/perl -w-
#
# Copyright 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


use FindBin qw($Bin $Script);
use File::Basename;
use Cwd 'abs_path';
use strict;
use warnings;

# This script should be run from NATIVE-*-x86_64/bin/tests
my $scriptDir = dirname(abs_path($0));
if ($scriptDir !~ /NATIVE-[a-zA-Z0-9_-]*\/bin\/tests$/) {
    print "This script should be run from <build_dir>/bin/tests.\n";
    print "<build_dir> is usually something like NATIVE-REL-x86_64.\n";
    exit;
}
chdir($scriptDir);

# open an output file, cannot have "test" (lowercase) in its name
my $logfile = "$scriptDir/Output.xml";
open(my $fh, '>', $logfile) or die $!;

# Add path to build binary directory for searching executables (ogr2ogr,
# gdal_rasterize,...) used in tests.
$ENV{'PATH'} = join ":", "..", $ENV{'PATH'};

my @tests = glob("./*test*");

my $longest = 0;
foreach my $test (@tests) {
    my $basename = basename($test);
    next if $basename eq $Script;
    if (length($basename) > $longest) {
        $longest = length($basename);
    }
}

#xml headers
print $fh "<?xml version=\"1.0\" ?>\n";
print $fh "<testsuites>\n";

$| = 1;
my $result = 0;

#for each file with the word "test" in its name in the current directory
foreach my $test (@tests) {
    my $basename = basename($test);
    next if $basename eq $Script;
    print "Running $basename ... ", ' 'x($longest-length($basename));

    #set up xml tags for this file
    my $testsuite = "\t<testsuite ";
    my $stdout_data = "\t\t\t<system-out>\n";
    my $stderr_data = "\t\t\t<system-err>\n";
    my $test_count = 0;
    my $failed = 0;
    my $test_output = "";
    my @testcases;

    if (open(OUTPUT, "$test 2>&1 |")) {
        my @output;
        while (<OUTPUT>) {
            my $line = $_;
            $test_output .= $line;

            #there are a lot of these from some of the test files and we don't care about them
            if ($line =~ /^Fusion Notice:/) {
              next;
            }

            #is this a test case with an individual result?
            if ($line =~ /OK|succeeded|FAILED/i && $line !~ /[0-9]+ of [0-9]+/) {
              $test_count++;
              my $ms = 0.0;

              #count failures
              if($line =~ /FAILED/) {
                $failed++;
              }

              #capture the test name from successes, which come in 2 different formats
              $line =~ s/^\[.+\]\s+//; 
              if ($line =~ /^(\[.+\]\w+)?(\w+)(\s+succeeded)$/) { 
                $line = $2;
              }
              elsif ($line =~ /(.+)\s+\((\d+)\s+ms\).*$/) {
                $line = $1;
                $ms = $2;
              }

              #find class name if possible 
              my $classname = $line;
              my $testname = $line;
              if($line =~ /(\w+)\.(\w+)/) {
                $classname = $1;
                $testname = $2;
              }
              $ms *= 0.001;
              push(@testcases, "\t\t<testcase classname=\"$classname\" name=\"$testname\" time=\"$ms\">\n");
            }

            #save test output in case we are logging a failure
        }
        if (close(OUTPUT)) {
            $testsuite .= "errors=\"0\" failures=\"$failed\" "; #FIXME  count errors 
            print "SUCCEEDED\n";
        } else {
            $testsuite .= "errors=\"$failed\" failures=\"$failed\" "; #FIXME count errors 
            $stderr_data .= "\n________________\nFAILED\n________________\n";
            $result = 1;
            print "FAILED\n";
            print "----------\n";
            print @output;
            print "----------\n";
        }
    } else {
        $stderr_data .= "FAILED to launch\n";
        $testsuite .= "errors=\"1\" failures=\"1\"";
        $failed = 1;
        print "FAILED to launch\n";
    }

    #if we didn't count any subtests, this should not be 0
    if($test_count == 0) {
      $test_count = 1;
    }

    ### print xml for the test file we just ran 
    $testsuite .= " name=\"$basename\" tests=\"$test_count\">\n";
    $stdout_data .= $test_output;
    $stdout_data .= "\n\t\t\t</system-out>\n";

    #if there was a failure, save the output in the stderr-data xml block
    if($failed > 0) {
      $stderr_data .= $test_output;
    }
    $stderr_data .= "\n\t\t\t</system-err>\n";

    print $fh $testsuite;

    #print xml for each testcase inside this testsuite 
    foreach my $testcase (@testcases) { 
      print $fh $testcase;
      print $fh $stdout_data;
      print $fh $stderr_data;
      print $fh "\t\t</testcase>\n";
    }
    print $fh "\t</testsuite>\n";
}

#close the top level xml tag
print $fh "</testsuites>\n";
close($fh);

exit $result;
