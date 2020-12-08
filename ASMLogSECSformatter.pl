################################################################################
# This script is written by Thinh Nguyen @ASM
# It's used to analyze the mes log, reformat it to readable, meaningful one
################################################################################
#!/usr/bin/perl
use strict;
use Win32::File;
use File::Path;
use File::Find;
use warnings FATAL => 'all';
use POSIX qw{strftime};
use feature qw(say);
use Tk;
use Tk::DirSelect;
use Cwd;
#no warnings 'uninitialized';
use Date::Parse;
use Time::Piece;

my %TIAACK = (0 => "Ok", 1 => "Too many SVIDs", 2 => "No more traces allowed", 3 => "Invalid period", 4 => "Unknown SVID", 5 => "Bad REPGSZ");
my %CEED = ("00" => "Disabled", "01" => "Enabled", "FF" => "Enabled");
my %ERACK = (0 => "Ok", 1 => "Denied");
my %DRACK = (0 => "Ok", 1 => "Out of space", 2 => "Invalid format", 3 => "1 or more RPTID already defined", 4 => "1 or more invalid VID");
my %LRACK = (0 => "Ok", 1 => "Out of space", 2 => "Invalid format", 3 => "1 or more CEID links already defined",
    4 => "1 or more CEID invalid", 5 => "1 or more RPTID invalid");
my %START_METHOD = ("00" => "MANUAL", "01" => "AUTO");
my %HCACK = ("00" => "ok, completed", "01" => "invalid command", "02" => "cannot do now", "03" => "parameter error",
    "04" => "initiated for Async completion", "05" => "rejected, already in desired condition", "06" => "invalid object");
