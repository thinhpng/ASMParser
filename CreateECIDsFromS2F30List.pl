#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use POSIX qw{strftime};
use feature qw(say);
binmode STDIN, ":encoding(UTF-8)";
binmode STDOUT, ":encoding(UTF-8)";
$SIG{'INT'} = 'Terminate'; #'IGNORE'; #'Terminate';
#local $\ = "\n";
#my $logDir = ".\\Logs\\"; #where the interested mes logs are stored to analyze
#my $datestring = gmtime();
#
#say "Start Tester... $datestring";
#my $one = " ";
#my $two = "  ";
#if ($one eq $two){
#    say"same";
#}else{
#    say"no";
#}

#my $libDir = ".\\Lib\\";
#my $vidFile = "";
#find(sub {
#    if ($_ =~ /Online SECS ID List.csv/ig) {
#        $vidFile = $_; #$File::Find::name; #$_;
#    }
#}, $libDir);
#if ($vidFile eq "") {
#    die "Missing the Online SECS ID List.csv file";
#}
#say "Resource file is $vidFile";
#open(INFILE, $libDir . $vidFile) || die "ERROR! Can't open $vidFile";
#my @vidBucket = <INFILE>;
#close(INFILE) || die "ERROR! Can't close $vidFile";
#
#my $lineNumber = 0;
#my $lastVidLineNumber = 0;
#my @update;
#my $temp = "";

#foreach my $line_str (@vidBucket) {
#    $lineNumber++;
#    #my $test = "line:".$lineNumber."->".$line_str;
#    #push(@update, $test);
#    if ($line_str =~/[^[:ascii:]]+/g){
#        say$line_str;
##        my $remark = $vidBucket[$lineNumber+1];
##        $remark =~s/[^[:ascii:]]+/=/g;
##        say$remark;
##        $remark = $vidBucket[$lineNumber+2];
##        $remark =~s/[^[:ascii:]]+/=/g;
##        say$remark;
##        $remark = $vidBucket[$lineNumber+3];
##        $remark =~s/[^[:ascii:]]+/=/g;
##        say$remark;
##        $remark = $vidBucket[$lineNumber+4];
##        $remark =~s/[^[:ascii:]]+/=/g;
##        say$remark;
#    }
#}

#foreach my $line_str (@vidBucket) {
#    if ($line_str eq "" || $line_str =~/^["|(]/i){
#        next;
#    }
#    $lineNumber++;
#
#    $line_str =~s/[^[:ascii:]]+/=/g;
#
#    if ($line_str =~/EquipmentType/i){
#        say $line_str;
#    }
#    if($line_str =~/^,.*?,SV,/i){
#        $lastVidLineNumber = $lineNumber;
#        chomp($line_str);
#        if ($temp ne ""){
#
#            if($temp =~/=/ig){
#                $line_str = $line_str.$temp."\n";
#                say"temp1 = $temp";
#            }
#            $temp = "";
#        }
#        push(@update, $line_str);
#        #say$line_str;
#        #say$temp;
#    }elsif($lineNumber == $lastVidLineNumber + 1){
#        chomp($line_str);
#        $lastVidLineNumber = $lineNumber;
#        $temp = $line_str.",";
#    }else{
#        say"temp2 = $temp";
#        push(@update, $line_str);
#        $temp = "";
#    }
#}
#
#my $tempfile = $logDir."tester1.txt";
#open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
#print OUTFILE @update;
#close (OUTFILE) || die "ERROR! Can't close $tempfile\n";


#foreach my $line_str (@update) {
#    $lineNumber++;
#
#    #$line_str =~s/[\r | \n]//gm;
#    chomp($line_str);
#
#    if($line_str =~/,(\d+),SV,/i){
#        #say "VID:$1";
#        #say$line_str;
#
#        if ($lastVidLineNumber){
#            my $diff = $lineNumber - $lastVidLineNumber;
#            #say"line difference = ", $diff;
#            if ($diff > 1){
#                for(my $i = 0; $i < $diff-1; $i++ ){
#                    my $previous = $vidBucket[$lastVidLineNumber + $i];
#                    #chomp($previous);
#                    if($previous =~/=| - /ig){
#                        say"$diff : traverse back: $i : $previous";
#                    }
#                }
#            }
#        }
#        $lastVidLineNumber = $lineNumber
#    }
#}

