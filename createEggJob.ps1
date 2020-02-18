function createEggJob {
    param ([int]$jobs, $int_records, $exp_records, $scriptblock, $cache_dir, $replace, $path, $errorlog)
    $stopwatch =  [system.diagnostics.stopwatch]::StartNew()

    function checkJobState {
        $jobStatus = get-job * | Select-Object State | foreach ( { $_.State })
        if ("Running" -in $JobStatus) { $Global:Status = "Running" }else { $Global:Status = "Done" }
    }
    function Get-RoundedDown($d, $digits) {
        $scale = [Math]::Pow(10, $digits)
        [Math]::Truncate($d * $scale) / $scale
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
        if ($scriptblock -like "*$arraycheck*") {
            $scriptblock = $scriptblock -replace "$arraycheck", "xyzzy"
            $scriptblock = $scriptblock -replace "$replace", "myjobvar"
            $scriptblock = $scriptblock -replace "xyzzy", "$arraycheck"
        }
        else {
            $scriptblock = $scriptblock -replace "$replace", "myjobvar"
        }
    }
    if ($path) {
        $scriptblock = $scriptblock -replace "\`$path", "$path"
    }
    #
    #Number of seperate jobs to spawn
    $jobs = $jobs

    $y = 0..($jobs - 1)
    #divide the jobs up equally
    $items = Get-RoundedDown ($records.count / $y.count)
    if (($records.count / $y.count) -like "*.*") { $items = $items + 1 }
    $itemsEgg = $items
    $scriptblockEgg = $scriptblock
    $recordsEgg = $records
    $cache_dirEgg = $cache_dir
    $errorlogEgg = $errorlog
    foreach ($x in $y) {
        start-job -Name ([string]$x + "_eggjob") -ScriptBlock {
        
            param ([string]$x, [int]$itemsEgg, $recordsEgg, $scriptblockEgg, $cache_dirEgg, $errorlogEgg) 
                                
            if ($x -eq 0) { $aEgg = 0 } else { $aEgg = (([int]$itemsEgg * $x) + 1) }               
            $bEgg = (([int]$itemsEgg * $x) + [int]$itemsEgg)
                              
            #Distribute the workload
            $xrecordsEgg = $recordsEgg[[int]$aEgg..[int]$bEgg] 

            #Each job now has a portion of the work to run.
            foreach ($myjobvar in $xrecordsEgg) {
            try{
            Invoke-Expression $scriptblockEgg
            }catch{$_.Exception.Message | out-file ($errorlogEgg + "\errorEggJob_" + $x + ".txt") -append}     
            }  
        } -ArgumentList ($x, $itemsEgg, $recordsEgg, $scriptblockEgg, $cache_dirEgg, $errorlogEgg)
    }

    checkJobState
    while ($Global:Status -notlike "Done") {
        start-sleep 3
        checkJobState
    }
    remove-Job *
    $stopwatch.Stop()
     
    clear-variable exp_records -ErrorAction SilentlyContinue
    clear-variable int_records -ErrorAction SilentlyContinue
    
    write-host ("All jobs are done. Time elapsed: " + $stopwatch.elapsed) -ForegroundColor Cyan
}
