################################################################################
# This script is written by Thinh Nguyen @ASM
# It's used to analyze all text logs which hold crucial info in troubleshooting sw issues
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

say"Start ASMLogAnalyzer...";
my $top  = Tk::MainWindow->new();
my $start_dir = "C:\\Escalation";#getcwd;
say"start_dir: ", $start_dir;
my $ds  = $top->DirSelect(-title => "Select Specific customer's Log folder", -width => 60, -height => 60);
my $SelFolder = $ds->Show($start_dir);
say"SelFolder: ", $SelFolder;
my %recipeStartedInfo;
my %recipeFinishedInfo;
my %wfMoveStartedInfo;
my %wfMoveFinishedInfo;
my %streamInfo;
my %alarmInfo;
my %modCode;
my %ceidDict;
#my %TMUnit;
my %TMReportID;
my %Events;
my %ILState; ILState();
my %remoteCmd;

#my %SSZPOS = (0 => "HONE",1 => "LOAD",2 => "UNLOAD", 3 => "GAP", 4 => "UD", 5 => "UD", 6 => "UD", 7 => "UD", 8 => "UD", 255 => "UD");
my %ALANS = (0  => "NONE", 1  => "REJECTED", 2  => "OK", 3  => "COMPLETED", 4  => "RECV_NAK", 5  => "RECV_BUSY", 6  => "PRM_ERROR",
    7  => "TIMEOUT_OK", 8  => "TIMEOUT_CMPL", 9  => "ABORTED", 10  => "STOPED", 10  => "PAUSED", 11  => "ERROR", 12  => "TBOX",
    13  => "EMS", 14  => "MEP", 15  => "NOTCH_ERR", 16  => "BWARN", 17  => "INTERLOCK", 18  => "WAFER_GAP_OVER");
my %ALCODE = ("ALSet" => "Set Alarm", "ALClr" => "Clear Alarm", "SFSet" => "Set Safety", "SFClr" => "Clear Safety", "PASet" => "Set Pause",
    "PAClr" => "Clear Pause", "ABSet" => "Set Abort", "ABClr" => "Clear Abort", "LMSet" => "Set Limit", "LMClr" => "Clear Limit",
    "F1Set" => "Set Forced Alarm1", "F1Clr" => "Clear Forced Alarm1", "F2Set" => "Set Forced Alarm2", "F2Clr" => "Clear Forced Alarm2",
    "LASet" => "Set Safety Latch",  "LAClr" => "Clear Safety Latch",  "MASet" => "Set Maint Alarm",  "MAClr" => "Clear Maint Alarm",
    "DMSet" => "Set DI Maint Alarm", "DMClr" => "Clear DI Maint Alarm", "X1Set" => "Set Cool Water Leak Alarm1",
    "X1Clr" => "Clear Cool Water Leak Alarm1",  "X2Set" => "Set Cool Water Leark Alarm2", "X2Clr" => "Clear Cool Water Leak Alarm2",
    "X3Set" => "Set Smoke Detected Alarm3",  "X3Clr" => "Clear Smoke Detected Alarm3",  "X4Set" => "Set HCl Sensor Alarm",
    "X4Clr" => "Clear HCl Sensor Alarm", "X5Set" => "Set Liquid Leak Detected Alarm",  "X5Clr" => "Clear Liquid Detected Alarm",
    "X6Set" => "Set Liquid Leak Detected Alarm6", "X6Clr" => "Clear Liquid Leak Detected Alarm6", "X7Set" => "Set H2 Detected Alarm",
    "X7Clr" => "Clear H2 Detected Alarm",  "X8Set" => "Set C12 Detected Alarm", "X8Clr" => "Clear C12 Detected Alarm",
    "X9Set" => "Set NH3 Detected Alarm", "X9Clr" => "Clear NH3 Detected Alarm");
my %ALNTYPE = ("01" => "ALNR_INIT", "02" => "ALNR_HOME", "03" => "ALNR_MOVE", "04" => "ALNR_PAUSE", "05" => "ALNR_RESUME", "06" => "ALNR_CHUCK",
    "07" => "ALNR_CLAMP", "08" => "ALNR_VACUUM", "09" => "ALNR_ORIF", "0A" => "ALNR_TEACH", "0B" => "ALNR_ANGLE", "0C" => "ALNR_OFFSET",
    "0D" => "ALNR_SETSPEED", "20" => "ALNR_ALRESET");
my %ALREQ = (0 => "None", 1 => "AlarmReset", 2 => "Init", 3 => "Alinment", 4 => "ReadPOS", 5 => "ReadErrLog", 6 => "ClrErrLog", 7 => "DWL",
    8 => "UPL", 9 => "SPD", 10 => "REV", 11 => "RRE", 12 => "OFS", 13 => "ROF", 14 => "DIS", 15 => "RDI", 16 => "SAR", 17 => "RAR",
    18 => "SRP", 19 => "RRP", 20 => "RSP", 21 => "RLV", 22 => "MoveHOM", 23 => "MovePRP", 24 => "Alin1of3", 25 => "Alin2of3",
    26 => "Alin3of3", 27 => "TRN", 28 => "VVN", 29 => "VVF", 30 => "ZUP", 31 => "ZDN", 32 => "WCH", 33 => "SLM", 34 => "RLM", 35 => "SRS",
    36 => "RRS", 36 => "LastCommand", 91 => "Abort", 92 => "Stop", 93 => "Pause", 94 => "Resume");
my %ALSTATE = ("00" => "CLEAR", "80" => "SET");
my %ALUNIT = (1 => "RC1",  2 => "RC2",  3 => "RC3",  4 => "RC4",  5 => "RC5",10 => "LL1",  11 => "LL2",  12 => "LL3",  13 => "LL4",  14 => "WHC");
my %AMHSSTATE = (0 => "INIT", 1 => "AUTO", 2 => "EXEC", 3 => "AUTO_EXEC", 4 => "VALID", 5 => "AUTO_VALID", 6 => "EXEC_VALID", 7 => "AUTO_EXEC_VALID", 8 => "ERROR", 10 => "RECOVER");
my %AUTOTYPE = ("01" => "SYS_STOP", "02" => "SYS_ABORT", "03" => "SYS_PAUSE", "04" => "SYS_RESUME", "05" => "SYS_RESET", "06" => "SYS_TERMINATE",
    "07" => "SYS_RB1RESUME", "11" => "CJ_CREATE", "12" => "CJ_START", "13" => "CJ_STOP", "14" => "CJ_ABORT", "15" => "CJ_PAUSE",
    "16" => "CJ_RESUME", "17" => "CJ_CANCEL", "18" => "CJ_HOQ", "19" => "CJ_DESELECT", "1A" => "CJ_SELECT", "1B" => "CJ_DELETE",
    "21" => "PJ_CREATE", "22" => "PJ_START", "23" => "PJ_STOP", "24" => "PJ_ABORT", "25" => "PJ_PAUSE", "26" => "PJ_RESUME",
    "27" => "PJ_CANCEL", "28" => "PJ_DELETE", "29" => "PJ_START_METHOD", "2A" => "PJ_MULTI_CREATE", "31" => "PMScript_DELETE");
my %BEANS = (0 => "NONE",1 => "REJECTED",2 => "OK",3 => "WAFER_BRANK",4 => "COMPLETED",5 => "ABORTED",6 => "TIMEOUT_OK", 7 => "TIMEOUT_CMPL", 8 => "REPRAY_ERR", 9 => "PARAM_ERR", 34 => "34:UNKNOWN");
my %BEAXIS = (0 => "All Axes", 1 => "X Axis", 2 => "Y Axis", 3 => "U Axis", 4 => "Z Axis");
my %BEPOS = (0 => "Invalid", 1 => "Standby_Lower_Position", 2 => "Lower_Position", 3 => "Upper_Position", 4 => "Standby_Upper_Position");
my %BEREQ = (0 => "NONE", 1 => "AlarmReset", 2 => "Initialize", 3 => "HomePos", 4 => "ArmReturn", 5 => "AxisP", 6 => "AxisU", 7 => "Load",
    8 => "Unload", 9 => "WafMove1", 10 => "WafMove2", 11 => "TechRead", 12 => "TechWrite", 13 => "SetSpeed", 14 => "GetErrCode",
    15 => "HomeCalib", 16 => "DataSave", 17 => "ServosOff", 18 => "StnCalib", 19 => "SaveCalib", 20 => "AWC_Enable", 21 => "Set_Z_Speed");
my %BEREQDATA = ("Arm" => "","From" => "","FSlot" => "","To" => "","TSlot" => "","WafBrank" => "", "REQ" => "");
my %BETYPE = ("01" => "BERBT_INIT", "02" => "BERBT_HOME", "03" => "BERBT_LOAD", "04" => "BERBT_UNLOAD", "05" => "BERBT_AXIS", "06" => "BERBT_PAUSE",
    "07" => "BERBT_RESUME", "08" => "BERBT_ABORT", "09" => "BERBT_STOP", "0A" => "BERBT_MOVE", "0B" => "BERBT_CLAMP_BAR", "0C" => "BERBT_ARM_RET",
    "0D" => "BERBT_PULSE", "0E" => "BERBT_WAF_TRANS", "0F" => "BERBT_WAF_TRANS2", "10" => "BERBT_SETSPEED", "11" => "BERBT_HOME_CALIB",
    "12" => "BERBT_DATA_SAVE", "13" => "BERBT_SERVO_OFF", "14" => "BERBT_STAT_CALIB", "15" => "BERBT_END_CALIB", "16" => "BERBT_CHGSPEED",
    "17" => "BERBT_AWC_ENABLE", "18" => "BERBT_SETZSPEED", "20" => "BERBT_ALRESET");
my %BEUNIT = (0 => "BERB",1 => "HOME",2 => "RC1",3 => "RC2",4 => "RC3",5 => "RC4",6 => "RC5", 7 => "LLL", 8 => "LLL2", 9 => "RLL", 10 => "RLL2");
#my %CAPP2HOFF = ("00" => "PRELOAD", "01" => "POSTLOAD", "02" => "PREUNLOAD", "03" => "POSTUNLOAD");
my %CAPSTATE = ("00" => "START", "01" => "END", "02" => "ABORT", "03" => "STEP");
my %CAPTYPE = ("01" => "CAP_INIT", "02" => "CAP_HOFF", "03" => "CAP_ISOLATE", "04" => "CAP_PUMPDOWN", "05" => "CAP_BACKFILL", "06" => "CAP_EXITMAINT",
    "07" => "CAP_BULKREFILL", "08" => "CAP_SUSTEMPSTABILIZE", "09" => "CAP_CUSTOM", "0A" => "CAP_SUSTEMPCHANGE", "0B" => "CAP_STANDBY");
my %CARRIERANS = (0 => "IDLE", 1 => "REJECT", 2 => "OK", 3 => "SUCCESS", 4 => "TIMEOUT", 5 => "REQ-ERROR", 6 => "SUMM-ERROR", 7 => "WRAN", 8 => "ALART",
    9 => "READ-ERROR", 10 => "ERR-CE", 11 => "ERR-TE", 12 => "ERR-HE", 13 => "ERR-EE", 14 => "ERR-HID", 15 => "ERR-FMT", 16 => "ERR-CMM", 17 => "ERR-VRT",
    18 => "ERR-NTG", 19 => "ERR-WRT", 20 => "ERR-ID1", 21 => "ERR-ID2", 22 => "ERR-DCN", 23 => "ERR-IDX");
my %CARRIERSTATE = (0 => "NOT REPORT", 1 => "RECEIVED", 2 => "REMOVED");
my %CCODE = ("01" => "SYS_DATA", "02" => "STAT_CHNG", "11" => "AUTO_CTRL", "12" => "MENTE_CTRL", "13" => "RC_CTRL", "14" => "LL_CTRL", "15" => "WHC_CTRL",
            "16" => "LLRBT_CTRL", "17" => "GV_CTRL", "18" => "SP_CTRL", "19" => "LP_CTRL", "1A" => "FERBT_CTRL", "1B" => "BERBT_CTRL", "1C" => "ALNR_CTRL",
            "1D" => "SS_CTRL", "1E" => "WL_CTRL", "1F" => "RCBF_CTRL", "20" => "CST_CTRL", "21" => "UIO_CTRL", "22" => "MON_CTRL", "23" => "WID_CTRL",
            "24" => "CID_CTRL", "26" => "EFEM_CTRL", "30" => "30-EPI", "32" => "32-EPI", "35" => "PCV_CTRL", "36" => "MFC_CTRL", "3A" => "3A-EPI", "41" => "SYSINFO_REQ", "42" => "STATUS_REQ", "51" => "EVENT_REP",
            "61" => "MAINPC_CTRL", "62" => "TM_CTRL", "63" => "PM_CTRL", "64" => "CAP_CTRL", "70" => "CCU_NOTIFY", "71" => "RCMD_CTRL", "80" => "EDA_EVENT",
            "90" => "COMP_NOTIFY", "91" => "MMI_DATA_UPDATE", "92" => "PMSTEP_CTRL", "93" => "MMI_EMERALD_SUS_UPDATE", "94" => "MMI_UPDATE_WITH_HO_CAP_DATA",
            "95" => "MMI_DUMMYINFO_UPDATE", "100" =>"SCHE_CMD_CANNOT_EXECUTE");
my %CCUTYPE = ("01" => "CCU_NOTIFY");
my %CIDTYPE = ("01" => "CID_ID_READ", "02" => "CID_ID_WRITE", "03" => "CID_TAG_READ", "04" => "CID_TAG_WRITE", "20" => "CID_ALRESET");
my %CMDMOVEBEUNIT = ("00" => "BERB","01" => "HOME","02" => "RC1","03" => "RC2","04" => "RC3","05" => "RC4","06" => "RC5", "07" => "LLL", "08" => "LLL2", "09" => "RLL", "10" => "RLL2");
my %CMDMOVEFEUNIT = ("00" => "FERB","01" => "HOME","02" => "LP1","03" => "LP2","04" => "LP3","05" => "LP4","06" => "Align(ext)", "07" => "LLL", "08" => "LLL2",
    "09" => "RLL", "10" => "RLL2", "11" => "MESUR", "12" => "COOL1", "13" => "COOL2", "14" => "UnknownNow");
my %CSTYPE = ("01" => "CST_COOL");
my %CTRLSTAT = (0 => "IDLE",1 => "READY",2 => "EXEC",3 => "PAUSE", 4 => "TEACH");
my %DIRECT = (1 => "To:", 2 => "Fr:");
my %EDATYPE = ("01" => "EDA_ONLINECTRL", "02" => "EDA_PROCESS", "03" => "EDA_CARRIER", "04" => "EDA_PECIPET", "05" => "EDA_STEP", "06" => "EDA_E87LPAMSM",
    "07" => "EDA_E87COSM", "08" => "EDA_E87LPCASM", "09" => "EDA_E87LPRSM", "0A" => "EDA_E87LPTSM", "0B" => "EDA_E40PJSM", "0C" => "EDA_E94CJSM",
    "0D" => "EDA_E90SLSM", "0E" => "EDA_E90SOSM", "0F" => "EDA_EXCEPTION", "10" => "EDA_PROCWAF", "11" => "EDA_LEAK", "12" => "EDA_ECCHANGE",
    "13" => "EDA_AUTOLEAK");
my %EFEMTYPE = ("01" => "EFEM_ISOLATE", "02" => "EFEM_CDAPURGE", "03" => "EFEM_N2PURGE", "04" => "EFEM_LEAKCHECK", "05" => "EFEM_SETMODE", "06" => "EFEM_SETFLOW",
    "07" => "EFEM_SETVALVE", "08" => "EFEM_SETPRESS", "09" => "EFEM_PURGESKIP", "0A" => "EFEM_ABORT", "20" => "EFEM_ALRESET");
my %EVENTID = (1740 => "MATERIAL_RECEIVED", 1741 => "MATERIAL_REMOVED");
my %EVENTTYPE = ("01" => "LP1", "02" => "LP2", "03" => "LP3", "04" => "LP4", "05" => "CID1", "06" => "CID2", "07" => "CID3", "08" => "CID4", "09" => "FERBT",
    "0A" => "BERBT", "0B" => "CST1", "0C" => "CST2", "0D" => "LL1", "0E" => "LL2", "0F" => "LL3", "10" => "LL4", "11" => "WHC", "12" => "MON",
    "13" => "ALN", "14" => "LLALN1", "15" => "LLALN2", "16" => "LLRBT1", "17" => "LLRBT2", "18" => "RC1", "19" => "RC2", "1A" => "RC3", "1B" => "RC4",
    "1C" => "RC5", "1D" => "SS1", "1E" => "SS2", "1F" => "SS3", "20" => "SS4", "21" => "SS5", "22" => "WL1", "23" => "WL2", "24" => "WL3", "25" => "WL4",
    "26" => "WL5", "27" => "RCBF1", "28" => "RCBF2", "29" => "RCBF3", "2A" => "RCBF4", "2B" => "RCBF5", "2C" => "GV1", "2D" => "GV2", "2E" => "GV3",
    "2F" => "GV4", "30" => "GV5", "31" => "GV6", "32" => "GV7", "33" => "GV8", "34" => "GV9", "35" => "SP1", "36" => "SP2", "37" => "UIO", "38" => "WID",
    "3C" => "EFEM", "40" => "ALARM", "41" => "TMC", "42" => "PMC1", "43" => "PMC2", "44" => "PMC3", "45" => "PMC4", "46" => "PMC5", "47" => "AMC",
    "50" => "PROCDATA", "51" => "JOBDELETE", "52" => "DATACHG", "53" => "COMMAND", "54" => "RCPCHG", "55" => "COM", "56" => "RCPSTEP", "57" => "LEAKCHECK",
    "58" => "AGV", "59" => "AWC", "60" => "PARTMUP", "61" => "INTERLOCK", "62" => "TM_INTERLOCK", "63" => "CCU_LOG", "64" => "PMSCRIPT", "65" => "CAP",
    "66" => "SystemStatus", "67" => "ScriptStatus");
my %FEABT = (0 => "NO-ABORT",1 => "ABORT",2 => "PAUSE",3 => "RESUME");
my %FEANS = (0 => "NONE",1 => "REJECTED",2 => "OK",3 => "WAFER_BRANK",4 => "COMPLETED",5 => "PAUSED",6 => "ABORTED", 7 => "TIMEOUT_OK", 8 => "TIMEOUT_CMPL",
    9 => "FORMAT_ERR", 10 => "PARAM_ERR", 11 => "BEUNIT_ERR", 12 => "TEACH_PRM_ERR", 20 => "CHG_TEACH", 21 => "ARM_NOT_RETURN", 22 => "POS_INTLOCK",
    23 => "WF_INTLOCK", 24 => "UNIT_INTLOCK", 25 => "NOT_EXIST_CS", 27 => "WF_ERR1", 28 => "WF_ERR2", 29 => "WF_ERR3", 30 => "WF_ERR4", 31 => "NAK_BUSY",
    32 => "NAK_CHKSUM", 33 => "NAK_T1TIMEOUT", 34 => "NAK_INVALID_CMD", 35 => "NAK_INVALID_PRM", 36 => "NAK_RECV_ERR", 37 => "RES_MESID_ERR");
my %FEAXIS = (0 => "All Axes", 1 => "XU Axis", 2 => "XD Axis", 3 => "Y Axis", 4 => "U Axis", 5 => "Z Axis");
my %FELOC = (0 => "Invalid", 1 => "GetBeforeStart", 2 => "GetBeforeExtend", 3 => "GetWaferExtend", 4 => "GetAfterExtend", 5 => "GetAfterChuck", 6 => "GetAfterEnd",
    7 => "PutBeforeStart", 8 => "PutBeforeExtend", 9 => "PutWaferExtend", 10 => "PutAfterExtend", 11 => "PutAfterEnd", 12 => "PutAfterEnd");
my %FEREQ = (0 => "NONE", 1 => "AlarmReset", 2 => "Initialize", 3 => "HomePos", 4 => "ArmReturn", 5 => "AxisU", 6 => "WafClamp", 7 => "Load", 8 => "Unload",
    9 => "WafMove1", 10 => "TechRead", 11 => "TechWrite", 12 => "AutoTech", 13 => "SetSpeed", 14 => "SetMode");
my %FEREQDATA = ("Arm" => "","From" => "","FSlot" => "","To" => "","TSlot" => "","WafBrank" => "","ShfCorr" => "", "NA" => "", "REQ" => "");
my %FETYPE = ("01" => "FERBT_INIT", "02" => "FERBT_HOME", "03" => "FERBT_LOAD", "04" => "FERBT_UNLOAD", "05" => "FERBT_AXIS", "06" => "FERBT_PAUSE",
    "07" => "FERBT_RESUME", "08" => "FERBT_ABORT", "09" => "FERBT_STOP", "0A" => "FERBT_MOVE", "0B" => "FERBT_CLAMP_BAR", "0C" => "FERBT_ARM_RET",
    "0D" => "FERBT_PULSE", "0E" => "FERBT_WAF_TRANS", "0F" => "FERBT_WAF_TRANS2", "10" => "FERBT_SETSPEED", "11" => "FERBT_VACUUM",
    "12" => "FERBT_TEACH", "20" => "FERBT_ALRESET");
my %FEUNIT = (0 => "FERB",1 => "HOME",2 => "LP1",3 => "LP2",4 => "LP3",5 => "LP4",6 => "Align(ext)", 7 => "LLL", 8 => "LLL2", 9 => "RLL", 10 => "RLL2", 11 => "MESUR", 12 => "COOL1", 13 => "COOL2", 14 => "UnknownNow");
my %FINSTAT = (0 => "Successful",1 => "Error");
my %GVCTLCHANGE = (0 => "IDLE",1 => "READY",2 => "EXEC");
my %GVCTRLSTATE = ("00" => "IDLE", "01" => "READY", "02" => "EXECUTING", "03" => "IDLE", "04" => "MAINTENANCE");
my %GVCTRLTYPE = ("01" => "GV_OPEN", "02" => "GV_CLOSE", "20" => "GV_ALRESET");
my %GVREQ = (0 => "UD",1 => "ALARMRESET",2 => "GV_CLOSE",3 => "GV_OPEN");
my %GVSTSCHANGE = (0 => "OPEN",1 => "CLOSE",2 => "NO_SENS", 3 => "SENS_ERR", 4 => "UNKNOWN", 255 => "INIT");
my %GVTYPE = (0 => "GV1",1 => "GV2",2 => "GV3",3 => "GV4",4 => "GV5",5 => "GV6",6 => "GV7", 7 => "GV8", 8 => "GV9");#(0 => "WHC",1 => "LLL",2 => "UD",3 => "RLL");
my %IOCTOLL = (0 => "UD",1 => "LLL",2 => "LLL2",3 => "RLL",4 => "RLL2");
my %LLRBTTYPE = ("01" => "LLRBT_INIT", "02" => "LLRBT_HOME", "03" => "LLRBT_LOAD", "04" => "LLRBT_UNLOAD", "05" => "LLRBT_AXIS", "06" => "LLRBT_PAUSE",
    "07" => "LLRBT_RESUME", "08" => "LLRBT_ABORT", "09" => "LLRBT_STOP", "0A" => "LLRBT_MOVE", "0B" => "LLRBT_SWAP", "0C" => "LLRBT_POS", "0D" => "LLRBT_PULSE",
    "0E" => "LLRBT_TEACH", "11" => "LLRBT_SEQ_INIT", "12" => "LLRBT_UPDATE", "13" => "LLRBT_MTR_POS", "14" => "LLRBT_SETSPEED", "20" => "LLRBT_ALRESET");
my %LLSTSCHANGE = (0 => "UNKNOWN",1 => "1ATM",2 => "TRANSITION",3 => "VACUUM");
my %LLTYPE = ("01" => "LL_SETVALVE", "03" => "LL_BACKFILL", "04" => "LL_PUMPDOWN", "05" => "LL_ISOLATE", "06" => "LL_BASE", "07" => "LL_SETPRESS", "08" => "LL_SETPID",
    "09" => "LL_CYCLE", "0A" => "LL_CYCLE_STOP", "0B" => "LL_ABORT", "0C" => "LL_LEAK", "0D" => "LL_SETFLOW", "0E" => "LL_COOL", "13" => "LL_BACKFILL_AUTO",
    "14" => "LL_PUMPDOWN_AUTO", "15" => "LL_ISOLATE_AUTO", "16" => "LL_FASTIDLE", "17" => "LL_IDLEFLOW", "20" => "LL_ALRESET", "21" => "LL_FLOW_MFC");
my %LOTSEQ = (0 => "NO_SEQ", 1 => "IN_REQUEST", 2 => "IN_COMP", 3 => "MOVE_IN_COMP", 4 => "PROCESS_START", 5 => "LOCK_COMP", 6 => "PROCESS_END", 7 => "REPORT_COMP",
    8 => "OUT_REQUEST", 9 => "UNLOCK_COMP", 10 => "OUT_COMP", 11 => "MOVE_OUT_COMP", 12 => "COMPLETE", 13 => "UNLOAD_REQ");
my %LPABT = (0 => "NONE", 1 => "CARRIER_STOP", 2 => "CARRIER_ABORT", 3 => "PAUSE", 4 => "RESUME");
my %LPACCMODE = (0 => "MANUAL",1 => "MANUAL EXEC",2 => "AUTO",3 => "AUTO EXEC");
my %LPANS = (0 => "NONE", 1 => "REJECT", 2 => "OK", 3 => "COMPLETED", 4 => "STOPPED", 5 => "ABORTED", 6 => "INVALID_CMD", 7 => "INVALID_ARG", 8 => "ALARM", 9 => "BUSY",
    10 => "DENIED", 11 => "NO_POD", 12 => "NOT_READY", 13 => "UNKNOWN_DATA", 14 => "OUT_OF_RANGE", 15 => "UNKNOWN_ECID", 16 => "TIMEOUT_OK", 17 => "TIMEOUT_CMPL",
    18 => "OTHER_ERROR", 19 => "AMHS_ERROR", 20 => "FERB_INTLK", 21 => "L_UL_INCOMPLETED", 22 => "N2PRS_UP_ERR", 23 => "N2PRS_LW_ERR", 24 => "N2PG_ERR",
    25 => "N2PGKEY_OFF", 26 => "N2FLOW_LIMIT", 27 => "N2_INTLK", 28 => "ERR");
my %LPCS = (0 => "IDLE",1 => "READY",2 => "EXEC",3 => "PAUSE");
my %LPCTLCHANGE = (0 => "IDLE",1 => "READY",2 => "EXEC");
my %LPREQ = (0 => "NONE", 1 => "ALARM_RESET", 2 => "PORT_INIT", 3 => "LOAD", 4 => "UNLOAD", 5 => "CANCEL_LOAD", 6 => "CANCEL_UNLOAD", 7 => "CARRIER_IN", 8 => "CARRIER_OUT_D",
    9 => "CARRIER_OUT", 10 => "CARRIER_MAP", 11 => "CARRIER_REMAP", 12 => "CARRIER_CLAMP", 13 => "CARRIER_UNCLAMP", 14 => "CARRIER_DOCK", 15 => "CARRIER_UNDOCK",
    16 => "CARRIER_OPEN", 17 => "CARRIER_CLOSE", 18 => "PORT_ALARM_CLEAR", 19 => "LED_BLINK_START", 20 => "LED_BLINK_STOP", 21 => "M_CARRIER_OPEN", 22 => "M_CARRIER_CLOSE",
    23 => "CHANGE_ACCESS", 24 => "CHANGE_SERVICE", 25 => "CHANGE_HOST", 26 => "ID_READ", 27 => "ID_WRITE", 28 => "AMHS_RECOVER", 29 => "TAG_READ", 30 => "TAG_WRITE",
    31 => "LP_RESERVE", 32 => "M_CARRIER_DOCK", 33 => "M_CARRIER_UNDOCK", 34 => "M_CALIB", 35 => "M_LON", 36 => "M_LOF", 37 => "M_LBL", 38 => "ID_READER_ERR",
    39 => "OPE_SW_ON", 40 => "N2FLOW", 41 => "ORGSH", 42 => "ABORG", 43 => "RELOAD", 44 => "PRG_MODE", 45 => "N2PURGE", 46 => "NOZZLE", 47 => "NZL_RESERVE",
    50 => "STATUS", 51 => "VERSION", 52 => "CARRIER_STOP", 53 => "CARRIER_ABORT", 54 => "CARRIER_PAUSE", 55 => "CARRIER_RESUME", 56 => "CARRIER_OUT_UCD",
    57 => "CARRIER_OUT_UD", 58 => "LED_OPE", 59 => "LED_CLR", 60 => "M2CARRIER_OPEN", 61 => "M2CARRIER_DOCK", 62 => "M2CARRIER_UNDOCK", 69 => "CARRIER_DOCKMAP");
my %LPSTATE = ("00" => "IN-READY", "01" => "MID-POSITION", "02" => "OUT-READY");
my %LPTRANSSTAT = (0 => "OUTOFSERVICE", 1 => "TRANSFERBLOCKED", 2 => "READYTOLOAD", 3 => "READYTOUNLOAD", 4 => "4 L", 5 => "TRANSFERBLOCKED_L", 6 => "TRANSFERBLOCK_U");
my %LPTRCHANGE = (0 => "Idle",1 => "In-Ready",2 => "In-Exec",3 => "IN-Comp",4 => "Out-Ready",5 => "Out-Exec",6 => "Out-Comp");
my %LPTYPE = ("01" => "LP_INIT", "03" => "LP_LOAD", "04" => "LP_UNLOAD", "08" => "LP_ABORT", "09" => "LP_MODE_CHG", "0A" => "LP_SRV_CHG", "0B" => "LP_RESERVE", "0C" => "LP_LED_BLINK",
    "11" => "LP_AMHS_RCVR", "13" => "LP_LOAD_CNCL", "14" => "LP_UNLOAD_CNCL", "17" => "LP_MAP_READ", "18" => "LP_IN", "19" => "LP_OUT", "1A" => "LP_CLAMP",
    "1B" => "LP_UNCLAMP", "1C" => "LP_DOCK", "1D" => "LP_UNDOCK", "1E" => "LP_OPEN", "1F" => "LP_CLOSE", "20" => "LP_ALRESET", "21" => "LP_HOST_CHG", "24" => "LP_RESERVE_LED",
    "25" => "LP_MTOPEN", "26" => "LP_MTCLOSE", "27" => "LP_MTDOCK", "28" => "LP_MTUNDOCK", "29" => "LP_IDERR_LED", "2A" => "LP_OPE_SW", "2B" => "LP_N2_FLOW", "2C" => "LP_ORGSH",
    "2D" => "LP_ABORG", "2E" => "LP_RELOAD", "2F" => "LP_N2_MODE", "30" => "LP_N2_PURGE", "31" => "LP_N2_NOZZLE", "32" => "LP_N2_NOZZLERSV");
my %MAINPCTYPE = ("01" => "MAINPC_SHUTDOWN", "02" => "MAINPC_WIN_OPEN", "03" => "MAINPC_WIN_CLOSE", "04" => "MAINPC_ALARM_LOG", "05" => "MAINPC_PROC_LOG", "06" => "MAINPC_PROC_EXIT",
    "07" => "MAINPC_LEAK_LOG", "08" => "MAINPC_SCRIPT_LOG", "09" => "MAINPC_SAVE_LOG", "0A" => "MAINPC_MAINT_LOG", "0B" => "MAINPC_AWC_LOG", "0C" => "MAINPC_START_APP");
my %MAINTTYPE = ("01" => "SETUP_STRT", "02" => "SETUP_STOP", "03" => "SHUTDWN_STRT", "04" => "SHUTDWN_STOP", "05" => "ISOLATE_STRT", "06" => "ISOLATE_STOP", "07" => "TRANS_STRT",
    "08" => "TRANS_STOP", "09" => "WAF_DEL", "0A" => "WAF_ADD", "0B" => "SEMIPRO_START", "0C" => "LLCYCLE_STRT", "0D" => "LLCYCLE_STOP", "0E" => "SCRIPT_START",
    "0F" => "SCRIPT_STOP", "10" => "SEMIMON_START", "11" => "SEMIMON_STOP", "12" => "SEMIMON_ABORT", "13" => "SEMILEAK_START", "14" => "SEMILEAK_STOP");
my %MODULE = ("MA" => "MAIN", "MM" => "MMI", "SC" => "SCHEDULER", "MC" => "MCIF", "MS" => "MCSHMEM", "AL" => "WATCHALARM", "PR" => "PROCESSLOG", "TR" => "TREND", "TF" => "TRFTP",
    "CC" => "CCU", "C2" => "CCU2", "CM" => "EXTCOM", "RC" => "RCS", "EE" => "EES", "CP" => "CAP", "TL" => "TRANSLOG", "\@S" => "SC-MMI", "\@C" => "CCU-MMI", "MD" => "MCIF-SIM");
my %MONTYPE = ("01" => "MON_INIT", "02" => "MON_MOVE", "03" => "MON_UPLOAD_RCP", "04" => "MON_EXIST_RCP", "05" => "MON_ABORT", "06" => "MON_MODE", "20" => "MON_ALRESET");
my %OPERATEMODE = ("00" => "NORMAL", "01" => "MAINTENANCE", "02" => "UNKNOWN OperateMode");
my %PASTATE = (0 => "ASSOCIATED", 1 => "NOT ASSOCIATED", 2 => "ASSOCIATED to ASSOCIATED");
my %PMSTEPTYPE = ("01" => "PMSTEP_PRE_START", "02" => "PMSTEP_PRE_END", "03" => "PMSTEP_PHY_START", "04" => "PMSTEP_PHY_END", "05" => "PMSTEP_POST_START", "06" => "PMSTEP_POST_END", "07" => "PMSTEP_NONE");
my %PMTYPE = ("01" => "PM_INIT", "0F" => "PM_SYSTIME", "20" => "PM_ALRESET");
my %PNUMB = (0 => 1, 1 => 2, 2 => 3, 3 => 4);
my %PVCTYPE = ("00" => "PCV_CMD_WRITE_PARAM", "01" => "PCV_CMD_READ_PARAM");
my %RBTCTRLSTATE = (0 => "IDLE",1 => "READY",2 => "EXEC",3 => "PAUSE",4 => "TEACH");
my %RCBFTYPE = ("02" => "RCBF_HOME", "03" => "RCBF_UP", "04" => "RCBF_DOWN", "05" => "RCBF_MOVE_PICK", "06" => "RCBF_PUT", "07" => "RCBF_GET", "20" => "RCBF_ALRESET");
my %RCCTRLSTAT = (0 => "SETUP", 1 => "IDLE", 2 => "STAND_BY", 3 => "READY", 4 => "RUN", 5 => "PAUSE", 6 => "END", 7 => "ALEND", 8 => "ABEND", 9 => "WAIT");
my %RCMDTYPE = ("01" => "RCMD_CHGDEPO", "02" => "RCMD_CHGETCH", "03" => "RCMD_CHGDEPOLIMIT", "04" => "RCMD_CHGETCHLIMIT", "05" => "RCMD_WSTART", "06" => "RCMD_WSTOP", "07" => "RCMD_CHGACTFOLDER",
    "08" => "RCMD_EQUSTOP", "09" => "RCMD_EQUABORT", "0A" => "RCMD_EQUPAUSE", "0B" => "RCMD_EQURESUME", "0C" => "RCMD_EQURESET", "0D" => "RCMD_CHGWAFER",
    "0E" => "RCMD_CHGWAFERLIMIT", "11" => "RCMD_CHGDEPONAME", "12" => "RCMD_CHGETCHNAME", "13" => "RCMD_CHGWAFERNAME", "14" => "RCMD_CHGLIGHTTOWER");
my %RCMODE = ("00" => "NORMAL", "01" => "MAINT", "02" => "ENG");
my %RCSTARTP2 = ("00" => "UNKNOWN", "01" => "PROCESS", "02" => "BACKFILL", "03" => "PUMPDOWN", "04" => "ISOLATE", "05" => "WAIT", "06" => "BASE", "07" => "LEAK", "08" => "PRE",
    "09" => "MAIN", "0A" => "POST", "0B" => "FIRST", "0C" => "LAST", "0D" => "PURGE", "0E" => "SPECIAL", "0F" => "CAP", "10" => "CAP_WAIT");
my %RCTYPE = ("01" => "RC_RESET", "02" => "RC_START", "06" => "RC_PAUSE", "07" => "RC_RESUME", "08" => "RC_ABORT", "09" => "RC_MODE_CHG", "0A" => "RC_SETDUMMY", "0B" => "RC_SETACTIVE",
    "0C" => "RC_SET_VIRTUAL_DI", "20" => "RC_ALRESET", "21" => "RC_LATCH_RELEASE", "30" => "RC_INITIALIZE", "31" => "RC_STANDBY", "32" => "RC_HANDOFF");
my %S2F50 = ("00" => "Ok, completed", "01" => "Invalid command", "02" => "Cannot do now", "03" => "Parameter error", "04" => "Initiated for asynchronous completion",
    "05" => "Rejected, already in desired condition", "06" => "Invalid object");
my %SPMODE = (0 => "NORMAL",1 => "TURN",2 => "GET_EXT",3 => "GET_UP",4 => "GET_RET",5 => "PUT_EXT",6 => "PUT_DOWN", 7 => "PUT_RET");
my %SPTYPE = ("01" => "SP_UP", "02" => "SP_DOWN", "20" => "SP_ALRESET");
my %SSABT = (0 => "NONE",1 => "STOP",2 => "ABORT");
my %SSANS = (0 => "NONE", 1 => "OK", 2 => "REJECT", 3 => "COMPLETED", 4 => "SUS_STOP", 5 => "SUS_ABORT", 6 => "TIMEOUT_OK", 7 => "TIMEOUT_CMPL", 8 => "SENS_ERROR", 9 => "SENS_UNFIX",
    10 => "SUS_UNIT_ERROR", 11 => "NO_INITIALIZE", 12 => "IL_FROM_BERB", 13 => "HW_UP_LIMIT", 14 => "HW_LW_LIMIT", 15 => "HW_ROT_DISABLE", 16 => "SW_ROT_DISABLE",
    17 => "SW_MOV_DISABLE", 18 => "IL_MISSMATCH", 19 => "SW_UP_LIMIT", 20 => "SW_LW_LIMIT", 21 => "GV_OPEN", 22 => "MTION_STOP", 23 => "LID_OPEN", 24 => "RB_EXTEND",
    25 => "CAB_OPEN", 26 => "FLAG_READ_ERR", 27 => "HOME_POS_ERR");
my %SSCTLCHANGE = (0 => "IDLE",1 => "READY",2 => "EXEC");
my %SSERR = (0 => "NONE",1 => "POSI_MISSMATCH",2 => "FAULT_INPUT",3 => "EXT_STOP_INPUT",4 => "FE_FAULT",5 => "REV_LIMIT",6 => "FWD_LIMIT", 7 => "OTHER_FAULT", 8 => "RES_MSG",
    9 => "DISCONNECT", 10 => "BOTH_LIMITS", 11 => "FLAG_READ_ERR", 12 => "HOME_POS_ERR");
my %SSREQ = (0 => "NONE",1 => "ALMRESET",2 => "SUS_INIT",3 => "SUS_HOME",4 => "NA",5 => "SUS_MOVE",6 => "SUS_INDEX", 7 => "SUS_ROT");
my %SSREQDATA = ("Mode" => "","Pls" => "","REQ" => "");
my %SSTYPE = ("01" => "SS_INIT", "02" => "SS_HOME", "03" => "SS_UP", "04" => "SS_DOWN", "05" => "SS_AXIS", "06" => "SS_PROC", "07" => "SS_CLAMP", "08" => "SS_UNCLAMP", "09" => "SS_INDEX", "0A" => "SS_ROTATE", "20" => "SS_ALRESET");
my %STATTYPE = ("01" => "STATUS_PMC", "02" => "STATUS_TMC", "03" => "STATUS_AMC", "04" => "STATUS_WAF_MAP", "05" => "STATUS_LL_TECH");
my %STEPFLAG = ("00" => "INIT", "01" => "START", "02" => "SUMMARY", "03" => "03-UNKNOWN", "04" => "LEAK", "08" => "DEPO", "09" => "09-EPI", "0A" => "0A-UNKNOWN", "10" => "END", "20" => "ALEND", "40" => "ABEND", "80" => "ETCH" );
my %SUSZPOS = (0 => "UNFIX", 1 => "DOWN", 2 => "UP", 3 => "ERROR", 4 => "NO_SENS", 5 => "HEATING", 6 => "DOWNCL", 7 => "UPCL", 8 => "MACHIN", 9 => "9-EPI",
            10 => "10-EPI", 11 => "11-EPI", 255 => "UD-EPI");
my %SYSDATATYPE = ("01" => "CNFSYS", "02" => "CNFTM", "03" => "CNFPM", "04" => "CNFLP", "05" => "RCPPJ", "06" => "RCPPRO", "07" => "PARTM", "08" => "PARPM", "09" => "PARLP",
    "0A" => "PARSYS", "0B" => "CNFLL", "0C" => "CNFWL", "0D" => "RCPMM", "0E" => "CNFMM", "0F" => "PARTMUPLD", "10" => "POSTM", "12" => "RCPLIST");
my %SYSTYPE = ("01" => "SYSINFO_PMC", "02" => "SYSINFO_TMC", "03" => "SYSINFO_AMC");
my %TMTYPE = ("01" => "TM_INIT", "02" => "TM_TEACH", "03" => "TM_PAUSE", "04" => "TM_RESUME", "05" => "TM_ABORT", "06" => "TM_STOP", "07" => "TM_ISOLATE",
    "08" => "TM_MAINTENANCE", "09" => "TM_SYSSTAT", "0F" => "TM_SYSTIME", "20" => "TM_ALRESET", "21" => "TM_WLALRESET");
my %TRENDTYPE = ("01" => "TRND_COMP");
my %UIOSIGP1 = ("01" => "ALARM", "02" => "END", "04" => "RUN", "08" => "READY", "10" => "HOST", "20" => "UTIL1", "40" => "UTIL2", "80" => "UTIL3", "FF" => "ALL");
my %UIOTYPE = ("01" => "UIO_SIG_ON", "02" => "UIO_SIG_OFF", "03" => "UIO_BUZ_ON", "04" => "UIO_BUZ_OFF", "05" => "UIO_MODE");
my %WHCTYPE = ("01" => "WHC_SETVALVE", "03" => "WHC_BACKFILL", "04" => "WHC_PUMPDOWN", "05" => "WHC_ISOLATE", "06" => "WHC_BASE", "07" => "WHC_SETPRESS",
    "08" => "WHC_SETPID", "09" => "WHC_CYCLE", "0A" => "WHC_CYCLE_STOP", "0B" => "WHC_ABORT", "0C" => "WHC_LEAK", "0D" => "WHC_SETFLOW", "0E" => "WHC_SETSNSPOS",
    "0F" => "WHC_SETSNSTHR", "10" => "WHC_SETSNSWRT", "13" => "WHC_BACKFILL_AUTO",	"14" => "WHC_PUMPDOWN_AUTO", "15" => "WHC_ISOLATE_AUTO", "20" => "WHC_ALRESET");
my %WIDTYPE = ("01" => "WID_INIT", "02" => "WID_MOVE", "20" => "WID_ALRESET");
my %WIOANS = (0 => "WIO_NONE", 1 => "WIO_OK", 2 => "WIO_COMPLETED", 3 => "WIO_REJECT", 4 => "WIO_MAINTENANCE", 5 => "WIO_SEQ_STOP", 6 => "WIO_SEQ_ABORT",
    7 => "WIO_TIMEOUT_OK", 8 => "WIO_TIMEOUT_CMPL", 9 => "WIO_STATE_ERROR", 10 => "WIO_INTERLOCK", 11 => "WIO_OTHER_ERROR", 12 => "WIO_SENS_UNFIX",
    13 => "WIO_SENS_ERROR", 14 => "WIO_PUMP_OFF", 15 => "WIO_PUMP_ALARM", 16 => "WIO_2PSI", 17 => "WIO_IOC_PUMP_BUSY", 18 => "WIO_PRESS_GAUGE_ERROR",
    19 => "WIO_DEV_NOT_CONNECT", 20 => "WIO_IL_FROM_FERB", 21 => "WIO_IL_FROM_BERB", 22 => "WIO_IL_FROM_PRESS", 23 => "WIO_IL_FROM_GV",
    24 => "WIO_IL_FROM_WAF", 25 => "WIO_FAST_VALVE_STATE_ERROR", 26 => "WIO_PRESS_95PER_ERROR", 27 => "WIO_THV_POSIT_OVER");
my %WIOCTRLSTATE = (0 => "IDLE",1 => "READY",2 => "EXEC",3 => "PAUSE",4 => "MAINT");
my %WIOGVSTATE  = (0 => "GV_OPEN", 1 => "GV_CLOSE", 2 => "GV_NO_SENS", 3 => "GV_SENS_ERR", 4 => "4:UNKNOWN", 8 => "8:UNKNOWN", 18 => "18:UNKNOWN",  255 => "GV_UNFIX");
my %WIOPRESSSTATE = (0 => "UNKNOWN",1 => "1ATM",2 => "INTRANS",3 => "VACUUM", 4 => "PRESSDIFF_GV3", 5 => "PRESSDIFF_GV4");
my %WIOREQ = (0 => "UnDefined", 1 => "WIO_ALARMRESET", 2 => "WIO_BACKFILL", 3 => "WIO_VACUUM", 4 => "WIO_BASE", 5 => "WIO_ISOLATE", 6 => "WIO_SETPRESS",
    7 => "WIO_SETPID", 8 => "WIO_SETFLOW", 9 => "WIO_CYCLEPURGE", 10 => "WIO_LEAKCHECK", 11 => "WIO_MAINTENANCE", 12 => "WIO_SET_VALVE", 13 => "WIO_COOLING",
    14 => "WIO_THV_POS", 15 => "WIO_THV_PRM", 16 => "WIO_R_THV_PRM", 17 => "WIO_SETPARMS", 18 => "WIO_FASTIDLE", 19 => "WIO_SETIDLEFLOW", 20 => "WIO_SETFLOWMFC");
my %WIOTYPE = (0 => "GV1",1 => "GV2",2 => "GV3",3 => "GV4",4 => "GV5",5 => "GV6",6 => "GV7", 7 => "GV8", 8 => "GV9");
my %WIOVALVESTATE = (0 => "UNKNOWN",1 => "ISOLATE",2 => "SLOW",3 => "FAST",4 => "CTRL",5 => "BACKFILL",6 => "N2FLOW");
my %WLTYPE = ("03" => "WL_UP", "04" => "WL_DOWN", "20" => "WL_ALRESET");
my %SYSSTAT = ("0" => "SYS_IDLE", "1" => "SYS_READY", "2" => "SYS_RUN", "3" => "SYS_PAUSE", "4" => "SYS_COMP", "5" => "SYS_ABEND",
    "6" => "SYS_STEND", "7" => "SYS_ABING", "8" => "SYS_STING", "9" => "SYS_PAUSING", "10" => "SYS_TERMINATE");

my @logBucket;
my @mesLogs;
my $LogDir = $SelFolder . "\\UPC\\Log";
my $CcuLogDir = $SelFolder . "\\UPC\\SystemFile\\CcuFiles\\Log";
my $LogMCDir = $SelFolder . "\\LogMC";

if ($SelFolder ne "C:\\Project"){
    $LogDir = $SelFolder . "\\UPC\\Work\\CollectLog\\Log";
    $CcuLogDir = $SelFolder . "\\UPC\\Work\\CollectLog\\CcuFiles\\Log";
    $LogMCDir = $SelFolder . "\\UPC\\Work\\CollectLog\\LogMC";
}
say "LogDir: $LogDir";
say "CcuLogDir: $CcuLogDir";
say "LogMCDir: $LogMCDir";

GetAlarmDefinition(); #initialize %alarmInfo to know all alarms.
GetModCodeDefinition(); #Module code for alarms info

readLogFilesTimeStamp($LogDir);
readLogFilesTimeStamp($LogDir . "\\Cap");
readLogFilesTimeStamp($LogDir . "\\Cmd");
readLogFilesTimeStamp($LogDir . "\\Except");
readLogFilesTimeStamp($LogDir . "\\MCIF");
readLogFilesTimeStamp($LogDir . "\\Sched");

readLogFilesTimeStamp($CcuLogDir);
ccuLogAnalyser(@mesLogs);

push(@logBucket, "\n\t" . $LogMCDir . "\n");
readLogFilesTimeStamp($LogMCDir . "\\PMC1");
readLogFilesTimeStamp($LogMCDir . "\\PMC2");
readLogFilesTimeStamp($LogMCDir . "\\PMC3");
readLogFilesTimeStamp($LogMCDir . "\\PMC4");
readLogFilesTimeStamp($LogMCDir . "\\TMC");

my $tempfile = $SelFolder."\\LogsTimeStampInfo.txt";
open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
print OUTFILE @logBucket;
close (OUTFILE) || die "ERROR! Can't close $tempfile\n";

sub readLogFilesTimeStamp {
    my $myDir = $_[0];
    if (! -e $myDir){
        return;
    }
    push(@logBucket, "\n\t", $myDir, "\n");
    opendir DIR, $myDir;
    my @dirs = readdir(DIR);
    close DIR;
    foreach(@dirs) {
        my $item = $myDir . "/" . $_;
        my @fileContent = ();

        if (-T $item && $_ !~/_Decoded.txt/) {
            #my $file = $_;
            #print $_,"   : file\n";
            open(INFH, $item) || die "Unable to open $item : $!\n";
            @fileContent = <INFH>;
            close INFH;
            $tempfile = $item ."_Decoded.txt";

            if($_ =~/^TMALL_\d+_\d+.CSV/i) { # decode interlocks info in TMIL log file
                open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
                print OUTFILE decodeTMALLLogFile(@fileContent);
                close (OUTFILE) || die "ERROR! Can't close $tempfile\n";
            }elsif($_ =~/^TMIL_\d+_\d+.CSV/i) { # decode interlocks info in TMIL log file
                open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
                print OUTFILE decodeTMILLogFile(@fileContent);
                close (OUTFILE) || die "ERROR! Can't close $tempfile\n";
            }elsif ($_ =~/^WIO_\d+_\d+.CSV/i) { # decode driver's commands info in WIO log file
                open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
                print OUTFILE decodeWIOLogFile(@fileContent);
                close (OUTFILE) || die "ERROR! Can't close $tempfile\n";
            }elsif ($_ =~/^BERB_\d+_\d+.CSV/i) { # decode driver's commands info in BERB log file
                open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
                print OUTFILE decodeBERBLogFile(@fileContent);
                close (OUTFILE) || die "ERROR! Can't close $tempfile\n";
            }elsif ($_ =~/^FERB_\d+_\d+.CSV/i) { # decode driver's commands info in FERB log file
                open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
                print OUTFILE decodeFERBLogFile(@fileContent);
                close (OUTFILE) || die "ERROR! Can't close $tempfile\n";
            }elsif ($_ =~/^PmSus.*?_\d+_\d+.CSV/i) { # decode driver's commands info in susceptor log file
                open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
                print OUTFILE decodePmSusLogFile(@fileContent);
                close (OUTFILE) || die "ERROR! Can't close $tempfile\n";
            }elsif ($_ =~/^LP\d+_\d+_\d+.CSV/i) { # decode driver's commands info in loadport log file
                open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
                print OUTFILE decodeLPLogFile(@fileContent);
                close (OUTFILE) || die "ERROR! Can't close $tempfile\n";
            }elsif ($_ =~/^Align_\d+_\d+.CSV/i) { # decode driver's commands info in Aligner log file
                open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
                print OUTFILE decodeAlignerLogFile(@fileContent);
                close (OUTFILE) || die "ERROR! Can't close $tempfile\n";
            }elsif ($_ =~/^CLog_MCIF_\d+.txt/i) { # Now start deciphering \Log\CLog_MCIF files
                open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
                print OUTFILE decodeMCIFLogFile(@fileContent);
                close (OUTFILE) || die "ERROR! Can't close $tempfile\n";
            }if ($_ =~/^CLog_MMI_\d+.txt/i) { # Now start deciphering \Log\CLog_MMI files
                open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
                print OUTFILE decodeMMILogFile(@fileContent);
                close (OUTFILE) || die "ERROR! Can't close $tempfile\n";
            }elsif ($_ =~/^CLog_Scheduler_\d+.txt/i) { # Now start deciphering \Log\CLog_Scheduler files
                open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
                print OUTFILE decodeSchedulerLogFile(@fileContent);
                close (OUTFILE) || die "ERROR! Can't close $tempfile\n";
            }elsif ($_ =~/^CLog_CCU_\d+.txt/i) { # Now start deciphering \Log\CLog_CCU files
                open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
                print OUTFILE decodeCCULogFile(@fileContent);
                close (OUTFILE) || die "ERROR! Can't close $tempfile\n";
            }elsif ($_ =~/^CLog_WatchAlarm_\d+.txt/i) { # Now start deciphering \Log\CLog_WatchAlarm files
                open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
                print OUTFILE decodeWAlarmLogFile(@fileContent);
                close (OUTFILE) || die "ERROR! Can't close $tempfile\n";
            }elsif ($_ =~/^CLog_CAP_\d+.txt/i) { # Now start deciphering \Log\CLog_CAP files
                open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
                print OUTFILE decodeCAPLogFile(@fileContent);
                close (OUTFILE) || die "ERROR! Can't close $tempfile\n";
            }elsif ($_ =~/^Operation\d+.alg/i) { # Now start deciphering \Log\Operation files
                open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
                print OUTFILE decodeOperationLogFile(@fileContent);
                close (OUTFILE) || die "ERROR! Can't close $tempfile\n";
            }elsif ($_ =~/^CLog_ProcLog_\d+.txt/i) { # Now start deciphering \Log\CLog_ProcLog files
                open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
                print OUTFILE decodeProcessLogFile(@fileContent);
                close (OUTFILE) || die "ERROR! Can't close $tempfile\n";
            }elsif ($_ =~/^Except_CAP\d+.txt/i) { # Now start deciphering \Log\Except\Except_CAPx.txt files
                open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
                print OUTFILE decodeCapExceptionLogFile(@fileContent);
                close (OUTFILE) || die "ERROR! Can't close $tempfile\n";
            }elsif ($_ =~/^Meslog.ml_\d+.csv/i) { # Now collecting ccu Meslog files to parse later
                push(@mesLogs,$_);
            }elsif ($_ =~/^Tcplog.tl_\d+/i) { # Now parsing ccu Tcplog files
                open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
                print OUTFILE decodeTcpLogFile(@fileContent);
                close (OUTFILE) || die "ERROR! Can't close $tempfile\n";
            }elsif ($_ =~/^StatusCcuPol2.sl_\d+/i) { # Now parsing ccu Tcplog files
                open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
                print OUTFILE decodeStatusCcuPol2LogFile(@fileContent);
                close (OUTFILE) || die "ERROR! Can't close $tempfile\n";
            }elsif ($_ =~/^MCIF_\d+.txt/i) { # Now parsing MCIF_x.txt files
                open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
                print OUTFILE decodeMCIFSECSFile(@fileContent);
                close (OUTFILE) || die "ERROR! Can't close $tempfile\n";
            }

            my $timeStampInfo = "";
            my $timePattern = "";
            my $firstLine = shift(@fileContent);

            if (!@fileContent){ #file has only one line
                #say "Single line file: ", $_, " firstLine: ", $firstLine;
                next;
            }

            my $lastLine = pop(@fileContent); #get it to check
            #print "file: ", $_, " firstLine: ", $firstLine, " lastLine: ", $lastLine;
            if ($myDir =~/LogMC/){
                $timePattern = '\[(\d+\/\d+-\d+:\d+:\d+.\d+)\]';
            }else{
                $timePattern = '^(\d+\/\d+-\d+:\d+:\d+)';
                if ($_ =~ /CapRC\d|Except_/ ) {
                    $timePattern = '^(\d+\/\d+\/\d+ \d+:\d+:\d+.\d+)';
                }elsif ($_ =~/MCIF_\d+/){
                    $timePattern = '(\d+\/\d+-\d+:\d+:\d+.\d+)';
                }elsif ($_ =~ /^MC|SCHE_/ ) {
                    $timePattern = '^(\d+\/\d+\/\d+-\d+:\d+:\d+.\d+)';
                }
            }

            while(@fileContent){    #make sure there's timestamp data on $firstLine
                if ($firstLine !~ /$timePattern/) {
                    $firstLine = shift(@fileContent); #continue until getting a line with timestamp
                }else{
                    last;
                }
            }

            while(@fileContent){    #make sure there's timestamp data on $lastLine
                if ($lastLine !~ /$timePattern/) {
                    $lastLine = pop(@fileContent); #continue until getting a line with timestamp
                }else{
                    last;
                }
            }

            if ($firstLine eq ""){
                next;
            }elsif ($firstLine =~ /$timePattern/) {
                $timeStampInfo = "From: " . $1;
            }else{
                $timeStampInfo = "From: No firstLine TimeStamp ";
                next;
            }

            if ($lastLine eq ""){
                next;
            }elsif ($lastLine =~ /$timePattern/) {
                $timeStampInfo = $timeStampInfo . " -> " . $1 . "\t\t $_\n";
            }else{
                $timeStampInfo = $timeStampInfo . " -> No lastLine TimeStamp \t\t $_\n";
            }

            push(@logBucket, $timeStampInfo);
        }
    }
}

sub decodeMCIFSECSFile {
    say "->decodeMCIFSECSFile()";
    GetEvents();
    #GetTMUnit();
    GetTMReportID();
    #GetPMReportID();
    GetRemoteCmd();
    my $GVControlPreStateReport = "GVControlPreStateReport";
    my $GVControlStateReport = "GVControlStateReport";
    my $GVEndStateReport = "GVEndStateReport";
    my $GVValvePreStateReport = "GVValvePreStateReport";
    my $GVValveStateReport = "GVValveStateReport";
    my $BERBPreStateReport = "BERBPreStateReport";
    my $BERBStateReport = "BERBStateReport";
    my $BERBEndReport = "BERBEndReport";
    my $FERBPreStateReport = "FERBPreStateReport";
    my $FERBStateReport = "FERBStateReport";
    my $FERBEndReport = "FERBEndReport";
    my $SSControlPreStateReport = "SSControlPreStateReport";
    my $SSControlStateReport = "SSControlStateReport";
    my $SSZPositionReport = "SSZPositionReport";
    my $SSEndStateReport = "SSEndStateReport";
    my $LPAccessModeReport = "LPAccessModeReport";
    my $LPTransferPreStateReport = "LPTransferPreStateReport";
    my $LPTransferStateReport = "LPTransferStateReport";
    my $LPTransferEndReport = "LPTransferEndReport";
    my $LPEndReport = "LPEndReport";
    my $LPFoupStateReport = "LPFoupStateReport";
    my $WHCLLCPressPreStateReport = "WHC:LLCPressPreStateReport";
    my $IOCLLCPressPreStateReport = "LL:LLCPressPreStateReport";
    my $WHCLLCPressStateReport = "WHC:LLCPressStateReport";
    my $IOCLLCPressStateReport = "LL:LLCPressStateReport";
    my $WHCLLCControlPreStateReport = "WHC:LLCControlPreStateReport";
    my $IOCLLCControlPreStateReport = "LL:LLCControlPreStateReport";
    my $WHCLLCControlStateReport = "WHC:LLCControlStateReport";
    my $IOCLLCControlStateReport = "LL:LLCControlStateReport";
    my $WHCLLCEndStateReport = "WHC:LLCEndStateReport";
    my $IOCLLCEndStateReport = "LL:LLCEndStateReport";
    my $TMBEWaferEndReport = "TMBEWaferEndReport";
    my $TMBEWaferPreStateReport = "TMBEWaferPreStateReport";
    my $TMBEWaferStateReport = "TMBEWaferStateReport";
    my $TMFEWaferPreStateReport = "TMFEWaferPreStateReport";
    my $TMFEWaferStateReport = "TMFEWaferStateReport";
    my $TMFEWaferEndReport = "TMFEWaferEndReport";
    my $RCControlPreStateReport = "RCControlPreStateReport";
    my $RCControlStateReport = "RCControlStateReport";
    my $RCStepReport = "RCStepReport";
    my $RCPreStepReport = "RCPreStepReport";
    my $RCNewStepReport = "RCNewStepReport";
    my $RCLogTimeReport = "RCLogTimeReport";
    my $RCModeReport = "RCModeReport";
    my $UIOPreStateReport = "UIOPreStateReport";
    my $UIOStateReport = "UIOStateReport";
    my $CIDControlPreStateReport = "CIDControlPreStateReport";
    my $CIDControlStateReport = "CIDControlStateReport";
    my $CIDEndReport = "CIDEndReport";
    my $CIDReadReport1 = "CIDReadReport1";
    my $ALNControlPreStateReport = "ALNControlPreStateReport";
    my $ALNControlStateReport = "ALNControlStateReport";
    my $ALNEndReport = "ALNEndReport";
    my @decodeFile;
    my $eventFound = -1;
    my %cmdQueue;
    my $index = -1;
    my $timeStamp = "";
    my $secsCmd = "";
    my $transID = "";
    my $processTime = 0;

    foreach my $line (@_) {
        $index++;
        if($line =~ /^(S\d+F\d+) , Time=(.*?) , .*TRID=(\w+).*/i) {
            $secsCmd = $1;
            $timeStamp = "$2\t";
            $transID = $3;
            push(@decodeFile, $line);
        }elsif ($secsCmd eq "S6F11") {
            if ($line =~ /(B0\(4\): 00,00,00,01,).*/) {
                push(@decodeFile, $timeStamp, $line);
                $eventFound = 0;
            }elsif ($line =~ /(B0\(4\): (\w+,\w+,\w+,\w+,).*)/) {
                my $data = $1;
                if ($eventFound == 0) {
                    $eventFound = 1;
                    if (defined $Events{$2}) {
                        push(@decodeFile, $timeStamp, $1, "\t TN--> $Events{$2}\n");
                    }else {
                        push(@decodeFile, $timeStamp, $1, "\t TN--> $2\n");
                    }
                }else {
                    my $rptID = $2;

                    if (defined $TMReportID{$rptID}) {
                        my $rpt = $TMReportID{$rptID};
                        if ($rpt =~ /$GVControlPreStateReport/) {
                            $GVControlPreStateReport = "Y";
                        }elsif ($rpt =~ /$GVControlStateReport/) {
                            $GVControlStateReport = "Y";
                        }elsif ($rpt =~ /$GVEndStateReport/) {
                            $GVEndStateReport = "Y";
                        }elsif ($rpt =~ /$GVValvePreStateReport/) {
                            $GVValvePreStateReport = "Y";
                        }elsif ($rpt =~ /$GVValveStateReport/) {
                            $GVValveStateReport = "Y";
                        }elsif ($rpt =~ /$BERBPreStateReport/) {
                            $BERBPreStateReport = "Y";
                        }elsif ($rpt =~ /$BERBStateReport/) {
                            $BERBStateReport = "Y";
                        }elsif ($rpt =~ /$BERBEndReport/) {
                            $BERBEndReport = "Y";
                        }elsif ($rpt =~ /$FERBPreStateReport/) {
                            $FERBPreStateReport = "Y";
                        }elsif ($rpt =~ /$FERBStateReport/) {
                            $FERBStateReport = "Y";
                        }elsif ($rpt =~ /$FERBEndReport/) {
                            $FERBEndReport = "Y";
                        }elsif ($rpt =~ /$SSControlPreStateReport/) {
                            $SSControlPreStateReport = "Y";
                        }elsif ($rpt =~ /$SSControlStateReport/) {
                            $SSControlStateReport = "Y";
                        }elsif ($rpt =~ /$SSZPositionReport/) {
                            $SSZPositionReport = "Y";
                        }elsif ($rpt =~ /$SSEndStateReport/) {
                            $SSEndStateReport = "Y";
                        }elsif ($rpt =~ /$LPAccessModeReport/) {
                            $LPAccessModeReport = "Y";
                        }elsif ($rpt =~ /$LPTransferPreStateReport/) {
                            $LPTransferPreStateReport = "Y";
                        }elsif ($rpt =~ /$LPTransferStateReport/) {
                            $LPTransferStateReport = "Y";
                        }elsif ($rpt =~ /$LPTransferEndReport/) {
                            $LPTransferEndReport = "Y";
                        }elsif ($rpt =~ /$LPEndReport/) {
                            $LPEndReport = "Y";
                        }elsif ($rpt =~ /$LPFoupStateReport/) {
                            $LPFoupStateReport = "Y";
                        }elsif ($rpt =~ /$IOCLLCPressPreStateReport/) {
                            $IOCLLCPressPreStateReport = "Y";
                        }elsif ($rpt =~ /$IOCLLCPressStateReport/) {
                            $IOCLLCPressStateReport = "Y";
                        }elsif ($rpt =~ /$IOCLLCControlPreStateReport/) {
                            $IOCLLCControlPreStateReport = "Y";
                        }elsif ($rpt =~ /$IOCLLCControlStateReport/) {
                            $IOCLLCControlStateReport = "Y";
                        }elsif ($rpt =~ /$IOCLLCEndStateReport/) {
                            $IOCLLCEndStateReport = "Y";
                        }elsif ($rpt =~ /$TMBEWaferEndReport/) {
                            $TMBEWaferEndReport = "Y";
                        }elsif ($rpt =~ /$TMBEWaferPreStateReport/) {
                            $TMBEWaferPreStateReport = "Y";
                        }elsif ($rpt =~ /$TMBEWaferStateReport/) {
                            $TMBEWaferStateReport = "Y";
                        }elsif ($rpt =~ /$TMFEWaferPreStateReport/) {
                            $TMFEWaferPreStateReport = "Y";
                        }elsif ($rpt =~ /$TMFEWaferStateReport/) {
                            $TMFEWaferStateReport = "Y";
                        }elsif ($rpt =~ /$TMFEWaferEndReport/) {
                            $TMFEWaferEndReport = "Y";
                        }elsif ($rpt =~ /$RCControlPreStateReport/) {
                            $RCControlPreStateReport = "Y";
                        }elsif ($rpt =~ /$RCControlStateReport/) {
                            $RCControlStateReport = "Y";
                        }elsif ($rpt =~ /$RCStepReport/) {
                            $RCStepReport = "Y";
                        }elsif ($rpt =~ /$RCPreStepReport/) {
                            $RCPreStepReport = "Y";
                        }elsif ($rpt =~ /$RCNewStepReport/) {
                            $RCNewStepReport = "Y";
                        }elsif ($rpt =~ /$RCLogTimeReport/) {
                            $RCLogTimeReport = "Y";
                        }elsif ($rpt =~ /$RCModeReport/) {
                            $RCModeReport = "Y";
                        }elsif ($rpt =~ /$UIOPreStateReport/) {
                            $UIOPreStateReport = "Y";
                        }elsif ($rpt =~ /$UIOStateReport/) {
                            $UIOStateReport = "Y";
                        }elsif ($rpt =~ /$CIDControlPreStateReport/) {
                            $CIDControlPreStateReport = "Y";
                        }elsif ($rpt =~ /$CIDControlStateReport/) {
                            $CIDControlStateReport = "Y";
                        }elsif ($rpt =~ /$CIDEndReport/) {
                            $CIDEndReport = "Y";
                        }elsif ($rpt =~ /$CIDReadReport1/) {
                            $CIDReadReport1 = "Y";
                        }elsif ($rpt =~ /$ALNControlPreStateReport/) {
                            $ALNControlPreStateReport = "Y";
                        }elsif ($rpt =~ /$ALNControlStateReport/) {
                            $ALNControlStateReport = "Y";
                        }elsif ($rpt =~ /$ALNEndReport/) {
                            $ALNEndReport = "Y";
                        }

                        push(@decodeFile, $timeStamp, $data, "\t TN--> RptID: $rpt\n");
                    }else {
                        push(@decodeFile, $timeStamp, $data, "\t TN--> RptID: $rptID\n");
                    }
                }
            }else {
                if ($GVControlPreStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Pre:$GVCTRLSTATE{$2}\n");
                    $GVControlPreStateReport = "GVControlPreStateReport";
                }elsif ($GVControlStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Now:$GVCTRLSTATE{$2}\n");
                    $GVControlStateReport = "GVControlStateReport";
                }elsif ($GVEndStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> $WIOGVSTATE{int($2)}\n");
                    $GVEndStateReport = "GVEndStateReport";
                }elsif ($GVValvePreStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Pre:$WIOGVSTATE{int($2)}\n");
                    $GVValvePreStateReport = "GVValvePreStateReport";
                }elsif ($GVValveStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Now:$WIOGVSTATE{int($2)}\n");
                    $GVValveStateReport = "GVValveStateReport";
                }elsif ($BERBPreStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Pre:$RBTCTRLSTATE{int($2)}\n");
                    $BERBPreStateReport = "BERBPreStateReport";
                }elsif ($BERBStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Now:$RBTCTRLSTATE{int($2)}\n");
                    $BERBStateReport = "BERBStateReport";
                }elsif ($BERBEndReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> $BEANS{int($2)}\n");
                    $BERBEndReport = "BERBEndReport";
                }elsif ($FERBPreStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Pre:$RBTCTRLSTATE{int($2)}\n");
                    $FERBPreStateReport = "FERBPreStateReport";
                }elsif ($FERBStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Now:$RBTCTRLSTATE{int($2)}\n");
                    $FERBStateReport = "FERBStateReport";
                }elsif ($FERBEndReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> $FEANS{int($2)}\n");
                    $FERBEndReport = "FERBEndReport";
                }elsif ($SSControlPreStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Pre:$CTRLSTAT{int($2)}\n");
                    $SSControlPreStateReport = "SSControlPreStateReport";
                }elsif ($SSControlStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Now:$CTRLSTAT{int($2)}\n");
                    $SSControlStateReport = "SSControlStateReport";
                }elsif ($SSZPositionReport eq "Y" && $line =~ /(20\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> $SUSZPOS{int($2)}\n");
                    $SSZPositionReport = "SSZPositionReport";
                }elsif ($SSEndStateReport eq "Y" && $line =~ /(20\(1\): (\d+).*)/) {
                    #SSControlStateChanged Event. Diff Data format
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> $SSANS{int($2)}\n");
                    $SSEndStateReport = "SSEndStateReport";
                }elsif ($SSEndStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    #SSControlEndChanged Event. Diff Data format
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> $SSANS{int($2)}\n");
                    $SSEndStateReport = "SSEndStateReport";
                }elsif ($LPAccessModeReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> $LPACCMODE{int($2)}\n");
                    $LPAccessModeReport = "LPAccessMode";
                }elsif ($LPAccessModeReport eq "LPAccessMode" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> $AMHSSTATE{int($2)}\n");
                    $LPAccessModeReport = "LPAccessModeReport";
                }elsif ($LPTransferPreStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Pre:$LPTRANSSTAT{int($2)}\n");
                    $LPTransferPreStateReport = "LPTransferPreStateReport";
                }elsif ($LPTransferStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Now:$LPTRANSSTAT{int($2)}\n");
                    $LPTransferStateReport = "LPTransferStateReport";
                }elsif ($LPTransferEndReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> $LPCS{int($2)}\n");
                    $LPTransferEndReport = "LPTransferEndReport";
                }elsif ($LPEndReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> $LPANS{int($2)}\n");
                    $LPEndReport = "LPEndReport";
                }elsif ($LPFoupStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> $LPSTATE{$2}\n");
                    $LPFoupStateReport = "LPFoupStateReport";
                }elsif ($IOCLLCPressPreStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Pre:$WIOPRESSSTATE{int($2)}\n");
                    $IOCLLCPressPreStateReport = "LL:LLCPressPreStateReport";
                }elsif ($IOCLLCPressStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Now:$WIOPRESSSTATE{int($2)}\n");
                    $IOCLLCPressStateReport = "LL:LLCPressStateReport";
                }elsif ($IOCLLCControlPreStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Pre:$WIOCTRLSTATE{int($2)}\n");
                    $IOCLLCControlPreStateReport = "LL:LLCControlPreStateReport";
                }elsif ($IOCLLCControlStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Now:$WIOCTRLSTATE{int($2)}\n");
                    $IOCLLCControlStateReport = "LL:LLCControlStateReport";
                }elsif ($IOCLLCEndStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> $WIOANS{int($2)}\n");
                    $IOCLLCEndStateReport = "LL:LLCEndStateReport";
                }elsif ($TMBEWaferEndReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> $BEANS{int($2)}\n");
                    $TMBEWaferEndReport = "TMBEWaferEndReport";
                }elsif ($TMBEWaferPreStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Pre:$RBTCTRLSTATE{int($2)}\n");
                    $TMBEWaferPreStateReport = "TMBEWaferPreStateReport";
                }elsif ($TMBEWaferStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Now:$RBTCTRLSTATE{int($2)}\n");
                    $TMBEWaferStateReport = "TMBEWaferStateReport";
                }elsif ($TMFEWaferPreStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Pre:$RBTCTRLSTATE{int($2)}\n");
                    $TMFEWaferPreStateReport = "TMFEWaferPreStateReport";
                }elsif ($TMFEWaferStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Now:$RBTCTRLSTATE{int($2)}\n");
                    $TMFEWaferStateReport = "TMFEWaferStateReport";
                }elsif ($TMFEWaferEndReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> $FEANS{int($2)}\n");
                    $TMFEWaferEndReport = "TMFEWaferEndReport";
                }elsif ($RCControlPreStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Pre:$RCCTRLSTAT{int($2)}\n");
                    $RCControlPreStateReport = "RCControlPreStateReport";
                }elsif ($RCControlStateReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Now:$RCCTRLSTAT{int($2)}\n");
                    $RCControlStateReport = "RCControlStateReport";
                }elsif ($RCStepReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> RC", int($2),"\n");
                    $RCStepReport = "RCUnitDone";
                }elsif ($RCStepReport eq "RCUnitDone" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> StepNum:", int($2),"\n");
                    $RCStepReport = "StepNoDone";
                }elsif ($RCStepReport eq "StepNoDone" && $line =~ /(40: (\w+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t TN--> StepName: $2 \n");
                    $RCStepReport = "StepNameDone";
                }elsif ($RCStepReport eq "StepNameDone" && $line =~ /(A8\(2\): \w+,(\w+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t TN--> StepFlag: $STEPFLAG{$2} \n");
                    $RCStepReport = "RCStepReport";
                }elsif ($RCPreStepReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> StepNum:", int($2),"\n");
                    $RCPreStepReport = "StepNoDone";
                }elsif ($RCPreStepReport eq "StepNoDone" && $line =~ /(40: (\w+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t TN--> StepName: $2 \n");
                    $RCPreStepReport = "StepNameDone";
                }elsif ($RCPreStepReport eq "StepNameDone" && $line =~ /(40: (.*).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> StepTime: $2 \n");
                    $RCPreStepReport = "StepTimeDone";
                }elsif ($RCPreStepReport eq "StepTimeDone" && $line =~ /(A8\(2\): \w+,(\w+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t TN--> StepFlag: $STEPFLAG{$2} \n");
                    $RCPreStepReport = "RCPreStepReport";
                } elsif ($RCNewStepReport eq "Y" && $line =~ /(A4\(1\): (\d+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> StepNum:", int($2), "\n");
                    $RCNewStepReport = "StepNoDone";
                } elsif ($RCNewStepReport eq "StepNoDone" && $line =~ /(40: (\w+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t TN--> StepName: $2 \n");
                    $RCNewStepReport = "StepNameDone";
                } elsif ($RCNewStepReport eq "StepNameDone" && $line =~ /(40: (.*).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> StepTime: $2 \n");
                    $RCNewStepReport = "StepTimeDone";
                } elsif ($RCNewStepReport eq "StepTimeDone" && $line =~ /(A8\(2\): \w+,(\w+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t TN--> StepFlag: $STEPFLAG{$2} \n");
                    $RCNewStepReport = "RCNewStepReport";
                } elsif ($RCLogTimeReport eq "Y" && $line =~ /(40: (.*).*)/) {
                    my $procTime = $processTime == 0 ? "SetProcessTime:" : "ActualProcTime:";
                    $processTime = $processTime == 0 ? 1 : 0;
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> $procTime $2 \n");
                    $RCLogTimeReport = "RCLogTimeReport";
                } elsif ($RCModeReport eq "Y" && $line =~ /(A4\(1\): (\w+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> RCMODE(L): $RCMODE{$2}) \n");
                    $RCModeReport = "RCModeLeftDone";
                } elsif ($RCModeReport eq "RCModeLeftDone" && $line =~ /(A4\(1\): (\w+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> RCMODE(R): $RCMODE{$2} \n");
                    $RCModeReport = "RCModeReport";
                } elsif ($UIOPreStateReport eq "Y" && $line =~ /(A4\(1\): (\w+).*)/) {
                    my $state = hex($2) & 0x1 > 0 ? "ON" : "OFF";
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Signal Pre:$state\n");
                    $UIOPreStateReport = "SignalDone";
                } elsif ($UIOPreStateReport eq "SignalDone" && $line =~ /(A4\(1\): (\w+).*)/) {
                    my $state = hex($2) & 0x1 > 0 ? "ON" : "OFF";
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Buzzer Pre:$state\n");
                    $UIOPreStateReport = "UIOPreStateReport";
                } elsif ($UIOStateReport eq "Y" && $line =~ /(A4\(1\): (\w+).*)/) {
                    my $state = hex($2) & 0x1 > 0 ? "ON" : "OFF";
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Signal Now:$state\n");
                    $UIOStateReport = "SignalDone";
                } elsif ($UIOStateReport eq "SignalDone" && $line =~ /(A4\(1\): (\w+).*)/) {
                    my $state = hex($2) & 0x1 > 0 ? "ON" : "OFF";
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Buzzer Now:$state\n");
                    $UIOStateReport = "UIOStateReport";
                } elsif ($CIDControlPreStateReport eq "Y" && $line =~ /(A4\(1\): (\w+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> PRE-CarrierCTRLSTATE: $CTRLSTAT{int($2)}\n");
                    $CIDControlPreStateReport = "CIDControlPreStateReport";
                } elsif ($CIDControlStateReport eq "Y" && $line =~ /(A4\(1\): (\w+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> NOW-CarrierCTRLSTATE: $CTRLSTAT{int($2)}\n");
                    $CIDControlStateReport = "CIDControlStateReport";
                } elsif ($CIDEndReport eq "Y" && $line =~ /(A4\(1\): (\w+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Carrier END State: $CARRIERANS{int($2)} \n");
                    $CIDEndReport = "CIDEndReport";
                } elsif ($CIDReadReport1 eq "Y" && $line =~ /(40: (.*).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t TN--> CarrierID: $2 \n");
                    $CIDReadReport1 = "CIDReadReport1";
                } elsif ($ALNControlPreStateReport eq "Y" && $line =~ /(A4\(1\): (\w+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> PRE-CTRLSTATE: $CTRLSTAT{int($2)} \n");
                    $ALNControlPreStateReport = "ALNControlPreStateReport";
                } elsif ($ALNControlStateReport eq "Y" && $line =~ /(A4\(1\): (\w+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> NOW-CTRLSTATE: $CTRLSTAT{int($2)} \n");
                    $ALNControlStateReport = "ALNControlStateReport";
                } elsif ($ALNEndReport eq "Y" && $line =~ /(A4\(1\): (\w+).*)/) {
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> ENDSTATE: $2 \n");
                    $ALNEndReport = "ALNEndReport";
                } else {
                    push(@decodeFile, $timeStamp, $line);
                }
            }
        }elsif ($secsCmd eq "S2F49") {
            if ($line =~ /(40:\s+(\w+).*)/){
                my $cmdLine = $1;
                my $command = $2;
                my $cmdDetail = "Cmd: " . $command;
                if (defined $remoteCmd{$cmdLine}){
                    $command = $remoteCmd{$cmdLine}; #defined command in dictionary might be textually different
                    $cmdQueue{$transID} = $command; #only command
                    if($command =~/TM[F|B]ERBWafMove1/) {
                        my $arm = $_[$index + 6];
                        if ($arm =~ /.*\s0(\d).*/) {
                            $arm = $1;
                        }
                        my $getUnit = $_[$index + 10];
                        #say "getUnit: $getUnit";
                        my $from = "";
                        my $to = "";
                        if ($getUnit =~ /.*\s(\w+).*/) {
                            $from = $1;
                            if ($command =~ /TMFERBWafMove1/) {
                                if (defined $CMDMOVEFEUNIT{$from}) {
                                    $from = $CMDMOVEFEUNIT{$from};
                                }
                            }elsif ($command =~ /TMBERBWafMove1/) {
                                if (defined $CMDMOVEBEUNIT{$from}) {
                                    $from = $CMDMOVEBEUNIT{$from};
                                }
                            }
                        }
                        my $putUnit = $_[$index + 18];
                        if ($putUnit =~ /.*\s(\w+).*/) {
                            $to = $1;
                            if ($command =~ /TMFERBWafMove1/) {
                                if (defined $CMDMOVEFEUNIT{$to}) {
                                    $to = $CMDMOVEFEUNIT{$to};
                                }
                            }elsif ($command =~ /TMBERBWafMove1/) {
                                if (defined $CMDMOVEBEUNIT{$to}) {
                                    $to = $CMDMOVEBEUNIT{$to};
                                }
                            }
                        }
                        $cmdDetail = "TRID:$transID Cmd: " . $command . " ARM:" . $arm . " from:" . $from . " to:" . $to;
                    }elsif($command eq "RCModeChange"){
                        #say "command: $command";
                        my $modeInfo = $_[$index + 10];
                        #say "modeInfo: $modeInfo";
                        if($modeInfo =~ /(A4\(1\):\s+(\w+),)/) {
                            #say "2: $2";
                            $modeInfo = ($2 eq "01") ? "MAINTENANCE" : "NORMAL";
                        }
                        $cmdDetail = "Change RC to $modeInfo";
                    }else{
                        my $source = $_[$index-2];
                        $source =~ s/\R//g; #remove carriage return
                        #say "source: $source";
                        if($source =~ /^(40: ([T|P]M\d*:\w+).*)/){
                            $source = $2;
                            if($2 =~ /TM:IOC(\d)/){
                                $source = $IOCTOLL{$1};
                            }
                            $cmdDetail = "TRID:$transID Cmd: " . $source . " " . $command;
                        }
                        #say "cmdDetail: $cmdDetail";
                    }

                    push(@decodeFile, $timeStamp, $cmdLine, "\t TN--> $cmdDetail\n");
                }else{
                    push(@decodeFile, $timeStamp, $line);
                }
            }else{
                push(@decodeFile, $timeStamp, $line);
            }
        }elsif ($secsCmd eq "S2F50") {
            if (defined $cmdQueue{$transID} && $line =~ /(A4\(1\):\s+(\w+).*)/) {
                #say "found $transID";
                if(defined $S2F50{$2}){
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> TRID:$transID $cmdQueue{$transID} $S2F50{$2}\n"); #Passed
                }else{
                    push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Unkown Error: $2\n"); #Failed
                }
            }else{
                push(@decodeFile, $timeStamp, $line);
            }
        }elsif ($secsCmd eq "S5F1") {
            if ($line =~ /(A4\(1\): (\d+).*)/) {
                my $alarmState = $ALSTATE{$2};
                push(@decodeFile, $timeStamp, $1, "\t\t\t TN--> Alarm: $alarmState\n");
            }elsif ($line =~ /(B0\(\d\): (.*))/) {
                my $info = $1;
                my $alarmID = $2;
                $alarmID =~ s/,//g;
                push(@decodeFile, $timeStamp, $info, "\t TN--> AlarmID: $alarmID\n");
            }else{
                push(@decodeFile, $timeStamp, $line);
            }
        }else{
            push(@decodeFile, $timeStamp, $line);
        }
    }
    return @decodeFile;
}

# sub decodeSchedulerExceptionLogFile {
#     say "->decodeSchedulerExceptionLogFile()";
#     my @decodeFile = ();
#     foreach my $line (@_) {
#         if ($line =~ /^((\d+\/\d+\/\d+\s+\d+:\d+:\d+.\d+),.*?\s+Code=\$(\d+)\s+Type=\$(\d+)\s+Par1=\$(\d+)\s+Par2=\$*(\d+)\s+.*)/i) {
#             #say "$1"; say "Code=$3 Type=$4 Par1=$5 Par2=$6";
#             my $code = $3;
#             my $type = $4;
#             my $par1 = $5;
#             my $par2 = $6;
#             if ($code =~ /\d{2}/){
#                 $code = $CCODE{$code};
#             }else{
#                 $code = $CCODE{"0" . $code};
#             }
#             if($code eq "CAP_CTRL"){
#                 $type = $CAPTYPE{$4};
#                 $par1 = "RC" . int($5);
#                 if ($type eq "CAP_HOFF"){
#                     $par2 = $CAPP2HOFF{$6};
#                 }
#             }
#             say "Code=$code Typ=$type Para1=$par1 Para2=$par2";
#             push(@decodeFile, $1, "\t TN--> (Code=$code Type=$type Par1=$par1 Par2=$par2)\n");
#         }elsif ($line =~ /^((\d+\/\d+\/\d+\s+\d+:\d+:\d+.\d+),.*?\s+Code=(\d+),\s+Typ=(\d+),\s+Para1=(\d+),\s+Para2=(\d+).*)/i) {
#             #say "$1"; say "Code=$3 Type=$4 Par1=$5 Par2=$6";
#             my $code = $3;
#             my $type = $4;
#             my $par1 = $5;
#             my $par2 = $6;
#             if ($code =~ /\d{2}/){
#                 $code = $CCODE{$code};
#             }else{
#                 $code = $CCODE{"0" . $code};
#             }
#
#             if($code eq "SCHE_CMD_CANNOT_EXECUTE"){
#                 $type = $CAPTYPE{"0" . $4};
#                 $par1 = "RC" . $5;
#                 if ($type eq "CAP_HOFF"){
#                     $par2 = $CAPP2HOFF{"0" . $6};
#                 }
#             }
#             say "Code=$code Typ=$type Para1=$par1 Para2=$par2";
#             push(@decodeFile, $1, "\t TN--> (Code=$code Typ=$type Para1=$par1) Para2=$par2\n");
#         }else{
#             push(@decodeFile, $line);
#         }
#     }
#     return @decodeFile;
# }

sub decodeStatusCcuPol2LogFile {
    say "->decodeStatusCcuPol2LogFile()";
    my @decodeFile;
    foreach my $line (@_) {
        if ($line =~ /^((\d+\/\d+\/\d+\s+\d+:\d+:\d+.\d+)\s+InfoSetUpPOL\(\): MMISetUp := 1)/i){
            push(@decodeFile, $1, "\t TN--> (EI Start Button Clicked!)\n");
        }elsif ($line =~ /^((\d+\/\d+\/\d+\s+\d+:\d+:\d+.\d+)\s+EventWatch \( (\d+) \) : (.*))/i) {
            my $orig = $1;
            my $EventInfo = $4;
            #say "EventInfo: $EventInfo";
            if($3 == 70 && $EventInfo =~ /AGV Event, Port=(\d+) EventNo=(\d+) AGVEvent=(\d+)/i){
                push(@decodeFile, $orig, "\t\t\t\t TN--> (LP$PNUMB{$1}, $EVENTID{$2})\n");
            }elsif($3 == 50 && $EventInfo =~ /Carrier LotSeq Changed IDLE, CJNo=(\d+) Internal Port=(\d+)/i){
                push(@decodeFile, $orig, "\t TN--> (LP$PNUMB{$2}, CJNo.$1 IDLE)\n");
            }elsif($3 == 40 && $EventInfo =~ /Carrier LotSeq Changed END, CJNo=(\d+) Internal Port=(\d+)/i){
                push(@decodeFile, $orig, "\t\t TN--> (LP$PNUMB{$2}, CJNo.$1 END)\n");
            }elsif($3 == 30 && $EventInfo =~ /Carrier LotSeq Changed RUN, CJNo=(\d+) Internal Port=(\d+)/i){
                push(@decodeFile, $orig, "\t\t TN--> (LP$PNUMB{$2}, CJNo.$1) RUN\n");
            }elsif($3 == 10){
                if($EventInfo =~ /LPHostMode Changed, CommMode\(Now\)=4, CommMode\(Pre\)=0/i) {
                    push(@decodeFile, $orig, "\t TN--> (From Offline -> Online!)\n");
                }elsif($EventInfo =~ /LPHostMode Changed, CommMode\(Now\)=0, CommMode\(Pre\)=4/i) {
                    push(@decodeFile, $orig, "\t TN--> (From Online -> Offline!)\n");
                }elsif($EventInfo =~ /LPHostMode Changed, CommMode\(Now\)=4, CommMode\(Pre\)=1/i) {
                    push(@decodeFile, $orig, "\t TN--> (From Remote -> Local!)\n");
                }elsif($EventInfo =~ /LPHostMode Changed, CommMode\(Now\)=1, CommMode\(Pre\)=4/i) {
                    push(@decodeFile, $orig, "\t TN--> (From Local -> Remote!)\n");
                }elsif($EventInfo =~ /LPHostMode Changed, CommMode\(Now\)=0, CommMode\(Pre\)=1/i) {
                    push(@decodeFile, $orig, "\t TN--> (From Online -> Offline!)\n");
                }elsif($EventInfo =~ /LPHostMode Changed, CommMode\(Now\)=1, CommMode\(Pre\)=0/i) {
                    push(@decodeFile, $orig, "\t TN--> (From Offline -> Online!)\n");
                }
            }else {
                push(@decodeFile, $line);
            }
        }elsif ($line =~ /^((\d+\/\d+\/\d+\s+\d+:\d+:\d+.\d+)\s+ObjEventWatch \( (\d+) \) : (.*))/i) {
            my $orig = $1;
            my $portAssociateState = $4;
            #say "portAssociateState: $portAssociateState"; say $3;
            if($3 == 80 && $portAssociateState =~ /Port Associate State Event, Port=(\d+) State=(\d+) AGVEvent=(\d+) Wait=(\d+)/i){
                #say $1; say $2; say $3;
                push(@decodeFile, $orig, "\t TN--> (LP$PNUMB{$1}, PortState:$PASTATE{$2}), CarrierState:$CARRIERSTATE{$3}\n");
            }elsif($3 == 10 && $portAssociateState =~ /Port Associate State Change, Port=(\d+) State=(\d+)/i){
                push(@decodeFile, $orig, "\t\t\t TN--> (LP$PNUMB{$1}, PortState:$PASTATE{$2})\n");
            }else {
                push(@decodeFile, $line);
            }
        }elsif ($line =~ /^((\d+\/\d+\/\d+\s+\d+:\d+:\d+.\d+)\sLotSeq Log, Port=(\d+), Seq\(Now\)=(\d+), Seq\(Pre\)=(\d+), TransferState=(\d+), ReleaseInfo=(\d+))/i) {
            push(@decodeFile, $1, "\t TN--> (LP$PNUMB{$3}, Now:$LOTSEQ{$4}, Pre:$LOTSEQ{$5}, LPTSTATE:$LPTRANSSTAT{$6})\n");
        }elsif ($line =~ /^((\d+\/\d+\/\d+\s+\d+:\d+:\d+.\d+)\sPSLog OutReq, Port=(\d+), Seq\(Now\)=(\d+), Seq\(Pre\)=(\d+))/i) {
            push(@decodeFile, $1, "\t\t\t\t\t\t\t\t\t TN--> (LP$PNUMB{$3}, Now:$LOTSEQ{$4}, Pre:$LOTSEQ{$5})\n");
        }else{
            push(@decodeFile, $line);
        }
    }
    return @decodeFile;
}

sub decodeTcpLogFile {
    say "->decodeTcpLogFile()";
    my @decodeFile;
    foreach my $line (@_) {
        if ($line =~ /^((\d+\/\d+\/\d+\s+\d+:\d+:\d+.\d+)\s+Disconnect, ControlFlg=0x00, Mode=0x00, HSMSStatus=0x00, ProcNo=1)/i){
            push(@decodeFile, $1, "\t TN--> (EI Startup!)\n");
        }elsif ($line =~ /^((\d+\/\d+\/\d+\s+\d+:\d+:\d+.\d+)\s+Disconnect, ControlFlg=0x00, Mode=0x01, HSMSStatus=0x01, ProcNo=2)/i) {
            push(@decodeFile, $1, "\t TN--> (Board_Setup!)\n");
        }elsif ($line =~ /^((\d+\/\d+\/\d+\s+\d+:\d+:\d+.\d+)\s+Disconnect, ControlFlg=0x(\w+), Mode=0x01, HSMSStatus=0x(\w+), ProcNo=11)/i) {
            push(@decodeFile, $1, "\t TN--> (FormRelease. EI Shutdown!)\n");
        }elsif ($line =~ /^((\d+\/\d+\/\d+\s+\d+:\d+:\d+.\d+)\s+T5Timer Recover Restart, HSMSStatus=0x81, ControlFlg=0x11)/i){
            push(@decodeFile, $1, "\t TN--> (T5Timer Repetitive Checking HSMSStatus!)\n");
        }elsif ($line =~ /^((\d+\/\d+\/\d+\s+\d+:\d+:\d+.\d+)\s+T5Timer End Stop, HSMSStatus=0xA7)/i){
            push(@decodeFile, $1, "\t TN--> (HSMSStatus Comm Ready Now. Stop Repetitive Comm checking!)\n");
        }elsif ($line =~ /^((\d+\/\d+\/\d+\s+\d+:\d+:\d+.\d+)\s+Event ServerSocketClientDisconnect, HSMSStatus=0xA7)/i){
            push(@decodeFile, $1, "\t TN--> (HSMSStatus Comm Lost Now!)\n");
        }else{
            push(@decodeFile, $line);
        }
    }
    return @decodeFile;
}

sub decodeCapExceptionLogFile {
    say "->decodeCapExceptionLogFile()";
    my @decodeFile;
    foreach my $line (@_) {
        if ($line =~ /^((\d+\/\d+\/\d+\s+\d+:\d+:\d+.\d+),.*?\s+lRc:(\d+),.*)/i) {
            my $rc = int($3) + 1;
            #say $rc;
            push(@decodeFile, $1, "\t TN--> (RC$rc Cap Exception!)\n");
        }else{
            push(@decodeFile, $line);
        }
    }
    return @decodeFile;
}

sub decodeProcessLogFile {
    say "->decodeProcessLogFile()";
    my @decodeFile;
    my $curStep = "";
    my $newStep = "";
    foreach my $line (@_) {
        if ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,1:(\w+)->,\s+<Event'(RC\d)'StepData')/i) { #Primary message sending out
            $curStep = "Fr: $MODULE{$3}: $4";
            #say $curStep;
        }elsif ($line =~ /^(\s+-->Data>>\s+(Step=\d+).*)/i) { #Data of previous entry
            push(@decodeFile, $1, "\t\t\t\t\t\t\t\t\t\t TN--> ($curStep at $2 currently!)\n");
            $curStep = "";
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,1:(\w+)->,\s+<Event'(RC\d)'StepChange')/i) { #Primary message sending out
            $newStep = "Fr: $MODULE{$3}: $4";
            #say $newStep;
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,1:(\w+)->,\s+<Event'(RC\d)'RcpEnd')/i) { #Primary message sending out
            push(@decodeFile, $1, "\t\t\t TN--> ($4 Recipe Finished!)\n");
        }elsif ($line =~ /^(\s+-->Data>>\s+PreStepNo=(\d+)\s+.*?NewStepNo=(\d+).*)/i) { #Data of previous entry
            push(@decodeFile, $1, "\t\t\t TN--> ($newStep StepChange: $2 -> $3!)\n");
            $newStep = "";
        }else{
            push(@decodeFile, $line);
        }
    }
    return @decodeFile;
}

sub decodeOperationLogFile {
    say "->decodeOperationLogFile()";
    my @decodeFile;
    my $EIReady = 1;
    foreach my $line (@_) {
        if($line =~ /^(.*?NEW\s+DATE\[(\d+\/\d+\/\d+-\d+:\d+:\d+.\d+)\].*)/) { #Start up line
            #say $1; say "2: $2";
            $EIReady = 0;
            push(@decodeFile, $1, "\t TN--> (EI just Started !)\n");
        }elsif($line =~ /^(.*?\s+DATE\[(\d+\/\d+\/\d+-\d+:\d+:\d+.\d+)\].*)/) { #Start up line
            #say $1; say "2: $2";
            push(@decodeFile, $1, "\t TN--> (Continued Log File!)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+)\s+"OpeningForm","EmagencyCloseBtn","TButton","OnClick",".*?","Overview:Start",)/i) {
            #say $1; say "2: $2";
            $EIReady = 1;
            push(@decodeFile, $1, " TN--> (After START button clicked MMI appears!)\n");
        }elsif($line =~ /^((\d+\/\d+-\d+:\d+:\d+)\s+"OpeningForm",.*?,"Overview:ESC",)/i) {
            #say $1; say "2: $2";
            $EIReady = 1;
            push(@decodeFile, "****************************************************************************************\n");
            push(@decodeFile, $1, "\t TN--> (******* Skipped Start with ESC clicked *******)\n");
            push(@decodeFile, "****************************************************************************************\n");
        }elsif($line =~ /(.*?"OnClick",".*?","ScreenChange:Debug")/) { #Debug button clicked
            #say $1;
            push(@decodeFile, $1, "\t\t TN--> (***** DEBUG button clicked by Operator *****!)\n");
        }elsif($EIReady == 1){
            if ($line =~ /^((\d+\/\d+-\d+:\d+:\d+)\s+"(\w+)Form","(\w{3})\w*","TCheckBox","OnClick",".*?","(.*?)(\w+)",)/i) {
                push(@decodeFile, $1, " TN--> ($4: $6!)\n");
            }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+)\s+"RCMainteForm","(RC\d+)(\w+)Btn","(\w+)Button","OnClick",".*?","(.*?)(\w+)",)/i) {
                push(@decodeFile, $1, " TN--> ($3 $4 Clicked!)\n");
            }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+)\s+"(\w{3})\w*Form","(\w{3})\w*","(\w+)Button","OnClick",".*?","(.*?)(\w+)",)/i) {
                push(@decodeFile, $1, " TN--> ($7 Clicked!)\n");
            }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+)\s+"(\w{3})\w*[Dlg|Dialog]","(\w{3})\w*","(\w+)Button","OnClick",".*?","(.*?)(\w+)",)/i) {
                push(@decodeFile, $1, " TN--> (ACTION confirmed $3 popup $7)\n");
            }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+)\s+"(\w+)Form","(\w+)Btn","(\w+)Button","OnClick",".*?","ScreenChange:",)/i) {
                push(@decodeFile, $1, " TN--> ($4 Clicked!)\n");
            }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+)\s+"(\w+)Func","(\w+)Btn","(\w+)Button","OnClick",".*?","(.*?):(.*?)",)/i) {
                if ($3 eq "EqSetup" && $7 eq "Start"){
                    push(@decodeFile, $1, " TN--> ($3:$7 Clicked! **** Start Initializing Chambers! *****)\n");
                }else{
                    push(@decodeFile, $1, " TN--> ($3:$7 Clicked!)\n");
                }
            }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+)\s+"(\w+)Form","(\w+)","(\w+)","OnChange",".*?","(.*?):(.*?)",)/i) {
                push(@decodeFile, $1, " TN--> ($3:$7 Viewing!)\n");
            }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+)\s+"Status(\w+)Dlg","(\w+)Btn","TButton","OnClick",".*?","StsChDlg(\w+):(.*?)",)/i) {
                push(@decodeFile, $1, " TN--> ($4 for $5 setting Clicked!)\n");
            }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+)\s+"Status(\w+)Dlg","(\w+)","(\w+)","OnChange",".*?","StsChDlg(\w+):(.*?)",)/i) {
                push(@decodeFile, $1, " TN--> (Verifying $6 setting!)\n");
            }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+)\s+"Status(\w+)Dlg","DoSetComb1","TComboBox","OnClick",".*?","StsChDlg(\w+):(.*?)",)/i) {
                push(@decodeFile, $1, " TN--> (Making new $4 setting!)\n");
            }else{
                push(@decodeFile, $line);
            }
        }else{
            push(@decodeFile, $line);
        }
    }
    return @decodeFile;
}

sub decodeCAPLogFile {
    say "->decodeCAPLogFile()";
    my @decodeFile;
    my $rc = "";
    foreach my $line (@_) {
        if ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+),\(\w+'\w+'0(\d)'.*?,----,(1):(\@?\w+)->,(\w+))/i) { #Primary message sending out
            #say $1; say "2: $2"; say "3: $3"; say "4: $4";
            if ($6 eq "HandoffCAP"){
                $rc = "RC$3";
            }
            push(@decodeFile, $1, "\t\t\t TN--> ($DIRECT{$4} $MODULE{$5} $6 $rc)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,(2):(\w+)->,(\w+)'(\w+)'(\w+))/i) { #Secondary message receiving in
            #say $1; say "2: $2"; say "3: $3"; say "4: $4"; say "5: $5"; say "6: $6";
            push(@decodeFile, $1, "\t\t\t TN--> ($DIRECT{$3} $MODULE{$4} $6 on $7)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+),\(02'04'0(\d)'.*?,----,(2):(\w+)->,(\w+)'(\w+))/i) { #Secondary message receiving in
            #say $1; say "2: $2"; say "3: $3"; say "4: $4"; say "5: $5"; say "6: $6"; say "7: $7";
            if ($6 eq "StsChange" && $7 eq "Difference"){
                $rc = "RC$3";
            }
            push(@decodeFile, $1, "\t TN--> ($DIRECT{$4} $MODULE{$5} $rc state changed!)\n");
        }elsif($line =~ /^(\s+-->Mem>>\s+Mode:(\w+)'RC:(\w+)'Active:(\w+)'Folder:'Rcp:)/i) { #RC status data
            #say $1; say "2: $2"; say "3: $3"; say "4: $4";
            push(@decodeFile, $1, "\t TN--> (Mode:$2, $rc:$3)\n");
            $rc = "";
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+),\(51'(\d+)'(\d+)'(\d+)'.*?,----,(\d):(\@?\w+)->,\s+<Event'.*)/i) {
            #say $1; say "2: $2"; say "3: $3"; say "4: $4";
            my $event = $EVENTTYPE{$3};
            if ($EVENTTYPE{$3} eq "CAP"){
                $event = "CAP RC" . (int($4) + 1);
            }elsif ($EVENTTYPE{$3} eq "RCPSTEP"){
                #$event = "RCPSTEP RC" . int($4);
                $event = "RCPSTEP";
            }
            push(@decodeFile, $1, "\t\t TN--> ($DIRECT{$6} $MODULE{$7} $event)\n");
        }else{
            push(@decodeFile, $line);
        }
    }
    return @decodeFile;
}

sub decodeWAlarmLogFile {
    say "->decodeWAlarmLogFile()";
    my @decodeFile;
    my $eventType = "";
    foreach my $line (@_) {
        if($line =~ /^(\s+-->Data>>\s+Kind:(\w+)'ID:((\w{2})\w+)'Mod:.*)/i) { #alarm data
            #say $1; say "2: $2"; say "3: $3"; say "4: $4";
            my $state = $2;
            my $info = $3;
            my $module = $4;

            if($eventType eq "Alarm"){
                if($2 eq "Off"){
                    $state = "Clear";
                }elsif($2 eq "On"){
                    $state = "Set";
                }
                $info = $alarmInfo{$3};
                $module = $modCode{$4};
                push(@decodeFile, $1, "\t\t TN--> ($state $module $eventType: $info)\n");
            }else{
                push(@decodeFile, $line);
            }

            $eventType = "";
        }elsif($line =~ /^(\s+-->Data>>\s+Unit:(\d+)'Code:(\w+)'Step:(\d+)'Typ:(\w+)'TypeNo:(\d+)'ID:(\w+))/i) { #alarm data
            #say $1; say "2: $2"; say "3: $3"; say "4: $4"; say "5: $5"; say "6: $6"; say "7: $7";
            push(@decodeFile, $1, "\t TN--> (Unit:$ALUNIT{$2}, Code:$ALCODE{$3}, Step:$4, Typ:$5, TypNo:$6, ID: $7)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,(\d):(\@?\w+)->,\s+<Event'(\w+))/i) {
            #say $1; say "2: $2"; say "3: $3"; say "4: $4"; say "5: $5";
            $eventType = $5;
            push(@decodeFile, $1, "\t TN--> ($DIRECT{$3} $MODULE{$4} $eventType)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,(\d):(\@?\w+)->,(\w+)'(\w+)'(\w+)'(\d+))/i) {
            #say $1; say "2: $2"; say "3: $3"; say "4: $4";
            push(@decodeFile, $1, "\t TN--> ($DIRECT{$3} $MODULE{$4} $6 $7)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,(\d):(\w+)->,(\w+)'(\w+)')/i) {
            #say $1; say "2: $2"; say "3: $3"; say "4: $4"; say "5: $5";
            push(@decodeFile, $1, "\t TN--> ($DIRECT{$3} $MODULE{$4} to do $5 for $6)\n");
        }else{
            push(@decodeFile, $line);
        }
    }
    return @decodeFile;
}

sub decodeCCULogFile {
    say "->decodeCCULogFile()";
    my @decodeFile;
    foreach my $line (@_) {
        if($line =~ /^(\s+-->Data>>\s+CD:(\w+)'TY:(\w+)'P1:(\w+)'P2:(\w+)')/i) { #command data
            #say $1; say "CD: $2"; say "TY: $3"; say "P1: $4"; say "P2: $5";
            my $type = "";
            if ($2 eq "01") { #COD_SYS_DATA
                $type = $SYSDATATYPE{$3};
            }elsif ($2 eq "02") { #COD_STAT_CHNG
                $type = $STATTYPE{$3};
                if ($STATTYPE{$3} eq "STATUS_WAF_MAP"){
                    $type = $STATTYPE{$3} . " for CID" . int($4);
                }
            }elsif ($2 eq "11") { #COD_AUTO_CTRL
                $type = $AUTOTYPE{$3};
            }elsif ($2 eq "12") { #COD_MENTE_CTRL
                $type = $MAINTTYPE{$3};
            }elsif ($2 eq "13") { #COD_RC_CTRL
                #say $1; say "CD: $2"; say "TY: $3"; say "P1: $4"; say "P2: $5";
                if($RCTYPE{$3} eq "RC_SET_VIRTUAL_DI"){
                   $type = $RCTYPE{$3} . " RC" . int($4) . " DI." . hex($5);
                }elsif($RCTYPE{$3} eq "RC_LATCH_RELEASE"){
                    $type = $RCTYPE{$3} . " RC" . int($4);
                }elsif($RCTYPE{$3} eq "RC_MODE_CHG"){
                    $type = $RCTYPE{$3} . " RC" . int($4) . " -> " . $OPERATEMODE{$5};
                }else{
                    $type = $RCTYPE{$3} . " RC" . int($4) . " $RCSTARTP2{$5}";
                }
            }elsif ($2 eq "14"){ #COD_LL_CTRL
                my %loadlock = ("01" => "LLL", "03" => "RLL");
                $type = $LLTYPE{$3} . " for $loadlock{$4}";
            }elsif ($2 eq "15"){ #COD_WHC_CTRL
                $type = $WHCTYPE{$3};
            }elsif ($2 eq "16"){ #COD_LLRBT_CTRL
                $type = $LLRBTTYPE{$3};
            }elsif ($2 eq "17"){ #COD_GV_CTRL
                $type = $GVCTRLTYPE{$3} . " for GV" . int($4);
            }elsif ($2 eq "18"){ #COD_SP_CTRL
                $type = $SPTYPE{$3};
            }elsif ($2 eq "19"){ #COD_LPTYPE_CTRL
                $type = $LPTYPE{$3} . " for LP" . int($4);
            }elsif ($2 eq "1A"){ #COD_FERBT_CTRL
                $type = $FETYPE{$3} . " Arm" . int($4);
            }elsif ($2 eq "1B"){ #COD_BERBT_CTRL
                $type = $BETYPE{$3} . " Arm" . int($4);
            }elsif ($2 eq "1C"){ #COD_ALNR_CTRL
                $type = $ALNTYPE{$3};
            }elsif ($2 eq "1D"){ #COD_SS_CTRL
                $type = $SSTYPE{$3} . " for SS" . int($4);
            }elsif ($2 eq "1E"){ #COD_WL_CTRL
                $type = $WLTYPE{$3};
            }elsif ($2 eq "1F"){ #COD_RCBF_CTRL
                $type = $RCBFTYPE{$3};
            }elsif ($2 eq "20"){ #COD_CST_CTRL
                $type = $CSTYPE{$3};
            }elsif ($2 eq "21"){ #COD_UIO_CTRL
                $type = $UIOTYPE{$3};
                if($UIOTYPE{$3} eq "UIO_SIG_OFF" || $UIOTYPE{$3} eq "UIO_SIG_ON"){
                    $type = $UIOTYPE{$3} . " $UIOSIGP1{$4}";
                }
            }elsif ($2 eq "22"){ #COD_MON_CTRL
                $type = $MONTYPE{$3};
            }elsif ($2 eq "23"){ #COD_WID_CTRL
                $type = $WIDTYPE{$3};
            }elsif ($2 eq "24"){ #COD_CID_CTRL
                $type = $CIDTYPE{$3}. " for CID" . int($4);
            }elsif ($2 eq "26"){ #COD_EFEM_CTRL
                $type = $EFEMTYPE{$3};
            }elsif ($2 eq "35"){ #COD_PVC_CTRL
                $type = $PVCTYPE{$3};
            }elsif ($2 eq "41"){ #COD_SYSINFO_CTRL
                $type = $SYSTYPE{$3};
            }elsif ($2 eq "42"){ #COD_STATUS_REQ
                $type = $STATTYPE{$3};
            }elsif ($2 eq "51"){ #COD_EVENT_REP
                $type = $EVENTTYPE{$3};
            }elsif ($2 eq "61"){ #COD_MAINPC_CTRL
                $type = $MAINPCTYPE{$3};
            }elsif ($2 eq "62"){ #COD_TM_CTRL
                my $module = $4;
                if ($4 eq "00") {
                    $module = "TMC"
                }
                $type = $TMTYPE{$3} . " for $module";
            }elsif ($2 eq "63"){ #COD_PM_CTRL
                $type = $PMTYPE{$3}. " for RC" . int($4);
            }elsif ($2 eq "64"){ #COD_CAP_CTRL
                $type = $CAPTYPE{$3};
            }elsif ($2 eq "70"){ #COD_CCU_NOTIFY
                $type = $CCUTYPE{$3};
            }elsif ($2 eq "71"){ #COD_RCMD_CTRL
                $type = $RCMDTYPE{$3};
            }elsif ($2 eq "80"){ #COD_EDA_EVENT
                $type = $EDATYPE{$3};
            }elsif ($2 eq "90"){ #COD_COMP_NOTIFY
                $type = $TRENDTYPE{$3};
            }elsif ($2 eq "92"){ #COD_PMSTEP_CTRL
                $type = $PMSTEPTYPE{$3};
            }

            push(@decodeFile, $1, "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t TN--> ($CCODE{$2}, $type)\n");

        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,(\d):(\w+)->,(\w+'\w+')(\w+))/i) {
            #say $1; say "2: $2"; say "3: $3"; say "4: $4"; say "5: $5";
            push(@decodeFile, $1, "\t TN--> ($DIRECT{$3} $MODULE{$4} to do $5 for $6)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+),\(51'(\d+)'(\d+)'(\w+).*?,----,(\d):(\@?\w+)->,\s+<Event'.*)/i) {
            #say $1; say "2: $2"; say "3: $3"; say "4: $4";
            my $event = $EVENTTYPE{$3};
            if ($EVENTTYPE{$3} eq "CAP"){
                $event = "RC" . (int($4) + 1) . $EVENTTYPE{$3} . ":" . $CAPSTATE{$5};
            }elsif ($EVENTTYPE{$3} eq "RCPSTEP"){
                #$event = $EVENTTYPE{$3} . " RC" . int($4);
                $event = $EVENTTYPE{$3};
            }
            push(@decodeFile, $1, "\t\t TN--> ($DIRECT{$6} $MODULE{$7} $event)\n");
        }else{
            push(@decodeFile, $line);
        }
    }
    return @decodeFile;
}

sub decodeSchedulerLogFile {
    say "->decodeSchedulerLogFile()";
    my @decodeFile;
    my $eventType = "";
    foreach my $line (@_) {
        if ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,(\d):->(\@?\w+),\s+<Event'(\w+)')/i) {
            #say $1; say "2: $2"; say "3: $3"; say "4: $4"; say "5: $5";
            $eventType = $5;
            push(@decodeFile, $1, "\t TN--> ($DIRECT{$3} $MODULE{$4} $eventType)\n");
        }elsif($line =~ /^(\s+-->Data>>\s+Kind:(\w+)'ID:((\w{2})\w+)'Mod:.*)/i) { #alarm data
            #say $1; say "2: $2"; say "3: $3"; say "4: $4";
            my $state = $2;
            my $info = $3;
            my $module = $4;

            if($eventType eq "Alarm"){
                if($2 eq "Off"){
                    $state = "Clear";
                }elsif($2 eq "On"){
                    $state = "Set";
                }
                $info = $alarmInfo{$3};
                $module = $modCode{$4};
            }
            #push(@decodeFile, $line);
            push(@decodeFile, $1, "\t\t\t\t TN--> ($state $module $eventType: $info)\n");
            #$eventType = "";
        }elsif($line =~ /^(\s+-->Data>>\s+Unit:(\d+)'Code:(\w+)'Step:(\d+)'Typ:(\w+)'TypeNo:(\d+)'ID:(\w+_?\w+))/i) { #RC Alarm's data
            #say $1; say "Unit: $2"; say "Code: $3"; say "Step: $4"; say "Type: $5"; say "Type#: $6"; say "ID: $7";
            push(@decodeFile, $1, "\t\t TN--> (Alarm occurs at Step:", $4, " related to $5.$6:$7)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+),\(51'40'(\d+)'.*?,----,(\d):(\w+)->,\s+<Event'RcAlarm')/i) {
            #say $1; say "2: $2"; say "3: $3"; say "4: $4";
            #my $rc = "RC" . (int($3) + 1); $3 = 01: Alarm, $3 = 02: RcAlarm, $3 = 03: ScheAlarm, $3 = 04: CcuAlarm
            push(@decodeFile, $1, "\t\t TN--> ($DIRECT{$4} $MODULE{$5} RcAlarm)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,(\d):(\w+)->,\s+<Event'(\w+)'CtlChange'Now=(\d+)\s+Pre=(\d+))/i) {
            #say $1; say "2: $2"; say "3: $3"; say "4: $4"; say "5: $5"; say "6: $6";
            push(@decodeFile, $1, " TN--> ($DIRECT{$3} $MODULE{$4} with $5 Now:$RCCTRLSTAT{$6}, Pre:$RCCTRLSTAT{$7})\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+),\(1[A|B]'0E'(\d+)'.*?,----,(\d):->(\w+),([F|B]ERB)'(WFTrans)'(Arm))/i) { #Message either FE or BE
            #say $1; say "2: $2"; say "3: $3"; say "4: $4"; say "5: $5"; say "6: $6";
            my $arm = "Arm" . int($3);
            push(@decodeFile, $1, "\t\t TN--> ($DIRECT{$4} $MODULE{$5} $6 $arm $7)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,(\d):->(\w+),(\w+)'(\w+)'(\w+))/i) {
            #say $1; say "2: $2"; say "3: $3"; say "4: $4"; say "5: $5"; say "6: $6"; say "7: $7";
            my $component = $7;
            if ($component eq "LLC1" || $component eq "LLC2"){
                $component = "LLL";
            }elsif ($component eq "LLC3" || $component eq "LLC4"){
                $component = "RLL";
            }elsif ($6 eq "SysStat"){
                $component = $SYSSTAT{$7};
            }
            push(@decodeFile, $1, "\t\t TN--> ($DIRECT{$3} $MODULE{$4} $component for $6)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,(\d):(\w+)->,(\w+)'(\w+)'(\w+))/i) {
            #say $1; say "2: $2"; say "3: $3"; say "4: $4"; say "5: $5"; say "6: $6"; say "7: $7";
            my $component = $7;
            if ($component eq "LLC1" || $component eq "LLC2"){
                $component = "LLL";
            }elsif ($component eq "LLC3" || $component eq "LLC4"){
                $component = "RLL";
            }elsif ($6 eq "SysStat"){
                $component = $SYSSTAT{$7};
            }
            push(@decodeFile, $1, "\t\t TN--> ($DIRECT{$3} $MODULE{$4} $component for $6)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+),\(1[A|B]'0E'(\d+)'.*?,----,(\d):(\w+)->,([F|B]ERB)'(WFTrans)')/i) {
            #say $1; say "2: $2"; say "3: $3"; say "4: $4"; say "5: $5"; say "6: $6";
            my $arm = "Arm" . int($3);
            push(@decodeFile, $1, "\t\t TN--> ($DIRECT{$4} $MODULE{$5} $6 $arm $7)\n");
        }else{
            push(@decodeFile, $line);
        }
    }
    return @decodeFile;
}

sub decodeMMILogFile {
    say "->decodeMMILogFile()";
    my @decodeFile;
    my $rc = "";
    foreach my $line (@_) {
        if ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+),\(02'04'0(\d)'.*?,----,(\d):(\w+)->,StsChange'Difference)/i) { #RC status update
            $rc = "RC$3";
            push(@decodeFile, $1, "\t TN--> ($DIRECT{$4} $MODULE{$5} $rc State Changed!)\n");
        }elsif ($line =~ /^(\s+-->Mem>>\s+Mode:(\w+)'RC:(\w+)'.*)/i) { #RC status data
            push(@decodeFile, $1, "\t\t\t\t\t\t\t TN--> ($rc:$3 in Mode:$2)\n");
            $rc = "";
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,(\d):(\w+)->,MainPC'ExitAppli)/i) {
            push(@decodeFile, $1, "\t TN--> ($DIRECT{$3} $MODULE{$4} Eagle-I shutdown!!!)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,(\d):(\w+)->,RC'ChangeMTMode'(\w+)')/i) {
            push(@decodeFile, $1, "\t TN--> ($DIRECT{$3} $MODULE{$4} $5 in MAINTENANCE now.)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,(\d):(\w+)->,ExitMaintCAP'(\w+)'ExitMainte->Normal)/i) {
            push(@decodeFile, $1, "\t TN--> ($DIRECT{$3} $MODULE{$4} prepares $5 for NORMAL)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,(\d):(\w+)->,Auto'(\w+))/i) {
            push(@decodeFile, $1, "\t TN--> ($DIRECT{$3} $MODULE{$4} $5!!!)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,(\d):(\w+)->,Sus'(\w+)'(\w+))/i) { #Susceptor cmd sent
            push(@decodeFile, $1, "\t\t\t TN--> ($DIRECT{$3} $MODULE{$4} sends cmd $5 to $6)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,(\d):(\w+)->,CID'(\w+)'(\w+))/i) { #Carrier cmd sent
            push(@decodeFile, $1, "\t\t TN--> ($DIRECT{$3} $MODULE{$4} sends Carrier cmd $5 to $6)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,(\d):(\w+)->,LP'(\w+)'(\w+))/i) { #LoadPort cmd sent
            push(@decodeFile, $1, "\t\t\t\t TN--> ($DIRECT{$3} $MODULE{$4} sends LoadPort cmd $5 to $6)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,(\d):(\w+)->,Maintenance'(\w+))/i) { #Maintenance cmd sent
            push(@decodeFile, $1, "\t TN--> ($DIRECT{$3} $MODULE{$4} sends Maintenance cmd $5)\n");
        }else{
            push(@decodeFile, $line);
        }
    }
    return @decodeFile;
}

sub decodeMCIFLogFile {
    say "->decodeMCIFLogFile()";
    my @decodeFile;
    foreach my $line (@_) {
        if ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,1:->SC,\s+<Event'(LP\d)'(CtlChange)'Now=(\d+)\s+Pre=(\d+)\s+Fin=(\d+))/i) { #LoadPort CtlChange command
            #say $1; say "TimeStamp: $2"; say "LP: $3"; say "Cmd: $4"; say "Now: $LPCTLCHANGE{$5}"; say "Pre: $LPCTLCHANGE{$6}"; say "Fin: $FINSTAT{$7}";
            my $finish = "";
            if ($7 > 1){
                $finish = "$7:UNKNOWN";
            }else{
                $finish = $FINSTAT{$7};
            }
            push(@decodeFile, $1, " TN--> (Now: $LPCTLCHANGE{$5}, Pre: $LPCTLCHANGE{$6}, Fin: $finish)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,(\d):(\w+)->,RC'ChangeMTMode'(\w+)')/i) {
            push(@decodeFile, $1, "\t\t TN--> ($DIRECT{$3} $MODULE{$4} $5 in MAINTENANCE now.)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,1:->SC,\s+<Event'(LP\d)'(TrChange)'Now=(\d+)\s+Pre=(\d+)\s+Fin=(\d+))/i) { #LoadPort TrChange command
            #say "TimeStamp: $2"; say "LP: $3"; say "Cmd: $4"; say "Now: $LPTRCHANGE{$5}"; say "Pre: $LPTRCHANGE{$6}"; say "Fin: $FINSTAT{$7}"; say $1;
            push(@decodeFile, $1, " TN--> (Now: $LPTRCHANGE{$5}, Pre: $LPTRCHANGE{$6}, Fin: $FINSTAT{$7})\n");
        }elsif($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,1:->SC,\s+<Event'(LP\d)'(StsChange)'PortStatus=(\d+))/i) { #LoadPort StsChange command
            #say "TimeStamp: $2"; say "Module: $3"; say "Cmd: $4"; say "PortStatus: $LPCTLCHANGE{$5}"; say $1;
            push(@decodeFile, $1, " TN--> (PortStatus: $LPCTLCHANGE{$5})\n");
        }elsif($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,1:->SC,\s+<Event'(LP\d)'(AccChange)'AccessMode=(\d+))/i) { #LoadPort AccChange command
            #say "TimeStamp: $2"; say "Module: $3"; say "Cmd: $4"; say "AccessMode: $LPACCMODE{$5}"; say $1;
            push(@decodeFile, $1, " TN--> (PortStatus: $LPACCMODE{$5})\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,1:->SC,\s+<Event'(LL\d)'(CtlChange)'Now=(\d+)\s+Pre=(\d+)\s+Fin=(\d+))/i) { #LoadLock CtlChange command
            #say "TimeStamp: $2"; say "LP: $3"; say "Cmd: $4"; say "Now: $LLSTSCHANGE{$5}"; say "Pre: $LLSTSCHANGE{$6}"; say "Fin: $FINSTAT{$7}"; say $1;
            my $finish = "";
            if ($7 > 1){
                $finish = "$7:UNKNOWN";
            }else{
                $finish = $FINSTAT{$7};
            }
            push(@decodeFile, $1, " TN--> (Now: $LLSTSCHANGE{$5}, Pre: $LLSTSCHANGE{$6}, Fin: $finish)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,1:->SC,\s+<Event'(LL\d)'(StsChange)'Now=(\d+)\s+Pre=(\d+))/i) { #LoadLock StsChange command
            #say "TimeStamp: $2"; say "LP: $3"; say "Cmd: $4"; say "Now: $LLSTSCHANGE{$5}"; say "Pre: $LLSTSCHANGE{$6}"; say $1;
            push(@decodeFile, $1, " TN--> (Now: $LLSTSCHANGE{$5}, Pre: $LLSTSCHANGE{$6})\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,1:->SC,\s+<Event'(LL\d)'(Finish)'EndStatus=(\d+))/i) { #LoadLock Finish command
            #say "TimeStamp: $2"; say "Module: $3"; say "Cmd: $4"; say "EndStatus: $FINSTAT{$5}"; say $1;
            my $status = "";
            if ($5 > 1){
                $status = "$5:UNKNOWN";
            }else{
                $status = $FINSTAT{$5};
            }
            push(@decodeFile, $1, " TN--> (EndStatus: $status)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,1:->SC,\s+<Event'(GV\d)'(CtlChange)'Now=(\d+)\s+Pre=(\d+)\s+Fin=(\d+))/i) { #GV CtlChange command
            #say "TimeStamp: $2"; say "LP: $3"; say "Cmd: $4"; say "Now: $GVCTLCHANGE{$5}"; say "Pre: $GVCTLCHANGE{$6}"; say "Fin: $FINSTAT{$7}"; say $1;
            my $finish = "";
            if ($7 > 1){
                $finish = "$7:UNKNOWN";
            }else{
                $finish = $FINSTAT{$7};
            }
            push(@decodeFile, $1, " TN--> (Now: $GVCTLCHANGE{$5}, Pre: $GVCTLCHANGE{$6}, Fin: $finish)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,1:->SC,\s+<Event'(GV\d)'(StsChange)'Now=(\d+)\s+Pre=(\d+))/i) { #GV StsChange command
            #say $1; say "TimeStamp: $2"; say "LP: $3"; say "Cmd: $4"; say "Now: $GVSTSCHANGE{$5}"; say "Pre: $GVSTSCHANGE{$6}";
            push(@decodeFile, $1, " TN--> (Now: $GVSTSCHANGE{$5}, Pre: $GVSTSCHANGE{$6})\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,1:->SC,\s+<Event'(SS\d)'(CtlChange)'Now=(\d+)\s+Pre=(\d+)\s+Fin=(\d+)\s+Zpos=(\d+))/i) { #Susceptor CtlChange command
            #say $1; say "TimeStamp: $2"; say "LP: $3"; say "Cmd: $4"; say "Now: $SSCTLCHANGE{$5}"; say "Pre: $SSCTLCHANGE{$6}"; say "Fin: $FINSTAT{$7}"; say "ZPos: $SUSZPOS{$8}" ;
            my $finish = "";
            if ($7 > 1){
                $finish = "$7:UNKNOWN";
            }else{
                $finish = $FINSTAT{$7};
            }
            push(@decodeFile, $1, " TN--> (Now: $SSCTLCHANGE{$5}, Pre: $SSCTLCHANGE{$6}, Fin: $finish, ZPos: $SUSZPOS{$8})\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,1:->SC,\s+<Event'(SS\d)'(Finish)'EndStatus=(\d+))/i) { #LoadLock Finish command
            #say "TimeStamp: $2"; say "Module: $3"; say "Cmd: $4"; say "EndStatus: $FINSTAT{$5}"; say $1;
            my $status = "";
            if ($5 > 1){
                $status = "$5:UNKNOWN";
            }else{
                $status = $FINSTAT{$5};
            }
            push(@decodeFile, $1, " TN--> (EndStatus: $status)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,1:->SC,\s+<Event'([F|B]ERB)'(CtlChange)'Now=(\d+)\s+Pre=(\d+)\s+Fin=(\d+))/i) { #FERB or BERB command
            #say $1; say $7; say "TimeStamp: $2"; say "Module: $3"; say "Cmd: $4"; say "Now: $RBTCTRLSTATE{$5}"; say "Pre: $RBTCTRLSTATE{$6}"; #say "Fin: $FINSTAT{$7}";
            my $finish = "";
            if ($7 > 1){
                $finish = "$7:UNKNOWN";
            }else{
                $finish = $FINSTAT{$7};
            }
            push(@decodeFile, $1, " TN--> (Now: $RBTCTRLSTATE{$5}, Pre: $RBTCTRLSTATE{$6}, Fin: $finish)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,1:->SC,\s+<Event'([F|B]ERB)'(Finish)'EndStatus=(\d+))/i) { #FERB or BERB Finish command
            #say $1; say "TimeStamp: $2"; say "Module: $3"; say "Cmd: $4"; say "EndStatus: $FINSTAT{$5}";
            my $finish = "";
            if ($5 > 1){
                $finish = "$5:UNKNOWN";
            }else{
                $finish = $FINSTAT{$5};
            }
            push(@decodeFile, $1, " TN--> (EndStatus: $finish)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,1:->SC,\s+<Event'(TMC)'(Change[F|B]ERB)'Now=(\d+)\s+Pre=(\d+))/i) { #TMC module's FERB or BERB command
            #say "TimeStamp: $2"; say "Module: $3"; say "Cmd: $4"; say "Now: $CTRLSTAT{$5}"; say "Pre: $CTRLSTAT{$6}"; say $1;
            push(@decodeFile, $1, " TN--> (Now: $CTRLSTAT{$5}, Pre: $CTRLSTAT{$6})\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,1:->SC,\s+<Event'(TMC)'(Finish\w+)'EndStatus=(\d+))/i) { #TMC module's command
            #say $1; say "TimeStamp: $2"; say "Module: $3"; say "Cmd: $4"; say "EndStatus: $FINSTAT{$5}";
            my $status = "";
            if ($5 > 1){
                $status = "$5:UNKNOWN";
            }else{
                $status = $FINSTAT{$5};
            }
            push(@decodeFile, $1, " TN--> (EndStatus: $status)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+),\(02'04'(\d+)'.*?,----,(\d):(\@?\w+)->,StsChange(.*))/i) { #Acknowledge to requester
            #say $1; say "2: $2"; say "3: $3"; say "4: $4"; say "5: $5";
            my $rc = "RC" . int($3);
            push(@decodeFile, $1, "\t\t\t TN--> ($DIRECT{$4} $MODULE{$5} with status change to $rc)\n");
        }elsif ($line =~ /^(\s+-->Data>>\s+AO\(No,Data\):(.*))/i) { #Data acknowledged to requester
            push(@decodeFile, $1, "\t\t\t\t\t\t\t\t\t\t\t\t\t TN--> (", parsingAiAoData($2), ")\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,(\d):->(\w+),(\w+)'(\w+)'(\w+))/i) {
            #say $1; say "2: $2"; say "3: $3"; say "4: $4"; say "5: $5"; say "6: $6"; say "7: $7";
            my $component = $7;
            if ($component eq "LLC1" || $component eq "LLC2"){
                $component = "LLL";
            }elsif ($component eq "LLC3" || $component eq "LLC4"){
                $component = "RLL";
            }elsif ($6 eq "SysStat"){
                $component = $SYSSTAT{$7};
            }
            push(@decodeFile, $1, "\t\t\t\t\t TN--> ($DIRECT{$3} $MODULE{$4} $component for $6)\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,(\d):(\w+)->,(\w+)'(\w+)'(\w+))/i) {
            #say $1; say "2: $2"; say "3: $3"; say "4: $4"; say "5: $5"; say "6: $6"; say "7: $7";
            my $component = $7;
            if ($component eq "LLC1" || $component eq "LLC2"){
                $component = "LLL";
            }elsif ($component eq "LLC3" || $component eq "LLC4"){
                $component = "RLL";
            }elsif ($6 eq "SysStat"){
                $component = $SYSSTAT{$7};
            }
            push(@decodeFile, $1, "\t\t\t\t\t TN--> ($DIRECT{$3} $MODULE{$4} $component for $6)\n");

        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,(\d):(\@?\w+)->,(.*))/i) { #Acknowledge to requester
            #say $1; say "2: $2"; say "3: $3"; say "4: $4";
            push(@decodeFile, $1, "\t\t\t TN--> ($DIRECT{$3} $MODULE{$4})\n");
        }elsif ($line =~ /^((\d+\/\d+-\d+:\d+:\d+.\d+).*?,----,(\d):(\w+)->,\s+<Event'Command'\w+)/i) { #Secondary message receiving in
            #say $1; say "2: $2"; say "3: $3"; say "4: $4"; say "5: $5";
            push(@decodeFile, $1, "\t\t TN--> ($DIRECT{$3} $MODULE{$4})\n");
        }else{
            push(@decodeFile, $line);
        }
    }
    return @decodeFile;
}

sub parsingAiAoData {
    #say "->parsingAiAoData()";
    my @result;
    if($_[0] ne ""){
        my $input = $_[0];
        my @data = split(/[\[\]]/, $input);
        foreach my $item (@data){
            if ($item =~ /(\d+)'(\d+.?\d+?)/ || $item =~ /(\d+)'(\d+)/){
                push (@result , "AI$1=$2");
            }
        }
    }
    return join(', ',@result);
}

sub decodeAlignerLogFile {
    say "->decodeAlignerLogFile()";
    my @decodeFile;
    foreach my $line (@_) {
        if ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],>>>>>>>>ReqHandler\[REQ:(\d+)\/PRM:(.*?)\/ANS:(\d+)\]<<<<<<<<)/i) {
            #say "TimeStamp: $2"; say "REQ: $ALREQ{$3}"; say "P: $4"; say "ANS: $ALANS{$5}"; say $1;
            push(@decodeFile, $1, " TN--> (REQ:$ALREQ{$3}, P:$4, ANS: $ALANS{$5})\n");
        }else{
            push(@decodeFile, $line);
        }
    }
    return @decodeFile;
}

sub decodeLPLogFile {
    say "->decodeLPLogFile()";
    my @decodeFile;
    foreach my $line (@_) {
        if ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],>>>>ReqHandler<<<<.CTRL\[(\d+)\],REQ\[(\d+)\],P\[(\d)\],ABT\[(\d+)\],ANS\[(\d+)\])/i) { #RequestHandler message
            #say $1; say "2: $2"; say "3: $3"; say "4: $4"; say "5: $5"; say "6: $6"; say "7: $7";
            my $parameter = $5;
            if ($LPREQ{$3} eq "N2FLOW" && $5 == 0){
                $parameter = "STOP";
            }elsif ($LPREQ{$3} eq "N2FLOW" && $5 == 1){
                $parameter = "START";
            }elsif ($LPREQ{$3} eq "PRG_MODE" && $5 == 0){
                $parameter = "N2";
            }elsif ($LPREQ{$3} eq "PRG_MODE" && $5 == 1){
                $parameter = "NOZZLE";
            }elsif ($LPREQ{$3} eq "PRG_MODE" && $5 == 2){
                $parameter = "PRE-PROCESS";
            }elsif ($LPREQ{$3} eq "PRG_MODE" && $5 == 3){
                $parameter = "PRE-MAINT";
            }elsif ($LPREQ{$3} eq "PRG_MODE" && $5 == 4){
                $parameter = "PROCESS";
            }elsif ($LPREQ{$3} eq "PRG_MODE" && $5 == 5){
                $parameter = "POST-PROCESS";
            }elsif ($LPREQ{$3} eq "PRG_MODE" && $5 == 6){
                $parameter = "POST-MAINT";
            }elsif ($LPREQ{$3} eq "NOZZLE" && $5 == 0){
                $parameter = "DOWN";
            }elsif ($LPREQ{$3} eq "NOZZLE" && $5 == 1){
                $parameter = "UP";
            }
            push(@decodeFile, $1, "\t\t\t TN--> (CTRL:$LPCS{$3}, REQ:$LPREQ{$4}, P[$parameter], ABT:$LPABT{$6}, ANS:$LPANS{$7})\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],<<<<Send\[SET,LPLOD\])/i) {
            push(@decodeFile, $1, " TN--> (Set LP LOAD with LED ON)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],Recv:>>>>SOH:0E:00ACK:LPLOD;)/i) {
            push(@decodeFile, $1, "\t\t\t\t\t\t\t\t\t TN--> (LP LOAD LED ON Confirmed!)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],<<<<Send\[SET,LOLOD\])/i) {
            push(@decodeFile, $1, " TN--> (Set LP LOAD)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],<<<<Send\[SET:LPLOD\])/i) {
            push(@decodeFile, $1, "\t\t\t\t\t\t\t\t\t\t\t TN--> (Sent LP LOAD Command!)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],<<<<Send\[SET:LOLOD\])/i) {
            push(@decodeFile, $1, "\t\t\t\t\t\t\t\t\t\t\t TN--> (Sent LOT LOAD Command)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],Recv:>>>>SOH:0E:00ACK:LOLOD;)/i) {
            push(@decodeFile, $1, "\t\t\t\t\t\t\t\t\t TN--> (LP LOAD Confirmed!)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],<<<<Send\[SET,LPMSW\])/i) {
            push(@decodeFile, $1, " TN--> (Set LP Switch LED ON)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],Recv:>>>>SOH:0E:00ACK:LPMSW;)/i) {
            push(@decodeFile, $1, " TN--> (LP Switch LED ON Confirmed!)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],<<<<Send\[SET,LOMSW\])/i) {
            push(@decodeFile, $1, " TN--> (Set LP Switch)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],Recv:>>>>SOH:0E:00ACK:LOMSW;)/i) {
            push(@decodeFile, $1, " TN--> (LP Switch Confirmed!)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],<<<<Send\[SET:LPULD\])/i) {
            push(@decodeFile, $1, "\t\t\t\t\t\t\t\t\t\t\t TN--> (Sent LP UNLOAD Command!)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],<<<<Send\[SET:LOULD\])/i) {
            push(@decodeFile, $1, "\t\t\t\t\t\t\t\t\t\t\t TN--> (Sent LOT UNLOAD Command!)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],<<<<Send\[SET,LPULD\])/i) {
            push(@decodeFile, $1, " TN--> (Set LP UNLOAD LED ON)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],Recv:>>>>SOH:0E:00ACK:LPULD;)/i) {
            push(@decodeFile, $1, "\t\t\t\t\t\t\t\t\t TN--> (LP UNLOAD LED ON Confirmed!)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],<<<<Send\[SET,LOULD\])/i) {
            push(@decodeFile, $1, " TN--> (Set LP UNLOAD)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],Recv:>>>>SOH:0E:00ACK:LOULD;)/i) {
            push(@decodeFile, $1, "\t\t\t\t\t\t\t\t\t TN--> (LOT OUT UNLOAD Confirmed!)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],<<<<Send\[SET,BLMSW\])/i) {
            push(@decodeFile, $1, " TN--> (Set LP Switch LED BLINK)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],Recv:>>>>SOH:0E:00ACK:BLMSW;)/i) {
            push(@decodeFile, $1, " TN--> (LP Switch LED BLINK Confirmed!)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],,CHANGE_SERVICE,.*?,.*?,.*?,(\w+),.*,NONE,COMPLETED,AMHSErr)/i) {
            push(@decodeFile, $1, " TN--> ($3 now!)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],.*?,.*?,(\w+),[0|1],NONE,COMPLETED,AMHSErr)/i) {
            push(@decodeFile, $1, "\t\t TN--> ($3 COMPLETED now!)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],,,,,,TrnsBlkd_L)/i) {
            push(@decodeFile, $1, "\t\t\t\t\t\t\t\t\t\t\t\t TN--> (LOAD TransferBlock now!)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],,,,,,TrnsBlkd_U)/i) {
            push(@decodeFile, $1, "\t\t\t\t\t\t\t\t\t\t\t\t TN--> (UNLOAD TransferBlock now!)\n");
        }else{
            push(@decodeFile, $line);
        }
    }
    return @decodeFile;
}

sub decodePmSusLogFile {
    say "->decodePmSusLogFile()";
    my @decodeFile;
    my $susMoveStart = "";
    my $susMoveEnd = "";

    foreach my $line (@_) {
        #say "B::: $line";
        if ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],>>>>ReqHandler\(\)\s+\[Req:(\d+)\/Ans:(\d+)\/Abt:(\d+)\/Pls:(-?\d+),Mode:(\d+))/i) {
            #say "TimeStamp: $2"; say "REQ: $SSREQ{$3}"; say "ANS: $SSANS{$4}"; say "ABT: $SSABT{$5}"; say "PLS: $6"; say "Mode: $7"; say $1;
            %SSREQDATA = ("Mode" => $7, "Pls" => $6, "REQ" => $SSREQ{$3});
            if ($SSREQ{$3} eq "SUS_MOVE"){
                my $dateTime = $2;
                if ($dateTime =~ /^(\d+\/\d+)-(\d+:\d+:\d+).\d+/i) {
                    my $date = $1;
                    my $time = $2;
                    $susMoveStart = $date . " " . $time;
                    #say "Start: $susMoveStart";
                }
            }
            push(@decodeFile, $1, " TN--> (REQ:$SSREQ{$3}, ANS: $SSANS{$4}, ABT: $SSABT{$5}, PLS: $6, Mode: $7)\n");
        }elsif ($SSREQDATA{"REQ"} eq "SUS_INIT"){
            if ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],CreateRequest\s+--\s+req:\s+(\d+),\s+mode:\s+(\d+),\s+prm:\s+(-?\d+))/i) {
                my $mode = $4;
                # say "TimeStamp: $2"; say "req: $SSREQ{$3}"; say "mode: $mode"; say "prm: $5"; say $1;
                if($mode == 0){
                    $mode = "StdMove";
                }elsif($mode == 1){
                    $mode = "Accel/Decel";
                }
                push(@decodeFile, $1, "\t TN--> ($SSREQ{$3}, $mode, prm:$5)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],SusMtrInit\(\): STEP0->1)/i) {
                push(@decodeFile, $1, "\t\t\t\t\t\t\t TN--> Is SVOn?\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],Detect SVOn)/i) {
                push(@decodeFile, $1, "\t\t\t\t\t\t\t\t\t TN--> Yes SVOn!\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],SusMtrInit\(\): STEP1->10)/i) {
                push(@decodeFile, $1, "\t\t\t\t\t\t TN--> Will go to Step11\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],SusMtrInit\(\): STEP10->11)/i) {
                push(@decodeFile, $1, "\t\t\t\t\t\t TN--> If SVOn then will ReqMoveHome\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],SusMtrInit\(\): ReqMoveHome\(\):RET\[(\d)H\])/i) {
                my $status = ($3 == 0) ? "Successful" : "Fail";
                push(@decodeFile, $1, "\t\t\t TN--> SVOn and ReqMoveHome $status\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],SusMtrInit\(\): STEP11->12)/i) {
                push(@decodeFile, $1, "\t\t\t\t\t\t TN--> Is susceptor still busy moving?\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ChkDiStatus\(\)\[m_bSusInit,\s+PosState\s+from\s+(\d+)\s+to\s+(\d+)\s+\((\w+)\)\])/i) {
                # say "TimeStamp: $2"; say "PosState: $SUSZPOS{$3}"; say "To: $SUSZPOS{$4}"; say "Pos: $5"; say $1;
                push(@decodeFile, $1, " TN--> (From PosState:$3 -> NewState:$4 =~ $SUSZPOS{$3} -> $SUSZPOS{$4})\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],SusMtrInit\(\): STEP12->13)/i) {
                push(@decodeFile, $1, "\t\t\t\t\t\t TN--> Is still busy or any alarm ? Not goto Step14\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],SusMtrInit\(\): STEP13->14)/i) {
                push(@decodeFile, $1, "\t\t\t\t\t\t TN--> Is SVOn? Is alarm? Not goto step15\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],SusMtrInit\(\): STEP14->15)/i) {
                push(@decodeFile, $1, "\t\t\t\t\t\t TN--> Is Home now with Position < 120 pulses?\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],\t+ChkPosition\(0\)\[AxisEnc:[-](\d+)\])/i) {
                my $status = ($3 < 120) ? "Expected Postion" : "Unexpected Postion";
                push(@decodeFile, $1, "\t\t\t\t\t TN--> $3 is $status\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],SusMtrInit\(\): STEP15->100)/i) {
                push(@decodeFile, $1, "\t\t\t\t\t\t TN--> ", $SSREQDATA{"REQ"}, " Succepfully Completed!\n");
            }else{
                #say "I::: $line";
                push(@decodeFile, $line);
            }
        }elsif ($SSREQDATA{"REQ"} eq "SUS_MOVE"){
            if ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],Completed:Req\[(\d+)\],Ans\[(\d+)\],Err\[(\d+)\])/i) {
                #say $1; say "TimeStamp: $2"; say "REQ: $SSREQ{$3}"; say "ANS: $SSANS{$4}"; say "ERR: $5";
                if ($5 > 12){
                    $SSERR{$5} = $5;
                }
                push(@decodeFile, $1, "\t\t TN--> (REQ:$SSREQ{$3}, ANS: $SSANS{$4}, ERR: $SSERR{$5})\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ChkDiStatus\(\)\[m_bSusInit,\s+PosState\s+from\s+(\d+)\s+to\s+(\d+)\s+\((\w+)\)\])/i) {
                # say "TimeStamp: $2"; say "PosState: $SUSZPOS{$3}"; say "To: $SUSZPOS{$4}"; say "Pos: $5"; say $1;
                push(@decodeFile, $1, " TN--> (From PosState:$3 -> NewState:$4 =~ $SUSZPOS{$3} -> $SUSZPOS{$4})\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],EXEC\[Req:(\d+)\/Ans:(\d+)\/Err:(\d+)\]\[Mode:(\d+)\/Pulse:(-?\d+))/i) {
                # say "TimeStamp: $2"; say "REQ: $SSREQ{$3}"; say "ANS: $SSANS{$4}"; say "ERR: $5"; say "Mode: $6"; say "Pulse: $7"; say $1;
                if ($5 > 12){
                    $SSERR{$5} = $5;
                }
                push(@decodeFile, $1, " TN--> (REQ:$SSREQ{$3}, ANS: $SSANS{$4}, ERR: $SSERR{$5}, Mode:$6, Pulse:$7)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],Deceleration\[(-?\d+)~(-?\d+)\])/i) {
                # say "TimeStamp: $2"; say "pinover: $3"; say "pinunder: $4"; say $1;
                push(@decodeFile, $1, "\t\t\t\t TN--> (pinover: $3, pinunder: $4)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],CreateRequest\s+--\s+req:\s+(\d+),\s+mode:\s+(\d+),\s+prm:\s+(-?\d+))/i) {
                my $mode = $4;
                # say "TimeStamp: $2"; say "req: $SSREQ{$3}"; say "mode: $mode"; say "prm: $5"; say $1;
                if($mode == 0){
                    $mode = "StdMove";
                }elsif($mode == 1){
                    $mode = "Accel/Decel";
                }
                push(@decodeFile, $1, " TN--> ($SSREQ{$3}, $mode, prm:$5)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqPulse:(-?\d+)\s+\(NowPos:(-?\d+)\))/i) {
                # say "TimeStamp: $2"; say "ReqPulse: $3"; say "NowPos: $4"; say $1;
                if ($3 == $4){
                    push(@decodeFile, $1, "\t\t\t\t TN--> (ReqPulse = NowPos. Thus no moving needed!)\n");
                }elsif ($3 > $4){
                    push(@decodeFile, $1, "\t\t\t\t TN--> (ReqPulse > NowPos. Thus moving upward from $4 -> $3)\n");
                }elsif ($3 < $4){
                    push(@decodeFile, $1, "\t\t\t\t TN--> (ReqPulse < NowPos. Thus moving downward from $4 -> $3)\n");
                }else{
                    push(@decodeFile, $1);
                }
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],\s+ChkPosition\(-?(\d+)\)\[AxisEnc:-?(\d+)\])/i) {
                push(@decodeFile, $1, "\t\t TN--> (Expect: $3, Current: $4. Acceptable if diff < 120!)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],SusMtrMove:STEP0->60)/i) {
                push(@decodeFile, $1, "\t\t\t\t\t\t TN--> (No Moving Needed)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],SusMtrMove:STEP0->10)/i) {
                push(@decodeFile, $1, "\t\t\t\t\t\t TN--> (Will Move Down High to PinOver)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],SusMtrMove:STEP10->11)/i) {
                push(@decodeFile, $1, "\t\t\t\t\t\t TN--> (Moving Down High to PinOver)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],SusMtrMove:STEP11->21)/i) {
                push(@decodeFile, $1, "\t\t\t\t\t\t TN--> (Is Sus Motor busy? It should be busy working now!)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],SusMtrMove:STEP21->30)/i) {
                push(@decodeFile, $1, "\t\t\t\t\t\t TN--> (Moving Down High to Destination)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],SusMtrMove:STEP0->30)/i) {
                push(@decodeFile, $1, "\t\t\t\t\t\t TN--> (Will Move Down High to destination)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],SusMtrMove:STEP30->31)/i) {
                push(@decodeFile, $1, "\t\t\t\t\t\t TN--> (Is Motor busy? Expected Moved DOWN almost done!)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],SusMtrMove:STEP31->32)/i) {
                push(@decodeFile, $1, "\t\t\t\t\t\t TN--> (Is it at expected location now?)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+)-(\d+:\d+:\d+.\d+)\],SusMtrMove:STEP32->100)/i) {
                my $origLine = $1;
                my $date = $2;
                my $time = $3;
                $susMoveEnd = $date . " " . $time;
                my $susMoveTime = "";
                #say "$susMoveStart -> $susMoveEnd";
                if ($susMoveStart ne "" && $susMoveEnd ne "") {
                    #say "Start: $susMoveStart";
                    #say "End: $susMoveEnd";
                    $susMoveTime = str2time($susMoveEnd) - str2time($susMoveStart);
                    #say "U Time: $susMoveTime";
                    $susMoveStart = "";
                    $susMoveEnd = "";
                    #say "D Time: $susMoveTime";
                    $susMoveStart = "";
                    push(@decodeFile, $origLine, "\t\t\t\t\t\t TN--> (", $SSREQDATA{"REQ"}, " DOWN completed in $susMoveTime secs)\n");
                }else{
                    push(@decodeFile, $origLine, "\t\t\t\t\t\t TN--> (", $SSREQDATA{"REQ"}, " DOWN completed!)\n");
                }
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],SusMtrMove:STEP0->40)/i) {
                push(@decodeFile, $1, "\t\t\t\t\t\t TN--> (Will Move Up High to PinUnder)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],SusMtrMove:STEP40->41)/i) {
                push(@decodeFile, $1, "\t\t\t\t\t\t TN--> (Moving Up to PinUnder)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],SusMtrMove:STEP41->51)/i) {
                push(@decodeFile, $1, "\t\t\t\t\t\t TN--> (Is Sus Motor busy? It should be busy working now!)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],SusMtrMove:STEP51->61)/i) {
                push(@decodeFile, $1, "\t\t\t\t\t\t TN--> (Is Motor busy? Expected Moved UP almost done!)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],SusMtrMove:STEP61->62)/i) {
                push(@decodeFile, $1, "\t\t\t\t\t\t TN--> (Is it at expected location now?)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+)-(\d+:\d+:\d+.\d+)\],SusMtrMove:STEP62->100)/i) {
                my $origLine = $1;
                my $date = $2;
                my $time = $3;
                $susMoveEnd = $date . " " . $time;
                my $susMoveTime = "";
                #say "$susMoveStart -> $susMoveEnd";
                if ($susMoveStart ne "" && $susMoveEnd ne "") {
                    #say "Start: $susMoveStart";
                    #say "End: $susMoveEnd";
                    $susMoveTime = str2time($susMoveEnd) - str2time($susMoveStart);
                    #say "U Time: $susMoveTime";
                    $susMoveStart = "";
                    $susMoveEnd = "";
                    push(@decodeFile, $origLine, "\t\t\t\t\t\t TN--> (", $SSREQDATA{"REQ"}, " UP completed in $susMoveTime secs)\n");
                }else{
                    push(@decodeFile, $origLine, "\t\t\t\t\t\t TN--> (", $SSREQDATA{"REQ"}, " UP completed!)\n");
                }
            }else{
                #say "I::: $line";
                push(@decodeFile, $line);
            }
        }else{
            #say "O::: $line";
            push(@decodeFile, $line);
        }
    }
    return @decodeFile;
}

sub decodeFERBLogFile {
    say "->decodeFERBLogFile()";
    my @decodeFile;
    my %FECMD;
    foreach my $line (@_) {
        if ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],========ReqHandler========\[REQ:(\d+)\/ANS:(\d+)\/PRM:\((\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+)\)\]<<<<<<<<)/i) {
            %FECMD = (-1 => ""); #initialize it
            #say "TimeStamp: $2"; say "REQ: $FEREQ{$3}"; say "ANS: $FEANS{$4}"; say "PRM: $5, $6, $7, $8, $9, $10, $11, $12"; say $1;
            if ( $3 >= 0 && $3 < 15){
                if($FEREQ{$3} eq "AlarmReset") {
                    %FEREQDATA = (REQ => $FEREQ{$3});
                    push(@decodeFile, $1, " TN--> (REQ:$FEREQ{$3})\n");
                }elsif($FEREQ{$3} eq "HomePos"){ #bP[0]:Arm/bP[1]:Unit/bP[2]:Slot/:bP[3]:0:GET/1:PUT
                    my $cmd = ($8 == 0) ? "GET" : "PUT";
                    %FEREQDATA = (Arm => $5, Unit => $FEUNIT{$6}, Slot => $7, Cmd => $cmd, REQ => $FEREQ{$3});
                    push(@decodeFile, $1, " TN--> (REQ:$FEREQ{$3}, ANS: $FEANS{$4}, PRM:(PRM: Arm$5, Unit:$FEUNIT{$6}, Slot:$7, Cmd:$cmd))\n");
                }elsif($FEREQ{$3} eq "AxisU"){ #bP[0]:Arm/bP[1]:Axis(全軸のみ)/bP[2]:Unit/bP[3]:Slot/bP[4]:Location
                    %FEREQDATA = (Arm => $5, Axis => $FEAXIS{$6}, Unit => $FEUNIT{$7}, Slot => $8, Location => $9, REQ => $FEREQ{$3});
                    push(@decodeFile, $1, " TN--> (REQ:$FEREQ{$3}, ANS: $FEANS{$4}, PRM:(PRM: Arm$5, Axis:$FEAXIS{$6}, Unit:$FEUNIT{$7}, Slot:$8, Location:$FELOC{$9}))\n");
                }else {
                    %FEREQDATA = (Arm => $5, From => $FEUNIT{$6}, FSlot => $7, To => $FEUNIT{$8}, TSlot => $9, WafBrank => $FEUNIT{$10}, ShfCorr => $FEUNIT{$11}, NA => $12, REQ => $FEREQ{$3});
                    push(@decodeFile, $1, " TN--> (REQ:$FEREQ{$3}, ANS: $FEANS{$4}, PRM:(PRM: Arm$5, From:$FEUNIT{$6}, FSlot:$7, To:$FEUNIT{$8}, TSlot:$9, WafBrank:$10, ShfCorr:$11, NA:$12))\n");
                }
            }else{
                say "Unknown REQ: $3";
            }
        }elsif($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],.*?Step\[(\d+)\])/i) {
            push(@decodeFile, $1, " TN--> (At Step $3 now!)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],<<<SEND<<<\[<(\d+),(\w+),(R\d+),H(\d+),P(\d+),(\d+))/i) {   ##### SEND cmd ####
            #say "1: $1, 2: $2, 3: $3, 4: $4, 5: $5, 6: $6, 7: $7, 8: $8 ";
            $FECMD{$3} = $4;
            #push(@decodeFile, $1, " TN--> (", $FEREQDATA{"REQ"}, " FERB Arm$6 $4 Slot$8 $FEUNIT{$7})\n");
            push(@decodeFile, $1, "\t\t\t\t TN--> (", $FEREQDATA{"REQ"}, " FERB Arm$6 $4 Slot$8)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],<<<SEND<<<\[<(\d+),(\w+),(R\d+),H(\d+))/i) {   ##### SEND AxisU cmd ####
            #say "1: $1, 2: $2, 3: $3, 4: $4, 5: $5, 6: $6";
            $FECMD{$3} = $4;
            #push(@decodeFile, $1, " TN--> (", $FEREQDATA{"REQ"}, " FERB Arm$6 $4 Slot$8 $FEUNIT{$7})\n");
            push(@decodeFile, $1, "\t\t\t\t TN--> (", $FEREQDATA{"REQ"}, " FERB Arm$6 $4)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],<<<SEND<<<\[<(\d+),(\w+),(R\d+))/i) {   ##### SEND SERV cmd ####
            #say "1: $1, 2: $2, 3: $3, 4: $4, 5: $5, 6: $6";
            $FECMD{$3} = $4;
            #push(@decodeFile, $1, " TN--> (", $FEREQDATA{"REQ"}, " FERB Arm$6 $4 Slot$8 $FEUNIT{$7})\n");
            push(@decodeFile, $1, "\t\t\t\t TN--> (", $FEREQDATA{"REQ"}, " $4)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],>>>RECV>>>\[<(\d+),(\w+)(.*>)(\w+))/i) {   ##### RECEIVE Response ####
            #say $1; say "3:$3, 4:$4, 5:$5";
            my $info = "";
            if (defined($FECMD{$3})){
                if($4 eq "Ack") {
                    $info = "Got Acknowledged cmd $FECMD{$3}";
                }elsif($4 eq "Success") {
                    $info = "Successfully executed cmd $FECMD{$3}";
                }else{
                    $info = "NA";
                }
            }
            push(@decodeFile, $1, "\t\t\t\t\t\t TN--> ($info)\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ID\[(\d+)\},Cmd\[(\w+),(.*),Res\[(.*))/i) {   ##### cmd status update ####
            my $info = "";
            if (defined($FECMD{$3})){
                my $cmd = $FECMD{$3};
                #my $status = $6;
                #say "Status:$status";
                if($6 =~/Success/gi) {
                    $info = "Confirmed successfully executed cmd $cmd";
                }else{
                    $info = "No response yet!";
                }
            }
            push(@decodeFile, $1, " TN--> $info\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],Ctrl:\[(\d+):(\w+)\],.*,Req:\[(\d+):(\w+)\],.*,Step\[(\d+)\])/i) {
            #say "1: $1, 2: $2, 3: $3, 4: $4, 5: $5, 6: $6, 7: $7";
            push(@decodeFile, $1, " TN--> (Step $7 of $6: $4)\n");
        #}elsif ($FEREQDATA{"REQ"} eq "AxisU"){
        }elsif ($FEREQDATA{"REQ"} eq "WafMove1"){
            if($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafMoveProc\(\)\s+STEP\[0->21\])/i) {
                push(@decodeFile, $1, "\t\t\t\t TN--> (Checking whether Transfer request being aborted ?)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafMoveProc\(\)\s+STEP\[0->22\])/i) {
                push(@decodeFile, $1, "\t\t\t\t TN--> (No abort so far, any interlock ?)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafMoveProc\(\)\s+STEP\[21->22\])/i) {
                push(@decodeFile, $1, "\t\t\t\t TN--> (No abort so far, any interlock ?)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafMoveProc\(\)\s+STEP\[22->23\])/i) {
                push(@decodeFile, $1, "\t\t\t\t TN--> (No interlock, No error. Continue to next step!)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafMoveProc\(\)\s+STEP\[23->24\])/i) {
                my $info = "";
                if ($FEREQDATA{"To"} eq "LLL" || $FEREQDATA{"To"} eq "RLL"){
                    $info = "(It is move wafer to LL command. Verify whether any timing concern! )";
                }else{
                    $info = "(Nothing ! Will proceed to step 25!)";
                }
                push(@decodeFile, $1, "\t\t\t\t TN--> $info\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafMoveProc\(\)\s+STEP\[24->25\])/i) {
                push(@decodeFile, $1, "\t\t\t\t TN--> (Verify LL sensor if needed. Otherwise, move to step 26!)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafMoveProc\(\)\s+STEP\[25->26\])/i) {
                push(@decodeFile, $1, "\t\t\t\t TN--> (If no concern with clamp sensor will move to step 30!)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafMoveProc\(\)\s+STEP\[26->30\])/i) {
                push(@decodeFile, $1, "\t\t\t\t TN--> (If no interlock will move to step 40!)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafMoveProc\(\)\s+STEP\[0->30\])/i) {
                push(@decodeFile, $1, "\t\t\t\t TN--> (Checking whether Transfer request should be interlocked ?)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafMoveProc\(\)\s+STEP\[30->40\])/i) {
                push(@decodeFile, $1, "\t\t\t\t TN--> (No Interlock happened. Now checking Destination)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafMoveProc\(\)\s+STEP\[40->41\])/i) {
                my $info = "";
                if($FEREQDATA{"To"} ne "FERB"){
                    if ($FEREQDATA{"To"} eq "LLL" || $FEREQDATA{"To"} eq "RLL"){
                        $info = "(Move wafer to LL command sent w/o issue!)";
                    }else{
                        $info = "(Nothing ! Will proceed to step 42)";
                    }
                }else{
                    $info = "(Nothing ! Will proceed to step 50)";
                }
                push(@decodeFile, $1, "\t\t\t\t TN--> $info\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafMoveProc\(\)\s+STEP\[41->42\])/i) {
                push(@decodeFile, $1, "\t\t\t\t TN--> (Cmd sent!)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafMoveProc\(\)\s+STEP\[40->42\])/i) {
                push(@decodeFile, $1, "\t\t\t\t TN--> (Destination is not LoadLock. Is destination available to receive a PUT?)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafMoveProc\(\)\s+STEP\[40->50\])/i) {
                push(@decodeFile, $1, "\t\t\t\t TN--> (So far, so good. Will finalize this movement!)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafMoveProc\(\)\s+STEP\[42->43\])/i) {
                push(@decodeFile, $1, "\t\t\t\t TN--> (Any error to perform command?)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafMoveProc\(\)\s+STEP\[43->44\])/i) {
                push(@decodeFile, $1, "\t\t\t\t TN--> (Is Destination a LoadLock?)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafMoveProc\(\)\s+STEP\[44->45\])/i) {
                push(@decodeFile, $1, "\t\t\t\t TN--> (Verify LL sensor if needed. Otherwise, move to step 50!)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafMoveProc\(\)\s+STEP\[45->50\])/i) {
                push(@decodeFile, $1, "\t\t\t\t TN--> (Any interlock after wafer transferred?)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafMoveProc\(\)\s+STEP\[50->100\])/i) {
                push(@decodeFile, $1, "\t\t\t\t TN--> (", $FEREQDATA{"REQ"}," successful ", $FEREQDATA{"From"}, " -> ", $FEREQDATA{"To"}, " )\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],--------ReqHandler\(\)\s+CTRL:(\d+),REQ:(\d+),ANS:(\d+),ABT:(\d+)--------)/i) {
                #say "TimeStamp: $2"; say "CTRL: $FRCTRLSTATE{$3} REQ: $FEREQ{$4}"; say "ANS: $FEANS{$5}"; say "ABT: $FEABT{$6}"; say $1;
                push(@decodeFile, $1, " TN--> (CTRL: $RBTCTRLSTATE{$3}, REQ: $FEREQ{$4}, ANS: $FEANS{$5}, ABT: $FEABT{$6})\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafPutProc\(\)\s+STEP\[0->3\])/i) {   ##### Start Load REQ ####
                push(@decodeFile, $1, "\t\t\t\t TN--> (Check interlock, check LL sensor if needed. If fine goes to next step !)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafPutProc\(\)\s+STEP\[3->4\])/i) {
                push(@decodeFile, $1, "\t\t\t\t TN--> (Check error. If fine goes to next step !)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafPutProc\(\)\s+STEP\[4->5\])/i) {
                push(@decodeFile, $1, "\t\t\t\t TN--> (Check abort. If fine goes to next step !)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafPutProc\(\)\s+STEP\[5->6\])/i) {
                push(@decodeFile, $1, " TN--> (Check LL status if needed then making final decision !)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafPutProc\(\)\s+STEP\[6->100\])/i) {
                push(@decodeFile, $1, " TN--> (", $FEREQDATA{"REQ"}," successful from ", $FEREQDATA{"From"}, " -> ", $FEREQDATA{"To"}, " )\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafGetProc\(\)\s+STEP\[0->1\])/i) {   ##### Start Unload REQ ####
                push(@decodeFile, $1, "\t\t\t\t TN--> (Check interlock, check LL sensor if needed. If fine goes to next step !)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafGetProc\(\)\s+STEP\[1->2\])/i) {
                push(@decodeFile, $1, "\t\t\t\t TN--> (Check error. If fine goes to next step !)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafGetProc\(\)\s+STEP\[2->3\])/i) {
                push(@decodeFile, $1, "\t\t\t\t TN--> (Check abort. If fine goes to next step !)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafGetProc\(\)\s+STEP\[3->4\])/i) {
                push(@decodeFile, $1, "\t\t\t\t TN--> (Check interlock, check LL sensor if needed. If fine goes to next step !)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafPutProc\(\)\s+STEP\[4->5\])/i) {
                push(@decodeFile, $1, "\t\t\t\t TN--> (Check Clamp sensor if needed then making final decision !)\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqWafGetProc\(\)\s+STEP\[5->100\])/i) {
                push(@decodeFile, $1, "\t\t\t\t TN--> (", $FEREQDATA{"REQ"}," successful from ", $FEREQDATA{"From"}, " -> ", $FEREQDATA{"To"}, " )\n");
            }else{
                push(@decodeFile, $line);
            }
        }else{
            push(@decodeFile, $line);
        }
    }
    return @decodeFile;
}

sub decodeBERBLogFile{
    say "->decodeBERBLogFile()";
    my @decodeFile;
    foreach my $line (@_) {
        if ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],>>>>ReqHandler<<<< CTRL\[(\d+)\]\s+REQ\[(\d+)\]\s+P\[(\d+)\/(\d+)\/(\d+)\/(\d+)\/(\d+)\/(\d+)\]\s+ABT\[(\d+)\]\s+ANS\[(\d+)\]\s+ERR\[(\d+)\])/i) {
            # say "TimeStamp: $2"; say "CTRL: $BRCTRLSTATE{$3}"; say "REQ: $BEREQ{$4}";
            # say "bp.0: Arm$5, pb.1: From$BEUNIT{$6}, bp.2: FromSlot$7, pb.3: To$BEUNIT{$8}, pb.4: ToSlot$9, bp.5: WafBrank$10";
            # say "Abort: $11"; say "ANS: $BEANS{$12}"; say "ERR: $13"; say $1;
            #say "TimeStamp: $2"; say "REQ: $BEREQ{$4}"; say "PRM: $5, $6, $7, $8, $9, $10, $11, $12"; say $1;
            if ( $4 >= 0 && $4 < 22){
                if($BEREQ{$4} eq "AlarmReset") {
                    %BEREQDATA = (REQ => $BEREQ{$4});
                    push(@decodeFile, $1, " TN--> ReqHandler(CTRL:$RBTCTRLSTATE{$3}, REQ:$BEREQ{$4})\n");
                }elsif($BEREQ{$4} eq "HomePos") { # bP[0]:Arm/bP[1]:Unit/bP[2]:Slot/:bP[3]:0:Put/1:Get
                    my $cmd = ($8 == 1) ? "GET" : "PUT";
                    %BEREQDATA = (Arm => $5, Unit => $BEUNIT{$6}, Slot => $7, Cmd => $cmd, REQ => $BEREQ{$4});
                    push(@decodeFile, $1, " TN--> ReqHandler(CTRL:$RBTCTRLSTATE{$3}, REQ:$BEREQ{$4}, PRM:(PRM: Arm$5, Unit:$BEUNIT{$6}, Slot:$7, Cmd:$cmd))\n");
                }elsif($BEREQ{$4} eq "AxisU") { # bP[0]:Arm/bP[1]:Axis(全軸のみ?)/bP[2]:Unit/bP[3]:Slot/bP[4]:Position:
                    %BEREQDATA = (Arm => $5, Axis => $BEAXIS{$6}, Unit => $BEUNIT{$7}, Slot => $8, Position => $9, REQ => $BEREQ{$4});
                    push(@decodeFile, $1, " TN--> ReqHandler(CTRL:$RBTCTRLSTATE{$3}, REQ:$BEREQ{$4}, PRM:(PRM: Arm$5, Axis:$BEAXIS{$6}, Unit:$BEUNIT{$7}, Slot:$8, Position:$BEPOS{$9}))\n");
                }else{
                    %BEREQDATA = ("Arm" => $5, "From" => $BEUNIT{$6}, "FSlot" => $7, "To" => $BEUNIT{$8}, "TSlot" => $9, "WafBrank" => $BEUNIT{$10}, "REQ" => $BEREQ{$4});
                    push(@decodeFile, $1, " TN--> ReqHandler(CTRL:$RBTCTRLSTATE{$3}, REQ:$BEREQ{$4} P:Arm$5/From$BEUNIT{$6}/FromSlot$7/To$BEUNIT{$8}/ToSlot$9/WafBrank$10 Abort:$11 ANS:$BEANS{$12} ERR:$13)\n");
                }
            }else{
                say "Unknown REQ: $3";
            }
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],SetSpeedPrm\((\d+),(\d+)\)(.*))/i){
            # say "Mode: $SPMODE{$3}"; say "Arm: $4)"; say $1;
            my $reset = "";
            if ($4 == 4){
                $reset = " :BE Arm now has No Wf";
            }
            push(@decodeFile, $1, "\t\t TN--> SetSpeedPrm($SPMODE{$3}, Arm$4)$reset\n");
        }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],Error:IsWaferDetectErrorOfIOC\(LL(\d+),(\w+)\):\s+iocsens:(0\w).*)/i){
            # say "LL: $3"; say "B: $4"; say "iocsens: $5"; say $1;
            my $loadlock = "UD";
            if ($3 == 1){
                $loadlock = "LLL";
            }elsif ($3 == 2){
                $loadlock = "RLL";
            }
            my $iocsens = "UD";
            if ($5 eq "0a"){
                $iocsens = "Wf exists"
            }elsif($5 eq "05"){
                $iocsens = "No Wf"
            }
            push(@decodeFile, $1, " TN--> $loadlock: $iocsens\n");
        }elsif ($BEREQDATA{"REQ"} eq "WafMove1"){
            if ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],\[STEP:0->21\])/i){
                push(@decodeFile, $1, "\t\t\t\t\t TN--> (Verifying errors, alarms!\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],\[STEP:21->22\])/i){
                push(@decodeFile, $1, "\t\t\t\t\t TN--> (Verify wafer detection sensors?\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],\[STEP:22->23\])/i){
                push(@decodeFile, $1, "\t\t\t\t\t TN--> (Any detection error?\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],\[STEP:30->39\])/i){
                push(@decodeFile, $1, "\t\t\t\t\t TN--> (No any concern so far!\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],\[STEP:39->60\])/i){
                push(@decodeFile, $1, "\t\t\t\t\t TN--> (Go next step to finalize if wafer now exists at ", $BEREQDATA{"To"}, ")\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],\[STEP:60->61\])/i){
                push(@decodeFile, $1, "\t\t\t\t\t TN--> (Finalizing this ", $BEREQDATA{"REQ"}, ")\n");
            }elsif ($line =~ /^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],\[STEP:61->100\])/i){
                push(@decodeFile, $1, "\t\t\t\t\t TN--> (", $BEREQDATA{"REQ"}, " successful. Wafer now at ", $BEREQDATA{"To"}, ")\n");
            }else{
                push(@decodeFile, $line);
            }
        }else{
            push(@decodeFile, $line);
        }
    }

    return @decodeFile;
}

sub decodeWIOLogFile{
    say "->decodeWIOLogFile()";
    my @decodeFile;
    foreach my $line (@_){
        if($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],>>>>(CreateWioCmd)\(TYPE\[(\d+)\],REQ\[(\d+)\]\)<<<<)/i){ # Create WIO commands
            push(@decodeFile, $1, " TN--> $3 ($WIOTYPE{$4}, $WIOREQ{$5})\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],>>>>(CreateGvCmd)\(TYPE\[(\d+)\],(GV\d),REQ\[(\d+)\],(\w+).*)/i){ # Create GV commands with option
            #say "line: $line";
            my $demandType = "Internal";
            if ($6 eq "FALSE"){
                $demandType = "External";
            }
            push(@decodeFile, $1, " TN--> $3 ($GVTYPE{$4}, $GVREQ{$6}, $demandType)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],>>>>(CreateGvCmd)\(TYPE\[(\d+)\],(GV\d),REQ\[(\d+)\]\)<<<<)/i){ # Create GV commands
            #say $1; say "TimeStamp: $2"; say "Cmd: $3"; say "TYPE: $GVTYPE{$4}"; say $5; say "REQ: $6";
            push(@decodeFile, $1, " TN--> $3 ($GVTYPE{$4}, $GVREQ{$6})\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],<<<<(SetCompleted)\(\)---GV(\d+):\[CTRL:(\d+)\/REQ:(\d+)\/ANS:(\d+)\/State:(\d+)\]>>>>)/i){ # GV Command completed
            # say "TimeStamp: $2"; say "Function: $3"; say "GV: $4"; say "CTRL: $5"; say "REQ: $6"; say "ANS: $7"; say "State: $8"; say $1;
            push(@decodeFile, $1, " TN--> GV$4 (CTRL: $WIOCTRLSTATE{$5}, REQ: $GVREQ{$6}, ANS: $WIOANS{$7}, State: $WIOGVSTATE{$8})\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],<<<<(SetCompleted)\(\)---IOC(\d+):\[CTRL:(\d+)\/REQ:(\d+)\/ANS:(\d+)\/Press:(\d+)\/Valve:(\d+)\]>>>>)/i){ # LL Command completed
            # say "TimeStamp: $2"; say "Function: $3"; say "IOC: $4"; say "CTRL: $5"; say "REQ: $6"; say "ANS: $7"; say "Press: $8"; say "Valve: $9"; say $1;
            push(@decodeFile, $1, " TN--> $IOCTOLL{$4} (CTRL: $WIOCTRLSTATE{$5}, REQ: $WIOREQ{$6}, ANS: $WIOANS{$7}, Press: $WIOPRESSSTATE{$8}, Valve: $WIOVALVESTATE{$9})\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],<<<<(SetCompleted)\(\)---WHC:\[CTRL:(\d+)\/REQ:(\d+)\/ANS:(\d+)\/Press:(\d+)\/Valve:(\d+)\]>>>>)/i){ # WHC Command completed
            # say "TimeStamp: $2"; say "Function: $3"; say "CTRL: $4"; say "REQ: $5"; say "ANS: $6"; say "Press: $7"; say "Valve: $8"; say $1;
            push(@decodeFile, $1, " TN--> WHC (CTRL: $WIOCTRLSTATE{$4}, REQ: $WIOREQ{$5}, ANS: $WIOANS{$6}, Press: $WIOPRESSSTATE{$7}, Valve: $WIOVALVESTATE{$8})\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocBackfill\[(\d+)\]-DwellFlow-Prm\[(\d+)\])/i){ # LL BackFill from step0
            push(@decodeFile, $1, " TN--> (Turn Off FastIdle if On. Otherwise, disable it then proceed to step:$3)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocBackfill\[(\d+)\]:STEP\[0->1\])/i){ # LL BackFill step1
            push(@decodeFile, $1, " TN--> (BackFill:$IOCTOLL{$3}. Check Style FLOW)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocBackfill\[(\d+)\]:STEP\[1->10\])/i){ # LL BackFill step10
            push(@decodeFile, $1, " TN--> (BackFill:$IOCTOLL{$3}. Check GVs of $IOCTOLL{$3} before isolate it!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocBackfill\[(\d+)\]:STEP\[10->11\])/i){ # LL BackFill step11
            push(@decodeFile, $1, " TN--> (BackFill:$IOCTOLL{$3}. Check style isolate)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocBackfill\[(\d+)\]:STEP\[11->20\])/i){ # LL BackFill step20
            push(@decodeFile, $1, " TN--> (BackFill:$IOCTOLL{$3}. If all related GVs closed go to next step)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocBackfill\[(\d+)\]:STEP\[20->21\])/i){ # LL BackFill step21
            push(@decodeFile, $1, " TN--> (BackFill:$IOCTOLL{$3}. Use fast pump if possible)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocBackfill\[(\d+)\]:STEP\[21->22\])/i){ # LL BackFill step22
            push(@decodeFile, $1, " TN--> (BackFill:$IOCTOLL{$3}. If ATM stop timer, close BackFill valve)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocBackfill\[(\d+)\]:STEP\[22->23\])/i){ # LL BackFill step23
            push(@decodeFile, $1, " TN--> (BackFill:$IOCTOLL{$3}. Go to step30 if style not ATM isolate. Otherwise, next step)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocBackfill\[(\d+)\]:STEP\[23->30\])/i){ # LL BackFill step30
            push(@decodeFile, $1, " TN--> (BackFill:$IOCTOLL{$3}. Open related GVs to do BackFill if needed. Go to next step)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocBackfill\[(\d+)\]:STEP\[30->31\])/i){ # LL BackFill step31
            push(@decodeFile, $1, " TN--> (BackFill:$IOCTOLL{$3}. Stop timer if related GVs open. Go to step40 if style flow is FE. Otherwise, go next step)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocBackfill\[(\d+)\]:STEP\[31->40\])/i){ # LL BackFill step40
            push(@decodeFile, $1, " TN--> (BackFill:$IOCTOLL{$3}. Finalize to complete BackFill operation)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocBackfill\[(\d+)\]:STEP\[40->100\])/i){ # LL BackFill complete
            push(@decodeFile, $1, " TN--> (BackFill:$IOCTOLL{$3}. BackFill operation completed!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocVacuum\[(\d+)\]:STEP\[0->1\])/i){ # LL ReqIocVacuum step1
            push(@decodeFile, $1, " TN--> (Vacuum:$IOCTOLL{$3}. Verify related GVs then go next step!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocVacuum\[(\d+)\]:STEP\[1->2\])/i){ # LL ReqIocVacuum step2
            push(@decodeFile, $1, " TN--> (Vacuum:$IOCTOLL{$3}. Are related GVs closed now? If pump not busy jump to step4. Otherwise, next)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocVacuum\[(\d+)\]:STEP\[2->4\])/i){ # LL ReqIocVacuum step4
            push(@decodeFile, $1, " TN--> (Vacuum:$IOCTOLL{$3}. Do some settings. Interlock GVOpen!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocVacuum\[(\d+)\]:STEP\[4->5\])/i){ # LL ReqIocVacuum step5
            push(@decodeFile, $1, " TN--> (Vacuum:$IOCTOLL{$3}. Verify pressures then go next step!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],SLOW->FAST:\[Pressur:(\d+)\]\[CrossPress:(\d+)\])/i){ # LL ReqIocVacuum
            my $info = " TN--> (Current pressure: $3 NOT meets NOR exceeds cross pressure: $4 yet!)\n";
            if($3 >= $4){
                $info = " TN--> (Current pressure: $3 meets or exceeds cross pressure: $4 now!)\n";
            }
            push(@decodeFile, $1, $info);
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocVacuum\[(\d+)\]:STEP\[5->6\])/i){ # LL ReqIocVacuum step6
            push(@decodeFile, $1, " TN--> (Vacuum:$IOCTOLL{$3}. Verify pump down type. Next if base pressure. Jump if setpoint pressure.)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocVacuum\[(\d+)\]:STEP\[6->7\])/i){ # LL ReqIocVacuum step7
            push(@decodeFile, $1, " TN--> (Vacuum:$IOCTOLL{$3}. Verify some settings!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocVacuum\[(\d+)\]:STEP\[7->8\])/i){ # LL ReqIocVacuum step8
            push(@decodeFile, $1, " TN--> (Vacuum:$IOCTOLL{$3}. Verify pressures to make conclusion!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],CONT:CLOSE\[Pressur:(\d+)\]\[SetPress:(\d+)\])/i){ # LL ReqIocVacuum
            my $info = " TN--> (Current pressure: $3 NOT meets NOR exceeds expected pressure: $4 yet!)\n";
            if($3 >= $4){
                $info = " TN--> (Current pressure: $3 meets or exceeds expected pressure: $4 now!)\n";
            }
            push(@decodeFile, $1, $info);
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocVacuum\[(\d+)\]:STEP\[8->100\])/i){ # LL ReqIocVacuum step100
            push(@decodeFile, $1, " TN--> (Vacuum:$IOCTOLL{$3} successfully completed!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocCyclePurge\[(\d+)\]:STEP\[0->1\])/i){ # LL ReqIocCyclePurge step1
            push(@decodeFile, $1, " TN--> (CycPurge:$IOCTOLL{$3} If all related GVs closed, set interlock then go to step10!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocCyclePurge\[(\d+)\]:STEP\[1->10\])/i){ # LL ReqIocCyclePurge step10
            push(@decodeFile, $1, " TN--> (CycPurge:$IOCTOLL{$3} Pump should be busy working now. Otherwise, set it!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocCyclePurge\[(\d+)\]:STEP\[10->11\])/i){ # LL ReqIocCyclePurge step11
            push(@decodeFile, $1, " TN--> (CycPurge:$IOCTOLL{$3} Run Fast Pump for Idle Purge then go next step!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocCyclePurge\[(\d+)\]:STEP\[11->12\])/i){ # LL ReqIocCyclePurge step12
            push(@decodeFile, $1, " TN--> (CycPurge:$IOCTOLL{$3} Check pressure. Not meet go next step!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocCyclePurge\[(\d+)\]:STEP\[12->13\])/i){ # LL ReqIocCyclePurge step13
            push(@decodeFile, $1, " TN--> (CycPurge:$IOCTOLL{$3} If all related GVs closed, set interlock then go next step!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocCyclePurge\[(\d+)\]:STEP\[13->14\])/i){ # LL ReqIocCyclePurge step14
            push(@decodeFile, $1, " TN--> (CycPurge:$IOCTOLL{$3} Verify DI signal. If fast pump closed and purge type 1ATM then go step30. Otherwise step20! If cycle done go step50!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocCyclePurge\[(\d+)\]:STEP\[14->30\])/i){ # LL ReqIocCyclePurge step30
            push(@decodeFile, $1, " TN--> (CycPurge:$IOCTOLL{$3} Do some state setting for purge type 1ATM!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocCyclePurge\[(\d+)\]:STEP\[30->31\])/i){ # LL ReqIocCyclePurge step31
            push(@decodeFile, $1, " TN--> (CycPurge:$IOCTOLL{$3} Set BackFile valve state then go next step!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocCyclePurge\[(\d+)\]:STEP\[31->32\])/i){ # LL ReqIocCyclePurge step32
            push(@decodeFile, $1, " TN--> (CycPurge:$IOCTOLL{$3} Unset BackFile valve state then go next step!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocCyclePurge\[(\d+)\]:STEP\[32->33\])/i){ # LL ReqIocCyclePurge step33
            push(@decodeFile, $1, " TN--> (CycPurge:$IOCTOLL{$3} Does it need more time for purging? Next step!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocCyclePurge\[(\d+)\]:STEP\[34->10\])/i){ # LL ReqIocCyclePurge step10
            push(@decodeFile, $1, " TN--> (CycPurge:$IOCTOLL{$3} Repeat purging operation logic!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocCyclePurge\[(\d+)\]:STEP\[14->50\])/i){ # LL ReqIocCyclePurge step50
            push(@decodeFile, $1, " TN--> (CycPurge:$IOCTOLL{$3} Almost done. Check pressure to continue working next step or finalizing on step60!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocCyclePurge\[(\d+)\]:STEP\[50->60\])/i){ # LL ReqIocCyclePurge step60
            push(@decodeFile, $1, " TN--> (CycPurge:$IOCTOLL{$3} Final check Fast Close DI signal to make conclusion!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocCyclePurge\[(\d+)\]:STEP\[60->100\])/i){ # LL ReqIocCyclePurge step100
            push(@decodeFile, $1, " TN--> (CycPurge:$IOCTOLL{$3} completed successfully!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocFastIdle\[(\d+)\]:STEP\[0->1\])/i){ # LL ReqIocFastIdle step1
            push(@decodeFile, $1, " TN--> (CycPurge:$IOCTOLL{$3} Prepare timer then go next step!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocFastIdle\[(\d+)\]:STEP\[1->2\])/i){ # LL ReqIocFastIdle step2
            push(@decodeFile, $1, " TN--> (CycPurge:$IOCTOLL{$3} Go next step if all related GVs ready!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocFastIdle\[(\d+)\]:STEP\[2->3\])/i){ # LL ReqIocFastIdle step3
            push(@decodeFile, $1, " TN--> (CycPurge:$IOCTOLL{$3} Go next 2 steps if valves closed but pump not busy yet! Otherwise, next step!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocFastIdle\[(\d+)\]:STEP\[3->5\])/i){ # LL ReqIocFastIdle step5
            push(@decodeFile, $1, " TN--> (CycPurge:$IOCTOLL{$3} Set interlocks and more!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocFastIdle\[(\d+)\]:STEP\[5->6\])/i){ # LL ReqIocFastIdle step6
            push(@decodeFile, $1, " TN--> (CycPurge:$IOCTOLL{$3} Check pressure whether it meets cross press yet. Go step 10 to start fast idle!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocFastIdle\[(\d+)\]:STEP\[6->10\])/i){ # LL ReqIocFastIdle step10
            push(@decodeFile, $1, " TN--> (CycPurge:$IOCTOLL{$3} Prepare to complete operation!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqIocFastIdle\[(\d+)\]:STEP\[10->100\])/i){ # LL ReqIocFastIdle step100
            push(@decodeFile, $1, " TN--> (CycPurge:$IOCTOLL{$3} successfully completed!)\n");
        }else{
            push(@decodeFile, $line);
        }
    }

    return @decodeFile;
}

sub decodeTMILLogFile{
    say "->decodeTMILLogFile()";
    my @decodeFile;
    foreach my $line (@_){
        if($line =~/^\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],(IL:GV.*?),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),/i){ #GVClose or GVOpen
            #say $line; say "1: $1, 2: $2, 3: $3, 4: $4, 5: $5, 6: $6, 7: $7, 8: $8, 9: $9, 10: $10, 11:$11";
            push(@decodeFile, "$1,$2, GV1: $ILState{$3}, GV2: $ILState{$4}, GV3: $ILState{$5}, GV4: $ILState{$6}, GV5: $ILState{$7}, GV6: $ILState{$8}, GV7: $ILState{$9}, GV8: $ILState{$10}, GV9: $ILState{$11}\n");
        }elsif($line =~/^\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],(IL:LP.*?),(\d+),(\d+),(\d+),(\d+),/i){ #LPClose or LPOpen
            push(@decodeFile, "$1,$2, LP1: $ILState{$3}, LP2: $ILState{$4}, LP3: $ILState{$5}, LP4: $ILState{$6}\n");
        }elsif($line =~/^\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],(IL:IocMove),(\d+),(\d+),(\d+),(\d+),/i){ #IOC:InputOutputChamber = LoadLock
            push(@decodeFile, "$1,$2, LLL: $ILState{$3}, UnUsed1: $ILState{$4}, RLL: $ILState{$5}, UnUsed2: $ILState{$6}\n");
        }elsif($line =~/^\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],(IL:BerbExt),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),/i){ #BERBT
            push(@decodeFile, "$1,$2, RC1: $ILState{$3}, RC2: $ILState{$4}, RC3: $ILState{$5}, RC4: $ILState{$6}, RC5: $ILState{$7}, LLL: $ILState{$8}, UnUsed1: $ILState{$9}, RLL: $ILState{$10}, UnUsed2: $ILState{$11}\n");
        }elsif($line =~/^\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],(IL:FerbExt),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),/i){ #FERBT
            push(@decodeFile, "$1,$2, LP1: $ILState{$3}, LP2: $ILState{$4}, LP3: $ILState{$5}, LP4: $ILState{$6}, ALN: $ILState{$7}, LLL: $ILState{$8}, UnUsed1: $ILState{$9}, RLL: $ILState{$10}, UnUsed2: $ILState{$11}, MES: $ILState{$12}, COOL1: $ILState{$13}, COOL2: $ILState{$14}\n");
        }
    }

    return @decodeFile;
}

sub decodeTMALLLogFile{
    say "->decodeTMALLLogFile()";
    my @decodeFile;
    foreach my $line (@_){
        if($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqAlarmReset::Step\[99->101\])/i){ #Timeout
            push(@decodeFile, $1, "\t TN--> (Timeout but ok!)\n");
        }elsif($line =~/^(\[(\d+\/\d+-\d+:\d+:\d+.\d+)\],ReqAlarmReset::Step\[5->100\])/i){ #Complete
            push(@decodeFile, $1, "\t TN--> (Completed Successfully)\n");
        }else{
            push(@decodeFile, $line);
        }
    }
    return @decodeFile;
}

sub ILState{
    #say "->ILState";
    $ILState{"0000"} = "Happy";
    $ILState{"0001"} = "FERB";
    $ILState{"0002"} = "BERB";
    $ILState{"0003"} = "FERB+BERB";
    $ILState{"0004"} = "GV";
    $ILState{"0005"} = "FERB+GV";
    $ILState{"0006"} = "BERB+GV";
    $ILState{"0007"} = "FERB+BERB+GV";
    $ILState{"0008"} = "LP";
    $ILState{"0009"} = "FERB+LP";

    $ILState{"0010"} = "SUS";
    $ILState{"0011"} = "SUS+FERB";
    $ILState{"0012"} = "SUS+BERB";
    $ILState{"0013"} = "SUS+BERB+FERB";
    $ILState{"0014"} = "SUS+GV";
    $ILState{"0015"} = "SUS+GV+FERB";
    $ILState{"0016"} = "SUS+GV+BERB";
    $ILState{"0017"} = "SUS+GV+BERB+FERB";
    $ILState{"0018"} = "SUS+LP";
    $ILState{"0019"} = "SUS+LP+FERB";

    $ILState{"0020"} = "ALN";
    $ILState{"0021"} = "ALN+FERB";
    $ILState{"0022"} = "ALN+BERB";
    $ILState{"0023"} = "ALN+BERB+FERB";
    $ILState{"0024"} = "ALN+GV";
    $ILState{"0025"} = "ALN+GV+FERB";
    $ILState{"0026"} = "ALN+GV+BERB";
    $ILState{"0027"} = "ALN+GV+BERB+FERB";
    $ILState{"0028"} = "ALN+LP";
    $ILState{"0029"} = "ALN+LP+FERB";

    $ILState{"0040"} = "MES";
    $ILState{"0041"} = "MES+FERB";
    $ILState{"0042"} = "MES+BERB";
    $ILState{"0043"} = "MES+BERB+FERB";
    $ILState{"0044"} = "MES+GV";
    $ILState{"0045"} = "MES+GV+FERB";
    $ILState{"0046"} = "MES+GV+BERB";
    $ILState{"0047"} = "MES+GV+BERB+FERB";
    $ILState{"0048"} = "MES+LP";
    $ILState{"0049"} = "MES+LP+FERB";

    $ILState{"0080"} = "DIFF_PRESS";
    $ILState{"0081"} = "DIFF_PRESS+FERB";
    $ILState{"0082"} = "DIFF_PRESS+BERB";
    $ILState{"0083"} = "DIFF_PRESS+BERB+FERB";
    $ILState{"0084"} = "DIFF_PRESS+GV";
    $ILState{"0085"} = "DIFF_PRESS+GV+FERB";
    $ILState{"0086"} = "DIFF_PRESS+GV+BERB";
    $ILState{"0087"} = "DIFF_PRESS+GV+BERB+FERB";
    $ILState{"0088"} = "DIFF_PRESS+LP";
    $ILState{"0089"} = "DIFF_PRESS+LP+FERB";

    $ILState{"0100"} = "WAF_SENS";
    $ILState{"0101"} = "WAF_SENS+FERB";
    $ILState{"0102"} = "WAF_SENS+BERB";
    $ILState{"0103"} = "WAF_SENS+BERB+FERB";
    $ILState{"0104"} = "WAF_SENS+GV";
    $ILState{"0105"} = "WAF_SENS+GV+FERB";
    $ILState{"0106"} = "WAF_SENS+GV+BERB";
    $ILState{"0107"} = "WAF_SENS+GV+BERB+FERB";
    $ILState{"0108"} = "WAF_SENS+LP";
    $ILState{"0109"} = "WAF_SENS+LP+FERB";

    $ILState{"0110"} = "WAF_SENS+SUS";
    $ILState{"0120"} = "WAF_SENS+ALN";
    $ILState{"0140"} = "WAF_SENS+MES";
    $ILState{"0180"} = "WAF_SENS+DIFF_PRESS";
    $ILState{"0182"} = "WAF_SENS+DIFF_PRESS+BERB";

    $ILState{"0200"} = "WHC";
    $ILState{"0201"} = "WHC+FERB";
    $ILState{"0202"} = "WHC+BERB";
    $ILState{"0203"} = "WHC+BERB+FERB";
    $ILState{"0204"} = "WHC+GV";
    $ILState{"0205"} = "WHC+GV+FERB";
    $ILState{"0206"} = "WHC+GV+BERB";
    $ILState{"0207"} = "WHC+GV+BERB+FERB";
    $ILState{"0208"} = "WHC+LP";
    $ILState{"0209"} = "WHC+LP+FERB";

    $ILState{"0210"} = "WHC+SUS";
    $ILState{"0220"} = "WHC+ALN";
    $ILState{"0240"} = "WHC+MES";
    $ILState{"0280"} = "WHC+DIFF_PRESS";

    $ILState{"0400"} = "IOC";
    $ILState{"0401"} = "IOC+FERB";
    $ILState{"0402"} = "IOC+BERB";
    $ILState{"0403"} = "IOC+BERB+FERB";
    $ILState{"0404"} = "IOC+GV";
    $ILState{"0405"} = "IOC+GV+FERB";
    $ILState{"0406"} = "IOC+GV+BERB";
    $ILState{"0407"} = "IOC+GV+BERB+FERB";
    $ILState{"0408"} = "IOC+LP";
    $ILState{"0409"} = "IOC+LP+FERB";

    $ILState{"0410"} = "IOC+SUS";
    $ILState{"0420"} = "IOC+ALN";
    $ILState{"0440"} = "IOC+MES";
    $ILState{"0480"} = "IOC+DIFF_PRESS";

    $ILState{"0600"} = "Unknown0600Now";
    $ILState{"0680"} = "Unknown0680Now";
    $ILState{"4000"} = "Unknown4000Now";
    $ILState{"4002"} = "Unknown4002Now";
    $ILState{"4100"} = "Unknown4100Now";
    $ILState{"4200"} = "Unknown4200Now";
    $ILState{"0802"} = "Unknown0802Now";
    $ILState{"0902"} = "Unknown0902Now";
}

sub ccuLogAnalyser{
    say "->ccuLogAnalyser()";
    if(@mesLogs) {
        my $libSource = 'C:\ASM-Host\Config\ALD\ConvertedEventXp.txt';
        open (INFILE, "$libSource") || die "ERROR! Can't open $libSource\n";
        my @libBucket = <INFILE>;
        close(INFILE) || die "ERROR! Can't close $libSource\n";
        foreach my $line_str (@libBucket) { #Just create dictionary first to use later on updating data
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

        @mesLogs = sort {$b cmp $a} @mesLogs; #sort by file's name
        my $lastNumber = 0;
        my @sortedMesLogs;
        my $change = 0;
        my @batchOne;
        my @batchTwo;

        # log is versioning from 1->99 then roll over
        # so we need to get the log files listed in order by creation time
        for(my $count = 0; $count < @mesLogs; $count++) { #sorting log file by chronological order
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
        #push(@sortedMesLogs, reverse @batchTwo, @batchOne);
        #say "Sorting files by time";

        if(@batchOne && @batchTwo){ #log files are grouped in 2 batches
            if (compareTimeStamp (getLastTimeStamp($CcuLogDir . "\\" . $batchTwo[$#batchTwo]), getFirstTimeStamp($CcuLogDir . "\\" . $batchOne[$#batchOne]) )) {
                push(@sortedMesLogs, reverse @batchTwo, @batchOne);
            }else {
                push(@sortedMesLogs, reverse @batchOne, @batchTwo);
            }
        }elsif(@batchOne){
            push(@sortedMesLogs, reverse @batchOne);
        }elsif(@batchTwo){
            push(@sortedMesLogs, reverse @batchTwo);
        }else{ #all log files are continuously in one batch
            push(@sortedMesLogs, reverse @mesLogs);
        }

        my @logData;
        foreach my $logFile (@sortedMesLogs){
            my $logFileFullPath = $CcuLogDir . "\\" . $logFile;
            #say"sorted : $logFile";
            open (INFILE, "$logFileFullPath") || die "ERROR! Can't open $logFileFullPath\n";
            my @content = <INFILE>;
            close(INFILE) || die "ERROR! Can't close $logFileFullPath\n";
            #$logFile = "***** $logFile *****";
            #say $logFile;
            push(@logData, "<<<<<< $logFile >>>>>>");
            push(@logData, reverse @content); #put items from old to new which's opposite with original
        }

        my @bucket;
        foreach my $line_str (@logData){
            if ($line_str =~ /^"\d+",(.*)/i || $line_str =~ /^(<<<<<<.*?>>>>>>)/i) {
                #say "1: $1";
                push(@bucket, $1); #get rid of the first index item to start from date item
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

        my $WithS6F12 = 0; # option to whether show it on report
        my @annotatedData;
        GetStreamDefinition(); #initialize %streamInfo to know all secs cmd name.
        my $fileName = "";

        foreach my $line_str (@bucket){
            #print "line found event $line_str\n";
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

            next if (($line_str =~ /^#/) || ($line_str =~ /^$/)); #skip all the comments or blank lines

            if ($line_str =~ /^(<<<<<<.*?>>>>>>)/i) {
                $fileName = $line_str;
            }elsif ($line_str =~ /^"(\d+\/\d+)","(\d+:\d+:\d+)",(".*?",)"(S\d+F\d+)"(.*)/i) {
                #say "1: $1, 2: $2, 3: $3, 4: $4, 5: $5";
                my $date = $1;
                my $time = $2;
                my $dateTime = $date . " " . $time;
                my $direction = $3;
                my $secsCmd = $4;
                my $remain = $5;
                my $ceidDetail = "";
                if($fileName ne ""){
                    $fileName = $dateTime . " " . $fileName . "\n";
                    push(@annotatedData, $fileName); #list name of the file first before its content
                    $fileName = "";
                }elsif ($secsCmd eq "S6F11" && $remain =~ /,"([-]?)(\d+).*",/i) { # We're just interested on events
                    #say $line_str; say $1;
                    my $ceid = $2;
                    if ($1 eq "-") {
                        $ceidDetail = "CEID:" . $1 . $ceid . " UNEXPECTED NEGATIVE NUMBER ! WARNING !WARNING !WARNING !";
                        say $ceidDetail;
                        push(@annotatedData, $dateTime . ',' . $direction . $secsCmd . ',' . $ceidDetail . "\n");
                        next;
                    }

                    if(exists $ceidDict{$ceid} && defined $ceidDict{$ceid}){
                        $ceidDetail = "CEID:" . $ceid . " " . $ceidDict{$ceid};
                    }else{
                        $ceidDetail = "CEID:" . $1 . $ceid . " is UNDEF ! WARNING !WARNING !WARNING !";
                        say $ceidDetail;
                        push(@annotatedData, $dateTime . ',' . $direction . $secsCmd . ',' . $ceidDetail . "\n");
                        next;
                    }

                    if ($ceidDict{$ceid} =~ /RC(\d)RecipeStarted/i) { # RCxRecipeStarted event
                        my $chamber = "RC".$1;
                        $stepCount = 0;
                        $recStartTime = $dateTime; #Time the recipe starts on the tool
                        #Start time must happen first; otherwise, this finish time does not have start time
                        $recipeStartedInfo{$chamber."RecipeStarted"} = $recStartTime;
                        if($recipeFinishedInfo{$chamber."RecipeFinished"} ne "") {
                            $recipeFinishedInfo{$chamber."RecipeFinished"} = ""; #clear it for the right data coming
                        }
                        $ceidDetail = "$ceidDetail at $time";
                    }elsif ($ceidDict{$ceid} =~ /RC(\d)RecipeFinished/i) { # RCxRecipeFinished event
                        my $chamber = "RC".$1;
                        $stepCount = 0;
                        $recFinishTime = $dateTime; #Time the recipe finishes on the tool
                        $recipeFinishedInfo{$ceidDict{$ceid}} = $recFinishTime;
                        $recStartTime = $recipeStartedInfo{$chamber."RecipeStarted"};
                        if($recStartTime ne "") {
                            $processTime = str2time($recFinishTime) - str2time($recStartTime);
                            $ceidDetail = "CEID:" . $ceid . " " . $ceidDict{$ceid} . " (" . $chamber . " Finished in " . POSIX::strftime("\%H:\%M:\%S", gmtime($processTime)) . ")";
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
                        $ceidDetail = "$ceidDetail at $time";
                    }elsif ($ceidDict{$ceid} =~ /RC(\d)StepFinished/i) { # RCxStepFinished event
                        my $chamber = "RC".$1;
                        $stepFinishTime = $dateTime; #Time recipe's step finishes
                        $stepStartTime = $recipeStartedInfo{$chamber."StepStarted"};
                        if($stepStartTime ne "" ) {
                            $stepTime = str2time($stepFinishTime) - str2time($stepStartTime);
                            $ceidDetail = "CEID:" . $ceid . " " . $ceidDict{$ceid} . " (" . $chamber . " " . $step . " Finished in " . POSIX::strftime("\%H:\%M:\%S", gmtime($stepTime)) . ")";
                            initializeChamberRecipeStepTimeInfo($1); #reset for new data coming
                        }
                    }elsif ($ceidDict{$ceid} =~ /WaferMovedStartLP(\d)FERbt/i) { # WaferMovedStartLPxFERbt event
                        my $loadport = "LP".$1;
                        #print"Wafer exits LoadPort: $lpWaferMovedStart\n";
                        $lpOutTime = $dateTime; #Time LP->FERbt starts is time Wafer exits LoadPort
                        $wfMoveStartedInfo{"WaferMovedStart".$loadport."FERbt"} = $lpOutTime;
                        if($wfMoveFinishedInfo{"WaferMovedFinishFERbt".$loadport} ne "") {
                            $wfMoveFinishedInfo{"WaferMovedFinishFERbt".$loadport} = ""; #clear it for the right data coming
                        }
                        $ceidDetail = "$ceidDetail at $time";
                    }elsif ($ceidDict{$ceid} =~ /WaferMovedFinishFERbtLP(\d+)/i) { # WaferMovedFinishFERbtLPx event
                        my $loadport = "LP".$1;
                        #print"Wafer returns to LoadPort: $lpWaferMovedFinish\n";
                        $lpInTime = $dateTime; #Time FERbt->LP finishes is time Wafer returns to LoadPort
                        $lpOutTime = $wfMoveStartedInfo{"WaferMovedStart".$loadport."FERbt"};
                        if($lpOutTime ne "") {
                            $lpOutInTime = str2time($lpInTime) - str2time($lpOutTime);
                            $ceidDetail = "CEID:" . $ceid . " " . $ceidDict{$ceid} . " (".$loadport." Finished Wafer in ". POSIX::strftime("\%H:\%M:\%S", gmtime($lpOutInTime)).")";
                            initializeWfFERbtMoveTimeInfo($1); #reset for new data coming
                        }
                    }elsif ($ceidDict{$ceid} =~ /WaferMovedStartRC(\d)BERbt/i) { # WaferMovedStartRCxBERbt event
                        my $chamber = "RC".$1;
                        #print"Wafer enters Chamber: $rcWaferMovedFinish\n";
                        $rcInTime = $dateTime; #Time BERbt->RC finishes is time Wafer enters RC
                        $wfMoveStartedInfo{"WaferMovedStart".$chamber."BERbt"} = $rcInTime;
                        if($wfMoveFinishedInfo{"WaferMovedFinishBERbt".$chamber} ne "") {
                            $wfMoveFinishedInfo{"WaferMovedFinishBERbt".$chamber} = ""; #clear it for the right data coming
                        }
                        $ceidDetail = "$ceidDetail at $time";
                    }elsif ($ceidDict{$ceid} =~ /WaferMovedFinishBERbtRC(\d)/i) { # WaferMovedFinishBERbtRCx event
                        my $chamber = "RC".$1;
                        #print"Wafer exits Chamber: $rcWaferMovedStart\n";
                        $rcOutTime = $dateTime; #Time RC->BERbt finishes is time Wafer exits RC
                        $rcInTime = $wfMoveStartedInfo{"WaferMovedStart".$chamber."BERbt"};
                        if($rcInTime ne "") {
                            $rcInOutTime = str2time($rcOutTime) - str2time($rcInTime);
                            $ceidDetail = "CEID:" . $ceid . " " . $ceidDict{$ceid} . " (" . $chamber . " Finished Wafer in " . POSIX::strftime("\%H:\%M:\%S", gmtime($rcInOutTime)) . ")";
                            initializeWfBERbtMoveTimeInfo($1); #reset for new data coming
                        }
                    }
                    push(@annotatedData, $dateTime . ',' . $direction . $secsCmd . ',' . $ceidDetail . "\n");
                }elsif ($line_str =~ /"(S\d+F\d+)"/i) {
                    $secsCmd = $1;
                    #say "other : $secsCmd";
                    if ($secsCmd eq "S6F12" && $WithS6F12 == 0) {
                        next;
                    }
                    push(@annotatedData, $dateTime . ',' . $direction . $secsCmd . ',' . $streamInfo{$secsCmd} . "\n");
                }
            }
        }

        $tempfile = $CcuLogDir . "\\logUpdated.txt";
        say $tempfile;
        open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
        print OUTFILE @annotatedData;
        close (OUTFILE) || die "ERROR! Can't close $tempfile\n";
    }else{
        say "No MesLog.csv files";
    }
}

sub getLastTimeStamp {
    #say "->getLastTimeStamp()";
    open (INFILE, $_[0]) || die "error! can't open $_[0]\n";
    my @fileContent = <INFILE>;
    close(INFILE) || die "error! can't close $_[0]\n";
    my $timePattern = '"(\d+\/\d+)","(\d+:\d+:\d+)"'; #eg. "09/28","17:13:48"
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

sub getFirstTimeStamp {
    #say "->getFirstTimeStamp()";
    open (INFILE, $_[0]) || die "error! can't open $_[0]\n";
    my @fileContent = <INFILE>;
    close(INFILE) || die "error! can't close $_[0]\n";
    my $timePattern = '"(\d+\/\d+)","(\d+:\d+:\d+)"'; #eg. "09/28","17:13:48"
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

sub compareTimeStamp {
    my $dateformat = "%H:%M:%S, %m/%d";
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

sub GetStreamDefinition{
    #say("GetStreamDefinition");
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
    $streamInfo{"S7F65"} = "Route Upload Request";
    $streamInfo{"S7F66"} = "Route Upload Reponse";
    $streamInfo{"S7F67"} = "Route Download Request";
    $streamInfo{"S7F68"} = "Route Download Response";
    $streamInfo{"S7F71"} = "Current Process Recipe List Request";
    $streamInfo{"S7F72"} = "Current Process Recipe List Data";
    $streamInfo{"S7F73"} = "NonRoute Formatted Process Program Download Request";
    $streamInfo{"S7F74"} = "NonRoute Formatted Process Program Download Response";
    $streamInfo{"S7F75"} = "NonRoute Formatted Process Program Upload Request";
    $streamInfo{"S7F76"} = "NonRoute Formatted Process Program Upload Response";
    $streamInfo{"S7F83"} = "Name/Value Formatted Process Program Send";
    $streamInfo{"S7F84"} = "Name/Value Formatted Process Program Acknowledge";
    $streamInfo{"S7F85"} = "Name/Value Formatted Process Program Request";
    $streamInfo{"S7F86"} = "Name/Value Formatted Process Program Data";
    $streamInfo{"S9F0"} = "Abort Transaction";
    $streamInfo{"S9F1"} = "Unrecognized Device ID";
    $streamInfo{"S9F3"} = "Unrecognized Stream Type";
    $streamInfo{"S9F5"} = "Unrecognized Function Type";
    $streamInfo{"S9F7"} = "Illegal Data";
    $streamInfo{"S9F8"} = "Response Illegal Data";
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

sub GetAlarmDefinition{
    $alarmInfo{"01060130"} = "ALLRC1LeakRateError";
    $alarmInfo{"01060131"} = "ALLRC1RPLeakRateError";
    $alarmInfo{"01060230"} = "ALLRC2LeakRateError";
    $alarmInfo{"01060231"} = "ALLRC2RPLeakRateError";
    $alarmInfo{"01060330"} = "ALLRC3LeakRateError";
    $alarmInfo{"01060331"} = "ALLRC3RPLeakRateError";
    $alarmInfo{"01060430"} = "ALLRC4LeakRateError";
    $alarmInfo{"01060431"} = "ALLRC4RPLeakRateError";
    $alarmInfo{"01060530"} = "ALLRC5LeakRateError";
    $alarmInfo{"01060531"} = "ALLRC5RPLeakRateError";
    $alarmInfo{"10060000"} = "SYN10060000";
    $alarmInfo{"10060001"} = "TMALLWatchDriverFroze";
    $alarmInfo{"10060002"} = "TMALLTMDeviceNetDriverFroze";
    $alarmInfo{"10060003"} = "TMALLLPxDriverFroze";
    $alarmInfo{"10060004"} = "TMALLLPxDriverFroze";
    $alarmInfo{"10060005"} = "TMALLLPxDriverFroze";
    $alarmInfo{"10060006"} = "TMALLLPxDriverFroze";
    $alarmInfo{"10060007"} = "TMALLCIDxDriverFroze";
    $alarmInfo{"10060008"} = "TMALLCIDxDriverFroze";
    $alarmInfo{"10060009"} = "TMALLCIDxDriverFroze";
    $alarmInfo{"1006000A"} = "TMALLCIDxDriverFroze";
    $alarmInfo{"1006000B"} = "TMALLFERobotDriverFroze";
    $alarmInfo{"1006000C"} = "TMALLBERobotDriverFroze";
    $alarmInfo{"1006000D"} = "TMALLLLxRobotDriverFroze";
    $alarmInfo{"1006000E"} = "TMALLLLxRobotDriverFroze";
    $alarmInfo{"1006000F"} = "TMALLMonitorDriverFroze";
    $alarmInfo{"10060010"} = "TMALLWaferAlignerDriverFroze";
    $alarmInfo{"10060011"} = "TMALLTMDeviceNetIODriverFroze";
    $alarmInfo{"10060012"} = "TMALLPMLinkxDriverFroze";
    $alarmInfo{"10060013"} = "TMALLPMLinkxDriverFroze";
    $alarmInfo{"10060014"} = "TMALLLLxWaferAlignerDriverFroze";
    $alarmInfo{"10060015"} = "TMALLLLxWaferAlignerDriverFroze";
    $alarmInfo{"10060016"} = "TMALLPBCDriverFroze";
    $alarmInfo{"10060017"} = "10060017";
    $alarmInfo{"10060018"} = "10060018";
    $alarmInfo{"10060019"} = "10060019";
    $alarmInfo{"1006001E"} = "1006001E";
    $alarmInfo{"10060020"} = "TMALLPBCSensorErrorOccurred";
    $alarmInfo{"10060030"} = "TMALLDeviceNetMacID0CommunicationLost";
    $alarmInfo{"10060031"} = "TMALLDeviceNetMacID1CommunicationLost";
    $alarmInfo{"10060032"} = "TMALLDeviceNetMacID2CommunicationLost";
    $alarmInfo{"10060033"} = "TMALLDeviceNetMacID3CommunicationLost";
    $alarmInfo{"10060034"} = "TMALLDeviceNetMacID4CommunicationLost";
    $alarmInfo{"10060035"} = "TMALLDeviceNetMacID5CommunicationLost";
    $alarmInfo{"10060036"} = "TMALLDeviceNetMacID6CommunicationLost";
    $alarmInfo{"10060037"} = "TMALLDeviceNetMacID7CommunicationLost";
    $alarmInfo{"10060038"} = "TMALLDeviceNetMacID8CommunicationLost";
    $alarmInfo{"10060039"} = "TMALLDeviceNetMacID9CommunicationLost";
    $alarmInfo{"1006003A"} = "TMALLDeviceNetMacID10CommunicationLost";
    $alarmInfo{"1006003B"} = "TMALLDeviceNetMacID11CommunicationLost";
    $alarmInfo{"1006003C"} = "TMALLDeviceNetMacID12CommunicationLost";
    $alarmInfo{"1006003D"} = "TMALLDeviceNetMacID13CommunicationLost";
    $alarmInfo{"1006003E"} = "TMALLDeviceNetMacID14CommunicationLost";
    $alarmInfo{"1006003F"} = "TMALLDeviceNetMacID15CommunicationLost";
    $alarmInfo{"10060040"} = "TMALLDeviceNetMacID16CommunicationLost";
    $alarmInfo{"10060041"} = "TMALLDeviceNetMacID17CommunicationLost";
    $alarmInfo{"10060042"} = "TMALLDeviceNetMacID18CommunicationLost";
    $alarmInfo{"10060043"} = "TMALLDeviceNetMacID19CommunicationLost";
    $alarmInfo{"10060044"} = "TMALLDeviceNetMacID20CommunicationLost";
    $alarmInfo{"10060045"} = "TMALLDeviceNetMacID21CommunicationLost";
    $alarmInfo{"10060046"} = "TMALLDeviceNetMacID22CommunicationLost";
    $alarmInfo{"10060047"} = "TMALLDeviceNetMacID23CommunicationLost";
    $alarmInfo{"10060048"} = "TMALLDeviceNetMacID24CommunicationLost";
    $alarmInfo{"10060049"} = "TMALLDeviceNetMacID25CommunicationLost";
    $alarmInfo{"1006004A"} = "TMALLDeviceNetMacID26CommunicationLost";
    $alarmInfo{"1006004B"} = "TMALLDeviceNetMacID27CommunicationLost";
    $alarmInfo{"1006004C"} = "TMALLDeviceNetMacID28CommunicationLost";
    $alarmInfo{"1006004D"} = "TMALLDeviceNetMacID29CommunicationLost";
    $alarmInfo{"1006004E"} = "TMALLDeviceNetMacID30CommunicationLost";
    $alarmInfo{"1006004F"} = "TMALLDeviceNetMacID31CommunicationLost";
    $alarmInfo{"10060050"} = "TMALLDeviceNetMacID32CommunicationLost";
    $alarmInfo{"10060051"} = "TMALLDeviceNetMacID33CommunicationLost";
    $alarmInfo{"10060052"} = "TMALLDeviceNetMacID34CommunicationLost";
    $alarmInfo{"10060053"} = "TMALLDeviceNetMacID35CommunicationLost";
    $alarmInfo{"10060054"} = "TMALLDeviceNetMacID36CommunicationLost";
    $alarmInfo{"10060055"} = "TMALLDeviceNetMacID37CommunicationLost";
    $alarmInfo{"10060056"} = "TMALLDeviceNetMacID38CommunicationLost";
    $alarmInfo{"10060057"} = "TMALLDeviceNetMacID39CommunicationLost";
    $alarmInfo{"10060058"} = "TMALLDeviceNetMacID40CommunicationLost";
    $alarmInfo{"10060059"} = "TMALLDeviceNetMacID41CommunicationLost";
    $alarmInfo{"1006005A"} = "TMALLDeviceNetMacID42CommunicationLost";
    $alarmInfo{"1006005B"} = "TMALLDeviceNetMacID43CommunicationLost";
    $alarmInfo{"1006005C"} = "TMALLDeviceNetMacID44CommunicationLost";
    $alarmInfo{"1006005D"} = "TMALLDeviceNetMacID45CommunicationLost";
    $alarmInfo{"1006005E"} = "TMALLDeviceNetMacID46CommunicationLost";
    $alarmInfo{"1006005F"} = "TMALLDeviceNetMacID47CommunicationLost";
    $alarmInfo{"10060060"} = "TMALLDeviceNetMacID48CommunicationLost";
    $alarmInfo{"10060061"} = "TMALLDeviceNetMacID49CommunicationLost";
    $alarmInfo{"10060062"} = "TMALLDeviceNetMacID50CommunicationLost";
    $alarmInfo{"10060063"} = "TMALLDeviceNetMacID51CommunicationLost";
    $alarmInfo{"10060064"} = "TMALLDeviceNetMacID52CommunicationLost";
    $alarmInfo{"10060065"} = "TMALLDeviceNetMacID53CommunicationLost";
    $alarmInfo{"10060066"} = "TMALLDeviceNetMacID54CommunicationLost";
    $alarmInfo{"10060067"} = "TMALLDeviceNetMacID55CommunicationLost";
    $alarmInfo{"10060068"} = "TMALLDeviceNetMacID56CommunicationLost";
    $alarmInfo{"10060069"} = "TMALLDeviceNetMacID57CommunicationLost";
    $alarmInfo{"1006006A"} = "TMALLDeviceNetMacID58CommunicationLost";
    $alarmInfo{"1006006B"} = "TMALLDeviceNetMacID59CommunicationLost";
    $alarmInfo{"1006006C"} = "TMALLDeviceNetMacID60CommunicationLost";
    $alarmInfo{"1006006D"} = "TMALLDeviceNetMacID61CommunicationLost";
    $alarmInfo{"1006006E"} = "TMALLDeviceNetMacID62CommunicationLost";
    $alarmInfo{"1006006F"} = "TMALLDeviceNetMacID63CommunicationLost";
    $alarmInfo{"1006001B"} = "SYN1006001B";
    $alarmInfo{"1006001C"} = "SYN1006001C";
    $alarmInfo{"1010000"} = "ChamberAlarmRC1Cleared";
    $alarmInfo{"1010001"} = "ChamberAlarmRC1Detected";
    $alarmInfo{"1020000"} = "ChamberAlarmRC2Cleared";
    $alarmInfo{"1020001"} = "ChamberAlarmRC2Detected";
    $alarmInfo{"1030000"} = "ChamberAlarmRC3Cleared";
    $alarmInfo{"1030001"} = "ChamberAlarmRC3Detected";
    $alarmInfo{"1040000"} = "ChamberAlarmRC4Cleared";
    $alarmInfo{"1040001"} = "ChamberAlarmRC4Detected";
    $alarmInfo{"1050000"} = "ChamberAlarmRC5Cleared";
    $alarmInfo{"1050001"} = "ChamberAlarmRC5Detected";
    $alarmInfo{"1070000"} = "ChamberAlarmLL1Cleared";
    $alarmInfo{"1070001"} = "ChamberAlarmLL1Detected";
    $alarmInfo{"1080000"} = "ChamberAlarmLL2Cleared";
    $alarmInfo{"1080001"} = "ChamberAlarmLL2Detected";
    $alarmInfo{"1090000"} = "ChamberAlarmLL3Cleared";
    $alarmInfo{"1090001"} = "ChamberAlarmLL3Detected";
    $alarmInfo{"10a0000"} = "ChamberAlarmLL4Cleared";
    $alarmInfo{"10a0001"} = "ChamberAlarmLL4Detected";
    $alarmInfo{"10b0000"} = "ChamberAlarmWHCCleared";
    $alarmInfo{"10b0001"} = "ChamberAlarmWHCDetected";
    $alarmInfo{"11060000"} = "11060000";
    $alarmInfo{"11060000"} = "11060000";
    $alarmInfo{"11060001"} = "FERBTCommunicationTimeout";
    $alarmInfo{"11060002"} = "FERBTStatusChangedToIDLE";
    $alarmInfo{"11060003"} = "FERBTCommandWasRejected";
    $alarmInfo{"11060004"} = "FERBTAborted";
    $alarmInfo{"11060005"} = "FERBTACKTimeout3Sec)";
    $alarmInfo{"11060006"} = "FERBTMovementTimeout60Sec)";
    $alarmInfo{"11060007"} = "FERBTReplyError";
    $alarmInfo{"11060008"} = "FERBTTheStatusOfTheEmergencyStopAlarmInput)WasReceived";
    $alarmInfo{"11060009"} = "FERBTTheStatusOfTheCommandErrorOccurringWasReceived";
    $alarmInfo{"1106000A"} = "FERBTTheStatusOfTheSensorErrorOccurringWasReceived";
    $alarmInfo{"1106000B"} = "FERBTAxis1StepOutError";
    $alarmInfo{"1106000C"} = "FERBTAxis2StepOutError";
    $alarmInfo{"1106000D"} = "FERBTAxis3StepOutError";
    $alarmInfo{"1106000E"} = "FERBTAxis4StepOutError";
    $alarmInfo{"1106000F"} = "FERBTCommandErrorOnRobotController";
    $alarmInfo{"11060010"} = "FERBTAxis1BatteryLow";
    $alarmInfo{"11060011"} = "FERBTAxis2BatteryLow";
    $alarmInfo{"11060012"} = "FERBTAxis3BatteryLow";
    $alarmInfo{"11060013"} = "FERBTAxis4BatteryLow";
    $alarmInfo{"11060014"} = "FERBTAxis1BatteryError";
    $alarmInfo{"11060015"} = "FERBTAxis2BatteryError";
    $alarmInfo{"11060016"} = "FERBTAxis3BatteryError";
    $alarmInfo{"11060017"} = "FERBTAxis4BatteryError";
    $alarmInfo{"11060018"} = "FERBTMovementOutOfRange";
    $alarmInfo{"11060019"} = "FERBTGVOrLPInterlockErrorOccurred";
    $alarmInfo{"1106001A"} = "FERBTWaferClampError";
    $alarmInfo{"1106001B"} = "FERBTChangedToTeachingMode";
    $alarmInfo{"1106001C"} = "FERBTAxis1SoftwareLimit";
    $alarmInfo{"1106001D"} = "FERBTAxis2SoftwareLimit";
    $alarmInfo{"1106001E"} = "FERBTAxis3SoftwareLimit";
    $alarmInfo{"1106001F"} = "FERBTAxis4SoftwareLimit";
    $alarmInfo{"11060020"} = "FERBTWaferInterlockErrorOccurred";
    $alarmInfo{"11060021"} = "FERBTARMIsNotRetractPosition";
    $alarmInfo{"11060022"} = "FERBTWaferClamp/unclampTimeout";
    $alarmInfo{"11060023"} = "FERBTUnitInterlockErrorOccurred";
    $alarmInfo{"11060027"} = "FERBTCommandFormatErrorOccurred";
    $alarmInfo{"11060028"} = "FERBTParameterErrorOccurred";
    $alarmInfo{"11060029"} = "FERBTUnitErrorOccurred";
    $alarmInfo{"1106002A"} = "FERBTCoolingStageDoesNotExist";
    $alarmInfo{"1106002D"} = "FERBTWaferExistsInTheLLCBeforePuttingWaferToLLC";
    $alarmInfo{"1106002E"} = "FERBTWaferDoesNotExistInTheLLCAfterPuttingWaferToLLC";
    $alarmInfo{"1106002F"} = "FERBTWaferDoesNotExistInTheLLCBeforeGettingWaferFromLLC";
    $alarmInfo{"11060030"} = "FERBTWaferExistsInTheLLCAfterGettingWaferFromLLC";
    $alarmInfo{"11060031"} = "FERBTAxis1PositionGapError";
    $alarmInfo{"11060032"} = "FERBTAxis2PositionGapError";
    $alarmInfo{"11060033"} = "FERBTAxis3PositionGapError";
    $alarmInfo{"11060034"} = "FERBTAxisZPositionGapError";
    $alarmInfo{"11060035"} = "FERBTAxis1AdjustError";
    $alarmInfo{"11060036"} = "FERBTAxis2AdjustError";
    $alarmInfo{"11060037"} = "FERBTAxis3AdjustError";
    $alarmInfo{"11060038"} = "FERBTUnitUndefined";
    $alarmInfo{"11060039"} = "FERBTNAKBUSY)WasReceived";
    $alarmInfo{"1106003A"} = "FERBTNAKCheckSumError)WasReceived";
    $alarmInfo{"1106003B"} = "FERBTNAKT1Timeout)WasReceived";
    $alarmInfo{"1106003C"} = "FERBTNAKCMD:commandError)WasReceived";
    $alarmInfo{"1106003D"} = "FERBTNAKPRM:parameterError)WasReceived";
    $alarmInfo{"1106003E"} = "FERBTNAKWasReceived.TheCauseIsUncertainOutsideTheManualDescription";
    $alarmInfo{"1106003F"} = "FERBTMessageIDMesID)OfAPrimaryResponseIsNotCorresponding";
    $alarmInfo{"11061003"} = "SYN11061003";
    $alarmInfo{"11061006"} = "SYN11061006";
    $alarmInfo{"11061007"} = "SYN11061007";
    $alarmInfo{"1106100D"} = "SYN1106100D";
    $alarmInfo{"12060000"} = "12060000";
    $alarmInfo{"12060001"} = "BERBTCommunicationTimeout";
    $alarmInfo{"12060002"} = "BERBTStatusChangedToIDLE";
    $alarmInfo{"12060003"} = "BERBTCommandWasRejected";
    $alarmInfo{"12060004"} = "BERBTAborted";
    $alarmInfo{"12060005"} = "BERBTACKTimeout3Sec)";
    $alarmInfo{"12060006"} = "BERBTMovementTimeout60Sec)";
    $alarmInfo{"12060007"} = "BERBTReplyError";
    $alarmInfo{"12060008"} = "BERBTTheStatusOfTheEmergencyStopAlarmInput)WasReceived";
    $alarmInfo{"12060009"} = "BERBTTheStatusOfTheCommandErrorOccurringWasReceived";
    $alarmInfo{"1206000A"} = "BERBTTheStatusOfTheSensorErrorOccurringWasReceived";
    $alarmInfo{"1206000B"} = "BERBTAxis1StepOutError";
    $alarmInfo{"1206000C"} = "BERBTAxis2StepOutError";
    $alarmInfo{"1206000D"} = "BERBTAxis3StepOutError";
    $alarmInfo{"1206000E"} = "BERBTAxis4StepOutError";
    $alarmInfo{"1206000F"} = "BERBTCommandErrorOnRobotController";
    $alarmInfo{"12060010"} = "BERBTAxis1BatteryLow";
    $alarmInfo{"12060011"} = "BERBTAxis2BatteryLow";
    $alarmInfo{"12060012"} = "BERBTAxis3BatteryLow";
    $alarmInfo{"12060013"} = "BERBTAxis4BatteryLow";
    $alarmInfo{"12060014"} = "BERBTAxis1BatteryError";
    $alarmInfo{"12060015"} = "BERBTAxis2BatteryError";
    $alarmInfo{"12060016"} = "BERBTAxis3BatteryError";
    $alarmInfo{"12060017"} = "BERBTAxis4BatteryError";
    $alarmInfo{"12060018"} = "BERBTMovementOutOfRange";
    $alarmInfo{"12060019"} = "BERBTGVInterlockErrorOccurred";
    $alarmInfo{"1206001A"} = "BERBTWaferClampError";
    $alarmInfo{"1206001B"} = "BERBTChangeToTeachingMode";
    $alarmInfo{"1206001C"} = "BERBTAxis1SoftwareLimit";
    $alarmInfo{"1206001D"} = "BERBTAxis2SoftwareLimit";
    $alarmInfo{"1206001E"} = "BERBTAxis3SoftwareLimit";
    $alarmInfo{"1206001F"} = "BERBTAxis4SoftwareLimit";
    $alarmInfo{"12060020"} = "BERBTWaferInterlockErrorOccurred";
    $alarmInfo{"12060021"} = "BERBTARMIsNotRetractPosition";
    $alarmInfo{"12060022"} = "BERBTWaferClamp/unclampTimeout";
    $alarmInfo{"12060023"} = "BERBTUnitInterlockErrorOccurred";
    $alarmInfo{"12060024"} = "BERBTEncoderCommunicationErrorOccurred";
    $alarmInfo{"12060025"} = "BERBTMotorPowerFailed";
    $alarmInfo{"12060026"} = "BERBTEncoderReadErrorOccurred";
    $alarmInfo{"12060028"} = "BERBTParameterErrorOccurred";
    $alarmInfo{"1206002B"} = "BERBTSusceptorInterlockErrorOccurred.SusceptorIsNotDown.";
    $alarmInfo{"1206002C"} = "BERBTGVInterlockErrorOccurred.GVIsNotOpen.";
    $alarmInfo{"1206002D"} = "BERBTWaferExistsInTheLLCBeforePuttingWaferToLLC";
    $alarmInfo{"1206002E"} = "BERBTWaferDoesNotExistInTheLLCAfterPuttingWaferToLLC";
    $alarmInfo{"1206002F"} = "BERBTWaferDoesNotExistInTheLLCBeforeGettingWaferFromLLC";
    $alarmInfo{"12060030"} = "BERBTWaferExistsInTheLLCAfterGettingWaferFromLLC";
    $alarmInfo{"12060031"} = "BERBTExceedTheLimitsOfPositionAdjustData";
    $alarmInfo{"12060032"} = "BERBTPBCWaferSensorAlarmOccurred";
    $alarmInfo{"12060033"} = "BERBTWaferExistsOnTheArmByTheSensorCheckOfArmFrontSideBeforeGettingWafer";
    $alarmInfo{"12060034"} = "BERBTWaferExistsOnTheArmByTheSensorCheckOfArmElbowSideBeforeGettingWafer";
    $alarmInfo{"12060035"} = "BERBTWaferDoesNotExistOnTheArmByTheSensorCheckOfArmFrontSideAfterGettingWafer";
    $alarmInfo{"12060036"} = "BERBTWaferDoesNotExistOnTheArmByTheSensorCheckOfArmElbowSideAfterGettingWafer";
    $alarmInfo{"12060037"} = "BERBTWaferDoesNotExistOnTheArmByTheSensorCheckOfArmFrontSideBeforePuttingWafer";
    $alarmInfo{"12060038"} = "BERBTWaferDoesNotExistOnTheArmByTheSensorCheckOfArmElbowSideBeforePuttingWafer";
    $alarmInfo{"12060039"} = "BERBTWaferExistsOnTheArmByTheSensorCheckOfArmFrontSideAfterPuttingWafer";
    $alarmInfo{"1206003A"} = "BERBTWaferExistsOnTheArmByTheSensorCheckOfArmElbowSideAfterPuttingWafer";
    $alarmInfo{"1206003B"} = "BERBTTheArmSensorErrorOccursWhenTheWaferClamperIsNothing";
    $alarmInfo{"1206003C"} = "BERBTUnitErrorOccurred";
    $alarmInfo{"1206003D"} = "BERBTAWCCalibrationDoesNotComplete";
    $alarmInfo{"1206003E"} = "BERBTAWCSavingDoesNotComplete";
    $alarmInfo{"1206003F"} = "BERBTGetFailed,WaferNotSensedOnBERobot";
    $alarmInfo{"12060040"} = "BERBTPutFailed,WaferStillSensedOnBERobot";
    $alarmInfo{"12061012"} = "SYN12061012";
    $alarmInfo{"12061020"} = "SYN12061020";
    $alarmInfo{"12600320"} = "BERobotPBCWaferSensorAlarmOccurredClr";
    $alarmInfo{"12600321"} = "BERobotPBCWaferSensorAlarmOccurredDet";
    $alarmInfo{"16060000"} = "16060000";
    $alarmInfo{"16060000"} = "16060000";
    $alarmInfo{"16060001"} = "LP1CommunicationTimeout";
    $alarmInfo{"16060002"} = "LP1StatusChangedToIDLE";
    $alarmInfo{"16060003"} = "LP1CommandWasRejected";
    $alarmInfo{"16060004"} = "LP1Stopped";
    $alarmInfo{"16060005"} = "LP1Aborted";
    $alarmInfo{"16060006"} = "LP1NAKCommandError)WasReceived";
    $alarmInfo{"16060007"} = "LP1NAKParameterError)WasReceived";
    $alarmInfo{"16060008"} = "LP1NAKAlarm)WasReceived";
    $alarmInfo{"16060009"} = "LP1StatusIsBusy";
    $alarmInfo{"1606000A"} = "LP1CommandIsDenied";
    $alarmInfo{"1606000B"} = "LP1CarrierIsNotOnTheLoadPort";
    $alarmInfo{"1606000C"} = "LP1StatusIsNotReady";
    $alarmInfo{"1606000D"} = "LP1DataErrorOccurs";
    $alarmInfo{"1606000E"} = "LP1OutOfRangeErrorOccurs";
    $alarmInfo{"1606000F"} = "LP1UnknownECIDErrorOccurs";
    $alarmInfo{"16060010"} = "LP1ACKTimeout";
    $alarmInfo{"16060011"} = "LP1CompletionTimeout";
    $alarmInfo{"16060012"} = "LP1OtherErrorOccurs";
    $alarmInfo{"16060014"} = "LP1FERobotInterlockErrorOccurred";
    $alarmInfo{"16060015"} = "LP1LOAD/UNLOADSequenceFailed";
    $alarmInfo{"16060016"} = "LP1N2PressureForFOUPPurgeUpperLimitErrorOccurred";
    $alarmInfo{"16060017"} = "LP1N2PressureForFOUPPurgeLowerLimitErrorOccurred";
    $alarmInfo{"16060018"} = "LP1N2ErrorOfFOUPPurgeUnitOccurred";
    $alarmInfo{"16060019"} = "LP1N2PurgeKeyOfFOUPPurgeUnitWasTurnedOff";
    $alarmInfo{"1606001A"} = "LP1N2FlowLimitErrorOfFOUPPurgeUnitOccurred";
    $alarmInfo{"1606001B"} = "LP1N2InterlockErrorOfFOUPPurgeUnitOccurred";
    $alarmInfo{"1606001C"} = "1606001C-Alarm";
    $alarmInfo{"16060020"} = "LP1AMHSTP1ErrorOccurred";
    $alarmInfo{"16060021"} = "LP1AMHSTP2ErrorOccurred";
    $alarmInfo{"16060022"} = "LP1AMHSTP3ErrorOccurred";
    $alarmInfo{"16060023"} = "LP1AMHSTP4ErrorOccurred";
    $alarmInfo{"16060024"} = "LP1AMHSTP5ErrorOccurred";
    $alarmInfo{"16060025"} = "LP1AMHSTP6ErrorOccurred";
    $alarmInfo{"16060026"} = "LP1AMHSEMSOccurred";
    $alarmInfo{"16060027"} = "LP1AMHSLoadPortErrorOccurred";
    $alarmInfo{"16060028"} = "LP1AMHSValidOffErrorOccurred";
    $alarmInfo{"16060029"} = "LP1AMHSPODIsTransferredManually";
    $alarmInfo{"1606002A"} = "LP1AMHSPODNotUnclamped";
    $alarmInfo{"1606002B"} = "LP1AMHSFERobotFailureOccurred";
    $alarmInfo{"1606002C"} = "LP1AMHSCarrierSensorErrorOccurred";
    $alarmInfo{"1606002D"} = "LP1AMHSAutoDisableByLPConfigSetting";
    $alarmInfo{"1606002E"} = "LP1LoadPortStatusIsNotTransferBlocked";
    $alarmInfo{"1606002F"} = "LP1ExecutingManualSequence";
    $alarmInfo{"16060030"} = "LP1ExecutingAutoHandoffSequence";
    $alarmInfo{"16060031"} = "LP1LPConfigIsRunningMode";
    $alarmInfo{"16060032"} = "LP1AMHSRecoverCannotBeDone";
    $alarmInfo{"16060033"} = "LP1AMHSLightCurtainError";
    $alarmInfo{"16060034"} = "LP1AbnormalSignalOfE84WasDetected";
    $alarmInfo{"16060035"} = "LP1Dummy/ProductMismatch";
    $alarmInfo{"16060036"} = "LP1MaterialMismatch";
    $alarmInfo{"16061012"} = "SYN16061012";
    $alarmInfo{"17060000"} = "17060000";
    $alarmInfo{"17060000"} = "17060000";
    $alarmInfo{"17060000"} = "17060000";
    $alarmInfo{"17060001"} = "CommunicationTimeout";
    $alarmInfo{"17060001"} = "LP2CommunicationTimeout";
    $alarmInfo{"17060002"} = "LP2StatusChangedToIDLE";
    $alarmInfo{"17060002"} = "StatusChangedToIDLE";
    $alarmInfo{"17060003"} = "CommandWasRejected";
    $alarmInfo{"17060003"} = "LP2CommandWasRejected";
    $alarmInfo{"17060004"} = "LP2Stopped";
    $alarmInfo{"17060004"} = "Stopped";
    $alarmInfo{"17060005"} = "Aborted";
    $alarmInfo{"17060005"} = "LP2Aborted";
    $alarmInfo{"17060006"} = "LP2NAKCommandError)WasReceived";
    $alarmInfo{"17060006"} = "NAK(commandError)WasReceived";
    $alarmInfo{"17060007"} = "LP2NAKParameterError)WasReceived";
    $alarmInfo{"17060007"} = "NAK(parameterError)WasReceived";
    $alarmInfo{"17060008"} = "LP2NAKAlarm)WasReceived";
    $alarmInfo{"17060008"} = "NAK(alarm)WasReceived";
    $alarmInfo{"17060009"} = "LP2StatusIsBusy";
    $alarmInfo{"17060009"} = "StatusIsBusy";
    $alarmInfo{"1706000A"} = "CommandIsDenied";
    $alarmInfo{"1706000A"} = "LP2CommandIsDenied";
    $alarmInfo{"1706000B"} = "CarrierIsNotOnTheLoadPort";
    $alarmInfo{"1706000B"} = "LP2CarrierIsNotOnTheLoadPort";
    $alarmInfo{"1706000C"} = "LP2StatusIsNotReady";
    $alarmInfo{"1706000C"} = "StatusIsNotReady";
    $alarmInfo{"1706000D"} = "DataErrorOccurs";
    $alarmInfo{"1706000D"} = "LP2DataErrorOccurs";
    $alarmInfo{"1706000E"} = "LP2OutOfRangeErrorOccurs";
    $alarmInfo{"1706000E"} = "OutOfRangeErrorOccurs";
    $alarmInfo{"1706000F"} = "LP2UnknownECIDErrorOccurs";
    $alarmInfo{"1706000F"} = "UnknownECIDErrorOccurs";
    $alarmInfo{"17060010"} = "ACKTimeout";
    $alarmInfo{"17060010"} = "LP2ACKTimeout";
    $alarmInfo{"17060011"} = "CompletionTimeout";
    $alarmInfo{"17060011"} = "LP2CompletionTimeout";
    $alarmInfo{"17060012"} = "LP2OtherErrorOccurs";
    $alarmInfo{"17060012"} = "OtherErrorOccurs";
    $alarmInfo{"17060014"} = "FERobotInterlockErrorOccurred";
    $alarmInfo{"17060014"} = "LP2FERobotInterlockErrorOccurred";
    $alarmInfo{"17060015"} = "LOAD/UNLOADSequenceFailed";
    $alarmInfo{"17060015"} = "LP2LOAD/UNLOADSequenceFailed";
    $alarmInfo{"17060016"} = "LP2N2PressureForFOUPPurgeUpperLimitErrorOccurred";
    $alarmInfo{"17060016"} = "N2PressureForFOUPPurgeUpperLimitErrorOccurred";
    $alarmInfo{"17060017"} = "LP2N2PressureForFOUPPurgeLowerLimitErrorOccurred";
    $alarmInfo{"17060017"} = "N2PressureForFOUPPurgeLowerLimitErrorOccurred";
    $alarmInfo{"17060018"} = "LP2N2ErrorOfFOUPPurgeUnitOccurred";
    $alarmInfo{"17060018"} = "N2ErrorOfFOUPPurgeUnitOccurred";
    $alarmInfo{"17060019"} = "LP2N2PurgeKeyOfFOUPPurgeUnitWasTurnedOff";
    $alarmInfo{"17060019"} = "N2PurgeKeyOfFOUPPurgeUnitWasTurnedOff";
    $alarmInfo{"1706001A"} = "LP2N2FlowLimitErrorOfFOUPPurgeUnitOccurred";
    $alarmInfo{"1706001A"} = "N2FlowLimitErrorOfFOUPPurgeUnitOccurred";
    $alarmInfo{"1706001B"} = "LP2N2InterlockErrorOfFOUPPurgeUnitOccurred";
    $alarmInfo{"1706001B"} = "N2InterlockErrorOfFOUPPurgeUnitOccurred";
    $alarmInfo{"1706001C"} = "1706001C-Alarm";
    $alarmInfo{"1706001D"} = "1706001D-Alarm";
    $alarmInfo{"1706001E"} = "1706001E-Alarm";
    $alarmInfo{"1706001F"} = "1706001F-Alarm";
    $alarmInfo{"17060020"} = "AMHSTP1ErrorOccurred";
    $alarmInfo{"17060020"} = "LP2AMHSTP1ErrorOccurred";
    $alarmInfo{"17060021"} = "AMHSTP2ErrorOccurred";
    $alarmInfo{"17060021"} = "LP2AMHSTP2ErrorOccurred";
    $alarmInfo{"17060022"} = "AMHSTP3ErrorOccurred";
    $alarmInfo{"17060022"} = "LP2AMHSTP3ErrorOccurred";
    $alarmInfo{"17060023"} = "AMHSTP4ErrorOccurred";
    $alarmInfo{"17060023"} = "LP2AMHSTP4ErrorOccurred";
    $alarmInfo{"17060024"} = "AMHSTP5ErrorOccurred";
    $alarmInfo{"17060024"} = "LP2AMHSTP5ErrorOccurred";
    $alarmInfo{"17060025"} = "AMHSTP6ErrorOccurred";
    $alarmInfo{"17060025"} = "LP2AMHSTP6ErrorOccurred";
    $alarmInfo{"17060026"} = "AMHSEMSOccurred";
    $alarmInfo{"17060026"} = "LP2AMHSEMSOccurred";
    $alarmInfo{"17060027"} = "AMHSLoadPortErrorOccurred";
    $alarmInfo{"17060027"} = "LP2AMHSLoadPortErrorOccurred";
    $alarmInfo{"17060028"} = "AMHSValidOffErrorOccurred";
    $alarmInfo{"17060028"} = "LP2AMHSValidOffErrorOccurred";
    $alarmInfo{"17060029"} = "AMHSPODIsTransferredManually";
    $alarmInfo{"17060029"} = "LP2AMHSPODIsTransferredManually";
    $alarmInfo{"1706002A"} = "AMHSPODNotUnclamped";
    $alarmInfo{"1706002A"} = "LP2AMHSPODNotUnclamped";
    $alarmInfo{"1706002B"} = "AMHSFERobotFailureOccurred";
    $alarmInfo{"1706002B"} = "LP2AMHSFERobotFailureOccurred";
    $alarmInfo{"1706002C"} = "AMHSCarrierSensorErrorOccurred";
    $alarmInfo{"1706002C"} = "LP2AMHSCarrierSensorErrorOccurred";
    $alarmInfo{"1706002D"} = "AMHSAutoDisableByLPConfigSetting";
    $alarmInfo{"1706002D"} = "LP2AMHSAutoDisableByLPConfigSetting";
    $alarmInfo{"1706002E"} = "LP2LoadPortStatusIsNotTransferBlocked";
    $alarmInfo{"1706002E"} = "LoadPortStatusIsNotTransferBlocked";
    $alarmInfo{"1706002F"} = "ExecutingManualSequence";
    $alarmInfo{"1706002F"} = "LP2ExecutingManualSequence";
    $alarmInfo{"17060030"} = "ExecutingAutoHandoffSequence";
    $alarmInfo{"17060030"} = "LP2ExecutingAutoHandoffSequence";
    $alarmInfo{"17060031"} = "LP2LPConfigIsRunningMode";
    $alarmInfo{"17060031"} = "LPConfigIsRunningMode";
    $alarmInfo{"17060032"} = "AMHSRecoverCannotBeDone";
    $alarmInfo{"17060032"} = "LP2AMHSRecoverCannotBeDone";
    $alarmInfo{"17060033"} = "AMHSLightCurtainError";
    $alarmInfo{"17060033"} = "LP2AMHSLightCurtainError";
    $alarmInfo{"17060034"} = "AbnormalSignalOfE84WasDetected";
    $alarmInfo{"17060034"} = "LP2AbnormalSignalOfE84WasDetected";
    $alarmInfo{"17060035"} = "Dummy/ProductMismatch";
    $alarmInfo{"17060035"} = "LP2Dummy/ProductMismatch";
    $alarmInfo{"17060036"} = "LP2MaterialMismatch";
    $alarmInfo{"17060036"} = "MaterialMismatch";
    $alarmInfo{"17061010"} = "SYN17061010";
    $alarmInfo{"17061012"} = "SYN17061012";
    $alarmInfo{"18060000"} = "LP3.18060000";
    $alarmInfo{"18060001"} = "LP3CommunicationTimeout";
    $alarmInfo{"18060002"} = "LP3StatusChangedToIDLE";
    $alarmInfo{"18060003"} = "LP3CommandWasRejected";
    $alarmInfo{"18060004"} = "LP3Stopped";
    $alarmInfo{"18060005"} = "LP3Aborted";
    $alarmInfo{"18060006"} = "LP3NAKCommandError)WasReceived";
    $alarmInfo{"18060007"} = "LP3NAKParameterError)WasReceived";
    $alarmInfo{"18060008"} = "LP3NAKAlarm)WasReceived";
    $alarmInfo{"18060009"} = "LP3StatusIsBusy";
    $alarmInfo{"1806000A"} = "LP3CommandIsDenied";
    $alarmInfo{"1806000B"} = "LP3CarrierIsNotOnTheLoadPort";
    $alarmInfo{"1806000C"} = "LP3StatusIsNotReady";
    $alarmInfo{"1806000D"} = "LP3DataErrorOccurs";
    $alarmInfo{"1806000E"} = "LP3OutOfRangeErrorOccurs";
    $alarmInfo{"1806000F"} = "LP3UnknownECIDErrorOccurs";
    $alarmInfo{"18060010"} = "LP3ACKTimeout";
    $alarmInfo{"18060011"} = "LP3CompletionTimeout";
    $alarmInfo{"18060012"} = "LP3OtherErrorOccurs";
    $alarmInfo{"18060014"} = "LP3FERobotInterlockErrorOccurred";
    $alarmInfo{"18060015"} = "LP3LOAD/UNLOADSequenceFailed";
    $alarmInfo{"18060016"} = "LP3N2PressureForFOUPPurgeUpperLimitErrorOccurred";
    $alarmInfo{"18060017"} = "LP3N2PressureForFOUPPurgeLowerLimitErrorOccurred";
    $alarmInfo{"18060018"} = "LP3N2ErrorOfFOUPPurgeUnitOccurred";
    $alarmInfo{"18060019"} = "LP3N2PurgeKeyOfFOUPPurgeUnitWasTurnedOff";
    $alarmInfo{"1806001A"} = "LP3N2FlowLimitErrorOfFOUPPurgeUnitOccurred";
    $alarmInfo{"1806001B"} = "LP3N2InterlockErrorOfFOUPPurgeUnitOccurred";
    $alarmInfo{"1806001C"} = "1806001C-Alarm";
    $alarmInfo{"1806001D"} = "1806001D-Alarm";
    $alarmInfo{"1806001E"} = "1806001E-Alarm";
    $alarmInfo{"1806001F"} = "1806001F-Alarm";
    $alarmInfo{"18060020"} = "LP3AMHSTP1ErrorOccurred";
    $alarmInfo{"18060021"} = "LP3AMHSTP2ErrorOccurred";
    $alarmInfo{"18060022"} = "LP3AMHSTP3ErrorOccurred";
    $alarmInfo{"18060023"} = "LP3AMHSTP4ErrorOccurred";
    $alarmInfo{"18060024"} = "LP3AMHSTP5ErrorOccurred";
    $alarmInfo{"18060025"} = "LP3AMHSTP6ErrorOccurred";
    $alarmInfo{"18060026"} = "LP3AMHSEMSOccurred";
    $alarmInfo{"18060027"} = "LP3AMHSLoadPortErrorOccurred";
    $alarmInfo{"18060028"} = "LP3AMHSValidOffErrorOccurred";
    $alarmInfo{"18060029"} = "LP3AMHSPODIsTransferredManually";
    $alarmInfo{"1806002A"} = "LP3AMHSPODNotUnclamped";
    $alarmInfo{"1806002B"} = "LP3AMHSFERobotFailureOccurred";
    $alarmInfo{"1806002C"} = "LP3AMHSCarrierSensorErrorOccurred";
    $alarmInfo{"1806002D"} = "LP3AMHSAutoDisableByLPConfigSetting";
    $alarmInfo{"1806002E"} = "LP3LoadPortStatusIsNotTransferBlocked";
    $alarmInfo{"1806002F"} = "LP3ExecutingManualSequence";
    $alarmInfo{"18060030"} = "LP3ExecutingAutoHandoffSequence";
    $alarmInfo{"18060031"} = "LP3LPConfigIsRunningMode";
    $alarmInfo{"18060032"} = "LP3AMHSRecoverCannotBeDone";
    $alarmInfo{"18060033"} = "LP3AMHSLightCurtainError";
    $alarmInfo{"18060034"} = "LP3AbnormalSignalOfE84WasDetected";
    $alarmInfo{"18060035"} = "LP3Dummy/ProductMismatch";
    $alarmInfo{"18060036"} = "LP3MaterialMismatch";
    $alarmInfo{"18061010"} = "SYN18061010";
    $alarmInfo{"18061012"} = "SYN18061012";
    $alarmInfo{"19060000"} = "SYN19060000";
    $alarmInfo{"19060001"} = "CommunicationTimeout";
    $alarmInfo{"19060002"} = "StatusChangedToIDLE";
    $alarmInfo{"19060003"} = "CommandWasRejected";
    $alarmInfo{"19060004"} = "Stopped";
    $alarmInfo{"19060005"} = "Aborted";
    $alarmInfo{"19060006"} = "NAKCommandError)WasReceived";
    $alarmInfo{"19060007"} = "NAKParameterError)WasReceived";
    $alarmInfo{"19060008"} = "NAKAlarm)WasReceived";
    $alarmInfo{"19060009"} = "StatusIsBusy";
    $alarmInfo{"1906000A"} = "CommandIsDenied";
    $alarmInfo{"1906000B"} = "CarrierIsNotOnTheLoadPort";
    $alarmInfo{"1906000C"} = "StatusIsNotReady";
    $alarmInfo{"1906000D"} = "DataErrorOccurs";
    $alarmInfo{"1906000E"} = "OutOfRangeErrorOccurs";
    $alarmInfo{"1906000F"} = "UnknownECIDErrorOccurs";
    $alarmInfo{"19060010"} = "ACKTimeout";
    $alarmInfo{"19060011"} = "CompletionTimeout";
    $alarmInfo{"19060012"} = "OtherErrorOccurs";
    $alarmInfo{"19060014"} = "FERobotInterlockErrorOccurred";
    $alarmInfo{"19060015"} = "LOAD/UNLOADSequenceFailed";
    $alarmInfo{"19060016"} = "N2PressureForFOUPPurgeUpperLimitErrorOccurred";
    $alarmInfo{"19060017"} = "N2PressureForFOUPPurgeLowerLimitErrorOccurred";
    $alarmInfo{"19060018"} = "N2ErrorOfFOUPPurgeUnitOccurred";
    $alarmInfo{"19060019"} = "N2PurgeKeyOfFOUPPurgeUnitWasTurnedOff";
    $alarmInfo{"1906001A"} = "N2FlowLimitErrorOfFOUPPurgeUnitOccurred";
    $alarmInfo{"1906001B"} = "N2InterlockErrorOfFOUPPurgeUnitOccurred";
    $alarmInfo{"19060020"} = "AMHSTP1ErrorOccurred";
    $alarmInfo{"19060021"} = "AMHSTP2ErrorOccurred";
    $alarmInfo{"19060022"} = "AMHSTP3ErrorOccurred";
    $alarmInfo{"19060023"} = "AMHSTP4ErrorOccurred";
    $alarmInfo{"19060024"} = "AMHSTP5ErrorOccurred";
    $alarmInfo{"19060025"} = "AMHSTP6ErrorOccurred";
    $alarmInfo{"19060026"} = "AMHSEMSOccurred";
    $alarmInfo{"19060027"} = "AMHSLoadPortErrorOccurred";
    $alarmInfo{"19060028"} = "AMHSValidOffErrorOccurred";
    $alarmInfo{"19060029"} = "AMHSPODIsTransferredManually";
    $alarmInfo{"1906002A"} = "AMHSPODNotUnclamped";
    $alarmInfo{"1906002B"} = "AMHSFERobotFailureOccurred";
    $alarmInfo{"1906002C"} = "AMHSCarrierSensorErrorOccurred";
    $alarmInfo{"1906002D"} = "AMHSAutoDisableByLPConfigSetting";
    $alarmInfo{"1906002E"} = "LoadPortStatusIsNotTransferBlocked";
    $alarmInfo{"1906002F"} = "ExecutingManualSequence";
    $alarmInfo{"19060030"} = "ExecutingAutoHandoffSequence";
    $alarmInfo{"19060031"} = "LPConfigIsRunningMode";
    $alarmInfo{"19060032"} = "AMHSRecoverCannotBeDone";
    $alarmInfo{"19060033"} = "AMHSLightCurtainError";
    $alarmInfo{"19060034"} = "AbnormalSignalOfE84WasDetected";
    $alarmInfo{"19060035"} = "Dummy/ProductMismatch";
    $alarmInfo{"19060036"} = "MaterialMismatch";
    $alarmInfo{"19061010"} = "SYN19061010";
    $alarmInfo{"19061012"} = "SYN19061012";
    $alarmInfo{"19061017"} = "SYN19061017";
    $alarmInfo{"1A060001"} = "CID1CommunicationTimeout";
    $alarmInfo{"1A060002"} = "CID1StatusChangedToIDLE";
    $alarmInfo{"1A060003"} = "CID1CommandWasRejected";
    $alarmInfo{"1B060001"} = "CID2CommunicationTimeout";
    $alarmInfo{"1B060002"} = "CID2StatusChangedToIDLE";
    $alarmInfo{"1B060003"} = "CID2CommandWasRejected";
    $alarmInfo{"1C060001"} = "CID3CommunicationTimeout";
    $alarmInfo{"1C060002"} = "CID3StatusChangedToIDLE";
    $alarmInfo{"1C060003"} = "CID3CommandWasRejected";
    $alarmInfo{"1D060001"} = "1D060001";
    $alarmInfo{"1E060000"} = "1E060000";
    $alarmInfo{"1E060002"} = "TMDeviceNetDriverFroze";
    $alarmInfo{"1E06000B"} = "FERobotDriverFroze";
    $alarmInfo{"1E060011"} = "1E060011";
    $alarmInfo{"20060000"} = "20060000";
    $alarmInfo{"20060001"} = "WHCCommunicationTimeout";
    $alarmInfo{"20060002"} = "WHCStatusChangedToIDLE";
    $alarmInfo{"20060003"} = "WHCCommandWasRejected";
    $alarmInfo{"20060004"} = "WHCACKTimeout";
    $alarmInfo{"20060005"} = "WHCCompletionTimeout";
    $alarmInfo{"20060006"} = "WHCControlStatusError";
    $alarmInfo{"20060007"} = "WHCSensorError";
    $alarmInfo{"20060008"} = "WHCSensorUnknown";
    $alarmInfo{"20060009"} = "WHCPressureStatusError";
    $alarmInfo{"2006000A"} = "WHCCommandWasNotContorolledByPumpAlarm";
    $alarmInfo{"2006000B"} = "WHCCommandWasNotContorolledByPumpStop";
    $alarmInfo{"20060011"} = "WHCPressureInterlockErrorOccurred";
    $alarmInfo{"20060014"} = "WHCFERobotInterlockErrorOccurred";
    $alarmInfo{"20060015"} = "WHCBERobotInterlockErrorOccurred";
    $alarmInfo{"20060016"} = "WHCPressureInterlockErrorOccurred";
    $alarmInfo{"20060017"} = "WHCGVInterlockErrorOccurred";
    $alarmInfo{"20060018"} = "WHCWaferInterlockErrorOccurred";
    $alarmInfo{"20060019"} = "WHCFastValveStatusErrorOccurred";
    $alarmInfo{"2006001F"} = "WHCPumpStopped";
    $alarmInfo{"20060020"} = "WHCPumpAlarmOccurred";
    $alarmInfo{"20060021"} = "WHCHighAirDown";
    $alarmInfo{"20060022"} = "WHCCommandIsNotAbleToExecutedBecauseMaintenanceMode";
    $alarmInfo{"20060023"} = "WHCSequenceStopped";
    $alarmInfo{"20060024"} = "WHCSequenceAborted";
    $alarmInfo{"20060025"} = "WHCInterlockErrorOcurred";
    $alarmInfo{"20060026"} = "WHCOtherErrorOccurred";
    $alarmInfo{"20060027"} = "WHC2PSIErrorOccurred";
    $alarmInfo{"20060028"} = "WHCLLCPumpBusy";
    $alarmInfo{"20060029"} = "WHCPressureValueAnd1atmSensorMismatch";
    $alarmInfo{"2006002A"} = "WHCDeviceNetUnitConnectionErrorOccurred";
    $alarmInfo{"2006002B"} = "WHCChamberPressureExceeded95%ThoughTheFastValveIsOpen";
    $alarmInfo{"2006002C"} = "WHCThrottleValvePositionExceededLimitDuringThePressureControl";
    $alarmInfo{"2006002D"} = "WHCN2PressureAlarmOccurred";
    $alarmInfo{"2006002E"} = "WHCHighAirAlarmOccurred";
    $alarmInfo{"20061002"} = "SYN20061002";
    $alarmInfo{"20061006"} = "SYN20061006";
    $alarmInfo{"2010000"} = "GateValveAlarmGV1Cleared";
    $alarmInfo{"2010001"} = "GateValveAlarmGV1Detected";
    $alarmInfo{"2020000"} = "GateValveAlarmGV2Cleared";
    $alarmInfo{"2020001"} = "GateValveAlarmGV2Detected";
    $alarmInfo{"2030000"} = "GateValveAlarmGV3Cleared";
    $alarmInfo{"2030001"} = "GateValveAlarmGV3Detected";
    $alarmInfo{"2040000"} = "GateValveAlarmGV4Cleared";
    $alarmInfo{"2040001"} = "GateValveAlarmGV4Detected";
    $alarmInfo{"2050000"} = "GateValveAlarmGV5Cleared";
    $alarmInfo{"2050001"} = "GateValveAlarmGV5Detected";
    $alarmInfo{"2060000"} = "GateValveAlarmGV6Cleared";
    $alarmInfo{"2060001"} = "GateValveAlarmGV6Detected";
    $alarmInfo{"206000a0"} = "WHCCommandNotContorolledByPumpAlarmClr";
    $alarmInfo{"206000a1"} = "WHCCommandNotContorolledByPumpAlarmDet";
    $alarmInfo{"20600200"} = "WHCPumpAlarmOccurredClr";
    $alarmInfo{"20600201"} = "WHCPumpAlarmOccurredDet";
    $alarmInfo{"206002d0"} = "WHCN2PressureAlarmOccurredClr";
    $alarmInfo{"206002d1"} = "WHCN2PressureAlarmOccurredDet";
    $alarmInfo{"206002e0"} = "WHCHighAirAlarmOccurredClr";
    $alarmInfo{"206002e1"} = "WHCHighAirAlarmOccurredDet";
    $alarmInfo{"2070000"} = "GateValveAlarmGV7Cleared";
    $alarmInfo{"2070001"} = "GateValveAlarmGV7Detected";
    $alarmInfo{"2080000"} = "GateValveAlarmGV8Cleared";
    $alarmInfo{"2080001"} = "GateValveAlarmGV8Detected";
    $alarmInfo{"2090000"} = "GateValveAlarmGV9Cleared";
    $alarmInfo{"2090001"} = "GateValveAlarmGV9Detected";
    $alarmInfo{"20b0000"} = "SealPlateAlarmCleared";
    $alarmInfo{"20b0001"} = "SealPlateAlarmDetected";
    $alarmInfo{"21060000"} = "21060000";
    $alarmInfo{"21060001"} = "CommunicationTimeout";
    $alarmInfo{"21060002"} = "StatusChangedToIDLE";
    $alarmInfo{"21060003"} = "CommandWasRejected";
    $alarmInfo{"21060004"} = "ACKTimeout";
    $alarmInfo{"21060005"} = "CompletionTimeout";
    $alarmInfo{"21060006"} = "ControlStatusError";
    $alarmInfo{"21060007"} = "SensorError";
    $alarmInfo{"21060008"} = "SensorUnknown";
    $alarmInfo{"21060009"} = "PressureStatusError";
    $alarmInfo{"2106000A"} = "CommandWasNotContorolledByPumpAlarm";
    $alarmInfo{"2106000B"} = "CommandWasNotContorolledByPumpStop";
    $alarmInfo{"2106000C"} = "SequenceAborted";
    $alarmInfo{"2106000D"} = "SequencePaused";
    $alarmInfo{"2106000E"} = "PMDisconnected";
    $alarmInfo{"2106000F"} = "WaferInterlockErrorOccurred";
    $alarmInfo{"21060010"} = "TransferInterlockErrorOccurred";
    $alarmInfo{"21060011"} = "PressureInterlockErrorOccurred";
    $alarmInfo{"21060014"} = "FERobotInterlockErrorOccurred";
    $alarmInfo{"21060015"} = "BERobotInterlockErrorOccurred";
    $alarmInfo{"21060016"} = "PressureInterlockErrorOccurred";
    $alarmInfo{"21060017"} = "GVInterlockErrorOccurred";
    $alarmInfo{"21060018"} = "WaferInterlockErrorOccurred";
    $alarmInfo{"21060019"} = "FastValveStatusErrorOccurred";
    $alarmInfo{"2106001F"} = "PumpStopped";
    $alarmInfo{"21060020"} = "PumpAlarmOccurred";
    $alarmInfo{"21060021"} = "HighAirDown";
    $alarmInfo{"21060022"} = "CommandIsNotAbleToExecutedBecauseMaintenanceMode";
    $alarmInfo{"21060023"} = "SequenceStopped";
    $alarmInfo{"21060024"} = "SequenceAborted";
    $alarmInfo{"21060025"} = "InterlockErrorOcurred";
    $alarmInfo{"21060026"} = "OtherErrorOccurred";
    $alarmInfo{"21060027"} = "2PSIErrorOccurred";
    $alarmInfo{"21060028"} = "LLCPumpBusy";
    $alarmInfo{"21060029"} = "PressureValueAnd1atmSensorMismatch";
    $alarmInfo{"2106002A"} = "DeviceNetUnitConnectionErrorOccurred";
    $alarmInfo{"21061002"} = "SYN21061002";
    $alarmInfo{"216000a0"} = "LLC1CommandNotContorolledByPumpAlarmClr";
    $alarmInfo{"216000a1"} = "LLC1CommandNotContorolledByPumpAlarmDet";
    $alarmInfo{"21600200"} = "LLC1PumpAlarmOccurredClr";
    $alarmInfo{"21600201"} = "LLC1PumpAlarmOccurredDet";
    $alarmInfo{"226000a0"} = "LLC2CommandNotContorolledByPumpAlarmClr";
    $alarmInfo{"226000a1"} = "LLC2CommandNotContorolledByPumpAlarmDet";
    $alarmInfo{"22600200"} = "LLC2PumpAlarmOccurredClr";
    $alarmInfo{"22600201"} = "LLC2PumpAlarmOccurredDet";
    $alarmInfo{"23060000"} = "23060000";
    $alarmInfo{"23060001"} = "CommunicationTimeout";
    $alarmInfo{"23060002"} = "StatusChangedToIDLE";
    $alarmInfo{"23060003"} = "CommandWasRejected";
    $alarmInfo{"23060004"} = "ACKTimeout";
    $alarmInfo{"23060005"} = "CompletionTimeout";
    $alarmInfo{"23060006"} = "ControlStatusError";
    $alarmInfo{"23060007"} = "SensorError";
    $alarmInfo{"23060008"} = "SensorUnknown";
    $alarmInfo{"23060009"} = "PressureStatusError";
    $alarmInfo{"2306000A"} = "CommandWasNotContorolledByPumpAlarm";
    $alarmInfo{"2306000B"} = "CommandWasNotContorolledByPumpStop";
    $alarmInfo{"2306000C"} = "SequenceAborted";
    $alarmInfo{"2306000D"} = "SequencePaused";
    $alarmInfo{"2306000E"} = "PMDisconnected";
    $alarmInfo{"2306000F"} = "WaferInterlockErrorOccurred";
    $alarmInfo{"23060010"} = "TransferInterlockErrorOccurred";
    $alarmInfo{"23060011"} = "PressureInterlockErrorOccurred";
    $alarmInfo{"23060014"} = "FERobotInterlockErrorOccurred";
    $alarmInfo{"23060015"} = "BERobotInterlockErrorOccurred";
    $alarmInfo{"23060016"} = "PressureInterlockErrorOccurred";
    $alarmInfo{"23060017"} = "GVInterlockErrorOccurred";
    $alarmInfo{"23060018"} = "WaferInterlockErrorOccurred";
    $alarmInfo{"23060019"} = "FastValveStatusErrorOccurred";
    $alarmInfo{"2306001F"} = "PumpStopped";
    $alarmInfo{"23060020"} = "PumpAlarmOccurred";
    $alarmInfo{"23060021"} = "HighAirDown";
    $alarmInfo{"23060022"} = "CommandIsNotAbleToExecutedBecauseMaintenanceMode";
    $alarmInfo{"23060023"} = "SequenceStopped";
    $alarmInfo{"23060024"} = "SequenceAborted";
    $alarmInfo{"23060025"} = "InterlockErrorOcurred";
    $alarmInfo{"23060026"} = "OtherErrorOccurred";
    $alarmInfo{"23060027"} = "2PSIErrorOccurred";
    $alarmInfo{"23060028"} = "LLCPumpBusy";
    $alarmInfo{"23060029"} = "PressureValueAnd1atmSensorMismatch";
    $alarmInfo{"2306002A"} = "DeviceNetUnitConnectionErrorOccurred";
    $alarmInfo{"23061002"} = "SYN23061002";
    $alarmInfo{"236000a0"} = "LLC3CommandNotContorolledByPumpAlarmClr";
    $alarmInfo{"236000a1"} = "LLC3CommandNotContorolledByPumpAlarmDet";
    $alarmInfo{"23600200"} = "LLC3PumpAlarmOccurredClr";
    $alarmInfo{"23600201"} = "LLC3PumpAlarmOccurredDet";
    $alarmInfo{"246000a0"} = "LLC4CommandNotContorolledByPumpAlarmClr";
    $alarmInfo{"246000a1"} = "LLC4CommandNotContorolledByPumpAlarmDet";
    $alarmInfo{"24600200"} = "LLC4PumpAlarmOccurredClr";
    $alarmInfo{"24600201"} = "LLC4PumpAlarmOccurredDet";
    $alarmInfo{"256000a0"} = "LLCCommandNotContorolledByPumpAlarmClr";
    $alarmInfo{"256000a1"} = "LLCCommandNotContorolledByPumpAlarmDet";
    $alarmInfo{"25600200"} = "LLCPumpAlarmOccurredClr";
    $alarmInfo{"25600201"} = "LLCPumpAlarmOccurredDet";
    $alarmInfo{"266009d0"} = "LLArm1ThisWarningOccursBeforeOverloadAlarmsAClr";
    $alarmInfo{"266009d1"} = "LLArm1ThisWarningOccursBeforeOverloadAlarmsADet";
    $alarmInfo{"276009d0"} = "LLArm2ThisWarningOccursBeforeOverloadAlarmsAClr";
    $alarmInfo{"276009d1"} = "LLArm2ThisWarningOccursBeforeOverloadAlarmsADet";
    $alarmInfo{"28060000"} = "SYN28060000";
    $alarmInfo{"29060000"} = "SYN29060000";
    $alarmInfo{"29060001"} = "CommunicationTimeout";
    $alarmInfo{"29060002"} = "StatusChangedToIDLE";
    $alarmInfo{"29060003"} = "CommandWasRejected";
    $alarmInfo{"29060004"} = "NAK(alarm)WasReceived";
    $alarmInfo{"29060005"} = "StatusIsBusy";
    $alarmInfo{"29060006"} = "NAK(parameterError)WasReceived";
    $alarmInfo{"29060007"} = "ACKTimeout(3Sec)";
    $alarmInfo{"29060008"} = "MovementTimeout(60Sec)";
    $alarmInfo{"29060009"} = "Aborted";
    $alarmInfo{"2906000A"} = "Stopped";
    $alarmInfo{"2906000B"} = "ErrorEnd";
    $alarmInfo{"2906000C"} = "ChangeToTeachingMode";
    $alarmInfo{"2906000D"} = "EMSStop";
    $alarmInfo{"2906000E"} = "PowerFailOccurred";
    $alarmInfo{"2906000F"} = "NotchWasNotAbleToBeDetected";
    $alarmInfo{"29060010"} = "BatteryVoltageLow";
    $alarmInfo{"29060011"} = "RobotInterlockErrorOccurred";
    $alarmInfo{"29060012"} = "WaferGapLimitOver";
    $alarmInfo{"2A060000"} = "SYN2A060000";
    $alarmInfo{"2A060001"} = "SYN2A060001";
    $alarmInfo{"2A060002"} = "SYN2A060002";
    $alarmInfo{"2A06000B"} = "SYN2A06000B";
    $alarmInfo{"2B060000"} = "SYN2B060000";
    $alarmInfo{"2C060000"} = "SYN2C060000";
    $alarmInfo{"2D060000"} = "TM-EFEM.2D060000";
    $alarmInfo{"2D060001"} = "CommunicationTimeout";
    $alarmInfo{"2D060002"} = "StatusChangedToIDLE";
    $alarmInfo{"2D060003"} = "CommandWasRejected";
    $alarmInfo{"2D061004"} = "Aborted";
    $alarmInfo{"2D061005"} = "CommandCompletionTimeoutOccurred";
    $alarmInfo{"2D061006"} = "DeviceNetUnitConnectionErrorOccurred";
    $alarmInfo{"2D061007"} = "O2ConcentrationOfTheEFEMLowerThanAnAllowableValue(19.5%)";
    $alarmInfo{"2D061008"} = "O2ConcentrationSensorOfTheEFEMIsAbnormal";
    $alarmInfo{"2D061009"} = "H2OConcentrationSensorOfTheEFEMIsAbnormal";
    $alarmInfo{"2D06100A"} = "N2PurgeOfTheEFEMIsNotEnable";
    $alarmInfo{"2D06100B"} = "CDAFlowOfTheEFEMIsAbnormal";
    $alarmInfo{"2D06100C"} = "ExhaustPressureOfTheEFEMIsAbnormal";
    $alarmInfo{"2D06100D"} = "O2OrH2OConcentrationOfTheEFEMIsAbnormal";
    $alarmInfo{"2D06100E"} = "FFUIsRunning";
    $alarmInfo{"2D06100F"} = "EFEMDifferentialPressureHighErrorOccurred";
    $alarmInfo{"2D061010"} = "CDASupplyRegulatorPressureOfTheEFEMDecreased";
    $alarmInfo{"2D061011"} = "N2-InValveInput/outputStateOfTheEFEMIsMismatched";
    $alarmInfo{"2D061012"} = "N2SupplyRegulatorPressureOfTheEFEMDecreased";
    $alarmInfo{"2D061013"} = "LLCLid(accessCover)Opens";
    $alarmInfo{"2D061014"} = "LeakCheckOfTheEFEMIsNotCompleted";
    $alarmInfo{"2D062000"} = "O2ConcentrationOfTheEFEMExceedsLimit(1)InTheN2Mode.(Monitoring)";
    $alarmInfo{"2D062001"} = "H2OConcentrationOfTheEFEMExceedsLimit(1)InTheN2Mode.(Monitoring)";
    $alarmInfo{"2D062002"} = "CDAFlowOfTheEFEMIsAbnormal.(Monitoring)";
    $alarmInfo{"2D062003"} = "O2ConcentrationSensorOfTheEFEMIsAbnormal.(Monitoring)";
    $alarmInfo{"2D062004"} = "H2OConcentrationSensorOfTheEFEMIsAbnormal.(Monitoring)";
    $alarmInfo{"2D062005"} = "ExhaustPressureOfTheEFEMIsAbnormal.(Monitoring)";
    $alarmInfo{"2D062006"} = "O2ConcentrationOfTheEFEMLowerThanAnAllowableValue(19.5%).(Monitoring)";
    $alarmInfo{"2D062007"} = "N2-InValveInput/outputStateOfTheEFEMIsMismatched.(Monitoring)";
    $alarmInfo{"2D062008"} = "O2ConcentrationOfTheEFEMExceedsLimit(2)InTheN2Mode.(Monitoring)";
    $alarmInfo{"2D062009"} = "H2OConcentrationOfTheEFEMExceedsLimit(2)InTheN2Mode.(Monitoring)";
    $alarmInfo{"2D06200A"} = "DeviceNetUnitConnectionErrorOccurred.(Monitoring)";
    $alarmInfo{"2D06200B"} = "N2PurgeOfTheEFEMIsNotEnable.(Monitoring)";
    $alarmInfo{"2D06200C"} = "EFEMDifferentialPressureHighErrorOccurred.(Monitoring)";
    $alarmInfo{"2D06200D"} = "CDASupplyRegulatorPressureOfTheEFEMDecreased.(Monitoring)";
    $alarmInfo{"2D06200E"} = "N2SupplyRegulatorPressureOfTheEFEMDecreased.(Monitoring)";
    $alarmInfo{"2D06200F"} = "LLCLid(accessCover)Opens.(Monitoring)";
    $alarmInfo{"2D062010"} = "SYN2D062010";
    $alarmInfo{"2D062011"} = "SYN2D062011";
    $alarmInfo{"2D062012"} = "SYN2D062012";
    $alarmInfo{"2D062013"} = "SYN2D062013";
    $alarmInfo{"2D062014"} = "SYN2D062014";
    $alarmInfo{"2D062015"} = "SYN2D062015";
    $alarmInfo{"2D062016"} = "SYN2D062016";
    $alarmInfo{"2D062017"} = "SYN2D062017";
    $alarmInfo{"2D062018"} = "SYN2D062018";
    $alarmInfo{"2D062019"} = "SYN2D062019";
    $alarmInfo{"2D06201A"} = "SYN2D06201A";
    $alarmInfo{"2D06201B"} = "SYN2D06201B";
    $alarmInfo{"2D06201C"} = "SYN2D06201C";
    $alarmInfo{"2D06201D"} = "SYN2D06201D";
    $alarmInfo{"2D06201E"} = "SYN2D06201E";
    $alarmInfo{"2D06201F"} = "SYN2D06201F";
    $alarmInfo{"30060000"} = "30060000";
    $alarmInfo{"30060001"} = "CommunicationTimeout";
    $alarmInfo{"30060002"} = "StatusChangedToIDLE";
    $alarmInfo{"30060003"} = "CommandWasRejected";
    $alarmInfo{"30060004"} = "ACKTimeout";
    $alarmInfo{"30060005"} = "CompletionTimeout";
    $alarmInfo{"30060006"} = "ControlStatusError";
    $alarmInfo{"30060007"} = "SensorError";
    $alarmInfo{"30060008"} = "SensorUnknown";
    $alarmInfo{"30060009"} = "PressureErrorOccurred";
    $alarmInfo{"30060010"} = "TransferInterlockErrorOccurred";
    $alarmInfo{"30060011"} = "PressureInterlockErrorOccurred";
    $alarmInfo{"30060014"} = "FERobotInterlockErrorOccurred";
    $alarmInfo{"30060015"} = "BERobotInterlockErrorOccurred";
    $alarmInfo{"30060016"} = "PressureInterlockErrorOccurred";
    $alarmInfo{"30060017"} = "GVInterlockErrorOccurred";
    $alarmInfo{"30060018"} = "WaferInterlockErrorOccurred";
    $alarmInfo{"3010000"} = "RobotAlarmFERbtCleared";
    $alarmInfo{"3010001"} = "RobotAlarmFERbtDetected";
    $alarmInfo{"3020000"} = "RobotAlarmBERbtCleared";
    $alarmInfo{"3020001"} = "RobotAlarmBERbtDetected";
    $alarmInfo{"3030000"} = "RobotAlarmLLAligner1Cleared";
    $alarmInfo{"3030001"} = "RobotAlarmLLAligner1Detected";
    $alarmInfo{"3040000"} = "RobotAlarmLLAligner2Cleared";
    $alarmInfo{"3040001"} = "RobotAlarmLLAligner2Detected";
    $alarmInfo{"3050000"} = "RobotAlarmAlignerCleared";
    $alarmInfo{"3050001"} = "RobotAlarmAlignerDetected";
    $alarmInfo{"3060000"} = "RobotAlarmMetrologyCleared";
    $alarmInfo{"3060001"} = "RobotAlarmMetrologyDetected";
    $alarmInfo{"31060000"} = "31060000";
    $alarmInfo{"31060001"} = "CommunicationTimeout";
    $alarmInfo{"31060002"} = "StatusChangedToIDLE";
    $alarmInfo{"31060003"} = "CommandWasRejected";
    $alarmInfo{"31060004"} = "ACKTimeout";
    $alarmInfo{"31060005"} = "CompletionTimeout";
    $alarmInfo{"31060006"} = "ControlStatusError";
    $alarmInfo{"31060007"} = "SensorError";
    $alarmInfo{"31060008"} = "SensorUnknown";
    $alarmInfo{"31060009"} = "PressureErrorOccurred";
    $alarmInfo{"31060010"} = "TransferInterlockErrorOccurred";
    $alarmInfo{"31060011"} = "PressureInterlockErrorOccurred";
    $alarmInfo{"31060014"} = "FERobotInterlockErrorOccurred";
    $alarmInfo{"31060015"} = "BERobotInterlockErrorOccurred";
    $alarmInfo{"31060016"} = "PressureInterlockErrorOccurred";
    $alarmInfo{"31060017"} = "GVInterlockErrorOccurred";
    $alarmInfo{"31060018"} = "WaferInterlockErrorOccurred";
    $alarmInfo{"31061006"} = "SYN31061006";
    $alarmInfo{"31061008"} = "SYN31061008";
    $alarmInfo{"32060000"} = "32060000";
    $alarmInfo{"32060001"} = "CommunicationTimeout";
    $alarmInfo{"32060002"} = "StatusChangedToIDLE";
    $alarmInfo{"32060003"} = "CommandWasRejected";
    $alarmInfo{"32060004"} = "ACKTimeout";
    $alarmInfo{"32060005"} = "CompletionTimeout";
    $alarmInfo{"32060006"} = "ControlStatusError";
    $alarmInfo{"32060007"} = "SensorError";
    $alarmInfo{"32060008"} = "SensorUnknown";
    $alarmInfo{"32060009"} = "PressureErrorOccurred";
    $alarmInfo{"32060010"} = "TransferInterlockErrorOccurred";
    $alarmInfo{"32060011"} = "PressureInterlockErrorOccurred";
    $alarmInfo{"32060014"} = "FERobotInterlockErrorOccurred";
    $alarmInfo{"32060015"} = "BERobotInterlockErrorOccurred";
    $alarmInfo{"32060016"} = "PressureInterlockErrorOccurred";
    $alarmInfo{"32060017"} = "GVInterlockErrorOccurred";
    $alarmInfo{"32060018"} = "WaferInterlockErrorOccurred";
    $alarmInfo{"33060000"} = "33060000";
    $alarmInfo{"33060001"} = "CommunicationTimeout";
    $alarmInfo{"33060002"} = "StatusChangedToIDLE";
    $alarmInfo{"33060003"} = "CommandWasRejected";
    $alarmInfo{"33060004"} = "ACKTimeout";
    $alarmInfo{"33060005"} = "CompletionTimeout";
    $alarmInfo{"33060006"} = "ControlStatusError";
    $alarmInfo{"33060007"} = "SensorError";
    $alarmInfo{"33060008"} = "SensorUnknown";
    $alarmInfo{"33060009"} = "PressureErrorOccurred";
    $alarmInfo{"33060010"} = "TransferInterlockErrorOccurred";
    $alarmInfo{"33060011"} = "PressureInterlockErrorOccurred";
    $alarmInfo{"33060014"} = "FERobotInterlockErrorOccurred";
    $alarmInfo{"33060015"} = "BERobotInterlockErrorOccurred";
    $alarmInfo{"33060016"} = "PressureInterlockErrorOccurred";
    $alarmInfo{"33060017"} = "GVInterlockErrorOccurred";
    $alarmInfo{"33060018"} = "WaferInterlockErrorOccurred";
    $alarmInfo{"33061006"} = "SYN33061006";
    $alarmInfo{"33061008"} = "SYN33061008";
    $alarmInfo{"34060000"} = "34060000";
    $alarmInfo{"34060001"} = "CommunicationTimeout";
    $alarmInfo{"34060002"} = "StatusChangedToIDLE";
    $alarmInfo{"34060003"} = "CommandWasRejected";
    $alarmInfo{"34060004"} = "ACKTimeout";
    $alarmInfo{"34060005"} = "CompletionTimeout";
    $alarmInfo{"34060006"} = "ControlStatusError";
    $alarmInfo{"34060007"} = "SensorError";
    $alarmInfo{"34060008"} = "SensorUnknown";
    $alarmInfo{"34060009"} = "PressureErrorOccurred";
    $alarmInfo{"34060010"} = "TransferInterlockErrorOccurred";
    $alarmInfo{"34060011"} = "PressureInterlockErrorOccurred";
    $alarmInfo{"34060014"} = "FERobotInterlockErrorOccurred";
    $alarmInfo{"34060015"} = "BERobotInterlockErrorOccurred";
    $alarmInfo{"34060016"} = "PressureInterlockErrorOccurred";
    $alarmInfo{"34060017"} = "GVInterlockErrorOccurred";
    $alarmInfo{"34060018"} = "WaferInterlockErrorOccurred";
    $alarmInfo{"35060000"} = "UK.35060000";
    $alarmInfo{"35060005"} = "UK.35060005";
    $alarmInfo{"35060008"} = "UK.35060008";
    $alarmInfo{"35060015"} = "UK.35060015";
    $alarmInfo{"35061006"} = "SYN35061006";
    $alarmInfo{"36060000"} = "UK.36060000";
    $alarmInfo{"36060005"} = "UK.36060005";
    $alarmInfo{"36060008"} = "UK.36060008";
    $alarmInfo{"36060016"} = "UK.36060016";
    $alarmInfo{"37060000"} = "UK.37060000";
    $alarmInfo{"37060001"} = "CommunicationTimeout";
    $alarmInfo{"37060002"} = "StatusChangedToIDLE";
    $alarmInfo{"37060003"} = "CommandWasRejected";
    $alarmInfo{"37060004"} = "ACKTimeout";
    $alarmInfo{"37060005"} = "CompletionTimeout";
    $alarmInfo{"37060006"} = "ControlStatusError";
    $alarmInfo{"37060007"} = "SensorError";
    $alarmInfo{"37060008"} = "SensorUnknown";
    $alarmInfo{"37060009"} = "PressureErrorOccurred";
    $alarmInfo{"37060010"} = "TransferInterlockErrorOccurred";
    $alarmInfo{"37060011"} = "PressureInterlockErrorOccurred";
    $alarmInfo{"37060014"} = "FERobotInterlockErrorOccurred";
    $alarmInfo{"37060015"} = "BERobotInterlockErrorOccurred";
    $alarmInfo{"37060016"} = "PressureInterlockErrorOccurred";
    $alarmInfo{"37060017"} = "GVInterlockErrorOccurred";
    $alarmInfo{"37060018"} = "WaferInterlockErrorOccurred";
    $alarmInfo{"38060003"} = "UIOLightFailureOccursInUPS";
    $alarmInfo{"38060004"} = "UIOSeriousFailureOccursInUPS";
    $alarmInfo{"38060005"} = "UIOIonizerErrorOccurred";
    $alarmInfo{"38060006"} = "UIOFFUErrorOccurred";
    $alarmInfo{"38060007"} = "UIOFFUDifferentialPressureErrorOccurred";
    $alarmInfo{"38060008"} = "UIOFFULeftFan1SpeedErrorOccurred";
    $alarmInfo{"38060009"} = "UIOCoolingWaterFaultOccurred";
    $alarmInfo{"3806000A"} = "UIOHighAirDown";
    $alarmInfo{"3806000B"} = "UION2PressureErrorOccurred";
    $alarmInfo{"38060010"} = "UIOFEPanelInterlockDisabled";
    $alarmInfo{"38060011"} = "UIOFEPanelOpen";
    $alarmInfo{"38060012"} = "UIOThePowerFailureOccurred";
    $alarmInfo{"38060013"} = "UIOTheFirstPowerFailureEventReceived";
    $alarmInfo{"38060014"} = "UIOTheSecondPowerFailureEventReceived";
    $alarmInfo{"38060019"} = "UIOFFULeftFan2SpeedErrorOccurred";
    $alarmInfo{"3806001A"} = "UIOFFURightFan1SpeedErrorOccurred";
    $alarmInfo{"3806001B"} = "UIOFFURightFan2SpeedErrorOccurred";
    $alarmInfo{"3806001C"} = "UIOPowerCabinetSignalErrorOccurred";
    $alarmInfo{"39060000"} = "39060000";
    $alarmInfo{"3C060000"} = "3C060000";
    $alarmInfo{"3C060001"} = "ALLFRCommunicationTimeout";
    $alarmInfo{"3C060002"} = "ALLFRStatusChangedToIDLE";
    $alarmInfo{"3C060003"} = "ALLFRCommandWasRejected";
    $alarmInfo{"3C060004"} = "ALLFRAborted";
    $alarmInfo{"3C060005"} = "ALLFRACKTimeout3Sec)";
    $alarmInfo{"3C060006"} = "ALLFRMovementTimeout60Sec)";
    $alarmInfo{"3C060007"} = "ALLFRReplyError";
    $alarmInfo{"3C060008"} = "ALLFRTheStatusOfTheEmergencyStopAlarmInput)WasReceived";
    $alarmInfo{"3C060009"} = "ALLFRTheStatusOfTheCommandErrorOccurringWasReceived";
    $alarmInfo{"3C06000A"} = "ALLFRTheStatusOfTheSensorErrorOccurringWasReceived";
    $alarmInfo{"3C06000B"} = "ALLFRAxis1StepOutError";
    $alarmInfo{"3C06000C"} = "ALLFRAxis2StepOutError";
    $alarmInfo{"3C06000D"} = "ALLFRAxis3StepOutError";
    $alarmInfo{"3C06000E"} = "ALLFRAxis4StepOutError";
    $alarmInfo{"3C06000F"} = "ALLFRCommandErrorOnRobotController";
    $alarmInfo{"3C060010"} = "ALLFRAxis1BatteryLow";
    $alarmInfo{"3C060011"} = "ALLFRAxis2BatteryLow";
    $alarmInfo{"3C060012"} = "ALLFRAxis3BatteryLow";
    $alarmInfo{"3C060013"} = "ALLFRAxis4BatteryLow";
    $alarmInfo{"3C060014"} = "ALLFRAxis1BatteryError";
    $alarmInfo{"3C060015"} = "ALLFRAxis2BatteryError";
    $alarmInfo{"3C060016"} = "ALLFRAxis3BatteryError";
    $alarmInfo{"3C060017"} = "ALLFRAxis4BatteryError";
    $alarmInfo{"3C060018"} = "ALLFRMovementOutOfRange";
    $alarmInfo{"3C060019"} = "ALLFRGVOrLPInterlockErrorOccurred";
    $alarmInfo{"3C06001A"} = "ALLFRWaferClampError";
    $alarmInfo{"3C06001B"} = "ALLFRChangedToTeachingMode";
    $alarmInfo{"3C06001C"} = "ALLFRAxis1SoftwareLimit";
    $alarmInfo{"3C06001D"} = "ALLFRAxis2SoftwareLimit";
    $alarmInfo{"3C06001E"} = "ALLFRAxis3SoftwareLimit";
    $alarmInfo{"3C06001F"} = "ALLFRAxis4SoftwareLimit";
    $alarmInfo{"3C060020"} = "ALLFRWaferInterlockErrorOccurred";
    $alarmInfo{"3C060021"} = "ALLFRARMIsNotRetractPosition";
    $alarmInfo{"3C060022"} = "ALLFRWaferClamp/unclampTimeout";
    $alarmInfo{"3C060023"} = "ALLFRUnitInterlockErrorOccurred";
    $alarmInfo{"3C060027"} = "ALLFRCommandFormatErrorOccurred";
    $alarmInfo{"3C060028"} = "ALLFRParameterErrorOccurred";
    $alarmInfo{"3C060029"} = "ALLFRUnitErrorOccurred";
    $alarmInfo{"3C06002A"} = "ALLFRCoolingStageDoesNotExist";
    $alarmInfo{"3C06002D"} = "ALLFRWaferExistsInTheLLCBeforePuttingWaferToLLC";
    $alarmInfo{"3C06002E"} = "ALLFRWaferDoesNotExistInTheLLCAfterPuttingWaferToLLC";
    $alarmInfo{"3C06002F"} = "ALLFRWaferDoesNotExistInTheLLCBeforeGettingWaferFromLLC";
    $alarmInfo{"3C060030"} = "ALLFRWaferExistsInTheLLCAfterGettingWaferFromLLC";
    $alarmInfo{"3C060031"} = "ALLFRAxis1PositionGapError";
    $alarmInfo{"3C060032"} = "ALLFRAxis2PositionGapError";
    $alarmInfo{"3C060033"} = "ALLFRAxis3PositionGapError";
    $alarmInfo{"3C060034"} = "ALLFRAxisZPositionGapError";
    $alarmInfo{"3C060035"} = "ALLFRAxis1AdjustError";
    $alarmInfo{"3C060036"} = "ALLFRAxis2AdjustError";
    $alarmInfo{"3C060037"} = "ALLFRAxis3AdjustError";
    $alarmInfo{"3C060038"} = "ALLFRUnitUndefined";
    $alarmInfo{"3C060039"} = "ALLFRNAKBUSY)WasReceived";
    $alarmInfo{"3C06003A"} = "ALLFRNAKCheckSumError)WasReceived";
    $alarmInfo{"3C06003B"} = "ALLFRNAKT1Timeout)WasReceived";
    $alarmInfo{"3C06003C"} = "ALLFRNAKCMD:commandError)WasReceived";
    $alarmInfo{"3C06003D"} = "ALLFRNAKPRM:parameterError)WasReceived";
    $alarmInfo{"3C06003E"} = "ALLFRNAKWasReceived.TheCauseIsUncertainOutsideTheManualDescriptionR";
    $alarmInfo{"3C06003F"} = "ALLFRMessageIDMesID)OfAPrimaryResponseIsNotCorresponding";
    $alarmInfo{"3D060000"} = "3D060000";
    $alarmInfo{"3D060001"} = "ALLBRCommunicationTimeout";
    $alarmInfo{"3D060002"} = "ALLBRStatusChangedToIDLE";
    $alarmInfo{"3D060003"} = "ALLBRCommandWasRejected";
    $alarmInfo{"3D060004"} = "ALLBRAborted";
    $alarmInfo{"3D060005"} = "ALLBRACKTimeout3Sec)";
    $alarmInfo{"3D060006"} = "ALLBRMovementTimeout60Sec)";
    $alarmInfo{"3D060007"} = "ALLBRReplyError";
    $alarmInfo{"3D060008"} = "ALLBRTheStatusOfTheEmergencyStopAlarmInput)WasReceived";
    $alarmInfo{"3D060009"} = "ALLBRTheStatusOfTheCommandErrorOccurringWasReceived";
    $alarmInfo{"3D06000A"} = "ALLBRTheStatusOfTheSensorErrorOccurringWasReceived";
    $alarmInfo{"3D06000B"} = "ALLBRAxis1StepOutError";
    $alarmInfo{"3D06000C"} = "ALLBRAxis2StepOutError";
    $alarmInfo{"3D06000D"} = "ALLBRAxis3StepOutError";
    $alarmInfo{"3D06000E"} = "ALLBRAxis4StepOutError";
    $alarmInfo{"3D06000F"} = "ALLBRCommandErrorOnRobotController";
    $alarmInfo{"3D060010"} = "ALLBRAxis1BatteryLow";
    $alarmInfo{"3D060011"} = "ALLBRAxis2BatteryLow";
    $alarmInfo{"3D060012"} = "ALLBRAxis3BatteryLow";
    $alarmInfo{"3D060013"} = "ALLBRAxis4BatteryLow";
    $alarmInfo{"3D060014"} = "ALLBRAxis1BatteryError";
    $alarmInfo{"3D060015"} = "ALLBRAxis2BatteryError";
    $alarmInfo{"3D060016"} = "ALLBRAxis3BatteryError";
    $alarmInfo{"3D060017"} = "ALLBRAxis4BatteryError";
    $alarmInfo{"3D060018"} = "ALLBRMovementOutOfRange";
    $alarmInfo{"3D060019"} = "ALLBRGVInterlockErrorOccurred";
    $alarmInfo{"3D06001A"} = "ALLBRWaferClampError";
    $alarmInfo{"3D06001B"} = "ALLBRChangeToTeachingMode";
    $alarmInfo{"3D06001C"} = "ALLBRAxis1SoftwareLimit";
    $alarmInfo{"3D06001D"} = "ALLBRAxis2SoftwareLimit";
    $alarmInfo{"3D06001E"} = "ALLBRAxis3SoftwareLimit";
    $alarmInfo{"3D06001F"} = "ALLBRAxis4SoftwareLimit";
    $alarmInfo{"3D060020"} = "ALLBRWaferInterlockErrorOccurred";
    $alarmInfo{"3D060021"} = "ALLBRARMIsNotRetractPosition";
    $alarmInfo{"3D060022"} = "ALLBRWaferClamp/unclampTimeout";
    $alarmInfo{"3D060023"} = "ALLBRUnitInterlockErrorOccurred";
    $alarmInfo{"3D060024"} = "ALLBREncoderCommunicationErrorOccurred";
    $alarmInfo{"3D060025"} = "ALLBRMotorPowerFailed";
    $alarmInfo{"3D060026"} = "ALLBREncoderReadErrorOccurred";
    $alarmInfo{"3D060028"} = "ALLBRParameterErrorOccurred";
    $alarmInfo{"3D06002B"} = "ALLBRSusceptorInterlockErrorOccurred.SusceptorIsNotDown";
    $alarmInfo{"3D06002C"} = "ALLBRGVInterlockErrorOccurred.GVIsNotOpen";
    $alarmInfo{"3D06002D"} = "ALLBRWaferExistsInTheLLCBeforePuttingWaferToLLC";
    $alarmInfo{"3D06002E"} = "ALLBRWaferDoesNotExistInTheLLCAfterPuttingWaferToLLC";
    $alarmInfo{"3D06002F"} = "ALLBRWaferDoesNotExistInTheLLCBeforeGettingWaferFromLLC";
    $alarmInfo{"3D060030"} = "ALLBRWaferExistsInTheLLCAfterGettingWaferFromLLC";
    $alarmInfo{"3D060031"} = "ALLBRExceedTheLimitsOfPositionAdjustData";
    $alarmInfo{"3D060032"} = "ALLBRPBCWaferSensorAlarmOccurred";
    $alarmInfo{"3D060033"} = "ALLBRWaferExistsOnTheArmByTheSensorCheckOfArmFrontSideBeforeGettingWafer";
    $alarmInfo{"3D060034"} = "ALLBRWaferExistsOnTheArmByTheSensorCheckOfArmElbowSideBeforeGettingWafer";
    $alarmInfo{"3D060035"} = "ALLBRWaferDoesNotExistOnTheArmByTheSensorCheckOfArmFrontSideAfterGettingWafer";
    $alarmInfo{"3D060036"} = "ALLBRWaferDoesNotExistOnTheArmByTheSensorCheckOfArmElbowSideAfterGettingWafer";
    $alarmInfo{"3D060037"} = "ALLBRWaferDoesNotExistOnTheArmByTheSensorCheckOfArmFrontSideBeforePuttingWafer";
    $alarmInfo{"3D060038"} = "ALLBRWaferDoesNotExistOnTheArmByTheSensorCheckOfArmElbowSideBeforePuttingWafer";
    $alarmInfo{"3D060039"} = "ALLBRWaferExistsOnTheArmByTheSensorCheckOfArmFrontSideAfterPuttingWafer";
    $alarmInfo{"3D06003A"} = "ALLBRWaferExistsOnTheArmByTheSensorCheckOfArmElbowSideAfterPuttingWafer";
    $alarmInfo{"3D06003B"} = "ALLBRTheArmSensorErrorOccursWhenTheWaferClamperIsNothing";
    $alarmInfo{"3D06003C"} = "ALLBRUnitErrorOccurred";
    $alarmInfo{"3D06003D"} = "ALLBRAWCCalibrationDoesNotComplete";
    $alarmInfo{"3D06003E"} = "ALLBRAWCSavingDoesNotComplete";
    $alarmInfo{"3D06003F"} = "ALLBRGetFailed,WaferNotSensedOnBERobot";
    $alarmInfo{"3D060040"} = "ALLBRPutFailed,WaferStillSensedOnBERobot";
    $alarmInfo{"3d600320"} = "TMBERBPBCWaferSensorAlarmOccurredClr";
    $alarmInfo{"3d600321"} = "TMBERBPBCWaferSensorAlarmOccurredDet";
    $alarmInfo{"3e6009d0"} = "TMLLRB1ThisWarningOccursBeforeOverloadAlarmsAClr";
    $alarmInfo{"3e6009d1"} = "TMLLRB1ThisWarningOccursBeforeOverloadAlarmsADet";
    $alarmInfo{"3f6009d0"} = "TMLLRB2ThisWarningOccursBeforeOverloadAlarmsAClr";
    $alarmInfo{"3f6009d1"} = "TMLLRB2ThisWarningOccursBeforeOverloadAlarmsADet";
    $alarmInfo{"40060000"} = "40060000";
    $alarmInfo{"40060001"} = "PM1ALLWatchDriverFroze";
    $alarmInfo{"40060002"} = "PM1ALLPMDeviceNetDriverFroze";
    $alarmInfo{"40060003"} = "PM1ALLADSDriverFroze";
    $alarmInfo{"40060004"} = "PM1ALLTemparatureDriverFroze";
    $alarmInfo{"40060005"} = "PM1ALLPMDeviceNetDIODriverFroze";
    $alarmInfo{"40060006"} = "PM1ALLPMSEQDriverFroze";
    $alarmInfo{"40060007"} = "PM1ALLPMDeviceNetAIODriverFroze";
    $alarmInfo{"40060008"} = "PM1ALLPMRecipeExecutorFroze";
    $alarmInfo{"40060009"} = "PM1ALLSusceptorControlDriverFroze";
    $alarmInfo{"4006000A"} = "PM1ALLPressurePIDControlDriverFroze";
    $alarmInfo{"4006000B"} = "PM1ALLPulsingEngineFroze";
    $alarmInfo{"4006000E"} = "PM1ALLStepTimeError";
    $alarmInfo{"40060010"} = "PM1ALLHSEControlDriverFroze";
    $alarmInfo{"40060020"} = "PM1ALLFASTLOOP:Error";
    $alarmInfo{"40060021"} = "PM1ALLFASTLOOP:CIF:DualPortMemoryIsNull";
    $alarmInfo{"40060022"} = "PM1ALLFASTLOOP:DeviceNet:WatchDogError";
    $alarmInfo{"40060023"} = "PM1ALLFASTLOOP:DeviceNet:CommunicationStateOff-line";
    $alarmInfo{"40060024"} = "PM1ALLFASTLOOP:DeviceNet:CommunicationStateStop";
    $alarmInfo{"40060025"} = "PM1ALLFASTLOOP:DeviceNet:CommunicationStateClear";
    $alarmInfo{"40060026"} = "PM1ALLFASTLOOP:DeviceNet:FatalError";
    $alarmInfo{"40060027"} = "PM1ALLFASTLOOP:DeviceNet:BUSError";
    $alarmInfo{"40060028"} = "PM1ALLFASTLOOP:DeviceNet:BUSOff";
    $alarmInfo{"40060029"} = "PM1ALLFASTLOOP:DeviceNet:NoExchange";
    $alarmInfo{"4006002A"} = "PM1ALLFASTLOOP:DeviceNet:AutoClearError";
    $alarmInfo{"4006002B"} = "PM1ALLFASTLOOP:DeviceNet:DuplicateMAC-ID";
    $alarmInfo{"4006002C"} = "PM1ALLFASTLOOP:DeviceNet:HostNotReady";
    $alarmInfo{"4006002D"} = "PM1ALLFASTLOOP:Unknown";
    $alarmInfo{"4006002E"} = "PM1ALLFASTLOOP:Unknown";
    $alarmInfo{"4006002F"} = "PM1ALLFASTLOOP:Unknown";
    $alarmInfo{"40060030"} = "PM1ALLFASTLOOP:MAC-ID1:DeviceGuardingFailed,AfterDeviceWasOperational";
    $alarmInfo{"40060031"} = "PM1ALLFASTLOOP:MAC-ID1:DeviceAccessTimeout";
    $alarmInfo{"40060032"} = "PM1ALLFASTLOOP:MAC-ID1:DeviceRejectsAccessWithUnknownErrorCode";
    $alarmInfo{"40060033"} = "PM1ALLFASTLOOP:MAC-ID1:DeviceResponseInAllocationPhaseWithConnectionError";
    $alarmInfo{"40060034"} = "PM1ALLFASTLOOP:MAC-ID1:ProducedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"40060035"} = "PM1ALLFASTLOOP:MAC-ID1:ConsumedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"40060036"} = "PM1ALLFASTLOOP:MAC-ID1:DeviceServiceResponseTelegramUnknownAndNotHandled";
    $alarmInfo{"40060037"} = "PM1ALLFASTLOOP:MAC-ID1:ConnectionAlreadyInRequest";
    $alarmInfo{"40060038"} = "PM1ALLFASTLOOP:MAC-ID1:NumberOfCAN-messageDataBytesInReadProducedOrConsumedConnectionSizeResponseUnequal4";
    $alarmInfo{"40060039"} = "PM1ALLFASTLOOP:MAC-ID1:PredefinedMaster-slaveConnectionAlreadyExists";
    $alarmInfo{"4006003A"} = "PM1ALLFASTLOOP:MAC-ID1:LengthInPollingDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"4006003B"} = "PM1ALLFASTLOOP:MAC-ID1:SequenceErrorInDevicePollingResponse";
    $alarmInfo{"4006003C"} = "PM1ALLFASTLOOP:MAC-ID1:FragmentErrorInDevicePollingResponse";
    $alarmInfo{"4006003D"} = "PM1ALLFASTLOOP:MAC-ID1:SequenceError2InDevicePollingResponse";
    $alarmInfo{"4006003E"} = "PM1ALLFASTLOOP:MAC-ID1:LengthInBitStrobeDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"4006003F"} = "PM1ALLFASTLOOP:MAC-ID1:SequenceErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"40060040"} = "PM1ALLFASTLOOP:MAC-ID1:FragmentErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"40060041"} = "PM1ALLFASTLOOP:MAC-ID1:SequenceError2InDeviceCOSOrCyclicResponse";
    $alarmInfo{"40060042"} = "PM1ALLFASTLOOP:MAC-ID1:LengthInCOSOrCyclicDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"40060043"} = "PM1ALLFASTLOOP:MAC-ID1:UCMMGroupNotSupported";
    $alarmInfo{"40060044"} = "PM1ALLFASTLOOP:MAC-ID1:UnknownHandshakeModeConfigured";
    $alarmInfo{"40060045"} = "PM1ALLFASTLOOP:MAC-ID1:ConfiguredBaudrateNotSupported";
    $alarmInfo{"40060046"} = "PM1ALLFASTLOOP:MAC-ID1:DeviceMAC-IDOutOfRange";
    $alarmInfo{"40060047"} = "PM1ALLFASTLOOP:MAC-ID1:DuplicateMAC-IDDetected";
    $alarmInfo{"40060048"} = "PM1ALLFASTLOOP:MAC-ID1:DatabaseInTheDeviceHasNoEntriesIncluded";
    $alarmInfo{"40060049"} = "PM1ALLFASTLOOP:MAC-ID1:DoubleMAC-IDConfiguredInternally";
    $alarmInfo{"4006004A"} = "PM1ALLFASTLOOP:MAC-ID1:SizeOfOneDeviceDataSetInvalid";
    $alarmInfo{"4006004B"} = "PM1ALLFASTLOOP:MAC-ID1:OffsetTableForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"4006004C"} = "PM1ALLFASTLOOP:MAC-ID1:ConfigurationTableLengthForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"4006004D"} = "PM1ALLFASTLOOP:MAC-ID1:OffsetTableDoNotCorrespondToI/OConfigurationTable";
    $alarmInfo{"4006004E"} = "PM1ALLFASTLOOP:MAC-ID1:SizeIndicatorOfParameterDataTableCorrupt";
    $alarmInfo{"4006004F"} = "PM1ALLFASTLOOP:MAC-ID1:NumberOfInputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"40060050"} = "PM1ALLFASTLOOP:MAC-ID1:NumberOfOutputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"40060051"} = "PM1ALLFASTLOOP:MAC-ID1:UnknownDataTypeInI/OConfiguration";
    $alarmInfo{"40060052"} = "PM1ALLFASTLOOP:MAC-ID1:DataTypeDoesNotCorrespondToItsConfiguredLength";
    $alarmInfo{"40060053"} = "PM1ALLFASTLOOP:MAC-ID1:ConfiguredOutputOffsetAddressOutOfRange";
    $alarmInfo{"40060054"} = "PM1ALLFASTLOOP:MAC-ID1:ConfiguredInputOffsetAddressOutOfRange";
    $alarmInfo{"40060055"} = "PM1ALLFASTLOOP:MAC-ID1:OnePredefinedConnectionTypeIsUnknown";
    $alarmInfo{"40060056"} = "PM1ALLFASTLOOP:MAC-ID1:MultipleConnectionsDefinedInParallel";
    $alarmInfo{"40060057"} = "PM1ALLFASTLOOP:MAC-ID1:ConfiguredEXP_PCKT_RATELessThenPROD_INHIBIT_TIME";
    $alarmInfo{"40060058"} = "PM1ALLFASTLOOP:MAC-ID1:NoDatabaseFoundOnTheSystem";
    $alarmInfo{"40060059"} = "PM1ALLFASTLOOP:MAC-ID1:DatabaseReadingFailure";
    $alarmInfo{"4006005A"} = "PM1ALLFASTLOOP:MAC-ID1:UserWatchdogFailed";
    $alarmInfo{"4006005B"} = "PM1ALLFASTLOOP:MAC-ID1:NoDataAcknowledgeFromUser";
    $alarmInfo{"4006005C"} = "PM1ALLFASTLOOP:MAC-ID1:Unknown";
    $alarmInfo{"4006005D"} = "PM1ALLFASTLOOP:MAC-ID1:Unknown";
    $alarmInfo{"4006005E"} = "PM1ALLFASTLOOP:MAC-ID1:Unknown";
    $alarmInfo{"4006005F"} = "PM1ALLFASTLOOP:MAC-ID1:Unknown";
    $alarmInfo{"40060060"} = "PM1ALLFASTLOOP:MAC-ID2:DeviceGuardingFailed,AfterDeviceWasOperational";
    $alarmInfo{"40060061"} = "PM1ALLFASTLOOP:MAC-ID2:DeviceAccessTimeout";
    $alarmInfo{"40060062"} = "PM1ALLFASTLOOP:MAC-ID2:DeviceRejectsAccessWithUnknownErrorCode";
    $alarmInfo{"40060063"} = "PM1ALLFASTLOOP:MAC-ID2:DeviceResponseInAllocationPhaseWithConnectionError";
    $alarmInfo{"40060064"} = "PM1ALLFASTLOOP:MAC-ID2:ProducedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"40060065"} = "PM1ALLFASTLOOP:MAC-ID2:ConsumedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"40060066"} = "PM1ALLFASTLOOP:MAC-ID2:DeviceServiceResponseTelegramUnknownAndNotHandled";
    $alarmInfo{"40060067"} = "PM1ALLFASTLOOP:MAC-ID2:ConnectionAlreadyInRequest";
    $alarmInfo{"40060068"} = "PM1ALLFASTLOOP:MAC-ID2:NumberOfCAN-messageDataBytesInReadProducedOrConsumedConnectionSizeResponseUnequal4";
    $alarmInfo{"40060069"} = "PM1ALLFASTLOOP:MAC-ID2:PredefinedMaster-slaveConnectionAlreadyExists";
    $alarmInfo{"4006006A"} = "PM1ALLFASTLOOP:MAC-ID2:LengthInPollingDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"4006006B"} = "PM1ALLFASTLOOP:MAC-ID2:SequenceErrorInDevicePollingResponse";
    $alarmInfo{"4006006C"} = "PM1ALLFASTLOOP:MAC-ID2:FragmentErrorInDevicePollingResponse";
    $alarmInfo{"4006006D"} = "PM1ALLFASTLOOP:MAC-ID2:SequenceError2InDevicePollingResponse";
    $alarmInfo{"4006006E"} = "PM1ALLFASTLOOP:MAC-ID2:LengthInBitStrobeDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"4006006F"} = "PM1ALLFASTLOOP:MAC-ID2:SequenceErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"40060070"} = "PM1ALLFASTLOOP:MAC-ID2:FragmentErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"40060071"} = "PM1ALLFASTLOOP:MAC-ID2:SequenceError2InDeviceCOSOrCyclicResponse";
    $alarmInfo{"40060072"} = "PM1ALLFASTLOOP:MAC-ID2:LengthInCOSOrCyclicDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"40060073"} = "PM1ALLFASTLOOP:MAC-ID2:UCMMGroupNotSupported";
    $alarmInfo{"40060074"} = "PM1ALLFASTLOOP:MAC-ID2:UnknownHandshakeModeConfigured";
    $alarmInfo{"40060075"} = "PM1ALLFASTLOOP:MAC-ID2:ConfiguredBaudrateNotSupported";
    $alarmInfo{"40060076"} = "PM1ALLFASTLOOP:MAC-ID2:DeviceMAC-IDOutOfRange";
    $alarmInfo{"40060077"} = "PM1ALLFASTLOOP:MAC-ID2:DuplicateMAC-IDDetected";
    $alarmInfo{"40060078"} = "PM1ALLFASTLOOP:MAC-ID2:DatabaseInTheDeviceHasNoEntriesIncluded";
    $alarmInfo{"40060079"} = "PM1ALLFASTLOOP:MAC-ID2:DoubleMAC-IDConfiguredInternally";
    $alarmInfo{"4006007A"} = "PM1ALLFASTLOOP:MAC-ID2:SizeOfOneDeviceDataSetInvalid";
    $alarmInfo{"4006007B"} = "PM1ALLFASTLOOP:MAC-ID2:OffsetTableForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"4006007C"} = "PM1ALLFASTLOOP:MAC-ID2:ConfigurationTableLengthForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"4006007D"} = "PM1ALLFASTLOOP:MAC-ID2:OffsetTableDoNotCorrespondToI/OConfigurationTable";
    $alarmInfo{"4006007E"} = "PM1ALLFASTLOOP:MAC-ID2:SizeIndicatorOfParameterDataTableCorrupt";
    $alarmInfo{"4006007F"} = "PM1ALLFASTLOOP:MAC-ID2:NumberOfInputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"40060080"} = "PM1ALLFASTLOOP:MAC-ID2:NumberOfOutputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"40060081"} = "PM1ALLFASTLOOP:MAC-ID2:UnknownDataTypeInI/OConfiguration";
    $alarmInfo{"40060082"} = "PM1ALLFASTLOOP:MAC-ID2:DataTypeDoesNotCorrespondToItsConfiguredLength";
    $alarmInfo{"40060083"} = "PM1ALLFASTLOOP:MAC-ID2:ConfiguredOutputOffsetAddressOutOfRange";
    $alarmInfo{"40060084"} = "PM1ALLFASTLOOP:MAC-ID2:ConfiguredInputOffsetAddressOutOfRange";
    $alarmInfo{"40060085"} = "PM1ALLFASTLOOP:MAC-ID2:OnePredefinedConnectionTypeIsUnknown";
    $alarmInfo{"40060086"} = "PM1ALLFASTLOOP:MAC-ID2:MultipleConnectionsDefinedInParallel";
    $alarmInfo{"40060087"} = "PM1ALLFASTLOOP:MAC-ID2:ConfiguredEXP_PCKT_RATELessThenPROD_INHIBIT_TIME";
    $alarmInfo{"40060088"} = "PM1ALLFASTLOOP:MAC-ID2:NoDatabaseFoundOnTheSystem";
    $alarmInfo{"40060089"} = "PM1ALLFASTLOOP:MAC-ID2:DatabaseReadingFailure";
    $alarmInfo{"4006008A"} = "PM1ALLFASTLOOP:MAC-ID2:UserWatchdogFailed";
    $alarmInfo{"4006008B"} = "PM1ALLFASTLOOP:MAC-ID2:NoDataAcknowledgeFromUser";
    $alarmInfo{"4006008C"} = "PM1ALLFASTLOOP:MAC-ID2:Unknown";
    $alarmInfo{"4006008D"} = "PM1ALLFASTLOOP:MAC-ID2:Unknown";
    $alarmInfo{"4006008E"} = "PM1ALLFASTLOOP:MAC-ID2:Unknown";
    $alarmInfo{"4006008F"} = "PM1ALLFASTLOOP:MAC-ID2:Unknown";
    $alarmInfo{"40060090"} = "PM1ALLFASTLOOP:MAC-ID3:DeviceGuardingFailed,AfterDeviceWasOperational";
    $alarmInfo{"40060091"} = "PM1ALLFASTLOOP:MAC-ID3:DeviceAccessTimeout";
    $alarmInfo{"40060092"} = "PM1ALLFASTLOOP:MAC-ID3:DeviceRejectsAccessWithUnknownErrorCode";
    $alarmInfo{"40060093"} = "PM1ALLFASTLOOP:MAC-ID3:DeviceResponseInAllocationPhaseWithConnectionError";
    $alarmInfo{"40060094"} = "PM1ALLFASTLOOP:MAC-ID3:ProducedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"40060095"} = "PM1ALLFASTLOOP:MAC-ID3:ConsumedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"40060096"} = "PM1ALLFASTLOOP:MAC-ID3:DeviceServiceResponseTelegramUnknownAndNotHandled";
    $alarmInfo{"40060097"} = "PM1ALLFASTLOOP:MAC-ID3:ConnectionAlreadyInRequest";
    $alarmInfo{"40060098"} = "PM1ALLFASTLOOP:MAC-ID3:NumberOfCAN-messageDataBytesInReadProducedOrConsumedConnectionSizeResponseUnequal4";
    $alarmInfo{"40060099"} = "PM1ALLFASTLOOP:MAC-ID3:PredefinedMaster-slaveConnectionAlreadyExists";
    $alarmInfo{"4006009A"} = "PM1ALLFASTLOOP:MAC-ID3:LengthInPollingDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"4006009B"} = "PM1ALLFASTLOOP:MAC-ID3:SequenceErrorInDevicePollingResponse";
    $alarmInfo{"4006009C"} = "PM1ALLFASTLOOP:MAC-ID3:FragmentErrorInDevicePollingResponse";
    $alarmInfo{"4006009D"} = "PM1ALLFASTLOOP:MAC-ID3:SequenceError2InDevicePollingResponse";
    $alarmInfo{"4006009E"} = "PM1ALLFASTLOOP:MAC-ID3:LengthInBitStrobeDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"4006009F"} = "PM1ALLFASTLOOP:MAC-ID3:SequenceErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"400600A0"} = "PM1ALLFASTLOOP:MAC-ID3:FragmentErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"400600A1"} = "PM1ALLFASTLOOP:MAC-ID3:SequenceError2InDeviceCOSOrCyclicResponse";
    $alarmInfo{"400600A2"} = "PM1ALLFASTLOOP:MAC-ID3:LengthInCOSOrCyclicDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"400600A3"} = "PM1ALLFASTLOOP:MAC-ID3:UCMMGroupNotSupported";
    $alarmInfo{"400600A4"} = "PM1ALLFASTLOOP:MAC-ID3:UnknownHandshakeModeConfigured";
    $alarmInfo{"400600A5"} = "PM1ALLFASTLOOP:MAC-ID3:ConfiguredBaudrateNotSupported";
    $alarmInfo{"400600A6"} = "PM1ALLFASTLOOP:MAC-ID3:DeviceMAC-IDOutOfRange";
    $alarmInfo{"400600A7"} = "PM1ALLFASTLOOP:MAC-ID3:DuplicateMAC-IDDetected";
    $alarmInfo{"400600A8"} = "PM1ALLFASTLOOP:MAC-ID3:DatabaseInTheDeviceHasNoEntriesIncluded";
    $alarmInfo{"400600A9"} = "PM1ALLFASTLOOP:MAC-ID3:DoubleMAC-IDConfiguredInternally";
    $alarmInfo{"400600AA"} = "PM1ALLFASTLOOP:MAC-ID3:SizeOfOneDeviceDataSetInvalid";
    $alarmInfo{"400600AB"} = "PM1ALLFASTLOOP:MAC-ID3:OffsetTableForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"400600AC"} = "PM1ALLFASTLOOP:MAC-ID3:ConfigurationTableLengthForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"400600AD"} = "PM1ALLFASTLOOP:MAC-ID3:OffsetTableDoNotCorrespondToI/OConfigurationTable";
    $alarmInfo{"400600AE"} = "PM1ALLFASTLOOP:MAC-ID3:SizeIndicatorOfParameterDataTableCorrupt";
    $alarmInfo{"400600AF"} = "PM1ALLFASTLOOP:MAC-ID3:NumberOfInputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"400600B0"} = "PM1ALLFASTLOOP:MAC-ID3:NumberOfOutputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"400600B1"} = "PM1ALLFASTLOOP:MAC-ID3:UnknownDataTypeInI/OConfiguration";
    $alarmInfo{"400600B2"} = "PM1ALLFASTLOOP:MAC-ID3:DataTypeDoesNotCorrespondToItsConfiguredLength";
    $alarmInfo{"400600B3"} = "PM1ALLFASTLOOP:MAC-ID3:ConfiguredOutputOffsetAddressOutOfRange";
    $alarmInfo{"400600B4"} = "PM1ALLFASTLOOP:MAC-ID3:ConfiguredInputOffsetAddressOutOfRange";
    $alarmInfo{"400600B5"} = "PM1ALLFASTLOOP:MAC-ID3:OnePredefinedConnectionTypeIsUnknown";
    $alarmInfo{"400600B6"} = "PM1ALLFASTLOOP:MAC-ID3:MultipleConnectionsDefinedInParallel";
    $alarmInfo{"400600B7"} = "PM1ALLFASTLOOP:MAC-ID3:ConfiguredEXP_PCKT_RATELessThenPROD_INHIBIT_TIME";
    $alarmInfo{"400600B8"} = "PM1ALLFASTLOOP:MAC-ID3:NoDatabaseFoundOnTheSystem";
    $alarmInfo{"400600B9"} = "PM1ALLFASTLOOP:MAC-ID3:DatabaseReadingFailure";
    $alarmInfo{"400600BA"} = "PM1ALLFASTLOOP:MAC-ID3:UserWatchdogFailed";
    $alarmInfo{"400600BB"} = "PM1ALLFASTLOOP:MAC-ID3:NoDataAcknowledgeFromUser";
    $alarmInfo{"400600BC"} = "PM1ALLFASTLOOP:MAC-ID3:Unknown";
    $alarmInfo{"400600BD"} = "PM1ALLFASTLOOP:MAC-ID3:Unknown";
    $alarmInfo{"400600BE"} = "PM1ALLFASTLOOP:MAC-ID3:Unknown";
    $alarmInfo{"400600BF"} = "PM1ALLFASTLOOP:MAC-ID3:Unknown";
    $alarmInfo{"400600C0"} = "PM1ALLFASTLOOP:MAC-ID4:DeviceGuardingFailed,AfterDeviceWasOperational";
    $alarmInfo{"400600C1"} = "PM1ALLFASTLOOP:MAC-ID4:DeviceAccessTimeout";
    $alarmInfo{"400600C2"} = "PM1ALLFASTLOOP:MAC-ID4:DeviceRejectsAccessWithUnknownErrorCode";
    $alarmInfo{"400600C3"} = "PM1ALLFASTLOOP:MAC-ID4:DeviceResponseInAllocationPhaseWithConnectionError";
    $alarmInfo{"400600C4"} = "PM1ALLFASTLOOP:MAC-ID4:ProducedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"400600C5"} = "PM1ALLFASTLOOP:MAC-ID4:ConsumedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"400600C6"} = "PM1ALLFASTLOOP:MAC-ID4:DeviceServiceResponseTelegramUnknownAndNotHandled";
    $alarmInfo{"400600C7"} = "PM1ALLFASTLOOP:MAC-ID4:ConnectionAlreadyInRequest";
    $alarmInfo{"400600C8"} = "PM1ALLFASTLOOP:MAC-ID4:NumberOfCAN-messageDataBytesInReadProducedOrConsumedConnectionSizeResponseUnequal4";
    $alarmInfo{"400600C9"} = "PM1ALLFASTLOOP:MAC-ID4:PredefinedMaster-slaveConnectionAlreadyExists";
    $alarmInfo{"400600CA"} = "PM1ALLFASTLOOP:MAC-ID4:LengthInPollingDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"400600CB"} = "PM1ALLFASTLOOP:MAC-ID4:SequenceErrorInDevicePollingResponse";
    $alarmInfo{"400600CC"} = "PM1ALLFASTLOOP:MAC-ID4:FragmentErrorInDevicePollingResponse";
    $alarmInfo{"400600CD"} = "PM1ALLFASTLOOP:MAC-ID4:SequenceError2InDevicePollingResponse";
    $alarmInfo{"400600CE"} = "PM1ALLFASTLOOP:MAC-ID4:LengthInBitStrobeDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"400600CF"} = "PM1ALLFASTLOOP:MAC-ID4:SequenceErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"400600D0"} = "PM1ALLFASTLOOP:MAC-ID4:FragmentErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"400600D1"} = "PM1ALLFASTLOOP:MAC-ID4:SequenceError2InDeviceCOSOrCyclicResponse";
    $alarmInfo{"400600D2"} = "PM1ALLFASTLOOP:MAC-ID4:LengthInCOSOrCyclicDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"400600D3"} = "PM1ALLFASTLOOP:MAC-ID4:UCMMGroupNotSupported";
    $alarmInfo{"400600D4"} = "PM1ALLFASTLOOP:MAC-ID4:UnknownHandshakeModeConfigured";
    $alarmInfo{"400600D5"} = "PM1ALLFASTLOOP:MAC-ID4:ConfiguredBaudrateNotSupported";
    $alarmInfo{"400600D6"} = "PM1ALLFASTLOOP:MAC-ID4:DeviceMAC-IDOutOfRange";
    $alarmInfo{"400600D7"} = "PM1ALLFASTLOOP:MAC-ID4:DuplicateMAC-IDDetected";
    $alarmInfo{"400600D8"} = "PM1ALLFASTLOOP:MAC-ID4:DatabaseInTheDeviceHasNoEntriesIncluded";
    $alarmInfo{"400600D9"} = "PM1ALLFASTLOOP:MAC-ID4:DoubleMAC-IDConfiguredInternally";
    $alarmInfo{"400600DA"} = "PM1ALLFASTLOOP:MAC-ID4:SizeOfOneDeviceDataSetInvalid";
    $alarmInfo{"400600DB"} = "PM1ALLFASTLOOP:MAC-ID4:OffsetTableForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"400600DC"} = "PM1ALLFASTLOOP:MAC-ID4:ConfigurationTableLengthForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"400600DD"} = "PM1ALLFASTLOOP:MAC-ID4:OffsetTableDoNotCorrespondToI/OConfigurationTable";
    $alarmInfo{"400600DE"} = "PM1ALLFASTLOOP:MAC-ID4:SizeIndicatorOfParameterDataTableCorrupt";
    $alarmInfo{"400600DF"} = "PM1ALLFASTLOOP:MAC-ID4:NumberOfInputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"400600E0"} = "PM1ALLFASTLOOP:MAC-ID4:NumberOfOutputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"400600E1"} = "PM1ALLFASTLOOP:MAC-ID4:UnknownDataTypeInI/OConfiguration";
    $alarmInfo{"400600E2"} = "PM1ALLFASTLOOP:MAC-ID4:DataTypeDoesNotCorrespondToItsConfiguredLength";
    $alarmInfo{"400600E3"} = "PM1ALLFASTLOOP:MAC-ID4:ConfiguredOutputOffsetAddressOutOfRange";
    $alarmInfo{"400600E4"} = "PM1ALLFASTLOOP:MAC-ID4:ConfiguredInputOffsetAddressOutOfRange";
    $alarmInfo{"400600E5"} = "PM1ALLFASTLOOP:MAC-ID4:OnePredefinedConnectionTypeIsUnknown";
    $alarmInfo{"400600E6"} = "PM1ALLFASTLOOP:MAC-ID4:MultipleConnectionsDefinedInParallel";
    $alarmInfo{"400600E7"} = "PM1ALLFASTLOOP:MAC-ID4:ConfiguredEXP_PCKT_RATELessThenPROD_INHIBIT_TIME";
    $alarmInfo{"400600E8"} = "PM1ALLFASTLOOP:MAC-ID4:NoDatabaseFoundOnTheSystem";
    $alarmInfo{"400600E9"} = "PM1ALLFASTLOOP:MAC-ID4:DatabaseReadingFailure";
    $alarmInfo{"400600EA"} = "PM1ALLFASTLOOP:MAC-ID4:UserWatchdogFailed";
    $alarmInfo{"400600EB"} = "PM1ALLFASTLOOP:MAC-ID4:NoDataAcknowledgeFromUser";
    $alarmInfo{"400600EC"} = "PM1ALLFASTLOOP:MAC-ID4:Unknown";
    $alarmInfo{"400600ED"} = "PM1ALLFASTLOOP:MAC-ID4:Unknown";
    $alarmInfo{"400600EE"} = "PM1ALLFASTLOOP:MAC-ID4:Unknown";
    $alarmInfo{"400600EF"} = "PM1ALLFASTLOOP:MAC-ID4:Unknown";
    $alarmInfo{"400600F0"} = "PM1ALLFASTLOOP:MAC-ID5:DeviceGuardingFailed,AfterDeviceWasOperational";
    $alarmInfo{"400600F1"} = "PM1ALLFASTLOOP:MAC-ID5:DeviceAccessTimeout";
    $alarmInfo{"400600F2"} = "PM1ALLFASTLOOP:MAC-ID5:DeviceRejectsAccessWithUnknownErrorCode";
    $alarmInfo{"400600F3"} = "PM1ALLFASTLOOP:MAC-ID5:DeviceResponseInAllocationPhaseWithConnectionError";
    $alarmInfo{"400600F4"} = "PM1ALLFASTLOOP:MAC-ID5:ProducedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"400600F5"} = "PM1ALLFASTLOOP:MAC-ID5:ConsumedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"400600F6"} = "PM1ALLFASTLOOP:MAC-ID5:DeviceServiceResponseTelegramUnknownAndNotHandled";
    $alarmInfo{"400600F7"} = "PM1ALLFASTLOOP:MAC-ID5:ConnectionAlreadyInRequest";
    $alarmInfo{"400600F8"} = "PM1ALLFASTLOOP:MAC-ID5:NumberOfCAN-messageDataBytesInReadProducedOrConsumedConnectionSizeResponseUnequal4";
    $alarmInfo{"400600F9"} = "PM1ALLFASTLOOP:MAC-ID5:PredefinedMaster-slaveConnectionAlreadyExists";
    $alarmInfo{"400600FA"} = "PM1ALLFASTLOOP:MAC-ID5:LengthInPollingDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"400600FB"} = "PM1ALLFASTLOOP:MAC-ID5:SequenceErrorInDevicePollingResponse";
    $alarmInfo{"400600FC"} = "PM1ALLFASTLOOP:MAC-ID5:FragmentErrorInDevicePollingResponse";
    $alarmInfo{"400600FD"} = "PM1ALLFASTLOOP:MAC-ID5:SequenceError2InDevicePollingResponse";
    $alarmInfo{"400600FE"} = "PM1ALLFASTLOOP:MAC-ID5:LengthInBitStrobeDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"400600FF"} = "PM1ALLFASTLOOP:MAC-ID5:SequenceErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"40060100"} = "PM1ALLFASTLOOP:MAC-ID5:FragmentErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"40060101"} = "PM1ALLFASTLOOP:MAC-ID5:SequenceError2InDeviceCOSOrCyclicResponse";
    $alarmInfo{"40060102"} = "PM1ALLFASTLOOP:MAC-ID5:LengthInCOSOrCyclicDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"40060103"} = "PM1ALLFASTLOOP:MAC-ID5:UCMMGroupNotSupported";
    $alarmInfo{"40060104"} = "PM1ALLFASTLOOP:MAC-ID5:UnknownHandshakeModeConfigured";
    $alarmInfo{"40060105"} = "PM1ALLFASTLOOP:MAC-ID5:ConfiguredBaudrateNotSupported";
    $alarmInfo{"40060106"} = "PM1ALLFASTLOOP:MAC-ID5:DeviceMAC-IDOutOfRange";
    $alarmInfo{"40060107"} = "PM1ALLFASTLOOP:MAC-ID5:DuplicateMAC-IDDetected";
    $alarmInfo{"40060108"} = "PM1ALLFASTLOOP:MAC-ID5:DatabaseInTheDeviceHasNoEntriesIncluded";
    $alarmInfo{"40060109"} = "PM1ALLFASTLOOP:MAC-ID5:DoubleMAC-IDConfiguredInternally";
    $alarmInfo{"4006010A"} = "PM1ALLFASTLOOP:MAC-ID5:SizeOfOneDeviceDataSetInvalid";
    $alarmInfo{"4006010B"} = "PM1ALLFASTLOOP:MAC-ID5:OffsetTableForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"4006010C"} = "PM1ALLFASTLOOP:MAC-ID5:ConfigurationTableLengthForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"4006010D"} = "PM1ALLFASTLOOP:MAC-ID5:OffsetTableDoNotCorrespondToI/OConfigurationTable";
    $alarmInfo{"4006010E"} = "PM1ALLFASTLOOP:MAC-ID5:SizeIndicatorOfParameterDataTableCorrupt";
    $alarmInfo{"4006010F"} = "PM1ALLFASTLOOP:MAC-ID5:NumberOfInputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"40060110"} = "PM1ALLFASTLOOP:MAC-ID5:NumberOfOutputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"40060111"} = "PM1ALLFASTLOOP:MAC-ID5:UnknownDataTypeInI/OConfiguration";
    $alarmInfo{"40060112"} = "PM1ALLFASTLOOP:MAC-ID5:DataTypeDoesNotCorrespondToItsConfiguredLength";
    $alarmInfo{"40060113"} = "PM1ALLFASTLOOP:MAC-ID5:ConfiguredOutputOffsetAddressOutOfRange";
    $alarmInfo{"40060114"} = "PM1ALLFASTLOOP:MAC-ID5:ConfiguredInputOffsetAddressOutOfRange";
    $alarmInfo{"40060115"} = "PM1ALLFASTLOOP:MAC-ID5:OnePredefinedConnectionTypeIsUnknown";
    $alarmInfo{"40060116"} = "PM1ALLFASTLOOP:MAC-ID5:MultipleConnectionsDefinedInParallel";
    $alarmInfo{"40060117"} = "PM1ALLFASTLOOP:MAC-ID5:ConfiguredEXP_PCKT_RATELessThenPROD_INHIBIT_TIME";
    $alarmInfo{"40060118"} = "PM1ALLFASTLOOP:MAC-ID5:NoDatabaseFoundOnTheSystem";
    $alarmInfo{"40060119"} = "PM1ALLFASTLOOP:MAC-ID5:DatabaseReadingFailure";
    $alarmInfo{"4006011A"} = "PM1ALLFASTLOOP:MAC-ID5:UserWatchdogFailed";
    $alarmInfo{"4006011B"} = "PM1ALLFASTLOOP:MAC-ID5:NoDataAcknowledgeFromUser";
    $alarmInfo{"4006011C"} = "PM1ALLFASTLOOP:MAC-ID5:Unknown";
    $alarmInfo{"4006011D"} = "PM1ALLFASTLOOP:MAC-ID5:Unknown";
    $alarmInfo{"4006011E"} = "PM1ALLFASTLOOP:MAC-ID5:Unknown";
    $alarmInfo{"4006011F"} = "PM1ALLFASTLOOP:MAC-ID5:Unknown";
    $alarmInfo{"40060120"} = "PM1ALLFASTLOOP:MAC-ID6:DeviceGuardingFailed,AfterDeviceWasOperational";
    $alarmInfo{"40060121"} = "PM1ALLFASTLOOP:MAC-ID6:DeviceAccessTimeout";
    $alarmInfo{"40060122"} = "PM1ALLFASTLOOP:MAC-ID6:DeviceRejectsAccessWithUnknownErrorCode";
    $alarmInfo{"40060123"} = "PM1ALLFASTLOOP:MAC-ID6:DeviceResponseInAllocationPhaseWithConnectionError";
    $alarmInfo{"40060124"} = "PM1ALLFASTLOOP:MAC-ID6:ProducedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"40060125"} = "PM1ALLFASTLOOP:MAC-ID6:ConsumedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"40060126"} = "PM1ALLFASTLOOP:MAC-ID6:DeviceServiceResponseTelegramUnknownAndNotHandled";
    $alarmInfo{"40060127"} = "PM1ALLFASTLOOP:MAC-ID6:ConnectionAlreadyInRequest";
    $alarmInfo{"40060128"} = "PM1ALLFASTLOOP:MAC-ID6:NumberOfCAN-messageDataBytesInReadProducedOrConsumedConnectionSizeResponseUnequal4";
    $alarmInfo{"40060129"} = "PM1ALLFASTLOOP:MAC-ID6:PredefinedMaster-slaveConnectionAlreadyExists";
    $alarmInfo{"4006012A"} = "PM1ALLFASTLOOP:MAC-ID6:LengthInPollingDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"4006012B"} = "PM1ALLFASTLOOP:MAC-ID6:SequenceErrorInDevicePollingResponse";
    $alarmInfo{"4006012C"} = "PM1ALLFASTLOOP:MAC-ID6:FragmentErrorInDevicePollingResponse";
    $alarmInfo{"4006012D"} = "PM1ALLFASTLOOP:MAC-ID6:SequenceError2InDevicePollingResponse";
    $alarmInfo{"4006012E"} = "PM1ALLFASTLOOP:MAC-ID6:LengthInBitStrobeDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"4006012F"} = "PM1ALLFASTLOOP:MAC-ID6:SequenceErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"40060130"} = "PM1ALLFASTLOOP:MAC-ID6:FragmentErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"40060131"} = "PM1ALLFASTLOOP:MAC-ID6:SequenceError2InDeviceCOSOrCyclicResponse";
    $alarmInfo{"40060132"} = "PM1ALLFASTLOOP:MAC-ID6:LengthInCOSOrCyclicDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"40060133"} = "PM1ALLFASTLOOP:MAC-ID6:UCMMGroupNotSupported";
    $alarmInfo{"40060134"} = "PM1ALLFASTLOOP:MAC-ID6:UnknownHandshakeModeConfigured";
    $alarmInfo{"40060135"} = "PM1ALLFASTLOOP:MAC-ID6:ConfiguredBaudrateNotSupported";
    $alarmInfo{"40060136"} = "PM1ALLFASTLOOP:MAC-ID6:DeviceMAC-IDOutOfRange";
    $alarmInfo{"40060137"} = "PM1ALLFASTLOOP:MAC-ID6:DuplicateMAC-IDDetected";
    $alarmInfo{"40060138"} = "PM1ALLFASTLOOP:MAC-ID6:DatabaseInTheDeviceHasNoEntriesIncluded";
    $alarmInfo{"40060139"} = "PM1ALLFASTLOOP:MAC-ID6:DoubleMAC-IDConfiguredInternally";
    $alarmInfo{"4006013A"} = "PM1ALLFASTLOOP:MAC-ID6:SizeOfOneDeviceDataSetInvalid";
    $alarmInfo{"4006013B"} = "PM1ALLFASTLOOP:MAC-ID6:OffsetTableForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"4006013C"} = "PM1ALLFASTLOOP:MAC-ID6:ConfigurationTableLengthForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"4006013D"} = "PM1ALLFASTLOOP:MAC-ID6:OffsetTableDoNotCorrespondToI/OConfigurationTable";
    $alarmInfo{"4006013E"} = "PM1ALLFASTLOOP:MAC-ID6:SizeIndicatorOfParameterDataTableCorrupt";
    $alarmInfo{"4006013F"} = "PM1ALLFASTLOOP:MAC-ID6:NumberOfInputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"40060140"} = "PM1ALLFASTLOOP:MAC-ID6:NumberOfOutputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"40060141"} = "PM1ALLFASTLOOP:MAC-ID6:UnknownDataTypeInI/OConfiguration";
    $alarmInfo{"40060142"} = "PM1ALLFASTLOOP:MAC-ID6:DataTypeDoesNotCorrespondToItsConfiguredLength";
    $alarmInfo{"40060143"} = "PM1ALLFASTLOOP:MAC-ID6:ConfiguredOutputOffsetAddressOutOfRange";
    $alarmInfo{"40060144"} = "PM1ALLFASTLOOP:MAC-ID6:ConfiguredInputOffsetAddressOutOfRange";
    $alarmInfo{"40060145"} = "PM1ALLFASTLOOP:MAC-ID6:OnePredefinedConnectionTypeIsUnknown";
    $alarmInfo{"40060146"} = "PM1ALLFASTLOOP:MAC-ID6:MultipleConnectionsDefinedInParallel";
    $alarmInfo{"40060147"} = "PM1ALLFASTLOOP:MAC-ID6:ConfiguredEXP_PCKT_RATELessThenPROD_INHIBIT_TIME";
    $alarmInfo{"40060148"} = "PM1ALLFASTLOOP:MAC-ID6:NoDatabaseFoundOnTheSystem";
    $alarmInfo{"40060149"} = "PM1ALLFASTLOOP:MAC-ID6:DatabaseReadingFailure";
    $alarmInfo{"4006014A"} = "PM1ALLFASTLOOP:MAC-ID6:UserWatchdogFailed";
    $alarmInfo{"4006014B"} = "PM1ALLFASTLOOP:MAC-ID6:NoDataAcknowledgeFromUser";
    $alarmInfo{"4006014C"} = "PM1ALLFASTLOOP:MAC-ID6:Unknown";
    $alarmInfo{"4006014D"} = "PM1ALLFASTLOOP:MAC-ID6:Unknown";
    $alarmInfo{"4006014E"} = "PM1ALLFASTLOOP:MAC-ID6:Unknown";
    $alarmInfo{"4006014F"} = "PM1ALLFASTLOOP:MAC-ID6:Unknown";
    $alarmInfo{"40060150"} = "PM1ALLFASTLOOP:CIF/DRIVER:BoardNotInitialized";
    $alarmInfo{"40060151"} = "PM1ALLFASTLOOP:CIF/DRIVER:ErrorInInternalInitState";
    $alarmInfo{"40060152"} = "PM1ALLFASTLOOP:CIF/DRIVER:ErrorInInternalReadState";
    $alarmInfo{"40060153"} = "PM1ALLFASTLOOP:CIF/DRIVER:CommandOnThisChannelIsActive";
    $alarmInfo{"40060154"} = "PM1ALLFASTLOOP:CIF/DRIVER:UnknownParameterInFunctionOccurred";
    $alarmInfo{"40060155"} = "PM1ALLFASTLOOP:CIF/DRIVER:VersionIsIncompatibleWithDLL";
    $alarmInfo{"40060156"} = "PM1ALLFASTLOOP:CIF/DRIVER:ErrorDuringPCISetConfigMode";
    $alarmInfo{"40060157"} = "PM1ALLFASTLOOP:CIF/DRIVER:CouldNotReadPCIDualPortMemoryLength";
    $alarmInfo{"40060158"} = "PM1ALLFASTLOOP:CIF/DRIVER:ErrorDuringPCISetRunMode";
    $alarmInfo{"40060159"} = "PM1ALLFASTLOOP:CIF/DRIVER:DualPortRamNotAccessibleBoardNotFound)";
    $alarmInfo{"4006015A"} = "PM1ALLFASTLOOP:CIF/DRIVER:NotReadyReady";
    $alarmInfo{"4006015B"} = "PM1ALLFASTLOOP:CIF/DRIVER:NotRunningRunning";
    $alarmInfo{"4006015C"} = "PM1ALLFASTLOOP:CIF/DRIVER:WatchdogTestFailed";
    $alarmInfo{"4006015D"} = "PM1ALLFASTLOOP:CIF/DRIVER:SignalsWrongOSVersion";
    $alarmInfo{"4006015E"} = "PM1ALLFASTLOOP:CIF/DRIVER:ErrorInDualPort";
    $alarmInfo{"4006015F"} = "PM1ALLFASTLOOP:CIF/DRIVER:SendMailboxIsFull";
    $alarmInfo{"40060160"} = "PM1ALLFASTLOOP:CIF/DRIVER:PutMessageTimeout";
    $alarmInfo{"40060161"} = "PM1ALLFASTLOOP:CIF/DRIVER:GetMessageTimeout";
    $alarmInfo{"40060162"} = "PM1ALLFASTLOOP:CIF/DRIVER:NoMessageAvailable";
    $alarmInfo{"40060163"} = "PM1ALLFASTLOOP:CIF/DRIVER:RESETCommandTimeout";
    $alarmInfo{"40060164"} = "PM1ALLFASTLOOP:CIF/DRIVER:COM-flagNotSet";
    $alarmInfo{"40060165"} = "PM1ALLFASTLOOP:CIF/DRIVER:I/ODataExchangeFailed";
    $alarmInfo{"40060166"} = "PM1ALLFASTLOOP:CIF/DRIVER:I/ODataExchangeTimeout";
    $alarmInfo{"40060167"} = "PM1ALLFASTLOOP:CIF/DRIVER:I/ODataModeUnknown";
    $alarmInfo{"40060168"} = "PM1ALLFASTLOOP:CIF/DRIVER:FunctionCallFailed";
    $alarmInfo{"40060169"} = "PM1ALLFASTLOOP:CIF/DRIVER:DualPortMemorySizeDiffersFromConfiguration";
    $alarmInfo{"4006016A"} = "PM1ALLFASTLOOP:CIF/DRIVER:StateModeUnknown";
    $alarmInfo{"4006016B"} = "PM1ALLFASTLOOP:CIF/DRIVER:HardwarePortIsUsed";
    $alarmInfo{"4006016C"} = "PM1ALLFASTLOOP:CIF/USER:DriverNotOpenedDeviceDriverNotLoaded)";
    $alarmInfo{"4006016D"} = "PM1ALLFASTLOOP:CIF/USER:CannotConnectWithDevice";
    $alarmInfo{"4006016E"} = "PM1ALLFASTLOOP:CIF/USER:BoardNotInitializedDevInitBoardNotCalled)";
    $alarmInfo{"4006016F"} = "PM1ALLFASTLOOP:CIF/USER:IOCTRLFunctionFailed";
    $alarmInfo{"40060170"} = "PM1ALLFASTLOOP:CIF/USER:ParameterDeviceNumberInvalid";
    $alarmInfo{"40060171"} = "PM1ALLFASTLOOP:CIF/USER:ParameterInfoAreaUnknown";
    $alarmInfo{"40060172"} = "PM1ALLFASTLOOP:CIF/USER:ParameterNumberInvalid";
    $alarmInfo{"40060173"} = "PM1ALLFASTLOOP:CIF/USER:ParameterModeInvalid";
    $alarmInfo{"40060174"} = "PM1ALLFASTLOOP:CIF/USER:NULLPointerAssignment";
    $alarmInfo{"40060175"} = "PM1ALLFASTLOOP:CIF/USER:MessageBufferTooShort";
    $alarmInfo{"40060176"} = "PM1ALLFASTLOOP:CIF/USER:ParameterSizeInvalid";
    $alarmInfo{"40060177"} = "PM1ALLFASTLOOP:CIF/USER:ParameterSizeWithZeroLength";
    $alarmInfo{"40060178"} = "PM1ALLFASTLOOP:CIF/USER:ParameterSizeTooLong";
    $alarmInfo{"40060179"} = "PM1ALLFASTLOOP:CIF/USER:DeviceAddressNullPointer";
    $alarmInfo{"4006017A"} = "PM1ALLFASTLOOP:CIF/USER:PointerToBufferIsANullPointer";
    $alarmInfo{"4006017B"} = "PM1ALLFASTLOOP:CIF/USER:ParameterSendSizeTooLong";
    $alarmInfo{"4006017C"} = "PM1ALLFASTLOOP:CIF/USER:ParameterReceiveSizeTooLong";
    $alarmInfo{"4006017D"} = "PM1ALLFASTLOOP:CIF/USER:PointerToSendBufferIsANullPointer";
    $alarmInfo{"4006017E"} = "PM1ALLFASTLOOP:CIF/USER:PointerToReceiveBufferIsANullPointer";
    $alarmInfo{"4006017F"} = "PM1ALLFASTLOOP:CIF/DMA:MemoryAllocationError";
    $alarmInfo{"40060180"} = "PM1ALLFASTLOOP:CIF/DMA:ReadI/OTimeout";
    $alarmInfo{"40060181"} = "PM1ALLFASTLOOP:CIF/DMA:WriteI/OTimeout";
    $alarmInfo{"40060182"} = "PM1ALLFASTLOOP:CIF/DMA:PCITransferTimeout";
    $alarmInfo{"40060183"} = "PM1ALLFASTLOOP:CIF/DMA:DownloadTimeout";
    $alarmInfo{"40060184"} = "PM1ALLFASTLOOP:CIF/DMA:DatabaseDownloadFailed";
    $alarmInfo{"40060185"} = "PM1ALLFASTLOOP:CIF/DMA:FirmwareDownloadFailed";
    $alarmInfo{"40060186"} = "PM1ALLFASTLOOP:CIF/DMA:ClearDatabaseOnTheDeviceFailed";
    $alarmInfo{"40060187"} = "PM1ALLFASTLOOP:CIF/USER:VirtualMemoryNotAvailable";
    $alarmInfo{"40060188"} = "PM1ALLFASTLOOP:CIF/USER:UnmapVirtualMemoryFailed";
    $alarmInfo{"40060189"} = "PM1ALLFASTLOOP:CIF/DRIVER:GeneralError";
    $alarmInfo{"4006018A"} = "PM1ALLFASTLOOP:CIF/DRIVER:GeneralDMAError";
    $alarmInfo{"4006018B"} = "PM1ALLFASTLOOP:CIF/DRIVER:BatteryError";
    $alarmInfo{"4006018C"} = "PM1ALLFASTLOOP:CIF/DRIVER:PowerFailedError";
    $alarmInfo{"4006018D"} = "PM1ALLFASTLOOP:CIF/USER:DriverUnknown";
    $alarmInfo{"4006018E"} = "PM1ALLFASTLOOP:CIF/USER:DeviceNameInvalid";
    $alarmInfo{"4006018F"} = "PM1ALLFASTLOOP:CIF/USER:DeviceNameUnknown";
    $alarmInfo{"40060190"} = "PM1ALLFASTLOOP:CIF/USER:DeviceFunctionNotImplemented";
    $alarmInfo{"40060191"} = "PM1ALLFASTLOOP:CIF/USER:FileNotOpened";
    $alarmInfo{"40060192"} = "PM1ALLFASTLOOP:CIF/USER:FileSizeZero";
    $alarmInfo{"40060193"} = "PM1ALLFASTLOOP:CIF/USER:NotEnoughMemoryToLoadFile";
    $alarmInfo{"40060194"} = "PM1ALLFASTLOOP:CIF/USER:FileReadFailed";
    $alarmInfo{"40060195"} = "PM1ALLFASTLOOP:CIF/USER:FileTypeInvalid";
    $alarmInfo{"40060196"} = "PM1ALLFASTLOOP:CIF/USER:FileNameNotValid";
    $alarmInfo{"40060197"} = "PM1ALLFASTLOOP:CIF/USER:FirmwareFileNotOpened";
    $alarmInfo{"40060198"} = "PM1ALLFASTLOOP:CIF/USER:FirmwareFileSizeZero";
    $alarmInfo{"40060199"} = "PM1ALLFASTLOOP:CIF/USER:NotEnoughMemoryToLoadFirmwareFile";
    $alarmInfo{"4006019A"} = "PM1ALLFASTLOOP:CIF/USER:FirmwareFileReadFailed";
    $alarmInfo{"4006019B"} = "PM1ALLFASTLOOP:CIF/USER:FirmwareFileTypeInvalid";
    $alarmInfo{"4006019C"} = "PM1ALLFASTLOOP:CIF/USER:FirmwareFileNameNotValid";
    $alarmInfo{"4006019D"} = "PM1ALLFASTLOOP:CIF/USER:FirmwareFileDownloadError";
    $alarmInfo{"4006019E"} = "PM1ALLFASTLOOP:CIF/USER:FirmwareFileNotFoundInTheInternalTable";
    $alarmInfo{"4006019F"} = "PM1ALLFASTLOOP:CIF/USER:FirmwareFileBOOTLOADERActive";
    $alarmInfo{"400601A0"} = "PM1ALLFASTLOOP:CIF/USER:FirmwareFileNotFilePath";
    $alarmInfo{"400601A1"} = "PM1ALLFASTLOOP:CIF/USER:ConfigurationFileNotOpened";
    $alarmInfo{"400601A2"} = "PM1ALLFASTLOOP:CIF/USER:ConfigurationFileSizeZero";
    $alarmInfo{"400601A3"} = "PM1ALLFASTLOOP:CIF/USER:NotEnoughMemoryToLoadConfigurationFile";
    $alarmInfo{"400601A4"} = "PM1ALLFASTLOOP:CIF/USER:ConfigurationFileReadFailed";
    $alarmInfo{"400601A5"} = "PM1ALLFASTLOOP:CIF/USER:ConfigurationFileTypeInvalid";
    $alarmInfo{"400601A6"} = "PM1ALLFASTLOOP:CIF/USER:ConfigurationFileNameNotValid";
    $alarmInfo{"400601A7"} = "PM1ALLFASTLOOP:CIF/USER:ConfigurationFileDownloadError";
    $alarmInfo{"400601A8"} = "PM1ALLFASTLOOP:CIF/USER:NoFlashSegmentInTheConfigurationFile";
    $alarmInfo{"400601A9"} = "PM1ALLFASTLOOP:CIF/USER:ConfigurationFileDiffersFromDatabase";
    $alarmInfo{"400601AA"} = "PM1ALLFASTLOOP:CIF/USER:DatabaseSizeZero";
    $alarmInfo{"400601AB"} = "PM1ALLFASTLOOP:CIF/USER:NotEnoughMemoryToUploadDatabase";
    $alarmInfo{"400601AC"} = "PM1ALLFASTLOOP:CIF/USER:DatabaseReadFailed";
    $alarmInfo{"400601AD"} = "PM1ALLFASTLOOP:CIF/USER:DatabaseSegmentUnknown";
    $alarmInfo{"400601AE"} = "PM1ALLFASTLOOP:CIF/CONFIG:VersionOfTheDescriptTableInvalid";
    $alarmInfo{"400601AF"} = "PM1ALLFASTLOOP:CIF/CONFIG:InputOffsetIsInvalid";
    $alarmInfo{"400601B0"} = "PM1ALLFASTLOOP:CIF/CONFIG:InputSizeIs0";
    $alarmInfo{"400601B1"} = "PM1ALLFASTLOOP:CIF/CONFIG:InputSizeDoesNotMatchConfiguration";
    $alarmInfo{"400601B2"} = "PM1ALLFASTLOOP:CIF/CONFIG:OutputOffsetIsInvalid";
    $alarmInfo{"400601B3"} = "PM1ALLFASTLOOP:CIF/CONFIG:OutputSizeIs0";
    $alarmInfo{"400601B4"} = "PM1ALLFASTLOOP:CIF/CONFIG:OutputSizeDoesNotMatchConfiguration";
    $alarmInfo{"400601B5"} = "PM1ALLFASTLOOP:CIF/CONFIG:StationNotConfigured";
    $alarmInfo{"400601B6"} = "PM1ALLFASTLOOP:CIF/CONFIG:CannotGetTheStationConfiguration";
    $alarmInfo{"400601B7"} = "PM1ALLFASTLOOP:CIF/CONFIG:ModuleDefinitionIsMissing";
    $alarmInfo{"400601B8"} = "PM1ALLFASTLOOP:CIF/CONFIG:EmptySlotMismatch";
    $alarmInfo{"400601B9"} = "PM1ALLFASTLOOP:CIF/CONFIG:InputOffsetMismatch";
    $alarmInfo{"400601BA"} = "PM1ALLFASTLOOP:CIF/CONFIG:OutputOffsetMismatch";
    $alarmInfo{"400601BB"} = "PM1ALLFASTLOOP:CIF/CONFIG:DataTypeMismatch";
    $alarmInfo{"400601BC"} = "PM1ALLFASTLOOP:CIF/CONFIG:ModuleDefinitionIsMissing,NoSlot/Idx)";
    $alarmInfo{"400601BD"} = "PM1ALLFASTLOOP:CIF:Unknown";
    $alarmInfo{"400601BE"} = "PM1ALLFASTLOOP:Unknown";
    $alarmInfo{"400601BF"} = "PM1ALLFASTLOOP:Unknown";
    $alarmInfo{"400601C0"} = "PM1ALLDeviceNetMacID0CommunicationLost";
    $alarmInfo{"400601C1"} = "PM1ALLDeviceNetMacID1CommunicationLost";
    $alarmInfo{"400601C2"} = "PM1ALLDeviceNetMacID2CommunicationLost";
    $alarmInfo{"400601C3"} = "PM1ALLDeviceNetMacID3CommunicationLost";
    $alarmInfo{"400601C4"} = "PM1ALLDeviceNetMacID4CommunicationLost";
    $alarmInfo{"400601C5"} = "PM1ALLDeviceNetMacID5CommunicationLost";
    $alarmInfo{"400601C6"} = "PM1ALLDeviceNetMacID6CommunicationLost";
    $alarmInfo{"400601C7"} = "PM1ALLDeviceNetMacID7CommunicationLost";
    $alarmInfo{"400601C8"} = "PM1ALLDeviceNetMacID8CommunicationLost";
    $alarmInfo{"400601C9"} = "PM1ALLDeviceNetMacID9CommunicationLost";
    $alarmInfo{"400601CA"} = "PM1ALLDeviceNetMacID10CommunicationLost";
    $alarmInfo{"400601CB"} = "PM1ALLDeviceNetMacID11CommunicationLost";
    $alarmInfo{"400601CC"} = "PM1ALLDeviceNetMacID12CommunicationLost";
    $alarmInfo{"400601CD"} = "PM1ALLDeviceNetMacID13CommunicationLost";
    $alarmInfo{"400601CE"} = "PM1ALLDeviceNetMacID14CommunicationLost";
    $alarmInfo{"400601CF"} = "PM1ALLDeviceNetMacID15CommunicationLost";
    $alarmInfo{"400601D0"} = "PM1ALLDeviceNetMacID16CommunicationLost";
    $alarmInfo{"400601D1"} = "PM1ALLDeviceNetMacID17CommunicationLost";
    $alarmInfo{"400601D2"} = "PM1ALLDeviceNetMacID18CommunicationLost";
    $alarmInfo{"400601D3"} = "PM1ALLDeviceNetMacID19CommunicationLost";
    $alarmInfo{"400601D4"} = "PM1ALLDeviceNetMacID20CommunicationLost";
    $alarmInfo{"400601D5"} = "PM1ALLDeviceNetMacID21CommunicationLost";
    $alarmInfo{"400601D6"} = "PM1ALLDeviceNetMacID22CommunicationLost";
    $alarmInfo{"400601D7"} = "PM1ALLDeviceNetMacID23CommunicationLost";
    $alarmInfo{"400601D8"} = "PM1ALLDeviceNetMacID24CommunicationLost";
    $alarmInfo{"400601D9"} = "PM1ALLDeviceNetMacID25CommunicationLost";
    $alarmInfo{"400601DA"} = "PM1ALLDeviceNetMacID26CommunicationLost";
    $alarmInfo{"400601DB"} = "PM1ALLDeviceNetMacID27CommunicationLost";
    $alarmInfo{"400601DC"} = "PM1ALLDeviceNetMacID28CommunicationLost";
    $alarmInfo{"400601DD"} = "PM1ALLDeviceNetMacID29CommunicationLost";
    $alarmInfo{"400601DE"} = "PM1ALLDeviceNetMacID30CommunicationLost";
    $alarmInfo{"400601DF"} = "PM1ALLDeviceNetMacID31CommunicationLost";
    $alarmInfo{"400601E0"} = "PM1ALLDeviceNetMacID32CommunicationLost";
    $alarmInfo{"400601E1"} = "PM1ALLDeviceNetMacID33CommunicationLost";
    $alarmInfo{"400601E2"} = "PM1ALLDeviceNetMacID34CommunicationLost";
    $alarmInfo{"400601E3"} = "PM1ALLDeviceNetMacID35CommunicationLost";
    $alarmInfo{"400601E4"} = "PM1ALLDeviceNetMacID36CommunicationLost";
    $alarmInfo{"400601E5"} = "PM1ALLDeviceNetMacID37CommunicationLost";
    $alarmInfo{"400601E6"} = "PM1ALLDeviceNetMacID38CommunicationLost";
    $alarmInfo{"400601E7"} = "PM1ALLDeviceNetMacID39CommunicationLost";
    $alarmInfo{"400601E8"} = "PM1ALLDeviceNetMacID40CommunicationLost";
    $alarmInfo{"400601E9"} = "PM1ALLDeviceNetMacID41CommunicationLost";
    $alarmInfo{"400601EA"} = "PM1ALLDeviceNetMacID42CommunicationLost";
    $alarmInfo{"400601EB"} = "PM1ALLDeviceNetMacID43CommunicationLost";
    $alarmInfo{"400601EC"} = "PM1ALLDeviceNetMacID44CommunicationLost";
    $alarmInfo{"400601ED"} = "PM1ALLDeviceNetMacID45CommunicationLost";
    $alarmInfo{"400601EE"} = "PM1ALLDeviceNetMacID46CommunicationLost";
    $alarmInfo{"400601EF"} = "PM1ALLDeviceNetMacID47CommunicationLost";
    $alarmInfo{"400601F0"} = "PM1ALLDeviceNetMacID48CommunicationLost";
    $alarmInfo{"400601F1"} = "PM1ALLDeviceNetMacID49CommunicationLost";
    $alarmInfo{"400601F2"} = "PM1ALLDeviceNetMacID50CommunicationLost";
    $alarmInfo{"400601F3"} = "PM1ALLDeviceNetMacID51CommunicationLost";
    $alarmInfo{"400601F4"} = "PM1ALLDeviceNetMacID52CommunicationLost";
    $alarmInfo{"400601F5"} = "PM1ALLDeviceNetMacID53CommunicationLost";
    $alarmInfo{"400601F6"} = "PM1ALLDeviceNetMacID54CommunicationLost";
    $alarmInfo{"400601F7"} = "PM1ALLDeviceNetMacID55CommunicationLost";
    $alarmInfo{"400601F8"} = "PM1ALLDeviceNetMacID56CommunicationLost";
    $alarmInfo{"400601F9"} = "PM1ALLDeviceNetMacID57CommunicationLost";
    $alarmInfo{"400601FA"} = "PM1ALLDeviceNetMacID58CommunicationLost";
    $alarmInfo{"400601FB"} = "PM1ALLDeviceNetMacID59CommunicationLost";
    $alarmInfo{"400601FC"} = "PM1ALLDeviceNetMacID60CommunicationLost";
    $alarmInfo{"400601FD"} = "PM1ALLDeviceNetMacID61CommunicationLost";
    $alarmInfo{"400601FE"} = "PM1ALLDeviceNetMacID62CommunicationLost";
    $alarmInfo{"400601FF"} = "PM1ALLDeviceNetMacID63CommunicationLost";
    $alarmInfo{"40060240"} = "PM1ALLDeviceNetMacID0Error";
    $alarmInfo{"40060241"} = "PM1ALLDeviceNetMacID1Error";
    $alarmInfo{"40060242"} = "PM1ALLDeviceNetMacID2Error";
    $alarmInfo{"40060243"} = "PM1ALLDeviceNetMacID3Error";
    $alarmInfo{"40060244"} = "PM1ALLDeviceNetMacID4Error";
    $alarmInfo{"40060245"} = "PM1ALLDeviceNetMacID5Error";
    $alarmInfo{"40060246"} = "PM1ALLDeviceNetMacID6Error";
    $alarmInfo{"40060247"} = "PM1ALLDeviceNetMacID7Error";
    $alarmInfo{"40060248"} = "PM1ALLDeviceNetMacID8Error";
    $alarmInfo{"40060249"} = "PM1ALLDeviceNetMacID9Error";
    $alarmInfo{"4006024A"} = "PM1ALLDeviceNetMacID10Error";
    $alarmInfo{"4006024B"} = "PM1ALLDeviceNetMacID11Error";
    $alarmInfo{"4006024C"} = "PM1ALLDeviceNetMacID12Error";
    $alarmInfo{"4006024D"} = "PM1ALLDeviceNetMacID13Error";
    $alarmInfo{"4006024E"} = "PM1ALLDeviceNetMacID14Error";
    $alarmInfo{"4006024F"} = "PM1ALLDeviceNetMacID15Error";
    $alarmInfo{"40060250"} = "PM1ALLDeviceNetMacID16Error";
    $alarmInfo{"40060251"} = "PM1ALLDeviceNetMacID17Error";
    $alarmInfo{"40060252"} = "PM1ALLDeviceNetMacID18Error";
    $alarmInfo{"40060253"} = "PM1ALLDeviceNetMacID19Error";
    $alarmInfo{"40060254"} = "PM1ALLDeviceNetMacID20Error";
    $alarmInfo{"40060255"} = "PM1ALLDeviceNetMacID21Error";
    $alarmInfo{"40060256"} = "PM1ALLDeviceNetMacID22Error";
    $alarmInfo{"40060257"} = "PM1ALLDeviceNetMacID23Error";
    $alarmInfo{"40060258"} = "PM1ALLDeviceNetMacID24Error";
    $alarmInfo{"40060259"} = "PM1ALLDeviceNetMacID25Error";
    $alarmInfo{"4006025A"} = "PM1ALLDeviceNetMacID26Error";
    $alarmInfo{"4006025B"} = "PM1ALLDeviceNetMacID27Error";
    $alarmInfo{"4006025C"} = "PM1ALLDeviceNetMacID28Error";
    $alarmInfo{"4006025D"} = "PM1ALLDeviceNetMacID29Error";
    $alarmInfo{"4006025E"} = "PM1ALLDeviceNetMacID30Error";
    $alarmInfo{"4006025F"} = "PM1ALLDeviceNetMacID31Error";
    $alarmInfo{"40060260"} = "PM1ALLDeviceNetMacID32Error";
    $alarmInfo{"40060261"} = "PM1ALLDeviceNetMacID33Error";
    $alarmInfo{"40060262"} = "PM1ALLDeviceNetMacID34Error";
    $alarmInfo{"40060263"} = "PM1ALLDeviceNetMacID35Error";
    $alarmInfo{"40060264"} = "PM1ALLDeviceNetMacID36Error";
    $alarmInfo{"40060265"} = "PM1ALLDeviceNetMacID37Error";
    $alarmInfo{"40060266"} = "PM1ALLDeviceNetMacID38Error";
    $alarmInfo{"40060267"} = "PM1ALLDeviceNetMacID39Error";
    $alarmInfo{"40060268"} = "PM1ALLDeviceNetMacID40Error";
    $alarmInfo{"40060269"} = "PM1ALLDeviceNetMacID41Error";
    $alarmInfo{"4006026A"} = "PM1ALLDeviceNetMacID42Error";
    $alarmInfo{"4006026B"} = "PM1ALLDeviceNetMacID43Error";
    $alarmInfo{"4006026C"} = "PM1ALLDeviceNetMacID44Error";
    $alarmInfo{"4006026D"} = "PM1ALLDeviceNetMacID45Error";
    $alarmInfo{"4006026E"} = "PM1ALLDeviceNetMacID46Error";
    $alarmInfo{"4006026F"} = "PM1ALLDeviceNetMacID47Error";
    $alarmInfo{"40060270"} = "PM1ALLDeviceNetMacID48Error";
    $alarmInfo{"40060271"} = "PM1ALLDeviceNetMacID49Error";
    $alarmInfo{"40060272"} = "PM1ALLDeviceNetMacID50Error";
    $alarmInfo{"40060273"} = "PM1ALLDeviceNetMacID51Error";
    $alarmInfo{"40060274"} = "PM1ALLDeviceNetMacID52Error";
    $alarmInfo{"40060275"} = "PM1ALLDeviceNetMacID53Error";
    $alarmInfo{"40060276"} = "PM1ALLDeviceNetMacID54Error";
    $alarmInfo{"40060277"} = "PM1ALLDeviceNetMacID55Error";
    $alarmInfo{"40060278"} = "PM1ALLDeviceNetMacID56Error";
    $alarmInfo{"40060279"} = "PM1ALLDeviceNetMacID57Error";
    $alarmInfo{"4006027A"} = "PM1ALLDeviceNetMacID58Error";
    $alarmInfo{"4006027B"} = "PM1ALLDeviceNetMacID59Error";
    $alarmInfo{"4006027C"} = "PM1ALLDeviceNetMacID60Error";
    $alarmInfo{"4006027D"} = "PM1ALLDeviceNetMacID61Error";
    $alarmInfo{"4006027E"} = "PM1ALLDeviceNetMacID62Error";
    $alarmInfo{"4006027F"} = "PM1ALLDeviceNetMacID63Error";
    $alarmInfo{"4010000"} = "LoadPortAlarmLP1Cleared";
    $alarmInfo{"4010001"} = "LoadPortAlarmLP1Detected";
    $alarmInfo{"4020000"} = "LoadPortAlarmLP2Cleared";
    $alarmInfo{"4020001"} = "LoadPortAlarmLP2Detected";
    $alarmInfo{"4030000"} = "LoadPortAlarmLP3Cleared";
    $alarmInfo{"4030001"} = "LoadPortAlarmLP3Detected";
    $alarmInfo{"4040000"} = "LoadPortAlarmLP4Cleared";
    $alarmInfo{"4040001"} = "LoadPortAlarmLP4Detected";
    $alarmInfo{"41060001"} = "TCCommunicationTimeout";
    $alarmInfo{"41060002"} = "ADSCommunicationTimeout";
    $alarmInfo{"41060003"} = "ADSWatchDogAlarmOccurred";
    $alarmInfo{"41060004"} = "ConfigurationFileOrRecipeFileNotReceived";
    $alarmInfo{"41060005"} = "StatusIsNotREADY";
    $alarmInfo{"41060006"} = "StatusIsRUN";
    $alarmInfo{"41060007"} = "StatusIsNotRUN";
    $alarmInfo{"41060008"} = "NoStartStepExistsInTheSpecifiedRecipe";
    $alarmInfo{"41060009"} = "PressureValueAnd1atmSensorMismatch";
    $alarmInfo{"4106000A"} = "AlarmOccurred";
    $alarmInfo{"4106000B"} = "PauseOccurred";
    $alarmInfo{"4106000C"} = "SafetyOccurred";
    $alarmInfo{"4106000D"} = "AbortOccurred";
    $alarmInfo{"4106000E"} = "OtherErrorOccurred";
    $alarmInfo{"41060010"} = "SeriousAlarmNonRecipe)Occurred";
    $alarmInfo{"41060011"} = "LightAlarmNonRecipe)Occurred";
    $alarmInfo{"41060012"} = "SafetyLatchAlarmOccurred";
    $alarmInfo{"41060013"} = "MaintenanceAlarmOccurred";
    $alarmInfo{"41060014"} = "DIMaintenanceAlarmOccurred";
    $alarmInfo{"41060020"} = "CapabilityIsAborted";
    $alarmInfo{"41060021"} = "Purge-CurtainStatusIsNot-Active";
    $alarmInfo{"41060022"} = "NoWafersAvailableForPeriodicDummy";
    $alarmInfo{"41060023"} = "WarningCountNearingAutoCleanLimit";
    $alarmInfo{"41060024"} = "WarningCountNearingAutoPurgeLimit";
    $alarmInfo{"41060025"} = "WarningCountNearingAutoDummyLimit";
    $alarmInfo{"41060026"} = "CoolingWaterLeak";
    $alarmInfo{"41060027"} = "CoolingWaterLeak2";
    $alarmInfo{"41060028"} = "SmokeDetected";
    $alarmInfo{"41060029"} = "HClDetectedBySensor";
    $alarmInfo{"4106002A"} = "LiquidLeakDetected";
    $alarmInfo{"4106002B"} = "LiquidLeak2Detected";
    $alarmInfo{"4106002C"} = "H2Detected";
    $alarmInfo{"4106002D"} = "Cl2Detected";
    $alarmInfo{"4106002E"} = "NH3Detected";
    $alarmInfo{"4106002F"} = "EmeraldHIGFlowControlDisabled";
    $alarmInfo{"41060040"} = "ModuleNotResponding";
    $alarmInfo{"41060041"} = "HoldToAbortTimeout";
    $alarmInfo{"41060042"} = "SlotValveOpen";
    $alarmInfo{"41060043"} = "PC104PMCommunicationsDisconnected";
    $alarmInfo{"41060044"} = "MustRunSERVICEStartupRecipe";
    $alarmInfo{"41060045"} = "InvalidSERVICERecipeType";
    $alarmInfo{"41060046"} = "LocalRackLockedUp";
    $alarmInfo{"41060047"} = "Gas1FlowToleranceFault";
    $alarmInfo{"41060048"} = "Gas2FlowToleranceFault";
    $alarmInfo{"41060049"} = "Gas3FlowToleranceFault";
    $alarmInfo{"4106004A"} = "Gas4FlowToleranceFault";
    $alarmInfo{"4106004B"} = "HivacFailedToOpen";
    $alarmInfo{"4106004C"} = "HivacFailedToClose";
    $alarmInfo{"4106004D"} = "PumpToBaseFailed";
    $alarmInfo{"4106004E"} = "RoughingTimeout";
    $alarmInfo{"4106004F"} = "RoughingPressureTooHigh";
    $alarmInfo{"41060050"} = "CryoOverMaxTemperature";
    $alarmInfo{"41060051"} = "TurboPumpFailed";
    $alarmInfo{"41060052"} = "TurboOverMaxTemperature";
    $alarmInfo{"41060053"} = "CannotRegenTurboPump!";
    $alarmInfo{"41060054"} = "TurboFailedToReachSpeed";
    $alarmInfo{"41060055"} = "TurboAtFaultOrNotAtSpeed";
    $alarmInfo{"41060056"} = "WaferLiftSlowToMoveUp";
    $alarmInfo{"41060057"} = "WaferLiftSlowToMoveDown";
    $alarmInfo{"41060058"} = "WaferLiftFailedToMove";
    $alarmInfo{"41060059"} = "PlatenControlTempT/CDisconnected";
    $alarmInfo{"4106005A"} = "PlatenSafetyTempT/CDisconnected";
    $alarmInfo{"4106005B"} = "PlatenControl-safetyTempDifference";
    $alarmInfo{"4106005C"} = "PlatenTempOutOfBand";
    $alarmInfo{"4106005D"} = "PlatenFailedToMoveUp";
    $alarmInfo{"4106005E"} = "PlatenFailedToMoveDown";
    $alarmInfo{"4106005F"} = "RecirculatorTempOutOfBand";
    $alarmInfo{"41060060"} = "RecirculatorTempT/CDisconnected";
    $alarmInfo{"41060061"} = "PlatenTempT/CDisconnected";
    $alarmInfo{"41060062"} = "CoilRFReflectedPowerFault";
    $alarmInfo{"41060063"} = "CoilRFReflectedPowerHold";
    $alarmInfo{"41060064"} = "CoilForwardPowerFault";
    $alarmInfo{"41060065"} = "PotMovementPositionFault";
    $alarmInfo{"41060066"} = "PlatenRFReflectedPowerAbort";
    $alarmInfo{"41060067"} = "PlatenRFReflectedPowerHold";
    $alarmInfo{"41060068"} = "DCBiasAboveMaxLimit";
    $alarmInfo{"41060069"} = "DCBiasBelowMinLimit";
    $alarmInfo{"4106006A"} = "DCBiasToleranceFault";
    $alarmInfo{"4106006B"} = "ForwardPowerToleranceFault";
    $alarmInfo{"4106006C"} = "LoadPowerToleranceFault";
    $alarmInfo{"4106006D"} = "Bake-outControlTempT/CDisconnected";
    $alarmInfo{"4106006E"} = "Bake-outSafetyTempT/CDisconnected";
    $alarmInfo{"4106006F"} = "Bake-outControl-safetyTempDifference";
    $alarmInfo{"41060070"} = "Bake-outSlowToReachTemperature";
    $alarmInfo{"41060071"} = "EscPump-outPressureLimitFault";
    $alarmInfo{"41060072"} = "EscPump-outPressureFaultInUnclamp";
    $alarmInfo{"41060073"} = "EscFlowFault";
    $alarmInfo{"41060074"} = "EscWaferValveOpenFault";
    $alarmInfo{"41060075"} = "EscPressureInBandTime-out";
    $alarmInfo{"41060076"} = "EscPressureToleranceFault";
    $alarmInfo{"41060077"} = "EscVoltageFault";
    $alarmInfo{"41060078"} = "TimeoutWaitingForBackfillPressure";
    $alarmInfo{"41060079"} = "Leak-upRateFailure";
    $alarmInfo{"4106007A"} = "CompressedAirFault";
    $alarmInfo{"4106007B"} = "LocalPCTemperatureFault";
    $alarmInfo{"4106007C"} = "ModuleFanFault";
    $alarmInfo{"4106007D"} = "VentServiceFailedToReachAtmosphere";
    $alarmInfo{"4106007E"} = "RGALeakCheckRequired";
    $alarmInfo{"4106007F"} = "WaitingForStage1Pressure -Slow";
    $alarmInfo{"41060080"} = "WaitingForStage2Pressure -Slow";
    $alarmInfo{"41060081"} = "NotWaitingForStage1Pressure ";
    $alarmInfo{"41060082"} = "FailedToReachStage1Pressure";
    $alarmInfo{"41060083"} = "FailedToReachStage2Pressure";
    $alarmInfo{"41060084"} = "CryoRegenServiceRoutineFailed";
    $alarmInfo{"41060085"} = "CTIControllerCommunicationsError";
    $alarmInfo{"41060086"} = "CTIPumpNotResponding";
    $alarmInfo{"41060087"} = "TurboPlusServiceRoutineFailed";
    $alarmInfo{"41060088"} = "HeaterMalfunctionHappened";
    $alarmInfo{"41600030"} = "RC1ADSWatchDogAlarmOccurredClr";
    $alarmInfo{"41600031"} = "RC1ADSWatchDogAlarmOccurredDet";
    $alarmInfo{"416000a0"} = "RC1AlarmOccurredClr";
    $alarmInfo{"416000a1"} = "RC1AlarmOccurredDet";
    $alarmInfo{"41600100"} = "RC1SeriousAlarmOccurredClr";
    $alarmInfo{"41600101"} = "RC1SeriousAlarmOccurredDet";
    $alarmInfo{"41600110"} = "RC1LightAlarmOccurredClr";
    $alarmInfo{"41600111"} = "RC1LightAlarmOccurredDet";
    $alarmInfo{"41600120"} = "RC1SafetyLatchAlarmOccurredClr";
    $alarmInfo{"41600121"} = "RC1SafetyLatchAlarmOccurredDet";
    $alarmInfo{"41600130"} = "RC1MaintenanceAlarmOccurredClr";
    $alarmInfo{"41600131"} = "RC1MaintenanceAlarmOccurredDet";
    $alarmInfo{"41600140"} = "RC1DIMaintenanceAlarmOccurredClr";
    $alarmInfo{"41600141"} = "RC1DIMaintenanceAlarmOccurredDet";
    $alarmInfo{"42060000"} = "42060000";
    $alarmInfo{"42060001"} = "CommunicationTimeout";
    $alarmInfo{"42060002"} = "StatusChangedToIDLE";
    $alarmInfo{"42060003"} = "CommandWasRejected";
    $alarmInfo{"42060004"} = "MotionStopped";
    $alarmInfo{"42060005"} = "MotionAborted";
    $alarmInfo{"42060006"} = "MotorStatusError";
    $alarmInfo{"42060007"} = "ACKTimeout";
    $alarmInfo{"42060008"} = "CompletionTimeout";
    $alarmInfo{"42060009"} = "ActualError";
    $alarmInfo{"4206000A"} = "SensorError";
    $alarmInfo{"4206000B"} = "SensorUnknown";
    $alarmInfo{"4206000C"} = "TransferInterlockErrorOccurred";
    $alarmInfo{"4206000D"} = "WaferInterlockErrorOccurred";
    $alarmInfo{"4206000E"} = "PressureInterlockErrorOccurred";
    $alarmInfo{"42060010"} = "MotorUnitErrorOccurred";
    $alarmInfo{"42060011"} = "InitializationUncompleted";
    $alarmInfo{"42060012"} = "BERobotInterlockErrorOccurred";
    $alarmInfo{"42060013"} = "HardwareUpperLimitSensorTripped";
    $alarmInfo{"42060014"} = "HardwareLowerLimitSensorTripped";
    $alarmInfo{"42060015"} = "RotationAxisHardwareInterlockOccurred";
    $alarmInfo{"42060016"} = "RotationAxisSoftwareInterlockOccurred";
    $alarmInfo{"42060017"} = "VerticalAxisSoftwareInterlockOccurred";
    $alarmInfo{"42060018"} = "HardwareLimitSwitchIsNotProperlySetup";
    $alarmInfo{"42060019"} = "ExceedTheSoftwareLimitsOfUpperPulse";
    $alarmInfo{"4206001A"} = "ExceedTheSoftwareLimitsOfLowerPulse";
    $alarmInfo{"4206001B"} = "GateValveIsOpen";
    $alarmInfo{"4206001C"} = "MotionStopOccurred";
    $alarmInfo{"4206001D"} = "ChamberLidIsOpen";
    $alarmInfo{"4206001E"} = "BERBArmIsExtendedPosition";
    $alarmInfo{"4206001F"} = "LiftCabinetIsOpen";
    $alarmInfo{"42060020"} = "ErrorReadingRotationHomeSensorState";
    $alarmInfo{"42060021"} = "RotationHome";
    $alarmInfo{"50060000"} = "50060000";
    $alarmInfo{"50060001"} = "PM2ALLWatchDriverFroze";
    $alarmInfo{"50060002"} = "PM2ALLPMDeviceNetDriverFroze";
    $alarmInfo{"50060003"} = "PM2ALLADSDriverFroze";
    $alarmInfo{"50060004"} = "PM2ALLTemparatureDriverFroze";
    $alarmInfo{"50060005"} = "PM2ALLPMDeviceNetDIODriverFroze";
    $alarmInfo{"50060006"} = "PM2ALLPMSEQDriverFroze";
    $alarmInfo{"50060007"} = "PM2ALLPMDeviceNetAIODriverFroze";
    $alarmInfo{"50060008"} = "PM2ALLPMRecipeExecutorFroze";
    $alarmInfo{"50060009"} = "PM2ALLSusceptorControlDriverFroze";
    $alarmInfo{"5006000A"} = "PM2ALLPressurePIDControlDriverFroze";
    $alarmInfo{"5006000B"} = "PM2ALLPulsingEngineFroze";
    $alarmInfo{"5006000C"} = "SYN5006000C";
    $alarmInfo{"5006000E"} = "PM2ALLStepTimeError";
    $alarmInfo{"50060010"} = "PM2ALLHSEControlDriverFroze";
    $alarmInfo{"50060020"} = "PM2ALLFASTLOOP:Error";
    $alarmInfo{"50060021"} = "PM2ALLFASTLOOP:CIF:DualPortMemoryIsNull";
    $alarmInfo{"50060022"} = "PM2ALLFASTLOOP:DeviceNet:WatchDogError";
    $alarmInfo{"50060023"} = "PM2ALLFASTLOOP:DeviceNet:CommunicationStateOff-line";
    $alarmInfo{"50060024"} = "PM2ALLFASTLOOP:DeviceNet:CommunicationStateStop";
    $alarmInfo{"50060025"} = "PM2ALLFASTLOOP:DeviceNet:CommunicationStateClear";
    $alarmInfo{"50060026"} = "PM2ALLFASTLOOP:DeviceNet:FatalError";
    $alarmInfo{"50060027"} = "PM2ALLFASTLOOP:DeviceNet:BUSError";
    $alarmInfo{"50060028"} = "PM2ALLFASTLOOP:DeviceNet:BUSOff";
    $alarmInfo{"50060029"} = "PM2ALLFASTLOOP:DeviceNet:NoExchange";
    $alarmInfo{"5006002A"} = "PM2ALLFASTLOOP:DeviceNet:AutoClearError";
    $alarmInfo{"5006002B"} = "PM2ALLFASTLOOP:DeviceNet:DuplicateMAC-ID";
    $alarmInfo{"5006002C"} = "PM2ALLFASTLOOP:DeviceNet:HostNotReady";
    $alarmInfo{"5006002D"} = "PM2ALLFASTLOOP:Unknown";
    $alarmInfo{"5006002E"} = "PM2ALLFASTLOOP:Unknown";
    $alarmInfo{"5006002F"} = "PM2ALLFASTLOOP:Unknown";
    $alarmInfo{"50060030"} = "PM2ALLFASTLOOP:MAC-ID1:DeviceGuardingFailed,AfterDeviceWasOperational";
    $alarmInfo{"50060031"} = "PM2ALLFASTLOOP:MAC-ID1:DeviceAccessTimeout";
    $alarmInfo{"50060032"} = "PM2ALLFASTLOOP:MAC-ID1:DeviceRejectsAccessWithUnknownErrorCode";
    $alarmInfo{"50060033"} = "PM2ALLFASTLOOP:MAC-ID1:DeviceResponseInAllocationPhaseWithConnectionError";
    $alarmInfo{"50060034"} = "PM2ALLFASTLOOP:MAC-ID1:ProducedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"50060035"} = "PM2ALLFASTLOOP:MAC-ID1:ConsumedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"50060036"} = "PM2ALLFASTLOOP:MAC-ID1:DeviceServiceResponseTelegramUnknownAndNotHandled";
    $alarmInfo{"50060037"} = "PM2ALLFASTLOOP:MAC-ID1:ConnectionAlreadyInRequest";
    $alarmInfo{"50060038"} = "PM2ALLFASTLOOP:MAC-ID1:NumberOfCAN-messageDataBytesInReadProducedOrConsumedConnectionSizeResponseUnequal4";
    $alarmInfo{"50060039"} = "PM2ALLFASTLOOP:MAC-ID1:PredefinedMaster-slaveConnectionAlreadyExists";
    $alarmInfo{"5006003A"} = "PM2ALLFASTLOOP:MAC-ID1:LengthInPollingDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"5006003B"} = "PM2ALLFASTLOOP:MAC-ID1:SequenceErrorInDevicePollingResponse";
    $alarmInfo{"5006003C"} = "PM2ALLFASTLOOP:MAC-ID1:FragmentErrorInDevicePollingResponse";
    $alarmInfo{"5006003D"} = "PM2ALLFASTLOOP:MAC-ID1:SequenceError2InDevicePollingResponse";
    $alarmInfo{"5006003E"} = "PM2ALLFASTLOOP:MAC-ID1:LengthInBitStrobeDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"5006003F"} = "PM2ALLFASTLOOP:MAC-ID1:SequenceErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"50060040"} = "PM2ALLFASTLOOP:MAC-ID1:FragmentErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"50060041"} = "PM2ALLFASTLOOP:MAC-ID1:SequenceError2InDeviceCOSOrCyclicResponse";
    $alarmInfo{"50060042"} = "PM2ALLFASTLOOP:MAC-ID1:LengthInCOSOrCyclicDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"50060043"} = "PM2ALLFASTLOOP:MAC-ID1:UCMMGroupNotSupported";
    $alarmInfo{"50060044"} = "PM2ALLFASTLOOP:MAC-ID1:UnknownHandshakeModeConfigured";
    $alarmInfo{"50060045"} = "PM2ALLFASTLOOP:MAC-ID1:ConfiguredBaudrateNotSupported";
    $alarmInfo{"50060046"} = "PM2ALLFASTLOOP:MAC-ID1:DeviceMAC-IDOutOfRange";
    $alarmInfo{"50060047"} = "PM2ALLFASTLOOP:MAC-ID1:DuplicateMAC-IDDetected";
    $alarmInfo{"50060048"} = "PM2ALLFASTLOOP:MAC-ID1:DatabaseInTheDeviceHasNoEntriesIncluded";
    $alarmInfo{"50060049"} = "PM2ALLFASTLOOP:MAC-ID1:DoubleMAC-IDConfiguredInternally";
    $alarmInfo{"5006004A"} = "PM2ALLFASTLOOP:MAC-ID1:SizeOfOneDeviceDataSetInvalid";
    $alarmInfo{"5006004B"} = "PM2ALLFASTLOOP:MAC-ID1:OffsetTableForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"5006004C"} = "PM2ALLFASTLOOP:MAC-ID1:ConfigurationTableLengthForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"5006004D"} = "PM2ALLFASTLOOP:MAC-ID1:OffsetTableDoNotCorrespondToI/OConfigurationTable";
    $alarmInfo{"5006004E"} = "PM2ALLFASTLOOP:MAC-ID1:SizeIndicatorOfParameterDataTableCorrupt";
    $alarmInfo{"5006004F"} = "PM2ALLFASTLOOP:MAC-ID1:NumberOfInputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"50060050"} = "PM2ALLFASTLOOP:MAC-ID1:NumberOfOutputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"50060051"} = "PM2ALLFASTLOOP:MAC-ID1:UnknownDataTypeInI/OConfiguration";
    $alarmInfo{"50060052"} = "PM2ALLFASTLOOP:MAC-ID1:DataTypeDoesNotCorrespondToItsConfiguredLength";
    $alarmInfo{"50060053"} = "PM2ALLFASTLOOP:MAC-ID1:ConfiguredOutputOffsetAddressOutOfRange";
    $alarmInfo{"50060054"} = "PM2ALLFASTLOOP:MAC-ID1:ConfiguredInputOffsetAddressOutOfRange";
    $alarmInfo{"50060055"} = "PM2ALLFASTLOOP:MAC-ID1:OnePredefinedConnectionTypeIsUnknown";
    $alarmInfo{"50060056"} = "PM2ALLFASTLOOP:MAC-ID1:MultipleConnectionsDefinedInParallel";
    $alarmInfo{"50060057"} = "PM2ALLFASTLOOP:MAC-ID1:ConfiguredEXP_PCKT_RATELessThenPROD_INHIBIT_TIME";
    $alarmInfo{"50060058"} = "PM2ALLFASTLOOP:MAC-ID1:NoDatabaseFoundOnTheSystem";
    $alarmInfo{"50060059"} = "PM2ALLFASTLOOP:MAC-ID1:DatabaseReadingFailure";
    $alarmInfo{"5006005A"} = "PM2ALLFASTLOOP:MAC-ID1:UserWatchdogFailed";
    $alarmInfo{"5006005B"} = "PM2ALLFASTLOOP:MAC-ID1:NoDataAcknowledgeFromUser";
    $alarmInfo{"5006005C"} = "PM2ALLFASTLOOP:MAC-ID1:Unknown";
    $alarmInfo{"5006005D"} = "PM2ALLFASTLOOP:MAC-ID1:Unknown";
    $alarmInfo{"5006005E"} = "PM2ALLFASTLOOP:MAC-ID1:Unknown";
    $alarmInfo{"5006005F"} = "PM2ALLFASTLOOP:MAC-ID1:Unknown";
    $alarmInfo{"50060060"} = "PM2ALLFASTLOOP:MAC-ID2:DeviceGuardingFailed,AfterDeviceWasOperational";
    $alarmInfo{"50060061"} = "PM2ALLFASTLOOP:MAC-ID2:DeviceAccessTimeout";
    $alarmInfo{"50060062"} = "PM2ALLFASTLOOP:MAC-ID2:DeviceRejectsAccessWithUnknownErrorCode";
    $alarmInfo{"50060063"} = "PM2ALLFASTLOOP:MAC-ID2:DeviceResponseInAllocationPhaseWithConnectionError";
    $alarmInfo{"50060064"} = "PM2ALLFASTLOOP:MAC-ID2:ProducedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"50060065"} = "PM2ALLFASTLOOP:MAC-ID2:ConsumedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"50060066"} = "PM2ALLFASTLOOP:MAC-ID2:DeviceServiceResponseTelegramUnknownAndNotHandled";
    $alarmInfo{"50060067"} = "PM2ALLFASTLOOP:MAC-ID2:ConnectionAlreadyInRequest";
    $alarmInfo{"50060068"} = "PM2ALLFASTLOOP:MAC-ID2:NumberOfCAN-messageDataBytesInReadProducedOrConsumedConnectionSizeResponseUnequal4";
    $alarmInfo{"50060069"} = "PM2ALLFASTLOOP:MAC-ID2:PredefinedMaster-slaveConnectionAlreadyExists";
    $alarmInfo{"5006006A"} = "PM2ALLFASTLOOP:MAC-ID2:LengthInPollingDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"5006006B"} = "PM2ALLFASTLOOP:MAC-ID2:SequenceErrorInDevicePollingResponse";
    $alarmInfo{"5006006C"} = "PM2ALLFASTLOOP:MAC-ID2:FragmentErrorInDevicePollingResponse";
    $alarmInfo{"5006006D"} = "PM2ALLFASTLOOP:MAC-ID2:SequenceError2InDevicePollingResponse";
    $alarmInfo{"5006006E"} = "PM2ALLFASTLOOP:MAC-ID2:LengthInBitStrobeDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"5006006F"} = "PM2ALLFASTLOOP:MAC-ID2:SequenceErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"50060070"} = "PM2ALLFASTLOOP:MAC-ID2:FragmentErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"50060071"} = "PM2ALLFASTLOOP:MAC-ID2:SequenceError2InDeviceCOSOrCyclicResponse";
    $alarmInfo{"50060072"} = "PM2ALLFASTLOOP:MAC-ID2:LengthInCOSOrCyclicDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"50060073"} = "PM2ALLFASTLOOP:MAC-ID2:UCMMGroupNotSupported";
    $alarmInfo{"50060074"} = "PM2ALLFASTLOOP:MAC-ID2:UnknownHandshakeModeConfigured";
    $alarmInfo{"50060075"} = "PM2ALLFASTLOOP:MAC-ID2:ConfiguredBaudrateNotSupported";
    $alarmInfo{"50060076"} = "PM2ALLFASTLOOP:MAC-ID2:DeviceMAC-IDOutOfRange";
    $alarmInfo{"50060077"} = "PM2ALLFASTLOOP:MAC-ID2:DuplicateMAC-IDDetected";
    $alarmInfo{"50060078"} = "PM2ALLFASTLOOP:MAC-ID2:DatabaseInTheDeviceHasNoEntriesIncluded";
    $alarmInfo{"50060079"} = "PM2ALLFASTLOOP:MAC-ID2:DoubleMAC-IDConfiguredInternally";
    $alarmInfo{"5006007A"} = "PM2ALLFASTLOOP:MAC-ID2:SizeOfOneDeviceDataSetInvalid";
    $alarmInfo{"5006007B"} = "PM2ALLFASTLOOP:MAC-ID2:OffsetTableForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"5006007C"} = "PM2ALLFASTLOOP:MAC-ID2:ConfigurationTableLengthForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"5006007D"} = "PM2ALLFASTLOOP:MAC-ID2:OffsetTableDoNotCorrespondToI/OConfigurationTable";
    $alarmInfo{"5006007E"} = "PM2ALLFASTLOOP:MAC-ID2:SizeIndicatorOfParameterDataTableCorrupt";
    $alarmInfo{"5006007F"} = "PM2ALLFASTLOOP:MAC-ID2:NumberOfInputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"50060080"} = "PM2ALLFASTLOOP:MAC-ID2:NumberOfOutputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"50060081"} = "PM2ALLFASTLOOP:MAC-ID2:UnknownDataTypeInI/OConfiguration";
    $alarmInfo{"50060082"} = "PM2ALLFASTLOOP:MAC-ID2:DataTypeDoesNotCorrespondToItsConfiguredLength";
    $alarmInfo{"50060083"} = "PM2ALLFASTLOOP:MAC-ID2:ConfiguredOutputOffsetAddressOutOfRange";
    $alarmInfo{"50060084"} = "PM2ALLFASTLOOP:MAC-ID2:ConfiguredInputOffsetAddressOutOfRange";
    $alarmInfo{"50060085"} = "PM2ALLFASTLOOP:MAC-ID2:OnePredefinedConnectionTypeIsUnknown";
    $alarmInfo{"50060086"} = "PM2ALLFASTLOOP:MAC-ID2:MultipleConnectionsDefinedInParallel";
    $alarmInfo{"50060087"} = "PM2ALLFASTLOOP:MAC-ID2:ConfiguredEXP_PCKT_RATELessThenPROD_INHIBIT_TIME";
    $alarmInfo{"50060088"} = "PM2ALLFASTLOOP:MAC-ID2:NoDatabaseFoundOnTheSystem";
    $alarmInfo{"50060089"} = "PM2ALLFASTLOOP:MAC-ID2:DatabaseReadingFailure";
    $alarmInfo{"5006008A"} = "PM2ALLFASTLOOP:MAC-ID2:UserWatchdogFailed";
    $alarmInfo{"5006008B"} = "PM2ALLFASTLOOP:MAC-ID2:NoDataAcknowledgeFromUser";
    $alarmInfo{"5006008C"} = "PM2ALLFASTLOOP:MAC-ID2:Unknown";
    $alarmInfo{"5006008D"} = "PM2ALLFASTLOOP:MAC-ID2:Unknown";
    $alarmInfo{"5006008E"} = "PM2ALLFASTLOOP:MAC-ID2:Unknown";
    $alarmInfo{"5006008F"} = "PM2ALLFASTLOOP:MAC-ID2:Unknown";
    $alarmInfo{"50060090"} = "PM2ALLFASTLOOP:MAC-ID3:DeviceGuardingFailed,AfterDeviceWasOperational";
    $alarmInfo{"50060091"} = "PM2ALLFASTLOOP:MAC-ID3:DeviceAccessTimeout";
    $alarmInfo{"50060092"} = "PM2ALLFASTLOOP:MAC-ID3:DeviceRejectsAccessWithUnknownErrorCode";
    $alarmInfo{"50060093"} = "PM2ALLFASTLOOP:MAC-ID3:DeviceResponseInAllocationPhaseWithConnectionError";
    $alarmInfo{"50060094"} = "PM2ALLFASTLOOP:MAC-ID3:ProducedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"50060095"} = "PM2ALLFASTLOOP:MAC-ID3:ConsumedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"50060096"} = "PM2ALLFASTLOOP:MAC-ID3:DeviceServiceResponseTelegramUnknownAndNotHandled";
    $alarmInfo{"50060097"} = "PM2ALLFASTLOOP:MAC-ID3:ConnectionAlreadyInRequest";
    $alarmInfo{"50060098"} = "PM2ALLFASTLOOP:MAC-ID3:NumberOfCAN-messageDataBytesInReadProducedOrConsumedConnectionSizeResponseUnequal4";
    $alarmInfo{"50060099"} = "PM2ALLFASTLOOP:MAC-ID3:PredefinedMaster-slaveConnectionAlreadyExists";
    $alarmInfo{"5006009A"} = "PM2ALLFASTLOOP:MAC-ID3:LengthInPollingDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"5006009B"} = "PM2ALLFASTLOOP:MAC-ID3:SequenceErrorInDevicePollingResponse";
    $alarmInfo{"5006009C"} = "PM2ALLFASTLOOP:MAC-ID3:FragmentErrorInDevicePollingResponse";
    $alarmInfo{"5006009D"} = "PM2ALLFASTLOOP:MAC-ID3:SequenceError2InDevicePollingResponse";
    $alarmInfo{"5006009E"} = "PM2ALLFASTLOOP:MAC-ID3:LengthInBitStrobeDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"5006009F"} = "PM2ALLFASTLOOP:MAC-ID3:SequenceErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"500600A0"} = "PM2ALLFASTLOOP:MAC-ID3:FragmentErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"500600A1"} = "PM2ALLFASTLOOP:MAC-ID3:SequenceError2InDeviceCOSOrCyclicResponse";
    $alarmInfo{"500600A2"} = "PM2ALLFASTLOOP:MAC-ID3:LengthInCOSOrCyclicDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"500600A3"} = "PM2ALLFASTLOOP:MAC-ID3:UCMMGroupNotSupported";
    $alarmInfo{"500600A4"} = "PM2ALLFASTLOOP:MAC-ID3:UnknownHandshakeModeConfigured";
    $alarmInfo{"500600A5"} = "PM2ALLFASTLOOP:MAC-ID3:ConfiguredBaudrateNotSupported";
    $alarmInfo{"500600A6"} = "PM2ALLFASTLOOP:MAC-ID3:DeviceMAC-IDOutOfRange";
    $alarmInfo{"500600A7"} = "PM2ALLFASTLOOP:MAC-ID3:DuplicateMAC-IDDetected";
    $alarmInfo{"500600A8"} = "PM2ALLFASTLOOP:MAC-ID3:DatabaseInTheDeviceHasNoEntriesIncluded";
    $alarmInfo{"500600A9"} = "PM2ALLFASTLOOP:MAC-ID3:DoubleMAC-IDConfiguredInternally";
    $alarmInfo{"500600AA"} = "PM2ALLFASTLOOP:MAC-ID3:SizeOfOneDeviceDataSetInvalid";
    $alarmInfo{"500600AB"} = "PM2ALLFASTLOOP:MAC-ID3:OffsetTableForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"500600AC"} = "PM2ALLFASTLOOP:MAC-ID3:ConfigurationTableLengthForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"500600AD"} = "PM2ALLFASTLOOP:MAC-ID3:OffsetTableDoNotCorrespondToI/OConfigurationTable";
    $alarmInfo{"500600AE"} = "PM2ALLFASTLOOP:MAC-ID3:SizeIndicatorOfParameterDataTableCorrupt";
    $alarmInfo{"500600AF"} = "PM2ALLFASTLOOP:MAC-ID3:NumberOfInputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"500600B0"} = "PM2ALLFASTLOOP:MAC-ID3:NumberOfOutputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"500600B1"} = "PM2ALLFASTLOOP:MAC-ID3:UnknownDataTypeInI/OConfiguration";
    $alarmInfo{"500600B2"} = "PM2ALLFASTLOOP:MAC-ID3:DataTypeDoesNotCorrespondToItsConfiguredLength";
    $alarmInfo{"500600B3"} = "PM2ALLFASTLOOP:MAC-ID3:ConfiguredOutputOffsetAddressOutOfRange";
    $alarmInfo{"500600B4"} = "PM2ALLFASTLOOP:MAC-ID3:ConfiguredInputOffsetAddressOutOfRange";
    $alarmInfo{"500600B5"} = "PM2ALLFASTLOOP:MAC-ID3:OnePredefinedConnectionTypeIsUnknown";
    $alarmInfo{"500600B6"} = "PM2ALLFASTLOOP:MAC-ID3:MultipleConnectionsDefinedInParallel";
    $alarmInfo{"500600B7"} = "PM2ALLFASTLOOP:MAC-ID3:ConfiguredEXP_PCKT_RATELessThenPROD_INHIBIT_TIME";
    $alarmInfo{"500600B8"} = "PM2ALLFASTLOOP:MAC-ID3:NoDatabaseFoundOnTheSystem";
    $alarmInfo{"500600B9"} = "PM2ALLFASTLOOP:MAC-ID3:DatabaseReadingFailure";
    $alarmInfo{"500600BA"} = "PM2ALLFASTLOOP:MAC-ID3:UserWatchdogFailed";
    $alarmInfo{"500600BB"} = "PM2ALLFASTLOOP:MAC-ID3:NoDataAcknowledgeFromUser";
    $alarmInfo{"500600BC"} = "PM2ALLFASTLOOP:MAC-ID3:Unknown";
    $alarmInfo{"500600BD"} = "PM2ALLFASTLOOP:MAC-ID3:Unknown";
    $alarmInfo{"500600BE"} = "PM2ALLFASTLOOP:MAC-ID3:Unknown";
    $alarmInfo{"500600BF"} = "PM2ALLFASTLOOP:MAC-ID3:Unknown";
    $alarmInfo{"500600C0"} = "PM2ALLFASTLOOP:MAC-ID4:DeviceGuardingFailed,AfterDeviceWasOperational";
    $alarmInfo{"500600C1"} = "PM2ALLFASTLOOP:MAC-ID4:DeviceAccessTimeout";
    $alarmInfo{"500600C2"} = "PM2ALLFASTLOOP:MAC-ID4:DeviceRejectsAccessWithUnknownErrorCode";
    $alarmInfo{"500600C3"} = "PM2ALLFASTLOOP:MAC-ID4:DeviceResponseInAllocationPhaseWithConnectionError";
    $alarmInfo{"500600C4"} = "PM2ALLFASTLOOP:MAC-ID4:ProducedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"500600C5"} = "PM2ALLFASTLOOP:MAC-ID4:ConsumedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"500600C6"} = "PM2ALLFASTLOOP:MAC-ID4:DeviceServiceResponseTelegramUnknownAndNotHandled";
    $alarmInfo{"500600C7"} = "PM2ALLFASTLOOP:MAC-ID4:ConnectionAlreadyInRequest";
    $alarmInfo{"500600C8"} = "PM2ALLFASTLOOP:MAC-ID4:NumberOfCAN-messageDataBytesInReadProducedOrConsumedConnectionSizeResponseUnequal4";
    $alarmInfo{"500600C9"} = "PM2ALLFASTLOOP:MAC-ID4:PredefinedMaster-slaveConnectionAlreadyExists";
    $alarmInfo{"500600CA"} = "PM2ALLFASTLOOP:MAC-ID4:LengthInPollingDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"500600CB"} = "PM2ALLFASTLOOP:MAC-ID4:SequenceErrorInDevicePollingResponse";
    $alarmInfo{"500600CC"} = "PM2ALLFASTLOOP:MAC-ID4:FragmentErrorInDevicePollingResponse";
    $alarmInfo{"500600CD"} = "PM2ALLFASTLOOP:MAC-ID4:SequenceError2InDevicePollingResponse";
    $alarmInfo{"500600CE"} = "PM2ALLFASTLOOP:MAC-ID4:LengthInBitStrobeDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"500600CF"} = "PM2ALLFASTLOOP:MAC-ID4:SequenceErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"500600D0"} = "PM2ALLFASTLOOP:MAC-ID4:FragmentErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"500600D1"} = "PM2ALLFASTLOOP:MAC-ID4:SequenceError2InDeviceCOSOrCyclicResponse";
    $alarmInfo{"500600D2"} = "PM2ALLFASTLOOP:MAC-ID4:LengthInCOSOrCyclicDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"500600D3"} = "PM2ALLFASTLOOP:MAC-ID4:UCMMGroupNotSupported";
    $alarmInfo{"500600D4"} = "PM2ALLFASTLOOP:MAC-ID4:UnknownHandshakeModeConfigured";
    $alarmInfo{"500600D5"} = "PM2ALLFASTLOOP:MAC-ID4:ConfiguredBaudrateNotSupported";
    $alarmInfo{"500600D6"} = "PM2ALLFASTLOOP:MAC-ID4:DeviceMAC-IDOutOfRange";
    $alarmInfo{"500600D7"} = "PM2ALLFASTLOOP:MAC-ID4:DuplicateMAC-IDDetected";
    $alarmInfo{"500600D8"} = "PM2ALLFASTLOOP:MAC-ID4:DatabaseInTheDeviceHasNoEntriesIncluded";
    $alarmInfo{"500600D9"} = "PM2ALLFASTLOOP:MAC-ID4:DoubleMAC-IDConfiguredInternally";
    $alarmInfo{"500600DA"} = "PM2ALLFASTLOOP:MAC-ID4:SizeOfOneDeviceDataSetInvalid";
    $alarmInfo{"500600DB"} = "PM2ALLFASTLOOP:MAC-ID4:OffsetTableForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"500600DC"} = "PM2ALLFASTLOOP:MAC-ID4:ConfigurationTableLengthForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"500600DD"} = "PM2ALLFASTLOOP:MAC-ID4:OffsetTableDoNotCorrespondToI/OConfigurationTable";
    $alarmInfo{"500600DE"} = "PM2ALLFASTLOOP:MAC-ID4:SizeIndicatorOfParameterDataTableCorrupt";
    $alarmInfo{"500600DF"} = "PM2ALLFASTLOOP:MAC-ID4:NumberOfInputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"500600E0"} = "PM2ALLFASTLOOP:MAC-ID4:NumberOfOutputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"500600E1"} = "PM2ALLFASTLOOP:MAC-ID4:UnknownDataTypeInI/OConfiguration";
    $alarmInfo{"500600E2"} = "PM2ALLFASTLOOP:MAC-ID4:DataTypeDoesNotCorrespondToItsConfiguredLength";
    $alarmInfo{"500600E3"} = "PM2ALLFASTLOOP:MAC-ID4:ConfiguredOutputOffsetAddressOutOfRange";
    $alarmInfo{"500600E4"} = "PM2ALLFASTLOOP:MAC-ID4:ConfiguredInputOffsetAddressOutOfRange";
    $alarmInfo{"500600E5"} = "PM2ALLFASTLOOP:MAC-ID4:OnePredefinedConnectionTypeIsUnknown";
    $alarmInfo{"500600E6"} = "PM2ALLFASTLOOP:MAC-ID4:MultipleConnectionsDefinedInParallel";
    $alarmInfo{"500600E7"} = "PM2ALLFASTLOOP:MAC-ID4:ConfiguredEXP_PCKT_RATELessThenPROD_INHIBIT_TIME";
    $alarmInfo{"500600E8"} = "PM2ALLFASTLOOP:MAC-ID4:NoDatabaseFoundOnTheSystem";
    $alarmInfo{"500600E9"} = "PM2ALLFASTLOOP:MAC-ID4:DatabaseReadingFailure";
    $alarmInfo{"500600EA"} = "PM2ALLFASTLOOP:MAC-ID4:UserWatchdogFailed";
    $alarmInfo{"500600EB"} = "PM2ALLFASTLOOP:MAC-ID4:NoDataAcknowledgeFromUser";
    $alarmInfo{"500600EC"} = "PM2ALLFASTLOOP:MAC-ID4:Unknown";
    $alarmInfo{"500600ED"} = "PM2ALLFASTLOOP:MAC-ID4:Unknown";
    $alarmInfo{"500600EE"} = "PM2ALLFASTLOOP:MAC-ID4:Unknown";
    $alarmInfo{"500600EF"} = "PM2ALLFASTLOOP:MAC-ID4:Unknown";
    $alarmInfo{"500600F0"} = "PM2ALLFASTLOOP:MAC-ID5:DeviceGuardingFailed,AfterDeviceWasOperational";
    $alarmInfo{"500600F1"} = "PM2ALLFASTLOOP:MAC-ID5:DeviceAccessTimeout";
    $alarmInfo{"500600F2"} = "PM2ALLFASTLOOP:MAC-ID5:DeviceRejectsAccessWithUnknownErrorCode";
    $alarmInfo{"500600F3"} = "PM2ALLFASTLOOP:MAC-ID5:DeviceResponseInAllocationPhaseWithConnectionError";
    $alarmInfo{"500600F4"} = "PM2ALLFASTLOOP:MAC-ID5:ProducedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"500600F5"} = "PM2ALLFASTLOOP:MAC-ID5:ConsumedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"500600F6"} = "PM2ALLFASTLOOP:MAC-ID5:DeviceServiceResponseTelegramUnknownAndNotHandled";
    $alarmInfo{"500600F7"} = "PM2ALLFASTLOOP:MAC-ID5:ConnectionAlreadyInRequest";
    $alarmInfo{"500600F8"} = "PM2ALLFASTLOOP:MAC-ID5:NumberOfCAN-messageDataBytesInReadProducedOrConsumedConnectionSizeResponseUnequal4";
    $alarmInfo{"500600F9"} = "PM2ALLFASTLOOP:MAC-ID5:PredefinedMaster-slaveConnectionAlreadyExists";
    $alarmInfo{"500600FA"} = "PM2ALLFASTLOOP:MAC-ID5:LengthInPollingDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"500600FB"} = "PM2ALLFASTLOOP:MAC-ID5:SequenceErrorInDevicePollingResponse";
    $alarmInfo{"500600FC"} = "PM2ALLFASTLOOP:MAC-ID5:FragmentErrorInDevicePollingResponse";
    $alarmInfo{"500600FD"} = "PM2ALLFASTLOOP:MAC-ID5:SequenceError2InDevicePollingResponse";
    $alarmInfo{"500600FE"} = "PM2ALLFASTLOOP:MAC-ID5:LengthInBitStrobeDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"500600FF"} = "PM2ALLFASTLOOP:MAC-ID5:SequenceErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"50060100"} = "PM2ALLFASTLOOP:MAC-ID5:FragmentErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"50060101"} = "PM2ALLFASTLOOP:MAC-ID5:SequenceError2InDeviceCOSOrCyclicResponse";
    $alarmInfo{"50060102"} = "PM2ALLFASTLOOP:MAC-ID5:LengthInCOSOrCyclicDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"50060103"} = "PM2ALLFASTLOOP:MAC-ID5:UCMMGroupNotSupported";
    $alarmInfo{"50060104"} = "PM2ALLFASTLOOP:MAC-ID5:UnknownHandshakeModeConfigured";
    $alarmInfo{"50060105"} = "PM2ALLFASTLOOP:MAC-ID5:ConfiguredBaudrateNotSupported";
    $alarmInfo{"50060106"} = "PM2ALLFASTLOOP:MAC-ID5:DeviceMAC-IDOutOfRange";
    $alarmInfo{"50060107"} = "PM2ALLFASTLOOP:MAC-ID5:DuplicateMAC-IDDetected";
    $alarmInfo{"50060108"} = "PM2ALLFASTLOOP:MAC-ID5:DatabaseInTheDeviceHasNoEntriesIncluded";
    $alarmInfo{"50060109"} = "PM2ALLFASTLOOP:MAC-ID5:DoubleMAC-IDConfiguredInternally";
    $alarmInfo{"5006010A"} = "PM2ALLFASTLOOP:MAC-ID5:SizeOfOneDeviceDataSetInvalid";
    $alarmInfo{"5006010B"} = "PM2ALLFASTLOOP:MAC-ID5:OffsetTableForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"5006010C"} = "PM2ALLFASTLOOP:MAC-ID5:ConfigurationTableLengthForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"5006010D"} = "PM2ALLFASTLOOP:MAC-ID5:OffsetTableDoNotCorrespondToI/OConfigurationTable";
    $alarmInfo{"5006010E"} = "PM2ALLFASTLOOP:MAC-ID5:SizeIndicatorOfParameterDataTableCorrupt";
    $alarmInfo{"5006010F"} = "PM2ALLFASTLOOP:MAC-ID5:NumberOfInputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"50060110"} = "PM2ALLFASTLOOP:MAC-ID5:NumberOfOutputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"50060111"} = "PM2ALLFASTLOOP:MAC-ID5:UnknownDataTypeInI/OConfiguration";
    $alarmInfo{"50060112"} = "PM2ALLFASTLOOP:MAC-ID5:DataTypeDoesNotCorrespondToItsConfiguredLength";
    $alarmInfo{"50060113"} = "PM2ALLFASTLOOP:MAC-ID5:ConfiguredOutputOffsetAddressOutOfRange";
    $alarmInfo{"50060114"} = "PM2ALLFASTLOOP:MAC-ID5:ConfiguredInputOffsetAddressOutOfRange";
    $alarmInfo{"50060115"} = "PM2ALLFASTLOOP:MAC-ID5:OnePredefinedConnectionTypeIsUnknown";
    $alarmInfo{"50060116"} = "PM2ALLFASTLOOP:MAC-ID5:MultipleConnectionsDefinedInParallel";
    $alarmInfo{"50060117"} = "PM2ALLFASTLOOP:MAC-ID5:ConfiguredEXP_PCKT_RATELessThenPROD_INHIBIT_TIME";
    $alarmInfo{"50060118"} = "PM2ALLFASTLOOP:MAC-ID5:NoDatabaseFoundOnTheSystem";
    $alarmInfo{"50060119"} = "PM2ALLFASTLOOP:MAC-ID5:DatabaseReadingFailure";
    $alarmInfo{"5006011A"} = "PM2ALLFASTLOOP:MAC-ID5:UserWatchdogFailed";
    $alarmInfo{"5006011B"} = "PM2ALLFASTLOOP:MAC-ID5:NoDataAcknowledgeFromUser";
    $alarmInfo{"5006011C"} = "PM2ALLFASTLOOP:MAC-ID5:Unknown";
    $alarmInfo{"5006011D"} = "PM2ALLFASTLOOP:MAC-ID5:Unknown";
    $alarmInfo{"5006011E"} = "PM2ALLFASTLOOP:MAC-ID5:Unknown";
    $alarmInfo{"5006011F"} = "PM2ALLFASTLOOP:MAC-ID5:Unknown";
    $alarmInfo{"50060120"} = "PM2ALLFASTLOOP:MAC-ID6:DeviceGuardingFailed,AfterDeviceWasOperational";
    $alarmInfo{"50060121"} = "PM2ALLFASTLOOP:MAC-ID6:DeviceAccessTimeout";
    $alarmInfo{"50060122"} = "PM2ALLFASTLOOP:MAC-ID6:DeviceRejectsAccessWithUnknownErrorCode";
    $alarmInfo{"50060123"} = "PM2ALLFASTLOOP:MAC-ID6:DeviceResponseInAllocationPhaseWithConnectionError";
    $alarmInfo{"50060124"} = "PM2ALLFASTLOOP:MAC-ID6:ProducedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"50060125"} = "PM2ALLFASTLOOP:MAC-ID6:ConsumedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"50060126"} = "PM2ALLFASTLOOP:MAC-ID6:DeviceServiceResponseTelegramUnknownAndNotHandled";
    $alarmInfo{"50060127"} = "PM2ALLFASTLOOP:MAC-ID6:ConnectionAlreadyInRequest";
    $alarmInfo{"50060128"} = "PM2ALLFASTLOOP:MAC-ID6:NumberOfCAN-messageDataBytesInReadProducedOrConsumedConnectionSizeResponseUnequal4";
    $alarmInfo{"50060129"} = "PM2ALLFASTLOOP:MAC-ID6:PredefinedMaster-slaveConnectionAlreadyExists";
    $alarmInfo{"5006012A"} = "PM2ALLFASTLOOP:MAC-ID6:LengthInPollingDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"5006012B"} = "PM2ALLFASTLOOP:MAC-ID6:SequenceErrorInDevicePollingResponse";
    $alarmInfo{"5006012C"} = "PM2ALLFASTLOOP:MAC-ID6:FragmentErrorInDevicePollingResponse";
    $alarmInfo{"5006012D"} = "PM2ALLFASTLOOP:MAC-ID6:SequenceError2InDevicePollingResponse";
    $alarmInfo{"5006012E"} = "PM2ALLFASTLOOP:MAC-ID6:LengthInBitStrobeDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"5006012F"} = "PM2ALLFASTLOOP:MAC-ID6:SequenceErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"50060130"} = "PM2ALLFASTLOOP:MAC-ID6:FragmentErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"50060131"} = "PM2ALLFASTLOOP:MAC-ID6:SequenceError2InDeviceCOSOrCyclicResponse";
    $alarmInfo{"50060132"} = "PM2ALLFASTLOOP:MAC-ID6:LengthInCOSOrCyclicDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"50060133"} = "PM2ALLFASTLOOP:MAC-ID6:UCMMGroupNotSupported";
    $alarmInfo{"50060134"} = "PM2ALLFASTLOOP:MAC-ID6:UnknownHandshakeModeConfigured";
    $alarmInfo{"50060135"} = "PM2ALLFASTLOOP:MAC-ID6:ConfiguredBaudrateNotSupported";
    $alarmInfo{"50060136"} = "PM2ALLFASTLOOP:MAC-ID6:DeviceMAC-IDOutOfRange";
    $alarmInfo{"50060137"} = "PM2ALLFASTLOOP:MAC-ID6:DuplicateMAC-IDDetected";
    $alarmInfo{"50060138"} = "PM2ALLFASTLOOP:MAC-ID6:DatabaseInTheDeviceHasNoEntriesIncluded";
    $alarmInfo{"50060139"} = "PM2ALLFASTLOOP:MAC-ID6:DoubleMAC-IDConfiguredInternally";
    $alarmInfo{"5006013A"} = "PM2ALLFASTLOOP:MAC-ID6:SizeOfOneDeviceDataSetInvalid";
    $alarmInfo{"5006013B"} = "PM2ALLFASTLOOP:MAC-ID6:OffsetTableForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"5006013C"} = "PM2ALLFASTLOOP:MAC-ID6:ConfigurationTableLengthForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"5006013D"} = "PM2ALLFASTLOOP:MAC-ID6:OffsetTableDoNotCorrespondToI/OConfigurationTable";
    $alarmInfo{"5006013E"} = "PM2ALLFASTLOOP:MAC-ID6:SizeIndicatorOfParameterDataTableCorrupt";
    $alarmInfo{"5006013F"} = "PM2ALLFASTLOOP:MAC-ID6:NumberOfInputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"50060140"} = "PM2ALLFASTLOOP:MAC-ID6:NumberOfOutputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"50060141"} = "PM2ALLFASTLOOP:MAC-ID6:UnknownDataTypeInI/OConfiguration";
    $alarmInfo{"50060142"} = "PM2ALLFASTLOOP:MAC-ID6:DataTypeDoesNotCorrespondToItsConfiguredLength";
    $alarmInfo{"50060143"} = "PM2ALLFASTLOOP:MAC-ID6:ConfiguredOutputOffsetAddressOutOfRange";
    $alarmInfo{"50060144"} = "PM2ALLFASTLOOP:MAC-ID6:ConfiguredInputOffsetAddressOutOfRange";
    $alarmInfo{"50060145"} = "PM2ALLFASTLOOP:MAC-ID6:OnePredefinedConnectionTypeIsUnknown";
    $alarmInfo{"50060146"} = "PM2ALLFASTLOOP:MAC-ID6:MultipleConnectionsDefinedInParallel";
    $alarmInfo{"50060147"} = "PM2ALLFASTLOOP:MAC-ID6:ConfiguredEXP_PCKT_RATELessThenPROD_INHIBIT_TIME";
    $alarmInfo{"50060148"} = "PM2ALLFASTLOOP:MAC-ID6:NoDatabaseFoundOnTheSystem";
    $alarmInfo{"50060149"} = "PM2ALLFASTLOOP:MAC-ID6:DatabaseReadingFailure";
    $alarmInfo{"5006014A"} = "PM2ALLFASTLOOP:MAC-ID6:UserWatchdogFailed";
    $alarmInfo{"5006014B"} = "PM2ALLFASTLOOP:MAC-ID6:NoDataAcknowledgeFromUser";
    $alarmInfo{"5006014C"} = "PM2ALLFASTLOOP:MAC-ID6:Unknown";
    $alarmInfo{"5006014D"} = "PM2ALLFASTLOOP:MAC-ID6:Unknown";
    $alarmInfo{"5006014E"} = "PM2ALLFASTLOOP:MAC-ID6:Unknown";
    $alarmInfo{"5006014F"} = "PM2ALLFASTLOOP:MAC-ID6:Unknown";
    $alarmInfo{"50060150"} = "PM2ALLFASTLOOP:CIF/DRIVER:BoardNotInitialized";
    $alarmInfo{"50060151"} = "PM2ALLFASTLOOP:CIF/DRIVER:ErrorInInternalInitState";
    $alarmInfo{"50060152"} = "PM2ALLFASTLOOP:CIF/DRIVER:ErrorInInternalReadState";
    $alarmInfo{"50060153"} = "PM2ALLFASTLOOP:CIF/DRIVER:CommandOnThisChannelIsActive";
    $alarmInfo{"50060154"} = "PM2ALLFASTLOOP:CIF/DRIVER:UnknownParameterInFunctionOccurred";
    $alarmInfo{"50060155"} = "PM2ALLFASTLOOP:CIF/DRIVER:VersionIsIncompatibleWithDLL";
    $alarmInfo{"50060156"} = "PM2ALLFASTLOOP:CIF/DRIVER:ErrorDuringPCISetConfigMode";
    $alarmInfo{"50060157"} = "PM2ALLFASTLOOP:CIF/DRIVER:CouldNotReadPCIDualPortMemoryLength";
    $alarmInfo{"50060158"} = "PM2ALLFASTLOOP:CIF/DRIVER:ErrorDuringPCISetRunMode";
    $alarmInfo{"50060159"} = "PM2ALLFASTLOOP:CIF/DRIVER:DualPortRamNotAccessibleBoardNotFound)";
    $alarmInfo{"5006015A"} = "PM2ALLFASTLOOP:CIF/DRIVER:NotReadyReady";
    $alarmInfo{"5006015B"} = "PM2ALLFASTLOOP:CIF/DRIVER:NotRunningRunning";
    $alarmInfo{"5006015C"} = "PM2ALLFASTLOOP:CIF/DRIVER:WatchdogTestFailed";
    $alarmInfo{"5006015D"} = "PM2ALLFASTLOOP:CIF/DRIVER:SignalsWrongOSVersion";
    $alarmInfo{"5006015E"} = "PM2ALLFASTLOOP:CIF/DRIVER:ErrorInDualPort";
    $alarmInfo{"5006015F"} = "PM2ALLFASTLOOP:CIF/DRIVER:SendMailboxIsFull";
    $alarmInfo{"50060160"} = "PM2ALLFASTLOOP:CIF/DRIVER:PutMessageTimeout";
    $alarmInfo{"50060161"} = "PM2ALLFASTLOOP:CIF/DRIVER:GetMessageTimeout";
    $alarmInfo{"50060162"} = "PM2ALLFASTLOOP:CIF/DRIVER:NoMessageAvailable";
    $alarmInfo{"50060163"} = "PM2ALLFASTLOOP:CIF/DRIVER:RESETCommandTimeout";
    $alarmInfo{"50060164"} = "PM2ALLFASTLOOP:CIF/DRIVER:COM-flagsNotSet";
    $alarmInfo{"50060165"} = "PM2ALLFASTLOOP:CIF/DRIVER:I/ODataExchangeFailed";
    $alarmInfo{"50060166"} = "PM2ALLFASTLOOP:CIF/DRIVER:I/ODataExchangeTimeout";
    $alarmInfo{"50060167"} = "PM2ALLFASTLOOP:CIF/DRIVER:I/ODataModeUnknown";
    $alarmInfo{"50060168"} = "PM2ALLFASTLOOP:CIF/DRIVER:FunctionCallFailed";
    $alarmInfo{"50060169"} = "PM2ALLFASTLOOP:CIF/DRIVER:DualPortMemorySizeDiffersFromConfiguration";
    $alarmInfo{"5006016A"} = "PM2ALLFASTLOOP:CIF/DRIVER:StateModeUnknown";
    $alarmInfo{"5006016B"} = "PM2ALLFASTLOOP:CIF/DRIVER:HardwarePortIsUsed";
    $alarmInfo{"5006016C"} = "PM2ALLFASTLOOP:CIF/USER:DriverNotOpenedDeviceDriverNotLoaded)";
    $alarmInfo{"5006016D"} = "PM2ALLFASTLOOP:CIF/USER:CannotConnectWithDevice";
    $alarmInfo{"5006016E"} = "PM2ALLFASTLOOP:CIF/USER:BoardNotInitializedDevInitBoardNotCalled)";
    $alarmInfo{"5006016F"} = "PM2ALLFASTLOOP:CIF/USER:IOCTRLFunctionFailed";
    $alarmInfo{"50060170"} = "PM2ALLFASTLOOP:CIF/USER:ParameterDeviceNumberInvalid";
    $alarmInfo{"50060171"} = "PM2ALLFASTLOOP:CIF/USER:ParameterInfoAreaUnknown";
    $alarmInfo{"50060172"} = "PM2ALLFASTLOOP:CIF/USER:ParameterNumberInvalid";
    $alarmInfo{"50060173"} = "PM2ALLFASTLOOP:CIF/USER:ParameterModeInvalid";
    $alarmInfo{"50060174"} = "PM2ALLFASTLOOP:CIF/USER:NULLPointerAssignment";
    $alarmInfo{"50060175"} = "PM2ALLFASTLOOP:CIF/USER:MessageBufferTooShort";
    $alarmInfo{"50060176"} = "PM2ALLFASTLOOP:CIF/USER:ParameterSizeInvalid";
    $alarmInfo{"50060177"} = "PM2ALLFASTLOOP:CIF/USER:ParameterSizeWithZeroLength";
    $alarmInfo{"50060178"} = "PM2ALLFASTLOOP:CIF/USER:ParameterSizeTooLong";
    $alarmInfo{"50060179"} = "PM2ALLFASTLOOP:CIF/USER:DeviceAddressNullPointer";
    $alarmInfo{"5006017A"} = "PM2ALLFASTLOOP:CIF/USER:PointerToBufferIsANullPointer";
    $alarmInfo{"5006017B"} = "PM2ALLFASTLOOP:CIF/USER:ParameterSendSizeTooLong";
    $alarmInfo{"5006017C"} = "PM2ALLFASTLOOP:CIF/USER:ParameterReceiveSizeTooLong";
    $alarmInfo{"5006017D"} = "PM2ALLFASTLOOP:CIF/USER:PointerToSendBufferIsANullPointer";
    $alarmInfo{"5006017E"} = "PM2ALLFASTLOOP:CIF/USER:PointerToReceiveBufferIsANullPointer";
    $alarmInfo{"5006017F"} = "PM2ALLFASTLOOP:CIF/DMA:MemoryAllocationError";
    $alarmInfo{"50060180"} = "PM2ALLFASTLOOP:CIF/DMA:ReadI/OTimeout";
    $alarmInfo{"50060181"} = "PM2ALLFASTLOOP:CIF/DMA:WriteI/OTimeout";
    $alarmInfo{"50060182"} = "PM2ALLFASTLOOP:CIF/DMA:PCITransferTimeout";
    $alarmInfo{"50060183"} = "PM2ALLFASTLOOP:CIF/DMA:DownloadTimeout";
    $alarmInfo{"50060184"} = "PM2ALLFASTLOOP:CIF/DMA:DatabaseDownloadFailed";
    $alarmInfo{"50060185"} = "PM2ALLFASTLOOP:CIF/DMA:FirmwareDownloadFailed";
    $alarmInfo{"50060186"} = "PM2ALLFASTLOOP:CIF/DMA:ClearDatabaseOnTheDeviceFailed";
    $alarmInfo{"50060187"} = "PM2ALLFASTLOOP:CIF/USER:VirtualMemoryNotAvailable";
    $alarmInfo{"50060188"} = "PM2ALLFASTLOOP:CIF/USER:UnmapVirtualMemoryFailed";
    $alarmInfo{"50060189"} = "PM2ALLFASTLOOP:CIF/DRIVER:GeneralError";
    $alarmInfo{"5006018A"} = "PM2ALLFASTLOOP:CIF/DRIVER:GeneralDMAError";
    $alarmInfo{"5006018B"} = "PM2ALLFASTLOOP:CIF/DRIVER:BatteryError";
    $alarmInfo{"5006018C"} = "PM2ALLFASTLOOP:CIF/DRIVER:PowerFailedError";
    $alarmInfo{"5006018D"} = "PM2ALLFASTLOOP:CIF/USER:DriverUnknown";
    $alarmInfo{"5006018E"} = "PM2ALLFASTLOOP:CIF/USER:DeviceNameInvalid";
    $alarmInfo{"5006018F"} = "PM2ALLFASTLOOP:CIF/USER:DeviceNameUnknown";
    $alarmInfo{"50060190"} = "PM2ALLFASTLOOP:CIF/USER:DeviceFunctionNotImplemented";
    $alarmInfo{"50060191"} = "PM2ALLFASTLOOP:CIF/USER:FileNotOpened";
    $alarmInfo{"50060192"} = "PM2ALLFASTLOOP:CIF/USER:FileSizeZero";
    $alarmInfo{"50060193"} = "PM2ALLFASTLOOP:CIF/USER:NotEnoughMemoryToLoadFile";
    $alarmInfo{"50060194"} = "PM2ALLFASTLOOP:CIF/USER:FileReadFailed";
    $alarmInfo{"50060195"} = "PM2ALLFASTLOOP:CIF/USER:FileTypeInvalid";
    $alarmInfo{"50060196"} = "PM2ALLFASTLOOP:CIF/USER:FileNameNotValid";
    $alarmInfo{"50060197"} = "PM2ALLFASTLOOP:CIF/USER:FirmwareFileNotOpened";
    $alarmInfo{"50060198"} = "PM2ALLFASTLOOP:CIF/USER:FirmwareFileSizeZero";
    $alarmInfo{"50060199"} = "PM2ALLFASTLOOP:CIF/USER:NotEnoughMemoryToLoadFirmwareFile";
    $alarmInfo{"5006019A"} = "PM2ALLFASTLOOP:CIF/USER:FirmwareFileReadFailed";
    $alarmInfo{"5006019B"} = "PM2ALLFASTLOOP:CIF/USER:FirmwareFileTypeInvalid";
    $alarmInfo{"5006019C"} = "PM2ALLFASTLOOP:CIF/USER:FirmwareFileNameNotValid";
    $alarmInfo{"5006019D"} = "PM2ALLFASTLOOP:CIF/USER:FirmwareFileDownloadError";
    $alarmInfo{"5006019E"} = "PM2ALLFASTLOOP:CIF/USER:FirmwareFileNotFoundInTheInternalTable";
    $alarmInfo{"5006019F"} = "PM2ALLFASTLOOP:CIF/USER:FirmwareFileBOOTLOADERActive";
    $alarmInfo{"500601A0"} = "PM2ALLFASTLOOP:CIF/USER:FirmwareFileNotFilePath";
    $alarmInfo{"500601A1"} = "PM2ALLFASTLOOP:CIF/USER:ConfigurationFileNotOpened";
    $alarmInfo{"500601A2"} = "PM2ALLFASTLOOP:CIF/USER:ConfigurationFileSizeZero";
    $alarmInfo{"500601A3"} = "PM2ALLFASTLOOP:CIF/USER:NotEnoughMemoryToLoadConfigurationFile";
    $alarmInfo{"500601A4"} = "PM2ALLFASTLOOP:CIF/USER:ConfigurationFileReadFailed";
    $alarmInfo{"500601A5"} = "PM2ALLFASTLOOP:CIF/USER:ConfigurationFileTypeInvalid";
    $alarmInfo{"500601A6"} = "PM2ALLFASTLOOP:CIF/USER:ConfigurationFileNameNotValid";
    $alarmInfo{"500601A7"} = "PM2ALLFASTLOOP:CIF/USER:ConfigurationFileDownloadError";
    $alarmInfo{"500601A8"} = "PM2ALLFASTLOOP:CIF/USER:NoFlashSegmentInTheConfigurationFile";
    $alarmInfo{"500601A9"} = "PM2ALLFASTLOOP:CIF/USER:ConfigurationFileDiffersFromDatabase";
    $alarmInfo{"500601AA"} = "PM2ALLFASTLOOP:CIF/USER:DatabaseSizeZero";
    $alarmInfo{"500601AB"} = "PM2ALLFASTLOOP:CIF/USER:NotEnoughMemoryToUploadDatabase";
    $alarmInfo{"500601AC"} = "PM2ALLFASTLOOP:CIF/USER:DatabaseReadFailed";
    $alarmInfo{"500601AD"} = "PM2ALLFASTLOOP:CIF/USER:DatabaseSegmentUnknown";
    $alarmInfo{"500601AE"} = "PM2ALLFASTLOOP:CIF/CONFIG:VersionOfTheDescriptTableInvalid";
    $alarmInfo{"500601AF"} = "PM2ALLFASTLOOP:CIF/CONFIG:InputOffsetIsInvalid";
    $alarmInfo{"500601B0"} = "PM2ALLFASTLOOP:CIF/CONFIG:InputSizeIs0";
    $alarmInfo{"500601B1"} = "PM2ALLFASTLOOP:CIF/CONFIG:InputSizeDoesNotMatchConfiguration";
    $alarmInfo{"500601B2"} = "PM2ALLFASTLOOP:CIF/CONFIG:OutputOffsetIsInvalid";
    $alarmInfo{"500601B3"} = "PM2ALLFASTLOOP:CIF/CONFIG:OutputSizeIs0";
    $alarmInfo{"500601B4"} = "PM2ALLFASTLOOP:CIF/CONFIG:OutputSizeDoesNotMatchConfiguration";
    $alarmInfo{"500601B5"} = "PM2ALLFASTLOOP:CIF/CONFIG:StationNotConfigured";
    $alarmInfo{"500601B6"} = "PM2ALLFASTLOOP:CIF/CONFIG:CannotGetTheStationConfiguration";
    $alarmInfo{"500601B7"} = "PM2ALLFASTLOOP:CIF/CONFIG:ModuleDefinitionIsMissing";
    $alarmInfo{"500601B8"} = "PM2ALLFASTLOOP:CIF/CONFIG:EmptySlotMismatch";
    $alarmInfo{"500601B9"} = "PM2ALLFASTLOOP:CIF/CONFIG:InputOffsetMismatch";
    $alarmInfo{"500601BA"} = "PM2ALLFASTLOOP:CIF/CONFIG:OutputOffsetMismatch";
    $alarmInfo{"500601BB"} = "PM2ALLFASTLOOP:CIF/CONFIG:DataTypeMismatch";
    $alarmInfo{"500601BC"} = "PM2ALLFASTLOOP:CIF/CONFIG:ModuleDefinitionIsMissing,NoSlot/Idx)";
    $alarmInfo{"500601BD"} = "PM2ALLFASTLOOP:CIF:Unknown";
    $alarmInfo{"500601BE"} = "PM2ALLFASTLOOP:Unknown";
    $alarmInfo{"500601BF"} = "PM2ALLFASTLOOP:Unknown";
    $alarmInfo{"500601C0"} = "PM2ALLDeviceNetMacID0CommunicationLost";
    $alarmInfo{"500601C1"} = "PM2ALLDeviceNetMacID1CommunicationLost";
    $alarmInfo{"500601C2"} = "PM2ALLDeviceNetMacID2CommunicationLost";
    $alarmInfo{"500601C3"} = "PM2ALLDeviceNetMacID3CommunicationLost";
    $alarmInfo{"500601C4"} = "PM2ALLDeviceNetMacID4CommunicationLost";
    $alarmInfo{"500601C5"} = "PM2ALLDeviceNetMacID5CommunicationLost";
    $alarmInfo{"500601C6"} = "PM2ALLDeviceNetMacID6CommunicationLost";
    $alarmInfo{"500601C7"} = "PM2ALLDeviceNetMacID7CommunicationLost";
    $alarmInfo{"500601C8"} = "PM2ALLDeviceNetMacID8CommunicationLost";
    $alarmInfo{"500601C9"} = "PM2ALLDeviceNetMacID9CommunicationLost";
    $alarmInfo{"500601CA"} = "PM2ALLDeviceNetMacID10CommunicationLost";
    $alarmInfo{"500601CB"} = "PM2ALLDeviceNetMacID11CommunicationLost";
    $alarmInfo{"500601CC"} = "PM2ALLDeviceNetMacID12CommunicationLost";
    $alarmInfo{"500601CD"} = "PM2ALLDeviceNetMacID13CommunicationLost";
    $alarmInfo{"500601CE"} = "PM2ALLDeviceNetMacID14CommunicationLost";
    $alarmInfo{"500601CF"} = "PM2ALLDeviceNetMacID15CommunicationLost";
    $alarmInfo{"500601D0"} = "PM2ALLDeviceNetMacID16CommunicationLost";
    $alarmInfo{"500601D1"} = "PM2ALLDeviceNetMacID17CommunicationLost";
    $alarmInfo{"500601D2"} = "PM2ALLDeviceNetMacID18CommunicationLost";
    $alarmInfo{"500601D3"} = "PM2ALLDeviceNetMacID19CommunicationLost";
    $alarmInfo{"500601D4"} = "PM2ALLDeviceNetMacID20CommunicationLost";
    $alarmInfo{"500601D5"} = "PM2ALLDeviceNetMacID21CommunicationLost";
    $alarmInfo{"500601D6"} = "PM2ALLDeviceNetMacID22CommunicationLost";
    $alarmInfo{"500601D7"} = "PM2ALLDeviceNetMacID23CommunicationLost";
    $alarmInfo{"500601D8"} = "PM2ALLDeviceNetMacID24CommunicationLost";
    $alarmInfo{"500601D9"} = "PM2ALLDeviceNetMacID25CommunicationLost";
    $alarmInfo{"500601DA"} = "PM2ALLDeviceNetMacID26CommunicationLost";
    $alarmInfo{"500601DB"} = "PM2ALLDeviceNetMacID27CommunicationLost";
    $alarmInfo{"500601DC"} = "PM2ALLDeviceNetMacID28CommunicationLost";
    $alarmInfo{"500601DD"} = "PM2ALLDeviceNetMacID29CommunicationLost";
    $alarmInfo{"500601DE"} = "PM2ALLDeviceNetMacID30CommunicationLost";
    $alarmInfo{"500601DF"} = "PM2ALLDeviceNetMacID31CommunicationLost";
    $alarmInfo{"500601E0"} = "PM2ALLDeviceNetMacID32CommunicationLost";
    $alarmInfo{"500601E1"} = "PM2ALLDeviceNetMacID33CommunicationLost";
    $alarmInfo{"500601E2"} = "PM2ALLDeviceNetMacID34CommunicationLost";
    $alarmInfo{"500601E3"} = "PM2ALLDeviceNetMacID35CommunicationLost";
    $alarmInfo{"500601E4"} = "PM2ALLDeviceNetMacID36CommunicationLost";
    $alarmInfo{"500601E5"} = "PM2ALLDeviceNetMacID37CommunicationLost";
    $alarmInfo{"500601E6"} = "PM2ALLDeviceNetMacID38CommunicationLost";
    $alarmInfo{"500601E7"} = "PM2ALLDeviceNetMacID39CommunicationLost";
    $alarmInfo{"500601E8"} = "PM2ALLDeviceNetMacID40CommunicationLost";
    $alarmInfo{"500601E9"} = "PM2ALLDeviceNetMacID41CommunicationLost";
    $alarmInfo{"500601EA"} = "PM2ALLDeviceNetMacID42CommunicationLost";
    $alarmInfo{"500601EB"} = "PM2ALLDeviceNetMacID43CommunicationLost";
    $alarmInfo{"500601EC"} = "PM2ALLDeviceNetMacID44CommunicationLost";
    $alarmInfo{"500601ED"} = "PM2ALLDeviceNetMacID45CommunicationLost";
    $alarmInfo{"500601EE"} = "PM2ALLDeviceNetMacID46CommunicationLost";
    $alarmInfo{"500601EF"} = "PM2ALLDeviceNetMacID47CommunicationLost";
    $alarmInfo{"500601F0"} = "PM2ALLDeviceNetMacID48CommunicationLost";
    $alarmInfo{"500601F1"} = "PM2ALLDeviceNetMacID49CommunicationLost";
    $alarmInfo{"500601F2"} = "PM2ALLDeviceNetMacID50CommunicationLost";
    $alarmInfo{"500601F3"} = "PM2ALLDeviceNetMacID51CommunicationLost";
    $alarmInfo{"500601F4"} = "PM2ALLDeviceNetMacID52CommunicationLost";
    $alarmInfo{"500601F5"} = "PM2ALLDeviceNetMacID53CommunicationLost";
    $alarmInfo{"500601F6"} = "PM2ALLDeviceNetMacID54CommunicationLost";
    $alarmInfo{"500601F7"} = "PM2ALLDeviceNetMacID55CommunicationLost";
    $alarmInfo{"500601F8"} = "PM2ALLDeviceNetMacID56CommunicationLost";
    $alarmInfo{"500601F9"} = "PM2ALLDeviceNetMacID57CommunicationLost";
    $alarmInfo{"500601FA"} = "PM2ALLDeviceNetMacID58CommunicationLost";
    $alarmInfo{"500601FB"} = "PM2ALLDeviceNetMacID59CommunicationLost";
    $alarmInfo{"500601FC"} = "PM2ALLDeviceNetMacID60CommunicationLost";
    $alarmInfo{"500601FD"} = "PM2ALLDeviceNetMacID61CommunicationLost";
    $alarmInfo{"500601FE"} = "PM2ALLDeviceNetMacID62CommunicationLost";
    $alarmInfo{"500601FF"} = "PM2ALLDeviceNetMacID63CommunicationLost";
    $alarmInfo{"50060240"} = "PM2ALLDeviceNetMacID0Error";
    $alarmInfo{"50060241"} = "PM2ALLDeviceNetMacID1Error";
    $alarmInfo{"50060242"} = "PM2ALLDeviceNetMacID2Error";
    $alarmInfo{"50060243"} = "PM2ALLDeviceNetMacID3Error";
    $alarmInfo{"50060244"} = "PM2ALLDeviceNetMacID4Error";
    $alarmInfo{"50060245"} = "PM2ALLDeviceNetMacID5Error";
    $alarmInfo{"50060246"} = "PM2ALLDeviceNetMacID6Error";
    $alarmInfo{"50060247"} = "PM2ALLDeviceNetMacID7Error";
    $alarmInfo{"50060248"} = "PM2ALLDeviceNetMacID8Error";
    $alarmInfo{"50060249"} = "PM2ALLDeviceNetMacID9Error";
    $alarmInfo{"5006024A"} = "PM2ALLDeviceNetMacID10Error";
    $alarmInfo{"5006024B"} = "PM2ALLDeviceNetMacID11Error";
    $alarmInfo{"5006024C"} = "PM2ALLDeviceNetMacID12Error";
    $alarmInfo{"5006024D"} = "PM2ALLDeviceNetMacID13Error";
    $alarmInfo{"5006024E"} = "PM2ALLDeviceNetMacID14Error";
    $alarmInfo{"5006024F"} = "PM2ALLDeviceNetMacID15Error";
    $alarmInfo{"50060250"} = "PM2ALLDeviceNetMacID16Error";
    $alarmInfo{"50060251"} = "PM2ALLDeviceNetMacID17Error";
    $alarmInfo{"50060252"} = "PM2ALLDeviceNetMacID18Error";
    $alarmInfo{"50060253"} = "PM2ALLDeviceNetMacID19Error";
    $alarmInfo{"50060254"} = "PM2ALLDeviceNetMacID20Error";
    $alarmInfo{"50060255"} = "PM2ALLDeviceNetMacID21Error";
    $alarmInfo{"50060256"} = "PM2ALLDeviceNetMacID22Error";
    $alarmInfo{"50060257"} = "PM2ALLDeviceNetMacID23Error";
    $alarmInfo{"50060258"} = "PM2ALLDeviceNetMacID24Error";
    $alarmInfo{"50060259"} = "PM2ALLDeviceNetMacID25Error";
    $alarmInfo{"5006025A"} = "PM2ALLDeviceNetMacID26Error";
    $alarmInfo{"5006025B"} = "PM2ALLDeviceNetMacID27Error";
    $alarmInfo{"5006025C"} = "PM2ALLDeviceNetMacID28Error";
    $alarmInfo{"5006025D"} = "PM2ALLDeviceNetMacID29Error";
    $alarmInfo{"5006025E"} = "PM2ALLDeviceNetMacID30Error";
    $alarmInfo{"5006025F"} = "PM2ALLDeviceNetMacID31Error";
    $alarmInfo{"50060260"} = "PM2ALLDeviceNetMacID32Error";
    $alarmInfo{"50060261"} = "PM2ALLDeviceNetMacID33Error";
    $alarmInfo{"50060262"} = "PM2ALLDeviceNetMacID34Error";
    $alarmInfo{"50060263"} = "PM2ALLDeviceNetMacID35Error";
    $alarmInfo{"50060264"} = "PM2ALLDeviceNetMacID36Error";
    $alarmInfo{"50060265"} = "PM2ALLDeviceNetMacID37Error";
    $alarmInfo{"50060266"} = "PM2ALLDeviceNetMacID38Error";
    $alarmInfo{"50060267"} = "PM2ALLDeviceNetMacID39Error";
    $alarmInfo{"50060268"} = "PM2ALLDeviceNetMacID40Error";
    $alarmInfo{"50060269"} = "PM2ALLDeviceNetMacID41Error";
    $alarmInfo{"5006026A"} = "PM2ALLDeviceNetMacID42Error";
    $alarmInfo{"5006026B"} = "PM2ALLDeviceNetMacID43Error";
    $alarmInfo{"5006026C"} = "PM2ALLDeviceNetMacID44Error";
    $alarmInfo{"5006026D"} = "PM2ALLDeviceNetMacID45Error";
    $alarmInfo{"5006026E"} = "PM2ALLDeviceNetMacID46Error";
    $alarmInfo{"5006026F"} = "PM2ALLDeviceNetMacID47Error";
    $alarmInfo{"50060270"} = "PM2ALLDeviceNetMacID48Error";
    $alarmInfo{"50060271"} = "PM2ALLDeviceNetMacID49Error";
    $alarmInfo{"50060272"} = "PM2ALLDeviceNetMacID50Error";
    $alarmInfo{"50060273"} = "PM2ALLDeviceNetMacID51Error";
    $alarmInfo{"50060274"} = "PM2ALLDeviceNetMacID52Error";
    $alarmInfo{"50060275"} = "PM2ALLDeviceNetMacID53Error";
    $alarmInfo{"50060276"} = "PM2ALLDeviceNetMacID54Error";
    $alarmInfo{"50060277"} = "PM2ALLDeviceNetMacID55Error";
    $alarmInfo{"50060278"} = "PM2ALLDeviceNetMacID56Error";
    $alarmInfo{"50060279"} = "PM2ALLDeviceNetMacID57Error";
    $alarmInfo{"5006027A"} = "PM2ALLDeviceNetMacID58Error";
    $alarmInfo{"5006027B"} = "PM2ALLDeviceNetMacID59Error";
    $alarmInfo{"5006027C"} = "PM2ALLDeviceNetMacID60Error";
    $alarmInfo{"5006027D"} = "PM2ALLDeviceNetMacID61Error";
    $alarmInfo{"5006027E"} = "PM2ALLDeviceNetMacID62Error";
    $alarmInfo{"5006027F"} = "PM2ALLDeviceNetMacID63Error";
    $alarmInfo{"5010000"} = "UIOAlarmCleared";
    $alarmInfo{"5010001"} = "UIOAlarmDetected";
    $alarmInfo{"51060000"} = "SYN51060000";
    $alarmInfo{"51060001"} = "TCCommunicationTimeout";
    $alarmInfo{"51060002"} = "ADSCommunicationTimeout";
    $alarmInfo{"51060003"} = "ADSWatchDogAlarmOccurred";
    $alarmInfo{"51060004"} = "ConfigurationFileOrRecipeFileNotReceived";
    $alarmInfo{"51060005"} = "StatusIsNotREADY";
    $alarmInfo{"51060006"} = "StatusIsRUN";
    $alarmInfo{"51060007"} = "StatusIsNotRUN";
    $alarmInfo{"51060008"} = "NoStartStepExistsInTheSpecifiedRecipe";
    $alarmInfo{"51060009"} = "PressureValueAnd1atmSensorMismatch";
    $alarmInfo{"5106000A"} = "AlarmOccurred";
    $alarmInfo{"5106000B"} = "PauseOccurred";
    $alarmInfo{"5106000C"} = "SafetyOccurred";
    $alarmInfo{"5106000D"} = "AbortOccurred";
    $alarmInfo{"5106000E"} = "OtherErrorOccurred";
    $alarmInfo{"51060010"} = "SeriousAlarmNonRecipe)Occurred";
    $alarmInfo{"51060011"} = "LightAlarmNonRecipe)Occurred";
    $alarmInfo{"51060012"} = "SafetyLatchAlarmOccurred";
    $alarmInfo{"51060013"} = "MaintenanceAlarmOccurred";
    $alarmInfo{"51060014"} = "DIMaintenanceAlarmOccurred";
    $alarmInfo{"51060020"} = "CapabilityIsAborted";
    $alarmInfo{"51060021"} = "Purge-CurtainStatusIsNot-Active";
    $alarmInfo{"51060022"} = "NoWafersAvailableForPeriodicDummy";
    $alarmInfo{"51060023"} = "WarningCountNearingAutoCleanLimit";
    $alarmInfo{"51060024"} = "WarningCountNearingAutoPurgeLimit";
    $alarmInfo{"51060025"} = "WarningCountNearingAutoDummyLimit";
    $alarmInfo{"51060026"} = "CoolingWaterLeak";
    $alarmInfo{"51060027"} = "CoolingWaterLeak2";
    $alarmInfo{"51060028"} = "SmokeDetected";
    $alarmInfo{"51060029"} = "HClDetectedBySensor";
    $alarmInfo{"5106002A"} = "LiquidLeakDetected";
    $alarmInfo{"5106002B"} = "LiquidLeak2Detected";
    $alarmInfo{"5106002C"} = "H2Detected";
    $alarmInfo{"5106002D"} = "Cl2Detected";
    $alarmInfo{"5106002E"} = "NH3Detected";
    $alarmInfo{"5106002F"} = "EmeraldHIGFlowControlDisabled";
    $alarmInfo{"51060040"} = "ModuleNotResponding";
    $alarmInfo{"51060041"} = "HoldToAbortTimeout";
    $alarmInfo{"51060042"} = "SlotValveOpen";
    $alarmInfo{"51060043"} = "PC104PMCommunicationsDisconnected";
    $alarmInfo{"51060044"} = "MustRunSERVICEStartupRecipe";
    $alarmInfo{"51060045"} = "InvalidSERVICERecipeType";
    $alarmInfo{"51060046"} = "LocalRackLockedUp";
    $alarmInfo{"51060047"} = "Gas1FlowToleranceFault";
    $alarmInfo{"51060048"} = "Gas2FlowToleranceFault";
    $alarmInfo{"51060049"} = "Gas3FlowToleranceFault";
    $alarmInfo{"5106004A"} = "Gas4FlowToleranceFault";
    $alarmInfo{"5106004B"} = "HivacFailedToOpen";
    $alarmInfo{"5106004C"} = "HivacFailedToClose";
    $alarmInfo{"5106004D"} = "PumpToBaseFailed";
    $alarmInfo{"5106004E"} = "RoughingTimeout";
    $alarmInfo{"5106004F"} = "RoughingPressureTooHigh";
    $alarmInfo{"51060050"} = "CryoOverMaxTemperature";
    $alarmInfo{"51060051"} = "TurboPumpFailed";
    $alarmInfo{"51060052"} = "TurboOverMaxTemperature";
    $alarmInfo{"51060053"} = "CannotRegenTurboPump!";
    $alarmInfo{"51060054"} = "TurboFailedToReachSpeed";
    $alarmInfo{"51060055"} = "TurboAtFaultOrNotAtSpeed";
    $alarmInfo{"51060056"} = "WaferLiftSlowToMoveUp";
    $alarmInfo{"51060057"} = "WaferLiftSlowToMoveDown";
    $alarmInfo{"51060058"} = "WaferLiftFailedToMove";
    $alarmInfo{"51060059"} = "PlatenControlTempT/CDisconnected";
    $alarmInfo{"5106005A"} = "PlatenSafetyTempT/CDisconnected";
    $alarmInfo{"5106005B"} = "PlatenControl-safetyTempDifference";
    $alarmInfo{"5106005C"} = "PlatenTempOutOfBand";
    $alarmInfo{"5106005D"} = "PlatenFailedToMoveUp";
    $alarmInfo{"5106005E"} = "PlatenFailedToMoveDown";
    $alarmInfo{"5106005F"} = "RecirculatorTempOutOfBand";
    $alarmInfo{"51060060"} = "RecirculatorTempT/CDisconnected";
    $alarmInfo{"51060061"} = "PlatenTempT/CDisconnected";
    $alarmInfo{"51060062"} = "CoilRFReflectedPowerFault";
    $alarmInfo{"51060063"} = "CoilRFReflectedPowerHold";
    $alarmInfo{"51060064"} = "CoilForwardPowerFault";
    $alarmInfo{"51060065"} = "PotMovementPositionFault";
    $alarmInfo{"51060066"} = "PlatenRFReflectedPowerAbort";
    $alarmInfo{"51060067"} = "PlatenRFReflectedPowerHold";
    $alarmInfo{"51060068"} = "DCBiasAboveMaxLimit";
    $alarmInfo{"51060069"} = "DCBiasBelowMinLimit";
    $alarmInfo{"5106006A"} = "DCBiasToleranceFault";
    $alarmInfo{"5106006B"} = "ForwardPowerToleranceFault";
    $alarmInfo{"5106006C"} = "LoadPowerToleranceFault";
    $alarmInfo{"5106006D"} = "Bake-outControlTempT/CDisconnected";
    $alarmInfo{"5106006E"} = "Bake-outSafetyTempT/CDisconnected";
    $alarmInfo{"5106006F"} = "Bake-outControl-safetyTempDifference";
    $alarmInfo{"51060070"} = "Bake-outSlowToReachTemperature";
    $alarmInfo{"51060071"} = "EscPump-outPressureLimitFault";
    $alarmInfo{"51060072"} = "EscPump-outPressureFaultInUnclamp";
    $alarmInfo{"51060073"} = "EscFlowFault";
    $alarmInfo{"51060074"} = "EscWaferValveOpenFault";
    $alarmInfo{"51060075"} = "EscPressureInBandTime-out";
    $alarmInfo{"51060076"} = "EscPressureToleranceFault";
    $alarmInfo{"51060077"} = "EscVoltageFault";
    $alarmInfo{"51060078"} = "TimeoutWaitingForBackfillPressure";
    $alarmInfo{"51060079"} = "Leak-upRateFailure";
    $alarmInfo{"5106007A"} = "CompressedAirFault";
    $alarmInfo{"5106007B"} = "LocalPCTemperatureFault";
    $alarmInfo{"5106007C"} = "ModuleFanFault";
    $alarmInfo{"5106007D"} = "VentServiceFailedToReachAtmosphere";
    $alarmInfo{"5106007E"} = "RGALeakCheckRequired";
    $alarmInfo{"5106007F"} = "WaitingForStage1Pressure -Slow";
    $alarmInfo{"51060080"} = "WaitingForStage2Pressure -Slow";
    $alarmInfo{"51060081"} = "NotWaitingForStage1Pressure ";
    $alarmInfo{"51060082"} = "FailedToReachStage1Pressure";
    $alarmInfo{"51060083"} = "FailedToReachStage2Pressure";
    $alarmInfo{"51060084"} = "CryoRegenServiceRoutineFailed";
    $alarmInfo{"51060085"} = "CTIControllerCommunicationsError";
    $alarmInfo{"51060086"} = "CTIPumpNotResponding";
    $alarmInfo{"51060087"} = "TurboPlusServiceRoutineFailed";
    $alarmInfo{"51060088"} = "HeaterMalfunctionHappened";
    $alarmInfo{"51600030"} = "RC2ADSWatchDogAlarmOccurredClr";
    $alarmInfo{"51600031"} = "RC2ADSWatchDogAlarmOccurredDet";
    $alarmInfo{"516000a0"} = "RC2AlarmOccurredClr";
    $alarmInfo{"516000a1"} = "RC2AlarmOccurredDet";
    $alarmInfo{"51600100"} = "RC2SeriousAlarmOccurredClr";
    $alarmInfo{"51600101"} = "RC2SeriousAlarmOccurredDet";
    $alarmInfo{"51600110"} = "RC2LightAlarmOccurredClr";
    $alarmInfo{"51600111"} = "RC2LightAlarmOccurredDet";
    $alarmInfo{"51600120"} = "RC2SafetyLatchAlarmOccurredClr";
    $alarmInfo{"51600121"} = "RC2SafetyLatchAlarmOccurredDet";
    $alarmInfo{"51600130"} = "RC2MaintenanceAlarmOccurredClr";
    $alarmInfo{"51600131"} = "RC2MaintenanceAlarmOccurredDet";
    $alarmInfo{"51600140"} = "RC2DIMaintenanceAlarmOccurredClr";
    $alarmInfo{"51600141"} = "RC2DIMaintenanceAlarmOccurredDet";
    $alarmInfo{"52060000"} = "52060000";
    $alarmInfo{"52060001"} = "CommunicationTimeout";
    $alarmInfo{"52060002"} = "StatusChangedToIDLE";
    $alarmInfo{"52060003"} = "CommandWasRejected";
    $alarmInfo{"52060004"} = "MotionStopped";
    $alarmInfo{"52060005"} = "MotionAborted";
    $alarmInfo{"52060006"} = "MotorStatusError";
    $alarmInfo{"52060007"} = "ACKTimeout";
    $alarmInfo{"52060008"} = "CompletionTimeout";
    $alarmInfo{"52060009"} = "ActualError";
    $alarmInfo{"5206000A"} = "SensorError";
    $alarmInfo{"5206000B"} = "SensorUnknown";
    $alarmInfo{"5206000C"} = "TransferInterlockErrorOccurred";
    $alarmInfo{"5206000D"} = "WaferInterlockErrorOccurred";
    $alarmInfo{"5206000E"} = "PressureInterlockErrorOccurred";
    $alarmInfo{"52060010"} = "MotorUnitErrorOccurred";
    $alarmInfo{"52060011"} = "InitializationUncompleted";
    $alarmInfo{"52060012"} = "BERobotInterlockErrorOccurred";
    $alarmInfo{"52060013"} = "HardwareUpperLimitSensorTripped";
    $alarmInfo{"52060014"} = "HardwareLowerLimitSensorTripped";
    $alarmInfo{"52060015"} = "RotationAxisHardwareInterlockOccurred";
    $alarmInfo{"52060016"} = "RotationAxisSoftwareInterlockOccurred";
    $alarmInfo{"52060017"} = "VerticalAxisSoftwareInterlockOccurred";
    $alarmInfo{"52060018"} = "HardwareLimitSwitchIsNotProperlySetup";
    $alarmInfo{"52060019"} = "ExceedTheSoftwareLimitsOfUpperPulse";
    $alarmInfo{"5206001A"} = "ExceedTheSoftwareLimitsOfLowerPulse";
    $alarmInfo{"5206001B"} = "GateValveIsOpen";
    $alarmInfo{"5206001C"} = "MotionStopOccurred";
    $alarmInfo{"5206001D"} = "ChamberLidIsOpen";
    $alarmInfo{"5206001E"} = "BERBArmIsExtendedPosition";
    $alarmInfo{"5206001F"} = "LiftCabinetIsOpen";
    $alarmInfo{"52060020"} = "ErrorReadingRotationHomeSensorState";
    $alarmInfo{"52060021"} = "RotationHome";
    $alarmInfo{"53060000"} = "53060000-EPI";
    $alarmInfo{"5B060001"} = "5B060001-EPI";
    $alarmInfo{"5B060002"} = "5B060002-EPI";
    $alarmInfo{"5B060003"} = "5B060003-EPI";
    $alarmInfo{"5B060004"} = "5B060004-EPI";
    $alarmInfo{"5B060005"} = "5B060005-EPI";
    $alarmInfo{"5B060006"} = "5B060006-EPI";
    $alarmInfo{"5B060007"} = "5B060007-EPI";
    $alarmInfo{"5B060008"} = "5B060008-EPI";
    $alarmInfo{"5B060009"} = "5B060009-EPI";
    $alarmInfo{"5B06000A"} = "5B06000A-EPI";
    $alarmInfo{"60060000"} = "60060000";
    $alarmInfo{"60060001"} = "PM3ALLWatchDriverFroze";
    $alarmInfo{"60060002"} = "PM3ALLPMDeviceNetDriverFroze";
    $alarmInfo{"60060003"} = "PM3ALLADSDriverFroze";
    $alarmInfo{"60060004"} = "PM3ALLTemparatureDriverFroze";
    $alarmInfo{"60060005"} = "PM3ALLPMDeviceNetDIODriverFroze";
    $alarmInfo{"60060006"} = "PM3ALLPMSEQDriverFroze";
    $alarmInfo{"60060007"} = "PM3ALLPMDeviceNetAIODriverFroze";
    $alarmInfo{"60060008"} = "PM3ALLPMRecipeExecutorFroze";
    $alarmInfo{"60060009"} = "PM3ALLSusceptorControlDriverFroze";
    $alarmInfo{"6006000A"} = "PM3ALLPressurePIDControlDriverFroze";
    $alarmInfo{"6006000B"} = "PM3ALLPulsingEngineFroze";
    $alarmInfo{"6006000C"} = "SYN6006000C";
    $alarmInfo{"6006000D"} = "SYN6006000D";
    $alarmInfo{"6006000E"} = "PM3ALLStepTimeError";
    $alarmInfo{"60060010"} = "PM3ALLHSEControlDriverFroze";
    $alarmInfo{"6006001E"} = "6006001E";
    $alarmInfo{"60060020"} = "PM3ALLFASTLOOP:Error";
    $alarmInfo{"60060021"} = "PM3ALLFASTLOOP:CIF:DualPortMemoryIsNull";
    $alarmInfo{"60060022"} = "PM3ALLFASTLOOP:DeviceNet:WatchDogError";
    $alarmInfo{"60060023"} = "PM3ALLFASTLOOP:DeviceNet:CommunicationStateOff-line";
    $alarmInfo{"60060024"} = "PM3ALLFASTLOOP:DeviceNet:CommunicationStateStop";
    $alarmInfo{"60060025"} = "PM3ALLFASTLOOP:DeviceNet:CommunicationStateClear";
    $alarmInfo{"60060026"} = "PM3ALLFASTLOOP:DeviceNet:FatalError";
    $alarmInfo{"60060027"} = "PM3ALLFASTLOOP:DeviceNet:BUSError";
    $alarmInfo{"60060028"} = "PM3ALLFASTLOOP:DeviceNet:BUSOff";
    $alarmInfo{"60060029"} = "PM3ALLFASTLOOP:DeviceNet:NoExchange";
    $alarmInfo{"6006002A"} = "PM3ALLFASTLOOP:DeviceNet:AutoClearError";
    $alarmInfo{"6006002B"} = "PM3ALLFASTLOOP:DeviceNet:DuplicateMAC-ID";
    $alarmInfo{"6006002C"} = "PM3ALLFASTLOOP:DeviceNet:HostNotReady";
    $alarmInfo{"6006002D"} = "PM3ALLFASTLOOP:Unknown";
    $alarmInfo{"6006002E"} = "PM3ALLFASTLOOP:Unknown";
    $alarmInfo{"6006002F"} = "PM3ALLFASTLOOP:Unknown";
    $alarmInfo{"60060030"} = "PM3ALLFASTLOOP:MAC-ID1:DeviceGuardingFailed,AfterDeviceWasOperational";
    $alarmInfo{"60060031"} = "PM3ALLFASTLOOP:MAC-ID1:DeviceAccessTimeout";
    $alarmInfo{"60060032"} = "PM3ALLFASTLOOP:MAC-ID1:DeviceRejectsAccessWithUnknownErrorCode";
    $alarmInfo{"60060033"} = "PM3ALLFASTLOOP:MAC-ID1:DeviceResponseInAllocationPhaseWithConnectionError";
    $alarmInfo{"60060034"} = "PM3ALLFASTLOOP:MAC-ID1:ProducedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"60060035"} = "PM3ALLFASTLOOP:MAC-ID1:ConsumedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"60060036"} = "PM3ALLFASTLOOP:MAC-ID1:DeviceServiceResponseTelegramUnknownAndNotHandled";
    $alarmInfo{"60060037"} = "PM3ALLFASTLOOP:MAC-ID1:ConnectionAlreadyInRequest";
    $alarmInfo{"60060038"} = "PM3ALLFASTLOOP:MAC-ID1:NumberOfCAN-messageDataBytesInReadProducedOrConsumedConnectionSizeResponseUnequal4";
    $alarmInfo{"60060039"} = "PM3ALLFASTLOOP:MAC-ID1:PredefinedMaster-slaveConnectionAlreadyExists";
    $alarmInfo{"6006003A"} = "PM3ALLFASTLOOP:MAC-ID1:LengthInPollingDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"6006003B"} = "PM3ALLFASTLOOP:MAC-ID1:SequenceErrorInDevicePollingResponse";
    $alarmInfo{"6006003C"} = "PM3ALLFASTLOOP:MAC-ID1:FragmentErrorInDevicePollingResponse";
    $alarmInfo{"6006003D"} = "PM3ALLFASTLOOP:MAC-ID1:SequenceError2InDevicePollingResponse";
    $alarmInfo{"6006003E"} = "PM3ALLFASTLOOP:MAC-ID1:LengthInBitStrobeDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"6006003F"} = "PM3ALLFASTLOOP:MAC-ID1:SequenceErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"60060040"} = "PM3ALLFASTLOOP:MAC-ID1:FragmentErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"60060041"} = "PM3ALLFASTLOOP:MAC-ID1:SequenceError2InDeviceCOSOrCyclicResponse";
    $alarmInfo{"60060042"} = "PM3ALLFASTLOOP:MAC-ID1:LengthInCOSOrCyclicDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"60060043"} = "PM3ALLFASTLOOP:MAC-ID1:UCMMGroupNotSupported";
    $alarmInfo{"60060044"} = "PM3ALLFASTLOOP:MAC-ID1:UnknownHandshakeModeConfigured";
    $alarmInfo{"60060045"} = "PM3ALLFASTLOOP:MAC-ID1:ConfiguredBaudrateNotSupported";
    $alarmInfo{"60060046"} = "PM3ALLFASTLOOP:MAC-ID1:DeviceMAC-IDOutOfRange";
    $alarmInfo{"60060047"} = "PM3ALLFASTLOOP:MAC-ID1:DuplicateMAC-IDDetected";
    $alarmInfo{"60060048"} = "PM3ALLFASTLOOP:MAC-ID1:DatabaseInTheDeviceHasNoEntriesIncluded";
    $alarmInfo{"60060049"} = "PM3ALLFASTLOOP:MAC-ID1:DoubleMAC-IDConfiguredInternally";
    $alarmInfo{"6006004A"} = "PM3ALLFASTLOOP:MAC-ID1:SizeOfOneDeviceDataSetInvalid";
    $alarmInfo{"6006004B"} = "PM3ALLFASTLOOP:MAC-ID1:OffsetTableForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"6006004C"} = "PM3ALLFASTLOOP:MAC-ID1:ConfigurationTableLengthForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"6006004D"} = "PM3ALLFASTLOOP:MAC-ID1:OffsetTableDoNotCorrespondToI/OConfigurationTable";
    $alarmInfo{"6006004E"} = "PM3ALLFASTLOOP:MAC-ID1:SizeIndicatorOfParameterDataTableCorrupt";
    $alarmInfo{"6006004F"} = "PM3ALLFASTLOOP:MAC-ID1:NumberOfInputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"60060050"} = "PM3ALLFASTLOOP:MAC-ID1:NumberOfOutputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"60060051"} = "PM3ALLFASTLOOP:MAC-ID1:UnknownDataTypeInI/OConfiguration";
    $alarmInfo{"60060052"} = "PM3ALLFASTLOOP:MAC-ID1:DataTypeDoesNotCorrespondToItsConfiguredLength";
    $alarmInfo{"60060053"} = "PM3ALLFASTLOOP:MAC-ID1:ConfiguredOutputOffsetAddressOutOfRange";
    $alarmInfo{"60060054"} = "PM3ALLFASTLOOP:MAC-ID1:ConfiguredInputOffsetAddressOutOfRange";
    $alarmInfo{"60060055"} = "PM3ALLFASTLOOP:MAC-ID1:OnePredefinedConnectionTypeIsUnknown";
    $alarmInfo{"60060056"} = "PM3ALLFASTLOOP:MAC-ID1:MultipleConnectionsDefinedInParallel";
    $alarmInfo{"60060057"} = "PM3ALLFASTLOOP:MAC-ID1:ConfiguredEXP_PCKT_RATELessThenPROD_INHIBIT_TIME";
    $alarmInfo{"60060058"} = "PM3ALLFASTLOOP:MAC-ID1:NoDatabaseFoundOnTheSystem";
    $alarmInfo{"60060059"} = "PM3ALLFASTLOOP:MAC-ID1:DatabaseReadingFailure";
    $alarmInfo{"6006005A"} = "PM3ALLFASTLOOP:MAC-ID1:UserWatchdogFailed";
    $alarmInfo{"6006005B"} = "PM3ALLFASTLOOP:MAC-ID1:NoDataAcknowledgeFromUser";
    $alarmInfo{"6006005C"} = "PM3ALLFASTLOOP:MAC-ID1:Unknown";
    $alarmInfo{"6006005D"} = "PM3ALLFASTLOOP:MAC-ID1:Unknown";
    $alarmInfo{"6006005E"} = "PM3ALLFASTLOOP:MAC-ID1:Unknown";
    $alarmInfo{"6006005F"} = "PM3ALLFASTLOOP:MAC-ID1:Unknown";
    $alarmInfo{"60060060"} = "PM3ALLFASTLOOP:MAC-ID2:DeviceGuardingFailed,AfterDeviceWasOperational";
    $alarmInfo{"60060061"} = "PM3ALLFASTLOOP:MAC-ID2:DeviceAccessTimeout";
    $alarmInfo{"60060062"} = "PM3ALLFASTLOOP:MAC-ID2:DeviceRejectsAccessWithUnknownErrorCode";
    $alarmInfo{"60060063"} = "PM3ALLFASTLOOP:MAC-ID2:DeviceResponseInAllocationPhaseWithConnectionError";
    $alarmInfo{"60060064"} = "PM3ALLFASTLOOP:MAC-ID2:ProducedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"60060065"} = "PM3ALLFASTLOOP:MAC-ID2:ConsumedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"60060066"} = "PM3ALLFASTLOOP:MAC-ID2:DeviceServiceResponseTelegramUnknownAndNotHandled";
    $alarmInfo{"60060067"} = "PM3ALLFASTLOOP:MAC-ID2:ConnectionAlreadyInRequest";
    $alarmInfo{"60060068"} = "PM3ALLFASTLOOP:MAC-ID2:NumberOfCAN-messageDataBytesInReadProducedOrConsumedConnectionSizeResponseUnequal4";
    $alarmInfo{"60060069"} = "PM3ALLFASTLOOP:MAC-ID2:PredefinedMaster-slaveConnectionAlreadyExists";
    $alarmInfo{"6006006A"} = "PM3ALLFASTLOOP:MAC-ID2:LengthInPollingDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"6006006B"} = "PM3ALLFASTLOOP:MAC-ID2:SequenceErrorInDevicePollingResponse";
    $alarmInfo{"6006006C"} = "PM3ALLFASTLOOP:MAC-ID2:FragmentErrorInDevicePollingResponse";
    $alarmInfo{"6006006D"} = "PM3ALLFASTLOOP:MAC-ID2:SequenceError2InDevicePollingResponse";
    $alarmInfo{"6006006E"} = "PM3ALLFASTLOOP:MAC-ID2:LengthInBitStrobeDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"6006006F"} = "PM3ALLFASTLOOP:MAC-ID2:SequenceErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"60060070"} = "PM3ALLFASTLOOP:MAC-ID2:FragmentErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"60060071"} = "PM3ALLFASTLOOP:MAC-ID2:SequenceError2InDeviceCOSOrCyclicResponse";
    $alarmInfo{"60060072"} = "PM3ALLFASTLOOP:MAC-ID2:LengthInCOSOrCyclicDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"60060073"} = "PM3ALLFASTLOOP:MAC-ID2:UCMMGroupNotSupported";
    $alarmInfo{"60060074"} = "PM3ALLFASTLOOP:MAC-ID2:UnknownHandshakeModeConfigured";
    $alarmInfo{"60060075"} = "PM3ALLFASTLOOP:MAC-ID2:ConfiguredBaudrateNotSupported";
    $alarmInfo{"60060076"} = "PM3ALLFASTLOOP:MAC-ID2:DeviceMAC-IDOutOfRange";
    $alarmInfo{"60060077"} = "PM3ALLFASTLOOP:MAC-ID2:DuplicateMAC-IDDetected";
    $alarmInfo{"60060078"} = "PM3ALLFASTLOOP:MAC-ID2:DatabaseInTheDeviceHasNoEntriesIncluded";
    $alarmInfo{"60060079"} = "PM3ALLFASTLOOP:MAC-ID2:DoubleMAC-IDConfiguredInternally";
    $alarmInfo{"6006007A"} = "PM3ALLFASTLOOP:MAC-ID2:SizeOfOneDeviceDataSetInvalid";
    $alarmInfo{"6006007B"} = "PM3ALLFASTLOOP:MAC-ID2:OffsetTableForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"6006007C"} = "PM3ALLFASTLOOP:MAC-ID2:ConfigurationTableLengthForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"6006007D"} = "PM3ALLFASTLOOP:MAC-ID2:OffsetTableDoNotCorrespondToI/OConfigurationTable";
    $alarmInfo{"6006007E"} = "PM3ALLFASTLOOP:MAC-ID2:SizeIndicatorOfParameterDataTableCorrupt";
    $alarmInfo{"6006007F"} = "PM3ALLFASTLOOP:MAC-ID2:NumberOfInputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"60060080"} = "PM3ALLFASTLOOP:MAC-ID2:NumberOfOutputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"60060081"} = "PM3ALLFASTLOOP:MAC-ID2:UnknownDataTypeInI/OConfiguration";
    $alarmInfo{"60060082"} = "PM3ALLFASTLOOP:MAC-ID2:DataTypeDoesNotCorrespondToItsConfiguredLength";
    $alarmInfo{"60060083"} = "PM3ALLFASTLOOP:MAC-ID2:ConfiguredOutputOffsetAddressOutOfRange";
    $alarmInfo{"60060084"} = "PM3ALLFASTLOOP:MAC-ID2:ConfiguredInputOffsetAddressOutOfRange";
    $alarmInfo{"60060085"} = "PM3ALLFASTLOOP:MAC-ID2:OnePredefinedConnectionTypeIsUnknown";
    $alarmInfo{"60060086"} = "PM3ALLFASTLOOP:MAC-ID2:MultipleConnectionsDefinedInParallel";
    $alarmInfo{"60060087"} = "PM3ALLFASTLOOP:MAC-ID2:ConfiguredEXP_PCKT_RATELessThenPROD_INHIBIT_TIME";
    $alarmInfo{"60060088"} = "PM3ALLFASTLOOP:MAC-ID2:NoDatabaseFoundOnTheSystem";
    $alarmInfo{"60060089"} = "PM3ALLFASTLOOP:MAC-ID2:DatabaseReadingFailure";
    $alarmInfo{"6006008A"} = "PM3ALLFASTLOOP:MAC-ID2:UserWatchdogFailed";
    $alarmInfo{"6006008B"} = "PM3ALLFASTLOOP:MAC-ID2:NoDataAcknowledgeFromUser";
    $alarmInfo{"6006008C"} = "PM3ALLFASTLOOP:MAC-ID2:Unknown";
    $alarmInfo{"6006008D"} = "PM3ALLFASTLOOP:MAC-ID2:Unknown";
    $alarmInfo{"6006008E"} = "PM3ALLFASTLOOP:MAC-ID2:Unknown";
    $alarmInfo{"6006008F"} = "PM3ALLFASTLOOP:MAC-ID2:Unknown";
    $alarmInfo{"60060090"} = "PM3ALLFASTLOOP:MAC-ID3:DeviceGuardingFailed,AfterDeviceWasOperational";
    $alarmInfo{"60060091"} = "PM3ALLFASTLOOP:MAC-ID3:DeviceAccessTimeout";
    $alarmInfo{"60060092"} = "PM3ALLFASTLOOP:MAC-ID3:DeviceRejectsAccessWithUnknownErrorCode";
    $alarmInfo{"60060093"} = "PM3ALLFASTLOOP:MAC-ID3:DeviceResponseInAllocationPhaseWithConnectionError";
    $alarmInfo{"60060094"} = "PM3ALLFASTLOOP:MAC-ID3:ProducedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"60060095"} = "PM3ALLFASTLOOP:MAC-ID3:ConsumedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"60060096"} = "PM3ALLFASTLOOP:MAC-ID3:DeviceServiceResponseTelegramUnknownAndNotHandled";
    $alarmInfo{"60060097"} = "PM3ALLFASTLOOP:MAC-ID3:ConnectionAlreadyInRequest";
    $alarmInfo{"60060098"} = "PM3ALLFASTLOOP:MAC-ID3:NumberOfCAN-messageDataBytesInReadProducedOrConsumedConnectionSizeResponseUnequal4";
    $alarmInfo{"60060099"} = "PM3ALLFASTLOOP:MAC-ID3:PredefinedMaster-slaveConnectionAlreadyExists";
    $alarmInfo{"6006009A"} = "PM3ALLFASTLOOP:MAC-ID3:LengthInPollingDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"6006009B"} = "PM3ALLFASTLOOP:MAC-ID3:SequenceErrorInDevicePollingResponse";
    $alarmInfo{"6006009C"} = "PM3ALLFASTLOOP:MAC-ID3:FragmentErrorInDevicePollingResponse";
    $alarmInfo{"6006009D"} = "PM3ALLFASTLOOP:MAC-ID3:SequenceError2InDevicePollingResponse";
    $alarmInfo{"6006009E"} = "PM3ALLFASTLOOP:MAC-ID3:LengthInBitStrobeDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"6006009F"} = "PM3ALLFASTLOOP:MAC-ID3:SequenceErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"600600A0"} = "PM3ALLFASTLOOP:MAC-ID3:FragmentErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"600600A1"} = "PM3ALLFASTLOOP:MAC-ID3:SequenceError2InDeviceCOSOrCyclicResponse";
    $alarmInfo{"600600A2"} = "PM3ALLFASTLOOP:MAC-ID3:LengthInCOSOrCyclicDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"600600A3"} = "PM3ALLFASTLOOP:MAC-ID3:UCMMGroupNotSupported";
    $alarmInfo{"600600A4"} = "PM3ALLFASTLOOP:MAC-ID3:UnknownHandshakeModeConfigured";
    $alarmInfo{"600600A5"} = "PM3ALLFASTLOOP:MAC-ID3:ConfiguredBaudrateNotSupported";
    $alarmInfo{"600600A6"} = "PM3ALLFASTLOOP:MAC-ID3:DeviceMAC-IDOutOfRange";
    $alarmInfo{"600600A7"} = "PM3ALLFASTLOOP:MAC-ID3:DuplicateMAC-IDDetected";
    $alarmInfo{"600600A8"} = "PM3ALLFASTLOOP:MAC-ID3:DatabaseInTheDeviceHasNoEntriesIncluded";
    $alarmInfo{"600600A9"} = "PM3ALLFASTLOOP:MAC-ID3:DoubleMAC-IDConfiguredInternally";
    $alarmInfo{"600600AA"} = "PM3ALLFASTLOOP:MAC-ID3:SizeOfOneDeviceDataSetInvalid";
    $alarmInfo{"600600AB"} = "PM3ALLFASTLOOP:MAC-ID3:OffsetTableForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"600600AC"} = "PM3ALLFASTLOOP:MAC-ID3:ConfigurationTableLengthForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"600600AD"} = "PM3ALLFASTLOOP:MAC-ID3:OffsetTableDoNotCorrespondToI/OConfigurationTable";
    $alarmInfo{"600600AE"} = "PM3ALLFASTLOOP:MAC-ID3:SizeIndicatorOfParameterDataTableCorrupt";
    $alarmInfo{"600600AF"} = "PM3ALLFASTLOOP:MAC-ID3:NumberOfInputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"600600B0"} = "PM3ALLFASTLOOP:MAC-ID3:NumberOfOutputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"600600B1"} = "PM3ALLFASTLOOP:MAC-ID3:UnknownDataTypeInI/OConfiguration";
    $alarmInfo{"600600B2"} = "PM3ALLFASTLOOP:MAC-ID3:DataTypeDoesNotCorrespondToItsConfiguredLength";
    $alarmInfo{"600600B3"} = "PM3ALLFASTLOOP:MAC-ID3:ConfiguredOutputOffsetAddressOutOfRange";
    $alarmInfo{"600600B4"} = "PM3ALLFASTLOOP:MAC-ID3:ConfiguredInputOffsetAddressOutOfRange";
    $alarmInfo{"600600B5"} = "PM3ALLFASTLOOP:MAC-ID3:OnePredefinedConnectionTypeIsUnknown";
    $alarmInfo{"600600B6"} = "PM3ALLFASTLOOP:MAC-ID3:MultipleConnectionsDefinedInParallel";
    $alarmInfo{"600600B7"} = "PM3ALLFASTLOOP:MAC-ID3:ConfiguredEXP_PCKT_RATELessThenPROD_INHIBIT_TIME";
    $alarmInfo{"600600B8"} = "PM3ALLFASTLOOP:MAC-ID3:NoDatabaseFoundOnTheSystem";
    $alarmInfo{"600600B9"} = "PM3ALLFASTLOOP:MAC-ID3:DatabaseReadingFailure";
    $alarmInfo{"600600BA"} = "PM3ALLFASTLOOP:MAC-ID3:UserWatchdogFailed";
    $alarmInfo{"600600BB"} = "PM3ALLFASTLOOP:MAC-ID3:NoDataAcknowledgeFromUser";
    $alarmInfo{"600600BC"} = "PM3ALLFASTLOOP:MAC-ID3:Unknown";
    $alarmInfo{"600600BD"} = "PM3ALLFASTLOOP:MAC-ID3:Unknown";
    $alarmInfo{"600600BE"} = "PM3ALLFASTLOOP:MAC-ID3:Unknown";
    $alarmInfo{"600600BF"} = "PM3ALLFASTLOOP:MAC-ID3:Unknown";
    $alarmInfo{"600600C0"} = "PM3ALLFASTLOOP:MAC-ID4:DeviceGuardingFailed,AfterDeviceWasOperational";
    $alarmInfo{"600600C1"} = "PM3ALLFASTLOOP:MAC-ID4:DeviceAccessTimeout";
    $alarmInfo{"600600C2"} = "PM3ALLFASTLOOP:MAC-ID4:DeviceRejectsAccessWithUnknownErrorCode";
    $alarmInfo{"600600C3"} = "PM3ALLFASTLOOP:MAC-ID4:DeviceResponseInAllocationPhaseWithConnectionError";
    $alarmInfo{"600600C4"} = "PM3ALLFASTLOOP:MAC-ID4:ProducedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"600600C5"} = "PM3ALLFASTLOOP:MAC-ID4:ConsumedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"600600C6"} = "PM3ALLFASTLOOP:MAC-ID4:DeviceServiceResponseTelegramUnknownAndNotHandled";
    $alarmInfo{"600600C7"} = "PM3ALLFASTLOOP:MAC-ID4:ConnectionAlreadyInRequest";
    $alarmInfo{"600600C8"} = "PM3ALLFASTLOOP:MAC-ID4:NumberOfCAN-messageDataBytesInReadProducedOrConsumedConnectionSizeResponseUnequal4";
    $alarmInfo{"600600C9"} = "PM3ALLFASTLOOP:MAC-ID4:PredefinedMaster-slaveConnectionAlreadyExists";
    $alarmInfo{"600600CA"} = "PM3ALLFASTLOOP:MAC-ID4:LengthInPollingDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"600600CB"} = "PM3ALLFASTLOOP:MAC-ID4:SequenceErrorInDevicePollingResponse";
    $alarmInfo{"600600CC"} = "PM3ALLFASTLOOP:MAC-ID4:FragmentErrorInDevicePollingResponse";
    $alarmInfo{"600600CD"} = "PM3ALLFASTLOOP:MAC-ID4:SequenceError2InDevicePollingResponse";
    $alarmInfo{"600600CE"} = "PM3ALLFASTLOOP:MAC-ID4:LengthInBitStrobeDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"600600CF"} = "PM3ALLFASTLOOP:MAC-ID4:SequenceErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"600600D0"} = "PM3ALLFASTLOOP:MAC-ID4:FragmentErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"600600D1"} = "PM3ALLFASTLOOP:MAC-ID4:SequenceError2InDeviceCOSOrCyclicResponse";
    $alarmInfo{"600600D2"} = "PM3ALLFASTLOOP:MAC-ID4:LengthInCOSOrCyclicDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"600600D3"} = "PM3ALLFASTLOOP:MAC-ID4:UCMMGroupNotSupported";
    $alarmInfo{"600600D4"} = "PM3ALLFASTLOOP:MAC-ID4:UnknownHandshakeModeConfigured";
    $alarmInfo{"600600D5"} = "PM3ALLFASTLOOP:MAC-ID4:ConfiguredBaudrateNotSupported";
    $alarmInfo{"600600D6"} = "PM3ALLFASTLOOP:MAC-ID4:DeviceMAC-IDOutOfRange";
    $alarmInfo{"600600D7"} = "PM3ALLFASTLOOP:MAC-ID4:DuplicateMAC-IDDetected";
    $alarmInfo{"600600D8"} = "PM3ALLFASTLOOP:MAC-ID4:DatabaseInTheDeviceHasNoEntriesIncluded";
    $alarmInfo{"600600D9"} = "PM3ALLFASTLOOP:MAC-ID4:DoubleMAC-IDConfiguredInternally";
    $alarmInfo{"600600DA"} = "PM3ALLFASTLOOP:MAC-ID4:SizeOfOneDeviceDataSetInvalid";
    $alarmInfo{"600600DB"} = "PM3ALLFASTLOOP:MAC-ID4:OffsetTableForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"600600DC"} = "PM3ALLFASTLOOP:MAC-ID4:ConfigurationTableLengthForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"600600DD"} = "PM3ALLFASTLOOP:MAC-ID4:OffsetTableDoNotCorrespondToI/OConfigurationTable";
    $alarmInfo{"600600DE"} = "PM3ALLFASTLOOP:MAC-ID4:SizeIndicatorOfParameterDataTableCorrupt";
    $alarmInfo{"600600DF"} = "PM3ALLFASTLOOP:MAC-ID4:NumberOfInputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"600600E0"} = "PM3ALLFASTLOOP:MAC-ID4:NumberOfOutputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"600600E1"} = "PM3ALLFASTLOOP:MAC-ID4:UnknownDataTypeInI/OConfiguration";
    $alarmInfo{"600600E2"} = "PM3ALLFASTLOOP:MAC-ID4:DataTypeDoesNotCorrespondToItsConfiguredLength";
    $alarmInfo{"600600E3"} = "PM3ALLFASTLOOP:MAC-ID4:ConfiguredOutputOffsetAddressOutOfRange";
    $alarmInfo{"600600E4"} = "PM3ALLFASTLOOP:MAC-ID4:ConfiguredInputOffsetAddressOutOfRange";
    $alarmInfo{"600600E5"} = "PM3ALLFASTLOOP:MAC-ID4:OnePredefinedConnectionTypeIsUnknown";
    $alarmInfo{"600600E6"} = "PM3ALLFASTLOOP:MAC-ID4:MultipleConnectionsDefinedInParallel";
    $alarmInfo{"600600E7"} = "PM3ALLFASTLOOP:MAC-ID4:ConfiguredEXP_PCKT_RATELessThenPROD_INHIBIT_TIME";
    $alarmInfo{"600600E8"} = "PM3ALLFASTLOOP:MAC-ID4:NoDatabaseFoundOnTheSystem";
    $alarmInfo{"600600E9"} = "PM3ALLFASTLOOP:MAC-ID4:DatabaseReadingFailure";
    $alarmInfo{"600600EA"} = "PM3ALLFASTLOOP:MAC-ID4:UserWatchdogFailed";
    $alarmInfo{"600600EB"} = "PM3ALLFASTLOOP:MAC-ID4:NoDataAcknowledgeFromUser";
    $alarmInfo{"600600EC"} = "PM3ALLFASTLOOP:MAC-ID4:Unknown";
    $alarmInfo{"600600ED"} = "PM3ALLFASTLOOP:MAC-ID4:Unknown";
    $alarmInfo{"600600EE"} = "PM3ALLFASTLOOP:MAC-ID4:Unknown";
    $alarmInfo{"600600EF"} = "PM3ALLFASTLOOP:MAC-ID4:Unknown";
    $alarmInfo{"600600F0"} = "PM3ALLFASTLOOP:MAC-ID5:DeviceGuardingFailed,AfterDeviceWasOperational";
    $alarmInfo{"600600F1"} = "PM3ALLFASTLOOP:MAC-ID5:DeviceAccessTimeout";
    $alarmInfo{"600600F2"} = "PM3ALLFASTLOOP:MAC-ID5:DeviceRejectsAccessWithUnknownErrorCode";
    $alarmInfo{"600600F3"} = "PM3ALLFASTLOOP:MAC-ID5:DeviceResponseInAllocationPhaseWithConnectionError";
    $alarmInfo{"600600F4"} = "PM3ALLFASTLOOP:MAC-ID5:ProducedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"600600F5"} = "PM3ALLFASTLOOP:MAC-ID5:ConsumedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"600600F6"} = "PM3ALLFASTLOOP:MAC-ID5:DeviceServiceResponseTelegramUnknownAndNotHandled";
    $alarmInfo{"600600F7"} = "PM3ALLFASTLOOP:MAC-ID5:ConnectionAlreadyInRequest";
    $alarmInfo{"600600F8"} = "PM3ALLFASTLOOP:MAC-ID5:NumberOfCAN-messageDataBytesInReadProducedOrConsumedConnectionSizeResponseUnequal4";
    $alarmInfo{"600600F9"} = "PM3ALLFASTLOOP:MAC-ID5:PredefinedMaster-slaveConnectionAlreadyExists";
    $alarmInfo{"600600FA"} = "PM3ALLFASTLOOP:MAC-ID5:LengthInPollingDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"600600FB"} = "PM3ALLFASTLOOP:MAC-ID5:SequenceErrorInDevicePollingResponse";
    $alarmInfo{"600600FC"} = "PM3ALLFASTLOOP:MAC-ID5:FragmentErrorInDevicePollingResponse";
    $alarmInfo{"600600FD"} = "PM3ALLFASTLOOP:MAC-ID5:SequenceError2InDevicePollingResponse";
    $alarmInfo{"600600FE"} = "PM3ALLFASTLOOP:MAC-ID5:LengthInBitStrobeDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"600600FF"} = "PM3ALLFASTLOOP:MAC-ID5:SequenceErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"60060100"} = "PM3ALLFASTLOOP:MAC-ID5:FragmentErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"60060101"} = "PM3ALLFASTLOOP:MAC-ID5:SequenceError2InDeviceCOSOrCyclicResponse";
    $alarmInfo{"60060102"} = "PM3ALLFASTLOOP:MAC-ID5:LengthInCOSOrCyclicDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"60060103"} = "PM3ALLFASTLOOP:MAC-ID5:UCMMGroupNotSupported";
    $alarmInfo{"60060104"} = "PM3ALLFASTLOOP:MAC-ID5:UnknownHandshakeModeConfigured";
    $alarmInfo{"60060105"} = "PM3ALLFASTLOOP:MAC-ID5:ConfiguredBaudrateNotSupported";
    $alarmInfo{"60060106"} = "PM3ALLFASTLOOP:MAC-ID5:DeviceMAC-IDOutOfRange";
    $alarmInfo{"60060107"} = "PM3ALLFASTLOOP:MAC-ID5:DuplicateMAC-IDDetected";
    $alarmInfo{"60060108"} = "PM3ALLFASTLOOP:MAC-ID5:DatabaseInTheDeviceHasNoEntriesIncluded";
    $alarmInfo{"60060109"} = "PM3ALLFASTLOOP:MAC-ID5:DoubleMAC-IDConfiguredInternally";
    $alarmInfo{"6006010A"} = "PM3ALLFASTLOOP:MAC-ID5:SizeOfOneDeviceDataSetInvalid";
    $alarmInfo{"6006010B"} = "PM3ALLFASTLOOP:MAC-ID5:OffsetTableForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"6006010C"} = "PM3ALLFASTLOOP:MAC-ID5:ConfigurationTableLengthForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"6006010D"} = "PM3ALLFASTLOOP:MAC-ID5:OffsetTableDoNotCorrespondToI/OConfigurationTable";
    $alarmInfo{"6006010E"} = "PM3ALLFASTLOOP:MAC-ID5:SizeIndicatorOfParameterDataTableCorrupt";
    $alarmInfo{"6006010F"} = "PM3ALLFASTLOOP:MAC-ID5:NumberOfInputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"60060110"} = "PM3ALLFASTLOOP:MAC-ID5:NumberOfOutputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"60060111"} = "PM3ALLFASTLOOP:MAC-ID5:UnknownDataTypeInI/OConfiguration";
    $alarmInfo{"60060112"} = "PM3ALLFASTLOOP:MAC-ID5:DataTypeDoesNotCorrespondToItsConfiguredLength";
    $alarmInfo{"60060113"} = "PM3ALLFASTLOOP:MAC-ID5:ConfiguredOutputOffsetAddressOutOfRange";
    $alarmInfo{"60060114"} = "PM3ALLFASTLOOP:MAC-ID5:ConfiguredInputOffsetAddressOutOfRange";
    $alarmInfo{"60060115"} = "PM3ALLFASTLOOP:MAC-ID5:OnePredefinedConnectionTypeIsUnknown";
    $alarmInfo{"60060116"} = "PM3ALLFASTLOOP:MAC-ID5:MultipleConnectionsDefinedInParallel";
    $alarmInfo{"60060117"} = "PM3ALLFASTLOOP:MAC-ID5:ConfiguredEXP_PCKT_RATELessThenPROD_INHIBIT_TIME";
    $alarmInfo{"60060118"} = "PM3ALLFASTLOOP:MAC-ID5:NoDatabaseFoundOnTheSystem";
    $alarmInfo{"60060119"} = "PM3ALLFASTLOOP:MAC-ID5:DatabaseReadingFailure";
    $alarmInfo{"6006011A"} = "PM3ALLFASTLOOP:MAC-ID5:UserWatchdogFailed";
    $alarmInfo{"6006011B"} = "PM3ALLFASTLOOP:MAC-ID5:NoDataAcknowledgeFromUser";
    $alarmInfo{"6006011C"} = "PM3ALLFASTLOOP:MAC-ID5:Unknown";
    $alarmInfo{"6006011D"} = "PM3ALLFASTLOOP:MAC-ID5:Unknown";
    $alarmInfo{"6006011E"} = "PM3ALLFASTLOOP:MAC-ID5:Unknown";
    $alarmInfo{"6006011F"} = "PM3ALLFASTLOOP:MAC-ID5:Unknown";
    $alarmInfo{"60060120"} = "PM3ALLFASTLOOP:MAC-ID6:DeviceGuardingFailed,AfterDeviceWasOperational";
    $alarmInfo{"60060121"} = "PM3ALLFASTLOOP:MAC-ID6:DeviceAccessTimeout";
    $alarmInfo{"60060122"} = "PM3ALLFASTLOOP:MAC-ID6:DeviceRejectsAccessWithUnknownErrorCode";
    $alarmInfo{"60060123"} = "PM3ALLFASTLOOP:MAC-ID6:DeviceResponseInAllocationPhaseWithConnectionError";
    $alarmInfo{"60060124"} = "PM3ALLFASTLOOP:MAC-ID6:ProducedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"60060125"} = "PM3ALLFASTLOOP:MAC-ID6:ConsumedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"60060126"} = "PM3ALLFASTLOOP:MAC-ID6:DeviceServiceResponseTelegramUnknownAndNotHandled";
    $alarmInfo{"60060127"} = "PM3ALLFASTLOOP:MAC-ID6:ConnectionAlreadyInRequest";
    $alarmInfo{"60060128"} = "PM3ALLFASTLOOP:MAC-ID6:NumberOfCAN-messageDataBytesInReadProducedOrConsumedConnectionSizeResponseUnequal4";
    $alarmInfo{"60060129"} = "PM3ALLFASTLOOP:MAC-ID6:PredefinedMaster-slaveConnectionAlreadyExists";
    $alarmInfo{"6006012A"} = "PM3ALLFASTLOOP:MAC-ID6:LengthInPollingDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"6006012B"} = "PM3ALLFASTLOOP:MAC-ID6:SequenceErrorInDevicePollingResponse";
    $alarmInfo{"6006012C"} = "PM3ALLFASTLOOP:MAC-ID6:FragmentErrorInDevicePollingResponse";
    $alarmInfo{"6006012D"} = "PM3ALLFASTLOOP:MAC-ID6:SequenceError2InDevicePollingResponse";
    $alarmInfo{"6006012E"} = "PM3ALLFASTLOOP:MAC-ID6:LengthInBitStrobeDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"6006012F"} = "PM3ALLFASTLOOP:MAC-ID6:SequenceErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"60060130"} = "PM3ALLFASTLOOP:MAC-ID6:FragmentErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"60060131"} = "PM3ALLFASTLOOP:MAC-ID6:SequenceError2InDeviceCOSOrCyclicResponse";
    $alarmInfo{"60060132"} = "PM3ALLFASTLOOP:MAC-ID6:LengthInCOSOrCyclicDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"60060133"} = "PM3ALLFASTLOOP:MAC-ID6:UCMMGroupNotSupported";
    $alarmInfo{"60060134"} = "PM3ALLFASTLOOP:MAC-ID6:UnknownHandshakeModeConfigured";
    $alarmInfo{"60060135"} = "PM3ALLFASTLOOP:MAC-ID6:ConfiguredBaudrateNotSupported";
    $alarmInfo{"60060136"} = "PM3ALLFASTLOOP:MAC-ID6:DeviceMAC-IDOutOfRange";
    $alarmInfo{"60060137"} = "PM3ALLFASTLOOP:MAC-ID6:DuplicateMAC-IDDetected";
    $alarmInfo{"60060138"} = "PM3ALLFASTLOOP:MAC-ID6:DatabaseInTheDeviceHasNoEntriesIncluded";
    $alarmInfo{"60060139"} = "PM3ALLFASTLOOP:MAC-ID6:DoubleMAC-IDConfiguredInternally";
    $alarmInfo{"6006013A"} = "PM3ALLFASTLOOP:MAC-ID6:SizeOfOneDeviceDataSetInvalid";
    $alarmInfo{"6006013B"} = "PM3ALLFASTLOOP:MAC-ID6:OffsetTableForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"6006013C"} = "PM3ALLFASTLOOP:MAC-ID6:ConfigurationTableLengthForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"6006013D"} = "PM3ALLFASTLOOP:MAC-ID6:OffsetTableDoNotCorrespondToI/OConfigurationTable";
    $alarmInfo{"6006013E"} = "PM3ALLFASTLOOP:MAC-ID6:SizeIndicatorOfParameterDataTableCorrupt";
    $alarmInfo{"6006013F"} = "PM3ALLFASTLOOP:MAC-ID6:NumberOfInputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"60060140"} = "PM3ALLFASTLOOP:MAC-ID6:NumberOfOutputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"60060141"} = "PM3ALLFASTLOOP:MAC-ID6:UnknownDataTypeInI/OConfiguration";
    $alarmInfo{"60060142"} = "PM3ALLFASTLOOP:MAC-ID6:DataTypeDoesNotCorrespondToItsConfiguredLength";
    $alarmInfo{"60060143"} = "PM3ALLFASTLOOP:MAC-ID6:ConfiguredOutputOffsetAddressOutOfRange";
    $alarmInfo{"60060144"} = "PM3ALLFASTLOOP:MAC-ID6:ConfiguredInputOffsetAddressOutOfRange";
    $alarmInfo{"60060145"} = "PM3ALLFASTLOOP:MAC-ID6:OnePredefinedConnectionTypeIsUnknown";
    $alarmInfo{"60060146"} = "PM3ALLFASTLOOP:MAC-ID6:MultipleConnectionsDefinedInParallel";
    $alarmInfo{"60060147"} = "PM3ALLFASTLOOP:MAC-ID6:ConfiguredEXP_PCKT_RATELessThenPROD_INHIBIT_TIME";
    $alarmInfo{"60060148"} = "PM3ALLFASTLOOP:MAC-ID6:NoDatabaseFoundOnTheSystem";
    $alarmInfo{"60060149"} = "PM3ALLFASTLOOP:MAC-ID6:DatabaseReadingFailure";
    $alarmInfo{"6006014A"} = "PM3ALLFASTLOOP:MAC-ID6:UserWatchdogFailed";
    $alarmInfo{"6006014B"} = "PM3ALLFASTLOOP:MAC-ID6:NoDataAcknowledgeFromUser";
    $alarmInfo{"6006014C"} = "PM3ALLFASTLOOP:MAC-ID6:Unknown";
    $alarmInfo{"6006014D"} = "PM3ALLFASTLOOP:MAC-ID6:Unknown";
    $alarmInfo{"6006014E"} = "PM3ALLFASTLOOP:MAC-ID6:Unknown";
    $alarmInfo{"6006014F"} = "PM3ALLFASTLOOP:MAC-ID6:Unknown";
    $alarmInfo{"60060150"} = "PM3ALLFASTLOOP:CIF/DRIVER:BoardNotInitialized";
    $alarmInfo{"60060151"} = "PM3ALLFASTLOOP:CIF/DRIVER:ErrorInInternalInitState";
    $alarmInfo{"60060152"} = "PM3ALLFASTLOOP:CIF/DRIVER:ErrorInInternalReadState";
    $alarmInfo{"60060153"} = "PM3ALLFASTLOOP:CIF/DRIVER:CommandOnThisChannelIsActive";
    $alarmInfo{"60060154"} = "PM3ALLFASTLOOP:CIF/DRIVER:UnknownParameterInFunctionOccurred";
    $alarmInfo{"60060155"} = "PM3ALLFASTLOOP:CIF/DRIVER:VersionIsIncompatibleWithDLL";
    $alarmInfo{"60060156"} = "PM3ALLFASTLOOP:CIF/DRIVER:ErrorDuringPCISetConfigMode";
    $alarmInfo{"60060157"} = "PM3ALLFASTLOOP:CIF/DRIVER:CouldNotReadPCIDualPortMemoryLength";
    $alarmInfo{"60060158"} = "PM3ALLFASTLOOP:CIF/DRIVER:ErrorDuringPCISetRunMode";
    $alarmInfo{"60060159"} = "PM3ALLFASTLOOP:CIF/DRIVER:DualPortRamNotAccessibleBoardNotFound)";
    $alarmInfo{"6006015A"} = "PM3ALLFASTLOOP:CIF/DRIVER:NotReadyReady";
    $alarmInfo{"6006015B"} = "PM3ALLFASTLOOP:CIF/DRIVER:NotRunningRunning";
    $alarmInfo{"6006015C"} = "PM3ALLFASTLOOP:CIF/DRIVER:WatchdogTestFailed";
    $alarmInfo{"6006015D"} = "PM3ALLFASTLOOP:CIF/DRIVER:SignalsWrongOSVersion";
    $alarmInfo{"6006015E"} = "PM3ALLFASTLOOP:CIF/DRIVER:ErrorInDualPort";
    $alarmInfo{"6006015F"} = "PM3ALLFASTLOOP:CIF/DRIVER:SendMailboxIsFull";
    $alarmInfo{"60060160"} = "PM3ALLFASTLOOP:CIF/DRIVER:PutMessageTimeout";
    $alarmInfo{"60060161"} = "PM3ALLFASTLOOP:CIF/DRIVER:GetMessageTimeout";
    $alarmInfo{"60060162"} = "PM3ALLFASTLOOP:CIF/DRIVER:NoMessageAvailable";
    $alarmInfo{"60060163"} = "PM3ALLFASTLOOP:CIF/DRIVER:RESETCommandTimeout";
    $alarmInfo{"60060164"} = "PM3ALLFASTLOOP:CIF/DRIVER:COM-flagsNotSet";
    $alarmInfo{"60060165"} = "PM3ALLFASTLOOP:CIF/DRIVER:I/ODataExchangeFailed";
    $alarmInfo{"60060166"} = "PM3ALLFASTLOOP:CIF/DRIVER:I/ODataExchangeTimeout";
    $alarmInfo{"60060167"} = "PM3ALLFASTLOOP:CIF/DRIVER:I/ODataModeUnknown";
    $alarmInfo{"60060168"} = "PM3ALLFASTLOOP:CIF/DRIVER:FunctionCallFailed";
    $alarmInfo{"60060169"} = "PM3ALLFASTLOOP:CIF/DRIVER:DualPortMemorySizeDiffersFromConfiguration";
    $alarmInfo{"6006016A"} = "PM3ALLFASTLOOP:CIF/DRIVER:StateModeUnknown";
    $alarmInfo{"6006016B"} = "PM3ALLFASTLOOP:CIF/DRIVER:HardwarePortIsUsed";
    $alarmInfo{"6006016C"} = "PM3ALLFASTLOOP:CIF/USER:DriverNotOpenedDeviceDriverNotLoaded)";
    $alarmInfo{"6006016D"} = "PM3ALLFASTLOOP:CIF/USER:CannotConnectWithDevice";
    $alarmInfo{"6006016E"} = "PM3ALLFASTLOOP:CIF/USER:BoardNotInitializedDevInitBoardNotCalled)";
    $alarmInfo{"6006016F"} = "PM3ALLFASTLOOP:CIF/USER:IOCTRLFunctionFailed";
    $alarmInfo{"60060170"} = "PM3ALLFASTLOOP:CIF/USER:ParameterDeviceNumberInvalid";
    $alarmInfo{"60060171"} = "PM3ALLFASTLOOP:CIF/USER:ParameterInfoAreaUnknown";
    $alarmInfo{"60060172"} = "PM3ALLFASTLOOP:CIF/USER:ParameterNumberInvalid";
    $alarmInfo{"60060173"} = "PM3ALLFASTLOOP:CIF/USER:ParameterModeInvalid";
    $alarmInfo{"60060174"} = "PM3ALLFASTLOOP:CIF/USER:NULLPointerAssignment";
    $alarmInfo{"60060175"} = "PM3ALLFASTLOOP:CIF/USER:MessageBufferTooShort";
    $alarmInfo{"60060176"} = "PM3ALLFASTLOOP:CIF/USER:ParameterSizeInvalid";
    $alarmInfo{"60060177"} = "PM3ALLFASTLOOP:CIF/USER:ParameterSizeWithZeroLength";
    $alarmInfo{"60060178"} = "PM3ALLFASTLOOP:CIF/USER:ParameterSizeTooLong";
    $alarmInfo{"60060179"} = "PM3ALLFASTLOOP:CIF/USER:DeviceAddressNullPointer";
    $alarmInfo{"6006017A"} = "PM3ALLFASTLOOP:CIF/USER:PointerToBufferIsANullPointer";
    $alarmInfo{"6006017B"} = "PM3ALLFASTLOOP:CIF/USER:ParameterSendSizeTooLong";
    $alarmInfo{"6006017C"} = "PM3ALLFASTLOOP:CIF/USER:ParameterReceiveSizeTooLong";
    $alarmInfo{"6006017D"} = "PM3ALLFASTLOOP:CIF/USER:PointerToSendBufferIsANullPointer";
    $alarmInfo{"6006017E"} = "PM3ALLFASTLOOP:CIF/USER:PointerToReceiveBufferIsANullPointer";
    $alarmInfo{"6006017F"} = "PM3ALLFASTLOOP:CIF/DMA:MemoryAllocationError";
    $alarmInfo{"60060180"} = "PM3ALLFASTLOOP:CIF/DMA:ReadI/OTimeout";
    $alarmInfo{"60060181"} = "PM3ALLFASTLOOP:CIF/DMA:WriteI/OTimeout";
    $alarmInfo{"60060182"} = "PM3ALLFASTLOOP:CIF/DMA:PCITransferTimeout";
    $alarmInfo{"60060183"} = "PM3ALLFASTLOOP:CIF/DMA:DownloadTimeout";
    $alarmInfo{"60060184"} = "PM3ALLFASTLOOP:CIF/DMA:DatabaseDownloadFailed";
    $alarmInfo{"60060185"} = "PM3ALLFASTLOOP:CIF/DMA:FirmwareDownloadFailed";
    $alarmInfo{"60060186"} = "PM3ALLFASTLOOP:CIF/DMA:ClearDatabaseOnTheDeviceFailed";
    $alarmInfo{"60060187"} = "PM3ALLFASTLOOP:CIF/USER:VirtualMemoryNotAvailable";
    $alarmInfo{"60060188"} = "PM3ALLFASTLOOP:CIF/USER:UnmapVirtualMemoryFailed";
    $alarmInfo{"60060189"} = "PM3ALLFASTLOOP:CIF/DRIVER:GeneralError";
    $alarmInfo{"6006018A"} = "PM3ALLFASTLOOP:CIF/DRIVER:GeneralDMAError";
    $alarmInfo{"6006018B"} = "PM3ALLFASTLOOP:CIF/DRIVER:BatteryError";
    $alarmInfo{"6006018C"} = "PM3ALLFASTLOOP:CIF/DRIVER:PowerFailedError";
    $alarmInfo{"6006018D"} = "PM3ALLFASTLOOP:CIF/USER:DriverUnknown";
    $alarmInfo{"6006018E"} = "PM3ALLFASTLOOP:CIF/USER:DeviceNameInvalid";
    $alarmInfo{"6006018F"} = "PM3ALLFASTLOOP:CIF/USER:DeviceNameUnknown";
    $alarmInfo{"60060190"} = "PM3ALLFASTLOOP:CIF/USER:DeviceFunctionNotImplemented";
    $alarmInfo{"60060191"} = "PM3ALLFASTLOOP:CIF/USER:FileNotOpened";
    $alarmInfo{"60060192"} = "PM3ALLFASTLOOP:CIF/USER:FileSizeZero";
    $alarmInfo{"60060193"} = "PM3ALLFASTLOOP:CIF/USER:NotEnoughMemoryToLoadFile";
    $alarmInfo{"60060194"} = "PM3ALLFASTLOOP:CIF/USER:FileReadFailed";
    $alarmInfo{"60060195"} = "PM3ALLFASTLOOP:CIF/USER:FileTypeInvalid";
    $alarmInfo{"60060196"} = "PM3ALLFASTLOOP:CIF/USER:FileNameNotValid";
    $alarmInfo{"60060197"} = "PM3ALLFASTLOOP:CIF/USER:FirmwareFileNotOpened";
    $alarmInfo{"60060198"} = "PM3ALLFASTLOOP:CIF/USER:FirmwareFileSizeZero";
    $alarmInfo{"60060199"} = "PM3ALLFASTLOOP:CIF/USER:NotEnoughMemoryToLoadFirmwareFile";
    $alarmInfo{"6006019A"} = "PM3ALLFASTLOOP:CIF/USER:FirmwareFileReadFailed";
    $alarmInfo{"6006019B"} = "PM3ALLFASTLOOP:CIF/USER:FirmwareFileTypeInvalid";
    $alarmInfo{"6006019C"} = "PM3ALLFASTLOOP:CIF/USER:FirmwareFileNameNotValid";
    $alarmInfo{"6006019D"} = "PM3ALLFASTLOOP:CIF/USER:FirmwareFileDownloadError";
    $alarmInfo{"6006019E"} = "PM3ALLFASTLOOP:CIF/USER:FirmwareFileNotFoundInTheInternalTable";
    $alarmInfo{"6006019F"} = "PM3ALLFASTLOOP:CIF/USER:FirmwareFileBOOTLOADERActive";
    $alarmInfo{"600601A0"} = "PM3ALLFASTLOOP:CIF/USER:FirmwareFileNotFilePath";
    $alarmInfo{"600601A1"} = "PM3ALLFASTLOOP:CIF/USER:ConfigurationFileNotOpened";
    $alarmInfo{"600601A2"} = "PM3ALLFASTLOOP:CIF/USER:ConfigurationFileSizeZero";
    $alarmInfo{"600601A3"} = "PM3ALLFASTLOOP:CIF/USER:NotEnoughMemoryToLoadConfigurationFile";
    $alarmInfo{"600601A4"} = "PM3ALLFASTLOOP:CIF/USER:ConfigurationFileReadFailed";
    $alarmInfo{"600601A5"} = "PM3ALLFASTLOOP:CIF/USER:ConfigurationFileTypeInvalid";
    $alarmInfo{"600601A6"} = "PM3ALLFASTLOOP:CIF/USER:ConfigurationFileNameNotValid";
    $alarmInfo{"600601A7"} = "PM3ALLFASTLOOP:CIF/USER:ConfigurationFileDownloadError";
    $alarmInfo{"600601A8"} = "PM3ALLFASTLOOP:CIF/USER:NoFlashSegmentInTheConfigurationFile";
    $alarmInfo{"600601A9"} = "PM3ALLFASTLOOP:CIF/USER:ConfigurationFileDiffersFromDatabase";
    $alarmInfo{"600601AA"} = "PM3ALLFASTLOOP:CIF/USER:DatabaseSizeZero";
    $alarmInfo{"600601AB"} = "PM3ALLFASTLOOP:CIF/USER:NotEnoughMemoryToUploadDatabase";
    $alarmInfo{"600601AC"} = "PM3ALLFASTLOOP:CIF/USER:DatabaseReadFailed";
    $alarmInfo{"600601AD"} = "PM3ALLFASTLOOP:CIF/USER:DatabaseSegmentUnknown";
    $alarmInfo{"600601AE"} = "PM3ALLFASTLOOP:CIF/CONFIG:VersionOfTheDescriptTableInvalid";
    $alarmInfo{"600601AF"} = "PM3ALLFASTLOOP:CIF/CONFIG:InputOffsetIsInvalid";
    $alarmInfo{"600601B0"} = "PM3ALLFASTLOOP:CIF/CONFIG:InputSizeIs0";
    $alarmInfo{"600601B1"} = "PM3ALLFASTLOOP:CIF/CONFIG:InputSizeDoesNotMatchConfiguration";
    $alarmInfo{"600601B2"} = "PM3ALLFASTLOOP:CIF/CONFIG:OutputOffsetIsInvalid";
    $alarmInfo{"600601B3"} = "PM3ALLFASTLOOP:CIF/CONFIG:OutputSizeIs0";
    $alarmInfo{"600601B4"} = "PM3ALLFASTLOOP:CIF/CONFIG:OutputSizeDoesNotMatchConfiguration";
    $alarmInfo{"600601B5"} = "PM3ALLFASTLOOP:CIF/CONFIG:StationNotConfigured";
    $alarmInfo{"600601B6"} = "PM3ALLFASTLOOP:CIF/CONFIG:CannotGetTheStationConfiguration";
    $alarmInfo{"600601B7"} = "PM3ALLFASTLOOP:CIF/CONFIG:ModuleDefinitionIsMissing";
    $alarmInfo{"600601B8"} = "PM3ALLFASTLOOP:CIF/CONFIG:EmptySlotMismatch";
    $alarmInfo{"600601B9"} = "PM3ALLFASTLOOP:CIF/CONFIG:InputOffsetMismatch";
    $alarmInfo{"600601BA"} = "PM3ALLFASTLOOP:CIF/CONFIG:OutputOffsetMismatch";
    $alarmInfo{"600601BB"} = "PM3ALLFASTLOOP:CIF/CONFIG:DataTypeMismatch";
    $alarmInfo{"600601BC"} = "PM3ALLFASTLOOP:CIF/CONFIG:ModuleDefinitionIsMissing,NoSlot/Idx)";
    $alarmInfo{"600601BD"} = "PM3ALLFASTLOOP:CIF:Unknown";
    $alarmInfo{"600601BE"} = "PM3ALLFASTLOOP:Unknown";
    $alarmInfo{"600601BF"} = "PM3ALLFASTLOOP:Unknown";
    $alarmInfo{"600601C0"} = "PM3ALLDeviceNetMacID0CommunicationLost";
    $alarmInfo{"600601C1"} = "PM3ALLDeviceNetMacID1CommunicationLost";
    $alarmInfo{"600601C2"} = "PM3ALLDeviceNetMacID2CommunicationLost";
    $alarmInfo{"600601C3"} = "PM3ALLDeviceNetMacID3CommunicationLost";
    $alarmInfo{"600601C4"} = "PM3ALLDeviceNetMacID4CommunicationLost";
    $alarmInfo{"600601C5"} = "PM3ALLDeviceNetMacID5CommunicationLost";
    $alarmInfo{"600601C6"} = "PM3ALLDeviceNetMacID6CommunicationLost";
    $alarmInfo{"600601C7"} = "PM3ALLDeviceNetMacID7CommunicationLost";
    $alarmInfo{"600601C8"} = "PM3ALLDeviceNetMacID8CommunicationLost";
    $alarmInfo{"600601C9"} = "PM3ALLDeviceNetMacID9CommunicationLost";
    $alarmInfo{"600601CA"} = "PM3ALLDeviceNetMacID10CommunicationLost";
    $alarmInfo{"600601CB"} = "PM3ALLDeviceNetMacID11CommunicationLost";
    $alarmInfo{"600601CC"} = "PM3ALLDeviceNetMacID12CommunicationLost";
    $alarmInfo{"600601CD"} = "PM3ALLDeviceNetMacID13CommunicationLost";
    $alarmInfo{"600601CE"} = "PM3ALLDeviceNetMacID14CommunicationLost";
    $alarmInfo{"600601CF"} = "PM3ALLDeviceNetMacID15CommunicationLost";
    $alarmInfo{"600601D0"} = "PM3ALLDeviceNetMacID16CommunicationLost";
    $alarmInfo{"600601D1"} = "PM3ALLDeviceNetMacID17CommunicationLost";
    $alarmInfo{"600601D2"} = "PM3ALLDeviceNetMacID18CommunicationLost";
    $alarmInfo{"600601D3"} = "PM3ALLDeviceNetMacID19CommunicationLost";
    $alarmInfo{"600601D4"} = "PM3ALLDeviceNetMacID20CommunicationLost";
    $alarmInfo{"600601D5"} = "PM3ALLDeviceNetMacID21CommunicationLost";
    $alarmInfo{"600601D6"} = "PM3ALLDeviceNetMacID22CommunicationLost";
    $alarmInfo{"600601D7"} = "PM3ALLDeviceNetMacID23CommunicationLost";
    $alarmInfo{"600601D8"} = "PM3ALLDeviceNetMacID24CommunicationLost";
    $alarmInfo{"600601D9"} = "PM3ALLDeviceNetMacID25CommunicationLost";
    $alarmInfo{"600601DA"} = "PM3ALLDeviceNetMacID26CommunicationLost";
    $alarmInfo{"600601DB"} = "PM3ALLDeviceNetMacID27CommunicationLost";
    $alarmInfo{"600601DC"} = "PM3ALLDeviceNetMacID28CommunicationLost";
    $alarmInfo{"600601DD"} = "PM3ALLDeviceNetMacID29CommunicationLost";
    $alarmInfo{"600601DE"} = "PM3ALLDeviceNetMacID30CommunicationLost";
    $alarmInfo{"600601DF"} = "PM3ALLDeviceNetMacID31CommunicationLost";
    $alarmInfo{"600601E0"} = "PM3ALLDeviceNetMacID32CommunicationLost";
    $alarmInfo{"600601E1"} = "PM3ALLDeviceNetMacID33CommunicationLost";
    $alarmInfo{"600601E2"} = "PM3ALLDeviceNetMacID34CommunicationLost";
    $alarmInfo{"600601E3"} = "PM3ALLDeviceNetMacID35CommunicationLost";
    $alarmInfo{"600601E4"} = "PM3ALLDeviceNetMacID36CommunicationLost";
    $alarmInfo{"600601E5"} = "PM3ALLDeviceNetMacID37CommunicationLost";
    $alarmInfo{"600601E6"} = "PM3ALLDeviceNetMacID38CommunicationLost";
    $alarmInfo{"600601E7"} = "PM3ALLDeviceNetMacID39CommunicationLost";
    $alarmInfo{"600601E8"} = "PM3ALLDeviceNetMacID40CommunicationLost";
    $alarmInfo{"600601E9"} = "PM3ALLDeviceNetMacID41CommunicationLost";
    $alarmInfo{"600601EA"} = "PM3ALLDeviceNetMacID42CommunicationLost";
    $alarmInfo{"600601EB"} = "PM3ALLDeviceNetMacID43CommunicationLost";
    $alarmInfo{"600601EC"} = "PM3ALLDeviceNetMacID44CommunicationLost";
    $alarmInfo{"600601ED"} = "PM3ALLDeviceNetMacID45CommunicationLost";
    $alarmInfo{"600601EE"} = "PM3ALLDeviceNetMacID46CommunicationLost";
    $alarmInfo{"600601EF"} = "PM3ALLDeviceNetMacID47CommunicationLost";
    $alarmInfo{"600601F0"} = "PM3ALLDeviceNetMacID48CommunicationLost";
    $alarmInfo{"600601F1"} = "PM3ALLDeviceNetMacID49CommunicationLost";
    $alarmInfo{"600601F2"} = "PM3ALLDeviceNetMacID50CommunicationLost";
    $alarmInfo{"600601F3"} = "PM3ALLDeviceNetMacID51CommunicationLost";
    $alarmInfo{"600601F4"} = "PM3ALLDeviceNetMacID52CommunicationLost";
    $alarmInfo{"600601F5"} = "PM3ALLDeviceNetMacID53CommunicationLost";
    $alarmInfo{"600601F6"} = "PM3ALLDeviceNetMacID54CommunicationLost";
    $alarmInfo{"600601F7"} = "PM3ALLDeviceNetMacID55CommunicationLost";
    $alarmInfo{"600601F8"} = "PM3ALLDeviceNetMacID56CommunicationLost";
    $alarmInfo{"600601F9"} = "PM3ALLDeviceNetMacID57CommunicationLost";
    $alarmInfo{"600601FA"} = "PM3ALLDeviceNetMacID58CommunicationLost";
    $alarmInfo{"600601FB"} = "PM3ALLDeviceNetMacID59CommunicationLost";
    $alarmInfo{"600601FC"} = "PM3ALLDeviceNetMacID60CommunicationLost";
    $alarmInfo{"600601FD"} = "PM3ALLDeviceNetMacID61CommunicationLost";
    $alarmInfo{"600601FE"} = "PM3ALLDeviceNetMacID62CommunicationLost";
    $alarmInfo{"600601FF"} = "PM3ALLDeviceNetMacID63CommunicationLost";
    $alarmInfo{"60060240"} = "PM3ALLDeviceNetMacID0Error";
    $alarmInfo{"60060241"} = "PM3ALLDeviceNetMacID1Error";
    $alarmInfo{"60060242"} = "PM3ALLDeviceNetMacID2Error";
    $alarmInfo{"60060243"} = "PM3ALLDeviceNetMacID3Error";
    $alarmInfo{"60060244"} = "PM3ALLDeviceNetMacID4Error";
    $alarmInfo{"60060245"} = "PM3ALLDeviceNetMacID5Error";
    $alarmInfo{"60060246"} = "PM3ALLDeviceNetMacID6Error";
    $alarmInfo{"60060247"} = "PM3ALLDeviceNetMacID7Error";
    $alarmInfo{"60060248"} = "PM3ALLDeviceNetMacID8Error";
    $alarmInfo{"60060249"} = "PM3ALLDeviceNetMacID9Error";
    $alarmInfo{"6006024A"} = "PM3ALLDeviceNetMacID10Error";
    $alarmInfo{"6006024B"} = "PM3ALLDeviceNetMacID11Error";
    $alarmInfo{"6006024C"} = "PM3ALLDeviceNetMacID12Error";
    $alarmInfo{"6006024D"} = "PM3ALLDeviceNetMacID13Error";
    $alarmInfo{"6006024E"} = "PM3ALLDeviceNetMacID14Error";
    $alarmInfo{"6006024F"} = "PM3ALLDeviceNetMacID15Error";
    $alarmInfo{"60060250"} = "PM3ALLDeviceNetMacID16Error";
    $alarmInfo{"60060251"} = "PM3ALLDeviceNetMacID17Error";
    $alarmInfo{"60060252"} = "PM3ALLDeviceNetMacID18Error";
    $alarmInfo{"60060253"} = "PM3ALLDeviceNetMacID19Error";
    $alarmInfo{"60060254"} = "PM3ALLDeviceNetMacID20Error";
    $alarmInfo{"60060255"} = "PM3ALLDeviceNetMacID21Error";
    $alarmInfo{"60060256"} = "PM3ALLDeviceNetMacID22Error";
    $alarmInfo{"60060257"} = "PM3ALLDeviceNetMacID23Error";
    $alarmInfo{"60060258"} = "PM3ALLDeviceNetMacID24Error";
    $alarmInfo{"60060259"} = "PM3ALLDeviceNetMacID25Error";
    $alarmInfo{"6006025A"} = "PM3ALLDeviceNetMacID26Error";
    $alarmInfo{"6006025B"} = "PM3ALLDeviceNetMacID27Error";
    $alarmInfo{"6006025C"} = "PM3ALLDeviceNetMacID28Error";
    $alarmInfo{"6006025D"} = "PM3ALLDeviceNetMacID29Error";
    $alarmInfo{"6006025E"} = "PM3ALLDeviceNetMacID30Error";
    $alarmInfo{"6006025F"} = "PM3ALLDeviceNetMacID31Error";
    $alarmInfo{"60060260"} = "PM3ALLDeviceNetMacID32Error";
    $alarmInfo{"60060261"} = "PM3ALLDeviceNetMacID33Error";
    $alarmInfo{"60060262"} = "PM3ALLDeviceNetMacID34Error";
    $alarmInfo{"60060263"} = "PM3ALLDeviceNetMacID35Error";
    $alarmInfo{"60060264"} = "PM3ALLDeviceNetMacID36Error";
    $alarmInfo{"60060265"} = "PM3ALLDeviceNetMacID37Error";
    $alarmInfo{"60060266"} = "PM3ALLDeviceNetMacID38Error";
    $alarmInfo{"60060267"} = "PM3ALLDeviceNetMacID39Error";
    $alarmInfo{"60060268"} = "PM3ALLDeviceNetMacID40Error";
    $alarmInfo{"60060269"} = "PM3ALLDeviceNetMacID41Error";
    $alarmInfo{"6006026A"} = "PM3ALLDeviceNetMacID42Error";
    $alarmInfo{"6006026B"} = "PM3ALLDeviceNetMacID43Error";
    $alarmInfo{"6006026C"} = "PM3ALLDeviceNetMacID44Error";
    $alarmInfo{"6006026D"} = "PM3ALLDeviceNetMacID45Error";
    $alarmInfo{"6006026E"} = "PM3ALLDeviceNetMacID46Error";
    $alarmInfo{"6006026F"} = "PM3ALLDeviceNetMacID47Error";
    $alarmInfo{"60060270"} = "PM3ALLDeviceNetMacID48Error";
    $alarmInfo{"60060271"} = "PM3ALLDeviceNetMacID49Error";
    $alarmInfo{"60060272"} = "PM3ALLDeviceNetMacID50Error";
    $alarmInfo{"60060273"} = "PM3ALLDeviceNetMacID51Error";
    $alarmInfo{"60060274"} = "PM3ALLDeviceNetMacID52Error";
    $alarmInfo{"60060275"} = "PM3ALLDeviceNetMacID53Error";
    $alarmInfo{"60060276"} = "PM3ALLDeviceNetMacID54Error";
    $alarmInfo{"60060277"} = "PM3ALLDeviceNetMacID55Error";
    $alarmInfo{"60060278"} = "PM3ALLDeviceNetMacID56Error";
    $alarmInfo{"60060279"} = "PM3ALLDeviceNetMacID57Error";
    $alarmInfo{"6006027A"} = "PM3ALLDeviceNetMacID58Error";
    $alarmInfo{"6006027B"} = "PM3ALLDeviceNetMacID59Error";
    $alarmInfo{"6006027C"} = "PM3ALLDeviceNetMacID60Error";
    $alarmInfo{"6006027D"} = "PM3ALLDeviceNetMacID61Error";
    $alarmInfo{"6006027E"} = "PM3ALLDeviceNetMacID62Error";
    $alarmInfo{"6006027F"} = "PM3ALLDeviceNetMacID63Error";
    $alarmInfo{"6010000"} = "SusceptorAlarmSS1Cleared";
    $alarmInfo{"6010001"} = "SusceptorAlarmSS1Detected";
    $alarmInfo{"6020000"} = "SusceptorAlarmSS2Cleared";
    $alarmInfo{"6020001"} = "SusceptorAlarmSS2Detected";
    $alarmInfo{"6030000"} = "SusceptorAlarmSS3Cleared";
    $alarmInfo{"6030001"} = "SusceptorAlarmSS3Detected";
    $alarmInfo{"6040000"} = "SusceptorAlarmSS4Cleared";
    $alarmInfo{"6040001"} = "SusceptorAlarmSS4Detected";
    $alarmInfo{"6060000"} = "6060000";
    $alarmInfo{"61060000"} = "61060000";
    $alarmInfo{"61060001"} = "TCCommunicationTimeout";
    $alarmInfo{"61060002"} = "ADSCommunicationTimeout";
    $alarmInfo{"61060003"} = "ADSWatchDogAlarmOccurred";
    $alarmInfo{"61060004"} = "ConfigurationFileOrRecipeFileNotReceived";
    $alarmInfo{"61060005"} = "StatusIsNotREADY";
    $alarmInfo{"61060006"} = "StatusIsRUN";
    $alarmInfo{"61060007"} = "StatusIsNotRUN";
    $alarmInfo{"61060008"} = "NoStartStepExistsInTheSpecifiedRecipe";
    $alarmInfo{"61060009"} = "PressureValueAnd1atmSensorMismatch";
    $alarmInfo{"6106000A"} = "AlarmOccurred";
    $alarmInfo{"6106000B"} = "PauseOccurred";
    $alarmInfo{"6106000C"} = "SafetyOccurred";
    $alarmInfo{"6106000D"} = "AbortOccurred";
    $alarmInfo{"6106000E"} = "OtherErrorOccurred";
    $alarmInfo{"61060010"} = "SeriousAlarmNonRecipe)Occurred";
    $alarmInfo{"61060011"} = "LightAlarmNonRecipe)Occurred";
    $alarmInfo{"61060012"} = "SafetyLatchAlarmOccurred";
    $alarmInfo{"61060013"} = "MaintenanceAlarmOccurred";
    $alarmInfo{"61060014"} = "DIMaintenanceAlarmOccurred";
    $alarmInfo{"61060020"} = "CapabilityIsAborted";
    $alarmInfo{"61060021"} = "Purge-CurtainStatusIsNot-Active";
    $alarmInfo{"61060022"} = "NoWafersAvailableForPeriodicDummy";
    $alarmInfo{"61060023"} = "WarningCountNearingAutoCleanLimit";
    $alarmInfo{"61060024"} = "WarningCountNearingAutoPurgeLimit";
    $alarmInfo{"61060025"} = "WarningCountNearingAutoDummyLimit";
    $alarmInfo{"61060026"} = "CoolingWaterLeak";
    $alarmInfo{"61060027"} = "CoolingWaterLeak2";
    $alarmInfo{"61060028"} = "SmokeDetected";
    $alarmInfo{"61060029"} = "HClDetectedBySensor";
    $alarmInfo{"6106002A"} = "LiquidLeakDetected";
    $alarmInfo{"6106002B"} = "LiquidLeak2Detected";
    $alarmInfo{"6106002C"} = "H2Detected";
    $alarmInfo{"6106002D"} = "Cl2Detected";
    $alarmInfo{"6106002E"} = "NH3Detected";
    $alarmInfo{"6106002F"} = "EmeraldHIGFlowControlDisabled";
    $alarmInfo{"61060040"} = "ModuleNotResponding";
    $alarmInfo{"61060041"} = "HoldToAbortTimeout";
    $alarmInfo{"61060042"} = "SlotValveOpen";
    $alarmInfo{"61060043"} = "PC104PMCommunicationsDisconnected";
    $alarmInfo{"61060044"} = "MustRunSERVICEStartupRecipe";
    $alarmInfo{"61060045"} = "InvalidSERVICERecipeType";
    $alarmInfo{"61060046"} = "LocalRackLockedUp";
    $alarmInfo{"61060047"} = "Gas1FlowToleranceFault";
    $alarmInfo{"61060048"} = "Gas2FlowToleranceFault";
    $alarmInfo{"61060049"} = "Gas3FlowToleranceFault";
    $alarmInfo{"6106004A"} = "Gas4FlowToleranceFault";
    $alarmInfo{"6106004B"} = "HivacFailedToOpen";
    $alarmInfo{"6106004C"} = "HivacFailedToClose";
    $alarmInfo{"6106004D"} = "PumpToBaseFailed";
    $alarmInfo{"6106004E"} = "RoughingTimeout";
    $alarmInfo{"6106004F"} = "RoughingPressureTooHigh";
    $alarmInfo{"61060050"} = "CryoOverMaxTemperature";
    $alarmInfo{"61060051"} = "TurboPumpFailed";
    $alarmInfo{"61060052"} = "TurboOverMaxTemperature";
    $alarmInfo{"61060053"} = "CannotRegenTurboPump!";
    $alarmInfo{"61060054"} = "TurboFailedToReachSpeed";
    $alarmInfo{"61060055"} = "TurboAtFaultOrNotAtSpeed";
    $alarmInfo{"61060056"} = "WaferLiftSlowToMoveUp";
    $alarmInfo{"61060057"} = "WaferLiftSlowToMoveDown";
    $alarmInfo{"61060058"} = "WaferLiftFailedToMove";
    $alarmInfo{"61060059"} = "PlatenControlTempT/CDisconnected";
    $alarmInfo{"6106005A"} = "PlatenSafetyTempT/CDisconnected";
    $alarmInfo{"6106005B"} = "PlatenControl-safetyTempDifference";
    $alarmInfo{"6106005C"} = "PlatenTempOutOfBand";
    $alarmInfo{"6106005D"} = "PlatenFailedToMoveUp";
    $alarmInfo{"6106005E"} = "PlatenFailedToMoveDown";
    $alarmInfo{"6106005F"} = "RecirculatorTempOutOfBand";
    $alarmInfo{"61060060"} = "RecirculatorTempT/CDisconnected";
    $alarmInfo{"61060061"} = "PlatenTempT/CDisconnected";
    $alarmInfo{"61060062"} = "CoilRFReflectedPowerFault";
    $alarmInfo{"61060063"} = "CoilRFReflectedPowerHold";
    $alarmInfo{"61060064"} = "CoilForwardPowerFault";
    $alarmInfo{"61060065"} = "PotMovementPositionFault";
    $alarmInfo{"61060066"} = "PlatenRFReflectedPowerAbort";
    $alarmInfo{"61060067"} = "PlatenRFReflectedPowerHold";
    $alarmInfo{"61060068"} = "DCBiasAboveMaxLimit";
    $alarmInfo{"61060069"} = "DCBiasBelowMinLimit";
    $alarmInfo{"6106006A"} = "DCBiasToleranceFault";
    $alarmInfo{"6106006B"} = "ForwardPowerToleranceFault";
    $alarmInfo{"6106006C"} = "LoadPowerToleranceFault";
    $alarmInfo{"6106006D"} = "Bake-outControlTempT/CDisconnected";
    $alarmInfo{"6106006E"} = "Bake-outSafetyTempT/CDisconnected";
    $alarmInfo{"6106006F"} = "Bake-outControl-safetyTempDifference";
    $alarmInfo{"61060070"} = "Bake-outSlowToReachTemperature";
    $alarmInfo{"61060071"} = "EscPump-outPressureLimitFault";
    $alarmInfo{"61060072"} = "EscPump-outPressureFaultInUnclamp";
    $alarmInfo{"61060073"} = "EscFlowFault";
    $alarmInfo{"61060074"} = "EscWaferValveOpenFault";
    $alarmInfo{"61060075"} = "EscPressureInBandTime-out";
    $alarmInfo{"61060076"} = "EscPressureToleranceFault";
    $alarmInfo{"61060077"} = "EscVoltageFault";
    $alarmInfo{"61060078"} = "TimeoutWaitingForBackfillPressure";
    $alarmInfo{"61060079"} = "Leak-upRateFailure";
    $alarmInfo{"6106007A"} = "CompressedAirFault";
    $alarmInfo{"6106007B"} = "LocalPCTemperatureFault";
    $alarmInfo{"6106007C"} = "ModuleFanFault";
    $alarmInfo{"6106007D"} = "VentServiceFailedToReachAtmosphere";
    $alarmInfo{"6106007E"} = "RGALeakCheckRequired";
    $alarmInfo{"6106007F"} = "WaitingForStage1Pressure -Slow";
    $alarmInfo{"61060080"} = "WaitingForStage2Pressure -Slow";
    $alarmInfo{"61060081"} = "NotWaitingForStage1Pressure ";
    $alarmInfo{"61060082"} = "FailedToReachStage1Pressure";
    $alarmInfo{"61060083"} = "FailedToReachStage2Pressure";
    $alarmInfo{"61060084"} = "CryoRegenServiceRoutineFailed";
    $alarmInfo{"61060085"} = "CTIControllerCommunicationsError";
    $alarmInfo{"61060086"} = "CTIPumpNotResponding";
    $alarmInfo{"61060087"} = "TurboPlusServiceRoutineFailed";
    $alarmInfo{"61060088"} = "HeaterMalfunctionHappened";
    $alarmInfo{"61600030"} = "RC3ADSWatchDogAlarmOccurredClr";
    $alarmInfo{"61600031"} = "RC3ADSWatchDogAlarmOccurredDet";
    $alarmInfo{"616000a0"} = "RC3AlarmOccurredClr";
    $alarmInfo{"616000a1"} = "RC3AlarmOccurredDet";
    $alarmInfo{"61600100"} = "RC3SeriousAlarmOccurredClr";
    $alarmInfo{"61600101"} = "RC3SeriousAlarmOccurredDet";
    $alarmInfo{"61600110"} = "RC3LightAlarmOccurredClr";
    $alarmInfo{"61600111"} = "RC3LightAlarmOccurredDet";
    $alarmInfo{"61600120"} = "RC3SafetyLatchAlarmOccurredClr";
    $alarmInfo{"61600121"} = "RC3SafetyLatchAlarmOccurredDet";
    $alarmInfo{"61600130"} = "RC3MaintenanceAlarmOccurredClr";
    $alarmInfo{"61600131"} = "RC3MaintenanceAlarmOccurredDet";
    $alarmInfo{"61600140"} = "RC3DIMaintenanceAlarmOccurredClr";
    $alarmInfo{"61600141"} = "RC3DIMaintenanceAlarmOccurredDet";
    $alarmInfo{"62060000"} = "62060000";
    $alarmInfo{"62060001"} = "CommunicationTimeout";
    $alarmInfo{"62060002"} = "StatusChangedToIDLE";
    $alarmInfo{"62060003"} = "CommandWasRejected";
    $alarmInfo{"62060004"} = "MotionStopped";
    $alarmInfo{"62060005"} = "MotionAborted";
    $alarmInfo{"62060006"} = "MotorStatusError";
    $alarmInfo{"62060007"} = "ACKTimeout";
    $alarmInfo{"62060008"} = "CompletionTimeout";
    $alarmInfo{"62060009"} = "ActualError";
    $alarmInfo{"6206000A"} = "SensorError";
    $alarmInfo{"6206000B"} = "SensorUnknown";
    $alarmInfo{"6206000C"} = "TransferInterlockErrorOccurred";
    $alarmInfo{"6206000D"} = "WaferInterlockErrorOccurred";
    $alarmInfo{"6206000E"} = "PressureInterlockErrorOccurred";
    $alarmInfo{"62060010"} = "MotorUnitErrorOccurred";
    $alarmInfo{"62060011"} = "InitializationUncompleted";
    $alarmInfo{"62060012"} = "BERobotInterlockErrorOccurred";
    $alarmInfo{"62060013"} = "HardwareUpperLimitSensorTripped";
    $alarmInfo{"62060014"} = "HardwareLowerLimitSensorTripped";
    $alarmInfo{"62060015"} = "RotationAxisHardwareInterlockOccurred";
    $alarmInfo{"62060016"} = "RotationAxisSoftwareInterlockOccurred";
    $alarmInfo{"62060017"} = "VerticalAxisSoftwareInterlockOccurred";
    $alarmInfo{"62060018"} = "HardwareLimitSwitchIsNotProperlySetup";
    $alarmInfo{"62060019"} = "ExceedTheSoftwareLimitsOfUpperPulse";
    $alarmInfo{"6206001A"} = "ExceedTheSoftwareLimitsOfLowerPulse";
    $alarmInfo{"6206001B"} = "GateValveIsOpen";
    $alarmInfo{"6206001C"} = "MotionStopOccurred";
    $alarmInfo{"6206001D"} = "ChamberLidIsOpen";
    $alarmInfo{"6206001E"} = "BERBArmIsExtendedPosition";
    $alarmInfo{"6206001F"} = "LiftCabinetIsOpen";
    $alarmInfo{"62060020"} = "ErrorReadingRotationHomeSensorState";
    $alarmInfo{"62060021"} = "RotationHome";
    $alarmInfo{"62061006"} = "62061006";
    $alarmInfo{"63060000"} = "63060000-EPI";
    $alarmInfo{"6B060001"} = "6B060001-EPI";
    $alarmInfo{"6B060002"} = "6B060002-EPI";
    $alarmInfo{"6B060003"} = "6B060003-EPI";
    $alarmInfo{"6B060004"} = "6B060004-EPI";
    $alarmInfo{"6B060005"} = "6B060005-EPI";
    $alarmInfo{"6B060006"} = "6B060006-EPI";
    $alarmInfo{"6B060007"} = "6B060007-EPI";
    $alarmInfo{"6B060008"} = "6B060008-EPI";
    $alarmInfo{"6B060009"} = "6B060009-EPI";
    $alarmInfo{"6B06000A"} = "6B06000A-EPI";

    $alarmInfo{"70060000"} = "70060000";
    $alarmInfo{"70060001"} = "PM4ALLWatchDriverFroze";
    $alarmInfo{"70060002"} = "PM4ALLPMDeviceNetDriverFroze";
    $alarmInfo{"70060003"} = "PM4ALLADSDriverFroze";
    $alarmInfo{"70060004"} = "PM4ALLTemparatureDriverFroze";
    $alarmInfo{"70060005"} = "PM4ALLPMDeviceNetDIODriverFroze";
    $alarmInfo{"70060006"} = "PM4ALLPMSEQDriverFroze";
    $alarmInfo{"70060007"} = "PM4ALLPMDeviceNetAIODriverFroze";
    $alarmInfo{"70060008"} = "PM4ALLPMRecipeExecutorFroze";
    $alarmInfo{"70060009"} = "PM4ALLSusceptorControlDriverFroze";
    $alarmInfo{"7006000A"} = "PM4ALLPressurePIDControlDriverFroze";
    $alarmInfo{"7006000B"} = "PM4ALLPulsingEngineFroze";
    $alarmInfo{"7006000E"} = "PM4ALLStepTimeError";
    $alarmInfo{"70060010"} = "PM4ALLHSEControlDriverFroze";
    $alarmInfo{"70060020"} = "PM4ALLFASTLOOP:Error";
    $alarmInfo{"70060021"} = "PM4ALLFASTLOOP:CIF:DualPortMemoryIsNull";
    $alarmInfo{"70060022"} = "PM4ALLFASTLOOP:DeviceNet:WatchDogError";
    $alarmInfo{"70060023"} = "PM4ALLFASTLOOP:DeviceNet:CommunicationStateOff-line";
    $alarmInfo{"70060024"} = "PM4ALLFASTLOOP:DeviceNet:CommunicationStateStop";
    $alarmInfo{"70060025"} = "PM4ALLFASTLOOP:DeviceNet:CommunicationStateClear";
    $alarmInfo{"70060026"} = "PM4ALLFASTLOOP:DeviceNet:FatalError";
    $alarmInfo{"70060027"} = "PM4ALLFASTLOOP:DeviceNet:BUSError";
    $alarmInfo{"70060028"} = "PM4ALLFASTLOOP:DeviceNet:BUSOff";
    $alarmInfo{"70060029"} = "PM4ALLFASTLOOP:DeviceNet:NoExchange";
    $alarmInfo{"7006002A"} = "PM4ALLFASTLOOP:DeviceNet:AutoClearError";
    $alarmInfo{"7006002B"} = "PM4ALLFASTLOOP:DeviceNet:DuplicateMAC-ID";
    $alarmInfo{"7006002C"} = "PM4ALLFASTLOOP:DeviceNet:HostNotReady";
    $alarmInfo{"7006002D"} = "PM4ALLFASTLOOP:Unknown";
    $alarmInfo{"7006002E"} = "PM4ALLFASTLOOP:Unknown";
    $alarmInfo{"7006002F"} = "PM4ALLFASTLOOP:Unknown";
    $alarmInfo{"70060030"} = "PM4ALLFASTLOOP:MAC-ID1:DeviceGuardingFailed,AfterDeviceWasOperational";
    $alarmInfo{"70060031"} = "PM4ALLFASTLOOP:MAC-ID1:DeviceAccessTimeout";
    $alarmInfo{"70060032"} = "PM4ALLFASTLOOP:MAC-ID1:DeviceRejectsAccessWithUnknownErrorCode";
    $alarmInfo{"70060033"} = "PM4ALLFASTLOOP:MAC-ID1:DeviceResponseInAllocationPhaseWithConnectionError";
    $alarmInfo{"70060034"} = "PM4ALLFASTLOOP:MAC-ID1:ProducedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"70060035"} = "PM4ALLFASTLOOP:MAC-ID1:ConsumedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"70060036"} = "PM4ALLFASTLOOP:MAC-ID1:DeviceServiceResponseTelegramUnknownAndNotHandled";
    $alarmInfo{"70060037"} = "PM4ALLFASTLOOP:MAC-ID1:ConnectionAlreadyInRequest";
    $alarmInfo{"70060038"} = "PM4ALLFASTLOOP:MAC-ID1:NumberOfCAN-messageDataBytesInReadProducedOrConsumedConnectionSizeResponseUnequal4";
    $alarmInfo{"70060039"} = "PM4ALLFASTLOOP:MAC-ID1:PredefinedMaster-slaveConnectionAlreadyExists";
    $alarmInfo{"7006003A"} = "PM4ALLFASTLOOP:MAC-ID1:LengthInPollingDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"7006003B"} = "PM4ALLFASTLOOP:MAC-ID1:SequenceErrorInDevicePollingResponse";
    $alarmInfo{"7006003C"} = "PM4ALLFASTLOOP:MAC-ID1:FragmentErrorInDevicePollingResponse";
    $alarmInfo{"7006003D"} = "PM4ALLFASTLOOP:MAC-ID1:SequenceError2InDevicePollingResponse";
    $alarmInfo{"7006003E"} = "PM4ALLFASTLOOP:MAC-ID1:LengthInBitStrobeDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"7006003F"} = "PM4ALLFASTLOOP:MAC-ID1:SequenceErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"70060040"} = "PM4ALLFASTLOOP:MAC-ID1:FragmentErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"70060041"} = "PM4ALLFASTLOOP:MAC-ID1:SequenceError2InDeviceCOSOrCyclicResponse";
    $alarmInfo{"70060042"} = "PM4ALLFASTLOOP:MAC-ID1:LengthInCOSOrCyclicDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"70060043"} = "PM4ALLFASTLOOP:MAC-ID1:UCMMGroupNotSupported";
    $alarmInfo{"70060044"} = "PM4ALLFASTLOOP:MAC-ID1:UnknownHandshakeModeConfigured";
    $alarmInfo{"70060045"} = "PM4ALLFASTLOOP:MAC-ID1:ConfiguredBaudrateNotSupported";
    $alarmInfo{"70060046"} = "PM4ALLFASTLOOP:MAC-ID1:DeviceMAC-IDOutOfRange";
    $alarmInfo{"70060047"} = "PM4ALLFASTLOOP:MAC-ID1:DuplicateMAC-IDDetected";
    $alarmInfo{"70060048"} = "PM4ALLFASTLOOP:MAC-ID1:DatabaseInTheDeviceHasNoEntriesIncluded";
    $alarmInfo{"70060049"} = "PM4ALLFASTLOOP:MAC-ID1:DoubleMAC-IDConfiguredInternally";
    $alarmInfo{"7006004A"} = "PM4ALLFASTLOOP:MAC-ID1:SizeOfOneDeviceDataSetInvalid";
    $alarmInfo{"7006004B"} = "PM4ALLFASTLOOP:MAC-ID1:OffsetTableForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"7006004C"} = "PM4ALLFASTLOOP:MAC-ID1:ConfigurationTableLengthForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"7006004D"} = "PM4ALLFASTLOOP:MAC-ID1:OffsetTableDoNotCorrespondToI/OConfigurationTable";
    $alarmInfo{"7006004E"} = "PM4ALLFASTLOOP:MAC-ID1:SizeIndicatorOfParameterDataTableCorrupt";
    $alarmInfo{"7006004F"} = "PM4ALLFASTLOOP:MAC-ID1:NumberOfInputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"70060050"} = "PM4ALLFASTLOOP:MAC-ID1:NumberOfOutputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"70060051"} = "PM4ALLFASTLOOP:MAC-ID1:UnknownDataTypeInI/OConfiguration";
    $alarmInfo{"70060052"} = "PM4ALLFASTLOOP:MAC-ID1:DataTypeDoesNotCorrespondToItsConfiguredLength";
    $alarmInfo{"70060053"} = "PM4ALLFASTLOOP:MAC-ID1:ConfiguredOutputOffsetAddressOutOfRange";
    $alarmInfo{"70060054"} = "PM4ALLFASTLOOP:MAC-ID1:ConfiguredInputOffsetAddressOutOfRange";
    $alarmInfo{"70060055"} = "PM4ALLFASTLOOP:MAC-ID1:OnePredefinedConnectionTypeIsUnknown";
    $alarmInfo{"70060056"} = "PM4ALLFASTLOOP:MAC-ID1:MultipleConnectionsDefinedInParallel";
    $alarmInfo{"70060057"} = "PM4ALLFASTLOOP:MAC-ID1:ConfiguredEXP_PCKT_RATELessThenPROD_INHIBIT_TIME";
    $alarmInfo{"70060058"} = "PM4ALLFASTLOOP:MAC-ID1:NoDatabaseFoundOnTheSystem";
    $alarmInfo{"70060059"} = "PM4ALLFASTLOOP:MAC-ID1:DatabaseReadingFailure";
    $alarmInfo{"7006005A"} = "PM4ALLFASTLOOP:MAC-ID1:UserWatchdogFailed";
    $alarmInfo{"7006005B"} = "PM4ALLFASTLOOP:MAC-ID1:NoDataAcknowledgeFromUser";
    $alarmInfo{"7006005C"} = "PM4ALLFASTLOOP:MAC-ID1:Unknown";
    $alarmInfo{"7006005D"} = "PM4ALLFASTLOOP:MAC-ID1:Unknown";
    $alarmInfo{"7006005E"} = "PM4ALLFASTLOOP:MAC-ID1:Unknown";
    $alarmInfo{"7006005F"} = "PM4ALLFASTLOOP:MAC-ID1:Unknown";
    $alarmInfo{"70060060"} = "PM4ALLFASTLOOP:MAC-ID2:DeviceGuardingFailed,AfterDeviceWasOperational";
    $alarmInfo{"70060061"} = "PM4ALLFASTLOOP:MAC-ID2:DeviceAccessTimeout";
    $alarmInfo{"70060062"} = "PM4ALLFASTLOOP:MAC-ID2:DeviceRejectsAccessWithUnknownErrorCode";
    $alarmInfo{"70060063"} = "PM4ALLFASTLOOP:MAC-ID2:DeviceResponseInAllocationPhaseWithConnectionError";
    $alarmInfo{"70060064"} = "PM4ALLFASTLOOP:MAC-ID2:ProducedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"70060065"} = "PM4ALLFASTLOOP:MAC-ID2:ConsumedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"70060066"} = "PM4ALLFASTLOOP:MAC-ID2:DeviceServiceResponseTelegramUnknownAndNotHandled";
    $alarmInfo{"70060067"} = "PM4ALLFASTLOOP:MAC-ID2:ConnectionAlreadyInRequest";
    $alarmInfo{"70060068"} = "PM4ALLFASTLOOP:MAC-ID2:NumberOfCAN-messageDataBytesInReadProducedOrConsumedConnectionSizeResponseUnequal4";
    $alarmInfo{"70060069"} = "PM4ALLFASTLOOP:MAC-ID2:PredefinedMaster-slaveConnectionAlreadyExists";
    $alarmInfo{"7006006A"} = "PM4ALLFASTLOOP:MAC-ID2:LengthInPollingDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"7006006B"} = "PM4ALLFASTLOOP:MAC-ID2:SequenceErrorInDevicePollingResponse";
    $alarmInfo{"7006006C"} = "PM4ALLFASTLOOP:MAC-ID2:FragmentErrorInDevicePollingResponse";
    $alarmInfo{"7006006D"} = "PM4ALLFASTLOOP:MAC-ID2:SequenceError2InDevicePollingResponse";
    $alarmInfo{"7006006E"} = "PM4ALLFASTLOOP:MAC-ID2:LengthInBitStrobeDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"7006006F"} = "PM4ALLFASTLOOP:MAC-ID2:SequenceErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"70060070"} = "PM4ALLFASTLOOP:MAC-ID2:FragmentErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"70060071"} = "PM4ALLFASTLOOP:MAC-ID2:SequenceError2InDeviceCOSOrCyclicResponse";
    $alarmInfo{"70060072"} = "PM4ALLFASTLOOP:MAC-ID2:LengthInCOSOrCyclicDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"70060073"} = "PM4ALLFASTLOOP:MAC-ID2:UCMMGroupNotSupported";
    $alarmInfo{"70060074"} = "PM4ALLFASTLOOP:MAC-ID2:UnknownHandshakeModeConfigured";
    $alarmInfo{"70060075"} = "PM4ALLFASTLOOP:MAC-ID2:ConfiguredBaudrateNotSupported";
    $alarmInfo{"70060076"} = "PM4ALLFASTLOOP:MAC-ID2:DeviceMAC-IDOutOfRange";
    $alarmInfo{"70060077"} = "PM4ALLFASTLOOP:MAC-ID2:DuplicateMAC-IDDetected";
    $alarmInfo{"70060078"} = "PM4ALLFASTLOOP:MAC-ID2:DatabaseInTheDeviceHasNoEntriesIncluded";
    $alarmInfo{"70060079"} = "PM4ALLFASTLOOP:MAC-ID2:DoubleMAC-IDConfiguredInternally";
    $alarmInfo{"7006007A"} = "PM4ALLFASTLOOP:MAC-ID2:SizeOfOneDeviceDataSetInvalid";
    $alarmInfo{"7006007B"} = "PM4ALLFASTLOOP:MAC-ID2:OffsetTableForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"7006007C"} = "PM4ALLFASTLOOP:MAC-ID2:ConfigurationTableLengthForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"7006007D"} = "PM4ALLFASTLOOP:MAC-ID2:OffsetTableDoNotCorrespondToI/OConfigurationTable";
    $alarmInfo{"7006007E"} = "PM4ALLFASTLOOP:MAC-ID2:SizeIndicatorOfParameterDataTableCorrupt";
    $alarmInfo{"7006007F"} = "PM4ALLFASTLOOP:MAC-ID2:NumberOfInputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"70060080"} = "PM4ALLFASTLOOP:MAC-ID2:NumberOfOutputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"70060081"} = "PM4ALLFASTLOOP:MAC-ID2:UnknownDataTypeInI/OConfiguration";
    $alarmInfo{"70060082"} = "PM4ALLFASTLOOP:MAC-ID2:DataTypeDoesNotCorrespondToItsConfiguredLength";
    $alarmInfo{"70060083"} = "PM4ALLFASTLOOP:MAC-ID2:ConfiguredOutputOffsetAddressOutOfRange";
    $alarmInfo{"70060084"} = "PM4ALLFASTLOOP:MAC-ID2:ConfiguredInputOffsetAddressOutOfRange";
    $alarmInfo{"70060085"} = "PM4ALLFASTLOOP:MAC-ID2:OnePredefinedConnectionTypeIsUnknown";
    $alarmInfo{"70060086"} = "PM4ALLFASTLOOP:MAC-ID2:MultipleConnectionsDefinedInParallel";
    $alarmInfo{"70060087"} = "PM4ALLFASTLOOP:MAC-ID2:ConfiguredEXP_PCKT_RATELessThenPROD_INHIBIT_TIME";
    $alarmInfo{"70060088"} = "PM4ALLFASTLOOP:MAC-ID2:NoDatabaseFoundOnTheSystem";
    $alarmInfo{"70060089"} = "PM4ALLFASTLOOP:MAC-ID2:DatabaseReadingFailure";
    $alarmInfo{"7006008A"} = "PM4ALLFASTLOOP:MAC-ID2:UserWatchdogFailed";
    $alarmInfo{"7006008B"} = "PM4ALLFASTLOOP:MAC-ID2:NoDataAcknowledgeFromUser";
    $alarmInfo{"7006008C"} = "PM4ALLFASTLOOP:MAC-ID2:Unknown";
    $alarmInfo{"7006008D"} = "PM4ALLFASTLOOP:MAC-ID2:Unknown";
    $alarmInfo{"7006008E"} = "PM4ALLFASTLOOP:MAC-ID2:Unknown";
    $alarmInfo{"7006008F"} = "PM4ALLFASTLOOP:MAC-ID2:Unknown";
    $alarmInfo{"70060090"} = "PM4ALLFASTLOOP:MAC-ID3:DeviceGuardingFailed,AfterDeviceWasOperational";
    $alarmInfo{"70060091"} = "PM4ALLFASTLOOP:MAC-ID3:DeviceAccessTimeout";
    $alarmInfo{"70060092"} = "PM4ALLFASTLOOP:MAC-ID3:DeviceRejectsAccessWithUnknownErrorCode";
    $alarmInfo{"70060093"} = "PM4ALLFASTLOOP:MAC-ID3:DeviceResponseInAllocationPhaseWithConnectionError";
    $alarmInfo{"70060094"} = "PM4ALLFASTLOOP:MAC-ID3:ProducedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"70060095"} = "PM4ALLFASTLOOP:MAC-ID3:ConsumedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"70060096"} = "PM4ALLFASTLOOP:MAC-ID3:DeviceServiceResponseTelegramUnknownAndNotHandled";
    $alarmInfo{"70060097"} = "PM4ALLFASTLOOP:MAC-ID3:ConnectionAlreadyInRequest";
    $alarmInfo{"70060098"} = "PM4ALLFASTLOOP:MAC-ID3:NumberOfCAN-messageDataBytesInReadProducedOrConsumedConnectionSizeResponseUnequal4";
    $alarmInfo{"70060099"} = "PM4ALLFASTLOOP:MAC-ID3:PredefinedMaster-slaveConnectionAlreadyExists";
    $alarmInfo{"7006009A"} = "PM4ALLFASTLOOP:MAC-ID3:LengthInPollingDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"7006009B"} = "PM4ALLFASTLOOP:MAC-ID3:SequenceErrorInDevicePollingResponse";
    $alarmInfo{"7006009C"} = "PM4ALLFASTLOOP:MAC-ID3:FragmentErrorInDevicePollingResponse";
    $alarmInfo{"7006009D"} = "PM4ALLFASTLOOP:MAC-ID3:SequenceError2InDevicePollingResponse";
    $alarmInfo{"7006009E"} = "PM4ALLFASTLOOP:MAC-ID3:LengthInBitStrobeDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"7006009F"} = "PM4ALLFASTLOOP:MAC-ID3:SequenceErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"700600A0"} = "PM4ALLFASTLOOP:MAC-ID3:FragmentErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"700600A1"} = "PM4ALLFASTLOOP:MAC-ID3:SequenceError2InDeviceCOSOrCyclicResponse";
    $alarmInfo{"700600A2"} = "PM4ALLFASTLOOP:MAC-ID3:LengthInCOSOrCyclicDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"700600A3"} = "PM4ALLFASTLOOP:MAC-ID3:UCMMGroupNotSupported";
    $alarmInfo{"700600A4"} = "PM4ALLFASTLOOP:MAC-ID3:UnknownHandshakeModeConfigured";
    $alarmInfo{"700600A5"} = "PM4ALLFASTLOOP:MAC-ID3:ConfiguredBaudrateNotSupported";
    $alarmInfo{"700600A6"} = "PM4ALLFASTLOOP:MAC-ID3:DeviceMAC-IDOutOfRange";
    $alarmInfo{"700600A7"} = "PM4ALLFASTLOOP:MAC-ID3:DuplicateMAC-IDDetected";
    $alarmInfo{"700600A8"} = "PM4ALLFASTLOOP:MAC-ID3:DatabaseInTheDeviceHasNoEntriesIncluded";
    $alarmInfo{"700600A9"} = "PM4ALLFASTLOOP:MAC-ID3:DoubleMAC-IDConfiguredInternally";
    $alarmInfo{"700600AA"} = "PM4ALLFASTLOOP:MAC-ID3:SizeOfOneDeviceDataSetInvalid";
    $alarmInfo{"700600AB"} = "PM4ALLFASTLOOP:MAC-ID3:OffsetTableForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"700600AC"} = "PM4ALLFASTLOOP:MAC-ID3:ConfigurationTableLengthForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"700600AD"} = "PM4ALLFASTLOOP:MAC-ID3:OffsetTableDoNotCorrespondToI/OConfigurationTable";
    $alarmInfo{"700600AE"} = "PM4ALLFASTLOOP:MAC-ID3:SizeIndicatorOfParameterDataTableCorrupt";
    $alarmInfo{"700600AF"} = "PM4ALLFASTLOOP:MAC-ID3:NumberOfInputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"700600B0"} = "PM4ALLFASTLOOP:MAC-ID3:NumberOfOutputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"700600B1"} = "PM4ALLFASTLOOP:MAC-ID3:UnknownDataTypeInI/OConfiguration";
    $alarmInfo{"700600B2"} = "PM4ALLFASTLOOP:MAC-ID3:DataTypeDoesNotCorrespondToItsConfiguredLength";
    $alarmInfo{"700600B3"} = "PM4ALLFASTLOOP:MAC-ID3:ConfiguredOutputOffsetAddressOutOfRange";
    $alarmInfo{"700600B4"} = "PM4ALLFASTLOOP:MAC-ID3:ConfiguredInputOffsetAddressOutOfRange";
    $alarmInfo{"700600B5"} = "PM4ALLFASTLOOP:MAC-ID3:OnePredefinedConnectionTypeIsUnknown";
    $alarmInfo{"700600B6"} = "PM4ALLFASTLOOP:MAC-ID3:MultipleConnectionsDefinedInParallel";
    $alarmInfo{"700600B7"} = "PM4ALLFASTLOOP:MAC-ID3:ConfiguredEXP_PCKT_RATELessThenPROD_INHIBIT_TIME";
    $alarmInfo{"700600B8"} = "PM4ALLFASTLOOP:MAC-ID3:NoDatabaseFoundOnTheSystem";
    $alarmInfo{"700600B9"} = "PM4ALLFASTLOOP:MAC-ID3:DatabaseReadingFailure";
    $alarmInfo{"700600BA"} = "PM4ALLFASTLOOP:MAC-ID3:UserWatchdogFailed";
    $alarmInfo{"700600BB"} = "PM4ALLFASTLOOP:MAC-ID3:NoDataAcknowledgeFromUser";
    $alarmInfo{"700600BC"} = "PM4ALLFASTLOOP:MAC-ID3:Unknown";
    $alarmInfo{"700600BD"} = "PM4ALLFASTLOOP:MAC-ID3:Unknown";
    $alarmInfo{"700600BE"} = "PM4ALLFASTLOOP:MAC-ID3:Unknown";
    $alarmInfo{"700600BF"} = "PM4ALLFASTLOOP:MAC-ID3:Unknown";
    $alarmInfo{"700600C0"} = "PM4ALLFASTLOOP:MAC-ID4:DeviceGuardingFailed,AfterDeviceWasOperational";
    $alarmInfo{"700600C1"} = "PM4ALLFASTLOOP:MAC-ID4:DeviceAccessTimeout";
    $alarmInfo{"700600C2"} = "PM4ALLFASTLOOP:MAC-ID4:DeviceRejectsAccessWithUnknownErrorCode";
    $alarmInfo{"700600C3"} = "PM4ALLFASTLOOP:MAC-ID4:DeviceResponseInAllocationPhaseWithConnectionError";
    $alarmInfo{"700600C4"} = "PM4ALLFASTLOOP:MAC-ID4:ProducedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"700600C5"} = "PM4ALLFASTLOOP:MAC-ID4:ConsumedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"700600C6"} = "PM4ALLFASTLOOP:MAC-ID4:DeviceServiceResponseTelegramUnknownAndNotHandled";
    $alarmInfo{"700600C7"} = "PM4ALLFASTLOOP:MAC-ID4:ConnectionAlreadyInRequest";
    $alarmInfo{"700600C8"} = "PM4ALLFASTLOOP:MAC-ID4:NumberOfCAN-messageDataBytesInReadProducedOrConsumedConnectionSizeResponseUnequal4";
    $alarmInfo{"700600C9"} = "PM4ALLFASTLOOP:MAC-ID4:PredefinedMaster-slaveConnectionAlreadyExists";
    $alarmInfo{"700600CA"} = "PM4ALLFASTLOOP:MAC-ID4:LengthInPollingDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"700600CB"} = "PM4ALLFASTLOOP:MAC-ID4:SequenceErrorInDevicePollingResponse";
    $alarmInfo{"700600CC"} = "PM4ALLFASTLOOP:MAC-ID4:FragmentErrorInDevicePollingResponse";
    $alarmInfo{"700600CD"} = "PM4ALLFASTLOOP:MAC-ID4:SequenceError2InDevicePollingResponse";
    $alarmInfo{"700600CE"} = "PM4ALLFASTLOOP:MAC-ID4:LengthInBitStrobeDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"700600CF"} = "PM4ALLFASTLOOP:MAC-ID4:SequenceErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"700600D0"} = "PM4ALLFASTLOOP:MAC-ID4:FragmentErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"700600D1"} = "PM4ALLFASTLOOP:MAC-ID4:SequenceError2InDeviceCOSOrCyclicResponse";
    $alarmInfo{"700600D2"} = "PM4ALLFASTLOOP:MAC-ID4:LengthInCOSOrCyclicDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"700600D3"} = "PM4ALLFASTLOOP:MAC-ID4:UCMMGroupNotSupported";
    $alarmInfo{"700600D4"} = "PM4ALLFASTLOOP:MAC-ID4:UnknownHandshakeModeConfigured";
    $alarmInfo{"700600D5"} = "PM4ALLFASTLOOP:MAC-ID4:ConfiguredBaudrateNotSupported";
    $alarmInfo{"700600D6"} = "PM4ALLFASTLOOP:MAC-ID4:DeviceMAC-IDOutOfRange";
    $alarmInfo{"700600D7"} = "PM4ALLFASTLOOP:MAC-ID4:DuplicateMAC-IDDetected";
    $alarmInfo{"700600D8"} = "PM4ALLFASTLOOP:MAC-ID4:DatabaseInTheDeviceHasNoEntriesIncluded";
    $alarmInfo{"700600D9"} = "PM4ALLFASTLOOP:MAC-ID4:DoubleMAC-IDConfiguredInternally";
    $alarmInfo{"700600DA"} = "PM4ALLFASTLOOP:MAC-ID4:SizeOfOneDeviceDataSetInvalid";
    $alarmInfo{"700600DB"} = "PM4ALLFASTLOOP:MAC-ID4:OffsetTableForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"700600DC"} = "PM4ALLFASTLOOP:MAC-ID4:ConfigurationTableLengthForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"700600DD"} = "PM4ALLFASTLOOP:MAC-ID4:OffsetTableDoNotCorrespondToI/OConfigurationTable";
    $alarmInfo{"700600DE"} = "PM4ALLFASTLOOP:MAC-ID4:SizeIndicatorOfParameterDataTableCorrupt";
    $alarmInfo{"700600DF"} = "PM4ALLFASTLOOP:MAC-ID4:NumberOfInputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"700600E0"} = "PM4ALLFASTLOOP:MAC-ID4:NumberOfOutputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"700600E1"} = "PM4ALLFASTLOOP:MAC-ID4:UnknownDataTypeInI/OConfiguration";
    $alarmInfo{"700600E2"} = "PM4ALLFASTLOOP:MAC-ID4:DataTypeDoesNotCorrespondToItsConfiguredLength";
    $alarmInfo{"700600E3"} = "PM4ALLFASTLOOP:MAC-ID4:ConfiguredOutputOffsetAddressOutOfRange";
    $alarmInfo{"700600E4"} = "PM4ALLFASTLOOP:MAC-ID4:ConfiguredInputOffsetAddressOutOfRange";
    $alarmInfo{"700600E5"} = "PM4ALLFASTLOOP:MAC-ID4:OnePredefinedConnectionTypeIsUnknown";
    $alarmInfo{"700600E6"} = "PM4ALLFASTLOOP:MAC-ID4:MultipleConnectionsDefinedInParallel";
    $alarmInfo{"700600E7"} = "PM4ALLFASTLOOP:MAC-ID4:ConfiguredEXP_PCKT_RATELessThenPROD_INHIBIT_TIME";
    $alarmInfo{"700600E8"} = "PM4ALLFASTLOOP:MAC-ID4:NoDatabaseFoundOnTheSystem";
    $alarmInfo{"700600E9"} = "PM4ALLFASTLOOP:MAC-ID4:DatabaseReadingFailure";
    $alarmInfo{"700600EA"} = "PM4ALLFASTLOOP:MAC-ID4:UserWatchdogFailed";
    $alarmInfo{"700600EB"} = "PM4ALLFASTLOOP:MAC-ID4:NoDataAcknowledgeFromUser";
    $alarmInfo{"700600EC"} = "PM4ALLFASTLOOP:MAC-ID4:Unknown";
    $alarmInfo{"700600ED"} = "PM4ALLFASTLOOP:MAC-ID4:Unknown";
    $alarmInfo{"700600EE"} = "PM4ALLFASTLOOP:MAC-ID4:Unknown";
    $alarmInfo{"700600EF"} = "PM4ALLFASTLOOP:MAC-ID4:Unknown";
    $alarmInfo{"700600F0"} = "PM4ALLFASTLOOP:MAC-ID5:DeviceGuardingFailed,AfterDeviceWasOperational";
    $alarmInfo{"700600F1"} = "PM4ALLFASTLOOP:MAC-ID5:DeviceAccessTimeout";
    $alarmInfo{"700600F2"} = "PM4ALLFASTLOOP:MAC-ID5:DeviceRejectsAccessWithUnknownErrorCode";
    $alarmInfo{"700600F3"} = "PM4ALLFASTLOOP:MAC-ID5:DeviceResponseInAllocationPhaseWithConnectionError";
    $alarmInfo{"700600F4"} = "PM4ALLFASTLOOP:MAC-ID5:ProducedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"700600F5"} = "PM4ALLFASTLOOP:MAC-ID5:ConsumedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"700600F6"} = "PM4ALLFASTLOOP:MAC-ID5:DeviceServiceResponseTelegramUnknownAndNotHandled";
    $alarmInfo{"700600F7"} = "PM4ALLFASTLOOP:MAC-ID5:ConnectionAlreadyInRequest";
    $alarmInfo{"700600F8"} = "PM4ALLFASTLOOP:MAC-ID5:NumberOfCAN-messageDataBytesInReadProducedOrConsumedConnectionSizeResponseUnequal4";
    $alarmInfo{"700600F9"} = "PM4ALLFASTLOOP:MAC-ID5:PredefinedMaster-slaveConnectionAlreadyExists";
    $alarmInfo{"700600FA"} = "PM4ALLFASTLOOP:MAC-ID5:LengthInPollingDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"700600FB"} = "PM4ALLFASTLOOP:MAC-ID5:SequenceErrorInDevicePollingResponse";
    $alarmInfo{"700600FC"} = "PM4ALLFASTLOOP:MAC-ID5:FragmentErrorInDevicePollingResponse";
    $alarmInfo{"700600FD"} = "PM4ALLFASTLOOP:MAC-ID5:SequenceError2InDevicePollingResponse";
    $alarmInfo{"700600FE"} = "PM4ALLFASTLOOP:MAC-ID5:LengthInBitStrobeDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"700600FF"} = "PM4ALLFASTLOOP:MAC-ID5:SequenceErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"70060100"} = "PM4ALLFASTLOOP:MAC-ID5:FragmentErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"70060101"} = "PM4ALLFASTLOOP:MAC-ID5:SequenceError2InDeviceCOSOrCyclicResponse";
    $alarmInfo{"70060102"} = "PM4ALLFASTLOOP:MAC-ID5:LengthInCOSOrCyclicDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"70060103"} = "PM4ALLFASTLOOP:MAC-ID5:UCMMGroupNotSupported";
    $alarmInfo{"70060104"} = "PM4ALLFASTLOOP:MAC-ID5:UnknownHandshakeModeConfigured";
    $alarmInfo{"70060105"} = "PM4ALLFASTLOOP:MAC-ID5:ConfiguredBaudrateNotSupported";
    $alarmInfo{"70060106"} = "PM4ALLFASTLOOP:MAC-ID5:DeviceMAC-IDOutOfRange";
    $alarmInfo{"70060107"} = "PM4ALLFASTLOOP:MAC-ID5:DuplicateMAC-IDDetected";
    $alarmInfo{"70060108"} = "PM4ALLFASTLOOP:MAC-ID5:DatabaseInTheDeviceHasNoEntriesIncluded";
    $alarmInfo{"70060109"} = "PM4ALLFASTLOOP:MAC-ID5:DoubleMAC-IDConfiguredInternally";
    $alarmInfo{"7006010A"} = "PM4ALLFASTLOOP:MAC-ID5:SizeOfOneDeviceDataSetInvalid";
    $alarmInfo{"7006010B"} = "PM4ALLFASTLOOP:MAC-ID5:OffsetTableForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"7006010C"} = "PM4ALLFASTLOOP:MAC-ID5:ConfigurationTableLengthForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"7006010D"} = "PM4ALLFASTLOOP:MAC-ID5:OffsetTableDoNotCorrespondToI/OConfigurationTable";
    $alarmInfo{"7006010E"} = "PM4ALLFASTLOOP:MAC-ID5:SizeIndicatorOfParameterDataTableCorrupt";
    $alarmInfo{"7006010F"} = "PM4ALLFASTLOOP:MAC-ID5:NumberOfInputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"70060110"} = "PM4ALLFASTLOOP:MAC-ID5:NumberOfOutputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"70060111"} = "PM4ALLFASTLOOP:MAC-ID5:UnknownDataTypeInI/OConfiguration";
    $alarmInfo{"70060112"} = "PM4ALLFASTLOOP:MAC-ID5:DataTypeDoesNotCorrespondToItsConfiguredLength";
    $alarmInfo{"70060113"} = "PM4ALLFASTLOOP:MAC-ID5:ConfiguredOutputOffsetAddressOutOfRange";
    $alarmInfo{"70060114"} = "PM4ALLFASTLOOP:MAC-ID5:ConfiguredInputOffsetAddressOutOfRange";
    $alarmInfo{"70060115"} = "PM4ALLFASTLOOP:MAC-ID5:OnePredefinedConnectionTypeIsUnknown";
    $alarmInfo{"70060116"} = "PM4ALLFASTLOOP:MAC-ID5:MultipleConnectionsDefinedInParallel";
    $alarmInfo{"70060117"} = "PM4ALLFASTLOOP:MAC-ID5:ConfiguredEXP_PCKT_RATELessThenPROD_INHIBIT_TIME";
    $alarmInfo{"70060118"} = "PM4ALLFASTLOOP:MAC-ID5:NoDatabaseFoundOnTheSystem";
    $alarmInfo{"70060119"} = "PM4ALLFASTLOOP:MAC-ID5:DatabaseReadingFailure";
    $alarmInfo{"7006011A"} = "PM4ALLFASTLOOP:MAC-ID5:UserWatchdogFailed";
    $alarmInfo{"7006011B"} = "PM4ALLFASTLOOP:MAC-ID5:NoDataAcknowledgeFromUser";
    $alarmInfo{"7006011C"} = "PM4ALLFASTLOOP:MAC-ID5:Unknown";
    $alarmInfo{"7006011D"} = "PM4ALLFASTLOOP:MAC-ID5:Unknown";
    $alarmInfo{"7006011E"} = "PM4ALLFASTLOOP:MAC-ID5:Unknown";
    $alarmInfo{"7006011F"} = "PM4ALLFASTLOOP:MAC-ID5:Unknown";
    $alarmInfo{"70060120"} = "PM4ALLFASTLOOP:MAC-ID6:DeviceGuardingFailed,AfterDeviceWasOperational";
    $alarmInfo{"70060121"} = "PM4ALLFASTLOOP:MAC-ID6:DeviceAccessTimeout";
    $alarmInfo{"70060122"} = "PM4ALLFASTLOOP:MAC-ID6:DeviceRejectsAccessWithUnknownErrorCode";
    $alarmInfo{"70060123"} = "PM4ALLFASTLOOP:MAC-ID6:DeviceResponseInAllocationPhaseWithConnectionError";
    $alarmInfo{"70060124"} = "PM4ALLFASTLOOP:MAC-ID6:ProducedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"70060125"} = "PM4ALLFASTLOOP:MAC-ID6:ConsumedConnectionIsDifferentToTheConfigured";
    $alarmInfo{"70060126"} = "PM4ALLFASTLOOP:MAC-ID6:DeviceServiceResponseTelegramUnknownAndNotHandled";
    $alarmInfo{"70060127"} = "PM4ALLFASTLOOP:MAC-ID6:ConnectionAlreadyInRequest";
    $alarmInfo{"70060128"} = "PM4ALLFASTLOOP:MAC-ID6:NumberOfCAN-messageDataBytesInReadProducedOrConsumedConnectionSizeResponseUnequal4";
    $alarmInfo{"70060129"} = "PM4ALLFASTLOOP:MAC-ID6:PredefinedMaster-slaveConnectionAlreadyExists";
    $alarmInfo{"7006012A"} = "PM4ALLFASTLOOP:MAC-ID6:LengthInPollingDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"7006012B"} = "PM4ALLFASTLOOP:MAC-ID6:SequenceErrorInDevicePollingResponse";
    $alarmInfo{"7006012C"} = "PM4ALLFASTLOOP:MAC-ID6:FragmentErrorInDevicePollingResponse";
    $alarmInfo{"7006012D"} = "PM4ALLFASTLOOP:MAC-ID6:SequenceError2InDevicePollingResponse";
    $alarmInfo{"7006012E"} = "PM4ALLFASTLOOP:MAC-ID6:LengthInBitStrobeDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"7006012F"} = "PM4ALLFASTLOOP:MAC-ID6:SequenceErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"70060130"} = "PM4ALLFASTLOOP:MAC-ID6:FragmentErrorInDeviceCOSOrCyclicResponse";
    $alarmInfo{"70060131"} = "PM4ALLFASTLOOP:MAC-ID6:SequenceError2InDeviceCOSOrCyclicResponse";
    $alarmInfo{"70060132"} = "PM4ALLFASTLOOP:MAC-ID6:LengthInCOSOrCyclicDeviceResponseUnequalProducedConnectionSize";
    $alarmInfo{"70060133"} = "PM4ALLFASTLOOP:MAC-ID6:UCMMGroupNotSupported";
    $alarmInfo{"70060134"} = "PM4ALLFASTLOOP:MAC-ID6:UnknownHandshakeModeConfigured";
    $alarmInfo{"70060135"} = "PM4ALLFASTLOOP:MAC-ID6:ConfiguredBaudrateNotSupported";
    $alarmInfo{"70060136"} = "PM4ALLFASTLOOP:MAC-ID6:DeviceMAC-IDOutOfRange";
    $alarmInfo{"70060137"} = "PM4ALLFASTLOOP:MAC-ID6:DuplicateMAC-IDDetected";
    $alarmInfo{"70060138"} = "PM4ALLFASTLOOP:MAC-ID6:DatabaseInTheDeviceHasNoEntriesIncluded";
    $alarmInfo{"70060139"} = "PM4ALLFASTLOOP:MAC-ID6:DoubleMAC-IDConfiguredInternally";
    $alarmInfo{"7006013A"} = "PM4ALLFASTLOOP:MAC-ID6:SizeOfOneDeviceDataSetInvalid";
    $alarmInfo{"7006013B"} = "PM4ALLFASTLOOP:MAC-ID6:OffsetTableForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"7006013C"} = "PM4ALLFASTLOOP:MAC-ID6:ConfigurationTableLengthForPredefinedMaster-slaveConnectionInvalid";
    $alarmInfo{"7006013D"} = "PM4ALLFASTLOOP:MAC-ID6:OffsetTableDoNotCorrespondToI/OConfigurationTable";
    $alarmInfo{"7006013E"} = "PM4ALLFASTLOOP:MAC-ID6:SizeIndicatorOfParameterDataTableCorrupt";
    $alarmInfo{"7006013F"} = "PM4ALLFASTLOOP:MAC-ID6:NumberOfInputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"70060140"} = "PM4ALLFASTLOOP:MAC-ID6:NumberOfOutputsInAddTabNotEqualI/OConfiguration";
    $alarmInfo{"70060141"} = "PM4ALLFASTLOOP:MAC-ID6:UnknownDataTypeInI/OConfiguration";
    $alarmInfo{"70060142"} = "PM4ALLFASTLOOP:MAC-ID6:DataTypeDoesNotCorrespondToItsConfiguredLength";
    $alarmInfo{"70060143"} = "PM4ALLFASTLOOP:MAC-ID6:ConfiguredOutputOffsetAddressOutOfRange";
    $alarmInfo{"70060144"} = "PM4ALLFASTLOOP:MAC-ID6:ConfiguredInputOffsetAddressOutOfRange";
    $alarmInfo{"70060145"} = "PM4ALLFASTLOOP:MAC-ID6:OnePredefinedConnectionTypeIsUnknown";
    $alarmInfo{"70060146"} = "PM4ALLFASTLOOP:MAC-ID6:MultipleConnectionsDefinedInParallel";
    $alarmInfo{"70060147"} = "PM4ALLFASTLOOP:MAC-ID6:ConfiguredEXP_PCKT_RATELessThenPROD_INHIBIT_TIME";
    $alarmInfo{"70060148"} = "PM4ALLFASTLOOP:MAC-ID6:NoDatabaseFoundOnTheSystem";
    $alarmInfo{"70060149"} = "PM4ALLFASTLOOP:MAC-ID6:DatabaseReadingFailure";
    $alarmInfo{"7006014A"} = "PM4ALLFASTLOOP:MAC-ID6:UserWatchdogFailed";
    $alarmInfo{"7006014B"} = "PM4ALLFASTLOOP:MAC-ID6:NoDataAcknowledgeFromUser";
    $alarmInfo{"7006014C"} = "PM4ALLFASTLOOP:MAC-ID6:Unknown";
    $alarmInfo{"7006014D"} = "PM4ALLFASTLOOP:MAC-ID6:Unknown";
    $alarmInfo{"7006014E"} = "PM4ALLFASTLOOP:MAC-ID6:Unknown";
    $alarmInfo{"7006014F"} = "PM4ALLFASTLOOP:MAC-ID6:Unknown";
    $alarmInfo{"70060150"} = "PM4ALLFASTLOOP:CIF/DRIVER:BoardNotInitialized";
    $alarmInfo{"70060151"} = "PM4ALLFASTLOOP:CIF/DRIVER:ErrorInInternalInitState";
    $alarmInfo{"70060152"} = "PM4ALLFASTLOOP:CIF/DRIVER:ErrorInInternalReadState";
    $alarmInfo{"70060153"} = "PM4ALLFASTLOOP:CIF/DRIVER:CommandOnThisChannelIsActive";
    $alarmInfo{"70060154"} = "PM4ALLFASTLOOP:CIF/DRIVER:UnknownParameterInFunctionOccurred";
    $alarmInfo{"70060155"} = "PM4ALLFASTLOOP:CIF/DRIVER:VersionIsIncompatibleWithDLL";
    $alarmInfo{"70060156"} = "PM4ALLFASTLOOP:CIF/DRIVER:ErrorDuringPCISetConfigMode";
    $alarmInfo{"70060157"} = "PM4ALLFASTLOOP:CIF/DRIVER:CouldNotReadPCIDualPortMemoryLength";
    $alarmInfo{"70060158"} = "PM4ALLFASTLOOP:CIF/DRIVER:ErrorDuringPCISetRunMode";
    $alarmInfo{"70060159"} = "PM4ALLFASTLOOP:CIF/DRIVER:DualPortRamNotAccessibleBoardNotFound)";
    $alarmInfo{"7006015A"} = "PM4ALLFASTLOOP:CIF/DRIVER:NotReadyReady";
    $alarmInfo{"7006015B"} = "PM4ALLFASTLOOP:CIF/DRIVER:NotRunningRunning";
    $alarmInfo{"7006015C"} = "PM4ALLFASTLOOP:CIF/DRIVER:WatchdogTestFailed";
    $alarmInfo{"7006015D"} = "PM4ALLFASTLOOP:CIF/DRIVER:SignalsWrongOSVersion";
    $alarmInfo{"7006015E"} = "PM4ALLFASTLOOP:CIF/DRIVER:ErrorInDualPort";
    $alarmInfo{"7006015F"} = "PM4ALLFASTLOOP:CIF/DRIVER:SendMailboxIsFull";
    $alarmInfo{"70060160"} = "PM4ALLFASTLOOP:CIF/DRIVER:PutMessageTimeout";
    $alarmInfo{"70060161"} = "PM4ALLFASTLOOP:CIF/DRIVER:GetMessageTimeout";
    $alarmInfo{"70060162"} = "PM4ALLFASTLOOP:CIF/DRIVER:NoMessageAvailable";
    $alarmInfo{"70060163"} = "PM4ALLFASTLOOP:CIF/DRIVER:RESETCommandTimeout";
    $alarmInfo{"70060164"} = "PM4ALLFASTLOOP:CIF/DRIVER:COM-flagsNotSet";
    $alarmInfo{"70060165"} = "PM4ALLFASTLOOP:CIF/DRIVER:I/ODataExchangeFailed";
    $alarmInfo{"70060166"} = "PM4ALLFASTLOOP:CIF/DRIVER:I/ODataExchangeTimeout";
    $alarmInfo{"70060167"} = "PM4ALLFASTLOOP:CIF/DRIVER:I/ODataModeUnknown";
    $alarmInfo{"70060168"} = "PM4ALLFASTLOOP:CIF/DRIVER:FunctionCallFailed";
    $alarmInfo{"70060169"} = "PM4ALLFASTLOOP:CIF/DRIVER:DualPortMemorySizeDiffersFromConfiguration";
    $alarmInfo{"7006016A"} = "PM4ALLFASTLOOP:CIF/DRIVER:StateModeUnknown";
    $alarmInfo{"7006016B"} = "PM4ALLFASTLOOP:CIF/DRIVER:HardwarePortIsUsed";
    $alarmInfo{"7006016C"} = "PM4ALLFASTLOOP:CIF/USER:DriverNotOpenedDeviceDriverNotLoaded)";
    $alarmInfo{"7006016D"} = "PM4ALLFASTLOOP:CIF/USER:CannotConnectWithDevice";
    $alarmInfo{"7006016E"} = "PM4ALLFASTLOOP:CIF/USER:BoardNotInitializedDevInitBoardNotCalled)";
    $alarmInfo{"7006016F"} = "PM4ALLFASTLOOP:CIF/USER:IOCTRLFunctionFailed";
    $alarmInfo{"70060170"} = "PM4ALLFASTLOOP:CIF/USER:ParameterDeviceNumberInvalid";
    $alarmInfo{"70060171"} = "PM4ALLFASTLOOP:CIF/USER:ParameterInfoAreaUnknown";
    $alarmInfo{"70060172"} = "PM4ALLFASTLOOP:CIF/USER:ParameterNumberInvalid";
    $alarmInfo{"70060173"} = "PM4ALLFASTLOOP:CIF/USER:ParameterModeInvalid";
    $alarmInfo{"70060174"} = "PM4ALLFASTLOOP:CIF/USER:NULLPointerAssignment";
    $alarmInfo{"70060175"} = "PM4ALLFASTLOOP:CIF/USER:MessageBufferTooShort";
    $alarmInfo{"70060176"} = "PM4ALLFASTLOOP:CIF/USER:ParameterSizeInvalid";
    $alarmInfo{"70060177"} = "PM4ALLFASTLOOP:CIF/USER:ParameterSizeWithZeroLength";
    $alarmInfo{"70060178"} = "PM4ALLFASTLOOP:CIF/USER:ParameterSizeTooLong";
    $alarmInfo{"70060179"} = "PM4ALLFASTLOOP:CIF/USER:DeviceAddressNullPointer";
    $alarmInfo{"7006017A"} = "PM4ALLFASTLOOP:CIF/USER:PointerToBufferIsANullPointer";
    $alarmInfo{"7006017B"} = "PM4ALLFASTLOOP:CIF/USER:ParameterSendSizeTooLong";
    $alarmInfo{"7006017C"} = "PM4ALLFASTLOOP:CIF/USER:ParameterReceiveSizeTooLong";
    $alarmInfo{"7006017D"} = "PM4ALLFASTLOOP:CIF/USER:PointerToSendBufferIsANullPointer";
    $alarmInfo{"7006017E"} = "PM4ALLFASTLOOP:CIF/USER:PointerToReceiveBufferIsANullPointer";
    $alarmInfo{"7006017F"} = "PM4ALLFASTLOOP:CIF/DMA:MemoryAllocationError";
    $alarmInfo{"70060180"} = "PM4ALLFASTLOOP:CIF/DMA:ReadI/OTimeout";
    $alarmInfo{"70060181"} = "PM4ALLFASTLOOP:CIF/DMA:WriteI/OTimeout";
    $alarmInfo{"70060182"} = "PM4ALLFASTLOOP:CIF/DMA:PCITransferTimeout";
    $alarmInfo{"70060183"} = "PM4ALLFASTLOOP:CIF/DMA:DownloadTimeout";
    $alarmInfo{"70060184"} = "PM4ALLFASTLOOP:CIF/DMA:DatabaseDownloadFailed";
    $alarmInfo{"70060185"} = "PM4ALLFASTLOOP:CIF/DMA:FirmwareDownloadFailed";
    $alarmInfo{"70060186"} = "PM4ALLFASTLOOP:CIF/DMA:ClearDatabaseOnTheDeviceFailed";
    $alarmInfo{"70060187"} = "PM4ALLFASTLOOP:CIF/USER:VirtualMemoryNotAvailable";
    $alarmInfo{"70060188"} = "PM4ALLFASTLOOP:CIF/USER:UnmapVirtualMemoryFailed";
    $alarmInfo{"70060189"} = "PM4ALLFASTLOOP:CIF/DRIVER:GeneralError";
    $alarmInfo{"7006018A"} = "PM4ALLFASTLOOP:CIF/DRIVER:GeneralDMAError";
    $alarmInfo{"7006018B"} = "PM4ALLFASTLOOP:CIF/DRIVER:BatteryError";
    $alarmInfo{"7006018C"} = "PM4ALLFASTLOOP:CIF/DRIVER:PowerFailedError";
    $alarmInfo{"7006018D"} = "PM4ALLFASTLOOP:CIF/USER:DriverUnknown";
    $alarmInfo{"7006018E"} = "PM4ALLFASTLOOP:CIF/USER:DeviceNameInvalid";
    $alarmInfo{"7006018F"} = "PM4ALLFASTLOOP:CIF/USER:DeviceNameUnknown";
    $alarmInfo{"70060190"} = "PM4ALLFASTLOOP:CIF/USER:DeviceFunctionNotImplemented";
    $alarmInfo{"70060191"} = "PM4ALLFASTLOOP:CIF/USER:FileNotOpened";
    $alarmInfo{"70060192"} = "PM4ALLFASTLOOP:CIF/USER:FileSizeZero";
    $alarmInfo{"70060193"} = "PM4ALLFASTLOOP:CIF/USER:NotEnoughMemoryToLoadFile";
    $alarmInfo{"70060194"} = "PM4ALLFASTLOOP:CIF/USER:FileReadFailed";
    $alarmInfo{"70060195"} = "PM4ALLFASTLOOP:CIF/USER:FileTypeInvalid";
    $alarmInfo{"70060196"} = "PM4ALLFASTLOOP:CIF/USER:FileNameNotValid";
    $alarmInfo{"70060197"} = "PM4ALLFASTLOOP:CIF/USER:FirmwareFileNotOpened";
    $alarmInfo{"70060198"} = "PM4ALLFASTLOOP:CIF/USER:FirmwareFileSizeZero";
    $alarmInfo{"70060199"} = "PM4ALLFASTLOOP:CIF/USER:NotEnoughMemoryToLoadFirmwareFile";
    $alarmInfo{"7006019A"} = "PM4ALLFASTLOOP:CIF/USER:FirmwareFileReadFailed";
    $alarmInfo{"7006019B"} = "PM4ALLFASTLOOP:CIF/USER:FirmwareFileTypeInvalid";
    $alarmInfo{"7006019C"} = "PM4ALLFASTLOOP:CIF/USER:FirmwareFileNameNotValid";
    $alarmInfo{"7006019D"} = "PM4ALLFASTLOOP:CIF/USER:FirmwareFileDownloadError";
    $alarmInfo{"7006019E"} = "PM4ALLFASTLOOP:CIF/USER:FirmwareFileNotFoundInTheInternalTable";
    $alarmInfo{"7006019F"} = "PM4ALLFASTLOOP:CIF/USER:FirmwareFileBOOTLOADERActive";
    $alarmInfo{"700601A0"} = "PM4ALLFASTLOOP:CIF/USER:FirmwareFileNotFilePath";
    $alarmInfo{"700601A1"} = "PM4ALLFASTLOOP:CIF/USER:ConfigurationFileNotOpened";
    $alarmInfo{"700601A2"} = "PM4ALLFASTLOOP:CIF/USER:ConfigurationFileSizeZero";
    $alarmInfo{"700601A3"} = "PM4ALLFASTLOOP:CIF/USER:NotEnoughMemoryToLoadConfigurationFile";
    $alarmInfo{"700601A4"} = "PM4ALLFASTLOOP:CIF/USER:ConfigurationFileReadFailed";
    $alarmInfo{"700601A5"} = "PM4ALLFASTLOOP:CIF/USER:ConfigurationFileTypeInvalid";
    $alarmInfo{"700601A6"} = "PM4ALLFASTLOOP:CIF/USER:ConfigurationFileNameNotValid";
    $alarmInfo{"700601A7"} = "PM4ALLFASTLOOP:CIF/USER:ConfigurationFileDownloadError";
    $alarmInfo{"700601A8"} = "PM4ALLFASTLOOP:CIF/USER:NoFlashSegmentInTheConfigurationFile";
    $alarmInfo{"700601A9"} = "PM4ALLFASTLOOP:CIF/USER:ConfigurationFileDiffersFromDatabase";
    $alarmInfo{"700601AA"} = "PM4ALLFASTLOOP:CIF/USER:DatabaseSizeZero";
    $alarmInfo{"700601AB"} = "PM4ALLFASTLOOP:CIF/USER:NotEnoughMemoryToUploadDatabase";
    $alarmInfo{"700601AC"} = "PM4ALLFASTLOOP:CIF/USER:DatabaseReadFailed";
    $alarmInfo{"700601AD"} = "PM4ALLFASTLOOP:CIF/USER:DatabaseSegmentUnknown";
    $alarmInfo{"700601AE"} = "PM4ALLFASTLOOP:CIF/CONFIG:VersionOfTheDescriptTableInvalid";
    $alarmInfo{"700601AF"} = "PM4ALLFASTLOOP:CIF/CONFIG:InputOffsetIsInvalid";
    $alarmInfo{"700601B0"} = "PM4ALLFASTLOOP:CIF/CONFIG:InputSizeIs0";
    $alarmInfo{"700601B1"} = "PM4ALLFASTLOOP:CIF/CONFIG:InputSizeDoesNotMatchConfiguration";
    $alarmInfo{"700601B2"} = "PM4ALLFASTLOOP:CIF/CONFIG:OutputOffsetIsInvalid";
    $alarmInfo{"700601B3"} = "PM4ALLFASTLOOP:CIF/CONFIG:OutputSizeIs0";
    $alarmInfo{"700601B4"} = "PM4ALLFASTLOOP:CIF/CONFIG:OutputSizeDoesNotMatchConfiguration";
    $alarmInfo{"700601B5"} = "PM4ALLFASTLOOP:CIF/CONFIG:StationNotConfigured";
    $alarmInfo{"700601B6"} = "PM4ALLFASTLOOP:CIF/CONFIG:CannotGetTheStationConfiguration";
    $alarmInfo{"700601B7"} = "PM4ALLFASTLOOP:CIF/CONFIG:ModuleDefinitionIsMissing";
    $alarmInfo{"700601B8"} = "PM4ALLFASTLOOP:CIF/CONFIG:EmptySlotMismatch";
    $alarmInfo{"700601B9"} = "PM4ALLFASTLOOP:CIF/CONFIG:InputOffsetMismatch";
    $alarmInfo{"700601BA"} = "PM4ALLFASTLOOP:CIF/CONFIG:OutputOffsetMismatch";
    $alarmInfo{"700601BB"} = "PM4ALLFASTLOOP:CIF/CONFIG:DataTypeMismatch";
    $alarmInfo{"700601BC"} = "PM4ALLFASTLOOP:CIF/CONFIG:ModuleDefinitionIsMissing,NoSlot/Idx)";
    $alarmInfo{"700601BD"} = "PM4ALLFASTLOOP:CIF:Unknown";
    $alarmInfo{"700601BE"} = "PM4ALLFASTLOOP:Unknown";
    $alarmInfo{"700601BF"} = "PM4ALLFASTLOOP:Unknown";
    $alarmInfo{"700601C0"} = "PM4ALLDeviceNetMacID0CommunicationLost";
    $alarmInfo{"700601C1"} = "PM4ALLDeviceNetMacID1CommunicationLost";
    $alarmInfo{"700601C2"} = "PM4ALLDeviceNetMacID2CommunicationLost";
    $alarmInfo{"700601C3"} = "PM4ALLDeviceNetMacID3CommunicationLost";
    $alarmInfo{"700601C4"} = "PM4ALLDeviceNetMacID4CommunicationLost";
    $alarmInfo{"700601C5"} = "PM4ALLDeviceNetMacID5CommunicationLost";
    $alarmInfo{"700601C6"} = "PM4ALLDeviceNetMacID6CommunicationLost";
    $alarmInfo{"700601C7"} = "PM4ALLDeviceNetMacID7CommunicationLost";
    $alarmInfo{"700601C8"} = "PM4ALLDeviceNetMacID8CommunicationLost";
    $alarmInfo{"700601C9"} = "PM4ALLDeviceNetMacID9CommunicationLost";
    $alarmInfo{"700601CA"} = "PM4ALLDeviceNetMacID10CommunicationLost";
    $alarmInfo{"700601CB"} = "PM4ALLDeviceNetMacID11CommunicationLost";
    $alarmInfo{"700601CC"} = "PM4ALLDeviceNetMacID12CommunicationLost";
    $alarmInfo{"700601CD"} = "PM4ALLDeviceNetMacID13CommunicationLost";
    $alarmInfo{"700601CE"} = "PM4ALLDeviceNetMacID14CommunicationLost";
    $alarmInfo{"700601CF"} = "PM4ALLDeviceNetMacID15CommunicationLost";
    $alarmInfo{"700601D0"} = "PM4ALLDeviceNetMacID16CommunicationLost";
    $alarmInfo{"700601D1"} = "PM4ALLDeviceNetMacID17CommunicationLost";
    $alarmInfo{"700601D2"} = "PM4ALLDeviceNetMacID18CommunicationLost";
    $alarmInfo{"700601D3"} = "PM4ALLDeviceNetMacID19CommunicationLost";
    $alarmInfo{"700601D4"} = "PM4ALLDeviceNetMacID20CommunicationLost";
    $alarmInfo{"700601D5"} = "PM4ALLDeviceNetMacID21CommunicationLost";
    $alarmInfo{"700601D6"} = "PM4ALLDeviceNetMacID22CommunicationLost";
    $alarmInfo{"700601D7"} = "PM4ALLDeviceNetMacID23CommunicationLost";
    $alarmInfo{"700601D8"} = "PM4ALLDeviceNetMacID24CommunicationLost";
    $alarmInfo{"700601D9"} = "PM4ALLDeviceNetMacID25CommunicationLost";
    $alarmInfo{"700601DA"} = "PM4ALLDeviceNetMacID26CommunicationLost";
    $alarmInfo{"700601DB"} = "PM4ALLDeviceNetMacID27CommunicationLost";
    $alarmInfo{"700601DC"} = "PM4ALLDeviceNetMacID28CommunicationLost";
    $alarmInfo{"700601DD"} = "PM4ALLDeviceNetMacID29CommunicationLost";
    $alarmInfo{"700601DE"} = "PM4ALLDeviceNetMacID30CommunicationLost";
    $alarmInfo{"700601DF"} = "PM4ALLDeviceNetMacID31CommunicationLost";
    $alarmInfo{"700601E0"} = "PM4ALLDeviceNetMacID32CommunicationLost";
    $alarmInfo{"700601E1"} = "PM4ALLDeviceNetMacID33CommunicationLost";
    $alarmInfo{"700601E2"} = "PM4ALLDeviceNetMacID34CommunicationLost";
    $alarmInfo{"700601E3"} = "PM4ALLDeviceNetMacID35CommunicationLost";
    $alarmInfo{"700601E4"} = "PM4ALLDeviceNetMacID36CommunicationLost";
    $alarmInfo{"700601E5"} = "PM4ALLDeviceNetMacID37CommunicationLost";
    $alarmInfo{"700601E6"} = "PM4ALLDeviceNetMacID38CommunicationLost";
    $alarmInfo{"700601E7"} = "PM4ALLDeviceNetMacID39CommunicationLost";
    $alarmInfo{"700601E8"} = "PM4ALLDeviceNetMacID40CommunicationLost";
    $alarmInfo{"700601E9"} = "PM4ALLDeviceNetMacID41CommunicationLost";
    $alarmInfo{"700601EA"} = "PM4ALLDeviceNetMacID42CommunicationLost";
    $alarmInfo{"700601EB"} = "PM4ALLDeviceNetMacID43CommunicationLost";
    $alarmInfo{"700601EC"} = "PM4ALLDeviceNetMacID44CommunicationLost";
    $alarmInfo{"700601ED"} = "PM4ALLDeviceNetMacID45CommunicationLost";
    $alarmInfo{"700601EE"} = "PM4ALLDeviceNetMacID46CommunicationLost";
    $alarmInfo{"700601EF"} = "PM4ALLDeviceNetMacID47CommunicationLost";
    $alarmInfo{"700601F0"} = "PM4ALLDeviceNetMacID48CommunicationLost";
    $alarmInfo{"700601F1"} = "PM4ALLDeviceNetMacID49CommunicationLost";
    $alarmInfo{"700601F2"} = "PM4ALLDeviceNetMacID50CommunicationLost";
    $alarmInfo{"700601F3"} = "PM4ALLDeviceNetMacID51CommunicationLost";
    $alarmInfo{"700601F4"} = "PM4ALLDeviceNetMacID52CommunicationLost";
    $alarmInfo{"700601F5"} = "PM4ALLDeviceNetMacID53CommunicationLost";
    $alarmInfo{"700601F6"} = "PM4ALLDeviceNetMacID54CommunicationLost";
    $alarmInfo{"700601F7"} = "PM4ALLDeviceNetMacID55CommunicationLost";
    $alarmInfo{"700601F8"} = "PM4ALLDeviceNetMacID56CommunicationLost";
    $alarmInfo{"700601F9"} = "PM4ALLDeviceNetMacID57CommunicationLost";
    $alarmInfo{"700601FA"} = "PM4ALLDeviceNetMacID58CommunicationLost";
    $alarmInfo{"700601FB"} = "PM4ALLDeviceNetMacID59CommunicationLost";
    $alarmInfo{"700601FC"} = "PM4ALLDeviceNetMacID60CommunicationLost";
    $alarmInfo{"700601FD"} = "PM4ALLDeviceNetMacID61CommunicationLost";
    $alarmInfo{"700601FE"} = "PM4ALLDeviceNetMacID62CommunicationLost";
    $alarmInfo{"700601FF"} = "PM4ALLDeviceNetMacID63CommunicationLost";
    $alarmInfo{"70060240"} = "PM4ALLDeviceNetMacID0Error";
    $alarmInfo{"70060241"} = "PM4ALLDeviceNetMacID1Error";
    $alarmInfo{"70060242"} = "PM4ALLDeviceNetMacID2Error";
    $alarmInfo{"70060243"} = "PM4ALLDeviceNetMacID3Error";
    $alarmInfo{"70060244"} = "PM4ALLDeviceNetMacID4Error";
    $alarmInfo{"70060245"} = "PM4ALLDeviceNetMacID5Error";
    $alarmInfo{"70060246"} = "PM4ALLDeviceNetMacID6Error";
    $alarmInfo{"70060247"} = "PM4ALLDeviceNetMacID7Error";
    $alarmInfo{"70060248"} = "PM4ALLDeviceNetMacID8Error";
    $alarmInfo{"70060249"} = "PM4ALLDeviceNetMacID9Error";
    $alarmInfo{"7006024A"} = "PM4ALLDeviceNetMacID10Error";
    $alarmInfo{"7006024B"} = "PM4ALLDeviceNetMacID11Error";
    $alarmInfo{"7006024C"} = "PM4ALLDeviceNetMacID12Error";
    $alarmInfo{"7006024D"} = "PM4ALLDeviceNetMacID13Error";
    $alarmInfo{"7006024E"} = "PM4ALLDeviceNetMacID14Error";
    $alarmInfo{"7006024F"} = "PM4ALLDeviceNetMacID15Error";
    $alarmInfo{"70060250"} = "PM4ALLDeviceNetMacID16Error";
    $alarmInfo{"70060251"} = "PM4ALLDeviceNetMacID17Error";
    $alarmInfo{"70060252"} = "PM4ALLDeviceNetMacID18Error";
    $alarmInfo{"70060253"} = "PM4ALLDeviceNetMacID19Error";
    $alarmInfo{"70060254"} = "PM4ALLDeviceNetMacID20Error";
    $alarmInfo{"70060255"} = "PM4ALLDeviceNetMacID21Error";
    $alarmInfo{"70060256"} = "PM4ALLDeviceNetMacID22Error";
    $alarmInfo{"70060257"} = "PM4ALLDeviceNetMacID23Error";
    $alarmInfo{"70060258"} = "PM4ALLDeviceNetMacID24Error";
    $alarmInfo{"70060259"} = "PM4ALLDeviceNetMacID25Error";
    $alarmInfo{"7006025A"} = "PM4ALLDeviceNetMacID26Error";
    $alarmInfo{"7006025B"} = "PM4ALLDeviceNetMacID27Error";
    $alarmInfo{"7006025C"} = "PM4ALLDeviceNetMacID28Error";
    $alarmInfo{"7006025D"} = "PM4ALLDeviceNetMacID29Error";
    $alarmInfo{"7006025E"} = "PM4ALLDeviceNetMacID30Error";
    $alarmInfo{"7006025F"} = "PM4ALLDeviceNetMacID31Error";
    $alarmInfo{"70060260"} = "PM4ALLDeviceNetMacID32Error";
    $alarmInfo{"70060261"} = "PM4ALLDeviceNetMacID33Error";
    $alarmInfo{"70060262"} = "PM4ALLDeviceNetMacID34Error";
    $alarmInfo{"70060263"} = "PM4ALLDeviceNetMacID35Error";
    $alarmInfo{"70060264"} = "PM4ALLDeviceNetMacID36Error";
    $alarmInfo{"70060265"} = "PM4ALLDeviceNetMacID37Error";
    $alarmInfo{"70060266"} = "PM4ALLDeviceNetMacID38Error";
    $alarmInfo{"70060267"} = "PM4ALLDeviceNetMacID39Error";
    $alarmInfo{"70060268"} = "PM4ALLDeviceNetMacID40Error";
    $alarmInfo{"70060269"} = "PM4ALLDeviceNetMacID41Error";
    $alarmInfo{"7006026A"} = "PM4ALLDeviceNetMacID42Error";
    $alarmInfo{"7006026B"} = "PM4ALLDeviceNetMacID43Error";
    $alarmInfo{"7006026C"} = "PM4ALLDeviceNetMacID44Error";
    $alarmInfo{"7006026D"} = "PM4ALLDeviceNetMacID45Error";
    $alarmInfo{"7006026E"} = "PM4ALLDeviceNetMacID46Error";
    $alarmInfo{"7006026F"} = "PM4ALLDeviceNetMacID47Error";
    $alarmInfo{"70060270"} = "PM4ALLDeviceNetMacID48Error";
    $alarmInfo{"70060271"} = "PM4ALLDeviceNetMacID49Error";
    $alarmInfo{"70060272"} = "PM4ALLDeviceNetMacID50Error";
    $alarmInfo{"70060273"} = "PM4ALLDeviceNetMacID51Error";
    $alarmInfo{"70060274"} = "PM4ALLDeviceNetMacID52Error";
    $alarmInfo{"70060275"} = "PM4ALLDeviceNetMacID53Error";
    $alarmInfo{"70060276"} = "PM4ALLDeviceNetMacID54Error";
    $alarmInfo{"70060277"} = "PM4ALLDeviceNetMacID55Error";
    $alarmInfo{"70060278"} = "PM4ALLDeviceNetMacID56Error";
    $alarmInfo{"70060279"} = "PM4ALLDeviceNetMacID57Error";
    $alarmInfo{"7006027A"} = "PM4ALLDeviceNetMacID58Error";
    $alarmInfo{"7006027B"} = "PM4ALLDeviceNetMacID59Error";
    $alarmInfo{"7006027C"} = "PM4ALLDeviceNetMacID60Error";
    $alarmInfo{"7006027D"} = "PM4ALLDeviceNetMacID61Error";
    $alarmInfo{"7006027E"} = "PM4ALLDeviceNetMacID62Error";
    $alarmInfo{"7006027F"} = "PM4ALLDeviceNetMacID63Error";
    $alarmInfo{"7010000"} = "WaferLiftAlarmWL1Cleared";
    $alarmInfo{"7010001"} = "WaferLiftAlarmWL1Detected";
    $alarmInfo{"7020000"} = "WaferLiftAlarmWL2Cleared";
    $alarmInfo{"7020001"} = "WaferLiftAlarmWL2Detected";
    $alarmInfo{"7030000"} = "WaferLiftAlarmWL3Cleared";
    $alarmInfo{"7030001"} = "WaferLiftAlarmWL3Detected";
    $alarmInfo{"7040000"} = "WaferLiftAlarmWL4Cleared";
    $alarmInfo{"7040001"} = "WaferLiftAlarmWL4Detected";
    $alarmInfo{"71060001"} = "TCCommunicationTimeout";
    $alarmInfo{"71060002"} = "ADSCommunicationTimeout";
    $alarmInfo{"71060003"} = "ADSWatchDogAlarmOccurred";
    $alarmInfo{"71060004"} = "ConfigurationFileOrRecipeFileNotReceived";
    $alarmInfo{"71060005"} = "StatusIsNotREADY";
    $alarmInfo{"71060006"} = "StatusIsRUN";
    $alarmInfo{"71060007"} = "StatusIsNotRUN";
    $alarmInfo{"71060008"} = "NoStartStepExistsInTheSpecifiedRecipe";
    $alarmInfo{"71060009"} = "PressureValueAnd1atmSensorMismatch";
    $alarmInfo{"7106000A"} = "AlarmOccurred";
    $alarmInfo{"7106000B"} = "PauseOccurred";
    $alarmInfo{"7106000C"} = "SafetyOccurred";
    $alarmInfo{"7106000D"} = "AbortOccurred";
    $alarmInfo{"7106000E"} = "OtherErrorOccurred";
    $alarmInfo{"71060010"} = "SeriousAlarmNonRecipe)Occurred";
    $alarmInfo{"71060011"} = "LightAlarmNonRecipe)Occurred";
    $alarmInfo{"71060012"} = "SafetyLatchAlarmOccurred";
    $alarmInfo{"71060013"} = "MaintenanceAlarmOccurred";
    $alarmInfo{"71060014"} = "DIMaintenanceAlarmOccurred";
    $alarmInfo{"71060020"} = "CapabilityIsAborted";
    $alarmInfo{"71060021"} = "Purge-CurtainStatusIsNot-Active";
    $alarmInfo{"71060022"} = "NoWafersAvailableForPeriodicDummy";
    $alarmInfo{"71060023"} = "WarningCountNearingAutoCleanLimit";
    $alarmInfo{"71060024"} = "WarningCountNearingAutoPurgeLimit";
    $alarmInfo{"71060025"} = "WarningCountNearingAutoDummyLimit";
    $alarmInfo{"71060026"} = "CoolingWaterLeak";
    $alarmInfo{"71060027"} = "CoolingWaterLeak2";
    $alarmInfo{"71060028"} = "SmokeDetected";
    $alarmInfo{"71060029"} = "HClDetectedBySensor";
    $alarmInfo{"7106002A"} = "LiquidLeakDetected";
    $alarmInfo{"7106002B"} = "LiquidLeak2Detected";
    $alarmInfo{"7106002C"} = "H2Detected";
    $alarmInfo{"7106002D"} = "Cl2Detected";
    $alarmInfo{"7106002E"} = "NH3Detected";
    $alarmInfo{"7106002F"} = "EmeraldHIGFlowControlDisabled";
    $alarmInfo{"71060040"} = "ModuleNotResponding";
    $alarmInfo{"71060041"} = "HoldToAbortTimeout";
    $alarmInfo{"71060042"} = "SlotValveOpen";
    $alarmInfo{"71060043"} = "PC104PMCommunicationsDisconnected";
    $alarmInfo{"71060044"} = "MustRunSERVICEStartupRecipe";
    $alarmInfo{"71060045"} = "InvalidSERVICERecipeType";
    $alarmInfo{"71060046"} = "LocalRackLockedUp";
    $alarmInfo{"71060047"} = "Gas1FlowToleranceFault";
    $alarmInfo{"71060048"} = "Gas2FlowToleranceFault";
    $alarmInfo{"71060049"} = "Gas3FlowToleranceFault";
    $alarmInfo{"7106004A"} = "Gas4FlowToleranceFault";
    $alarmInfo{"7106004B"} = "HivacFailedToOpen";
    $alarmInfo{"7106004C"} = "HivacFailedToClose";
    $alarmInfo{"7106004D"} = "PumpToBaseFailed";
    $alarmInfo{"7106004E"} = "RoughingTimeout";
    $alarmInfo{"7106004F"} = "RoughingPressureTooHigh";
    $alarmInfo{"71060050"} = "CryoOverMaxTemperature";
    $alarmInfo{"71060051"} = "TurboPumpFailed";
    $alarmInfo{"71060052"} = "TurboOverMaxTemperature";
    $alarmInfo{"71060053"} = "CannotRegenTurboPump!";
    $alarmInfo{"71060054"} = "TurboFailedToReachSpeed";
    $alarmInfo{"71060055"} = "TurboAtFaultOrNotAtSpeed";
    $alarmInfo{"71060056"} = "WaferLiftSlowToMoveUp";
    $alarmInfo{"71060057"} = "WaferLiftSlowToMoveDown";
    $alarmInfo{"71060058"} = "WaferLiftFailedToMove";
    $alarmInfo{"71060059"} = "PlatenControlTempT/CDisconnected";
    $alarmInfo{"7106005A"} = "PlatenSafetyTempT/CDisconnected";
    $alarmInfo{"7106005B"} = "PlatenControl-safetyTempDifference";
    $alarmInfo{"7106005C"} = "PlatenTempOutOfBand";
    $alarmInfo{"7106005D"} = "PlatenFailedToMoveUp";
    $alarmInfo{"7106005E"} = "PlatenFailedToMoveDown";
    $alarmInfo{"7106005F"} = "RecirculatorTempOutOfBand";
    $alarmInfo{"71060060"} = "RecirculatorTempT/CDisconnected";
    $alarmInfo{"71060061"} = "PlatenTempT/CDisconnected";
    $alarmInfo{"71060062"} = "CoilRFReflectedPowerFault";
    $alarmInfo{"71060063"} = "CoilRFReflectedPowerHold";
    $alarmInfo{"71060064"} = "CoilForwardPowerFault";
    $alarmInfo{"71060065"} = "PotMovementPositionFault";
    $alarmInfo{"71060066"} = "PlatenRFReflectedPowerAbort";
    $alarmInfo{"71060067"} = "PlatenRFReflectedPowerHold";
    $alarmInfo{"71060068"} = "DCBiasAboveMaxLimit";
    $alarmInfo{"71060069"} = "DCBiasBelowMinLimit";
    $alarmInfo{"7106006A"} = "DCBiasToleranceFault";
    $alarmInfo{"7106006B"} = "ForwardPowerToleranceFault";
    $alarmInfo{"7106006C"} = "LoadPowerToleranceFault";
    $alarmInfo{"7106006D"} = "Bake-outControlTempT/CDisconnected";
    $alarmInfo{"7106006E"} = "Bake-outSafetyTempT/CDisconnected";
    $alarmInfo{"7106006F"} = "Bake-outControl-safetyTempDifference";
    $alarmInfo{"71060070"} = "Bake-outSlowToReachTemperature";
    $alarmInfo{"71060071"} = "EscPump-outPressureLimitFault";
    $alarmInfo{"71060072"} = "EscPump-outPressureFaultInUnclamp";
    $alarmInfo{"71060073"} = "EscFlowFault";
    $alarmInfo{"71060074"} = "EscWaferValveOpenFault";
    $alarmInfo{"71060075"} = "EscPressureInBandTime-out";
    $alarmInfo{"71060076"} = "EscPressureToleranceFault";
    $alarmInfo{"71060077"} = "EscVoltageFault";
    $alarmInfo{"71060078"} = "TimeoutWaitingForBackfillPressure";
    $alarmInfo{"71060079"} = "Leak-upRateFailure";
    $alarmInfo{"7106007A"} = "CompressedAirFault";
    $alarmInfo{"7106007B"} = "LocalPCTemperatureFault";
    $alarmInfo{"7106007C"} = "ModuleFanFault";
    $alarmInfo{"7106007D"} = "VentServiceFailedToReachAtmosphere";
    $alarmInfo{"7106007E"} = "RGALeakCheckRequired";
    $alarmInfo{"7106007F"} = "WaitingForStage1Pressure -Slow";
    $alarmInfo{"71060080"} = "WaitingForStage2Pressure -Slow";
    $alarmInfo{"71060081"} = "NotWaitingForStage1Pressure ";
    $alarmInfo{"71060082"} = "FailedToReachStage1Pressure";
    $alarmInfo{"71060083"} = "FailedToReachStage2Pressure";
    $alarmInfo{"71060084"} = "CryoRegenServiceRoutineFailed";
    $alarmInfo{"71060085"} = "CTIControllerCommunicationsError";
    $alarmInfo{"71060086"} = "CTIPumpNotResponding";
    $alarmInfo{"71060087"} = "TurboPlusServiceRoutineFailed";
    $alarmInfo{"71060088"} = "HeaterMalfunctionHappened";
    $alarmInfo{"71600030"} = "RC4ADSWatchDogAlarmOccurredClr";
    $alarmInfo{"71600031"} = "RC4ADSWatchDogAlarmOccurredDet";
    $alarmInfo{"716000a0"} = "RC4AlarmOccurredClr";
    $alarmInfo{"716000a1"} = "RC4AlarmOccurredDet";
    $alarmInfo{"71600100"} = "RC4SeriousAlarmOccurredClr";
    $alarmInfo{"71600101"} = "RC4SeriousAlarmOccurredDet";
    $alarmInfo{"71600110"} = "RC4LightAlarmOccurredClr";
    $alarmInfo{"71600111"} = "RC4LightAlarmOccurredDet";
    $alarmInfo{"71600120"} = "RC4SafetyLatchAlarmOccurredClr";
    $alarmInfo{"71600121"} = "RC4SafetyLatchAlarmOccurredDet";
    $alarmInfo{"71600130"} = "RC4MaintenanceAlarmOccurredClr";
    $alarmInfo{"71600131"} = "RC4MaintenanceAlarmOccurredDet";
    $alarmInfo{"71600140"} = "RC4DIMaintenanceAlarmOccurredClr";
    $alarmInfo{"71600141"} = "RC4DIMaintenanceAlarmOccurredDet";
    $alarmInfo{"72060000"} = "72060000";
    $alarmInfo{"72060001"} = "CommunicationTimeout";
    $alarmInfo{"72060002"} = "StatusChangedToIDLE";
    $alarmInfo{"72060003"} = "CommandWasRejected";
    $alarmInfo{"72060004"} = "MotionStopped";
    $alarmInfo{"72060005"} = "MotionAborted";
    $alarmInfo{"72060006"} = "MotorStatusError";
    $alarmInfo{"72060007"} = "ACKTimeout";
    $alarmInfo{"72060008"} = "CompletionTimeout";
    $alarmInfo{"72060009"} = "ActualError";
    $alarmInfo{"7206000A"} = "SensorError";
    $alarmInfo{"7206000B"} = "SensorUnknown";
    $alarmInfo{"7206000C"} = "TransferInterlockErrorOccurred";
    $alarmInfo{"7206000D"} = "WaferInterlockErrorOccurred";
    $alarmInfo{"7206000E"} = "PressureInterlockErrorOccurred";
    $alarmInfo{"72060010"} = "MotorUnitErrorOccurred";
    $alarmInfo{"72060011"} = "InitializationUncompleted";
    $alarmInfo{"72060012"} = "BERobotInterlockErrorOccurred";
    $alarmInfo{"72060013"} = "HardwareUpperLimitSensorTripped";
    $alarmInfo{"72060014"} = "HardwareLowerLimitSensorTripped";
    $alarmInfo{"72060015"} = "RotationAxisHardwareInterlockOccurred";
    $alarmInfo{"72060016"} = "RotationAxisSoftwareInterlockOccurred";
    $alarmInfo{"72060017"} = "VerticalAxisSoftwareInterlockOccurred";
    $alarmInfo{"72060018"} = "HardwareLimitSwitchIsNotProperlySetup";
    $alarmInfo{"72060019"} = "ExceedTheSoftwareLimitsOfUpperPulse";
    $alarmInfo{"7206001A"} = "ExceedTheSoftwareLimitsOfLowerPulse";
    $alarmInfo{"7206001B"} = "GateValveIsOpen";
    $alarmInfo{"7206001C"} = "MotionStopOccurred";
    $alarmInfo{"7206001D"} = "ChamberLidIsOpen";
    $alarmInfo{"7206001E"} = "BERBArmIsExtendedPosition";
    $alarmInfo{"7206001F"} = "LiftCabinetIsOpen";
    $alarmInfo{"72060020"} = "ErrorReadingRotationHomeSensorState";
    $alarmInfo{"72060021"} = "RotationHome";
    $alarmInfo{"73060000"} = "73060000-EPI";
    $alarmInfo{"78060000"} = "78060000-EPI";
    $alarmInfo{"7B060001"} = "7B060001-EPI";
    $alarmInfo{"7B060002"} = "7B060002-EPI";
    $alarmInfo{"7B060003"} = "7B060003-EPI";
    $alarmInfo{"7B060004"} = "7B060004-EPI";
    $alarmInfo{"7B060005"} = "7B060005-EPI";
    $alarmInfo{"7B060006"} = "7B060006-EPI";
    $alarmInfo{"7B060007"} = "7B060007-EPI";
    $alarmInfo{"7B060008"} = "7B060008-EPI";
    $alarmInfo{"7B060009"} = "7B060009-EPI";
    $alarmInfo{"7B06000A"} = "7B06000A-EPI";
    $alarmInfo{"800601E2"} = "SYN800601E2";
    $alarmInfo{"800601E3"} = "SYN800601E3";
    $alarmInfo{"800601E4"} = "SYN800601E4";
    $alarmInfo{"800601DE"} = "SYN800601DE";
    $alarmInfo{"800601DF"} = "SYN800601DF";
    $alarmInfo{"800601E1"} = "SYN800601E1";
    $alarmInfo{"8010000"} = "ReactorBufferAlarmBF1Cleared";
    $alarmInfo{"8010001"} = "ReactorBufferAlarmBF1Detected";
    $alarmInfo{"8020000"} = "ReactorBufferAlarmBF2Cleared";
    $alarmInfo{"8020001"} = "ReactorBufferAlarmBF2Detected";
    $alarmInfo{"8030000"} = "ReactorBufferAlarmBF3Cleared";
    $alarmInfo{"8030001"} = "ReactorBufferAlarmBF3Detected";
    $alarmInfo{"8040000"} = "ReactorBufferAlarmBF4Cleared";
    $alarmInfo{"8040001"} = "ReactorBufferAlarmBF4Detected";
    $alarmInfo{"81060001"} = "TCCommunicationTimeout";
    $alarmInfo{"81060002"} = "ADSCommunicationTimeout";
    $alarmInfo{"81060003"} = "ADSWatchDogAlarmOccurred";
    $alarmInfo{"81060004"} = "ConfigurationFileOrRecipeFileNotReceived";
    $alarmInfo{"81060005"} = "StatusIsNotREADY";
    $alarmInfo{"81060006"} = "StatusIsRUN";
    $alarmInfo{"81060007"} = "StatusIsNotRUN";
    $alarmInfo{"81060008"} = "NoStartStepExistsInTheSpecifiedRecipe";
    $alarmInfo{"81060009"} = "PressureValueAnd1atmSensorMismatch";
    $alarmInfo{"8106000A"} = "AlarmOccurred";
    $alarmInfo{"8106000B"} = "PauseOccurred";
    $alarmInfo{"8106000C"} = "SafetyOccurred";
    $alarmInfo{"8106000D"} = "AbortOccurred";
    $alarmInfo{"8106000E"} = "OtherErrorOccurred";
    $alarmInfo{"81060010"} = "SeriousAlarmNonRecipe)Occurred";
    $alarmInfo{"81060011"} = "LightAlarmNonRecipe)Occurred";
    $alarmInfo{"81060012"} = "SafetyLatchAlarmOccurred";
    $alarmInfo{"81060013"} = "MaintenanceAlarmOccurred";
    $alarmInfo{"81060014"} = "DIMaintenanceAlarmOccurred";
    $alarmInfo{"81060020"} = "CapabilityIsAborted";
    $alarmInfo{"81060021"} = "Purge-CurtainStatusIsNot-Active";
    $alarmInfo{"81060022"} = "NoWafersAvailableForPeriodicDummy";
    $alarmInfo{"81060023"} = "WarningCountNearingAutoCleanLimit";
    $alarmInfo{"81060024"} = "WarningCountNearingAutoPurgeLimit";
    $alarmInfo{"81060025"} = "WarningCountNearingAutoDummyLimit";
    $alarmInfo{"81060026"} = "CoolingWaterLeak";
    $alarmInfo{"81060027"} = "CoolingWaterLeak2";
    $alarmInfo{"81060028"} = "SmokeDetected";
    $alarmInfo{"81060029"} = "HClDetectedBySensor";
    $alarmInfo{"8106002A"} = "LiquidLeakDetected";
    $alarmInfo{"8106002B"} = "LiquidLeak2Detected";
    $alarmInfo{"8106002C"} = "H2Detected";
    $alarmInfo{"8106002D"} = "Cl2Detected";
    $alarmInfo{"8106002E"} = "NH3Detected";
    $alarmInfo{"8106002F"} = "EmeraldHIGFlowControlDisabled";
    $alarmInfo{"81060040"} = "ModuleNotResponding";
    $alarmInfo{"81060041"} = "HoldToAbortTimeout";
    $alarmInfo{"81060042"} = "SlotValveOpen";
    $alarmInfo{"81060043"} = "PC104PMCommunicationsDisconnected";
    $alarmInfo{"81060044"} = "MustRunSERVICEStartupRecipe";
    $alarmInfo{"81060045"} = "InvalidSERVICERecipeType";
    $alarmInfo{"81060046"} = "LocalRackLockedUp";
    $alarmInfo{"81060047"} = "Gas1FlowToleranceFault";
    $alarmInfo{"81060048"} = "Gas2FlowToleranceFault";
    $alarmInfo{"81060049"} = "Gas3FlowToleranceFault";
    $alarmInfo{"8106004A"} = "Gas4FlowToleranceFault";
    $alarmInfo{"8106004B"} = "HivacFailedToOpen";
    $alarmInfo{"8106004C"} = "HivacFailedToClose";
    $alarmInfo{"8106004D"} = "PumpToBaseFailed";
    $alarmInfo{"8106004E"} = "RoughingTimeout";
    $alarmInfo{"8106004F"} = "RoughingPressureTooHigh";
    $alarmInfo{"81060050"} = "CryoOverMaxTemperature";
    $alarmInfo{"81060051"} = "TurboPumpFailed";
    $alarmInfo{"81060052"} = "TurboOverMaxTemperature";
    $alarmInfo{"81060053"} = "CannotRegenTurboPump!";
    $alarmInfo{"81060054"} = "TurboFailedToReachSpeed";
    $alarmInfo{"81060055"} = "TurboAtFaultOrNotAtSpeed";
    $alarmInfo{"81060056"} = "WaferLiftSlowToMoveUp";
    $alarmInfo{"81060057"} = "WaferLiftSlowToMoveDown";
    $alarmInfo{"81060058"} = "WaferLiftFailedToMove";
    $alarmInfo{"81060059"} = "PlatenControlTempT/CDisconnected";
    $alarmInfo{"8106005A"} = "PlatenSafetyTempT/CDisconnected";
    $alarmInfo{"8106005B"} = "PlatenControl-safetyTempDifference";
    $alarmInfo{"8106005C"} = "PlatenTempOutOfBand";
    $alarmInfo{"8106005D"} = "PlatenFailedToMoveUp";
    $alarmInfo{"8106005E"} = "PlatenFailedToMoveDown";
    $alarmInfo{"8106005F"} = "RecirculatorTempOutOfBand";
    $alarmInfo{"81060060"} = "RecirculatorTempT/CDisconnected";
    $alarmInfo{"81060061"} = "PlatenTempT/CDisconnected";
    $alarmInfo{"81060062"} = "CoilRFReflectedPowerFault";
    $alarmInfo{"81060063"} = "CoilRFReflectedPowerHold";
    $alarmInfo{"81060064"} = "CoilForwardPowerFault";
    $alarmInfo{"81060065"} = "PotMovementPositionFault";
    $alarmInfo{"81060066"} = "PlatenRFReflectedPowerAbort";
    $alarmInfo{"81060067"} = "PlatenRFReflectedPowerHold";
    $alarmInfo{"81060068"} = "DCBiasAboveMaxLimit";
    $alarmInfo{"81060069"} = "DCBiasBelowMinLimit";
    $alarmInfo{"8106006A"} = "DCBiasToleranceFault";
    $alarmInfo{"8106006B"} = "ForwardPowerToleranceFault";
    $alarmInfo{"8106006C"} = "LoadPowerToleranceFault";
    $alarmInfo{"8106006D"} = "Bake-outControlTempT/CDisconnected";
    $alarmInfo{"8106006E"} = "Bake-outSafetyTempT/CDisconnected";
    $alarmInfo{"8106006F"} = "Bake-outControl-safetyTempDifference";
    $alarmInfo{"81060070"} = "Bake-outSlowToReachTemperature";
    $alarmInfo{"81060071"} = "EscPump-outPressureLimitFault";
    $alarmInfo{"81060072"} = "EscPump-outPressureFaultInUnclamp";
    $alarmInfo{"81060073"} = "EscFlowFault";
    $alarmInfo{"81060074"} = "EscWaferValveOpenFault";
    $alarmInfo{"81060075"} = "EscPressureInBandTime-out";
    $alarmInfo{"81060076"} = "EscPressureToleranceFault";
    $alarmInfo{"81060077"} = "EscVoltageFault";
    $alarmInfo{"81060078"} = "TimeoutWaitingForBackfillPressure";
    $alarmInfo{"81060079"} = "Leak-upRateFailure";
    $alarmInfo{"8106007A"} = "CompressedAirFault";
    $alarmInfo{"8106007B"} = "LocalPCTemperatureFault";
    $alarmInfo{"8106007C"} = "ModuleFanFault";
    $alarmInfo{"8106007D"} = "VentServiceFailedToReachAtmosphere";
    $alarmInfo{"8106007E"} = "RGALeakCheckRequired";
    $alarmInfo{"8106007F"} = "WaitingForStage1Pressure -Slow";
    $alarmInfo{"81060080"} = "WaitingForStage2Pressure -Slow";
    $alarmInfo{"81060081"} = "NotWaitingForStage1Pressure ";
    $alarmInfo{"81060082"} = "FailedToReachStage1Pressure";
    $alarmInfo{"81060083"} = "FailedToReachStage2Pressure";
    $alarmInfo{"81060084"} = "CryoRegenServiceRoutineFailed";
    $alarmInfo{"81060085"} = "CTIControllerCommunicationsError";
    $alarmInfo{"81060086"} = "CTIPumpNotResponding";
    $alarmInfo{"81060087"} = "TurboPlusServiceRoutineFailed";
    $alarmInfo{"81060088"} = "HeaterMalfunctionHappened";
    $alarmInfo{"81600030"} = "RC5ADSWatchDogAlarmOccurredClr";
    $alarmInfo{"81600031"} = "RC5ADSWatchDogAlarmOccurredDet";
    $alarmInfo{"816000a0"} = "RC5AlarmOccurredClr";
    $alarmInfo{"816000a1"} = "RC5AlarmOccurredDet";
    $alarmInfo{"81600100"} = "RC5SeriousAlarmOccurredClr";
    $alarmInfo{"81600101"} = "RC5SeriousAlarmOccurredDet";
    $alarmInfo{"81600110"} = "RC5LightAlarmOccurredClr";
    $alarmInfo{"81600111"} = "RC5LightAlarmOccurredDet";
    $alarmInfo{"81600120"} = "RC5SafetyLatchAlarmOccurredClr";
    $alarmInfo{"81600121"} = "RC5SafetyLatchAlarmOccurredDet";
    $alarmInfo{"81600130"} = "RC5MaintenanceAlarmOccurredClr";
    $alarmInfo{"81600131"} = "RC5MaintenanceAlarmOccurredDet";
    $alarmInfo{"81600140"} = "RC5DIMaintenanceAlarmOccurredClr";
    $alarmInfo{"81600141"} = "RC5DIMaintenanceAlarmOccurredDet";
    $alarmInfo{"9010000"} = "CoolingStageAlarmCS1Cleared";
    $alarmInfo{"9010001"} = "CoolingStageAlarmCS1Detected";
    $alarmInfo{"9020000"} = "CoolingStageAlarmCS2Cleared";
    $alarmInfo{"9020001"} = "CoolingStageAlarmCS2Detected";
    $alarmInfo{"96060000"} = "96060000";
    $alarmInfo{"96060001"} = "96060001";
    $alarmInfo{"97060000"} = "97060000";
    $alarmInfo{"97060001"} = "97060001";
    $alarmInfo{"A1060001"} = "LP1TransferEndStatusTimeout";
    $alarmInfo{"A1060002"} = "LP2TransferEndStatusTimeout";
    $alarmInfo{"A1060003"} = "LP3TransferEndStatusTimeout";
    $alarmInfo{"A1060004"} = "LP4TransferEndStatusTimeout";
    $alarmInfo{"A1060005"} = "LP1MapReadCompleteTimeout";
    $alarmInfo{"A1060006"} = "LP2MapReadCompleteTimeout";
    $alarmInfo{"A1060007"} = "LP3MapReadCompleteTimeout";
    $alarmInfo{"A1060008"} = "LP4MapReadCompleteTimeout";
    $alarmInfo{"A1060009"} = "LP1IDReadCompleteTimeout";
    $alarmInfo{"A106000A"} = "LP2IDReadCompleteTimeout";
    $alarmInfo{"A106000B"} = "LP3IDReadCompleteTimeout";
    $alarmInfo{"A106000C"} = "LP4IDReadCompleteTimeout";
    $alarmInfo{"A106000D"} = "LP1Aborted";
    $alarmInfo{"A106000E"} = "LP2Aborted";
    $alarmInfo{"A106000F"} = "LP2Aborted";
    $alarmInfo{"A1060010"} = "LP3Aborted";
    $alarmInfo{"A1060100"} = "LP1IDReaderError";
    $alarmInfo{"A1060101"} = "LP2IDReaderError";
    $alarmInfo{"A1060102"} = "LP3IDReaderError";
    $alarmInfo{"A1060103"} = "LP4IDReaderError";
    $alarmInfo{"A1060104"} = "LP1IDReaderTimeOut";
    $alarmInfo{"A1060105"} = "LP2IDReaderTimeOut";
    $alarmInfo{"A1060106"} = "LP3IDReaderTimeOut";
    $alarmInfo{"A1060107"} = "LP4IDReaderTimeOut";
    $alarmInfo{"A1060108"} = "LP1IDVerifyNG";
    $alarmInfo{"A1060109"} = "LP2IDVerifyNG";
    $alarmInfo{"A106010A"} = "LP3IDVerifyNG";
    $alarmInfo{"A106010B"} = "LP4IDVerifyNG";
    $alarmInfo{"A1060110"} = "LP1OutOfSerevice";
    $alarmInfo{"A1060111"} = "LP2OutOfSerevice";
    $alarmInfo{"A1060112"} = "LP3OutOfSerevice";
    $alarmInfo{"A1060113"} = "LP4OutOfSerevice";
    $alarmInfo{"A1060120"} = "LP1MapReadError";
    $alarmInfo{"A1060121"} = "LP2MapReadError";
    $alarmInfo{"A1060122"} = "LP3MapReadError";
    $alarmInfo{"A1060123"} = "LP4MapReadError";
    $alarmInfo{"A1060124"} = "LP1MapReadTimeOut";
    $alarmInfo{"A1060125"} = "LP2MapReadTimeOut";
    $alarmInfo{"A1060126"} = "LP3MapReadTimeOut";
    $alarmInfo{"A1060127"} = "LP4MapReadTimeOut";
    $alarmInfo{"A1060128"} = "LP1MapVerifyNG";
    $alarmInfo{"A1060129"} = "LP2MapVerifyNG";
    $alarmInfo{"A106012A"} = "LP3MapVerifyNG";
    $alarmInfo{"A106012B"} = "LP4MapVerifyNG";
    $alarmInfo{"A106012C"} = "LP1MapDataIllegal";
    $alarmInfo{"A106012D"} = "LP2MapDataIllegal";
    $alarmInfo{"A106012E"} = "LP3MapDataIllegal";
    $alarmInfo{"A106012F"} = "LP4MapDataIllegal";
    $alarmInfo{"A2060000"} = "A2060000";
    $alarmInfo{"A2060001"} = "CommunicationTimeoutInTheMessageSending";
    $alarmInfo{"A2060001"} = "SCHECommunicationTimeoutInTheMessageSending";
    $alarmInfo{"A2060002"} = "SCHETheMessageSendNG";
    $alarmInfo{"A2060002"} = "TheMessageSendNG";
    $alarmInfo{"A2060003"} = "SCHETheErrorResponseIsReceivedInTheMessageSending";
    $alarmInfo{"A2060003"} = "TheErrorResponseIsReceivedInTheMessageSending";
    $alarmInfo{"A2060011"} = "SCHETheWaferExistsThoughThereIsNotRecipeSetting";
    $alarmInfo{"A2060011"} = "TheWaferExistsThoughThereIsNotRecipeSetting";
    $alarmInfo{"A2060012"} = "SCHETheWaferDoesNotExistThoughThereIsRecipeSetting";
    $alarmInfo{"A2060012"} = "TheWaferDoesNotExistThoughThereIsRecipeSetting";
    $alarmInfo{"A2060013"} = "SCHETheWaferDoesNotExistThoughThereIsSlotMapInformation";
    $alarmInfo{"A2060013"} = "TheWaferDoesNotExistThoughThereIsSlotMapInformation";
    $alarmInfo{"A2060014"} = "SCHETheSetupSequenceTerminatedAbnormally";
    $alarmInfo{"A2060014"} = "TheSetupSequenceTerminatedAbnormally";
    $alarmInfo{"A2060015"} = "SCHETheShutdownSequenceTerminatedAbnormally";
    $alarmInfo{"A2060015"} = "TheShutdownSequenceTerminatedAbnormally";
    $alarmInfo{"A2060016"} = "SCHETheIsolateSequenceTerminatedAbnormally";
    $alarmInfo{"A2060016"} = "TheIsolateSequenceTerminatedAbnormally";
    $alarmInfo{"A2060017"} = "SCHETheLLC%sCyclePurgeSequenceTerminatedAbnormally";
    $alarmInfo{"A2060017"} = "TheLLC%sCyclePurgeSequenceTerminatedAbnormally";
    $alarmInfo{"A2060018"} = "SCHETheLLC%sCyclePurgeSequenceTerminatedAbnormally";
    $alarmInfo{"A2060018"} = "TheLLC%sCyclePurgeSequenceTerminatedAbnormally";
    $alarmInfo{"A2060019"} = "SCHETheSemi-autoTransferSequenceTerminatedAbnormally";
    $alarmInfo{"A2060019"} = "TheSemi-autoTransferSequenceTerminatedAbnormally";
    $alarmInfo{"A206001A"} = "SCHETheAutoTransferSequencePaused";
    $alarmInfo{"A206001A"} = "TheAutoTransferSequencePaused";
    $alarmInfo{"A206001B"} = "SCHETheAutoTransferSequenceStopped";
    $alarmInfo{"A206001B"} = "TheAutoTransferSequenceStopped";
    $alarmInfo{"A206001C"} = "SCHETheAutoTransferSequenceAborted";
    $alarmInfo{"A206001C"} = "TheAutoTransferSequenceAborted";
    $alarmInfo{"A206001D"} = "SCHETheAutoTransferSequenceTerminated";
    $alarmInfo{"A206001D"} = "TheAutoTransferSequenceTerminated";
    $alarmInfo{"A206001E"} = "SCHETheScriptSequenceTerminatedAbnormally";
    $alarmInfo{"A206001E"} = "TheScriptSequenceTerminatedAbnormally";
    $alarmInfo{"A206001F"} = "SCHETheAutoLeakCheckSequenceTerminatedAbnormally";
    $alarmInfo{"A206001F"} = "TheAutoLeakCheckSequenceTerminatedAbnormally";
    $alarmInfo{"A2060021"} = "SCHEWaferInformationOverlaps";
    $alarmInfo{"A2060021"} = "WaferInformationOverlaps";
    $alarmInfo{"A2060022"} = "SCHEWaferExists";
    $alarmInfo{"A2060022"} = "WaferExists";
    $alarmInfo{"A2060023"} = "SCHEWaferDoesNotExist";
    $alarmInfo{"A2060023"} = "WaferDoesNotExist";
    $alarmInfo{"A2060024"} = "SCHEWaferInformationIsIllegal";
    $alarmInfo{"A2060024"} = "WaferInformationIsIllegal";
    $alarmInfo{"A2060025"} = "SCHEWaferInformationDoesNotMove";
    $alarmInfo{"A2060025"} = "WaferInformationDoesNotMove";
    $alarmInfo{"A206002A"} = "SCHEWaferMappingReadTimeoutOccurred";
    $alarmInfo{"A206002A"} = "WaferMappingReadTimeoutOccurred";
    $alarmInfo{"A206002B"} = "SCHEWaferMappingVerificationErrorOccurred";
    $alarmInfo{"A206002B"} = "WaferMappingVerificationErrorOccurred";
    $alarmInfo{"A2060031"} = "ProcessCannotExecute";
    $alarmInfo{"A2060031"} = "SCHEProcessCannotExecute";
    $alarmInfo{"A2060032"} = "SCHETheSemi-autoTransferSequenceCannotExecute";
    $alarmInfo{"A2060032"} = "TheSemi-autoTransferSequenceCannotExecute";
    $alarmInfo{"A2060041"} = "SCHETheControlDoesNotFinish";
    $alarmInfo{"A2060041"} = "TheControlDoesNotFinish";
    $alarmInfo{"A2060042"} = "SCHETheControlCompletedAbnormally";
    $alarmInfo{"A2060042"} = "TheControlCompletedAbnormally";
    $alarmInfo{"A2060043"} = "SCHETheControlCouldNotBeExecutedOrTheControlFailed";
    $alarmInfo{"A2060043"} = "TheControlCouldNotBeExecutedOrTheControlFailed";
    $alarmInfo{"A2060051"} = "SCHEStatusDoesNotChange.TimeOutOccur";
    $alarmInfo{"A2060051"} = "StatusDoesNotChange.TimeOutOccur.)";
    $alarmInfo{"A2060052"} = "SCHEStatusIsIDLE";
    $alarmInfo{"A2060052"} = "StatusIsIDLE";
    $alarmInfo{"A2060053"} = "SCHEStatusIsBUSY";
    $alarmInfo{"A2060053"} = "StatusIsBUSY";
    $alarmInfo{"A2060054"} = "SCHEStatusIsAL-END";
    $alarmInfo{"A2060054"} = "StatusIsAL-END";
    $alarmInfo{"A2060055"} = "SCHEStatusIsAB-END";
    $alarmInfo{"A2060055"} = "StatusIsAB-END";
    $alarmInfo{"A2060056"} = "SCHEStatusIsNotREADY";
    $alarmInfo{"A2060056"} = "StatusIsNotREADY";
    $alarmInfo{"A2060057"} = "SCHEStatusIsNotWAIT";
    $alarmInfo{"A2060057"} = "StatusIsNotWAIT";
    $alarmInfo{"A2060058"} = "SCHEStatusIsNotOPEN";
    $alarmInfo{"A2060058"} = "StatusIsNotOPEN";
    $alarmInfo{"A2060059"} = "SCHEStatusIsNotCLOSE";
    $alarmInfo{"A2060059"} = "StatusIsNotCLOSE";
    $alarmInfo{"A206005A"} = "SCHEStatusIsNotUP";
    $alarmInfo{"A206005A"} = "StatusIsNotUP";
    $alarmInfo{"A206005B"} = "SCHEStatusIsNotDOWN";
    $alarmInfo{"A206005B"} = "StatusIsNotDOWN";
    $alarmInfo{"A206005C"} = "SCHEStatusIsNotOUT-READY";
    $alarmInfo{"A206005C"} = "StatusIsNotOUT-READY";
    $alarmInfo{"A206005D"} = "SCHEStatusIsNot1ATM";
    $alarmInfo{"A206005D"} = "StatusIsNot1ATM";
    $alarmInfo{"A206005E"} = "SCHEStatusIsNotVACUUM";
    $alarmInfo{"A206005E"} = "StatusIsNotVACUUM";
    $alarmInfo{"A206005F"} = "SCHEStatusIsNotCLAMP";
    $alarmInfo{"A206005F"} = "StatusIsNotCLAMP";
    $alarmInfo{"A2060060"} = "SCHEStatusIsNotUNCLAMP";
    $alarmInfo{"A2060060"} = "StatusIsNotUNCLAMP";
    $alarmInfo{"A2060061"} = "SCHEStatusIsNotDOCK";
    $alarmInfo{"A2060061"} = "StatusIsNotDOCK";
    $alarmInfo{"A2060062"} = "SCHEStatusIsNotUNDOCK";
    $alarmInfo{"A2060062"} = "StatusIsNotUNDOCK";
    $alarmInfo{"A2060063"} = "SCHESealPlatePositionIsUnknown";
    $alarmInfo{"A2060063"} = "SealPlatePositionIsUnknown";
    $alarmInfo{"A2060064"} = "ChamberStatusIsUnknown";
    $alarmInfo{"A2060064"} = "SCHEChamberStatusIsUnknown";
    $alarmInfo{"A2060065"} = "ChamberPressureIsDifferent";
    $alarmInfo{"A2060065"} = "SCHEChamberPressureIsDifferent";
    $alarmInfo{"A2060066"} = "SCHEStatusDoesNotChangeToREADY";
    $alarmInfo{"A2060066"} = "StatusDoesNotChangeToREADY";
    $alarmInfo{"A2060067"} = "SCHEThePositionOfRobotArmAxisIsNotOrigin";
    $alarmInfo{"A2060067"} = "ThePositionOfRobotArmAxisIsNotOrigin";
    $alarmInfo{"A2060068"} = "FFUStatusIsAlarm";
    $alarmInfo{"A2060068"} = "SCHEFFUStatusIsAlarm";
    $alarmInfo{"A2060069"} = "InterlockErrorOccursInTheMini-environment";
    $alarmInfo{"A2060069"} = "SCHEInterlockErrorOccursInTheMini-environment";
    $alarmInfo{"A206006A"} = "SCHEStatusIsNotHomePosition";
    $alarmInfo{"A206006A"} = "StatusIsNotHomePosition";
    $alarmInfo{"A206006B"} = "IonizerStatusIsAlarm";
    $alarmInfo{"A206006B"} = "SCHEIonizerStatusIsAlarm";
    $alarmInfo{"A206006C"} = "SCHEStatusIsUnknown";
    $alarmInfo{"A206006C"} = "StatusIsUnknown";
    $alarmInfo{"A206006D"} = "FERobotInterlockErrorOccurs";
    $alarmInfo{"A206006D"} = "SCHEFERobotInterlockErrorOccurs";
    $alarmInfo{"A206006E"} = "AnAlarmHasOccurred";
    $alarmInfo{"A206006E"} = "SCHEAnAlarmHasOccurred";
    $alarmInfo{"A206006F"} = "SCHEStatusIsNotPressureControl";
    $alarmInfo{"A206006F"} = "StatusIsNotPressureControl";
    $alarmInfo{"A2060070"} = "SCHETheWaferCannotBeLoadedIntoTheReactorByTheNonClamperArm";
    $alarmInfo{"A2060070"} = "TheWaferCannotBeLoadedIntoTheReactorByTheNonClamperArm";
    $alarmInfo{"A2060071"} = "SCHETheWaferCannotBeUnloadedFromTheReactorByTheClamperArm";
    $alarmInfo{"A2060071"} = "TheWaferCannotBeUnloadedFromTheReactorByTheClamperArm";
    $alarmInfo{"A2060072"} = "SCHEStatusIsMT-END";
    $alarmInfo{"A2060072"} = "StatusIsMT-END";
    $alarmInfo{"A2060073"} = "SCHETMCCommunicationErrorWasDetected";
    $alarmInfo{"A2060073"} = "TMCCommunicationErrorWasDetected";
    $alarmInfo{"A2060074"} = "SCHETMCSharedMemoryStatusUpdatingErrorWasDetected";
    $alarmInfo{"A2060074"} = "TMCSharedMemoryStatusUpdatingErrorWasDetected";
    $alarmInfo{"A2060075"} = "SCHETMCDriverStatusErrorWasDetected";
    $alarmInfo{"A2060075"} = "TMCDriverStatusErrorWasDetected";
    $alarmInfo{"A2060076"} = "PMCCommunicationErrorWasDetected";
    $alarmInfo{"A2060076"} = "SCHEPMCCommunicationErrorWasDetected";
    $alarmInfo{"A2060077"} = "PMCSharedMemoryStatusUpdatingErrorWasDetected";
    $alarmInfo{"A2060077"} = "SCHEPMCSharedMemoryStatusUpdatingErrorWasDetected";
    $alarmInfo{"A2060078"} = "PMCDriverStatusErrorWasDetected";
    $alarmInfo{"A2060078"} = "SCHEPMCDriverStatusErrorWasDetected";
    $alarmInfo{"A2060079"} = "SCHETheCapabilityIsBeingExecuted";
    $alarmInfo{"A2060079"} = "TheCapabilityIsBeingExecuted";
    $alarmInfo{"A206007A"} = "SCHETheCommunicationStateOfTheDriverIsNotNormal";
    $alarmInfo{"A206007A"} = "TheCommunicationStateOfTheDriverIsNotNormal";
    $alarmInfo{"A206007B"} = "SCHETheTemperatureIsNotStandbyOrStabilizedStatus,OrSetpointIsOutOfRecommendedRange";
    $alarmInfo{"A206007B"} = "TheTemperatureIsNotStandbyOrStabilizedStatus,OrSetpointIsOutOfRecommendedRange";
    $alarmInfo{"A206007C"} = "SCHETheSpecialRecipeSuchAsAPurge)CouldNotBeLoaded";
    $alarmInfo{"A206007C"} = "TheSpecialRecipeSuchAsAPurge)CouldNotBeLoaded";
    $alarmInfo{"A206007D"} = "GVOpenIsDisable";
    $alarmInfo{"A206007D"} = "SCHEGVOpenIsDisable";
    $alarmInfo{"A3060001"} = "TheCommunicationWithTMCWasDisconnected";
    $alarmInfo{"A3060002"} = "TheCommunicationWithPMC1WasDisconnected";
    $alarmInfo{"A3060003"} = "TheCommunicationWithPMC2WasDisconnected";
    $alarmInfo{"A3060004"} = "TheCommunicationWithPMC3WasDisconnected";
    $alarmInfo{"A3060005"} = "TheCommunicationWithPMC4WasDisconnected";
    $alarmInfo{"A3060006"} = "TheCommunicationWithPMC5WasDisconnected";
    $alarmInfo{"A7060001"} = "TheStatusUpdateWithTMCWasDisconnected";
    $alarmInfo{"A7060002"} = "TheStatusUpdateWithPMC1WasDisconnected";
    $alarmInfo{"A7060003"} = "TheStatusUpdateWithPMC2WasDisconnected";
    $alarmInfo{"A7060004"} = "TheStatusUpdateWithPMC3WasDisconnected";
    $alarmInfo{"A7060005"} = "TheStatusUpdateWithPMC4WasDisconnected";
    $alarmInfo{"A7060006"} = "TheStatusUpdateWithPMC5WasDisconnected";
    $alarmInfo{"A8060001"} = "UnknownErrorOccurredInCAP";
    $alarmInfo{"A8060002"} = "UnknownErrorOccurredInRC1ForCAP";
    $alarmInfo{"A8060003"} = "UnknownErrorOccurredInRC2ForCAP";
    $alarmInfo{"A8060004"} = "UnknownErrorOccurredInRC3ForCAP";
    $alarmInfo{"A8060005"} = "UnknownErrorOccurredInRC4ForCAP";
    $alarmInfo{"A010100"} = "ReactorAlarmRC1ABCleared";
    $alarmInfo{"A010101"} = "ReactorAlarmRC1ABDetected";
    $alarmInfo{"A010200"} = "ReactorAlarmRC1HDCleared";
    $alarmInfo{"A010201"} = "ReactorAlarmRC1HDDetected";
    $alarmInfo{"A010300"} = "ReactorAlarmRC1ALCleared";
    $alarmInfo{"A010301"} = "ReactorAlarmRC1ALDetected";
    $alarmInfo{"A010400"} = "ReactorAlarmRC1SFCleared";
    $alarmInfo{"A010401"} = "ReactorAlarmRC1SFDetected";
    $alarmInfo{"A010500"} = "ReactorAlarmRC1Forced1Cleared";
    $alarmInfo{"A010501"} = "ReactorAlarmRC1Forced1Detected";
    $alarmInfo{"A010600"} = "ReactorAlarmRC1Forced2Cleared";
    $alarmInfo{"A010601"} = "ReactorAlarmRC1Forced2Detected";
    $alarmInfo{"A010700"} = "ReactorAlarmRC1SafetyLatchCleared";
    $alarmInfo{"A010701"} = "ReactorAlarmRC1SafetyLatchDetected";
    $alarmInfo{"A020100"} = "ReactorAlarmRC2ABCleared";
    $alarmInfo{"A020101"} = "ReactorAlarmRC2ABDetected";
    $alarmInfo{"A020200"} = "ReactorAlarmRC2HDCleared";
    $alarmInfo{"A020201"} = "ReactorAlarmRC2HDDetected";
    $alarmInfo{"A020300"} = "ReactorAlarmRC2ALCleared";
    $alarmInfo{"A020301"} = "ReactorAlarmRC2ALDetected";
    $alarmInfo{"A020400"} = "ReactorAlarmRC2SFCleared";
    $alarmInfo{"A020401"} = "ReactorAlarmRC2SFDetected";
    $alarmInfo{"A020500"} = "ReactorAlarmRC2Forced1Cleared";
    $alarmInfo{"A020501"} = "ReactorAlarmRC2Forced1Detected";
    $alarmInfo{"A020600"} = "ReactorAlarmRC2Forced2Cleared";
    $alarmInfo{"A020601"} = "ReactorAlarmRC2Forced2Detected";
    $alarmInfo{"A020700"} = "ReactorAlarmRC2SafetyLatchCleared";
    $alarmInfo{"A020701"} = "ReactorAlarmRC2SafetyLatchDetected";
    $alarmInfo{"A030100"} = "ReactorAlarmRC3ABCleared";
    $alarmInfo{"A030101"} = "ReactorAlarmRC3ABDetected";
    $alarmInfo{"A030200"} = "ReactorAlarmRC3HDCleared";
    $alarmInfo{"A030201"} = "ReactorAlarmRC3HDDetected";
    $alarmInfo{"A030300"} = "ReactorAlarmRC3ALCleared";
    $alarmInfo{"A030301"} = "ReactorAlarmRC3ALDetected";
    $alarmInfo{"A030400"} = "ReactorAlarmRC3SFCleared";
    $alarmInfo{"A030401"} = "ReactorAlarmRC3SFDetected";
    $alarmInfo{"A030500"} = "ReactorAlarmRC3Forced1Cleared";
    $alarmInfo{"A030501"} = "ReactorAlarmRC3Forced1Detected";
    $alarmInfo{"A030600"} = "ReactorAlarmRC3Forced2Cleared";
    $alarmInfo{"A030601"} = "ReactorAlarmRC3Forced2Detected";
    $alarmInfo{"A030700"} = "ReactorAlarmRC3SafetyLatchCleared";
    $alarmInfo{"A030701"} = "ReactorAlarmRC3SafetyLatchDetected";
    $alarmInfo{"A040100"} = "ReactorAlarmRC4ABCleared";
    $alarmInfo{"A040101"} = "ReactorAlarmRC4ABDetected";
    $alarmInfo{"A040200"} = "ReactorAlarmRC4HDCleared";
    $alarmInfo{"A040201"} = "ReactorAlarmRC4HDDetected";
    $alarmInfo{"A040300"} = "ReactorAlarmRC4ALCleared";
    $alarmInfo{"A040301"} = "ReactorAlarmRC4ALDetected";
    $alarmInfo{"A040400"} = "ReactorAlarmRC4SFCleared";
    $alarmInfo{"A040401"} = "ReactorAlarmRC4SFDetected";
    $alarmInfo{"A040500"} = "ReactorAlarmRC4Forced1Cleared";
    $alarmInfo{"A040501"} = "ReactorAlarmRC4Forced1Detected";
    $alarmInfo{"A040600"} = "ReactorAlarmRC4Forced2Cleared";
    $alarmInfo{"A040601"} = "ReactorAlarmRC4Forced2Detected";
    $alarmInfo{"A040700"} = "ReactorAlarmRC4SafetyLatchCleared";
    $alarmInfo{"A040701"} = "ReactorAlarmRC4SafetyLatchDetected";
    $alarmInfo{"A050100"} = "ReactorAlarmRC5ABCleared";
    $alarmInfo{"A050101"} = "ReactorAlarmRC5ABDetected";
    $alarmInfo{"A050200"} = "ReactorAlarmRC5HDCleared";
    $alarmInfo{"A050201"} = "ReactorAlarmRC5HDDetected";
    $alarmInfo{"A050300"} = "ReactorAlarmRC5ALCleared";
    $alarmInfo{"A050301"} = "ReactorAlarmRC5ALDetected";
    $alarmInfo{"A050400"} = "ReactorAlarmRC5SFCleared";
    $alarmInfo{"A050401"} = "ReactorAlarmRC5SFDetected";
    $alarmInfo{"A050500"} = "ReactorAlarmRC5Forced1Cleared";
    $alarmInfo{"A050501"} = "ReactorAlarmRC5Forced1Detected";
    $alarmInfo{"A050600"} = "ReactorAlarmRC5Forced2Cleared";
    $alarmInfo{"A050601"} = "ReactorAlarmRC5Forced2Detected";
    $alarmInfo{"A050700"} = "ReactorAlarmRC5SafetyLatchCleared";
    $alarmInfo{"A050701"} = "ReactorAlarmRC5SafetyLatchDetected";
    $alarmInfo{"A0600050"} = "MAINProcessWATCHALARMHasEndedClr";
    $alarmInfo{"A0600051"} = "MAINProcessWATCHALARMHasEndedDet";
    $alarmInfo{"A2600680"} = "SchedulerFFUStatusAlarmClr";
    $alarmInfo{"A2600681"} = "SchedulerFFUStatusAlarmDet";
    $alarmInfo{"A26006b0"} = "SchedulerIonizerStatusAlarmClr";
    $alarmInfo{"A26006b1"} = "SchedulerIonizerStatusAlarmDet";
    $alarmInfo{"A26006e0"} = "SchedulerAnAlarmHasOccurredClr";
    $alarmInfo{"A26006e1"} = "SchedulerAnAlarmHasOccurredDet";
    $alarmInfo{"B010100"} = "ReactorAlarmRC1PMLimit1OverCleared";
    $alarmInfo{"B010101"} = "ReactorAlarmRC1PMLimit1OverDetected";
    $alarmInfo{"B010200"} = "ReactorAlarmRC1PMLimit2OverCleared";
    $alarmInfo{"B010201"} = "ReactorAlarmRC1PMLimit2OverDetected";
    $alarmInfo{"B010300"} = "ReactorAlarmRC1PMLimit3OverCleared";
    $alarmInfo{"B010301"} = "ReactorAlarmRC1PMLimit3OverDetected";
    $alarmInfo{"B010400"} = "ReactorAlarmRC1PMLimit4OverCleared";
    $alarmInfo{"B010401"} = "ReactorAlarmRC1PMLimit4OverDetected";
    $alarmInfo{"B010500"} = "ReactorAlarmRC1PMLimit5OverCleared";
    $alarmInfo{"B010501"} = "ReactorAlarmRC1PMLimit5OverDetected";
    $alarmInfo{"B010600"} = "ReactorAlarmRC1PMLimit6OverCleared";
    $alarmInfo{"B010601"} = "ReactorAlarmRC1PMLimit6OverDetected";
    $alarmInfo{"B010700"} = "ReactorAlarmRC1PMLimit7OverCleared";
    $alarmInfo{"B010701"} = "ReactorAlarmRC1PMLimit7OverDetected";
    $alarmInfo{"B010800"} = "ReactorAlarmRC1PMLimit8OverCleared";
    $alarmInfo{"B010801"} = "ReactorAlarmRC1PMLimit8OverDetected";
    $alarmInfo{"B010900"} = "ReactorAlarmRC1PMLimit9OverCleared";
    $alarmInfo{"B010901"} = "ReactorAlarmRC1PMLimit9OverDetected";
    $alarmInfo{"B010a00"} = "ReactorAlarmRC1PMLimit10OverCleared";
    $alarmInfo{"B010a01"} = "ReactorAlarmRC1PMLimit10OverDetected";
    $alarmInfo{"B010b00"} = "ReactorAlarmRC1PMLimit11OverCleared";
    $alarmInfo{"B010b01"} = "ReactorAlarmRC1PMLimit11OverDetected";
    $alarmInfo{"B010c00"} = "ReactorAlarmRC1PMLimit12OverCleared";
    $alarmInfo{"B010c01"} = "ReactorAlarmRC1PMLimit12OverDetected";
    $alarmInfo{"B010d00"} = "ReactorAlarmRC1PMLimit13OverCleared";
    $alarmInfo{"B010d01"} = "ReactorAlarmRC1PMLimit13OverDetected";
    $alarmInfo{"B010e00"} = "ReactorAlarmRC1PMLimit14OverCleared";
    $alarmInfo{"B010e01"} = "ReactorAlarmRC1PMLimit14OverDetected";
    $alarmInfo{"B010f00"} = "ReactorAlarmRC1PMLimit15OverCleared";
    $alarmInfo{"B010f01"} = "ReactorAlarmRC1PMLimit15OverDetected";
    $alarmInfo{"B011000"} = "ReactorAlarmRC1PMLimit16OverCleared";
    $alarmInfo{"B011001"} = "ReactorAlarmRC1PMLimit16OverDetected";
    $alarmInfo{"B011100"} = "ReactorAlarmRC1PMLimit17OverCleared";
    $alarmInfo{"B011101"} = "ReactorAlarmRC1PMLimit17OverDetected";
    $alarmInfo{"B011200"} = "ReactorAlarmRC1PMLimit18OverCleared";
    $alarmInfo{"B011201"} = "ReactorAlarmRC1PMLimit18OverDetected";
    $alarmInfo{"B011300"} = "ReactorAlarmRC1PMLimit19OverCleared";
    $alarmInfo{"B011301"} = "ReactorAlarmRC1PMLimit19OverDetected";
    $alarmInfo{"B011400"} = "ReactorAlarmRC1PMLimit20OverCleared";
    $alarmInfo{"B011401"} = "ReactorAlarmRC1PMLimit20OverDetected";
    $alarmInfo{"B018100"} = "ReactorAlarmRC1PMDOLimitOverCleared";
    $alarmInfo{"B018101"} = "ReactorAlarmRC1PMDOLimitOverDetected";
    $alarmInfo{"B018200"} = "ReactorAlarmRC1PMRFLimitOverCleared";
    $alarmInfo{"B018201"} = "ReactorAlarmRC1PMRFLimitOverDetected";
    $alarmInfo{"B018300"} = "ReactorAlarmRC1PMThicknessLimitOverCleared";
    $alarmInfo{"B018301"} = "ReactorAlarmRC1PMThicknessLimitOverDetected";
    $alarmInfo{"B020100"} = "ReactorAlarmRC2PMLimit1OverCleared";
    $alarmInfo{"B020101"} = "ReactorAlarmRC2PMLimit1OverDetected";
    $alarmInfo{"B020200"} = "ReactorAlarmRC2PMLimit2OverCleared";
    $alarmInfo{"B020201"} = "ReactorAlarmRC2PMLimit2OverDetected";
    $alarmInfo{"B020300"} = "ReactorAlarmRC2PMLimit3OverCleared";
    $alarmInfo{"B020301"} = "ReactorAlarmRC2PMLimit3OverDetected";
    $alarmInfo{"B020400"} = "ReactorAlarmRC2PMLimit4OverCleared";
    $alarmInfo{"B020401"} = "ReactorAlarmRC2PMLimit4OverDetected";
    $alarmInfo{"B020500"} = "ReactorAlarmRC2PMLimit5OverCleared";
    $alarmInfo{"B020501"} = "ReactorAlarmRC2PMLimit5OverDetected";
    $alarmInfo{"B020600"} = "ReactorAlarmRC2PMLimit6OverCleared";
    $alarmInfo{"B020601"} = "ReactorAlarmRC2PMLimit6OverDetected";
    $alarmInfo{"B020700"} = "ReactorAlarmRC2PMLimit7OverCleared";
    $alarmInfo{"B020701"} = "ReactorAlarmRC2PMLimit7OverDetected";
    $alarmInfo{"B020800"} = "ReactorAlarmRC2PMLimit8OverCleared";
    $alarmInfo{"B020801"} = "ReactorAlarmRC2PMLimit8OverDetected";
    $alarmInfo{"B020900"} = "ReactorAlarmRC2PMLimit9OverCleared";
    $alarmInfo{"B020901"} = "ReactorAlarmRC2PMLimit9OverDetected";
    $alarmInfo{"B020a00"} = "ReactorAlarmRC2PMLimit10OverCleared";
    $alarmInfo{"B020a01"} = "ReactorAlarmRC2PMLimit10OverDetected";
    $alarmInfo{"B020b00"} = "ReactorAlarmRC2PMLimit11OverCleared";
    $alarmInfo{"B020b01"} = "ReactorAlarmRC2PMLimit11OverDetected";
    $alarmInfo{"B020c00"} = "ReactorAlarmRC2PMLimit12OverCleared";
    $alarmInfo{"B020c01"} = "ReactorAlarmRC2PMLimit12OverDetected";
    $alarmInfo{"B020d00"} = "ReactorAlarmRC2PMLimit13OverCleared";
    $alarmInfo{"B020d01"} = "ReactorAlarmRC2PMLimit13OverDetected";
    $alarmInfo{"B020e00"} = "ReactorAlarmRC2PMLimit14OverCleared";
    $alarmInfo{"B020e01"} = "ReactorAlarmRC2PMLimit14OverDetected";
    $alarmInfo{"B020f00"} = "ReactorAlarmRC2PMLimit15OverCleared";
    $alarmInfo{"B020f01"} = "ReactorAlarmRC2PMLimit15OverDetected";
    $alarmInfo{"B021000"} = "ReactorAlarmRC2PMLimit16OverCleared";
    $alarmInfo{"B021001"} = "ReactorAlarmRC2PMLimit16OverDetected";
    $alarmInfo{"B021100"} = "ReactorAlarmRC2PMLimit17OverCleared";
    $alarmInfo{"B021101"} = "ReactorAlarmRC2PMLimit17OverDetected";
    $alarmInfo{"B021200"} = "ReactorAlarmRC2PMLimit18OverCleared";
    $alarmInfo{"B021201"} = "ReactorAlarmRC2PMLimit18OverDetected";
    $alarmInfo{"B021300"} = "ReactorAlarmRC2PMLimit19OverCleared";
    $alarmInfo{"B021301"} = "ReactorAlarmRC2PMLimit19OverDetected";
    $alarmInfo{"B021400"} = "ReactorAlarmRC2PMLimit20OverCleared";
    $alarmInfo{"B021401"} = "ReactorAlarmRC2PMLimit20OverDetected";
    $alarmInfo{"B028100"} = "ReactorAlarmRC2PMDOLimitOverCleared";
    $alarmInfo{"B028101"} = "ReactorAlarmRC2PMDOLimitOverDetected";
    $alarmInfo{"B028200"} = "ReactorAlarmRC2PMRFLimitOverCleared";
    $alarmInfo{"B028201"} = "ReactorAlarmRC2PMRFLimitOverDetected";
    $alarmInfo{"B028300"} = "ReactorAlarmRC2PMThicknessLimitOverCleared";
    $alarmInfo{"B028301"} = "ReactorAlarmRC2PMThicknessLimitOverDetected";
    $alarmInfo{"B030100"} = "ReactorAlarmRC3PMLimit1OverCleared";
    $alarmInfo{"B030101"} = "ReactorAlarmRC3PMLimit1OverDetected";
    $alarmInfo{"B030200"} = "ReactorAlarmRC3PMLimit2OverCleared";
    $alarmInfo{"B030201"} = "ReactorAlarmRC3PMLimit2OverDetected";
    $alarmInfo{"B030300"} = "ReactorAlarmRC3PMLimit3OverCleared";
    $alarmInfo{"B030301"} = "ReactorAlarmRC3PMLimit3OverDetected";
    $alarmInfo{"B030400"} = "ReactorAlarmRC3PMLimit4OverCleared";
    $alarmInfo{"B030401"} = "ReactorAlarmRC3PMLimit4OverDetected";
    $alarmInfo{"B030500"} = "ReactorAlarmRC3PMLimit5OverCleared";
    $alarmInfo{"B030501"} = "ReactorAlarmRC3PMLimit5OverDetected";
    $alarmInfo{"B030600"} = "ReactorAlarmRC3PMLimit6OverCleared";
    $alarmInfo{"B030601"} = "ReactorAlarmRC3PMLimit6OverDetected";
    $alarmInfo{"B030700"} = "ReactorAlarmRC3PMLimit7OverCleared";
    $alarmInfo{"B030701"} = "ReactorAlarmRC3PMLimit7OverDetected";
    $alarmInfo{"B030800"} = "ReactorAlarmRC3PMLimit8OverCleared";
    $alarmInfo{"B030801"} = "ReactorAlarmRC3PMLimit8OverDetected";
    $alarmInfo{"B030900"} = "ReactorAlarmRC3PMLimit9OverCleared";
    $alarmInfo{"B030901"} = "ReactorAlarmRC3PMLimit9OverDetected";
    $alarmInfo{"B030a00"} = "ReactorAlarmRC3PMLimit10OverCleared";
    $alarmInfo{"B030a01"} = "ReactorAlarmRC3PMLimit10OverDetected";
    $alarmInfo{"B030b00"} = "ReactorAlarmRC3PMLimit11OverCleared";
    $alarmInfo{"B030b01"} = "ReactorAlarmRC3PMLimit11OverDetected";
    $alarmInfo{"B030c00"} = "ReactorAlarmRC3PMLimit12OverCleared";
    $alarmInfo{"B030c01"} = "ReactorAlarmRC3PMLimit12OverDetected";
    $alarmInfo{"B030d00"} = "ReactorAlarmRC3PMLimit13OverCleared";
    $alarmInfo{"B030d01"} = "ReactorAlarmRC3PMLimit13OverDetected";
    $alarmInfo{"B030e00"} = "ReactorAlarmRC3PMLimit14OverCleared";
    $alarmInfo{"B030e01"} = "ReactorAlarmRC3PMLimit14OverDetected";
    $alarmInfo{"B030f00"} = "ReactorAlarmRC3PMLimit15OverCleared";
    $alarmInfo{"B030f01"} = "ReactorAlarmRC3PMLimit15OverDetected";
    $alarmInfo{"B031000"} = "ReactorAlarmRC3PMLimit16OverCleared";
    $alarmInfo{"B031001"} = "ReactorAlarmRC3PMLimit16OverDetected";
    $alarmInfo{"B031100"} = "ReactorAlarmRC3PMLimit17OverCleared";
    $alarmInfo{"B031101"} = "ReactorAlarmRC3PMLimit17OverDetected";
    $alarmInfo{"B031200"} = "ReactorAlarmRC3PMLimit18OverCleared";
    $alarmInfo{"B031201"} = "ReactorAlarmRC3PMLimit18OverDetected";
    $alarmInfo{"B031300"} = "ReactorAlarmRC3PMLimit19OverCleared";
    $alarmInfo{"B031301"} = "ReactorAlarmRC3PMLimit19OverDetected";
    $alarmInfo{"B031400"} = "ReactorAlarmRC3PMLimit20OverCleared";
    $alarmInfo{"B031401"} = "ReactorAlarmRC3PMLimit20OverDetected";
    $alarmInfo{"B038100"} = "ReactorAlarmRC3PMDOLimitOverCleared";
    $alarmInfo{"B038101"} = "ReactorAlarmRC3PMDOLimitOverDetected";
    $alarmInfo{"B038200"} = "ReactorAlarmRC3PMRFLimitOverCleared";
    $alarmInfo{"B038201"} = "ReactorAlarmRC3PMRFLimitOverDetected";
    $alarmInfo{"B038300"} = "ReactorAlarmRC3PMThicknessLimitOverCleared";
    $alarmInfo{"B038301"} = "ReactorAlarmRC3PMThicknessLimitOverDetected";
    $alarmInfo{"B040100"} = "ReactorAlarmRC4PMLimit1OverCleared";
    $alarmInfo{"B040101"} = "ReactorAlarmRC4PMLimit1OverDetected";
    $alarmInfo{"B040200"} = "ReactorAlarmRC4PMLimit2OverCleared";
    $alarmInfo{"B040201"} = "ReactorAlarmRC4PMLimit2OverDetected";
    $alarmInfo{"B040300"} = "ReactorAlarmRC4PMLimit3OverCleared";
    $alarmInfo{"B040301"} = "ReactorAlarmRC4PMLimit3OverDetected";
    $alarmInfo{"B040400"} = "ReactorAlarmRC4PMLimit4OverCleared";
    $alarmInfo{"B040401"} = "ReactorAlarmRC4PMLimit4OverDetected";
    $alarmInfo{"B040500"} = "ReactorAlarmRC4PMLimit5OverCleared";
    $alarmInfo{"B040501"} = "ReactorAlarmRC4PMLimit5OverDetected";
    $alarmInfo{"B040600"} = "ReactorAlarmRC4PMLimit6OverCleared";
    $alarmInfo{"B040601"} = "ReactorAlarmRC4PMLimit6OverDetected";
    $alarmInfo{"B040700"} = "ReactorAlarmRC4PMLimit7OverCleared";
    $alarmInfo{"B040701"} = "ReactorAlarmRC4PMLimit7OverDetected";
    $alarmInfo{"B040800"} = "ReactorAlarmRC4PMLimit8OverCleared";
    $alarmInfo{"B040801"} = "ReactorAlarmRC4PMLimit8OverDetected";
    $alarmInfo{"B040900"} = "ReactorAlarmRC4PMLimit9OverCleared";
    $alarmInfo{"B040901"} = "ReactorAlarmRC4PMLimit9OverDetected";
    $alarmInfo{"B040a00"} = "ReactorAlarmRC4PMLimit10OverCleared";
    $alarmInfo{"B040a01"} = "ReactorAlarmRC4PMLimit10OverDetected";
    $alarmInfo{"B040b00"} = "ReactorAlarmRC4PMLimit11OverCleared";
    $alarmInfo{"B040b01"} = "ReactorAlarmRC4PMLimit11OverDetected";
    $alarmInfo{"B040c00"} = "ReactorAlarmRC4PMLimit12OverCleared";
    $alarmInfo{"B040c01"} = "ReactorAlarmRC4PMLimit12OverDetected";
    $alarmInfo{"B040d00"} = "ReactorAlarmRC4PMLimit13OverCleared";
    $alarmInfo{"B040d01"} = "ReactorAlarmRC4PMLimit13OverDetected";
    $alarmInfo{"B040e00"} = "ReactorAlarmRC4PMLimit14OverCleared";
    $alarmInfo{"B040e01"} = "ReactorAlarmRC4PMLimit14OverDetected";
    $alarmInfo{"B040f00"} = "ReactorAlarmRC4PMLimit15OverCleared";
    $alarmInfo{"B040f01"} = "ReactorAlarmRC4PMLimit15OverDetected";
    $alarmInfo{"B041000"} = "ReactorAlarmRC4PMLimit16OverCleared";
    $alarmInfo{"B041001"} = "ReactorAlarmRC4PMLimit16OverDetected";
    $alarmInfo{"B041100"} = "ReactorAlarmRC4PMLimit17OverCleared";
    $alarmInfo{"B041101"} = "ReactorAlarmRC4PMLimit17OverDetected";
    $alarmInfo{"B041200"} = "ReactorAlarmRC4PMLimit18OverCleared";
    $alarmInfo{"B041201"} = "ReactorAlarmRC4PMLimit18OverDetected";
    $alarmInfo{"B041300"} = "ReactorAlarmRC4PMLimit19OverCleared";
    $alarmInfo{"B041301"} = "ReactorAlarmRC4PMLimit19OverDetected";
    $alarmInfo{"B041400"} = "ReactorAlarmRC4PMLimit20OverCleared";
    $alarmInfo{"B041401"} = "ReactorAlarmRC4PMLimit20OverDetected";
    $alarmInfo{"B048100"} = "ReactorAlarmRC4PMDOLimitOverCleared";
    $alarmInfo{"B048101"} = "ReactorAlarmRC4PMDOLimitOverDetected";
    $alarmInfo{"B048200"} = "ReactorAlarmRC4PMRFLimitOverCleared";
    $alarmInfo{"B048201"} = "ReactorAlarmRC4PMRFLimitOverDetected";
    $alarmInfo{"B048300"} = "ReactorAlarmRC4PMThicknessLimitOverCleared";
    $alarmInfo{"B048301"} = "ReactorAlarmRC4PMThicknessLimitOverDetected";
    $alarmInfo{"B050100"} = "ReactorAlarmRC5PMLimit1OverCleared";
    $alarmInfo{"B050101"} = "ReactorAlarmRC5PMLimit1OverDetected";
    $alarmInfo{"B050200"} = "ReactorAlarmRC5PMLimit2OverCleared";
    $alarmInfo{"B050201"} = "ReactorAlarmRC5PMLimit2OverDetected";
    $alarmInfo{"B050300"} = "ReactorAlarmRC5PMLimit3OverCleared";
    $alarmInfo{"B050301"} = "ReactorAlarmRC5PMLimit3OverDetected";
    $alarmInfo{"B050400"} = "ReactorAlarmRC5PMLimit4OverCleared";
    $alarmInfo{"B050401"} = "ReactorAlarmRC5PMLimit4OverDetected";
    $alarmInfo{"B050500"} = "ReactorAlarmRC5PMLimit5OverCleared";
    $alarmInfo{"B050501"} = "ReactorAlarmRC5PMLimit5OverDetected";
    $alarmInfo{"B050600"} = "ReactorAlarmRC5PMLimit6OverCleared";
    $alarmInfo{"B050601"} = "ReactorAlarmRC5PMLimit6OverDetected";
    $alarmInfo{"B050700"} = "ReactorAlarmRC5PMLimit7OverCleared";
    $alarmInfo{"B050701"} = "ReactorAlarmRC5PMLimit7OverDetected";
    $alarmInfo{"B050800"} = "ReactorAlarmRC5PMLimit8OverCleared";
    $alarmInfo{"B050801"} = "ReactorAlarmRC5PMLimit8OverDetected";
    $alarmInfo{"B050900"} = "ReactorAlarmRC5PMLimit9OverCleared";
    $alarmInfo{"B050901"} = "ReactorAlarmRC5PMLimit9OverDetected";
    $alarmInfo{"B050a00"} = "ReactorAlarmRC5PMLimit10OverCleared";
    $alarmInfo{"B050a01"} = "ReactorAlarmRC5PMLimit10OverDetected";
    $alarmInfo{"B050b00"} = "ReactorAlarmRC5PMLimit11OverCleared";
    $alarmInfo{"B050b01"} = "ReactorAlarmRC5PMLimit11OverDetected";
    $alarmInfo{"B050c00"} = "ReactorAlarmRC5PMLimit12OverCleared";
    $alarmInfo{"B050c01"} = "ReactorAlarmRC5PMLimit12OverDetected";
    $alarmInfo{"B050d00"} = "ReactorAlarmRC5PMLimit13OverCleared";
    $alarmInfo{"B050d01"} = "ReactorAlarmRC5PMLimit13OverDetected";
    $alarmInfo{"B050e00"} = "ReactorAlarmRC5PMLimit14OverCleared";
    $alarmInfo{"B050e01"} = "ReactorAlarmRC5PMLimit14OverDetected";
    $alarmInfo{"B050f00"} = "ReactorAlarmRC5PMLimit15OverCleared";
    $alarmInfo{"B050f01"} = "ReactorAlarmRC5PMLimit15OverDetected";
    $alarmInfo{"B051000"} = "ReactorAlarmRC5PMLimit16OverCleared";
    $alarmInfo{"B051001"} = "ReactorAlarmRC5PMLimit16OverDetected";
    $alarmInfo{"B051100"} = "ReactorAlarmRC5PMLimit17OverCleared";
    $alarmInfo{"B051101"} = "ReactorAlarmRC5PMLimit17OverDetected";
    $alarmInfo{"B051200"} = "ReactorAlarmRC5PMLimit18OverCleared";
    $alarmInfo{"B051201"} = "ReactorAlarmRC5PMLimit18OverDetected";
    $alarmInfo{"B051300"} = "ReactorAlarmRC5PMLimit19OverCleared";
    $alarmInfo{"B051301"} = "ReactorAlarmRC5PMLimit19OverDetected";
    $alarmInfo{"B051400"} = "ReactorAlarmRC5PMLimit20OverCleared";
    $alarmInfo{"B051401"} = "ReactorAlarmRC5PMLimit20OverDetected";
    $alarmInfo{"B058100"} = "ReactorAlarmRC5PMDOLimitOverCleared";
    $alarmInfo{"B058101"} = "ReactorAlarmRC5PMDOLimitOverDetected";
    $alarmInfo{"B058200"} = "ReactorAlarmRC5PMRFLimitOverCleared";
    $alarmInfo{"B058201"} = "ReactorAlarmRC5PMRFLimitOverDetected";
    $alarmInfo{"B058300"} = "ReactorAlarmRC5PMThicknessLimitOverCleared";
    $alarmInfo{"B058301"} = "ReactorAlarmRC5PMThicknessLimitOverDetected";
    $alarmInfo{"B070100"} = "LLC1AlarmCountLimit1OverCleared";
    $alarmInfo{"B070101"} = "LLC1AlarmCountLimit1OverDetected";
    $alarmInfo{"B070200"} = "LLC1AlarmCountLimit2OverCleared";
    $alarmInfo{"B070201"} = "LLC1AlarmCountLimit2OverDetected";
    $alarmInfo{"B070300"} = "LLC1AlarmCountLimit3OverCleared";
    $alarmInfo{"B070301"} = "LLC1AlarmCountLimit3OverDetected";
    $alarmInfo{"B070400"} = "LLC1AlarmCountLimit4OverCleared";
    $alarmInfo{"B070401"} = "LLC1AlarmCountLimit4OverDetected";
    $alarmInfo{"B070500"} = "LLC1AlarmCountLimit5OverCleared";
    $alarmInfo{"B070501"} = "LLC1AlarmCountLimit5OverDetected";
    $alarmInfo{"B070600"} = "LLC1AlarmCountLimit6OverCleared";
    $alarmInfo{"B070601"} = "LLC1AlarmCountLimit6OverDetected";
    $alarmInfo{"B070700"} = "LLC1AlarmCountLimit7OverCleared";
    $alarmInfo{"B070701"} = "LLC1AlarmCountLimit7OverDetected";
    $alarmInfo{"B070800"} = "LLC1AlarmCountLimit8OverCleared";
    $alarmInfo{"B070801"} = "LLC1AlarmCountLimit8OverDetected";
    $alarmInfo{"B070900"} = "LLC1AlarmCountLimit9OverCleared";
    $alarmInfo{"B070901"} = "LLC1AlarmCountLimit9OverDetected";
    $alarmInfo{"B070a00"} = "LLC1AlarmCountLimit10OverCleared";
    $alarmInfo{"B070a01"} = "LLC1AlarmCountLimit10OverDetected";
    $alarmInfo{"B070b00"} = "LLC1AlarmCountLimit11OverCleared";
    $alarmInfo{"B070b01"} = "LLC1AlarmCountLimit11OverDetected";
    $alarmInfo{"B070c00"} = "LLC1AlarmCountLimit12OverCleared";
    $alarmInfo{"B070c01"} = "LLC1AlarmCountLimit12OverDetected";
    $alarmInfo{"B070d00"} = "LLC1AlarmCountLimit13OverCleared";
    $alarmInfo{"B070d01"} = "LLC1AlarmCountLimit13OverDetected";
    $alarmInfo{"B070e00"} = "LLC1AlarmCountLimit14OverCleared";
    $alarmInfo{"B070e01"} = "LLC1AlarmCountLimit14OverDetected";
    $alarmInfo{"B070f00"} = "LLC1AlarmCountLimit15OverCleared";
    $alarmInfo{"B070f01"} = "LLC1AlarmCountLimit15OverDetected";
    $alarmInfo{"B071000"} = "LLC1AlarmCountLimit16OverCleared";
    $alarmInfo{"B071001"} = "LLC1AlarmCountLimit16OverDetected";
    $alarmInfo{"B071100"} = "LLC1AlarmCountLimit17OverCleared";
    $alarmInfo{"B071101"} = "LLC1AlarmCountLimit17OverDetected";
    $alarmInfo{"B071200"} = "LLC1AlarmCountLimit18OverCleared";
    $alarmInfo{"B071201"} = "LLC1AlarmCountLimit18OverDetected";
    $alarmInfo{"B071300"} = "LLC1AlarmCountLimit19OverCleared";
    $alarmInfo{"B071301"} = "LLC1AlarmCountLimit19OverDetected";
    $alarmInfo{"B071400"} = "LLC1AlarmCountLimit20OverCleared";
    $alarmInfo{"B071401"} = "LLC1AlarmCountLimit20OverDetected";
    $alarmInfo{"B080100"} = "LLC2AlarmCountLimit1OverCleared";
    $alarmInfo{"B080101"} = "LLC2AlarmCountLimit1OverDetected";
    $alarmInfo{"B080200"} = "LLC2AlarmCountLimit2OverCleared";
    $alarmInfo{"B080201"} = "LLC2AlarmCountLimit2OverDetected";
    $alarmInfo{"B080300"} = "LLC2AlarmCountLimit3OverCleared";
    $alarmInfo{"B080301"} = "LLC2AlarmCountLimit3OverDetected";
    $alarmInfo{"B080400"} = "LLC2AlarmCountLimit4OverCleared";
    $alarmInfo{"B080401"} = "LLC2AlarmCountLimit4OverDetected";
    $alarmInfo{"B080500"} = "LLC2AlarmCountLimit5OverCleared";
    $alarmInfo{"B080501"} = "LLC2AlarmCountLimit5OverDetected";
    $alarmInfo{"B080600"} = "LLC2AlarmCountLimit6OverCleared";
    $alarmInfo{"B080601"} = "LLC2AlarmCountLimit6OverDetected";
    $alarmInfo{"B080700"} = "LLC2AlarmCountLimit7OverCleared";
    $alarmInfo{"B080701"} = "LLC2AlarmCountLimit7OverDetected";
    $alarmInfo{"B080800"} = "LLC2AlarmCountLimit8OverCleared";
    $alarmInfo{"B080801"} = "LLC2AlarmCountLimit8OverDetected";
    $alarmInfo{"B080900"} = "LLC2AlarmCountLimit9OverCleared";
    $alarmInfo{"B080901"} = "LLC2AlarmCountLimit9OverDetected";
    $alarmInfo{"B080a00"} = "LLC2AlarmCountLimit10OverCleared";
    $alarmInfo{"B080a01"} = "LLC2AlarmCountLimit10OverDetected";
    $alarmInfo{"B080b00"} = "LLC2AlarmCountLimit11OverCleared";
    $alarmInfo{"B080b01"} = "LLC2AlarmCountLimit11OverDetected";
    $alarmInfo{"B080c00"} = "LLC2AlarmCountLimit12OverCleared";
    $alarmInfo{"B080c01"} = "LLC2AlarmCountLimit12OverDetected";
    $alarmInfo{"B080d00"} = "LLC2AlarmCountLimit13OverCleared";
    $alarmInfo{"B080d01"} = "LLC2AlarmCountLimit13OverDetected";
    $alarmInfo{"B080e00"} = "LLC2AlarmCountLimit14OverCleared";
    $alarmInfo{"B080e01"} = "LLC2AlarmCountLimit14OverDetected";
    $alarmInfo{"B080f00"} = "LLC2AlarmCountLimit15OverCleared";
    $alarmInfo{"B080f01"} = "LLC2AlarmCountLimit15OverDetected";
    $alarmInfo{"B081000"} = "LLC2AlarmCountLimit16OverCleared";
    $alarmInfo{"B081001"} = "LLC2AlarmCountLimit16OverDetected";
    $alarmInfo{"B081100"} = "LLC2AlarmCountLimit17OverCleared";
    $alarmInfo{"B081101"} = "LLC2AlarmCountLimit17OverDetected";
    $alarmInfo{"B081200"} = "LLC2AlarmCountLimit18OverCleared";
    $alarmInfo{"B081201"} = "LLC2AlarmCountLimit18OverDetected";
    $alarmInfo{"B081300"} = "LLC2AlarmCountLimit19OverCleared";
    $alarmInfo{"B081301"} = "LLC2AlarmCountLimit19OverDetected";
    $alarmInfo{"B081400"} = "LLC2AlarmCountLimit20OverCleared";
    $alarmInfo{"B081401"} = "LLC2AlarmCountLimit20OverDetected";
    $alarmInfo{"B0b0100"} = "WHCAlarmCountLimit1OverCleared";
    $alarmInfo{"B0b0101"} = "WHCAlarmCountLimit1OverDetected";
    $alarmInfo{"B0b0200"} = "WHCAlarmCountLimit2OverCleared";
    $alarmInfo{"B0b0201"} = "WHCAlarmCountLimit2OverDetected";
    $alarmInfo{"B0b0300"} = "WHCAlarmCountLimit3OverCleared";
    $alarmInfo{"B0b0301"} = "WHCAlarmCountLimit3OverDetected";
    $alarmInfo{"B0b0400"} = "WHCAlarmCountLimit4OverCleared";
    $alarmInfo{"B0b0401"} = "WHCAlarmCountLimit4OverDetected";
    $alarmInfo{"B0b0500"} = "WHCAlarmCountLimit5OverCleared";
    $alarmInfo{"B0b0501"} = "WHCAlarmCountLimit5OverDetected";
    $alarmInfo{"B0b0600"} = "WHCAlarmCountLimit6OverCleared";
    $alarmInfo{"B0b0601"} = "WHCAlarmCountLimit6OverDetected";
    $alarmInfo{"B0b0700"} = "WHCAlarmCountLimit7OverCleared";
    $alarmInfo{"B0b0701"} = "WHCAlarmCountLimit7OverDetected";
    $alarmInfo{"B0b0800"} = "WHCAlarmCountLimit8OverCleared";
    $alarmInfo{"B0b0801"} = "WHCAlarmCountLimit8OverDetected";
    $alarmInfo{"B0b0900"} = "WHCAlarmCountLimit9OverCleared";
    $alarmInfo{"B0b0901"} = "WHCAlarmCountLimit9OverDetected";
    $alarmInfo{"B0b0a00"} = "WHCAlarmCountLimit10OverCleared";
    $alarmInfo{"B0b0a01"} = "WHCAlarmCountLimit10OverDetected";
    $alarmInfo{"B0b0b00"} = "WHCAlarmCountLimit11OverCleared";
    $alarmInfo{"B0b0b01"} = "WHCAlarmCountLimit11OverDetected";
    $alarmInfo{"B0b0c00"} = "WHCAlarmCountLimit12OverCleared";
    $alarmInfo{"B0b0c01"} = "WHCAlarmCountLimit12OverDetected";
    $alarmInfo{"B0b0d00"} = "WHCAlarmCountLimit13OverCleared";
    $alarmInfo{"B0b0d01"} = "WHCAlarmCountLimit13OverDetected";
    $alarmInfo{"B0b0e00"} = "WHCAlarmCountLimit14OverCleared";
    $alarmInfo{"B0b0e01"} = "WHCAlarmCountLimit14OverDetected";
    $alarmInfo{"B0b0f00"} = "WHCAlarmCountLimit15OverCleared";
    $alarmInfo{"B0b0f01"} = "WHCAlarmCountLimit15OverDetected";
    $alarmInfo{"B0b1000"} = "WHCAlarmCountLimit16OverCleared";
    $alarmInfo{"B0b1001"} = "WHCAlarmCountLimit16OverDetected";
    $alarmInfo{"B0b1100"} = "WHCAlarmCountLimit17OverCleared";
    $alarmInfo{"B0b1101"} = "WHCAlarmCountLimit17OverDetected";
    $alarmInfo{"B0b1200"} = "WHCAlarmCountLimit18OverCleared";
    $alarmInfo{"B0b1201"} = "WHCAlarmCountLimit18OverDetected";
    $alarmInfo{"B0b1300"} = "WHCAlarmCountLimit19OverCleared";
    $alarmInfo{"B0b1301"} = "WHCAlarmCountLimit19OverDetected";
    $alarmInfo{"B0b1400"} = "WHCAlarmCountLimit20OverCleared";
    $alarmInfo{"B0b1401"} = "WHCAlarmCountLimit20OverDetected";
    $alarmInfo{"C100000"} = "EquipmentAlarmCleared";
    $alarmInfo{"C100001"} = "EquipmentAlarmDetected";
}

sub GetModCodeDefinition {
    $modCode{"01"} = "ALL";
    $modCode{"10"} = "TM_ALL";
    $modCode{"11"} = "TM_FERBT";
    $modCode{"12"} = "TM_BERBT";
    $modCode{"13"} = "TM_LLRBL";
    $modCode{"14"} = "TM_LLRBR";
    $modCode{"15"} = "TM_SLIDE";
    $modCode{"16"} = "TM_LP1";
    $modCode{"17"} = "TM_LP2";
    $modCode{"18"} = "TM_LP3";
    $modCode{"19"} = "TM_LP4";
    $modCode{"1A"} = "TM_CID1";
    $modCode{"1B"} = "TM_CID2";
    $modCode{"1C"} = "TM_CID3";
    $modCode{"1D"} = "TM_CID4";
    $modCode{"1E"} = "TM_ALN";
    $modCode{"1F"} = "TM_MON";
    $modCode{"20"} = "TM_WHC";
    $modCode{"21"} = "TM_LLCL1(LLL)";
    $modCode{"22"} = "TM_LLCL2(LLL)";
    $modCode{"23"} = "TM_LLCR1(RLL)";
    $modCode{"24"} = "TM_LLCR2(RLL)";
    $modCode{"25"} = "TM_LLC";
    $modCode{"26"} = "TM_LLARML";
    $modCode{"27"} = "TM_LLARMR";
    $modCode{"28"} = "TM_LLALN1";
    $modCode{"29"} = "TM_LLALN2";
    $modCode{"2A"} = "UnknownSYN";
    $modCode{"2B"} = "UnknownSYN";
    $modCode{"2C"} = "UnknownSYN";
    $modCode{"2D"} = "TM_EFEM";
    $modCode{"30"} = "TM_GVFL1(GV1)";
    $modCode{"31"} = "TM_GVFL2(GV2)";
    $modCode{"32"} = "TM_GVFR1(GV3)";
    $modCode{"33"} = "TM_GVFR2(GV4)";
    $modCode{"34"} = "TM_GVB1(GV5)";
    $modCode{"35"} = "TM_GVB2(GV6)";
    $modCode{"36"} = "TM_GVB3(GV7)";
    $modCode{"37"} = "TM_GVB4(GV8)";
    $modCode{"38"} = "TM_UIO";
    $modCode{"39"} = "TM_GVB5";
    $modCode{"3A"} = "TM_LLELV1";
    $modCode{"3B"} = "TM_LLELV2";
    $modCode{"3C"} = "TM_ALLFR";
    $modCode{"3D"} = "TM_ALLBR";
    $modCode{"3E"} = "TM_ALLLL1";
    $modCode{"3F"} = "TM_ALLLL2";
    $modCode{"40"} = "PM1_ALL";
    $modCode{"41"} = "PM1_RC";
    $modCode{"42"} = "PM1_SS";
    $modCode{"43"} = "PM1_WL";
    $modCode{"44"} = "PM1_RCBF";
    $modCode{"45"} = "PM1_ALLBF";
    $modCode{"4A"} = "PM1_PCV";
    $modCode{"50"} = "PM2_ALL";
    $modCode{"51"} = "PM2_RC";
    $modCode{"52"} = "PM2_SS";
    $modCode{"53"} = "PM2_WL";
    $modCode{"54"} = "PM2_RCBF";
    $modCode{"55"} = "PM2_ALLBF";
    $modCode{"5A"} = "PM2_PCV";
    $modCode{"5B"} = "5B-EPI";
    $modCode{"60"} = "PM3_ALL";
    $modCode{"61"} = "PM3_RC";
    $modCode{"62"} = "PM3_SS";
    $modCode{"63"} = "PM3_WL";
    $modCode{"64"} = "PM3_RCBF";
    $modCode{"65"} = "PM3_ALLBF";
    $modCode{"6A"} = "PM3_PCV";
    $modCode{"6B"} = "6B-EPI";
    $modCode{"70"} = "PM4_ALL";
    $modCode{"71"} = "PM4_RC";
    $modCode{"72"} = "PM4_SS";
    $modCode{"73"} = "PM4_WL";
    $modCode{"74"} = "PM4_RCBF";
    $modCode{"75"} = "PM4_ALLBF";
    $modCode{"78"} = "79-EPI";
    $modCode{"7A"} = "PM4_PCV";
    $modCode{"7B"} = "7B-EPI";
    $modCode{"80"} = "PM5_ALL";
    $modCode{"81"} = "PM5_RC";
    $modCode{"82"} = "PM5_SS";
    $modCode{"83"} = "PM5_WL";
    $modCode{"84"} = "PM5_RCBF";
    $modCode{"85"} = "PM5_ALLBF";
    $modCode{"8A"} = "PM5_PCV";
    $modCode{"90"} = "TM_CST1";
    $modCode{"91"} = "TM_CST2";
    $modCode{"92"} = "TM_SPL";
    $modCode{"93"} = "TM_SPR";
    $modCode{"94"} = "TM_WID";
    $modCode{"96"} = "CODE96";
    $modCode{"97"} = "CODE97";
    $modCode{"A0"} = "PR_MAIN";
    $modCode{"A1"} = "PR_MMI";
    $modCode{"A2"} = "PR_SCHE";
    $modCode{"A3"} = "PR_MCIF";
    $modCode{"A4"} = "PR_WALARM";
    $modCode{"A5"} = "PR_PROCLOG";
    $modCode{"A6"} = "PR_CCU";
    $modCode{"A7"} = "PR_MCSH";
    $modCode{"A8"} = "PR_CAP";
    $modCode{"A9"} = "PR_TRANSLOG";
}

sub GetTMReportID {
    $TMReportID{"10,04,00,10,"} = "ALL:TMStartUp";
    $TMReportID{"10,05,00,10,"} = "ALL:TMFEWaferEndReport";
    $TMReportID{"10,05,00,40,"} = "ALL:TMFEWaferStateReport";
    $TMReportID{"10,05,00,70,"} = "ALL:TMFEWaferPreStateReport";
    $TMReportID{"10,05,00,11,"} = "ALL:TMBEWaferEndReport";
    $TMReportID{"10,05,00,41,"} = "ALL:TMBEWaferStateReport";
    $TMReportID{"10,05,00,71,"} = "ALL:TMBEWaferPreStateReport";
    $TMReportID{"10,05,01,01,"} = "ALL:TMWhcEndReport";
    $TMReportID{"10,05,01,02,"} = "ALL:TMLLLEndReport";
    $TMReportID{"10,05,01,03,"} = "ALL:TMLLL2EndReport";
    $TMReportID{"10,05,01,04,"} = "ALL:TMRLLEndReport";
    $TMReportID{"10,05,01,05,"} = "ALL:TMRLL2EndReport";
    $TMReportID{"10,05,02,00,"} = "ALL:TMALLEndReport";
    $TMReportID{"10,05,02,10,"} = "ALL:TMALLStateReport";
    $TMReportID{"10,05,02,20,"} = "ALL:TMALLPreStateReport";
    $TMReportID{"20,05,00,10,"} = "WHC:LLCControlPreStateReport";
    $TMReportID{"20,05,00,20,"} = "WHC:LLCControlStateReport";
    $TMReportID{"20,05,00,30,"} = "WHC:LLCPressPreStateReport";
    $TMReportID{"20,05,00,40,"} = "WHC:LLCPressStateReport";
    $TMReportID{"20,05,00,60,"} = "WHC:LLCEndStateReport";
    $TMReportID{"21,05,00,10,"} = "LLL:LLCControlPreStateReport";
    $TMReportID{"21,05,00,20,"} = "LLL:LLCControlStateReport";
    $TMReportID{"21,05,00,30,"} = "LLL:LLCPressPreStateReport";
    $TMReportID{"21,05,00,40,"} = "LLL:LLCPressStateReport";
    $TMReportID{"21,05,00,60,"} = "LLL:LLCEndStateReport";
    $TMReportID{"23,05,00,10,"} = "RLL:LLCControlPreStateReport";
    $TMReportID{"23,05,00,20,"} = "RLL:LLCControlStateReport";
    $TMReportID{"23,05,00,30,"} = "RLL:LLCPressPreStateReport";
    $TMReportID{"23,05,00,40,"} = "RLL:LLCPressStateReport";
    $TMReportID{"23,05,00,60,"} = "RLL:LLCEndStateReport";
    $TMReportID{"11,05,00,10,"} = "FERBPreStateReport";
    $TMReportID{"11,05,00,20,"} = "FERBStateReport";
    $TMReportID{"11,05,00,30,"} = "FERBEndReport";
    $TMReportID{"11,05,00,40,"} = "FERBPauseReport";
    $TMReportID{"12,05,00,10,"} = "BERBPreStateReport";
    $TMReportID{"12,05,00,20,"} = "BERBStateReport";
    $TMReportID{"12,05,00,30,"} = "BERBEndReport";
    $TMReportID{"12,05,00,40,"} = "BERBPauseReport";
    $TMReportID{"16,05,00,10,"} = "LP1:LPControlPreStateReport";
    $TMReportID{"16,05,00,20,"} = "LP1:LPControlStateReport";
    $TMReportID{"16,05,00,30,"} = "LP1:LPEndReport";
    $TMReportID{"16,05,00,40,"} = "LP1:LPFoupStateReport";
    $TMReportID{"16,05,00,50,"} = "LP1:LPAccessModeReport";
    $TMReportID{"16,05,00,60,"} = "LP1:LPCarrierIDReport";
    $TMReportID{"16,05,00,70,"} = "LP1:LPSlotMapReport";
    $TMReportID{"16,05,00,80,"} = "LP1:LPTransferPreStateReport";
    $TMReportID{"16,05,00,90,"} = "LP1:LPTransferStateReport";
    $TMReportID{"16,05,00,A0,"} = "LP1:LPTransferEndReport";
    $TMReportID{"16,05,00,B0,"} = "LP1:LPCIDWriteReport";
    $TMReportID{"16,05,00,C0,"} = "LP1:LPHostModeReport";
    $TMReportID{"17,05,00,10,"} = "LP2:LPControlPreStateReport";
    $TMReportID{"17,05,00,20,"} = "LP2:LPControlStateReport";
    $TMReportID{"17,05,00,30,"} = "LP2:LPEndReport";
    $TMReportID{"17,05,00,40,"} = "LP2:LPFoupStateReport";
    $TMReportID{"17,05,00,50,"} = "LP2:LPAccessModeReport";
    $TMReportID{"17,05,00,60,"} = "LP2:LPCarrierIDReport";
    $TMReportID{"17,05,00,70,"} = "LP2:LPSlotMapReport";
    $TMReportID{"17,05,00,80,"} = "LP2:LPTransferPreStateReport";
    $TMReportID{"17,05,00,90,"} = "LP2:LPTransferStateReport";
    $TMReportID{"17,05,00,A0,"} = "LP2:LPTransferEndReport";
    $TMReportID{"17,05,00,B0,"} = "LP2:LPCIDWriteReport";
    $TMReportID{"17,05,00,C0,"} = "LP2:LPHostModeReport";
    $TMReportID{"18,05,00,10,"} = "LP3:LPControlPreStateReport";
    $TMReportID{"18,05,00,20,"} = "LP3:LPControlStateReport";
    $TMReportID{"18,05,00,30,"} = "LP3:LPEndReport";
    $TMReportID{"18,05,00,40,"} = "LP3:LPFoupStateReport";
    $TMReportID{"18,05,00,50,"} = "LP3:LPAccessModeReport";
    $TMReportID{"18,05,00,60,"} = "LP3:LPCarrierIDReport";
    $TMReportID{"18,05,00,70,"} = "LP3:LPSlotMapReport";
    $TMReportID{"18,05,00,80,"} = "LP3:LPTransferPreStateReport";
    $TMReportID{"18,05,00,90,"} = "LP3:LPTransferStateReport";
    $TMReportID{"18,05,00,A0,"} = "LP3:LPTransferEndReport";
    $TMReportID{"18,05,00,B0,"} = "LP3:LPCIDWriteReport";
    $TMReportID{"18,05,00,C0,"} = "LP3:LPHostModeReport";
    $TMReportID{"19,05,00,10,"} = "LP4:LPControlPreStateReport";
    $TMReportID{"19,05,00,20,"} = "LP4:LPControlStateReport";
    $TMReportID{"19,05,00,30,"} = "LP4:LPEndReport";
    $TMReportID{"19,05,00,40,"} = "LP4:LPFoupStateReport";
    $TMReportID{"19,05,00,50,"} = "LP4:LPAccessModeReport";
    $TMReportID{"19,05,00,60,"} = "LP4:LPCarrierIDReport";
    $TMReportID{"19,05,00,70,"} = "LP4:LPSlotMapReport";
    $TMReportID{"19,05,00,80,"} = "LP4:LPTransferPreStateReport";
    $TMReportID{"19,05,00,90,"} = "LP4:LPTransferStateReport";
    $TMReportID{"19,05,00,A0,"} = "LP4:LPTransferEndReport";
    $TMReportID{"19,05,00,B0,"} = "LP4:LPCIDWriteReport";
    $TMReportID{"19,05,00,C0,"} = "LP4:LPHostModeReport";
    $TMReportID{"1A,05,00,10,"} = "CA1:CIDControlPreStateReport";
    $TMReportID{"1A,05,00,20,"} = "CA1:CIDControlStateReport";
    $TMReportID{"1A,05,00,30,"} = "CA1:CIDEndReport";
    $TMReportID{"1A,05,00,40,"} = "CA1:CIDReadReport1";
    $TMReportID{"1A,05,00,50,"} = "CA1:CIDReadReport2";
    $TMReportID{"1A,05,00,60,"} = "CA1:CIDWriteReport1";
    $TMReportID{"1A,05,00,70,"} = "CA1:CIDWriteReport2";
    $TMReportID{"1B,05,00,10,"} = "CA2:CIDControlPreStateReport";
    $TMReportID{"1B,05,00,20,"} = "CA2:CIDControlStateReport";
    $TMReportID{"1B,05,00,30,"} = "CA2:CIDEndReport";
    $TMReportID{"1B,05,00,40,"} = "CA2:CIDReadReport1";
    $TMReportID{"1B,05,00,50,"} = "CA2:CIDReadReport2";
    $TMReportID{"1B,05,00,60,"} = "CA2:CIDWriteReport1";
    $TMReportID{"1B,05,00,70,"} = "CA2:CIDWriteReport2";
    $TMReportID{"1C,05,00,10,"} = "CA2:CIDControlPreStateReport";
    $TMReportID{"1C,05,00,20,"} = "CA2:CIDControlStateReport";
    $TMReportID{"1C,05,00,30,"} = "CA2:CIDEndReport";
    $TMReportID{"1C,05,00,40,"} = "CA2:CIDReadReport1";
    $TMReportID{"1C,05,00,50,"} = "CA2:CIDReadReport2";
    $TMReportID{"1C,05,00,60,"} = "CA2:CIDWriteReport1";
    $TMReportID{"1C,05,00,70,"} = "CA2:CIDWriteReport2";
    $TMReportID{"1D,05,00,10,"} = "CA3:CIDControlPreStateReport";
    $TMReportID{"1D,05,00,20,"} = "CA3:CIDControlStateReport";
    $TMReportID{"1D,05,00,30,"} = "CA3:CIDEndReport";
    $TMReportID{"1D,05,00,40,"} = "CA3:CIDReadReport1";
    $TMReportID{"1D,05,00,50,"} = "CA3:CIDReadReport2";
    $TMReportID{"1D,05,00,60,"} = "CA3:CIDWriteReport1";
    $TMReportID{"1D,05,00,70,"} = "CA3:CIDWriteReport2";
    $TMReportID{"38,05,00,10,"} = "UIOPreStateReport";
    $TMReportID{"38,05,00,20,"} = "UIOStateReport";
    $TMReportID{"38,05,00,30,"} = "UIOILKReport";
    $TMReportID{"38,05,00,40,"} = "UIOFFUReport";
    $TMReportID{"28,05,00,10,"} = "LLALN1:ALNControlPreStateReport";
    $TMReportID{"28,05,00,20,"} = "LLALN1:ALNControlStateReport";
    $TMReportID{"28,05,00,30,"} = "LLALN1:ALNEndReport";
    $TMReportID{"29,05,00,10,"} = "LLALN1:ALNControlPreStateReport";
    $TMReportID{"29,05,00,20,"} = "LLALN2:ALNControlStateReport";
    $TMReportID{"29,05,00,30,"} = "LLALN2:ALNEndReport";
    $TMReportID{"1E,05,00,10,"} = "ALN:ALNControlPreStateReport";
    $TMReportID{"1E,05,00,20,"} = "ALN:ALNControlStateReport";
    $TMReportID{"1E,05,00,30,"} = "ALN:ALNEndReport";
    $TMReportID{"1F,05,00,10,"} = "MONPreStateReport";
    $TMReportID{"1F,05,00,20,"} = "MONStateReport";
    $TMReportID{"1F,05,00,30,"} = "MONEndReport";
    $TMReportID{"1F,05,00,40,"} = "MONRecipeListReport";
    $TMReportID{"1F,05,00,50,"} = "MONMeasureReport";
    $TMReportID{"1F,05,00,60,"} = "MONModeReport";
    $TMReportID{"30,05,00,10,"} = "GV1:GVControlPreStateReport";
    $TMReportID{"30,05,00,20,"} = "GV1:GVControlStateReport";
    $TMReportID{"30,05,00,30,"} = "GV1:GVValvePreStateReport";
    $TMReportID{"30,05,00,40,"} = "GV1:GVValveStateReport";
    $TMReportID{"30,05,00,50,"} = "GV1:GVEndStateReport";
    $TMReportID{"31,05,00,10,"} = "GV2:GVControlPreStateReport";
    $TMReportID{"31,05,00,20,"} = "GV2:GVControlStateReport";
    $TMReportID{"31,05,00,30,"} = "GV2:GVValvePreStateReport";
    $TMReportID{"31,05,00,40,"} = "GV2:GVValveStateReport";
    $TMReportID{"31,05,00,50,"} = "GV2:GVEndStateReport";
    $TMReportID{"32,05,00,10,"} = "GV3:GVControlPreStateReport";
    $TMReportID{"32,05,00,20,"} = "GV3:GVControlStateReport";
    $TMReportID{"32,05,00,30,"} = "GV3:GVValvePreStateReport";
    $TMReportID{"32,05,00,40,"} = "GV3:GVValveStateReport";
    $TMReportID{"32,05,00,50,"} = "GV3:GVEndStateReport";
    $TMReportID{"33,05,00,10,"} = "GV4:GVControlPreStateReport";
    $TMReportID{"33,05,00,20,"} = "GV4:GVControlStateReport";
    $TMReportID{"33,05,00,30,"} = "GV4:GVValvePreStateReport";
    $TMReportID{"33,05,00,40,"} = "GV4:GVValveStateReport";
    $TMReportID{"33,05,00,50,"} = "GV4:GVEndStateReport";
    $TMReportID{"34,05,00,10,"} = "GV5:GVControlPreStateReport";
    $TMReportID{"34,05,00,20,"} = "GV5:GVControlStateReport";
    $TMReportID{"34,05,00,30,"} = "GV5:GVValvePreStateReport";
    $TMReportID{"34,05,00,40,"} = "GV5:GVValveStateReport";
    $TMReportID{"34,05,00,50,"} = "GV5:GVEndStateReport";
    $TMReportID{"35,05,00,10,"} = "GV6:GVControlPreStateReport";
    $TMReportID{"35,05,00,20,"} = "GV6:GVControlStateReport";
    $TMReportID{"35,05,00,30,"} = "GV6:GVValvePreStateReport";
    $TMReportID{"35,05,00,40,"} = "GV6:GVValveStateReport";
    $TMReportID{"35,05,00,50,"} = "GV6:GVEndStateReport";
    $TMReportID{"36,05,00,10,"} = "GV7:GVControlPreStateReport";
    $TMReportID{"36,05,00,20,"} = "GV7:GVControlStateReport";
    $TMReportID{"36,05,00,30,"} = "GV7:GVValvePreStateReport";
    $TMReportID{"36,05,00,40,"} = "GV7:GVValveStateReport";
    $TMReportID{"36,05,00,50,"} = "GV7:GVEndStateReport";
    $TMReportID{"37,05,00,10,"} = "GV8:GVControlPreStateReport";
    $TMReportID{"37,05,00,20,"} = "GV8:GVControlStateReport";
    $TMReportID{"37,05,00,30,"} = "GV8:GVValvePreStateReport";
    $TMReportID{"37,05,00,40,"} = "GV8:GVValveStateReport";
    $TMReportID{"37,05,00,50,"} = "GV8:GVEndStateReport";
    $TMReportID{"39,05,00,10,"} = "GV9:GVControlPreStateReport";
    $TMReportID{"39,05,00,20,"} = "GV9:GVControlStateReport";
    $TMReportID{"39,05,00,30,"} = "GV9:GVValvePreStateReport";
    $TMReportID{"39,05,00,40,"} = "GV9:GVValveStateReport";
    $TMReportID{"39,05,00,50,"} = "GV9:GVEndStateReport";
    $TMReportID{"2D,05,00,10,"} = "EFEMPreStateReport";
    $TMReportID{"2D,05,00,20,"} = "EFEMStateReport";
    $TMReportID{"2D,05,00,30,"} = "EFEMEndReport";
    $TMReportID{"2D,05,00,60,"} = "EFEMModeReport";
    $TMReportID{"2D,05,10,10,"} = "EFEMAnswerReport";
    $TMReportID{"2D,05,10,20,"} = "EFEMAlarmBitReport";
    $TMReportID{"41,05,00,10,"} = "PM1:RCControlPreStateReport";
    $TMReportID{"41,05,00,20,"} = "PM1:RCControlStateReport";
    $TMReportID{"41,05,00,30,"} = "PM1:RCPressStateReport";
    $TMReportID{"41,05,00,40,"} = "PM1:RCPressureReport";
    $TMReportID{"41,05,00,50,"} = "PM1:RCStepReport";
    $TMReportID{"41,05,00,70,"} = "PM1:RCWaferDataReport";
    $TMReportID{"41,05,00,80,"} = "PM1:RCModeReport";
    $TMReportID{"41,05,00,90,"} = "PM1:RCAlarmReport";
    $TMReportID{"41,05,00,A0,"} = "PM1:RCLogTimeReport";
    $TMReportID{"41,05,00,B0,"} = "PM1:RCLogCountReport";
    $TMReportID{"41,05,00,D0,"} = "PM1:RCAbortReport";
    $TMReportID{"41,05,00,E0,"} = "PM1:RCNewStepReport";
    $TMReportID{"41,05,00,F0,"} = "PM1:RCPreStepReport";
    $TMReportID{"41,05,01,00,"} = "PM1:RCCycleReport";
    $TMReportID{"51,05,00,10,"} = "PM2:RCControlPreStateReport";
    $TMReportID{"51,05,00,20,"} = "PM2:RCControlStateReport";
    $TMReportID{"51,05,00,30,"} = "PM2:RCPressStateReport";
    $TMReportID{"51,05,00,40,"} = "PM2:RCPressureReport";
    $TMReportID{"51,05,00,50,"} = "PM2:RCStepReport";
    $TMReportID{"51,05,00,70,"} = "PM2:RCWaferDataReport";
    $TMReportID{"51,05,00,80,"} = "PM2:RCModeReport";
    $TMReportID{"51,05,00,90,"} = "PM2:RCAlarmReport";
    $TMReportID{"51,05,00,A0,"} = "PM2:RCLogTimeReport";
    $TMReportID{"51,05,00,B0,"} = "PM2:RCLogCountReport";
    $TMReportID{"51,05,00,D0,"} = "PM2:RCAbortReport";
    $TMReportID{"51,05,00,E0,"} = "PM2:RCNewStepReport";
    $TMReportID{"51,05,00,F0,"} = "PM2:RCPreStepReport";
    $TMReportID{"51,05,01,00,"} = "PM2:RCCycleReport";
    $TMReportID{"61,05,00,10,"} = "PM3:RCControlPreStateReport";
    $TMReportID{"61,05,00,20,"} = "PM3:RCControlStateReport";
    $TMReportID{"61,05,00,30,"} = "PM3:RCPressStateReport";
    $TMReportID{"61,05,00,40,"} = "PM3:RCPressureReport";
    $TMReportID{"61,05,00,50,"} = "PM3:RCStepReport";
    $TMReportID{"61,05,00,70,"} = "PM3:RCWaferDataReport";
    $TMReportID{"61,05,00,80,"} = "PM3:RCModeReport";
    $TMReportID{"61,05,00,90,"} = "PM3:RCAlarmReport";
    $TMReportID{"61,05,00,A0,"} = "PM3:RCLogTimeReport";
    $TMReportID{"61,05,00,B0,"} = "PM3:RCLogCountReport";
    $TMReportID{"61,05,00,D0,"} = "PM3:RCAbortReport";
    $TMReportID{"61,05,00,E0,"} = "PM3:RCNewStepReport";
    $TMReportID{"61,05,00,F0,"} = "PM3:RCPreStepReport";
    $TMReportID{"61,05,01,00,"} = "PM3:RCCycleReport";
    $TMReportID{"71,05,00,10,"} = "PM4:RCControlPreStateReport";
    $TMReportID{"71,05,00,20,"} = "PM4:RCControlStateReport";
    $TMReportID{"71,05,00,30,"} = "PM4:RCPressStateReport";
    $TMReportID{"71,05,00,40,"} = "PM4:RCPressureReport";
    $TMReportID{"71,05,00,50,"} = "PM4:RCStepReport";
    $TMReportID{"71,05,00,70,"} = "PM4:RCWaferDataReport";
    $TMReportID{"71,05,00,80,"} = "PM4:RCModeReport";
    $TMReportID{"71,05,00,90,"} = "PM4:RCAlarmReport";
    $TMReportID{"71,05,00,A0,"} = "PM4:RCLogTimeReport";
    $TMReportID{"71,05,00,B0,"} = "PM4:RCLogCountReport";
    $TMReportID{"71,05,00,D0,"} = "PM4:RCAbortReport";
    $TMReportID{"71,05,00,E0,"} = "PM4:RCNewStepReport";
    $TMReportID{"71,05,00,F0,"} = "PM4:RCPreStepReport";
    $TMReportID{"71,05,01,00,"} = "PM4:RCCycleReport";
    $TMReportID{"81,05,00,10,"} = "PM5:RCControlPreStateReport";
    $TMReportID{"81,05,00,20,"} = "PM5:RCControlStateReport";
    $TMReportID{"81,05,00,30,"} = "PM5:RCPressStateReport";
    $TMReportID{"81,05,00,40,"} = "PM5:RCPressureReport";
    $TMReportID{"81,05,00,50,"} = "PM5:RCStepReport";
    $TMReportID{"81,05,00,70,"} = "PM5:RCWaferDataReport";
    $TMReportID{"81,05,00,80,"} = "PM5:RCModeReport";
    $TMReportID{"81,05,00,90,"} = "PM5:RCAlarmReport";
    $TMReportID{"81,05,00,A0,"} = "PM5:RCLogTimeReport";
    $TMReportID{"81,05,00,B0,"} = "PM5:RCLogCountReport";
    $TMReportID{"81,05,00,D0,"} = "PM5:RCAbortReport";
    $TMReportID{"81,05,00,E0,"} = "PM5:RCNewStepReport";
    $TMReportID{"81,05,00,F0,"} = "PM5:RCPreStepReport";
    $TMReportID{"81,05,01,00,"} = "PM5:RCCycleReport";
    $TMReportID{"40,05,00,10,"} = "PM1_ALL:PMWaferEndReport";
    $TMReportID{"40,05,00,20,"} = "PM1_ALL:PMWaferStateReport";
    $TMReportID{"40,05,00,30,"} = "PM1_ALL:PMWaferPreStateReport";
    $TMReportID{"40,05,00,40,"} = "PM1_ALL:PMEndReport";
    $TMReportID{"40,05,02,00,"} = "PM1_ALL:PMALLEndReport";
    $TMReportID{"50,05,00,10,"} = "PM2_ALL:PMWaferEndReport";
    $TMReportID{"50,05,00,20,"} = "PM2_ALL:PMWaferStateReport";
    $TMReportID{"50,05,00,30,"} = "PM2_ALL:PMWaferPreStateReport";
    $TMReportID{"50,05,00,40,"} = "PM2_ALL:PMEndReport";
    $TMReportID{"50,05,02,00,"} = "PM2_ALL:PMALLEndReport";
    $TMReportID{"60,05,00,10,"} = "PM3_ALL:PMWaferEndReport";
    $TMReportID{"60,05,00,20,"} = "PM3_ALL:PMWaferStateReport";
    $TMReportID{"60,05,00,30,"} = "PM3_ALL:PMWaferPreStateReport";
    $TMReportID{"60,05,00,40,"} = "PM3_ALL:PMEndReport";
    $TMReportID{"60,05,02,00,"} = "PM3_ALL:PMALLEndReport";
    $TMReportID{"70,05,00,10,"} = "PM4_ALL:PMWaferEndReport";
    $TMReportID{"70,05,00,20,"} = "PM4_ALL:PMWaferStateReport";
    $TMReportID{"70,05,00,30,"} = "PM4_ALL:PMWaferPreStateReport";
    $TMReportID{"70,05,00,40,"} = "PM4_ALL:PMEndReport";
    $TMReportID{"70,05,02,00,"} = "PM4_ALL:PMALLEndReport";
    $TMReportID{"80,05,00,10,"} = "PM5_ALL:PMWaferEndReport";
    $TMReportID{"80,05,00,20,"} = "PM5_ALL:PMWaferStateReport";
    $TMReportID{"80,05,00,30,"} = "PM5_ALL:PMWaferPreStateReport";
    $TMReportID{"80,05,00,40,"} = "PM5_ALL:PMEndReport";
    $TMReportID{"80,05,02,00,"} = "PM5_ALL:PMALLEndReport";
    $TMReportID{"42,05,00,10,"} = "PM1:SSControlPreStateReport";
    $TMReportID{"42,05,00,20,"} = "PM1:SSControlStateReport";
    $TMReportID{"42,05,00,30,"} = "PM1:SSZPositionReport";
    $TMReportID{"42,05,00,40,"} = "PM1:SSEndStateReport";
    $TMReportID{"42,05,00,10,"} = "PM1:SSControlPreStateReport";
    $TMReportID{"42,05,00,20,"} = "PM1:SSControlStateReport";
    $TMReportID{"42,05,00,30,"} = "PM1:SSZPositionReport";
    $TMReportID{"42,05,00,40,"} = "PM1:SSEndStateReport";
    $TMReportID{"42,05,01,00,"} = "PM1:RCCycleReport";
    $TMReportID{"52,05,00,10,"} = "PM2:SSControlPreStateReport";
    $TMReportID{"52,05,00,20,"} = "PM2:SSControlStateReport";
    $TMReportID{"52,05,00,30,"} = "PM2:SSZPositionReport";
    $TMReportID{"52,05,00,40,"} = "PM2:SSEndStateReport";
    $TMReportID{"52,05,00,10,"} = "PM2:SSControlPreStateReport";
    $TMReportID{"52,05,00,20,"} = "PM2:SSControlStateReport";
    $TMReportID{"52,05,00,30,"} = "PM2:SSZPositionReport";
    $TMReportID{"52,05,00,40,"} = "PM2:SSEndStateReport";
    $TMReportID{"52,05,01,00,"} = "PM2:RCCycleReport";
    $TMReportID{"62,05,00,10,"} = "PM3:SSControlPreStateReport";
    $TMReportID{"62,05,00,20,"} = "PM3:SSControlStateReport";
    $TMReportID{"62,05,00,30,"} = "PM3:SSZPositionReport";
    $TMReportID{"62,05,00,40,"} = "PM3:SSEndStateReport";
    $TMReportID{"62,05,00,10,"} = "PM3:SSControlPreStateReport";
    $TMReportID{"62,05,00,20,"} = "PM3:SSControlStateReport";
    $TMReportID{"62,05,00,30,"} = "PM3:SSZPositionReport";
    $TMReportID{"62,05,00,40,"} = "PM3:SSEndStateReport";
    $TMReportID{"62,05,01,00,"} = "PM3:RCCycleReport";
    $TMReportID{"72,05,00,10,"} = "PM4:SSControlPreStateReport";
    $TMReportID{"72,05,00,20,"} = "PM4:SSControlStateReport";
    $TMReportID{"72,05,00,30,"} = "PM4:SSZPositionReport";
    $TMReportID{"72,05,00,40,"} = "PM4:SSEndStateReport";
    $TMReportID{"72,05,00,10,"} = "PM4:SSControlPreStateReport";
    $TMReportID{"72,05,00,20,"} = "PM4:SSControlStateReport";
    $TMReportID{"72,05,00,30,"} = "PM4:SSZPositionReport";
    $TMReportID{"72,05,00,40,"} = "PM4:SSEndStateReport";
    $TMReportID{"72,05,01,00,"} = "PM4:RCCycleReport";
    $TMReportID{"82,05,00,10,"} = "PM5:SSControlPreStateReport";
    $TMReportID{"82,05,00,20,"} = "PM5:SSControlStateReport";
    $TMReportID{"82,05,00,30,"} = "PM5:SSZPositionReport";
    $TMReportID{"82,05,00,40,"} = "PM5:SSEndStateReport";
    $TMReportID{"82,05,00,10,"} = "PM5:SSControlPreStateReport";
    $TMReportID{"82,05,00,20,"} = "PM5:SSControlStateReport";
    $TMReportID{"82,05,00,30,"} = "PM5:SSZPositionReport";
    $TMReportID{"82,05,00,40,"} = "PM5:SSEndStateReport";
    $TMReportID{"82,05,01,00,"} = "PM5:RCCycleReport";
}

# sub GetTMUnit {
#     $TMUnit{"10"} = "ALL";
#     $TMUnit{"11"} = "FERB";
#     $TMUnit{"12"} = "BERB";
#     $TMUnit{"16"} = "LP1";
#     $TMUnit{"17"} = "LP2";
#     $TMUnit{"18"} = "LP3";
#     $TMUnit{"19"} = "LP4";
#     $TMUnit{"1A"} = "CID1";
#     $TMUnit{"1B"} = "CID2";
#     $TMUnit{"1C"} = "CID3";
#     $TMUnit{"1D"} = "CID4";
#     $TMUnit{"1E"} = "ALN";
#     $TMUnit{"1F"} = "MON";
#     $TMUnit{"20"} = "WHC";
#     $TMUnit{"21"} = "IOC1";
#     $TMUnit{"22"} = "IOC2";
#     $TMUnit{"23"} = "IOC3";
#     $TMUnit{"24"} = "IOC4";
#     $TMUnit{"28"} = "LLALN1";
#     $TMUnit{"29"} = "LLALN2";
#     $TMUnit{"2D"} = "EFEM";
#     $TMUnit{"30"} = "GV1";
#     $TMUnit{"31"} = "GV2";
#     $TMUnit{"32"} = "GV3";
#     $TMUnit{"33"} = "GV4";
#     $TMUnit{"34"} = "GV5";
#     $TMUnit{"35"} = "GV6";
#     $TMUnit{"36"} = "GV7";
#     $TMUnit{"37"} = "GV8";
#     $TMUnit{"39"} = "GV9";
#     $TMUnit{"38"} = "UIO";
#     $TMUnit{"3C"} = "ALLFE";
#     $TMUnit{"3D"} = "ALLBE";
# }

sub GetEvents {
    $Events{"10,04,00,10,"} = "ALL:TMStartUp";
    $Events{"10,04,00,20,"} = "ALL:TMFEWaferTransferEnd";
    $Events{"10,04,00,21,"} = "ALL:TMBEWaferTransferEnd";
    $Events{"10,04,00,30,"} = "ALL:TMFEWaferStateChanged";
    $Events{"10,04,00,31,"} = "ALL:TMBEWaferStateChanged";
    $Events{"10,04,01,21,"} = "ALL:TMWhcEnd";
    $Events{"10,04,01,22,"} = "ALL:TMLLLEnd";
    $Events{"10,04,01,23,"} = "ALL:TMLLL2End";
    $Events{"10,04,01,24,"} = "ALL:TMRLLEnd";
    $Events{"10,04,01,25,"} = "ALL:TMRLL2End";
    $Events{"10,04,02,00,"} = "ALL:TMAllStateChanged";
    $Events{"10,04,02,10,"} = "ALL:TMAllEnd";
    $Events{"11,04,00,10,"} = "FE:FERBStateChanged";
    $Events{"11,04,00,20,"} = "FE:FERBPaused";
    $Events{"11,04,00,30,"} = "FE:FERBResumed";
    $Events{"11,04,00,40,"} = "FE:FERBControlEnd";
    $Events{"12,04,00,10,"} = "BE:BERBStateChanged";
    $Events{"12,04,00,20,"} = "BE:BERBPaused";
    $Events{"12,04,00,30,"} = "BE:BERBResumed";
    $Events{"12,04,00,40,"} = "BE:BERBControlEnd";
    $Events{"16,04,00,10,"} = "LP1:LPControlStateChanged";
    $Events{"16,04,00,20,"} = "LP1:LPPortStateChanged";
    $Events{"16,04,00,30,"} = "LP1:LPAccessModeChanged";
    $Events{"16,04,00,50,"} = "LP1:LPSlotMapReportEvent";
    $Events{"16,04,00,60,"} = "LP1:LPTransferStateChanged";
    $Events{"16,04,00,70,"} = "LP1:LPControlEnd";
    $Events{"16,04,01,00,"} = "LP1:LPHostModeChanged";
    $Events{"17,04,00,10,"} = "LP2:LPControlStateChanged";
    $Events{"17,04,00,20,"} = "LP2:LPPortStateChanged";
    $Events{"17,04,00,30,"} = "LP2:LPAccessModeChanged";
    $Events{"17,04,00,50,"} = "LP2:LPSlotMapReportEvent";
    $Events{"17,04,00,60,"} = "LP2:LPTransferStateChanged";
    $Events{"17,04,00,70,"} = "LP2:LPControlEnd";
    $Events{"17,04,01,00,"} = "LP2:LPHostModeChanged";
    $Events{"18,04,00,10,"} = "LP3:LPControlStateChanged";
    $Events{"18,04,00,20,"} = "LP3:LPPortStateChanged";
    $Events{"18,04,00,30,"} = "LP3:LPAccessModeChanged";
    $Events{"18,04,00,50,"} = "LP3:LPSlotMapReportEvent";
    $Events{"16804,00,60,"} = "LP3:LPTransferStateChanged";
    $Events{"18,04,00,70,"} = "LP3:LPControlEnd";
    $Events{"18,04,01,00,"} = "LP3:LPHostModeChanged";
    $Events{"19,04,00,10,"} = "LP4:LPControlStateChanged";
    $Events{"19,04,00,20,"} = "LP4:LPPortStateChanged";
    $Events{"19,04,00,30,"} = "LP4:LPAccessModeChanged";
    $Events{"19,04,00,50,"} = "LP4:LPSlotMapReportEvent";
    $Events{"19,04,00,60,"} = "LP4:LPTransferStateChanged";
    $Events{"19,04,00,70,"} = "LP4:LPControlEnd";
    $Events{"19,04,01,00,"} = "LP4:LPHostModeChanged";
    $Events{"1A,04,00,10,"} = "CID1:CIDControlStateChanged";
    $Events{"1A,04,00,20,"} = "CID1:CIDReadReportEvent";
    $Events{"1A,04,00,30,"} = "CID1:CIDTagReadReportEvent";
    $Events{"1A,04,00,40,"} = "CID1:CIDWriteReportEvent";
    $Events{"1A,04,00,50,"} = "CID1:CIDTagWriteReportEvent";
    $Events{"1B,04,00,10,"} = "CID2:CIDControlStateChanged";
    $Events{"1B,04,00,20,"} = "CID2:CIDReadReportEvent";
    $Events{"1B,04,00,30,"} = "CID2:CIDTagReadReportEvent";
    $Events{"1B,04,00,40,"} = "CID2:CIDWriteReportEvent";
    $Events{"1B,04,00,50,"} = "CID2:CIDTagWriteReportEvent";
    $Events{"1C,04,00,10,"} = "CID3:CIDControlStateChanged";
    $Events{"1C,04,00,20,"} = "CID3:CIDReadReportEvent";
    $Events{"1C,04,00,30,"} = "CID3:CIDTagReadReportEvent";
    $Events{"1C,04,00,40,"} = "CID3:CIDWriteReportEvent";
    $Events{"1C,04,00,50,"} = "CID3:CIDTagWriteReportEvent";
    $Events{"1D,04,00,10,"} = "CID4:CIDControlStateChanged";
    $Events{"1D,04,00,20,"} = "CID4:CIDReadReportEvent";
    $Events{"1D,04,00,30,"} = "CID4:CIDTagReadReportEvent";
    $Events{"1D,04,00,40,"} = "CID4:CIDWriteReportEvent";
    $Events{"1D,04,00,50,"} = "CID4:CIDTagWriteReportEvent";
    $Events{"1E,04,00,10,"} = "ALN:ALNControlStateChanged";
    $Events{"1E,04,00,20,"} = "ALN:ALNReqCompleted";
    $Events{"1F,04,00,10,"} = "MON:MONStateChanged";
    $Events{"1F,04,00,20,"} = "MON:MONReqCompleted";
    $Events{"1F,04,00,30,"} = "MON:MONRecipeListReqEvent";
    $Events{"1F,04,00,40,"} = "MON:MONMeasureEvent";
    $Events{"1F,04,00,50,"} = "MON:MONModeChanged";
    $Events{"20,04,00,10,"} = "WHC:LLCControlStateChanged";
    $Events{"20,04,00,20,"} = "WHC:LLCPressStateChanged";
    $Events{"20,04,01,00,"} = "WHC:LLCWioSeqEnd";
    $Events{"20,04,01,10,"} = "WHC:LLCLeakCheckEnd";
    $Events{"21,04,00,10,"} = "LLL:LLCControlStateChanged";
    $Events{"21,04,00,20,"} = "LLL:LLCPressStateChanged";
    $Events{"21,04,01,00,"} = "LLL:LLCWioSeqEnd";
    $Events{"21,04,01,10,"} = "LLL:LLCLeakCheckEnd";
    $Events{"22,04,00,10,"} = "LLL2:LLCControlStateChanged";
    $Events{"22,04,00,20,"} = "LLL2:LLCPressStateChanged";
    $Events{"22,04,01,00,"} = "LLL2:LLCWioSeqEnd";
    $Events{"22,04,01,10,"} = "LLL2:LLCLeakCheckEnd";
    $Events{"23,04,00,10,"} = "RLL:LLCControlStateChanged";
    $Events{"23,04,00,20,"} = "RLL:LLCPressStateChanged";
    $Events{"23,04,01,00,"} = "RLL:LLCWioSeqEnd";
    $Events{"23,04,01,10,"} = "RLL:LLCLeakCheckEnd";
    $Events{"24,04,00,10,"} = "RLL2:LLCControlStateChanged";
    $Events{"24,04,00,20,"} = "RLL2:LLCPressStateChanged";
    $Events{"24,04,01,00,"} = "RLL2:LLCWioSeqEnd";
    $Events{"24,04,01,10,"} = "RLL2:LLCLeakCheckEnd";
    $Events{"28,04,00,10,"} = "LLALN1:ALNControlStateChanged";
    $Events{"28,04,00,20,"} = "LLALN1:ALNReqCompleted";
    $Events{"29,04,00,10,"} = "LLALN2:ALNControlStateChanged";
    $Events{"29,04,00,20,"} = "LLALN2:ALNReqCompleted";
    $Events{"2D,04,00,10,"} = "EFEM:EFEMStateChanged";
    $Events{"2D,04,00,50,"} = "EFEM:EFEMModeChanged";
    $Events{"2D,04,10,10,"} = "EFEM:EFEMControlAnswer";
    $Events{"2D,04,10,20,"} = "EFEM:EFEMAlarmBitChanged";
    $Events{"30,04,00,10,"} = "GV1:GVControlStateChanged";
    $Events{"30,04,00,20,"} = "GV1:GVValveStateChanged";
    $Events{"30,04,00,30,"} = "GV1:GVControlEndChanged";
    $Events{"31,04,00,10,"} = "GV2:GVControlStateChanged";
    $Events{"31,04,00,20,"} = "GV2:GVValveStateChanged";
    $Events{"31,04,00,30,"} = "GV2:GVControlEndChanged";
    $Events{"32,04,00,10,"} = "GV3:GVControlStateChanged";
    $Events{"32,04,00,20,"} = "GV3:GVValveStateChanged";
    $Events{"32,04,00,30,"} = "GV3:GVControlEndChanged";
    $Events{"33,04,00,10,"} = "GV4:GVControlStateChanged";
    $Events{"33,04,00,20,"} = "GV4:GVValveStateChanged";
    $Events{"33,04,00,30,"} = "GV4:GVControlEndChanged";
    $Events{"34,04,00,10,"} = "GV5:GVControlStateChanged";
    $Events{"34,04,00,20,"} = "GV5:GVValveStateChanged";
    $Events{"34,04,00,30,"} = "GV5:GVControlEndChanged";
    $Events{"35,04,00,10,"} = "GV6:GVControlStateChanged";
    $Events{"35,04,00,20,"} = "GV6:GVValveStateChanged";
    $Events{"35,04,00,30,"} = "GV6:GVControlEndChanged";
    $Events{"36,04,00,10,"} = "GV7:GVControlStateChanged";
    $Events{"36,04,00,20,"} = "GV7:GVValveStateChanged";
    $Events{"36,04,00,30,"} = "GV7:GVControlEndChanged";
    $Events{"37,04,00,10,"} = "GV8:GVControlStateChanged";
    $Events{"37,04,00,20,"} = "GV8:GVValveStateChanged";
    $Events{"37,04,00,30,"} = "GV8:GVControlEndChanged";
    $Events{"38,04,00,10,"} = "UIO:UIOStateChanged";
    $Events{"38,04,00,20,"} = "UIO:UIOILKChanged";
    $Events{"38,04,00,30,"} = "UIO:UIOFFUChanged";
    $Events{"38,04,00,40,"} = "UIO:UIOPowerFailChanged";
    $Events{"39,04,00,10,"} = "GV9:GVControlStateChanged";
    $Events{"39,04,00,20,"} = "GV9:GVValveStateChanged";
    $Events{"39,04,00,30,"} = "GV9:GVControlEndChanged";
    $Events{"40,04,00,10,"} = "PM1_ALL:PMStartUp";
    $Events{"40,04,00,20,"} = "PM1_ALL:PMWaferTransferEnd";
    $Events{"40,04,00,30,"} = "PM1_ALL:PMWaferTransferChanged";
    $Events{"40,04,00,40,"} = "PM1_ALL:PMInitializeEnd";
    $Events{"40,04,02,10,"} = "PM1_ALL:PMAllEnd";
    $Events{"41,04,00,10,"} = "PM1:RCControlStateChanged";
    $Events{"41,04,00,20,"} = "PM1:RCPressStateChanged";
    $Events{"41,04,00,30,"} = "PM1:RCGetDataEnd";
    $Events{"41,04,00,40,"} = "PM1:RCModeChanged";
    $Events{"41,04,00,50,"} = "PM1:RCAlarmChanged";
    $Events{"41,04,00,60,"} = "PM1:RCGetPressDataEnd";
    $Events{"41,04,00,70,"} = "PM1:RCAborted";
    $Events{"41,04,00,80,"} = "PM1:RCStepStarted";
    $Events{"41,04,00,90,"} = "PM1:RCStepChanged";
    $Events{"41,04,00,A0,"} = "PM1:RCStepEnded";
    $Events{"42,04,00,10,"} = "PM1:SSControlStateChanged";
    $Events{"42,04,00,30,"} = "PM1:SSControlEndChanged";
    $Events{"50,04,00,10,"} = "PM2_ALL:PMStartUp";
    $Events{"50,04,00,20,"} = "PM2_ALL:PMWaferTransferEnd";
    $Events{"50,04,00,30,"} = "PM2_ALL:PMWaferTransferChanged";
    $Events{"50,04,00,40,"} = "PM2_ALL:PMInitializeEnd";
    $Events{"50,04,02,10,"} = "PM2_ALL:PMAllEnd";
    $Events{"51,04,00,10,"} = "PM2:RCControlStateChanged";
    $Events{"51,04,00,20,"} = "PM2:RCPressStateChanged";
    $Events{"51,04,00,30,"} = "PM2:RCGetDataEnd";
    $Events{"51,04,00,40,"} = "PM2:RCModeChanged";
    $Events{"51,04,00,50,"} = "PM2:RCAlarmChanged";
    $Events{"51,04,00,60,"} = "PM2:RCGetPressDataEnd";
    $Events{"51,04,00,70,"} = "PM2:RCAborted";
    $Events{"51,04,00,80,"} = "PM2:RCStepStarted";
    $Events{"51,04,00,90,"} = "PM2:RCStepChanged";
    $Events{"51,04,00,A0,"} = "PM2:RCStepEnded";
    $Events{"52,04,00,10,"} = "PM2:SSControlStateChanged";
    $Events{"52,04,00,30,"} = "PM2:SSControlEndChanged";
    $Events{"60,04,00,10,"} = "PM3_ALL:PMStartUp";
    $Events{"60,04,00,20,"} = "PM3_ALL:PMWaferTransferEnd";
    $Events{"60,04,00,30,"} = "PM3_ALL:PMWaferTransferChanged";
    $Events{"60,04,00,40,"} = "PM3_ALL:PMInitializeEnd";
    $Events{"60,04,02,10,"} = "PM3_ALL:PMAllEnd";
    $Events{"61,04,00,10,"} = "PM3:RCControlStateChanged";
    $Events{"61,04,00,20,"} = "PM3:RCPressStateChanged";
    $Events{"61,04,00,30,"} = "PM3:RCGetDataEnd";
    $Events{"61,04,00,40,"} = "PM3:RCModeChanged";
    $Events{"61,04,00,50,"} = "PM3:RCAlarmChanged";
    $Events{"61,04,00,60,"} = "PM3:RCGetPressDataEnd";
    $Events{"61,04,00,70,"} = "PM3:RCAborted";
    $Events{"61,04,00,80,"} = "PM3:RCStepStarted";
    $Events{"61,04,00,90,"} = "PM3:RCStepChanged";
    $Events{"61,04,00,A0,"} = "PM3:RCStepEnded";
    $Events{"62,04,00,10,"} = "PM3:SSControlStateChanged";
    $Events{"62,04,00,30,"} = "PM3:SSControlEndChanged";
    $Events{"70,04,00,10,"} = "PM4_ALL:PMStartUp";
    $Events{"70,04,00,20,"} = "PM4_ALL:PMWaferTransferEnd";
    $Events{"70,04,00,30,"} = "PM4_ALL:PMWaferTransferChanged";
    $Events{"70,04,00,40,"} = "PM4_ALL:PMInitializeEnd";
    $Events{"70,04,02,10,"} = "PM4_ALL:PMAllEnd";
    $Events{"71,04,00,10,"} = "PM4:RCControlStateChanged";
    $Events{"71,04,00,20,"} = "PM4:RCPressStateChanged";
    $Events{"71,04,00,30,"} = "PM4:RCGetDataEnd";
    $Events{"71,04,00,40,"} = "PM4:RCModeChanged";
    $Events{"71,04,00,50,"} = "PM4:RCAlarmChanged";
    $Events{"71,04,00,60,"} = "PM4:RCGetPressDataEnd";
    $Events{"71,04,00,70,"} = "PM4:RCAborted";
    $Events{"71,04,00,80,"} = "PM4:RCStepStarted";
    $Events{"71,04,00,90,"} = "PM4:RCStepChanged";
    $Events{"71,04,00,A0,"} = "PM4:RCStepEnded";
    $Events{"72,04,00,10,"} = "PM4:SSControlStateChanged";
    $Events{"72,04,00,30,"} = "PM4:SSControlEndChanged";
    $Events{"80,04,00,10,"} = "PM5_ALL:PMStartUp";
    $Events{"80,04,00,20,"} = "PM5_ALL:PMWaferTransferEnd";
    $Events{"80,04,00,30,"} = "PM5_ALL:PMWaferTransferChanged";
    $Events{"80,04,00,40,"} = "PM5_ALL:PMInitializeEnd";
    $Events{"80,04,02,10,"} = "PM5_ALL:PMAllEnd";
    $Events{"81,04,00,10,"} = "PM5:RCControlStateChanged";
    $Events{"81,04,00,20,"} = "PM5:RCPressStateChanged";
    $Events{"81,04,00,30,"} = "PM5:RCGetDataEnd";
    $Events{"81,04,00,40,"} = "PM5:RCModeChanged";
    $Events{"81,04,00,50,"} = "PM5:RCAlarmChanged";
    $Events{"81,04,00,60,"} = "PM5:RCGetPressDataEnd";
    $Events{"81,04,00,70,"} = "PM5:RCAborted";
    $Events{"81,04,00,80,"} = "PM5:RCStepStarted";
    $Events{"81,04,00,90,"} = "PM5:RCStepChanged";
    $Events{"81,04,00,A0,"} = "PM5:RCStepEnded";
    $Events{"82,04,00,10,"} = "PM5:SSControlStateChanged";
    $Events{"82,04,00,30,"} = "PM5:SSControlEndChanged";
}

sub GetRemoteCmd{
    $remoteCmd{"40: ALNAlarmReset"} = "ALNAlarmReset";
    $remoteCmd{"40: ALNAlignment"} = "ALNAlignment";
    $remoteCmd{"40: ALNInitialize"} = "ALNInitialize";
    $remoteCmd{"40: ALNMoveHome"} = "ALNMoveHome";
    $remoteCmd{"40: ALNMoveTrans"} = "ALNMoveTrans";
    $remoteCmd{"40: ALNPause"} = "ALNPause";
    $remoteCmd{"40: ALNResume"} = "ALNResume";
    $remoteCmd{"40: ALNSetDegree"} = "ALNSetDegree";
    $remoteCmd{"40: ALNSetOffset"} = "ALNSetOffset";
    $remoteCmd{"40: ALNSetSpeed"} = "ALNSetSpeed";
    $remoteCmd{"40: ALNWafClamp"} = "ALNWafClamp";
    $remoteCmd{"40: CIDAlarmReset"} = "CIDAlarmReset";
    $remoteCmd{"40: CIDIDRead"} = "CIDIDRead";
    $remoteCmd{"40: CIDIDWrite"} = "CIDIDWrite";
    $remoteCmd{"40: CIDTagRead"} = "CIDTagRead";
    $remoteCmd{"40: CIDTagWrite"} = "CIDTagWrite";
    $remoteCmd{"40: EFEMAbort"} = "EFEMAbort";
    $remoteCmd{"40: EFEMAlarmReset"} = "EFEMAlarmReset";
    $remoteCmd{"40: EFEMCDAPurge"} = "EFEMCDAPurge";
    $remoteCmd{"40: EFEMIsolate"} = "EFEMIsolate";
    $remoteCmd{"40: EFEMLeakCheck"} = "EFEMLeakCheck";
    $remoteCmd{"40: EFEMN2Purge"} = "EFEMN2Purge";
    $remoteCmd{"40: EFEMPurgeSkip"} = "EFEMPurgeSkip";
    $remoteCmd{"40: EFEMSetFlow"} = "EFEMSetFlow";
    $remoteCmd{"40: EFEMSetMode"} = "EFEMSetMode";
    $remoteCmd{"40: EFEMSetPress"} = "EFEMSetPress";
    $remoteCmd{"40: EFEMSetValve"} = "EFEMSetValve";
    $remoteCmd{"40: GVAlarmReset"} = "GVAlarmReset";
    $remoteCmd{"40: GVClose"} = "GVClose";
    $remoteCmd{"40: GVOpen"} = "GVOpen";
    $remoteCmd{"40: IOCAbort"} = "IOCAbort";
    $remoteCmd{"40: IOCAlarmReset"} = "IOCAlarmReset";
    $remoteCmd{"40: IOCBackfill"} = "IOCBackfill";
    $remoteCmd{"40: IOCBase"} = "IOCBase";
    $remoteCmd{"40: IOCCooling"} = "IOCCooling";
    $remoteCmd{"40: IOCCycleStart"} = "IOCCycleStart";
    $remoteCmd{"40: IOCCycleStop"} = "IOCCycleStop";
    $remoteCmd{"40: IOCFastIdle"} = "IOCFastIdle";
    $remoteCmd{"40: IOCIsolate"} = "IOCIsolate";
    $remoteCmd{"40: IOCLeakCheck"} = "IOCLeakCheck";
    $remoteCmd{"40: IOCSetFlow"} = "IOCSetFlow";
    $remoteCmd{"40: IOCSetFlowMFC"} = "IOCSetFlowMFC";
    $remoteCmd{"40: IOCSetIdleFlow"} = "IOCSetIdleFlow";
    $remoteCmd{"40: IOCSetPid"} = "IOCSetPid";
    $remoteCmd{"40: IOCSetPress"} = "IOCSetPress";
    $remoteCmd{"40: IOCSetValve"} = "IOCSetValve";
    $remoteCmd{"40: IOCVacuum"} = "IOCVacuum";
    $remoteCmd{"40: LPABORG"} = "LPABORG";
    $remoteCmd{"40: LPAMHSRecover"} = "LPAMHSRecover";
    $remoteCmd{"40: LPAbort"} = "LPAbort";
    $remoteCmd{"40: LPAlarmReset"} = "LPAlarmReset";
    $remoteCmd{"40: LPCancelLoad"} = "LPCancelLoad";
    $remoteCmd{"40: LPCancelUnload"} = "LPCancelUnload";
    $remoteCmd{"40: LPChangeAccess"} = "LPChangeAccess";
    $remoteCmd{"40: LPChangeHost"} = "LPChangeHost";
    $remoteCmd{"40: LPChangeService"} = "LPChangeService";
    $remoteCmd{"40: LPClamp"} = "LPClamp";
    $remoteCmd{"40: LPClose"} = "LPClose";
    $remoteCmd{"40: LPDock"} = "LPDock";
    $remoteCmd{"40: LPIDErrorLED"} = "LPIDErrorLED";
    $remoteCmd{"40: LPIN"} = "LPIN";
    $remoteCmd{"40: LPInitialize"} = "LPInitialize";
    $remoteCmd{"40: LPLoadRequest"} = "LPLoadRequest";
    $remoteCmd{"40: LPMClose"} = "LPMClose";
    $remoteCmd{"40: LPMDock"} = "LPMDock";
    $remoteCmd{"40: LPMOpen"} = "LPMOpen";
    $remoteCmd{"40: LPMUnDock"} = "LPMUnDock";
    $remoteCmd{"40: LPMap"} = "LPMap";
    $remoteCmd{"40: LPN2Flow"} = "LPN2Flow";
    $remoteCmd{"40: LPN2Nozzle"} = "LPN2Nozzle";
    $remoteCmd{"40: LPN2NozzleReserve"} = "LPN2NozzleReserve";
    $remoteCmd{"40: LPN2Purge"} = "LPN2Purge";
    $remoteCmd{"40: LPORGSH"} = "LPORGSH";
    $remoteCmd{"40: LPOpeSwitch"} = "LPOpeSwitch";
    $remoteCmd{"40: LPOpen"} = "LPOpen";
    $remoteCmd{"40: LPOut"} = "LPOut";
    $remoteCmd{"40: LPPurgeMode"} = "LPPurgeMode";
    $remoteCmd{"40: LPReload"} = "LPReload";
    $remoteCmd{"40: LPReserve"} = "LPReserve";
    $remoteCmd{"40: LPUnClamp"} = "LPUnClamp";
    $remoteCmd{"40: LPUnDock"} = "LPUnDock";
    $remoteCmd{"40: LPUnloadRequest"} = "LPUnloadRequest";
    $remoteCmd{"40: MONAlarmReset"} = "MONAlarmReset";
    $remoteCmd{"40: MONInitialize"} = "MONInitialize";
    $remoteCmd{"40: MONMeasureStart"} = "MONMeasureStart";
    $remoteCmd{"40: MONModeChange"} = "MONModeChange";
    $remoteCmd{"40: MONRecipeExist"} = "MONRecipeExist";
    $remoteCmd{"40: MONRecipeListReq"} = "MONRecipeListReq";
    $remoteCmd{"40: MTRAWCCalib"} = "MTRAWCCalib";
    $remoteCmd{"40: MTRAWCEnable"} = "MTRAWCEnable";
    $remoteCmd{"40: MTRAWCSave"} = "MTRAWCSave";
    $remoteCmd{"40: MTRAbort"} = "MTRAbort";
    $remoteCmd{"40: MTRAlarmReset"} = "MTRAlarmReset";
    $remoteCmd{"40: MTRArmReturn"} = "MTRArmReturn";
    $remoteCmd{"40: MTRAutoTeach"} = "MTRAutoTeach";
    $remoteCmd{"40: MTRDataSave"} = "MTRDataSave";
    $remoteCmd{"40: MTRHome"} = "MTRHome";
    $remoteCmd{"40: MTRHomeCalib"} = "MTRHomeCalib";
    $remoteCmd{"40: MTRInitialize"} = "MTRInitialize";
    $remoteCmd{"40: MTRLoad"} = "MTRLoad";
    $remoteCmd{"40: MTRMove"} = "MTRMove";
    $remoteCmd{"40: MTRPause"} = "MTRPause";
    $remoteCmd{"40: MTRPoint"} = "MTRPoint";
    $remoteCmd{"40: MTRResume"} = "MTRResume";
    $remoteCmd{"40: MTRServoOff"} = "MTRServoOff";
    $remoteCmd{"40: MTRSetLowSpeed"} = "MTRSetLowSpeed";
    $remoteCmd{"40: MTRSetSpeed"} = "MTRSetSpeed";
    $remoteCmd{"40: MTRSetZSpeed"} = "MTRSetZSpeed";
    $remoteCmd{"40: MTRUnload"} = "MTRUnload";
    $remoteCmd{"40: MTRWafClamp"} = "MTRWafClamp";
    $remoteCmd{"40: PMAlarmReset"} = "PMAlarmReset";
    $remoteCmd{"40: PMInitialize"} = "PMInitialize";
    $remoteCmd{"40: PMSetSystemTime"} = "PMSetSystemTime";
    $remoteCmd{"40: PMWaferGet"} = "PMWaferGet";
    $remoteCmd{"40: PMWaferPut"} = "PMWaferPut";
    $remoteCmd{"40: RCAbort"} = "RCAbort";
    $remoteCmd{"40: RCCompoChange"} = "RCCompoChange";
    $remoteCmd{"40: RCLatchReset"} = "RCLatchReset";
    $remoteCmd{"40: RCModeChange"} = "RCModeChange";
    $remoteCmd{"40: RCPause"} = "RCPause";
    $remoteCmd{"40: RCReset"} = "RCReset";
    $remoteCmd{"40: RCResume"} = "RCResume";
    $remoteCmd{"40: RCSetActive"} = "RCSetActive";
    $remoteCmd{"40: RCSetDummy"} = "RCSetDummy";
    $remoteCmd{"40: RCSetVirtualDI"} = "RCSetVirtualDI";
    $remoteCmd{"40: RCStart"} = "RCStart";
    $remoteCmd{"40: RCTimeChange"} = "RCTimeChange";
    $remoteCmd{"40: RCmdMFCGetSpec"} = "RCmdMFCGetSpec";
    $remoteCmd{"40: RCmdPCVLearn"} = "RCmdPCVLearn";
    $remoteCmd{"40: RCmdPCVReadLearn"} = "RCmdPCVReadLearn";
    $remoteCmd{"40: RCmdPCVReadParam"} = "RCmdPCVReadParam";
    $remoteCmd{"40: RCmdPCVWriteLearn"} = "RCmdPCVWriteLearn";
    $remoteCmd{"40: RCmdPCVWriteParam"} = "RCmdPCVWriteParam";
    $remoteCmd{"40: SSAbort"} = "SSAbort";
    $remoteCmd{"40: SSAlarmReset"} = "SSAlarmReset";
    $remoteCmd{"40: SSClamp"} = "SSClamp";
    $remoteCmd{"40: SSDown"} = "SSDown";
    $remoteCmd{"40: SSHomePos"} = "SSHomePos";
    $remoteCmd{"40: SSIndex"} = "SSIndex";
    $remoteCmd{"40: SSInitialize"} = "SSInitialize";
    $remoteCmd{"40: SSProcPos"} = "SSProcPos";
    $remoteCmd{"40: SSRotate"} = "SSRotate";
    $remoteCmd{"40: SSStop"} = "SSStop";
    $remoteCmd{"40: SSUnclamp"} = "SSUnclamp";
    $remoteCmd{"40: SSUp"} = "SSUp";
    $remoteCmd{"40: SSZAxis"} = "SSZAxis";
    $remoteCmd{"40: TMAlarmReset"} = "TMAlarmReset";
    $remoteCmd{"40: TMBERBWafMove1"} = "TMBERBWafMove1";
    $remoteCmd{"40: TMFERBWafMove1"} = "TMFERBWafMove1";
    $remoteCmd{"40: TMInitialize"} = "TMInitialize";
    $remoteCmd{"40: TMIoc1"} = "LLL";
    $remoteCmd{"40: TMIoc2"} = "LLL2";
    $remoteCmd{"40: TMIoc3"} = "RLL";
    $remoteCmd{"40: TMIoc4"} = "RLL2";
    $remoteCmd{"40: TMMaintenance"} = "TMMaintenance";
    $remoteCmd{"40: TMSetSystemTime"} = "TMSetSystemTime";
    $remoteCmd{"40: TMSysStatus"} = "TMSysStatus";
    $remoteCmd{"40: TMWhc"} = "TMWhc";
    $remoteCmd{"40: UIOBuzzerOFF"} = "UIOBuzzerOFF";
    $remoteCmd{"40: UIOBuzzerON"} = "UIOBuzzerON";
    $remoteCmd{"40: UIOSignalOFF"} = "UIOSignalOFF";
    $remoteCmd{"40: UIOSignalON"} = "UIOSignalON";
    $remoteCmd{"40: WHCIOCPressDiff"} = "WHCIOCPressDiff";
    $remoteCmd{"40: WHCSensSetCurPos"} = "WHCSensSetCurPos";
    $remoteCmd{"40: WHCSensSetPos"} = "WHCSensSetPos";
    $remoteCmd{"40: WHCSensSetThreshold"} = "WHCSensSetThreshold";
    $remoteCmd{"40: WHCSensWriteEEPROM"} = "WHCSensWriteEEPROM";
}