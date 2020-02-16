#EGGSTOASTBACON :: https://github.com/eggstoastbacon
#Process jobs concurrently by invoking this function. 
#Specify the amount of jobs, the records to use, and the command to perform on the record.
#Automatically balances items based on the amount of jobs
#Cleans up jobs when it's done
# $x is the variable for each specific job.
# $myjobvar needs to be used in your command as a placeholder for an item in your record array.
#
#Params: 
#Jobs (how many jobs to create), 
#int_records (numeric value), 
#exp_records (invoke a command to retrieve your records), 
#command (command to use on your records)
#Usage Examples: 
#Int_Record; createEggJob -jobs 6 -int_records (1..450) -command '$myjobvar | out-file c:\temp\results_$x.txt -append'
#
#Exp_Record; createEggJob -jobs 15 -exp_records 'get-content c:\temp\list.txt' -command '$myjobvar | out-file c:\temp\results_$x.txt -append'
#

function createEggJob{
param ([int]$jobs, $int_records, $exp_records, $command)

function checkJobState {
    $jobStatus = get-job * | Select-Object State | foreach ( { $_.State })
    if ("Running" -in $JobStatus) { $Global:Status = "Running" }else { $Global:Status = "Done" }
}

#Your content
if ($int_records){
$records = $int_records
}
if ($exp_records){
$records = Invoke-Expression $exp_records
}

$command = $command.replace("myjobvar","xrecord")

#Number of seperate jobs to spawn
$jobs = $jobs

$y = 0..($jobs - 1)
#divide the jobs up equally
$items = [math]::Round($records.count / $y.count)
if(($records.count / $y.count) -like "*.*"){$items = $items + 1}

    foreach ($x in $y) {
        start-job -Name ([string]$x + "_eggjob") -ScriptBlock {
                param ([string]$x,[int]$items,$records,$command) 
                                
                if($x -eq 0){$a = 0} else {$a = (([int]$items * $x) + 1)}               
                $b = (([int]$items * $x) + [int]$items)
                              
                #Distribute the workload
                $xrecords = $records[[int]$a..[int]$b] 

                #Each job now has a portion of the work to run.
                foreach ($xrecord in $xrecords) {
                Invoke-Expression $command
                }  
            } -ArgumentList ($x,$items,$records,$command)
    }

    checkJobState
    while($Global:Status -notlike "Done"){
    start-sleep 3
    checkJobState
    }
    remove-job *
    clear-variable xrecord -ErrorAction SilentlyContinue
    clear-variable command -ErrorAction SilentlyContinue
    clear-variable exp_records -ErrorAction SilentlyContinue
    clear-variable int_records -ErrorAction SilentlyContinue
    write-host "All jobs are done." -ForegroundColor Cyan

    }

