Import-Module .\bktree

$bktree = [BKTree]::new()

$bktree.add('fold')
$bktree.add('mold')
$bktree.add('hold')
$bktree.add('bold')
$bktree.add('fork')
$bktree.add('beer')
$bktree.add('hole')
$bktree.add('shim')

# Uncomment following block to load a dictionary from text file with a list of words

#$lines = Get-Content "$PSScriptRoot\words.txt" | Where-Object { $_ -notmatch '^\s+$' } 
#foreach ($line in $lines) {
    #$line_clean = $line.Trim().ToLower()
    #$bktree.Add($line_clean)
#}


$stopWatch = [System.Diagnostics.Stopwatch]::StartNew()     
Write-Host ($bktree.Search('cold', 2))
$stopWatch.Stop()
Write-Host "Search finished in $($stopWatch.Elapsed.TotalSeconds.ToString(".00")) sec."

$bktree.SaveArrays("$PSScriptRoot\dictionary.bin")

$stopWatch = [System.Diagnostics.Stopwatch]::StartNew()     
$bktree.LoadArrays("$PSScriptRoot\dictionary.bin")
$stopWatch.Stop()
Write-Host "Load finished in $($stopWatch.Elapsed.TotalSeconds.ToString(".00")) sec."

$stopWatch = [System.Diagnostics.Stopwatch]::StartNew()     
Write-Host ($bktree.SearchFast('cold', 2))
$stopWatch.Stop()
Write-Host "Search finished in $($stopWatch.Elapsed.TotalSeconds.ToString(".00")) sec."
