################################################################################
# This script is written by Thinh Nguyen @ASM
# It's used to analyze the mes log for Samsung customer
# due to the issue reported via OneComm# 300130350
# It computes the wafer & recipe complete time to locate event delay or missing
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
use Tk;
use Tk::DirSelect;
use Cwd;
my %dataFormat = ("Ascii(1)" => "A", "Byte (1)" => "B 0x0", "List (1)" => "L", "Truth(1)" => "BOOLEAN", "UInt1(1)" => "U1", "UInt2(1)" => "U2", "UInt4(1)" => "U4");
#my @listData;
my %CEID_DESC_MAP;
my %RPID_DESC_MAP;
my %RPTID_VIDS_MAP;
my %VID_DESC_MAP;
my $start_dir = "C:\\Users\\tnguyen02\\IdeaProjects\\ASM-Parser\\Logs";#getcwd;
say"Start SECS Format...";
#Popup to select specific customer's log folder to process
my $top  = Tk::MainWindow->new;
my $ds  = $top->DirSelect(-title => "Select Specific customer's Log folder", -width => 50, -height => 30);
my $logFolder = $ds->Show($start_dir);
#my $logFolder = "C:\\Users\\tnguyen02\\IdeaProjects\\ASM-Parser\\Logs\\Samsung"; #intel"; #TDK (Headway)"; #getcwd . "/Logs/Intel";
my $libFolder = $logFolder . "\\lib";
createVIDdictionary($libFolder);
readLogFilesTimeStamp($logFolder); # (getcwd . "/Logs");

sub readLogFilesTimeStamp {
    my $dir = $_[0];
    if (!-e $dir) {
        return;
    }
    say "my Logs at: $dir";
    opendir DIR, $dir;
    my @dirs = readdir(DIR);
    close DIR;
    foreach (@dirs) {
        my $item = $dir . "/" . $_;
        my @fileContent = ();
        if (-T $item && $_ =~/^.*.CSV?$/i) { # csv log file
            #print $_,"   : file\n";
            open(INFH, $item) || die "Unable to open $item : $!\n";
            @fileContent = <INFH>;
            close INFH;
            my $tempfile = $item . "_Decoded.sml"; #$item ."_Decoded.txt";
            open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
            print OUTFILE formatLogFile(@fileContent);
            close (OUTFILE) || die "ERROR! Can't close $tempfile\n";
        }
    }
}

