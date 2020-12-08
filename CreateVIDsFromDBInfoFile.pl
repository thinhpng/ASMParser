################################################################################
# This script is written by Thinh Nguyen @ASM
# It's used to analyze the mes log for Samsung customer
# due to the issue reported via OneComm# 300130350
# It computes the wafer & recipe complete time to locate event delay or missing
################################################################################
#!/usr/bin/perl
use strict;
use Switch;
#use Spreadsheet::Read;
#use Spreadsheet::ParseExcel;
use Win32::File;
use File::Path;
use File::Find;
use warnings FATAL => 'all';
#use Date::Parse;
use POSIX qw{strftime};
use feature qw(say);
binmode STDIN, ":encoding(UTF-8)";
binmode STDOUT, ":encoding(UTF-8)";
$SIG{'INT'} = 'Terminate'; #'IGNORE'; #'Terminate';
my $start_dir = "C:\\Project\\UPC\\SystemFile\\CcuFiles\\Default\\";
my $tempfile = $start_dir . "DBInfo.txt";
open (INFILE, "$tempfile") || die "ERROR! Can't open $tempfile\n";
my @bucket = <INFILE>;
close(INFILE) || die "ERROR! Can't close $tempfile\n";
my @vidLines;
my @ecidLines;
my $seperator = " : ";
foreach my $line_str (@bucket){
    #$line_str;
    next if(($line_str =~ /^#/) || ($line_str =~ /^$/));
    #say "line_str=$line_str";
    chomp($line_str);
    if ($line_str =~/^\$/i) {
        my $vidHexVal = "";
        my $vidDecVal = 0;
        my $vidDesc = "";
        my $nameDetail = "";

        #Gather all the VIDs
        if ($line_str =~/^\$(\w+)(\s+.*?\s+.*?\s+.*?\s+.*?\s+.*?\s+.*?\s+.*?\s+.*?\s+.*?\s+.*?\s+.*?\s+.*?\s+.*?)(.*?)\s*\/\/\s*(\w+)/i) {
            #say "$1 : $3";
            $vidHexVal = $1;
            $vidDecVal = hex($vidHexVal);
            $vidDesc = $3;
            $nameDetail = $4;
            chomp($nameDetail);
            #push(@vidLines, "VID : \$".$vidHexVal, $seperator, $vidDecVal, $seperator, $vidDesc, $seperator, "\n");
#            say "\$$vidHexVal : $vidDecVal : $vidDesc : $nameDetail : ";

            #Specific VIDs need to be compute to gather the rest of population. They might be using different formula
            switch (hex($vidHexVal)) {
                case (hex('0x01050041')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x01050201')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 1, 20); }
                case (hex('0x01050341')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 1, 20); }
                case (hex('0x01050481')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 1, 20); }
                case (hex('0x010505C0')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 1, 20); }
                case (hex('0x01050701')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x01050711')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 19); }
                case (hex('0x01050851')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 19); }

                # VIDsAndVals case (hex('0x01050711')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 1, 20); }
                # VIDsAndVals case (hex('0x01050851')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 1, 20); }
                case (hex('0x01060021')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x01080401')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x01080411')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x01080421')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x01080431')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x01080441')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x01080451')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x01080461')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x01080471')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x01080481')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x01080491')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x010804A1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x010804B1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x010804C1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x010804D1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x010804E1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x010804F1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x01080501')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x01080511')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x010805B1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 1); }
                case (hex('0x010805D1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 1); }
                case (hex('0x010805F1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 1); }
                case (hex('0x01080611')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 1); }
                case (hex('0x01080631')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 1); }
                case (hex('0x01080651')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x01080661')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x01080671')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x01080681')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x01080691')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                # VIDsAndVals case (hex('0x010806A1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x010806A1')) { ; }
                case (hex('0x010806B1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                # VIDsAndVals case (hex('0x010806C1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x010806C1')) { ; }
                case (hex('0x010806D1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x010806E1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                # VIDDsAndVals case (hex('0x010806F1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                # VIDDsAndVals case (hex('0x01080701')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                # VIDDsAndVals case (hex('0x01080711')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x01080721')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x01080731')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x01080741')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 1, 4, 0, 3); }
                case (hex('0x01080781')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 1, 4, 0, 3); }
                case (hex('0x010807C1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 1, 4, 0, 3); }
                case (hex('0x01080801')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 1, 4, 0, 3); }
                case (hex('0x01080841')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 1, 4, 0, 3); }
                case (hex('0x01080881')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 1, 4, 0, 3); }
                case (hex('0x010808C1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 1, 4, 0, 3); }
                case (hex('0x01080901')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x01080911')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 19); }
                case (hex('0x01080A51')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 19); }
                case (hex('0x01080B91')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 19); }
                case (hex('0x01080CD1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 19); }
                case (hex('0x01080E11')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 19); }
                case (hex('0x01080F51')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 19); }
                case (hex('0x01081091')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 19); }
                case (hex('0x010811D1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 19); }
                case (hex('0x01081311')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 19); }
                case (hex('0x01081451')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 19); }
                case (hex('0x02000001')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                # VIDsAndVals case (hex('0x02000201')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x02000201')) { ; }
                case (hex('0x02010111')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 95); }
                case (hex('0x02010711')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 63); }
                case (hex('0x02010B11')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 239); }
                case (hex('0x02011A10')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 15); }
                case (hex('0x02011B10')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 31); }
                case (hex('0x02011D10')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 191); }
                case (hex('0x02012910')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 16, 31); }
                case (hex('0x02020010')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 3); }
                case (hex('0x02020050')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 3); }
                case (hex('0x02020090')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 3); }
                case (hex('0x020200D0')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 3); }
                case (hex('0x02033401')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 95); }
                # VIDsAndVals case (hex('0x02033A01')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 1, 2); }
                case (hex('0x02033A01')) { ; }
                # VIDsAndVals case (hex('0x02033A10')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 1, 2); }
                case (hex('0x02033A10')) { ; }
                # VIDsAndVals case (hex('0x02033A81')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 1, 2); }
                case (hex('0x02033A81')) { ; }
                case (hex('0x02050011')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                # VIDsAndVals case (hex('0x02050131')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x02050131')) { ; }
                # VIDsAndVals case (hex('0x02050160')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x02050160')) { ; }
                # VIDsAndVals case (hex('0x02050181')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x02050181')) { ; }
                # VIDsAndVals case (hex('0x020501A1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x020501A1')) { ; }
                # VIDsAndVals case (hex('0x020501B1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x020501B1')) { ; }
                # VIDsAndVals case (hex('0x020501E1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x020501E1')) { ; }
                # VIDsAndVals case (hex('0x020501F1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x020501F1')) { ; }
                # VIDsAndVals case (hex('0x02050291')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x02050291')) { ; }
                # VIDsAndVals case (hex('0x020502A1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x020502A1')) { ; }
                # VIDsAndVals case (hex('0x020502B1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x020502B1')) { ; }
                case (hex('0x020502C1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                # VIDsAndVals case (hex('0x020502D1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x020502D1')) { ; }
                case (hex('0x020502E1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x020502F1')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x02050301')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x02050311')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x02050321')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                case (hex('0x02050331')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 1, 2); }
                case (hex('0x02050371')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 3); }
                case (hex('0x02050400')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 15); }
                case (hex('0x02050500')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 15); }
                case (hex('0x02050600')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 31); }
                # Removed from SSDoc case (hex('0x02050602')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 15); }
                case (hex('0x02050602')) { ; }
                case (hex('0x02050800')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 191); }
                case (hex('0x02051400')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 191); }
                # p & q different case (hex('0x02052900')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 15); }
                case (hex('0x02052900')) { ; }
                # p & q different case (hex('0x02052A00')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 15); }
                case (hex('0x02052A00')) { ; }
                case (hex('0x02052201')) { computeVIDs(6, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                #case (hex('0x02052211')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 1, 2); }

                #case (hex('0x02091001')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 64, 94); }
                #case (hex('0x02091201')) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 96, 143); }

                # case (33554433) { computeVIDs(5, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail); }
                # case (33620001) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 63); }
                # case (33621025) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 31); }
                # case (33621537) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 95); }
                # case (33623297) { computeVIDs(0, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 3); }
                #
                # case (34673153) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 32, 63); }
                # case (34679040) { computeVIDs(4, $vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 144, 239); }
                else {
                    if ($nameDetail =~/VID_EC/){
                        push(@ecidLines, "VID : \$" . $vidHexVal, $seperator, $vidDecVal, $seperator, $vidDesc, $seperator, "\n");
                    }else {
                        push(@vidLines, "VID : \$" . $vidHexVal, $seperator, $vidDecVal, $seperator, $vidDesc, $seperator, "\n");
                    }
                }

#                case (33620001) { computeVIDs($vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 63); }
#                case (34148353) { computeVIDs($vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 64, 94); }
#                case (33621025) { computeVIDs($vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 31); }
#                case (34673153) { computeVIDs($vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 32, 63); }
#                case (33621537) { computeVIDs($vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 0, 95); }
#                case (34148865) { computeVIDs($vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 96, 143); }
#                case (34679040) { computeVIDs($vidHexVal, $vidDecVal, $vidDesc, $nameDetail, 144, 239); }
#                else{
#                    computeVIDs($vidHexVal, $vidDecVal, $vidDesc, $nameDetail);
#                }
            }
        }elsif ($line_str =~/^\$(\w+)(\s+.*?\s+.*?\s+.*?\s+.*?\s+.*?\s+.*?\s+.*?\s+.*?\s+.*?\s+.*?\s+.*?\s+.*?\s+.*?)(\w+)/i) {
            #say "$1 : $3";
            $vidHexVal = $1;
            $vidDecVal = hex($vidHexVal);
            $vidDesc = $3;
            if ($nameDetail =~/VID_EC/){
                push(@ecidLines, "VID : \$" . $vidHexVal, $seperator, $vidDecVal, $seperator, $vidDesc, $seperator, "\n");
            }else {
                push(@vidLines, "VID : \$" . $vidHexVal, $seperator, $vidDecVal, $seperator, $vidDesc, $seperator, "\n");
            }
#            say "\$$vidHexVal : $vidDecVal : $vidDesc : ";
            computeVIDs($vidHexVal, $vidDecVal, $vidDesc);
        }else{
            #say $line_str;
        }
    }
}
sub computeVIDs{
    my $module = $_[0]; #Use to be 1-4
    my $vidHexVal = $_[1];
    my $vidDecVal = $_[2];
    my $vidDesc = $_[3];
    my $nameDetail = $_[4];
    my $begin = $_[5];
    my $end = $_[6];
    my $optFirst = $_[7];
    my $optLast = $_[8]; #parameter with 4 last numbers

    say "0: @_";

    if(!$begin && !$end)  {
        $vidDecVal = $vidDecVal - 1;
        for(my $n = 1; $n <= $module; $n++) {
            my $vidDecVal = $vidDecVal + $n;
            $vidHexVal = sprintf("0%x", $vidDecVal);
            $vidDesc =~s/(.*?)[X|\d*](.*?)/$1$n$2/;
            $nameDetail =~s/(.*?)[X|\d*](.*?)/$1$n$2/;
            #say "\$0$vidHexVal : $vidDecVal : $vidDesc : $nameDetail : ";
            if ($nameDetail =~/VID_EC/){
                push(@ecidLines, "VID : \$".$vidHexVal, $seperator, $vidDecVal, $seperator, $vidDesc, $seperator, "\n");
            }else {
                push(@vidLines, "VID : \$".$vidHexVal, $seperator, $vidDecVal, $seperator, $vidDesc, $seperator, "\n");
            }
        }
#    }elsif ($vidDesc =~/(.*?)X(.*?)X/ && $nameDetail =~/(.*?)X(.*?)X(.*?)/) { # Name with 2 variables X
    }elsif ($vidDesc =~/(.*?)X(.*?)X(.*?)/) { # Name with 2 variables X
        say "2 Xs: $vidHexVal, $vidDecVal, $begin, $end";
        $vidDesc =~s/(.*?)X(.*?)X/${1}1${2}$begin/;
        $nameDetail =~s/(.*?)X(.*?)X(.*?)/${1}1${2}$begin$3/;
        $vidDecVal = $vidDecVal - 1;
        for(my $pp = $begin; $pp <= $end; $pp++) {
            for(my $n = 1; $n <= $module; $n++) {
                my $vidDecVal = $vidDecVal + 16*($pp - $begin) + $n; #the formula with n
                $vidHexVal = sprintf("0%x", $vidDecVal);
                $vidDesc =~s/(.*?)\d+(.*?)\d+/$1$n$2$pp/;
                $nameDetail =~s/(.*?)\d+(.*?)\d+(.*?)/$1$n$2$pp$3/;
                #say "\$0$vidHexVal : $vidDecVal : $vidDesc : $nameDetail : ";
                #say "formula with n used: $vidHexVal";
                if ($nameDetail =~/VID_EC/){
                    push(@ecidLines, "VID : \$".$vidHexVal, $seperator, $vidDecVal, $seperator, $vidDesc, $seperator, "\n");
                }else {
                    push(@vidLines, "VID : \$" . $vidHexVal, $seperator, $vidDecVal, $seperator, $vidDesc, $seperator, "\n");
                }
            }
        }
#    }elsif ($vidDesc =~/(.*?)X/ && $nameDetail =~/(.*?)X(.*?)/) { # Name with one variable X
    }elsif ($vidDesc =~/(.*?)X(.*?)/) { # Name with one variable X
        say "1 X: $vidHexVal, $vidDecVal, $nameDetail, $begin, $end";
        $vidDesc =~s/(.*?)X/${1}$begin/;
        $nameDetail =~s/(.*?)X/${1}$begin/;
        for(my $pp = $begin; $pp <= $end; $pp++) {
            $vidDesc =~s/(.*?)\d+/$1$pp/;
            $nameDetail =~s/(.*?)\d+/$1$pp/;

            if($optLast){
                $vidDecVal = $vidDecVal + 16*($pp - 1); #the formula without n
                $vidHexVal = sprintf("0%x", $vidDecVal);
                #say "formula without n used: $vidHexVal, $optFirst, $optLast";
                my $optVidDesc = "";
                my $optNameDetail = "";
                my $optVidDecVal;
                my $optVidHexVal;

                for(my $opt = $optFirst; $opt <= $optLast; $opt++) {
                    switch ($opt) {
                        case 0 { $optVidDesc=$vidDesc."PreUnload"; $optNameDetail=$nameDetail."PreUnload";}
                        case 1 { $optVidDesc=$vidDesc."PostLoad"; $optNameDetail=$nameDetail."PostLoad";}
                        case 2 { $optVidDesc=$vidDesc."PreLoad"; $optNameDetail=$nameDetail."PreLoad";}
                        case 3 { $optVidDesc=$vidDesc."PostUnload"; $optNameDetail=$nameDetail."PostUnload";}
                    }
                    #say $vidDecVal, " ", $opt, " ", $pp;
                    $optVidDecVal = $vidDecVal-1 + (16*$opt) + $pp;
                    $optVidHexVal = sprintf("0%x", $optVidDecVal);
                    if ($nameDetail =~/VID_EC/){
                        push(@ecidLines, "VID : \$" . $optVidHexVal, $seperator, $optVidDecVal, $seperator, $optVidDesc, $seperator, "\n");
                    }else {
                        say "\$0$optVidHexVal : $optVidDecVal : $optVidDesc : $optNameDetail : ";
                        push(@vidLines, "VID : \$" . $optVidHexVal, $seperator, $optVidDecVal, $seperator, $optVidDesc, $seperator, "\n");
                    }
                }
            }else{
                $vidDecVal = $vidDecVal + (16*$pp); #the formula without n
                $vidHexVal = sprintf("0%x", $vidDecVal);
#                say "No optLast:, $vidHexVal, $vidDecVal";
                #say "\$0$vidHexVal : $vidDecVal : $vidDesc : $nameDetail : ";
                if ($nameDetail =~/VID_EC/){
                    push(@ecidLines, "VID : \$" . $vidHexVal, $seperator, $vidDecVal, $seperator, $vidDesc, $seperator, "\n");
                }else {
                    push(@vidLines, "VID : \$" . $vidHexVal, $seperator, $vidDecVal, $seperator, $vidDesc, $seperator, "\n");
                }
            }
        }
    }else {
        say "else: $vidHexVal, $vidDecVal";
        if($nameDetail){
            #say "\$$vidHexVal : $vidDecVal : $vidDesc : $nameDetail : ";
        }else{
            #say "\$$vidHexVal : $vidDecVal : $vidDesc : ";
        }
    }
}

