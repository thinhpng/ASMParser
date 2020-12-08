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

my $tempfile = ".\\Info\\MCIF_0.txt";
open (INFILE, "$tempfile") || die "ERROR! Can't open $tempfile\n";
my @bucket = <INFILE>;
close(INFILE) || die "ERROR! Can't close $tempfile\n";
my $isSECScmdBlock = 0;
my $isMainList = 0;
my $mainListSize = 0;
my $isBoolean = 0;
my $boolValue = 0;
my $parameter = "";
my $isSubList = 0;
my $subListSize = 0;
my $secsCmd = "";
my @cmdData;

foreach my $line_str (@bucket){

    #$line_str;
    next if(($line_str =~ /^#/));
    #say "line_str=$line_str";
    chomp($line_str);
#    if ($isSECScmdBlock == 0 && $line_str =~/\(S\d+F\d+)\s*,\s*Time=(.*?)\s*,s*SSID]/) {

    #if ($line_str =~/(S\d+F\d+)\s*,\s*Time=(.*?)\s*,s*SSID]/) {
        if ($isSECScmdBlock == 0 && $line_str =~/(S\d+F\d+)\s*,\s*Time=(.*?)\s*,\s*SSID/) { #Begins cmd block
            $isSECScmdBlock = 1;
            push(@cmdData,$1);
            say($2, " : ", $1);
            $isMainList = 0;
            $secsCmd = $1 . "\n";
            next;
    }

    if($isSECScmdBlock == 1){
        if($line_str =~/^$/){ #Ends of cmd block
            $isSECScmdBlock = 0;
            say("End of Cmd Block");
            ConvertCmdBlockToSecsCmd();
            $secsCmd = $secsCmd . ">\n";
            #say $secsCmd;
            $secsCmd = "";
            foreach my $item (@cmdData){
                say ("Got item: ", $item);
            }
        }else{
            push(@cmdData,$line_str);
            if($line_str =~/L,(\d+)/){ #Any List data type belongs to secs cmd

                if($isMainList == 0){ #First or Main List right after secs cmd has identified
                    $isMainList = 1;
                    $mainListSize = $1;
                    #say ("Main List: ", $line_str);
                    $secsCmd = $secsCmd . "<L\n";
                }else{ #It's sub-list data
                    $isSubList = 1;
                    $subListSize = $1;
                    #say("Sub List: ", $line_str);
                    $secsCmd = $secsCmd . "<L\n";
                }
            }else{ #It's any other type of data belongs to the List above it
                #say ("No LIST data");
                if ($line_str =~/B0\(4\): 00,00,00,0(\d+),/gi){ #It's Boolean data
                    $isBoolean = 1;
                    $boolValue = "<B 0x" . $1;
                    #say("Got Boolean: ", $boolValue);
                    $secsCmd = $secsCmd . $boolValue . ">\n";
                }elsif($line_str =~/40:\s+(.*)/){
                    $parameter = "<A " . $1;
                    #say("Got parameter: ", $1);
                    if($parameter !~/(.*?)>/i){
                        $parameter = $parameter . ">";
                        #say("Trimmed parameter: ", $parameter);
                    }
                    $secsCmd = $secsCmd . $parameter . "\n";
                }elsif($line_str =~/A4\(1\): (\d+),/){
                    #say ("Got A4 ", $1);
                }else{
                    pop(@cmdData); #not collecting this item
                }
                #TrackingList();
            }
        }
    }
}

sub ConvertCmdBlockToSecsCmd{
    my $item;
    my @data;
    my @secsCmd;
    my @listData;

    while(@cmdData){
        $item = pop(@cmdData);
        if($item =~/A4\(1\): (\d+),/i){
            $item = "<I1 " . $1 . ">\n";
            push(@data, $item);
        }elsif($item =~/40:\s+(.*)/i){
            $item = "<A " . $1 . ">\n";
            push(@data, $item);
        }elsif($item =~/B0\(4\): 00,00,00,0(\d+),/i){ #It's Boolean data
            $item = "<B 0x" . $1 . ">\n";
            push(@data, $item);
        }elsif($item =~/L,(\d+)/){
            push(@listData, "<L\n");
            my $listSize = $1;
            for(my $i = 0; $i < $listSize; $i++){
                push(@listData, pop(@data));
            }
            push(@listData, ">");
            if(!@secsCmd) {
                push(@secsCmd, @listData);
                push(@secsCmd, ">");
            }else{
                push(@listData, pop(@cmdData));
                push(@secsCmd, @listData);
            }
        }
    }

    foreach $item (@secsCmd){
        say @secsCmd;
    }
}

sub TrackingList{
    if($isSubList){
        $subListSize--;
        if($subListSize == 0){
            $mainListSize--;
            $secsCmd = $secsCmd . ">";
        }
    }
}

# my $outFile = ".\\Info\\ECIDsFromS2F30.txt";
# say("outFile: ", $outFile);
# open(OUTFILE, ">:encoding(UTF-8)", $outFile) || die "ERROR! Can't open $outFile";
# print OUTFILE EventsAndReportsHeader(),@ecidLines;
# close(OUTFILE) || die "ERROR! Can't close $outFile";

sub EventsAndReportsHeader{
    my $header = '///////////////////////////////////////////////////////////////
// Scripted by THINH NGUYEN
// File: ECIDsFromS2F30.txt
// Version: 1.0
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