#my $book  = ReadData (".\\Lib\\ALD Online SECS ID List.xls");
#my $book = Spreadsheet::Read->new (".\\Lib\\ALD Online SECS ID List.xls");
#my $sheet = $book->sheet (1);
#my $cell  = $sheet->cell ("G15878");
##say $cell;
#my $rowCount = $sheet->maxrow;
##say "rowCount: $rowCount";
#my @out;
#
#for(my $i = 0; $i < $rowCount; $i++){
#    my $vidCell = $sheet->cell("C".$i);
#    my $vidClass = $sheet->cell("D".$i);
#    my $vidRemark = $sheet->cell("G".$i);
#
#    $vidRemark =~s/[^[:ascii:]]+//g;
#    chop($vidRemark);
#    chomp($vidRemark);
#    if ($vidClass eq "SV") {
#        say "VID: $vidCell remark: $vidRemark";
#        #push(@out, $vidCell);
#
#        if ($vidRemark =~ /[=| - ]/ig) {
#            say "VID: $vidCell remark: $vidRemark";
#            push(@out, $vidCell, " ", $vidRemark, "\n");
#        }else{
#            say "VID: $vidCell";
#        }
#    }
#}
#
#my $tempfile = $logDir."tester.txt";
#open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
#print OUTFILE @out;
#close (OUTFILE) || die "ERROR! Can't close $tempfile\n";

#foreach my $row (@rows){
#    say $row;
#}
#my $parser = Spreadsheet::ParseExcel->new();
#my $workbook = $parser->parse(".\\Lib\\ALD Online SECS ID List.xls");
#
#if (!defined $workbook) {
#    die $parser->error(), ".\n";
#}
#
#for my $worksheet ($workbook->worksheets()) {
#    my ($row_min, $row_max) = $worksheet->row_range();
#    for my $row ($row_min .. $row_max) {
#        my $svid = $worksheet->get_cell($row, 3);
#        next unless $svid->value() eq "SV";
#
#        my $vid = $worksheet->get_cell($row, 2)->value();
#        my $vidName = $worksheet->get_cell($row, 5)->value();
#        my $remark = $worksheet->get_cell($row, 6)->value();
#
#        $vidName =~ s/[\n]+//g;
#        $vidName =~ s/\s+//g;
#        #say "VID:  $vid $vidName";
#
#        $remark =~ s/[\n]+/!!!/g;
#
#        if ($remark =~ /(!!!.*)$/ig) {
#            #say "Remark: ", $remark;
#            #say "VID:  ",$vid." ".$vidName." ".$1;
#            my $t = $1;
#            if ($t !~ /!!!\d+.*?!!!/ig) {
#                #say"Not used: $t";
#                say $vid . " " . $vidName . " NA";
#            }
#            else {
#                $t =~ s/\s+//ig;
#                $t =~ s/!.*?(\d+)/ $1/ig;
#                $t =~ s/!!!.*?//ig;
##                $t =~ s/ 1$//ig;
#                $t =~ s/\d+.*?:ASMA\s//ig;
#                $t =~ s/\$FFFF.*$//ig;
##                $t =~ s/(\d+)[^[:ascii:]](\w+)/$1=$2/ig;
#                $t =~ s/(\d+)-(\w+)/$1=$2/ig;
#                $t =~ s/\d+-\d+\s0.*full/0=FULL/ig;
#                $t =~ s/\s?\d?\.+$//ig;
#                $t =~ s/\s/,/ig;
#                $t =~ s/^,/ /ig;
#                say $vid . " " . $vidName . $t;
#            }
#        }
#    }
#}
#my $libSource = ".\\Lib\\Ceids.txt"; #must have the ecid:name pairs library text file
#my $logDir = ".\\Logs\\"; #must have the saved cvs mes log as a text file
#say"libSource: $libSource, and logDir: $logDir";
#my @mesLogs;
#find (\&parseLogs,$logDir);

my $ecidHexVal = 0;
my $ecidDecVal = 0;
my $ecidDesc = "";
my $isECIDblock = 0;
my $isRPTblock = 0;
my @ecidLines;
my $seperator = " : ";
my @bucket;
my $softRevBlock = 0;
my $softRev = "Unknown";

my $tempfile = ".\\Info\\S2F30.txt"; # We can parse file with only content of S2F30

