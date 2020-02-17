function createEggJob {
    param ([int]$jobs, $int_records, $exp_records, $command, $cache_dir, $replace, $path)
    $stopwatch =  [system.diagnostics.stopwatch]::StartNew()
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
    if ($path) {
        $command = $command -replace "\`$path", "$path"
    }
    #
    #Number of seperate jobs to spawn
    $jobs = $jobs

    $y = 0..($jobs - 1)
    #divide the jobs up equally
    $items = [math]::Round($records.count / $y.count)
    if (($records.count / $y.count) -like "*.*") { $items = $items + 1 }
    $itemsEgg = $items
    $commandEgg = $command
    $recordsEgg = $records
    $cache_dirEgg = $cache_dir
    foreach ($x in $y) {
        start-job -Name ([string]$x + "_eggjob") -ScriptBlock {
        
            param ([string]$x, [int]$itemsEgg, $recordsEgg, $commandEgg, $cache_dirEgg) 
                                
            if ($x -eq 0) { $aEgg = 0 } else { $aEgg = (([int]$itemsEgg * $x) + 1) }               
            $bEgg = (([int]$itemsEgg * $x) + [int]$itemsEgg)
                              
            #Distribute the workload
            $xrecordsEgg = $recordsEgg[[int]$aEgg..[int]$bEgg] 

            #Each job now has a portion of the work to run.
            foreach ($myjobvar in $xrecordsEgg) {
                Invoke-Expression $command
                
            }  
        } -ArgumentList ($x, $itemsEgg, $recordsEgg, $commandEgg, $cache_dirEgg)
    }

    checkJobState
    while ($Global:Status -notlike "Done") {
        start-sleep 3
        checkJobState
    }
    remove-Job *
    $stopwatch.Stop()
     
    clear-variable myjobvar -ErrorAction SilentlyContinue
    clear-variable command -ErrorAction SilentlyContinue
    clear-variable exp_records -ErrorAction SilentlyContinue
    clear-variable int_records -ErrorAction SilentlyContinue
    
    write-host ("All jobs are done. Time elapsed: " + $stopwatch.elapsed) -ForegroundColor Cyan
}
