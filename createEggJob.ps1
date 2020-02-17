function createEggJob {
    param ([int]$jobs, $int_records, $exp_records, $command, $cache_dir, $replace)

    function checkJobState {
        $jobStatus = get-job * | Select-Object State | foreach ( { $_.State })
        if ("Running" -in $JobStatus) { $Global:Status = "Running" }else { $Global:Status = "Done" }
    }

    #Your content
    if ($int_records) {
        $records = $int_records
    }
    if ($exp_records) {
        $records = Invoke-Expression $exp_records
    }
    $cache_dir = $cache_dir
   if ($replace) {
    #Can you figure out why I had to do this with replace? 
    $arraycheck = ($replace + "s")
    if ($command -like "*$arraycheck*") {
        $command = $command -replace "$arraycheck", "xyzzy"
        $command = $command -replace "$replace", "myjobvar"
        $command = $command -replace "xyzzy", "$arraycheck"
    }
    else {
        $command = $command -replace "$replace", "myjobvar"
    }
}
    #
    #Number of seperate jobs to spawn
    $jobs = $jobs

    $y = 0..($jobs - 1)
    #divide the jobs up equally
    $items = [math]::Round($records.count / $y.count)
    if (($records.count / $y.count) -like "*.*") { $items = $items + 1 }

    foreach ($x in $y) {
        start-job -Name ([string]$x + "_eggjob") -ScriptBlock {
        
            param ([string]$x, [int]$items, $records, $command, $cache_dir) 
                                
            if ($x -eq 0) { $a = 0 } else { $a = (([int]$items * $x) + 1) }               
            $b = (([int]$items * $x) + [int]$items)
                              
            #Distribute the workload
            $xrecords = $records[[int]$a..[int]$b] 

            #Each job now has a portion of the work to run.
            foreach ($myjobvar in $xrecords) {
                Invoke-Expression $command
                
            }  
        } -ArgumentList ($x, $items, $records, $command, $cache_dir)
    }

    checkJobState
    while ($Global:Status -notlike "Done") {
        start-sleep 3
        checkJobState
    }
    remove-Job *
     
    clear-variable myjobvar -ErrorAction SilentlyContinue
    clear-variable command -ErrorAction SilentlyContinue
    clear-variable exp_records -ErrorAction SilentlyContinue
    clear-variable int_records -ErrorAction SilentlyContinue
    
    write-host "All jobs are done." -ForegroundColor Cyan
}
