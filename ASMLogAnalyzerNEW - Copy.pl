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
use Cwd;

say"Start ASMLogAnalyzer...";

# my $top  = MainWindow->new;
# my $start_dir = getcwd;
# say"start_dir: ", $start_dir;
# my $FSref = $top->FileSelect(-directory => $start_dir);
# my $libSource = $FSref->Show;
# say"$libSource: ", $libSource;

my $libSource = 'D:\ASM-Parser\Info\ALD\ConvertedEventXp.txt';

#my $libSource = ".\\Lib\\Ceids.txt"; #must have the ceid:name pairs library text file
my $logDir = ".\\Logs\\"; #where the interested mes logs are stored to analyze
say"libSource: $libSource, and logDir: $logDir";
#We need to build CEID dictionary to transform the ids to names
open (INFILE, "$libSource") || die "ERROR! Can't open $libSource\n";
my @libBucket = <INFILE>;
close(INFILE) || die "ERROR! Can't close $libSource\n";
my %recipeStartedInfo;
my %recipeFinishedInfo;
my %wfMoveStartedInfo;
my %wfMoveFinishedInfo;
my %streamInfo;
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
        #say ("CEID: $2, = $3");
        $ceidDict{$2} = $3;
    }
}
#log file listed the newest data on top and oldest data at the bottom.
#manipulating the log file to get all data in the right order to process.
my @mesLogs;
find (\&gatherLogs,$logDir);
@mesLogs = sort {$b cmp $a} @mesLogs;
my $lastNumber = 0;
my @sortedMesLogs;
my $change = 0;
my @batchOne;
my @batchTwo;

