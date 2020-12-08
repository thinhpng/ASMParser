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
my %errorCode;
my %dataFormat = ("Ascii(1)" => "A", "Byte (1)" => "B 0x0", "List (1)" => "L", "Truth(1)" => "BOOLEAN", "UInt1(1)" => "U1", "UInt2(1)" => "U2", "UInt4(1)" => "U4");
my %CAACK = (0 => "Ok", 1 => "Invalid Command", 2 => "Cannot Perform Now", 3 => "Invalid Data or Argument", 4 => "Initiated for Asynchronous Completion",
    5 => "Rejected - Invalid State", 6 => "Command Performed with Errors");
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
getErrorCodeMap();
createVIDdictionary($libFolder);
createReportDictionary($libFolder); #prepare Report Dict to translate data later.
createCEIDdictionary($libFolder); #prepare CEID Dict to translate data later.
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
        say "item: $item";
        my @fileContent = ();
        if (-T $item && $_ =~/^.*.CSV?$/i) { # csv log file
            #print $_,"   : file\n";
            open(INFH, $item) || die "Unable to open $item : $!\n";
            @fileContent = <INFH>;
            close INFH;
            my $tempfile = $item ."_Decoded.txt";
            open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
            #print OUTFILE formatLogFile(@fileContent);
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
    my %Carriers;
    my $transID;

    foreach my $line (@_) {
        $index++;
        if($line =~ /^("\d+","(.*)","(.*)","\w+","(S\d+F\d+)",.*,"(\w+)","(O[N|F]\w*)",.*)/i) { #first line of SECS SxFx command
            while(@allSpaces){
                my $latestLastSpace = pop @allSpaces;
                if (length($lastSpace) > length($latestLastSpace)){
                    push(@decodeFile, $timeStamp, "\t$latestLastSpace>\n");
                    $lastSpace = $latestLastSpace;
                }
            }
            $timeStamp = $2 . " " . $3;
            $secsCmd = $4;
            $transID = $5;
            $resFlag = $6 eq "ON"? " W":"";

            if($secsCmd eq "S6F11" && $line =~ /.*"List\s+\(1\)\s+3$/){ #sometimes there's incomplete record does not have <List \(1\)   3> at the EOL. It's a LogVier bug
                $rptSize = 0;
                $numb = 0;
                $countU4 = 0;
                $lastSpace = "";
                @allSpaces = ();
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag>\n");
                push(@decodeFile, $timeStamp, "\t<L 3\n");
                push(@allSpaces, $lastSpace);
                if($_[$index+3] =~ /L.*?(\d+)$/){ #Nees to know how many reports in each event
                    $rptSize = $1;
                }
            }elsif($secsCmd eq "S3F17"){
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                if($_[$index+2] =~ /Ascii\(1\)\s+\d+\s+:(\w+)/){
                    $S3F17Cmd = $1;
                    my $cID = "";
                    if($_[$index+3] =~ /Ascii\(1\)\s+\d+\s+:(\w+)/){
                        $cID = $1;
                        if(defined($Carriers{$cID})){
                            $S3F17Cmd .= "_1"; #time in the log newer on top so parsing the file second cmd is seen first.
                        }else{
                            $Carriers{$transID} = $cID;
                            $S3F17Cmd .= "_2"; #scan log file from top to bottom the second PWC is seen fist
                        }
                    }
                    #say "$S3F17Cmd: cID";
                    if ($S3F17Cmd eq "ProceedWithCarrier"){
                        if ($_[$index+5] =~ /List\s+\(1\)\s+0/){
                            push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> $S3F17Cmd : $cID *\\\n");
                        }else{
                            push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> $S3F17Cmd : Mapping $cID *\\\n");
                        }
                    }else{
                        push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> $S3F17Cmd $cID *\\\n");
                    }
                }
            }elsif($secsCmd eq "S3F18"){
                if($_[$index+1] =~ /UInt1\(1\)\s+1\s+:(\d+)/){
                    my $caAck = $CAACK{$1};
                    if($_[$index+4] =~ /UInt1\(1\)\s+1\s+:(\d+)/){
                        my $errCode = $errorCode{$1};
                        if($_[$index+5] =~ /Ascii\(1\)\s+\d+\s+:(\w+)/){
                            my $errText = $1;
                            push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> $caAck Error: $errCode ($errText) *\\\n");
                        }else{
                            push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> $caAck Error: $errCode *\\\n");
                        }
                    }else{
                        push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> $caAck *\\\n");
                    }
                }
            }elsif($secsCmd eq "S16F15"){
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                my $pjID = $_[$index+4];
                if ($pjID =~ /Ascii\(1\)\s+\d+\s+:(.*)/){
                    $pjID = $1;
                    my $cID = "";
                    if ($_[$index+8] =~ /Ascii\(1\)\s+\d+\s+:(.*)/){
                        $cID = $1;
                    }
                    push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> PJ:$pjID CID:$cID *\\\n");
                }else{
                    push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag>\n");
                }
            }elsif($secsCmd eq "S14F9"){
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                my $cjID = $_[$index+6];
                if ($cjID =~ /Ascii\(1\)\s+\d+\s+:(.*)/){
                    $cjID = $1;
                    my $pjID = "";
                    if ($_[$index+11] =~ /Ascii\(1\)\s+\d+\s+:(.*)/) {
                        $pjID = $1;
                    }
                    my $cID = "";
                    if ($_[$index+17] =~ /Ascii\(1\)\s+\d+\s+:(.*)/) {
                        $cID = $1;
                    }
                    push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> CJ:$cjID PJ:$pjID CID:$cID *\\\n");
                }else{
                    push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag>\n");
                }
            }elsif($secsCmd eq "S5F1"){
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                my $alState = ($_[$index+1] =~ /:80/) ? "(ON)" : "(OFF)";
                my $alID = "";
                if($_[$index+2] =~ /:\d+\s+\((\w+)\)/){
                    $alID = $1;
                }
                my $altext = "";
                if($_[$index+3] =~ /:(.*)/){
                    $altext = $1;
                }
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> ALARM:$alID $altext $alState\n");
            }elsif($secsCmd eq "S7F25"){
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                my $recipe = "";
                if($line =~ /"Ascii\(1\)\s+\d+\s+:([\w_-|.]*).*/){
                    $recipe = $1;
                }
                $decodeFile[$#decodeFile] =~ s/"Ascii\(1\)\s+\d+\s+:.*//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> Upload: $recipe\n");
            }else{
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag>\n");
            }
        }elsif($secsCmd eq "S6F11"){
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
                        push(@decodeFile, $timeStamp, "\t$latestLastSpace>\n"); #right space for closing bracket >
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
                            if ($countU4 == 2){
                                if(defined $CEID_DESC_MAP{$number}){
                                    push(@decodeFile, $timeStamp, "\t$currentSpace<$dataF $number>\t\t\t \\* TN -> CEID: $CEID_DESC_MAP{$number} *\\\n");
                                }else{
                                    push(@decodeFile, $timeStamp, "\t$currentSpace<$dataF $number>\t\t\t \\* TN -> CEID: $number *\\\n");
                                }
                            }elsif ($countU4 > 2) { #Begins ReportID then its list of VIDs
                                if ($rptSize > 0) {
                                    $rptSize--;
                                    if (defined $RPID_DESC_MAP{$number}) {
                                        push(@decodeFile, $timeStamp, "\t$currentSpace<$dataF $number>\t\t \\* TN -> RPID: $RPID_DESC_MAP{$number} *\\\n");
                                    }
                                    else {
                                        push(@decodeFile, $timeStamp, "\t$currentSpace<$dataF $number>\t\t \\* TN -> RPID: $number *\\\n");
                                    }

                                    if (defined $RPTID_VIDS_MAP{$number}) {
                                        @vidNames = reverse @{$RPTID_VIDS_MAP{$number}};
                                    }
                                }else {
                                    if(@vidNames){
                                        my $vidName = pop @vidNames;
                                        push(@decodeFile, $timeStamp, "\t$currentSpace<$dataF $number \t\t \\* TN -> $vidName *\\\n");
                                    }else{
                                        push(@decodeFile, $timeStamp, "\t$currentSpace<$dataF $number \n");
                                    }
                                }
                            }
                        }else{
                            if(@vidNames && $dataF ne "L"){
                                my $vidName = pop @vidNames;
                                push(@decodeFile, $timeStamp, "\t$currentSpace<$dataF $number \t\t \\* TN -> $vidName *\\\n");
                            }else{
                                push(@decodeFile, $timeStamp, "\t$currentSpace<$dataF $number \n");
                            }
                        }
                    }
                }else{
                    push(@decodeFile, $timeStamp, "\n");
                }
            }else{
                push(@decodeFile, $timeStamp, "\n");
            }
        }
    }
    while(@allSpaces){
        my $latestLastSpace = pop @allSpaces;
        if (length($lastSpace) > length($latestLastSpace)){
            push(@decodeFile, $timeStamp, "\t$latestLastSpace>\n");
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

sub getErrorCodeMap{
    say "->getErrorCodeMap()";
    $errorCode{0} = "ok";
    $errorCode{1} = "unknown object";
    $errorCode{2} = "unknown class";
    $errorCode{3} = "unknown object instance";
    $errorCode{4} = "unknown attribute type";
    $errorCode{5} = "read-only attribute";
    $errorCode{6} = "unknown class";
    $errorCode{7} = "invalid attribute value";
    $errorCode{8} = "syntax error";
    $errorCode{9} = "verification error";
    $errorCode{10} = "validation error";
    $errorCode{11} = "object ID in use";
    $errorCode{12} = "improper parameters";
    $errorCode{13} = "missing parameters";
    $errorCode{14} = "unsupported option requested";
    $errorCode{15} = "busy";
    $errorCode{16} = "unavailable";
    $errorCode{17} = "command not valid in current state";
    $errorCode{18} = "no material altered";
    $errorCode{19} = "partially processed";
    $errorCode{20} = "all material processed";
    $errorCode{21} = "recipe specification error";
    $errorCode{22} = "failure when processing";
    $errorCode{23} = "failure when not processing";
    $errorCode{24} = "lack of material";
    $errorCode{25} = "job aborted";
    $errorCode{26} = "job stopped";
    $errorCode{27} = "job cancelled";
    $errorCode{28} = "cannot change selected recipe";
    $errorCode{29} = "unknown event";
    $errorCode{30} = "duplicate report ID";
    $errorCode{31} = "unknown data report";
    $errorCode{32} = "data report not linked";
    $errorCode{33} = "unknown trace report";
    $errorCode{34} = "duplicate trace ID";
    $errorCode{35} = "too many reports";
    $errorCode{36} = "invalid sample period";
    $errorCode{37} = "group size too large";
    $errorCode{38} = "recovery action invalid";
    $errorCode{39} = "busy with previous recovery";
    $errorCode{40} = "no active recovery";
    $errorCode{41} = "recovery failed";
    $errorCode{42} = "recovery aborted";
    $errorCode{43} = "invalid table element";
    $errorCode{44} = "unknown table element";
    $errorCode{45} = "cannot delete predefined";
    $errorCode{46} = "invalid token";
    $errorCode{47} = "invalid parameter";
    $errorCode{48} = "Load port does not exist";
    $errorCode{49} = "Load port is busy";
    $errorCode{50} = "missing carrier";
    $errorCode{32768} = "deferred for later initiation";
    $errorCode{32769} = "can not be performed now";
    $errorCode{32770} = "failure from errors";
    $errorCode{32771} = "invalid command";
    $errorCode{32772} = "client alarm";
    $errorCode{32773} = "duplicate clientID";
    $errorCode{32774} = "invalid client type";
    $errorCode{32776} = "unknown clientID";
    $errorCode{32777} = "Unsuccessful completion";
    $errorCode{32779} = "detected obstacle";
    $errorCode{32780} = "material not sent";
    $errorCode{32781} = "material not received";
    $errorCode{32782} = "material lost";
    $errorCode{32783} = "hardware error";
    $errorCode{32784} = "transfer cancelled";
}