if (!-e $tempfile) {
    say "$tempfile does not exist!";
    $tempfile = ".\\Info\\ASM-Host.log"; # or we can parse for the log file contains content of S2F30
    if (!-e $tempfile) {
        die "$tempfile does not exist!";
    }else {
        extractSECSMessageFromLog("S2F30");
    }
}else{
    open (INFILE, "$tempfile") || die "ERROR! Can't open $tempfile\n";
    @bucket = <INFILE>;
    close(INFILE) || die "ERROR! Can't close $tempfile\n";
}

foreach my $line_str (@bucket){
    #$line_str;
    next if(($line_str =~ /^#/) || ($line_str =~ /^$/));
    #say "line_str=$line_str";
    chomp($line_str);

    if ($isECIDblock == 0 && $line_str =~/\<L\[6\/1\]/i) {
        #say "ECID Block";
        $isECIDblock = 1;
        $isRPTblock = 0;
        push(@ecidLines, "ECID", $seperator);
        next;
    }

    if($isECIDblock == 1){
        if($isRPTblock == 0){
            if ($line_str =~/\<U4\[1\/1\]\s(\d+)\>/i) {
                say "ECID: $1";
                $ecidDecVal = $1;
                $ecidHexVal = sprintf("%x", $ecidDecVal);
                push(@ecidLines, "\$".$ecidHexVal, $seperator, $ecidDecVal, $seperator);
                #push(@ecidLines, $ecidDecVal, " \"" );
            }elsif ($line_str =~/\<A\[\d+\/1\]\s"(.*?)"/i) {
                say "ECID Name: $1";
                $ecidDesc = $1;
                push(@ecidLines, $ecidDesc, $seperator, "\n");
                #push(@ecidLines, $ecidDesc, "\"\n");
                $isECIDblock = 0;
            }
            # elsif ($line_str =~/\<L\[\d+\/1\]$/i) {
            #     #say "Report Block";
            #     $isRPTblock = 1;
            #     push(@ecidLines, "\n");
            # }
        }
    }
}

my $outFile = ".\\Info\\ECIDsFromS2F30.txt";
say("outFile: ", $outFile);
open(OUTFILE, ">:encoding(UTF-8)", $outFile) || die "ERROR! Can't open $outFile";
print OUTFILE EventsAndReportsHeader(),@ecidLines;
close(OUTFILE) || die "ERROR! Can't close $outFile";

sub extractSECSMessageFromLog{
    my $secsMsg = $_[0];
    say "-> extractFromLog: $secsMsg";
    open (INFILE, "$tempfile") || die "ERROR! Can't open $tempfile\n";
    my @tempBucket = <INFILE>;
    close(INFILE) || die "ERROR! Can't close $tempfile\n";
    my $begin = 0;
    foreach my $line_str (@tempBucket){
        next if(($line_str =~ /^#/) || ($line_str =~ /^$/));
        #say "line_str=$line_str";
        chomp($line_str);
        if ($line_str =~/^\s+<$secsMsg.*/) {
            $begin = 1;
            #say $line_str;
            push(@bucket, $line_str);
        }elsif ($begin == 1){
            #say $line_str;
            push(@bucket, $line_str);
            if ($line_str =~/^>$/) {
                last;
            }
        }elsif($softRevBlock == 0){
            if ($line_str =~/^\s+<S1F13.*/) {
                #say "SoftRevBlock";
                $softRevBlock = 1;
            }
        }elsif($softRev eq "Unknown"){
            #say "SoftRevBlock = $softRevBlock";
            if ($line_str =~/^\s+<A\[\d+\/\d+\]\s+"(\d+.*)".*/) {
                $softRev = $1;
                say "Got SoftRev: $1";
            }
        }
    }
}

sub EventsAndReportsHeader{
    my $header = '///////////////////////////////////////////////////////////////
// Scripted by THINH NGUYEN
// File: ECIDsFromS2F30.txt
// SoftRev: '.$softRev.'
// Date: '.gmtime().'
//
// This file is to configure all ECIDs. WARNING!!!
// DO NOT_EDIT without reading first.
// All comments should follow the format being used and seen.
// The last line should be an empty line.
//
';
    return $header;
}

#################################################################################
# Terminate sub
# input = a string or message
# Obj : It's an error handling sub to wrap up the mess before exiting the program
sub Terminate() {
    say "$_[0]\n" if ($_[0]);
    say "Unexpected termination\n" if (!$_[0]);
    if ($_[0] eq "INT") {
        die "$_[0]\n" if ($_[0]);
        exit(0) if (!$_[0]);
        #  die "Unexpected termination\n" if (!$_[0]);
    }
}
