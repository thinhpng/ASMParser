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
my $smlDir = ".\\Sml\\"; #where the interested mes logs are stored to analyze
say"smlDir: $smlDir";
find (\&CreateConvertedEventXpFomCustomData,$smlDir);

sub CreateConvertedEventXpFomCustomData()
{
    my $myfile = $_;
    if (-f $myfile && $myfile =~ /S2F33.txt/i){
        say("Got it : ", $myfile);
        open(INFILE, "$myfile") || die "ERROR! Can't open $myfile\n";
        my @bucket = <INFILE>;
        close(INFILE) || die "ERROR! Can't close $myfile\n";

        pop(@bucket);
        pop(@bucket);
        pop(@bucket);

        my $count = 0;
        foreach my $line_str (@bucket) {
            if($line_str =~ /\tList \(1\)   2/){
                say $count++, " : $line_str";
            }

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