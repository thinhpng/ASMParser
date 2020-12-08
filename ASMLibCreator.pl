################################################################################
# This script is written by Thinh Nguyen @ASM
# It's used to parse ASM's EventXp.txt to create 2 library files
# to use in SecSimPro++ to run ASM-Host
# 1-Ceids.txt (contains all Ceids found in EventXp.txt)
# 2-ReportIds.txt (contains all ReportIds & related Vids found in EventXp.txt)
################################################################################
#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use feature qw(say);
use File::stat;
use Time::Local;
use Time::localtime;
use Win32::File;
use File::Path;
use File::Find;
use Spreadsheet::ParseExcel;
binmode STDIN, ":encoding(UTF-8)";
binmode STDOUT, ":encoding(UTF-8)";
#use utf8;
use Encode qw(from_to);
$SIG{'INT'} = 'Terminate'; #'IGNORE'; #'Terminate';

say "INFO! Start ASMLibCreator ...";
my $vidCount = 0;
my @vidsInfo;
my @dvidsInfo;
my @ecidsInfo;
my @ceidsInfo;
my @rptsInfo;
my @vids;
my @vidNames;
my %vidsInfo;

my $libDir = ".\\Lib\\";
my $eventFile = $libDir."EventXp.txt";
say "Resource eventFile is $eventFile";
open (INFILE, "$eventFile") || die "ERROR! Can't open $eventFile";
my @eventBucket = <INFILE>;
close(INFILE) || die "ERROR! Can't close $eventFile";

my $vidFile = "";
find(sub {
    if ($_ =~ /Online SECS ID List.xls/ig) {
        $vidFile = $_; #$File::Find::name; #$_;
    }
}, $libDir);
if ($vidFile eq "") {
    say "Missing file: Online SECS ID List. You won't have Vids.txt created.";
}else {
    say "Resource vidFile is $vidFile";
    my $parser = Spreadsheet::ParseExcel->new();
    my $workbook = $parser->parse($libDir . $vidFile);
    if (!defined $workbook) {
        die $parser->error(), ".\n";
    }
    for my $worksheet ($workbook->worksheets()) {
        my ($row_min, $row_max) = $worksheet->row_range();
        for my $row ($row_min .. $row_max) {
            my $svid = $worksheet->get_cell($row, 3); #3 is The Class Column
            if ($svid->value() eq "DVVAL" || $svid->value() eq "SV") {
                my $vid = $worksheet->get_cell($row, 2)->value();
                my $vidName = $worksheet->get_cell($row, 5)->value();
                my $remark = $worksheet->get_cell($row, 6)->value();
                $vidName =~ s/[\n]+//g;
                $vidName =~ s/\s+//g;
#                say "VID:  $vid $vidName $remark";
                $remark =~ s/[\n]+/!!!/g;
                my $vidInfo;
                if ($remark !~/\!\!\!/ig) {
                    #say "VID:  $vid $vidName $remark";
                    $vidInfo = $vid . " " . $vidName . " NA";
                    push(@vidsInfo, $vidInfo, "\n");
                } elsif ($remark =~ /(!!!.*)$/ig) {
                    my $t = $1;
                    if ($t !~ /!!!\d+.*?!!!/ig) {
                        $vidInfo = $vid . " " . $vidName . " NA";
                        push(@vidsInfo, $vidInfo, "\n");
                    } else {
                        $t =~ s/\s+//ig;
                        $t =~ s/!.*?(\d+)/ $1/ig;
                        $t =~ s/\d+.*?:ASMA\s//ig;
                        $t =~ s/\$FFFF.*$//ig;
                        $t =~ s/\d+-\d+\s0.*full/0=FULL/ig;
                        $t =~ s/\s/,/ig;
                        $t =~ s/^,/ /ig;
                        $t =~ s/(\d+):/$1=/ig;
                        $t =~ s/(\d+=)=/$1/ig;
                        $t =~ s/!!!.*$//ig;
                        $t =~ s/\d+.,//ig;
                        $t =~ s/,,/,/ig;
                        $t =~ s/,\d+.$//ig;
                        $vidInfo = $vid . " " . $vidName . $t;
                        push(@vidsInfo, $vidInfo, "\n");
                    }
                }
            }elsif ($svid->value() eq "ECV"){
                my $ecid = $worksheet->get_cell($row, 2)->value();
                my $ecName = $worksheet->get_cell($row, 5)->value();
                my $remark = $worksheet->get_cell($row, 6)->value();
                $ecName =~ s/[\n]+//g;
                $ecName =~ s/\s+//g;
                my $ecidInfo = $ecid . " " . $ecName . " NA";
                push(@ecidsInfo, $ecidInfo, "\n");
            }
        }
    }
    #Now is time to create the VID library
    my $tempfile = '.\\Lib\\Vids.txt';
    open (OUTFILE, ">:encoding(UTF-8)", $tempfile) || die "ERROR! Can't open $tempfile";
    print OUTFILE vidHeader(),@vidsInfo;
    close (OUTFILE) || die "ERROR! Can't close $tempfile";
    #Now is time to create the VID library
    $tempfile = '.\\Lib\\Dvids.txt';
    open (OUTFILE, ">:encoding(UTF-8)", $tempfile) || die "ERROR! Can't open $tempfile";
    print OUTFILE vidHeader(),@dvidsInfo;
    close (OUTFILE) || die "ERROR! Can't close $tempfile";
    #Now is time to create the ECID library
    $tempfile = '.\\Lib\\Ecids.txt';
    open (OUTFILE, ">:encoding(UTF-8)", $tempfile) || die "ERROR! Can't open $tempfile";
    print OUTFILE ecidHeader(),@ecidsInfo;
    close (OUTFILE) || die "ERROR! Can't close $tempfile";
}