my $outFile = $start_dir . "VIDsOnlyFromDBInfo.txt";
say("outFile: ", $outFile);
open(OUTFILE, ">:encoding(UTF-8)", $outFile) || die "ERROR! Can't open $outFile";
print OUTFILE VIDsOnlyFromDBInfoHeader(),@vidLines;
close(OUTFILE) || die "ERROR! Can't close $outFile";

$outFile = $start_dir . "ECIDsOnlyFromDBInfo.txt";
say("outFile: ", $outFile);
open(OUTFILE, ">:encoding(UTF-8)", $outFile) || die "ERROR! Can't open $outFile";
print OUTFILE ECIDsOnlyFromDBInfoHeader(),@ecidLines;
close(OUTFILE) || die "ERROR! Can't close $outFile";

sub VIDsOnlyFromDBInfoHeader{
    my $header = '///////////////////////////////////////////////////////////////
// Scripted by THINH NGUYEN
// File: VIDsOnlyFromDBInfo.txt
// Version: 1.0
// Date: '.gmtime().'
//
// This file is to configure all VIDs. WARNING!!!
// DO NOT_EDIT without reading first.
// All comments should follow the format being used and seen.
// The last line should be an empty line.
//
';
    return $header;
}

sub ECIDsOnlyFromDBInfoHeader{
    my $header = '///////////////////////////////////////////////////////////////
// Scripted by THINH NGUYEN
// File: ECIDsOnlyFromDBInfo.txt
// Version: 1.0
// Date: '.gmtime().'
//
// This file is to configure all VIDs. WARNING!!!
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