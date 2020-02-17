#Process jobs concurrently by invoking this function. 

#Specify the amount of jobs, the records to use, and the command to perform on the record.

#Automatically balances items based on the amount of jobs

#Cleans up jobs when it's done

# $x is the variable for each specific job.

# $myjobvar needs to be used in your command as a placeholder for an item in your record array.

#Command is more than one line? Create a variable with your command as a string in parenthesis and pass the variable to command, just make sure to include $myjobvar where necessary.

#Params: 

#Jobs (how many jobs to create), 

#int_records (numeric value), 

#exp_records (invoke a command to retrieve your records), 

#command (command to use on your records)

#Usage Examples: 

#Int_Record; createEggJob -jobs 6 -int_records (1..450) -command '$myjobvar | out-file c:\temp\results_$x.txt -append'

#Exp_Record; createEggJob -jobs 15 -exp_records 'get-content c:\temp\list.txt' -command '$myjobvar | out-file c:\temp\results_$x.txt -append'

