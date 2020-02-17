Process jobs concurrently by invoking this function. You specify the amount of jobs, the records to use, and the command to perform on the record. This  function automatically balances items based on the amount of jobs specified. To keep track of specific job output use the variable for the job number: $x. Cleans up jobs when it's done. Designed to use a cache directory to carry data in and out of jobs, see example below.

Use ($myjobvar) in every command expression, this represents a single item in your record array.

The variable for a specific running job number is ( $x )


Params:

-Jobs (how many jobs to create)

-int_records (numeric value) ex: (1..100)

-exp_records (invoke a command to retrieve your records) ex: 'get-content c:\temp\list.txt'

-Command (command to use on your records) ex: '$myjobvar | out-file c:\temp\results_$x.txt -append'

-cache_dir specify a directory to save processed data. Useful for bringing back in a variable for further processing.


Usage Examples:

int_record:

createEggJob -jobs 6 -int_records (1..450) -command '$myjobvar | out-file c:\temp\results_$x.txt -append'

exp_record:

createEggJob -jobs 15 -exp_records 'get-content c:\temp\list.txt' -command '$myjobvar | out-file c:\temp\results_$x.txt -append'

Command is more than one line? Create a variable with your command as a string in single quotes and pass the variable to command, just make sure to include $myjobvar where necessary.

example:
$mycustomcommand = '
$myjobvar | $line1
$myjobvar | $line2
$myjobvar | $line3
'

createEggJob -jobs 4 -exp_records 'get-content c:\temp\list.txt' -command $mycustomcommand

Use a cache directory to store variable data that's been processed, in the example below I fetch the data of all the jobs and bring it into one variable. I specified the result file and appended the job number variable in my custom command and  I can reasonably assume all of the output files will be called result_<job_number>.txt

example:

createEggJob -jobs 5 -exp_records 'get-content c:\temp\list.txt' -command $mycommand -cache_dir "c:\temp"

$mycommand = '

$myjobvar | out-file $cachedir\results_$x.txt -append

'

$cachedir = "c:\temp"

$results = Get-ChildItem $cachedir | where-object {$.name -like "*results*"} | foreach{get-content -path ("$cachedir" + $_.Name)}
