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
    $stopwatch.Stop()
    
    clear-variable myjobvar -ErrorAction SilentlyContinue
    clear-variable command -ErrorAction SilentlyContinue
    clear-variable exp_records -ErrorAction SilentlyContinue
    clear-variable int_records -ErrorAction SilentlyContinue
    
    write-host ("All jobs are done. Time elapsed: " + $stopwatch.elapsed) -ForegroundColor Cyan
}

$cranrows = get-content C:\temp\cran-clean.txt -command $custom


createEggJob -jobs 4 -exp_records 'Get-ChildItem -Path C:\windows -Directory' -command $command

$custom = '
Invoke-webrequest -URI $myjobvar -UseBasicParsing | export-csv c:\temp\status_$x.csv -append 
'

$dirs = Get-ChildItem -Path C:\windows -Directory
Get-ChildItem -Path C:\ -Directory 

# ScriptBlock to compute the file sizes in the directory.
$command = '
    $measure = (Get-ChildItem $_ -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum) 
    $sum = $measure.Sum
    $count = $measure.Count 
    [pscustomobject]@{
        Name = $Measure.Name
        FileCount = $measure.Count
        SizeMB = ([math]::round(($sum/1MB),2))
    } | export-csv c:\temp\dir_$x.csv -append 

    '