sub formatLogFile{
    say "->formatLogFile($_)";
    my @decodeFile;
    my $timeStamp = "";
    my $secsCmd = "";
    my $resFlag = "";
    my @allSpaces = ();
    my $lastSpace = "";
    my $index = -1;
    my $countU4 = 0;
    my $numb = 0;
    my $S3F17Cmd = "";
    my @vidNames = ();
    my $rptSize = 0;
    foreach my $line (@_) {
        $index++;
        if($line =~ /^("\d+","(.*)","(.*)","\w+","(S\d+F\d+)",.*,"(O[N|F]\w*)",.*)/i) { #first line of SECS SxFx command
            while(@allSpaces){
                my $latestLastSpace = pop @allSpaces;
                if (length($lastSpace) > length($latestLastSpace)){
                    push(@decodeFile, "\t$latestLastSpace>\n");
                    $lastSpace = $latestLastSpace;
                }
            }
            $timeStamp = $2 . " " . $3;
            $secsCmd = $4;
            $resFlag = $5 eq "ON"? " W":"";
            #say "cmd: $secsCmd";
            if($secsCmd eq "S2F33" && $line =~ /.*"List\s+\(1\)\s+2$/){ #sometimes there's incomplete record does not have <List \(1\)   > at the EOL. It's a LogVier bug
                $rptSize = 0;
                $numb = 0;
                $countU4 = 0;
                $lastSpace = "";
                @allSpaces = ();
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                #push(@decodeFile, $line);
                push(@decodeFile, "<$secsCmd$resFlag>\n");
                push(@decodeFile, "\t<L 2\n");
                push(@allSpaces, $lastSpace);
                if($_[$index+2] =~ /L.*?(\d+)$/){ #Nees to know how many reports in each event
                    $rptSize = $1;
                }
            }
        }elsif($secsCmd eq "S2F33"){
            $numb++;
            if($line =~ /^((\s*)(\w+\s*\(1\))(.*))/i) {
                my $data = $1;
                my $currentSpace = $2;
                #Takecare of closing bracket '>' when it starts changing space to smaller
                if (length($currentSpace) < length($lastSpace)){
                    my $latestLastSpace = pop @allSpaces;
                    while(length($lastSpace) == length($latestLastSpace)){
                        $latestLastSpace = pop @allSpaces; #keep popping to get space smaller than the last push
                    }
                    if(length($lastSpace) > length($latestLastSpace)){
                        push(@decodeFile, "\t$latestLastSpace>\n"); #right space for closing bracket >
                    }
                }
                push(@allSpaces, $currentSpace);
                $lastSpace = $currentSpace;
                if(defined $dataFormat{$3}){
                    my $dataF = $dataFormat{$3};
                    #say "dataF: $dataF";
                    if ($data =~ /\d+\s+:(\d+)/ || $data =~ /\d+\s+:(\w*\W*\w*)\s*/ || $data =~ /\s+(\d+)/){
                        my $number = $1;
                        if ($dataF eq "U4"){
                            $countU4++;
                            if ($countU4 > 2) { #Begins ReportID then its list of VIDs
                                if ($rptSize > 0) {
                                    $rptSize--;
                                }
                                if($VID_DESC_MAP{$number}){
                                    push(@decodeFile, "\t$currentSpace<$dataF $number> \t\t\t\t \\* TN -> $VID_DESC_MAP{$number} *\\\n");
                                }else{
                                    push(@decodeFile, "\t$currentSpace<$dataF $number>\n");
                                }
                            }else{
                                push(@decodeFile, "\t$currentSpace<$dataF $number>\n");
                            }
                        }else{
                            if($VID_DESC_MAP{$number}){
                                push(@decodeFile, "\t$currentSpace<$dataF $number \t\t\t\t \\* TN -> $VID_DESC_MAP{$number} *\\\n");
                            }else{
                                push(@decodeFile, "\t$currentSpace<$dataF $number\n");
                            }
                        }
                    }
                }else{
                    push(@decodeFile, "\n");
                }
            }else{
                push(@decodeFile, "\n");
            }
        }
    }
    while(@allSpaces){
        my $latestLastSpace = pop @allSpaces;
        if (length($lastSpace) > length($latestLastSpace)){
            push(@decodeFile, "\t$latestLastSpace>\n");
            $lastSpace = $latestLastSpace;
        }
    }
    return @decodeFile;
}
#createDataList is a sub to generate Secs List Data not being used in here
# sub createDataList {
#     #say "->createDataList()";
#     while(my $item = pop @listData) {
#         #say "item: $item";
#         if ($item =~ /^((\s*)(\w+\s*\(1\))(.*))/i) {
#             my $space = $2;
#             my $dataF = $dataFormat{$3};
#             my $data = $4;
#             #say "\tdataF: $dataF";
#             if ($dataF eq "L"&& $data =~ /(\d+)/){
#                 my @dataList;
#                 my $count = $1;
#                 #say "count: $count";
#                 push (@dataList, "$space<L $count\n");
#
#                 for (my $i = 0; $i < $count; $i++){
#                     push(@dataList, createDataList(@listData));
#                 }
#                 push (@dataList, "$space> \n");
#                 #say ("data: @data");
#                 return @dataList;
#             }else{
#
#                 return $item;
#             }
#         }else{
#             say "item2: $item";
#             return $item;
#         }
#
#         createDataList(@listData);
#     }
#     return ;
# }

