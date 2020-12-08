################################################################################
# This script is written by Thinh Nguyen @ASM
# It's used to create sml message which can be used with SecSimPro+
################################################################################
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
my $smlDir = "C:\\ASM-Host\\Config\\ALD\\Sml Files\\"; #where the interested mes logs are stored to analyze
say"smlDir: $smlDir";

my $libSource = $smlDir . 'ConvertedEventXp.txt';
say "CEID's libSource: $libSource";
#We need to build CEID dictionary to transform the ids to names
open (INFILE, "$libSource") || die "ERROR! Can't open $libSource\n";
my @libBucket = <INFILE>;
close(INFILE) || die "ERROR! Can't close $libSource\n";
my %ceidDict;
foreach my $line_str (@libBucket) {
    #skip all the comments or blank lines
    next if (($line_str =~ /^#/) || ($line_str =~ /^$/));
    #print "line_str=$line_str\n";
    #chomp($line_str);
    if ($line_str =~ /^(\d+)\s+(.*)/i) {
        $ceidDict{$1} = $2;
        #        print"Ceid: $1\n";
        #        print"Name: $2\n";
    }elsif ($line_str =~ /^CEID\s+:\s+(\$.*)\s+:\s+(\d+)\s+:\s+(.*?)\s+:/i){
        #say ("CEID: $2 = $3");
        $ceidDict{$2} = $3;
    }
}

$libSource = $smlDir . 'VIDsOnlyFromHostLog.txt';
say "VID's libSource: $libSource";
#We need to build CEID dictionary to transform the ids to names
open (INFILE, "$libSource") || die "ERROR! Can't open $libSource\n";
@libBucket = <INFILE>;
close(INFILE) || die "ERROR! Can't close $libSource\n";
my %vidDict;
foreach my $line_str (@libBucket) {
    #skip all the comments or blank lines
    next if (($line_str =~ /^#/) || ($line_str =~ /^$/));
    #print "line_str=$line_str\n";
    #chomp($line_str);
    if ($line_str =~ /^(\d+)\s+(.*)/i) {
        $vidDict{$1} = $2;
        #        print"Ceid: $1\n";
        #        print"Name: $2\n";
    }elsif ($line_str =~ /^VID\s+:\s+(\$.*)\s+:\s+(\d+)\s+:\s+(.*?)\s+:/i){
        #say ("VID: $2 = $3");
        $vidDict{$2} = $3;
    }
}

find (\&CreateSml,$smlDir);

sub CreateSml()
{
    my $myfile = $_;
    if ($myfile =~ /(S\d+F\d+)\.(sml)/i){;
    }elsif (-T $myfile){
        say("Got it : ", $myfile);
        $myfile =~ /(S\d+F\d+)\.(txt)/i;
        my $fileName = $1;
        my $fileExt = $2;
        my $first = 1;
        my $count = 0;

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
            my $sec;
            my @VIDS;

            say "fileName: $fileName - streamCmd: $streamCmd";
            push(@secs, $streamCmd);
            foreach my $line_str (@bucket) {
                #skip all the comments or blank lines
                #            say("line = ", $line_str);
                $line_str =~ /^(\s*)(\w+)\s*\(\d+\)\s+(\d+)\s*.*?:*(.*)/i;
                $space = $1;
                my $dataType = $2;
                $size = $3;
                my $value = $4;

                #            say("size: ", $size);
#                            say("value: ", $value);
#                            say("Data Type: ", $dataType);
                switch($dataType){
                    case "List" {
                        if ($first == 1) {
                            $first = 0;
                            $sec = $space . "<L \n";
                        }elsif ($size == 0) {
                            $first = 0;
                            $sec = $space . "<L >\n";
                        }else{
                            $sec = $space . "<" . $dataType . ">\n";
                            $count++;
                        }
                    }
                    case "Truth" {
                        $dataType = "<BOOLEAN ";
                        if($value eq "FF" || $value eq "01"){
                            $value = "0x1";
                        }
                        else{
                            $value = "0x0";
                        }
                        $sec = $space . $dataType . "'" . $value . "'>\n";
                    }
                    case "Ascii" {
                        $dataType = "<A ";
                        $sec = $space . $dataType . "'" . $value . "'>\n";
                    }
                    case "UInt1" {
                        $dataType = "<U1 ";
                        $value =~ s/\s+\(\d+\w+\)//;
                        $sec = $space . $dataType . $value . ">\n";
                    }
                    case "UInt2" {
                        $dataType = "<U2 ";
                        $value =~ s/\s+\(\d+\w+\)//;
                        $sec = $space . $dataType . $value . ">\n";
                    }
                    case "UInt4" {
                        if ($value =~/(\d{5,})\s(.*)/){
                            say "value: $value : $1";
                            push(@VIDS, $1, "\n");
                        }

                        $dataType = "<U4 ";
                        $value =~ s/\s+\(\d+\w+\)//;
                        $sec = $space . $dataType . $value . ">\n";

                        if($fileName eq "S2F33"){
                            if(exists $vidDict{$value} && defined $vidDict{$value}){
                                $sec = $space . $dataType . $value . "> /* " . $vidDict{$value} . " */\n";
                                #say "sec : $sec ";
                            }
                        }elsif($fileName eq "S2F35" || $fileName eq "S2F37"){
                            if(exists $ceidDict{$value} && defined $ceidDict{$value}){
                                $sec = $space . $dataType . $value . "> /* " . $ceidDict{$value} . " */\n";
                                #say "sec : $sec ";
                            }
                        }
                    }
                    case "Byte" {
                        $dataType = "<B ";
                        $value =~ s/\s+\(\d+\w+\)//;
                        $sec = $space . $dataType . $value . ">\n";
                    }
                }
                if($sec){
                    push(@secs, $sec);
                }
            }
            push(@secs, ">\n");
            for(my $i = 0; $i < $count; $i++){
                @secs = endList(reverse @secs);
            }

            my $outFile = $fileName . ".sml";
            say("outFile: ", $outFile);
            open(OUTFILE, ">:encoding(UTF-8)", $outFile) || die "ERROR! Can't open $outFile";
            print OUTFILE @secs;
            close(OUTFILE) || die "ERROR! Can't close $outFile";

            $outFile = "VIDS.txt";
            say("outFile: ", $outFile);
            open(OUTFILE, ">:encoding(UTF-8)", $outFile) || die "ERROR! Can't open $outFile";
            print OUTFILE @VIDS;
            close(OUTFILE) || die "ERROR! Can't close $outFile";
        }
    }
}

sub endList{
    my @result = "";
    my $listSpace = "NA";

    while(@_){
        my $data = pop(@_);
        $data =~ /^(\s*)(.*)/gi;
        my $sp = $1;
        my $dt = $2;
#        say("data:", $data);
        if ($dt eq "<List>" && $listSpace eq "NA"){
            $listSpace = $sp;
            $data = $listSpace . "<L \n";
#            say("------------------- First");
        }elsif (length($listSpace) > length($sp) && $listSpace ne "NA"){
            $dt = $listSpace . ">\n";
            push(@result, $dt);
            $listSpace = "NA";
#            say("------------------- Got 1");
        }elsif ($dt eq ">" && $listSpace ne "NA"){
            $dt = $listSpace . ">\n";
            $data = $data . $dt;
#            push(@result, $dt);
            $listSpace = "NA";
#            say("------------------- Got 2");
        }elsif ($listSpace eq $sp && $listSpace ne "NA"){
            $dt = $sp . ">\n";
            push(@result, $dt);
            if ($dt ne "<List>"){
                $listSpace = "NA";
            }
#            say("------------------- Got 3");
        }

        push(@result, $data);
    }

    return(@result);
}