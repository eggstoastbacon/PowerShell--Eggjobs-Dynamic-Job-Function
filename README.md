Process jobs concurrently by invoking this function. 

Specify the amount of jobs, the records to use, and the command to perform on the record.

Automatically balances items based on the amount of jobs

Cleans up jobs when it's done

// $x is the variable for each specific job.

// $myjobvar needs to be used in your command as a placeholder for an item in your record array.

Command is more than one line? Create a variable with your command as a string in single quotes and pass the variable to command, just make sure to include $myjobvar where necessary. 

example:

$mycustomcommand = '

$myjobvar | $line1

$myjobvar | $line2

$myjobvar | $line3

'

createEggJob -jobs 4 -exp_records 'get-content c:\temp\list.txt' -command $mycustomcommand

#Params: 

Jobs (how many jobs to create), 

int_records (numeric value), 

exp_records (invoke a command to retrieve your records), 

command (command to use on your records)

#Usage Examples: 

Int_Record; createEggJob -jobs 6 -int_records (1..450) -command '$myjobvar | out-file c:\temp\results_$x.txt -append'

Exp_Record; createEggJob -jobs 15 -exp_records 'get-content c:\temp\list.txt' -command '$myjobvar | out-file c:\temp\results_$x.txt -append'

cache_dir; specify a directory to save processed data. Useful for bringing back in a variable for further processing.

Example:

createEggJob -jobs 5 -exp_records 'get-content c:\temp\list.txt' -command $mycommand -cachedir "c:\temp"
$mycommand = '
$myjobvar | out-file $cachedir\results_$x.txt -append
'
$cachdir = "c:\temp" 
$results = Get-ChildItem $cachdir | where-object {$_.name -like "*results_*"} | foreach{get-content -path ("$cachdir\" + $_.Name)}

