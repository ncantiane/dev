' =========================================================
' Script to get backup state of veeam backups
' (c) Jeroen Steenhuis - ACA-IT - 2012
' =========================================================

SetLocale(1043)

dim output
 
set output = wscript.stdout

' Required Variables
Const PROGNAME = "check_printer"
Const VERSION = "0.0.1"
Const DEBUGMODE = 0

'Cons for return val's
Const OK = 0
Const WARNING = 1
Const CRITICAL = 2
Const UNKNOWN = 3

' Default settings and variable initialization
intDaysSinceLastSuccessDateTime = 9999
intDaysSinceLastFailedDate = 9999
strVeeamBackupPath = ""
strVeeamBackupName = ""
return_code = UNKNOWN
msg = "Error while parsing veeam backup job log"
msgfailed = "Failed backup job found"
intBackupWarning =  1
intBackupCritical =  3

strBytesBackedUpLastSucces = ""
strBytesBackedUpLastFailed = ""
strLastBackupSuccessEndDateTime = ""
strLastBackupFailedEndDateTime = ""

'### Get command line arguments ###
Set Args = WScript.Arguments
If (Args.Count < 2) then
	output.writeline "usage: check_veaam backup_path job_name /w:warning_level /c:critical_level"
	output.writeline " warning_level = days since last successfull backup to generate warning"
	output.writeline " critical_level = days since last successfull backup to generate warning"
	output.writeline ""

	msg = "Error while parsing veeam backup job log"
	output.writeline msg
	WScript.quit return_code
End If

strVeeamBackupPath = Args.Item(0)
strVeeamBackupName = Args.Item(1)

'### If we define /warning /critical on commandline it should override the script default. ###
If Args.Named.Exists("w") Then intBackupWarning = cint(Args.Named("w"))
If Args.Named.Exists("c") Then intBackupCritical = cint(Args.Named("c"))


'### Open backup log file ###
filename = strVeeamBackupPath+"\BackupJob_"+strVeeamBackupName+".log"
If DEBUGMODE then output.writeline "Opening:"+filename
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.OpenTextFile(filename, 1)

'### Parse backup log file line by line ###
Do Until objFile.AtEndOfStream
	strLine= objFile.ReadLine()

	'### Search for lines with "Starting job mode: " to extract start date and time of backup start ###
	if (Instr(strLine, "Starting job mode: ")) Then

		If DEBUGMODE then output.writeline "strLine="+strLine

		'### Extract Date ###
		strBackupStartDateTime = Left (strLine, Instr(strLine,"]") - 1)
		strBackupStartDateTime = Right(strBackupStartDateTime,Len(strBackupStartDateTime) - 1)
		strBackupStartDateTime = Replace(strBackupStartDateTime,".","/")

		If DEBUGMODE then output.writeline "strBackupStartDateTime="+strBackupStartDateTime
	End If

	'### Search for lines with "Job session" ###
	If(InStr(strLine, "Job session")) Then 

		'### Search for "has been completed, status: 'Success'" ###
		If(InStr(strLine, "has been completed, status: 'Success'")) Then 

			If DEBUGMODE then output.writeline "strLine="+strLine
	
			'### Extract Date ###
			strBackupSuccessDateTime = Left (strLine, Instr(strLine,"]") - 1)
			strBackupSuccessDateTime = Right(strBackupSuccessDateTime,Len(strBackupSuccessDateTime) - 1)
			strBackupSuccessDateTime = Replace(strBackupSuccessDateTime,".","/")

			If DEBUGMODE then output.writeline "strBackupSuccessDateTime="+strBackupSuccessDateTime

			'### Calculate days since last successfull backup date ###
			intDaysSinceSuccessDate= int(DateDiff("h", strBackupSuccessDateTime, now()) / 24)
			If DEBUGMODE then output.writeline "intDaysSinceSuccessDate="+Cstr(intDaysSinceSuccessDate)

			'### If this job has finished earlier than the last found job then store this date, bytes and minutes
			if (intDaysSinceLastSuccessDateTime > intDaysSinceSuccessDate) then 
				intDaysSinceLastSuccessDateTime = intDaysSinceSuccessDate
				strLastBackupSuccessEndDateTime = strBackupSuccessDateTime				

				strBytesBackedUpLastSuccess = Right(strLine,Len(StrLine) - Instr(strLine, "'Success', '") - 11)
				strBytesBackedUpLastSuccess = Left(strBytesBackedUpLastSuccess,Instr(strBytesBackedUpLastSuccess, "'") - 1)

				intBackupMinutesLastSuccess = int(DateDiff("n", strBackupStartDateTime, strBackupSuccessDateTime))
			End if

			If DEBUGMODE then output.writeline "intDaysSinceLastSuccessDateTime="+Cstr(intDaysSinceLastSuccessDateTime)
		End If

		'### Search for "has been completed, status: 'Failed'" ###
		If(InStr(strLine, "has been completed, status: 'Failed'")) Then 

			If DEBUGMODE then output.writeline "strLine="+strLine

			'### Extract Date ###
			strBackupFailedDateTime = Left (strLine, Instr(strLine,"]") - 1)
			strBackupFailedDateTime = Right(strBackupFailedDateTime,Len(strBackupSuccessDateTime) - 1)
			strBackupFailedDateTime = Replace(strBackupFailedDateTime,".","/")

			If DEBUGMODE then output.writeline "strBackupFailedDateTime="+strBackupFailedDateTime

			'### Calculate days since last failed backup date ###
			intDaysSinceLastFailedDate= int(DateDiff("h", strBackupFailedDateTime , now()) / 24)
			If DEBUGMODE then output.writeline "intDaysSinceLastFailedDate="+Cstr(intDaysSinceLastFailedDate)

			'### If this job has finished earlier than the last found job then store this date, bytes and minutes
			If (intDaysSinceLastFailedDate > intDaysSinceFailedDate) then
				intDaysSinceLastFailedDate = intDaysSinceFailedDate
				strLastBackupFailedEndDateTime = strBackupFailedDateTime

				strBytesBackedUpLastFailed = Right(strLine,Len(StrLine) - Instr(strLine, "'Failed', '") - 10)
				strBytesBackedUpLastFailed = Left(strBytesBackedUpLastFailed,Instr(strBytesBackedUpLastFailed, "'") - 1)

				intBackupMinutesLastFailed = int(DateDiff("n", strBackupStartDateTime, strBackupFailedDateTime))
			End If

			If DEBUGMODE then output.writeline "intDaysSinceLastFailedDate="+Cstr(intDaysSinceLastFailedDate)
		End If
	End If