my %ACKA = ("00" => "ERROR", "01" => "OK");
my %OBJACK = (0 => "OK", 1 => "ERROR");
my %errorCode;
my %dataFormat = ("Ascii(1)" => "A", "Byte (1)" => "B", "List (1)" => "L", "Truth(1)" => "BOOLEAN", "UInt1(1)" => "U1", "UInt2(1)" => "U2", "UInt4(1)" => "U4");
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
    my @mesLogs = readdir(DIR);
    close DIR;
    @mesLogs = sort {$b cmp $a} @mesLogs; #sort by file's name
    my $lastNumber = 0;
    my @sortedMesLogs;
    my $change = 0;
    my @batchOne;
    my @batchTwo;

    # log is versioning from 1->99 then roll over
    # so we need to get the log files listed in order by creation time
    for(my $count = 0; $count < @mesLogs; $count++) { #sorting log file by chronological order
        my $logName = $dir . "/" . $mesLogs[$count];
        if($logName =~/.*_(\d+).csv/i){ #processing .csv log files only
            #say $lastNumber;
            if($lastNumber == 0 || $lastNumber == int($1) + 1 && $change == 0){
                $lastNumber = int($1);
                push(@batchOne, $logName); #this batch holds older files
            }else{
                $change = 1;
                push(@batchTwo, $logName); #this batch holds newer files
            }
        }
    }
    #push(@sortedMesLogs, reverse @batchTwo, @batchOne);
    #say "Sorting files by time";

    if(@batchOne && @batchTwo) { #log files are grouped in 2 batches because naming rollover. Needs to sort them by time
        if (compareTimeStamp(getLastTimeStamp($batchTwo[$#batchTwo]), getFirstTimeStamp($batchOne[$#batchOne]))) {
            push(@sortedMesLogs, reverse @batchTwo, @batchOne);
        }else {
            push(@sortedMesLogs, reverse @batchOne, @batchTwo);
        }
    }elsif(@batchOne){
        push(@sortedMesLogs, reverse @batchOne);
    }elsif(@batchTwo){
        push(@sortedMesLogs, reverse @batchTwo);
    }else { #all log files are continuously in one batch
        push(@sortedMesLogs, reverse @mesLogs);
    }

    foreach (@sortedMesLogs) {
        my $item = $_;
        my @fileContent = ();
        #print $_,"   : file\n";
        open(INFH, $item) || die "Unable to open $item : $!\n";
        @fileContent = <INFH>;
        close INFH;
        my $index = 0;
        my @ind = ();
        my @sortedData = ();

        if (-T $item && $_ =~/^.*.CSV?$/i) { #processing .csv log files only
            foreach my $line (@fileContent){
                if($line =~ /^"(\d+)",("\d+\/\d+\/\d+","\d+:\d+:\d+")/){ #"773","2020/09/27","23:43:47"
                    push(@ind, $index); #gather starting point on each transaction (each transaction starts with timestamp)
                }
                $index++;
            }
            my $first = "";
            my $second = pop @ind; #data in reverse timing top->down = new->old. So get last line first.
            my $prevSecond = 0;

            while(1){ #First, take care of all cmd with header only and the first one with content.
                if($fileContent[$second+1] !~ /^\s+/){ #just SxFx cmd header w/o content follows
                    $prevSecond = $second; #save info to be used later if needed
                    push (@sortedData, $fileContent[$second]); #last line is even function so its odd function must be in another file.
                    $second = pop @ind; #get all cmds with header only w/o content. They start and end on the same line
                }else{
                    $first = $second; #this cmd has content follow so we start from this cmd to next cmd
                    for(my $i = $first ; $i < $prevSecond; $i++) { #all contents must be up to the $prevSecond or next cmd
                        push(@sortedData, $fileContent[$i]); #each transaction starts from timestamp to next timestamp
                    }
                    last;
                }
            }

            while (@ind){ #Second, take care of regular cmds with contents or w/o content until the last found cmd
                $first = pop @ind;
                for(my $i = $first ; $i < $second; $i++) {
                    push(@sortedData, $fileContent[$i]); #each transaction starts from timestamp to next timestamp
                }
                $second = $first;
            }

            my $tempfile = $item ."_Decoded.txt";
            open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
            print OUTFILE formatLogFile(@sortedData); #sending sorted data to parse to get detail info
            close (OUTFILE) || die "ERROR! Can't close $tempfile\n";
        }
    }
}

sub formatLogFile{ #reformat the content in the log file so it's readable with additional meaningful details
    say "->formatLogFile($_)";
    my @decodeFile;
    my $timeStamp = "";
    my $secsCmd = "";
    my $resFlag = "";
    my @allSpaces = ();
    my $lastSpace = "";
    my $index = -1;
    my $countU4 = 0;
    my $S3F17Cmd = "";
    my @vidNames = ();
    my $rptSize = 0;
    my %carriers;
    my %transactions;
    my $transID;
    my $skipPollingData = 1; #Option to dump S1F1/F2 polling messages
    my $skipF6F12 = 1;

    foreach my $line (@_) {
        $index++;
        if($line =~ /^("\d+","(.*)","(.*)","\w+","(S\d+F\d+)",.*,"(\w+)","(O[N|F]\w*)",.*)/i) { #first line of SECS SxFx command
            while(@allSpaces){
                my $latestLastSpace = pop @allSpaces;
                if (length($lastSpace) > length($latestLastSpace)){
                    if($secsCmd eq "S2F15" || $secsCmd eq "S2F23" || $secsCmd eq "S2F33" || $secsCmd eq "S2F35"){
                        push(@decodeFile, "$latestLastSpace>\n");
                    }else {
                        push(@decodeFile, $timeStamp, "\t$latestLastSpace>\n");
                    }
                    $lastSpace = $latestLastSpace;
                }
            }

            $lastSpace = "";
            @allSpaces = ();
            push(@allSpaces, $lastSpace);
            $timeStamp = $2 . " " . $3;
            $transID = $5;
            $resFlag = $6 eq "ON"? " W":"";
            $secsCmd = $4;
            next if ($skipPollingData && $secsCmd eq "S6F1" || $secsCmd eq "S6F2");
            next if ($skipF6F12 && $secsCmd eq "S6F12");

            if($secsCmd =~/S\d+F0/) {
                push(@decodeFile, $line);
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t\t \\* TN -> Abort Transaction *\\\n");
            }elsif($secsCmd eq "S1F13") {
                push(@decodeFile, $line);
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> Request to Establish Communication *\\\n");
            }elsif($secsCmd eq "S1F17") {
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> Request ON-LINE *\\\n");
            }elsif($secsCmd eq "S2F13"){
                my $number = ($line =~ /"List\s+\(\d+\)\s+(\d+)/) ? $1 : "";
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> Request $number ECIDs *\\\n");
            }elsif($secsCmd eq "S2F15"){
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                push(@decodeFile, "<$secsCmd$resFlag>\n");
                push(@decodeFile, "<L \n");
            }elsif($secsCmd eq "S2F23"){
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                push(@decodeFile, "<$secsCmd$resFlag>\n");
                push(@decodeFile, "<L \n");
            }elsif($secsCmd eq "S2F24"){
                my $response = ($line =~ /.*"Byte\s+\(1\)\s+\d+\s+:(\d+)"/) ? $TIAACK{int($1)} : "Unknown Response";
                $line =~ s/"Byte\s+\(1\)\s+\d+\s+:.*$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> $response *\\\n");
            }elsif($secsCmd eq "S2F33"){
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                push(@decodeFile, "<$secsCmd$resFlag>\n");
            }elsif($secsCmd eq "S2F34"){
                my $response = ($line =~ /.*?"Byte\s+\(1\)\s+\d+\s+:(\d+)"/) ? $DRACK{int($1)} : "Unknown Response: " . $1;
                $line =~ s/"Byte\s+\(1\)\s+\d+\s+:.*$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> $response *\\\n");
            }elsif($secsCmd eq "S2F35"){
                say("*******************************************");
                say(">>>>>>>>>>>>>> S2F35 Found <<<<<<<<<<<<<<<<");
                say("*******************************************");
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                push(@decodeFile, "<$secsCmd$resFlag>\n");
            }elsif($secsCmd eq "S2F36"){
                my $response = ($line =~ /.*?"Byte\s+\(1\)\s+\d+\s+:(\d+)"/) ? $LRACK{int($1)} : "Unknown Response";
                $line =~ s/"Byte\s+\(1\)\s+\d+\s+:.*$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> $response *\\\n");
            }elsif($secsCmd eq "S2F37"){
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                my $request = ($_[$index+1] =~ /Truth\(1\)\s+\d+\s+:(\w+)/) ? $CEED{$1} : "Unknown request: " . $1;
                my $requestList = ($_[$index+2] =~ /List\s+\(\d+\)\s+(\d+)/) ? $1 : -1;
                $request .= ($requestList == 0) ? " All CEIDs" : " $requestList CEIDs";
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> $request *\\\n");
            }elsif($secsCmd eq "S2F38"){
                my $response = ($line =~ /.*?"Byte\s+\(1\)\s+\d+\s+:(\d+)"/) ? $ERACK{int($1)} : "Unknown Response: " . $1;
                $line =~ s/"Byte\s+\(1\)\s+\d+\s+:.*$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> $response *\\\n");
            }elsif($secsCmd eq "S2F43"){
                my $request = ($line =~ /List\s+\(\d+\)\s+(\d+)/) ? $1 : -1;
                $line =~ s/"Byte\s+\(1\)\s+\d+\s+:.*$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                $request = ($request == 0) ? "Turns OFF all streams and functions" : "";
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> Spooling Req: $request *\\\n");
            }elsif($secsCmd eq "S2F44"){
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                my %RSPACK = ("00" => "Ok", "01" => "Rejected");
                my $response = ($_[$index+1] =~ /Byte\s+\(1\)\s+\d+\s+:(\w+)/) ? $RSPACK{$1} : "";
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> $response *\\\n");
            }elsif($secsCmd eq "S2F49"){
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                my $command = ($_[$index+3] =~ /Ascii\(1\)\s+\d+\s+:(\w+)/) ? $1 : "";
                $transactions{$transID} = $command;
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> Cmd:$command *\\\n");
            }elsif($secsCmd eq "S2F50"){
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                my $response = ($_[$index+1] =~ /Byte\s+\(1\)\s+\d+\s+:(\w+)/) ? $HCACK{$1} : "";
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> Cmd:$transactions{$transID} $response *\\\n");
            }elsif($secsCmd eq "S3F17"){
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                if($_[$index+2] =~ /Ascii\(1\)\s+\d+\s+:(\w+)/){
                    $S3F17Cmd = $1;
                    my $cID = "";
                    my $portID = -1;
                    if($_[$index+3] =~ /Ascii\(1\)\s+\d+\s+:(\w+)/){
                        $cID = $1;
                        $transactions{$transID} = $cID;
                        if ($S3F17Cmd eq "ProceedWithCarrier"){
                            $S3F17Cmd .= (!defined($carriers{$cID})) ? "_1" : "_2";
                        }
                        $portID = ($_[$index+4] =~ /UInt1\(1\)\s+1\s+:(\d+)/) ? $1 : "-1";
                        $carriers{$cID} = $portID;
                    }
                    #say "$S3F17Cmd: cID";
                    my $task = ($_[$index+5] =~ /List\s+\(1\)\s+0/) ? "" : "Mapping";
                    push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> CID.$cID PID.$portID :$task $S3F17Cmd *\\\n");
                }
            }elsif($secsCmd eq "S3F18"){
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                if($_[$index+1] =~ /UInt1\(1\)\s+1\s+:(\d+)/){
                    my $caAck = $CAACK{$1};
                    if($_[$index+4] =~ /UInt1\(1\)\s+1\s+:(\d+)/){
                        my $errCode = $errorCode{$1};
                        my $errText = ($_[$index+5] =~ /Ascii\(1\)\s+\d+\s+:(\w+)/) ? $1 : "";
                        push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> $caAck Error: $errCode ($errText) *\\\n");
                    }elsif(defined $transactions{$transID}){
                        push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> CID.$transactions{$transID} $caAck *\\\n");
                    }else{
                        push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> $caAck *\\\n");
                    }
                }
            }elsif($secsCmd eq "S5F1"){
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                my $alState = ($_[$index+1] =~ /:80/) ? "(ON)" : "(OFF)";
                my $alID = ($_[$index+2] =~ /:\d+\s+\((\w+)\)/) ? $1 : "";
                my $alText = ($_[$index+3] =~ /:(.*)/) ? $1 : "";
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> ALARM:$alID $alText $alState\n");
            }elsif($secsCmd eq "S5F3"){
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                my $request = ($_[$index+1] =~ /:80/) ? "Enable" : "Disable";
                my $number = ($_[$index+2] =~ /UInt4\(1\)\s+(\d+)/) ? $1 : -1;
                $request .= ($number == 0) ? " All Alarms" : "Alarm: $number";
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> $request *\\\n");
            }elsif($secsCmd eq "S5F4"){
                my %ACK5 = (0 => "Ok", 1 => "Can Not");
                my $response = ($line =~ /.*?"Byte\s+\(1\)\s+\d+\s+:(\d+)"/) ? $ACK5{int($1)} : "Unknown Response: " . $1;
                $line =~ s/"Byte\s+\(1\)\s+\d+\s+:.*$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t\t \\* TN -> $response *\\\n");
            }elsif($secsCmd eq "S6F5"){
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                my $number = ($_[$index+2] =~ /UInt4\(1\)\s+\d+\s+:(\d+)/) ? $1 : -1;
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> Multi-block Data Send Inquire for $number bytes *\\\n");
            }elsif($secsCmd eq "S6F11" && $line =~ /.*"List\s+\(1\)\s+3$/){ #sometimes there's incomplete record does not have <List \(1\)   3> at the EOL. It's a LogViewer bug
                $countU4 = 0;
                $rptSize = ($_[$index+3] =~ /L.*?(\d+)$/) ? $1 : 0; #Needs to know how many reports in each event
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag>\n");
                push(@decodeFile, $timeStamp, "\t<L \n");
            }elsif($secsCmd eq "S7F19" || $secsCmd eq "S7F85"){
                push(@decodeFile, $line);
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> Request to list all Recipes in Dir *\\\n");
            }elsif($secsCmd eq "S7F20" || $secsCmd eq "S7F85"){
                my $number = ($line =~ /"List\s+\(\d+\)\s+(\d+)/) ? $1 : "";
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> There're $number Recipes *\\\n");
            }elsif($secsCmd eq "S7F25" || $secsCmd eq "S7F85"){
                my $recipe = ($line =~ /"Ascii\(1\)\s+\d+\s+:([\w_-|.]*).*/) ? $1 : "";
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                $decodeFile[$#decodeFile] =~ s/"Ascii\(1\)\s+\d+\s+:.*//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> Upload: $recipe\n");
            }elsif($secsCmd eq "S9F1"){
                my $alert = ($line =~ /.*?"Byte\s+\(1\)\s+\d+\s+:(.*?)"/) ? $1 : "";
                $line =~ s/"Byte\s+\(1\)\s+\d+\s+:.*$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t\t \\* TN -> Unknown Device ID Sent: $alert *\\\n");
            }elsif($secsCmd eq "S9F7"){
                my $alert = ($line =~ /.*?"Byte\s+\(1\)\s+\d+\s+:(.*?)"/) ? $1 : "";
                $line =~ s/"Byte\s+\(1\)\s+\d+\s+:.*$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t\t \\* TN -> Illegal Data: $alert *\\\n");
            }elsif($secsCmd eq "S9F9"){
                my $alert = ($line =~ /.*?"Byte\s+\(1\)\s+\d+\s+:(.*?)"/) ? $1 : "";
                $line =~ s/"Byte\s+\(1\)\s+\d+\s+:.*$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t\t \\* TN -> Transaction Timeout <$alert> *\\\n");
            }elsif($secsCmd eq "S14F9"){
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                my $cjID = $_[$index+6];
                if ($cjID =~ /Ascii\(1\)\s+\d+\s+:(.*)/){
                    $cjID = $1;
                    $transactions{$transID} = $cjID;
                }
            }elsif($secsCmd eq "S14F10"){
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                if($_[$index+4] =~ /UInt1\(1\)\s+1\s+:(\d+)/){
                    if(defined $transactions{$transID}){
                        push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> CJ:$transactions{$transID} created $OBJACK{$1} *\\\n");
                    }else{
                        push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> created $OBJACK{$1} *\\\n");
                    }
                }elsif(defined $transactions{$transID}){
                    push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> CJ:$transactions{$transID} *\\\n");
                }else{
                    push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag>\n");
                }
            }elsif($secsCmd eq "S16F15"){
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                if ($_[$index+4] =~ /Ascii\(1\)\s+\d+\s+:(.*)/){
                    $transactions{$transID} = $1;
                }
            }elsif($secsCmd eq "S16F16"){
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                if ($_[$index+2] =~ /Ascii\(1\)\s+\d+\s+:(.*)/){
                    my $pjID = $1;
                    my $acka = ($_[$index+4] =~ /Truth\(1\)\s+\d+\s+:(\w+)/) ? $ACKA{$1} : "";
                    push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> PJ:$pjID created $acka *\\\n");
                }elsif(defined $transactions{$transID}){
                    push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> PJ:$transactions{$transID} $_[$index+2] *\\\n");
                }else{
                    push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> $_[$index+2] *\\\n");
                }
            }else{
                $line =~ s/"List\s+\(\d+\)\s+\d+$//g; #get rid of this portion EOL because it was supposed to be on next line
                push(@decodeFile, $line);
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag>\n");
            }
        }elsif($secsCmd eq "S2F15"){
            if($line =~ /^((\s*)(\w+\s*\(1\))(.*))/i) {
                my $currentSpace = $2;
                my $dataF = $dataFormat{$3};
                my $data = ($1 =~ /UInt4\(1\)\s+\d+\s+:(\d+)/) ? $1 : -1;
                #Takecare of closing bracket '>' when it starts changing space to smaller
                while (length($currentSpace) < length($lastSpace)) {
                    my $latestLastSpace = pop @allSpaces;
                    while (length($lastSpace) == length($latestLastSpace)) {
                        $latestLastSpace = pop @allSpaces; #keep popping to get space smaller than the last push
                    }
                    if (length($lastSpace) > length($latestLastSpace)) {
                        push(@decodeFile, "$latestLastSpace>\n"); #right space for closing bracket >
                        $lastSpace = $latestLastSpace;            #update lastSpace because it's now smaller
                    }
                }
                push(@allSpaces, $currentSpace);
                $lastSpace = $currentSpace;
                if($dataF eq "L") {
                    push(@decodeFile, "$currentSpace<L \n");
                    $countU4 = 1;
                }elsif($countU4 == 1){
                    $countU4++;
                    if(defined $VID_DESC_MAP{$data}){
                        push(@decodeFile, "$currentSpace<$dataF $data>\t\t \\* TN -> $data:$VID_DESC_MAP{$data} *\\\n");
                    }else{
                        push(@decodeFile, "$currentSpace<$dataF $data>\t\t \\* TN -> $data=Unknown VID *\\\n");
                    }
                }else{
                    $countU4--;
                    push(@decodeFile, "$currentSpace<$dataF $data>\n");
                }
            }
        }elsif($secsCmd eq "S2F23"){
            if($line =~ /^((\s*)(\w+\s*\(1\))(.*):(\w+))/i) {
                my $data = $1;
                my $currentSpace = $2;
                #Takecare of closing bracket '>' when it starts changing space to smaller
                while (length($currentSpace) < length($lastSpace)){
                    my $latestLastSpace = pop @allSpaces;
                    while(length($lastSpace) == length($latestLastSpace)){
                        $latestLastSpace = pop @allSpaces; #keep popping to get space smaller than the last push
                    }
                    if(length($lastSpace) > length($latestLastSpace)){
                        push(@decodeFile, "$latestLastSpace>\n"); #right space for closing bracket >
                        $lastSpace = $latestLastSpace; #update lastSpace because it's now smaller
                    }
                }
                push(@allSpaces, $currentSpace);
                $lastSpace = $currentSpace;
                if(defined $dataFormat{$3}) {
                    my $dataF = $dataFormat{$3};
                    #say "dataF: $dataF";
                    if ($dataF eq "U4" && $data =~ /\d+\s+:(\d+)/) {
                        if(defined $VID_DESC_MAP{$1}){
                            push(@decodeFile, "$currentSpace<$dataF $1>\t\t \\* TN -> VID: $VID_DESC_MAP{$1} *\\\n");
                        }else {
                            push(@decodeFile, "$currentSpace<$dataF $1> \n");
                        }
                    }elsif ($dataF eq "A"){
                        push(@decodeFile, "$currentSpace<$dataF $5>\n");
                    }else{
                        push(@decodeFile, "$currentSpace<$dataF \n");
                    }
                }
            }
        }elsif($secsCmd eq "S2F33"){
            if($line =~ /^((\s*)(\w+\s*\(1\))(.*))/i) {
                my $data = $1;
                my $currentSpace = $2;
                #Takecare of closing bracket '>' when it starts changing space to smaller
                while (length($currentSpace) < length($lastSpace)){
                    my $latestLastSpace = pop @allSpaces;
                    while(length($lastSpace) == length($latestLastSpace)){
                        $latestLastSpace = pop @allSpaces; #keep popping to get space smaller than the last push
                    }
                    if(length($lastSpace) > length($latestLastSpace)){
                        push(@decodeFile, "$latestLastSpace>\n"); #right space for closing bracket >
                        $lastSpace = $latestLastSpace; #update lastSpace because it's now smaller
                    }
                }
                push(@allSpaces, $currentSpace);
                $lastSpace = $currentSpace;
                if(defined $dataFormat{$3}) {
                    my $dataF = $dataFormat{$3};
                    #say "dataF: $dataF";
                    if ($dataF eq "U4" && $data =~ /\d+\s+:(\d+)/) {
                        if(defined $VID_DESC_MAP{$1}){
                            push(@decodeFile, "$currentSpace<$dataF $1>\t\t \\* TN -> VID: $VID_DESC_MAP{$1} *\\\n");
                        }else {
                            if(defined $RPID_DESC_MAP{$1}){
                                push(@decodeFile, "$currentSpace<$dataF $1>\t\t\t \\* TN -> $RPID_DESC_MAP{$1} *\\\n");
                            }else{
                                push(@decodeFile, "$currentSpace<$dataF $1> \n");
                            }
                        }
                    }else{
                        push(@decodeFile, "$currentSpace<$dataF \n");
                    }
                }
            }
        }elsif($secsCmd eq "S2F35"){
            if($line =~ /^((\s*)(\w+\s*\(1\))(.*))/i) {
                my $data = $1;
                my $currentSpace = $2;
                #Takecare of closing bracket '>' when it starts changing space to smaller
                while (length($currentSpace) < length($lastSpace)){
                    my $latestLastSpace = pop @allSpaces;
                    while(length($lastSpace) == length($latestLastSpace)){
                        $latestLastSpace = pop @allSpaces; #keep popping to get space smaller than the last push
                    }
                    if(length($lastSpace) > length($latestLastSpace)){
                        push(@decodeFile, "$latestLastSpace>\n"); #right space for closing bracket >
                        $lastSpace = $latestLastSpace; #update lastSpace because it's now smaller
                    }
                }
                push(@allSpaces, $currentSpace);
                $lastSpace = $currentSpace;
                if(defined $dataFormat{$3}) {
                    my $dataF = $dataFormat{$3};
                    #say "dataF: $dataF";
                    if ($dataF eq "U4" && $data =~ /\d+\s+:(\d+)/) {
                        if(defined $CEID_DESC_MAP{$1}){
                            push(@decodeFile, "$currentSpace<$dataF $1>\t\t\t \\* TN -> CEID: $CEID_DESC_MAP{$1} *\\\n");
                        }else {
                            if(defined $RPID_DESC_MAP{$1}){
                                push(@decodeFile, "$currentSpace<$dataF $1>\t\t\t \\* TN -> $RPID_DESC_MAP{$1} *\\\n");
                            }else{
                                push(@decodeFile, "$currentSpace<$dataF $1> \n");
                            }
                        }
                    }else{
                        push(@decodeFile, "$currentSpace<$dataF \n");
                    }
                }
            }
        }elsif($secsCmd eq "S6F11"){
            if($line =~ /^((\s*)(\w+\s*\(1\))(.*))/i) {
                my $data = $1;
                my $currentSpace = $2;
                #Takecare of closing bracket '>' when it starts changing space to smaller
                while (length($currentSpace) < length($lastSpace)){
                    my $latestLastSpace = pop @allSpaces;
                    while(length($lastSpace) == length($latestLastSpace)){
                        $latestLastSpace = pop @allSpaces; #keep popping to get space smaller than the last push
                    }
                    if(length($lastSpace) > length($latestLastSpace)){
                        push(@decodeFile, $timeStamp, "\t$latestLastSpace>\n"); #right space for closing bracket >
                        $lastSpace = $latestLastSpace; #update lastSpace because it's now smaller
                    }
                }
                push(@allSpaces, $currentSpace);
                $lastSpace = $currentSpace;
                if(defined $dataFormat{$3}){
                    my $dataF = $dataFormat{$3};
                    #say "dataF: $dataF";
                    if ($data =~ /\d+\s+:(\d+)/ || $data =~ /\d+\s+:(\w*)["]*\s*/ || $data =~ /\s+(\d+)/){
                        my $number = $1;
                        if ($dataF eq "U4"){
                            $countU4++;
                            if ($countU4 == 2){
                                if(defined $CEID_DESC_MAP{$number}){
                                    push(@decodeFile, $timeStamp, "\t$currentSpace<$dataF $number >\t\t\t \\* TN -> CEID: $CEID_DESC_MAP{$number} *\\\n");
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
                                        push(@decodeFile, $timeStamp, "\t$currentSpace<$dataF $number> \t\t \\* TN -> $vidName *\\\n");
                                    }else{
                                        push(@decodeFile, $timeStamp, "\t$currentSpace<$dataF $number> \n");
                                    }
                                }
                            }
                        }else{
                            if(@vidNames && $dataF ne "L"){
                                my $vidName = pop @vidNames;
                                push(@decodeFile, $timeStamp, "\t$currentSpace<$dataF $number> \t\t \\* TN -> $vidName *\\\n");
                            }else{
                                push(@decodeFile, $timeStamp, "\t$currentSpace<$dataF \n"); #This is the <L line
                            }
                        }
                    }
                }else{
                    push(@decodeFile, $timeStamp, "\n");
                }
            }else{
                push(@decodeFile, $timeStamp, "\n");
            }
        }elsif($secsCmd eq "S14F9") {
            if ($line =~ /Ascii\(1\)\s+\d+\s+:(.*)/) {
                #say "method: $1";
                if ($1 eq "StartMethod") {
                    my $method = ($_[$index + 1] =~ /Truth\(1\)\s+\d+\s+:(\w+)/) ? $START_METHOD{$1} : "";
                    push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> CJ:$transactions{$transID} Start:$method *\\\n");
                }
            }
        }elsif($secsCmd eq "S16F15"){
            my $method = "";
            if ($line =~ /Truth\(1\)\s+\d+\s+:(\w+)/){
                $method = $START_METHOD{$1};
                push(@decodeFile, $timeStamp, "\t<$secsCmd$resFlag> \t\t\t\t \\* TN -> PJ:$transactions{$transID} Start:$method *\\\n");
            }
        }
    }
    while(@allSpaces){
        my $latestLastSpace = pop @allSpaces;
        if (length($lastSpace) > length($latestLastSpace)){
            if($secsCmd eq "S2F33" || $secsCmd eq "S2F35"){
                push(@decodeFile, "$latestLastSpace>\n");
            }else {
                push(@decodeFile, $timeStamp, "\t$latestLastSpace>\n");
            }
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
                            my $vid = (defined $VID_DESC_MAP{$1}) ? $1 . ":" . $VID_DESC_MAP{$1} : $1 . ":Unknown";
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
                my $RPID = 0;
                foreach my $line (@fileContent) {
                    next if(($line =~ /^#/) || ($line =~ /^$/)); #skip comments
                    if($line =~ /^RPTID\s+:.*:\s+(\d+)/){
                        $RPID = $1;
                    }
                    if($RPID && $line =~ /^\s+VID\s+:.*:\s+(\d+)/){
                        my $vid = ($VID_DESC_MAP{$1}) ? $1 . ":". $VID_DESC_MAP{$1} : $1;
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
            if ($_ =~ /^[VID|ECID].*.txt?$/i) {
                say "VIDs from: $tempfile";
                foreach my $line (@fileContent) {
                    next if (($line =~ /^#/) || ($line =~ /^$/));
                    if ($line =~ /[V|EC]ID\s+:\s+[\$]*\w+\s+:\s+(\d+)\s+:\s+(.*)\s+:/) {
                        $VID_DESC_MAP{$1} = $2;
                        #say "$1 = $2";
                    }
                }
            }
        }
    }
}

sub getFirstTimeStamp {
    #say "->getFirstTimeStamp()";
    open (INFILE, $_[0]) || die "error! can't open $_[0]\n";
    my @fileContent = <INFILE>;
    close(INFILE) || die "error! can't close $_[0]\n";
    my $timePattern = '"(\d+\/\d+\/\d+)","(\d+:\d+:\d+)"'; #eg. "2020/09/28","17:09:20"
    my $timeStamp = "";
    while(@fileContent){    #make sure there's timestamp data on $firstLine
        if ($timeStamp !~ /$timePattern/) {
            $timeStamp = shift(@fileContent); #continue until getting a line with timestamp
        }else{
            $timeStamp = $2 . ", " . $1;
            last;
        }
    }

    return $timeStamp;
}

sub getLastTimeStamp {
    #say "->getLastTimeStamp()";
    open (INFILE, $_[0]) || die "error! can't open $_[0]\n";
    my @fileContent = <INFILE>;
    close(INFILE) || die "error! can't close $_[0]\n";
    my $timePattern = '"(\d+\/\d+\/\d+)","(\d+:\d+:\d+)"'; #eg. "2020/09/28","17:09:20"
    my $timeStamp = "";
    while(@fileContent){    #make sure there's timestamp data on $lastLine
        if ($timeStamp !~ /$timePattern/) {
            $timeStamp = pop(@fileContent); #continue until getting a line with timestamp
        }else{
            $timeStamp = $2 . ", " . $1;
            last;
        }
    }
    #say "timeStamp: $timeStamp";
    return $timeStamp;
}

sub compareTimeStamp {
    my $dateformat = "%H:%M:%S, %Y/%m/%d"; #timeStamp: 23:43:47, 2020/09/27 --- Must use %Y for "2020", %y for "20"
    my $date1 = $_[0];
    my $date2 = $_[1];

    $date1 = Time::Piece->strptime($date1, $dateformat);
    $date2 = Time::Piece->strptime($date2, $dateformat);

    if ($date2 < $date1) {
        return 1;
    } else {
        return 0;
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