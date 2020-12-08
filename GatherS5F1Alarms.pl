################################################################################
# This script is written by Thinh Nguyen @ASM
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

say"Start GatherS5F1Alarms ...";
my $logDir = ".\\Logs\\"; #where the interested logs are stored to analyze
my @alarms;
my @mesLogs;
find (\&gatherLogs,$logDir);
@mesLogs = sort {$a cmp $b} @mesLogs;
my @logData;
foreach my $logFile (@mesLogs){
    say"sorted : $logDir$logFile";
    open (INFILE, "$logDir$logFile") || die "ERROR! Can't open $logFile\n";
    my @bucket = <INFILE>;
    close(INFILE) || die "ERROR! Can't close $logFile\n";
    push(@logData,@bucket);
}

my @logBucket = @logData;
my $alarm = "";

for(my $count = 0; $count < @logBucket; $count++) {
    my $line_str = $logBucket[$count];
    next if (($line_str =~ /^#/) || ($line_str =~ /^$/));
    if ($line_str =~ /^(S5F1\s*,\s*.*\s*,\s*).*,.*,.*/i) {
        $alarm = $1;
    }else{
        if ($alarm) {
            if ($line_str =~ /^40:\s+(.*)/i) {
                my $info = $alarm . $1 . "\n";
                say("info: ", $info);
                $alarm = "";
                push(@alarms, $info);
            }
        }
    }
}

#@alarms = removeDuplicate(@alarms);

my $outFile = $logDir . "Alarms.txt";
say("outFile: ", $outFile);
open(OUTFILE, ">:encoding(UTF-8)", $outFile) || die "ERROR! Can't open $outFile";
print OUTFILE @alarms;
close(OUTFILE) || die "ERROR! Can't close $outFile";

sub gatherLogs() {
    my $currfname = $_ ; #$File::Find::name; #$_;
    if($currfname =~/MCIF_\d+(.txt)/i){
        push(@mesLogs,$currfname);
    }
}

sub removeDuplicate{
    my %unique = ();
    foreach my $item (@_)
    {
        $unique{$item} ++;
    }
    my @myuniquearray = keys %unique;
    return(@myuniquearray);
}

