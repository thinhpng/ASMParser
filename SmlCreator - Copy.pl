#!/usr/bin/perl
use strict;
use Win32::File;
use File::Path;
use File::Find;
use warnings FATAL => 'all';
use Date::Parse;
use POSIX qw{strftime};
use feature qw(say);
use Switch;

say"Start SmlCreator ...";
my $smlDir = ".\\Sml\\"; #where the interested mes logs are stored to analyze
say"smlDir: $smlDir";
find (\&CreateSml,$smlDir);

sub CreateSml()
{
    my $myfile = $_;
    if (-T $myfile){
        say("Got it : ", $myfile);
        $myfile =~ /(S\d+F\d+)\.(txt)/i;
        my $fileName = $1;
        my $fileExt = $2;

        if(!$fileName || !$fileExt){
            say($myfile, " is not qualified ! Your file name should be in the format of SxFx.txt");
        }else {
            my $streamCmd = $fileName . " W\n";
            open(INFILE, "$myfile") || die "ERROR! Can't open $myfile\n";
            my @bucket = <INFILE>;
            close(INFILE) || die "ERROR! Can't close $myfile\n";
            my $size = -1;
            my @listTracker;
            my @spaces;
            my $space;
            my @secs;
            say($streamCmd);
            push(@secs, $streamCmd);
            foreach my $line_str (@bucket) {
                next if($line_str =~/^$/);
                #skip all the comments or blank lines
                #            say("line = ", $line_str);
                #say($line_str, "|line");
                $line_str =~ /^(\s*)(\w+)\s*\(\d+\)\s+(\d+)\s*.*?:*(.*)/i;
                $space = $1;
                say($space, "|space");
                my $dataType = $2;
                my $value = $4;
                #            say("size: ", $size);
                #            say("value: ", $value);
                #            say("Data Type: ", $dataType);
                if($dataType){
                    switch($dataType){
                        #say("size: ", $size);
                        case "List" {
                            if ($size > 0) {
                                push(@listTracker, $size);
                                $size = $3;
                                push(@spaces, $space);
                            }
                            elsif ($size == 0) {
                                $space = pop(@spaces);
                                say($space, ">");
                                push(@secs, $space, ">\n");
                                $size = pop(@listTracker);
                                if ($size == 1) {
                                    $space = pop(@spaces);
                                    say($space, ">");
                                    push(@secs, $space, ">\n");
                                    $size = pop(@listTracker);
                                    $size--;
                                    push(@listTracker, $size);
                                    $size = $3;
                                    #push(@spaces, $space);
                                }
                                $space = pop(@spaces);
                                push(@secs, $space, ">\n");
                            }else {
                                $size = $3;
                                push(@spaces, $space);
                            }
                            say("size: ", $size);
                            $dataType = "<L ";
                            say($space, $dataType);
                            if ($size == 0) {
                                push(@secs, $space, $dataType, ">\n");
                                $space = pop(@spaces);

                                $size = pop(@listTracker);
                                $size--;
                                say($space,"size: ", $size);
                                if ($size == 0) {
                                    push(@secs, $space, ">\n");
                                }
                            }elsif($size < 0){
                                push(@secs, $space, $dataType, ">\n");
                            }else{
                                push(@secs, $space, $dataType, "\n");
                            }




                        }
                        case "Truth" {
                            $dataType = "<BOOLEAN ";
                            $size--;
                            if($value eq "FF"){
                                $value = "0x1";
                            }
                            else{
                                $value = "0x0";
                            }
                            say($space, $dataType, "'", $value, "'>");
                            push(@secs, $space, $dataType, "'", $value, "'>\n");
                        }
                        case "Ascii" {
                            $dataType = "<A ";
                            $size--;
                            say($space, $dataType, "'", $value, "'>");
                            push(@secs, $space, $dataType, "'", $value, "'>\n");
                        }
                        case "UInt1" {
                            $dataType = "<U1 ";
                            $size--;
                            $value =~ s/\s+\(\d+\w+\)//;
                            say($space, $dataType, $value, ">");
                            push(@secs, $space, $dataType, $value, ">\n");
                        }
                        case "UInt2" {
                            $dataType = "<U2 ";
                            $size--;
                            $value =~ s/\s+\(\d+\w+\)//;
                            say($space, $dataType, $value, ">");
                            push(@secs, $space, $dataType, $value, ">\n");
                        }
                        case "UInt4" {
                            $dataType = "<U4 ";
                            $size--;
                            $value =~ s/\s+\(\d+\w+\)//;
                            say($space, $dataType, $value, ">");
                            push(@secs, $space, $dataType, $value, ">\n");
                        }
                        case "Byte" {
                            $dataType = "<B ";
                            $size--;
                            $value =~ s/\s+\(\d+\w+\)//;
                            say($space, $dataType, $value, ">");
                            push(@secs, $space, $dataType, $value, ">\n");
                        }
                    }

                }
            }

            foreach $space (reverse @spaces) {
                say($space, ">");
                push(@secs, $space, ">\n");
            }

            my $outFile = $fileName . ".sml";
            say("outFile: ", $outFile);
            open(OUTFILE, ">:encoding(UTF-8)", $outFile) || die "ERROR! Can't open $outFile";
            print OUTFILE @secs;
            close(OUTFILE) || die "ERROR! Can't close $outFile";
        }
    }
}
