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

say"Start ASMLogAnalyzer...";
my $libSource = ".\\Lib\\Ceids.txt"; #must have the ceid:name pairs library text file
my $logDir = ".\\Logs\\"; #where the interested mes logs are stored to analyze
say"libSource: $libSource, and logDir: $logDir";
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
    }
}
#log file listed the newest data on top and oldest data at the bottom.
#manipulating the log file to get all data in the right order to process.
my %streamInfo;
my @mesLogs;
find (\&gatherLogs,$logDir);
@mesLogs = sort {$b cmp $a} @mesLogs;
my @logData;
foreach my $logFile (@mesLogs){
    say"sorted : $logDir$logFile";
    open (INFILE, "$logDir$logFile") || die "ERROR! Can't open $logFile\n";
    my @bucket = <INFILE>;
    close(INFILE) || die "ERROR! Can't close $logFile\n";
    push(@logData,@bucket);
}
my @logBucket = reverse @logData;
#Because events of different RC & LP are published whenever they're ready
#Therefore, they're all mixing altogether in the log.
#We must traverse several times to pickup all events of all RC & LP
for(my $i = 1; $i < 5; $i++){
    my $rc = "RC".$i;
    my $lp = "LP".$i;
    my $recStart = $rc."RecipeStarted";
    my $recFinish = $rc."RecipeFinished";
    my $stepStart = $rc."StepStarted";
    my $stepFinish = $rc."StepFinished";
    my $rcWaferMovedStart = "WaferMovedStart".$rc."BERbt";
    my $rcWaferMovedFinish = "WaferMovedFinishBERbt".$rc;
    my $lpWaferMovedStart = "WaferMovedStart".$lp."FERbt";
    my $lpWaferMovedFinish = "WaferMovedFinishFERbt".$lp;
    my $recStartTime = undef;
    my $recFinishTime;
    my $stepStartTime;
    my $stepFinishTime;
    my $processTime;
    my $stepTime;
    my $rcInTime;
    my $rcOutTime;
    my $rcInOutTime;
    my $lpOutInTime;
    my $lpInTime;
    my $lpOutTime;
    my $stepCount = 0;
    my $step;
	my @sml;
    print"Updating $rc, $lp events ...\n";
    for(my $count = 0; $count < @logBucket; $count++){
        my $line_str = $logBucket[$count];
    #    foreach my $line_str (@logBucket) {
        #print "line found event $line_str\n";
        #skip all the comments or blank lines
        next if (($line_str =~ /^#/) || ($line_str =~ /^$/));
        #print "line_str=$line_str\n";
#        chomp($line_str);
        #if ($line_str =~ /(".*?",)("(.*?)","(.*?)",)(".*?",)(".*?",)("(\d+).*",)(".*?",)(".*?",)/i) {
        if ($line_str =~ /(".*?",)("(.*?)","(.*?)",)(".*?",)(".*?",)("(\d+).*",)(".*?",)(".*?",)/i) {
			
			if(@sml){
				constructSml(@sml);
				undef @sml;
			}
			
            #print "line found $line_str\n";
            #print"1:$1 2:$2 3:$3 4:$4 5:$5 6:$6 7:$7 8:$8 9:$9 10:$10\n";
            my $date = $3;
            my $time = $4;
            my $dateTime = $date." ".$time;
            my $id = $8;
            my $one = $1;
            my $two = $2;
            my $five = $5;
            my $six = $6;
#            my $nine = $9;
#            my $ten = $10;
            if ($6 =~ /"S6F11"/i && $ceidDict{$id}) { #We're just interested on events
                my $ceid = "CEID:" . $id . " " . $ceidDict{$id};
                if($ceidDict{$id} eq $recStart){ #Time the recipe starts on the tool
                    $stepCount = 0;
                    $ceid = '"'.$ceid." (".$rc." Started)".'"';
                    $recStartTime = $dateTime;
#                    print "$id: recStartTime: $recStartTime\n";
                    $logBucket[$count] = $one.$two.$five.$six.$ceid."\n";
                }elsif($ceidDict{$id} eq $recFinish && $recStartTime){ #Time the recipe finishes on the tool
                    $recFinishTime = $dateTime;
                    $processTime = str2time ($recFinishTime) - str2time ($recStartTime);
                    $ceid = '"'.$ceid." (".$rc." Finished in ".strftime("\%H:\%M:\%S", gmtime($processTime)).")".'"';
                    $stepCount = 0;
#                    print "$id: recFinishTime: $recFinishTime\n";
                    $logBucket[$count] = $one.$two.$five.$six.$ceid."\n";
                }elsif($ceidDict{$id} eq $stepStart && $recStartTime) { #Time recipe's step starts
                    $stepCount++;
                    $stepStartTime = $dateTime;
                    $step = "Step".$stepCount;
#                    print "$id: stepStartTime: $stepStartTime\n";
                    $ceid = '"'.$ceid." (".$rc." ".$step." Started)".'"';
                    $logBucket[$count] = $one.$two.$five.$six.$ceid."\n";
                }elsif($ceidDict{$id} eq $stepFinish && $recStartTime && $stepStartTime){ #Time recipe's step finishes
                    $stepFinishTime = $dateTime;
                    $stepTime = str2time ($stepFinishTime) - str2time ($stepStartTime);
                    $ceid = '"'.$ceid." (".$rc." ".$step." Finished in ".strftime("\%H:\%M:\%S", gmtime($stepTime)).")".'"';
                    $stepStartTime = undef;
#                    print "$id: stepFinishTime: $stepFinishTime\n";
                    $logBucket[$count] = $one.$two.$five.$six.$ceid."\n";
                }elsif($ceidDict{$id} eq $rcWaferMovedFinish){ #Time BERbt->RC finishes is time Wafer enters RC
                    #print"Wafer enters Chamber: $rcWaferMovedFinish\n";
                    $rcInTime = $dateTime;
                    $ceid = '"'.$ceid." (".$rc." Wafer Entered)".'"';
                    $logBucket[$count] = $one.$two.$five.$six.$ceid."\n";
                }elsif($ceidDict{$id} eq $rcWaferMovedStart && $rcInTime){ #Time RC->BERbt finishes is time Wafer exits RC
                    #print"Wafer exits Chamber: $rcWaferMovedStart\n";
                    $rcOutTime = $dateTime;
                    $rcInOutTime = str2time ($rcOutTime) - str2time ($rcInTime);
                    $ceid = '"'.$ceid." (".$rc." Finished Wafer in ".strftime("\%H:\%M:\%S", gmtime($rcInOutTime)).")".'"';
                    $logBucket[$count] = $one.$two.$five.$six.$ceid."\n";
                }elsif($ceidDict{$id} eq $lpWaferMovedStart){ #Time LP->FERbt starts is time Wafer exits LoadPort
                    #print"Wafer exits LoadPort: $lpWaferMovedStart\n";
                    $lpOutTime = $dateTime;
                    $ceid = '"'.$ceid." (".$lp." sending Wafer in )".'"';
                    $logBucket[$count] = $one.$two.$five.$six.$ceid."\n";
                }elsif($ceidDict{$id} eq $lpWaferMovedFinish && $lpOutTime){ #Time FERbt->LP finishes is time Wafer returns to LoadPort
                    #print"Wafer returns to LoadPort: $lpWaferMovedFinish\n";
                    $lpInTime = $dateTime;
                    $lpOutInTime = str2time ($lpInTime) - str2time ($lpOutTime);
                    $ceid = '"'.$ceid." (".$lp." receiving a Wafer )".'"';
                    #$ceid = '"'.$ceid." (".$lp." Finished Wafer in ".strftime("\%H:\%M:\%S", gmtime($lpOutInTime)).")".'"';
                    $logBucket[$count] = $one.$two.$five.$six.$ceid."\n";
                }
            }
        }elsif($line_str !~/^"\d+"/i){
            $logBucket[$count] = "";
			if($line_str =~/^\s+/){
				print("Got: \t $line_str");
				push(@sml, $line_str);
			}
        }
    }
}

GetStreamDefinition();

#Whatever events that we did not annotate or giving names in above task, now we do
#so that all CEIDs will be transforming to more meaningful data
for(my $count = 0; $count < @logBucket; $count++) {
    my $line_str = $logBucket[$count];
    next if (($line_str =~ /CEID:/) || ($line_str =~ /^#/) || ($line_str =~ /^$/));

    if ($line_str =~ /(".*?",)("(.*?)","(.*?)",)(".*?",)(".*?",)("(\d+).*",)(".*?",)(".*?",)/i) {
        my $id = $8;
        my $one = $1;
        my $two = $2;
        my $five = $5;
        my $six = $6;
        #say($1," ",$2," ",$3," ",$4," ",$5," ",$6);
        if ($6 =~ /"S6F11"/i && $ceidDict{$id}) {
            my $ceid = "CEID:" . $id . " " . $ceidDict{$id};
            $logBucket[$count] = $one.$two.$five.$six.$ceid."\n";
        }
    }elsif ($line_str =~ /(".*?",)(".*?",)(".*?",)(".*?",)("(.*?)")/i) {
        my $streamFunction = $6;
        if ($streamInfo{$streamFunction}){
            my $streamName = $streamInfo{$streamFunction} ;
            $logBucket[$count] = $1.$2.$3.$4.$5.','.$streamName."\n";
        }
    }
}
#We can write back to the same log file but I chose to output to the new file
# my $tempfile = $logDir."logUpdated.txt";
# open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
# print OUTFILE @logBucket;
# close (OUTFILE) || die "ERROR! Can't close $tempfile\n";

sub gatherLogs() {
    my $currfname = $_ ; #$File::Find::name; #$_;
    if($currfname =~/Meslog.ml_\d+(.csv)/i){
        push(@mesLogs,$currfname);
    }
}

sub constructSml(@bucket){
    my $size = -1;
	my @listTracker;
	my @spaces;
	my $space;
	my @secs;
	my $sec;

	say($streamCmd);
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
				if($value eq "FF"){
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
				$dataType = "<U4 ";
				$value =~ s/\s+\(\d+\w+\)//;
				$sec = $space . $dataType . $value . ">\n";
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
	
	return(@secs);
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