foreach my $line_str (@eventBucket)
{
    #skip all the comments or blank lines
    next if(($line_str =~ /^#/) || ($line_str =~ /^$/));
    #say "line_str=$line_str";
    #chomp($line_str);
    if ($line_str =~/^\s+E.*\$(\w+)\s+\d+\s+#(.*)?/i) # 'E' stands for event, is to identify CEID
    {
        #say "found event $line_str";
        #my $hVal = $1;
        my $hex = hex("0x".$1);
        my $ceidName = $2;
        $ceidName =~s/\s+//ig;
        $ceidName =~s/#.*$//ig;
        #say "$hVal = CEID:$hex $ceidName";
        push(@ceidsInfo,$hex." ".$ceidName."\n");
#        say "CEID: $hex.",".$2";
    }elsif ($line_str =~/^\s+R.*\$(\w+)\s+(\d+)\s+#(.*)$/i) # 'R' stands for report, is to identify ReportId
    {
        $vidCount = $2; #This number tells how many VIDs the report carries on
        #say "found report $line_str";
        my $hex = hex("0x".$1);
        push(@rptsInfo, $hex." ".$3." ");
        #say "$1 = RPTID:$hex $3 has $vidCount vids";
    }elsif($line_str =~/^\s+.*\$(\w+)\s+#\_{0,3}(\w+)/i && $vidCount > 0){ #Needs to gather number of VIDs as indicated
        my $hex = hex("0x".$1);
        #say "$vidCount -> $1 = VID:$hex $2";
        my $vidName = $2;
        $vidsInfo{$hex} = $vidName;
        $vidCount--;
        #say "found report $line_str";
        if ($vidCount == 0){ #The last VID belongs to a report
            #say("Last VID: ", $vidName);
            push(@vids, $hex." ");
            push(@vidNames, $vidName." NA");
            #say @vids;
            #say @vidNames;
            push(@rptsInfo, @vids);
            push(@rptsInfo, @vidNames);
            push(@rptsInfo, "\n");
            @vids = ();
            @vidNames = ();
        }else{
            push(@vids, $hex.",");
            push(@vidNames, $2.",");
        }
    }
}
#Now is time to create the CEID library
my $tempfile = '.\\Lib\\Ceids.txt';
open (OUTFILE, ">:encoding(UTF-8)", $tempfile) || die "ERROR! Can't open $tempfile";
print OUTFILE ceidHeader(),@ceidsInfo;
close (OUTFILE) || die "ERROR! Can't close $tempfile";
#Now is time to create the ReportId library
$tempfile = '.\\Lib\\ReportIds.txt';
open (OUTFILE, ">:encoding(UTF-8)", $tempfile) || die "ERROR! Can't open $tempfile";
print OUTFILE rptIdHeader(),@rptsInfo;
close (OUTFILE) || die "ERROR! Can't close $tempfile";

sub getVidFile{
    my $currfname = $_ ; #$File::Find::name; #$_;
    if($currfname =~/Online SECS ID List.csv/i){
        return $currfname;
    }
}

sub vidHeader{
    my $header = '//
//	Scripted by THINH NGUYEN
//  File: Vids.txt
//	Version: 1.0
//	Date: '.gmtime().'
//
// This file is to configure all VIDs. WARNING!!! DO NOT_EDIT without reading first.
// All comments should follow the format being used and seen.
// The last line should be an empty line.
//
// This is a typical way to express an VID.
//   vid		is id of the vid
//   name		is name of the vid
//   values     possible values (or NA)
//
// vid		name    values(possible values or NA)
//
';
    return $header;
}

sub ecidHeader{
    my $header = '//
//	Scripted by THINH NGUYEN
//  File: Ecids.txt
//	Version: 1.0
//	Date: '.gmtime().'
//
// This file is to configure all ECIDs. WARNING!!! DO NOT_EDIT without reading first.
// All comments should follow the format being used and seen.
// The last line should be an empty line.
//
// This is a typical way to express an ECID.
//   ecid		is id of the ec
//   name		is name of the ecid
//   values     possible values (or NA)
//
// ecid		name    values(possible values or NA)
//
';
    return $header;
}

sub ceidHeader{
    my $header = '//
//	Scripted by THINH NGUYEN
//  File: Ceids.txt
//	Version: 1.0
//	Date: '.gmtime().'
//
// This file is to configure all CEIDs. WARNING!!! DO NOT_EDIT without reading first.
// All comments should follow the format being used and seen.
// The last line should be an empty line.
//
// This is a typical way to express an CEID.
//   ceid		is id of the ceid
//   name		is name of the ceid
//
// ceid		name
//
';
    return $header;
}

sub rptIdHeader{
    my $header = '//
//	Scripted by THINH NGUYEN
//  File: ReportIds.txt
//	Version: 1.0
//	Date: '.gmtime().'
//
// WARNING!!! DO NOT EDIT without reading first.
// This file should contains all ReportIds used by your Tool or Host.
// All comments should follow the format being used and seen.
// Each field should be separated by a white space
// Data in each field should be separated by a comma (w/o space)
// The last line should be an empty line.
//
// This is a typical way to express an RPTID.
//   rptid		is a number of the REPORT
//   rptname	is name of the REPORT
//   vids		is an SSL list of vids (use comma separator, no space allowed)
//   vidnames	is a name list of vids (use comma separator, no space allowed)
//   values		is a value list of vids (Single NA is ok; otherwise use comma separator, no space allowed)
//
// rptid(unique)  rptname(single)  vids(single/multiple)  vidnames(single/multiple  values(NA by default)
//
';
    return $header;
}

#binmode STDIN, ":encoding(UTF-8)";

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