# log is versioning from 1->99 then roll over
# so we need to get the log files listed in order by creation time
for(my $count = 0; $count < @mesLogs; $count++) {
    my $logName = $mesLogs[$count];
    if($logName =~/.*_(\d+).csv/i){
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

push(@sortedMesLogs, reverse @batchTwo, @batchOne);

my @logData;
foreach my $logFile (@sortedMesLogs){
    say"sorted : $logDir$logFile";
    open (INFILE, "$logDir$logFile") || die "ERROR! Can't open $logFile\n";
    my @bucket = <INFILE>;
    close(INFILE) || die "ERROR! Can't close $logFile\n";
    push(@logData, reverse @bucket);
}

my @logBucket;
foreach my $line_str (@logData){
    if ($line_str =~ /^"\d+",(.*)/i) {
        #say "1: $1";
        push(@logBucket, $1); #get rid of the first index item to start from date item
        #if ($1 =~ /^("\d+\/\d+",)("\d+:\d+:\d+",)/i) {
        #        if ($1 =~ /^"(\d+\/\d+)","(\d+:\d+:\d+)",(".*?",)(".*?",)("(\d+).*",)/i) { say "1: $1, 2: $2, 3: $3, 4: $4, 5: $5, 6: $6"; exit;}
    }
}

#initialize hashes
for(my $i = 1; $i <5; $i++) {
    initializeChamberRecipeProcessTimeInfo($i);
    initializeChamberRecipeStepTimeInfo($i);
    initializeWfFERbtMoveTimeInfo($i);
    initializeWfBERbtMoveTimeInfo($i);
}

sub initializeChamberRecipeProcessTimeInfo {
    $recipeStartedInfo{"RC".$_[0]."RecipeStarted"} = "";
    $recipeFinishedInfo{"RC".$_[0]."RecipeFinished"} = "";
}

sub initializeChamberRecipeStepTimeInfo {
    $recipeStartedInfo{"RC".$_[0]."StepStarted"} = "";
    $recipeFinishedInfo{"RC".$_[0]."StepFinished"} = "";
}

sub initializeWfFERbtMoveTimeInfo {
    $wfMoveStartedInfo{"WaferMovedStartLP".$_[0]."FERbt"} = "";
    $wfMoveFinishedInfo{"WaferMovedFinishFERbtLP".$_[0]} = "";
}

sub initializeWfBERbtMoveTimeInfo {
    $wfMoveStartedInfo{"WaferMovedStartRC".$_[0]."BERbt"} = "";
    $wfMoveFinishedInfo{"WaferMovedFinishBERbtRC".$_[0]} = "";
}

my $NoS1F12 = 1;
my @annotatedData;
GetStreamDefinition(); #initialize %streamInfo
#Because events of different RC & LP are published whenever they're ready
#Therefore, they're all mixing altogether in the log.
#We must traverse several times to pickup all events of all RC & LP
foreach my $line_str (@logBucket){
    my $recStartTime = "";
    my $recFinishTime = "";
    my $stepStartTime = "";
    my $stepFinishTime = "";
    my $processTime = "";
    my $stepTime = "";
    my $rcInTime = "";
    my $rcOutTime = "";
    my $rcInOutTime = "";
    my $lpOutInTime = "";
    my $lpInTime = "";
    my $lpOutTime = "";
    my $stepCount = 0;
    my $step = 0;
        #say $line_str;
    #    foreach my $line_str (@logBucket) {
        #print "line found event $line_str\n";
        #skip all the comments or blank lines
        next if (($line_str =~ /^#/) || ($line_str =~ /^$/));

        if ($line_str =~ /^"(\d+\/\d+)","(\d+:\d+:\d+)",(".*?",)"(S\d+F\d+)"(.*)/i) {
            #say "1: $1, 2: $2, 3: $3, 4: $4, 5: $5, 6: $6";
            #print "line found $line_str\n";
            #print"1:$1 2:$2 3:$3 4:$4 5:$5 6:$6 7:$7 8:$8 9:$9 10:$10\n";
            my $date = $1;
            my $time = $2;
            my $dateTime = $date . " " . $time;
            my $direction = $3;
            my $secsCmd = $4;
            my $remain = $5;
            #say "1: $1, 2: $2, 3: $3, 4: $4, 5: $5";
            if ($secsCmd eq "S6F11" && $remain =~ /,"(\d+).*",/i) {
                #We're just interested on events
                my $ceid = $1;
                my $ceidDetail = "CEID:" . $ceid . " " . $ceidDict{$ceid};
                # say "$ceid: $ceidDetail";
                if ($ceidDict{$ceid} =~ /RC(\d)RecipeStarted/i) { # RCxRecipeStarted event
                    my $chamber = "RC".$1;
                    $stepCount = 0;
                    $recStartTime = $dateTime; #Time the recipe starts on the tool
                    #Start time must happen first; otherwise, this finish time does not have start time
                    $recipeStartedInfo{$chamber."RecipeStarted"} = $recStartTime;
                    if($recipeFinishedInfo{$chamber."RecipeFinished"} ne "") {
                        $recipeFinishedInfo{$chamber."RecipeFinished"} = ""; #clear it for the right data coming
                    }
                    #$ceidDetail = "CEID:" . $ceid . " (". $chamber . " Started)";
                }elsif ($ceidDict{$ceid} =~ /RC(\d)RecipeFinished/i) { # RCxRecipeFinished event
                    my $chamber = "RC".$1;
                    $stepCount = 0;
                    $recFinishTime = $dateTime; #Time the recipe finishes on the tool
                    $recipeFinishedInfo{$ceidDict{$ceid}} = $recFinishTime;
                    $recStartTime = $recipeStartedInfo{$chamber."RecipeStarted"};
                    if($recStartTime ne "") {
                        $processTime = str2time($recFinishTime) - str2time($recStartTime);
                        $ceidDetail = "CEID:" . $ceid . " " . $ceidDict{$ceid} . " (" . $chamber . " Finished in " . strftime("\%H:\%M:\%S", gmtime($processTime)) . ")";
                        initializeChamberRecipeProcessTimeInfo($1); #reset for new data coming
                    }
                }elsif ($ceidDict{$ceid} =~ /RC(\d)StepStarted/i) { # RCxStepStarted event
                    my $chamber = "RC".$1;
                    $stepCount++;
                    $stepStartTime = $dateTime; #Time recipe's step starts
                    $step = "Step" . $stepCount;
                    #Start time must happen first; otherwise, this finish time does not have start time
                    $recipeStartedInfo{$chamber."StepStarted"} = $stepStartTime;
                    if($recipeFinishedInfo{$chamber."StepFinished"} ne "") {
                        $recipeFinishedInfo{$chamber."StepFinished"} = ""; #clear it for the right data coming
                    }
                    #$ceidDetail = "CEID:" . $ceid . " (" . $chamber . " " . $step . " Started)";
                }elsif ($ceidDict{$ceid} =~ /RC(\d)StepFinished/i) {
                    my $chamber = "RC".$1;
                    $stepFinishTime = $dateTime; #Time recipe's step finishes
                    $stepStartTime = $recipeStartedInfo{$chamber."StepStarted"};
                    if($stepStartTime ne "" ) {
                        $stepTime = str2time($stepFinishTime) - str2time($stepStartTime);
                        $ceidDetail = "CEID:" . $ceid . " " . $ceidDict{$ceid} . " (" . $chamber . " " . $step . " Finished in " . strftime("\%H:\%M:\%S", gmtime($stepTime)) . ")";
                        initializeChamberRecipeStepTimeInfo($1); #reset for new data coming
                    }
                }elsif ($ceidDict{$ceid} =~ /WaferMovedStartLP(\d)FERbt/i) {
                    my $loadport = "LP".$1;
                    #print"Wafer exits LoadPort: $lpWaferMovedStart\n";
                    $lpOutTime = $dateTime; #Time LP->FERbt starts is time Wafer exits LoadPort
                    $wfMoveStartedInfo{"WaferMovedStart".$loadport."FERbt"} = $lpOutTime;
                    if($wfMoveFinishedInfo{"WaferMovedFinishFERbt".$loadport} ne "") {
                        $wfMoveFinishedInfo{"WaferMovedFinishFERbt".$loadport} = ""; #clear it for the right data coming
                    }
                    #$ceidDetail = "CEID:" . $ceid . " (" . $loadport . " sending Wafer to RC )";
                }elsif ($ceidDict{$ceid} =~ /WaferMovedFinishFERbtLP(\d+)/i) {
                    my $loadport = "LP".$1;
                    #print"Wafer returns to LoadPort: $lpWaferMovedFinish\n";
                    $lpInTime = $dateTime; #Time FERbt->LP finishes is time Wafer returns to LoadPort
                    $lpOutTime = $wfMoveStartedInfo{"WaferMovedStart".$loadport."FERbt"};
                    if($lpOutTime ne "") {
                        $lpOutInTime = str2time($lpInTime) - str2time($lpOutTime);
                        $ceidDetail = "CEID:" . $ceid . " " . $ceidDict{$ceid} . " (".$loadport." Finished Wafer in ".strftime("\%H:\%M:\%S", gmtime($lpOutInTime)).")";
                        initializeWfFERbtMoveTimeInfo($1); #reset for new data coming
                    }
                }elsif ($ceidDict{$ceid} =~ /WaferMovedStartRC(\d)BERbt/i) {
                    my $chamber = "RC".$1;
                    #print"Wafer enters Chamber: $rcWaferMovedFinish\n";
                    $rcInTime = $dateTime; #Time BERbt->RC finishes is time Wafer enters RC
                    $wfMoveStartedInfo{"WaferMovedStart".$chamber."BERbt"} = $rcInTime;
                    if($wfMoveFinishedInfo{"WaferMovedFinishBERbt".$chamber} ne "") {
                        $wfMoveFinishedInfo{"WaferMovedFinishBERbt".$chamber} = ""; #clear it for the right data coming
                    }
                    #$ceidDetail = "CEID:" . $ceid . " (" . $chamber . " has Wafer Entered)" ;
                }elsif ($ceidDict{$ceid} =~ /WaferMovedFinishBERbtRC(\d)/i) {
                    my $chamber = "RC".$1;
                    #print"Wafer exits Chamber: $rcWaferMovedStart\n";
                    $rcOutTime = $dateTime; #Time RC->BERbt finishes is time Wafer exits RC
                    $rcInTime = $wfMoveStartedInfo{"WaferMovedStart".$chamber."BERbt"};
                    if($rcInTime ne "") {
                        $rcInOutTime = str2time($rcOutTime) - str2time($rcInTime);
                        $ceidDetail = "CEID:" . $ceid . " " . $ceidDict{$ceid} . " (" . $chamber . " Finished Wafer in " . strftime("\%H:\%M:\%S", gmtime($rcInOutTime)) . ")";
                        initializeWfBERbtMoveTimeInfo($1); #reset for new data coming
                    }
                }
                #say "$ceid: $ceidDetail";
                push(@annotatedData, $dateTime . ',' . $direction . $secsCmd . ',' . $ceidDetail . "\n");
            }elsif ($line_str =~ /"(S\d+F\d+)"/i) {
                $secsCmd = $1;
                #say "other : $secsCmd";
                if ($secsCmd eq "S6F12" && $NoS1F12 == 1) {
                    next;
                }
                push(@annotatedData, $dateTime . ',' . $direction . $secsCmd . ',' . $streamInfo{$secsCmd} . "\n");
            }
        }
    }
#Whatever events that we did not annotate or giving names in above task, now we do
#so that all CEIDs will be transforming to more meaningful data

#We can write back to the same log file but I chose to output to the new file
my $tempfile = $logDir."logUpdated.txt";
open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
print OUTFILE @annotatedData;
close (OUTFILE) || die "ERROR! Can't close $tempfile\n";

sub gatherLogs() {
    my $currfname = $_ ; #$File::Find::name; #$_;
    if($currfname =~/Meslog.ml_\d+(.csv)/i){
        push(@mesLogs,$currfname);
    }
}

sub GetStreamDefinition{
    say("GetStreamDefinition");
    $streamInfo{"S1F0"} = "Abort Transaction";
    $streamInfo{"S1F1"} = "Are You There Request";
    $streamInfo{"S1F2"} = "On Line Data";
    $streamInfo{"S1F3"} = "Selected Equipment Status Request";
    $streamInfo{"S1F4"} = "Selected Equipment Status Data";
    $streamInfo{"S1F11"} = "Status Variable Namelist Reply";
    $streamInfo{"S1F12"} = "Status Variable Namelist Reply";
    $streamInfo{"S1F13"} = "Establish Communications Request ";
    $streamInfo{"S1F14"} = "Establish Communications Request Acknowledge";
    $streamInfo{"S1F15"} = "Request OFF-LINE";
    $streamInfo{"S1F16"} = "OFF-LINE Acknowledge";
    $streamInfo{"S1F17"} = "Request ON-LINE";
    $streamInfo{"S1F18"} = "ON-LINE Acknowledge";
    $streamInfo{"S1F65"} = "Request ON-LINE LOCAL";
    $streamInfo{"S1F66"} = "ON-LINE LOCAL Acknowledge ";
    $streamInfo{"S1F67"} = "Request OFF-LINE REMOTE";
    $streamInfo{"S1F68"} = "OFF-LINE REMOTE Acknowledge ";
    $streamInfo{"S2F0"} = "Abort Transaction";
    $streamInfo{"S2F13"} = "Equipment Constant Request";
    $streamInfo{"S2F14"} = "Equipment Constant Data";
    $streamInfo{"S2F15"} = "New Equipment Constant Send";
    $streamInfo{"S2F16"} = "New Equipment Constant Acknowledge";
    $streamInfo{"S2F17"} = "Date and Time Request";
    $streamInfo{"S2F18"} = "Date and Time Data";
    $streamInfo{"S2F23"} = "Trace Initialize Send";
    $streamInfo{"S2F24"} = "Trace Initialize Acknowledge";
    $streamInfo{"S2F25"} = "Loopback Diagnostic Request";
    $streamInfo{"S2F26"} = "Loopback Diagnostic Data";
    $streamInfo{"S2F29"} = "Equipment Constant Namelist Request";
    $streamInfo{"S2F30"} = "Equipment Constant Namelist";
    $streamInfo{"S2F31"} = "Date and Time Set Request";
    $streamInfo{"S2F32"} = "Date and Time Set Acknowledge";
    $streamInfo{"S2F33"} = "Define Report";
    $streamInfo{"S2F34"} = "Define Report Acknowledge";
    $streamInfo{"S2F35"} = "Link Event Report";
    $streamInfo{"S2F36"} = "Link Event Report Acknowledge";
    $streamInfo{"S2F37"} = "Enable/Disable Event Report";
    $streamInfo{"S2F38"} = "Enable/Disable Event Report Acknowledge";
    $streamInfo{"S2F39"} = "Multi-block Inquire";
    $streamInfo{"S2F40"} = "Multi-block Grant";
    $streamInfo{"S2F41"} = "Host Command Send";
    $streamInfo{"S2F42"} = "Host Command Acknowledge";
    $streamInfo{"S2F43"} = "Reset Spooling Streams and Functions";
    $streamInfo{"S2F44"} = "Reset Spooling Acknowledge";
    $streamInfo{"S2F45"} = "Define Variable Limit Attributes";
    $streamInfo{"S2F46"} = "Variable Limit Attribute Acknowledge";
    $streamInfo{"S2F47"} = "Variable Limit Attribute Request";
    $streamInfo{"S2F48"} = "Variable Limit Attributes Send";
    $streamInfo{"S2F49"} = "Enhanced Remote Command";
    $streamInfo{"S2F50"} = "Enhanced Remote Command Acknowledge";
    $streamInfo{"S3F0"} = "Abort Transaction";
    $streamInfo{"S3F17"} = "Carrier Action Request ";
    $streamInfo{"S3F18"} = "Carrier Action Acknowledge ";
    $streamInfo{"S3F25"} = "Load Port Action Request ";
    $streamInfo{"S3F26"} = "Load Port Action Acknowledge ";
    $streamInfo{"S3F27"} = "Change Access";
    $streamInfo{"S3F28"} = "Change Access Acknowledge";
    $streamInfo{"S3F29"} = "Carrier Tag Read Request";
    $streamInfo{"S3F30"} = "Carrier Tag Read Data";
    $streamInfo{"S3F31"} = "Carrier Tag Write Data Request";
    $streamInfo{"S3F32"} = "Carrier Tag Write Data Acknowledge";
    $streamInfo{"S5F0"} = "Abort Transaction";
    $streamInfo{"S5F1"} = "Alarm Report Send";
    $streamInfo{"S5F2"} = "Alarm Report Acknowledge";
    $streamInfo{"S5F3"} = "Enable/Disable Alarm Send";
    $streamInfo{"S5F4"} = "Enable/Disable Alarm Acknowledge";
    $streamInfo{"S5F5"} = "List Alarms Request";
    $streamInfo{"S5F6"} = "List Alarm Data";
    $streamInfo{"S5F7"} = "List Enabled Alarm Request";
    $streamInfo{"S5F8"} = "List Enabled Alarm Data";
    $streamInfo{"S6F0"} = "Abort Transaction";
    $streamInfo{"S6F1"} = "Trace Data Send";
    $streamInfo{"S6F2"} = "Trace Data Acknowledge";
    $streamInfo{"S6F5"} = "Multi-block Data Send Inquire";
    $streamInfo{"S6F6"} = "Multi-block Grant";
    $streamInfo{"S6F11"} = "Event Report Send";
    $streamInfo{"S6F12"} = "Event Report Acknowledge";
    $streamInfo{"S6F15"} = "Event Report Request";
    $streamInfo{"S6F16"} = "Event Report Data";
    $streamInfo{"S6F19"} = "Individual Report Request";
    $streamInfo{"S6F20"} = "Individual Report Data";
    $streamInfo{"S6F23"} = "Request Spooled Data";
    $streamInfo{"S6F24"} = "Request Spooled Data Acknowledgement Send";
    $streamInfo{"S7F0"} = "Abort Transaction";
    $streamInfo{"S7F1"} = "Process Program Load Inquire";
    $streamInfo{"S7F2"} = "Process Program Load Grant";
    $streamInfo{"S7F3"} = "Process Program Send";
    $streamInfo{"S7F4"} = "Process Program Acknowledge";
    $streamInfo{"S7F5"} = "Process Program Request";
    $streamInfo{"S7F6"} = "Process Program Data";
    $streamInfo{"S7F17"} = "Delete Process Program Send";
    $streamInfo{"S7F18"} = "Delete Process Program Acknowledge";
    $streamInfo{"S7F19"} = "Current EPPD Request";
    $streamInfo{"S7F20"} = "Current EPPD Data";
    $streamInfo{"S7F23"} = "Formatted Process Program Send";
    $streamInfo{"S7F24"} = "Formatted Process Program Acknowledge";
    $streamInfo{"S7F25"} = "Formatted Process Program Request";
    $streamInfo{"S7F26"} = "Formatted Process Program Data";
    $streamInfo{"S7F27"} = "Process Program Verification Send";
    $streamInfo{"S7F28"} = "Process Program Verification Acknowledge";
    $streamInfo{"S7F29"} = "Process Program Verification Inquire";
    $streamInfo{"S7F30"} = "Process Program Verification Grant";
    $streamInfo{"S7F71"} = "Current Process Recipe List Request";
    $streamInfo{"S7F72"} = "Current Process Recipe List Data";
    $streamInfo{"S7F83"} = "Name/Value Formatted Process Program Send";
    $streamInfo{"S7F84"} = "Name/Value Formatted Process Program Acknowledge";
    $streamInfo{"S7F85"} = "Name/Value Formatted Process Program Request";
    $streamInfo{"S7F86"} = "Name/Value Formatted Process Program Data";
    $streamInfo{"S9F0"} = "Abort Transaction";
    $streamInfo{"S9F1"} = "Unrecognized Device ID";
    $streamInfo{"S9F3"} = "Unrecognized Stream Type";
    $streamInfo{"S9F5"} = "Unrecognized Function Type";
    $streamInfo{"S9F7"} = "Illegal Data";
    $streamInfo{"S9F9"} = "Transaction Timer Timeout";
    $streamInfo{"S9F11"} = "Data Too Long";
    $streamInfo{"S9F13"} = "Conversation Timeout";
    $streamInfo{"S10F0"} = "Abort Transaction";
    $streamInfo{"S10F1"} = "Terminal Request ";
    $streamInfo{"S10F2"} = "Terminal Request Acknowledge";
    $streamInfo{"S10F3"} = "Terminal Display, Single";
    $streamInfo{"S10F4"} = "Terminal Display, Single Acknowledge";
    $streamInfo{"S10F5"} = "Terminal Display, Multi-block";
    $streamInfo{"S10F6"} = "Terminal Display, Multi-block Acknowledge";
    $streamInfo{"S14F0"} = "Abort Transaction";
    $streamInfo{"S14F1"} = "GetAttr Request";
    $streamInfo{"S14F2"} = "GetAttr Data";
    $streamInfo{"S14F3"} = "SetAttr Request";
    $streamInfo{"S14F4"} = "SetAttr Data";
    $streamInfo{"S14F5"} = "GetType Request";
    $streamInfo{"S14F6"} = "GetType Data";
    $streamInfo{"S14F7"} = "GetAttrName Request";
    $streamInfo{"S14F8"} = "GetAttrName Data";
    $streamInfo{"S14F9"} = "Create Object Request";
    $streamInfo{"S14F10"} = "Create Object Acknowledge";
    $streamInfo{"S14F11"} = "Delete Object Request";
    $streamInfo{"S14F12"} = "Delete Object Acknowledge";
    $streamInfo{"S16F0"} = "Abort Transaction";
    $streamInfo{"S16F1"} = "Multi-block Process Job Data Inquire";
    $streamInfo{"S16F2"} = "Multi-block Process Job Data Grant";
    $streamInfo{"S16F5"} = "Process Job Command Request";
    $streamInfo{"S16F6"} = "Process Job Command Acknowledge";
    $streamInfo{"S16F7"} = "Process Job Alert Notify";
    $streamInfo{"S16F8"} = "Process Job Alert Confirm";
    $streamInfo{"S16F9"} = "Process Job Event Notify";
    $streamInfo{"S16F10"} = "Process Job Event Confirm";
    $streamInfo{"S16F11"} = "PRJobCreateEnh";
    $streamInfo{"S16F12"} = "PRJobCreateEnh Acknowledge";
    $streamInfo{"S16F15"} = "PRJobMultiCreate";
    $streamInfo{"S16F16"} = "PRJobMultiCreate Acknowledge";
    $streamInfo{"S16F17"} = "PRJobDequeue";
    $streamInfo{"S16F18"} = "PRJobDequeue Acknowledge";
    $streamInfo{"S16F19"} = "PRGetAllJobs";
    $streamInfo{"S16F20"} = "PRGetAllJobs Send";
    $streamInfo{"S16F21"} = "PRGetSpace";
    $streamInfo{"S16F22"} = "PRGetSpace Send";
    $streamInfo{"S16F23"} = "PRJobSetRecipeVariable";
    $streamInfo{"S16F24"} = "PRJobSetRecipeVariable Acknowledge";
    $streamInfo{"S16F25"} = "PRJobSetStartMethod";
    $streamInfo{"S16F26"} = "PRJobSetStartMethod Acknowledge";
    $streamInfo{"S16F27"} = "Control Job Command Request";
    $streamInfo{"S16F28"} = "Control Job Command Acknowledge";
    $streamInfo{"S16F29"} = "PRSetMtrlOrder";
    $streamInfo{"S16F30"} = "PRSEtMtrlOrder Acknowledge";
}