sub createCEIDdictionary {
    say "->createCEIDdictionary()";
    my $dir = $_[0];
    if (!-e $dir) {
        return;
    }
    opendir DIR, $dir;
    my @dirs = readdir(DIR);
    close DIR;
    foreach (@dirs) {
        my $tempfile = $dir . "\\" . $_;
        my @fileContent = ();
        if (-T $tempfile) {
            open(INFILE, "$tempfile") || die "ERROR! Can't open $tempfile\n";
            @fileContent = <INFILE>;
            close(INFILE) || die "ERROR! Can't close $tempfile\n";
            if ($_ =~ /^ConvertedEventXp/i) {
                say "CEIDs from: $tempfile";
                foreach my $line (@fileContent) {
                    next if (($line =~ /^#/) || ($line =~ /^$/)); #skip all the comments or blank lines
                    if ($line =~ /^CEID : .* : (\d+) : (.*?) :/i) {
                        $CEID_DESC_MAP{$1} = $2;
                    }elsif ($line =~ /^\s+RPID : .*? : (\d+) : (\w+) :/){
                        $RPID_DESC_MAP{$1} = $2;
                    }
                }
            }
        }
    }
}

sub createReportDictionary{
    say "->createReportDictionary()";
    my $dir = $_[0];
    if (!-e $dir) {
        return;
    }
    #say "my Logs at: $dir";
    opendir DIR, $dir;
    my @dirs = readdir(DIR);
    close DIR;
    foreach (@dirs) {
        my $tempfile = $dir . "\\" . $_;
        my @fileContent = ();
        if (-T $tempfile) {
            open (INFILE, "$tempfile") || die "ERROR! Can't open $tempfile\n";
            @fileContent = <INFILE>;
            close(INFILE) || die "ERROR! Can't close $tempfile\n";

            if($_ =~/^.*.sml?$/i) { # S2F33.sml file where reports are defined specifically
                say "Reports from: $tempfile";
                my $index = -1;
                my $rptDone = "N";
                my $RPID = -1;
                foreach my $line (@fileContent) {
                    $index++;
                    if ($line =~ /^.*S2F33.*/i || $index < 4) { #skip some first lines w/o data
                        next;
                    }elsif ($line =~ /<U4\s+(\d+)>/) {
                        if ($rptDone eq "N") {
                            $RPID = $1;
                            $rptDone = "Y";
                            next;
                        }elsif ($rptDone eq "Y") {
                            #say "One: $1";
                            my $vid = $1 . ":". $VID_DESC_MAP{$1};
                            push(@{ $RPTID_VIDS_MAP{$RPID} }, $vid);
                        }
                    }elsif ($line =~ /\s+>\s+/) { #Done collecting VID data in the list. Time to reset
                        if ($RPID > -1) {
                            $rptDone = "N";
                            $RPID = -1;
                        }
                    }
                }
            }elsif($_ =~/^ConvertedEventXp/i) { # Reports and VIDs map where reports are defined by default in EventXp file
                say "Reports from: $tempfile";
                my @VID = ();
                my $RPID = -1;
                foreach my $line (@fileContent) {
                    next if(($line =~ /^#/) || ($line =~ /^$/)); #skip comments
                    if($line =~ /^RPID\s+:.*:\s+(\d+)/){
                        $RPID = $1;
                    }elsif($line =~ /^\s+VID\s+:.*:\s+(\d+)/){
                        my $vid = $1;
                        if ($VID_DESC_MAP{$1}){
                            $vid = $1 . ":". $VID_DESC_MAP{$1};
                        }
                        push(@{ $RPTID_VIDS_MAP{$RPID} }, $vid);
                    }
                }
            }
        }
    }
}

sub createVIDdictionary {
    say "->createVIDdictionary()";
    my $dir = $_[0];
    if (!-e $dir) {
        return;
    }
    #say "my VID at: $dir";
    opendir DIR, $dir;
    my @dirs = readdir(DIR);
    close DIR;
    foreach (@dirs) {
        my $tempfile = $dir . "\\" . $_;
        my @fileContent = ();
        if (-T $tempfile) {
            open(INFILE, "$tempfile") || die "ERROR! Can't open $tempfile\n";
            @fileContent = <INFILE>;
            close(INFILE) || die "ERROR! Can't close $tempfile\n";
            if ($_ =~ /^VID.*.txt?$/i) {
                say "VIDs from: $tempfile";
                foreach my $line (@fileContent) {
                    next if (($line =~ /^#/) || ($line =~ /^$/));
                    if ($line =~ /VID\s+:\s+[\$]*\w+\s+:\s+(\d+)\s+:\s+(.*)\s+:/) {
                        $VID_DESC_MAP{$1} = $2;
                    }
                }
            }
        }
    }
}