Loop

strDaysSinceLastSuccessDateTime = cstr (intDaysSinceLastSuccessDateTime)
if (strDaysSinceLastSuccessDateTime = "9999") then
	strDaysSinceLastSuccessDateTime = "Never Successfull"
end if

'### Build a nice looking and consistent date time string
if (strLastBackupSuccessEndDateTime <> "") then
	strLastBackupSuccessEndDateTime = cstr(Day(strLastBackupSuccessEndDateTime)) + "-" + cstr(Month(strLastBackupSuccessEndDateTime)) + "-" + cstr(Year(strLastBackupSuccessEndDateTime)) + " " + FormatDateTime(strLastBackupSuccessEndDateTime,vbShortTime)
else
	strLastBackupSuccessEndDateTime = "Never"
end if


'### Check warning levels ###
if (cint(intDaysSinceLastSuccessDateTime) < cint(intBackupWarning)) then 
	return_code = OK
	msg = "Job: " + strVeeamBackupName + " last ended on  " + strLastBackupSuccessEndDateTime + " was Successfull"
end if
if (cint(intDaysSinceLastSuccessDateTime) >= cint(intBackupWarning)) then 
	return_code = WARNING
	msg = "Job: " + strVeeamBackupName + " last ended on  " + strLastBackupSuccessEndDateTime + " was Successfull but to long ago"
end if
if (cint(intDaysSinceLastSuccessDateTime) >= cint(intBackupCritical)) then 
	return_code = CRITICAL
	msg = "Job: " + strVeeamBackupName + " last ended on  " + strLastBackupSuccessEndDateTime + " was Successfull but to long ago"
end if

'### Build a nice looking and consistent date time string
if (strLastBackupFailedEndDateTime <> "") then 
	strLastBackupFailedEndDateTime = cstr(Day(strLastBackupFailedEndDateTime)) + "-" + cstr(Month(strLastBackupFailedEndDateTime)) + "-" + cstr(Year(strLastBackupFailedEndDateTime)) + " " + FormatDateTime(strLastBackupFailedEndDateTime,vbShortTime)
else
	strLastBackupFailedEndDateTime = "Never"
end if


'### Check if last backup has failed ###
if (intDaysSinceLastSuccessDateTime >= intDaysSinceLastFailedDate) then 
	return_code = CRITICAL
	msg = "Job: " + strVeeamBackupName + " last ended on  " + strLastBackupFailedEndDateTime + " was FAILED"
end if

msg = msg + ", Days since last successfull backup: " + strDaysSinceLastSuccessDateTime + ", Bytes Backed Up: " + strBytesBackedUpLastSuccess + ", Elapsed Time: " + cstr(intBackupMinutesLastSuccess) + " Minutes."


' Nice Exit with msg and exitcode
output.writeline msg
WScript.quit return_code
