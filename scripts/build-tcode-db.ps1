param()
$USOBT = "C:\Users\UtsavMukherjee\Documents\IBM Basis+Security Curriculam\SAP GEN AI\Agentic AI\BoB\UM_Authority-Check-Analyzer\USOBT.txt"
$USOBX = "C:\Users\UtsavMukherjee\Documents\IBM Basis+Security Curriculam\SAP GEN AI\Agentic AI\BoB\UM_Authority-Check-Analyzer\USOBX.txt"
$OUT   = "scripts\tcode-db-output.js"

Write-Host "Reading USOBX..."
$proposed = @{}
$ln = 0
foreach ($line in [System.IO.File]::ReadLines($USOBX)) {
    $ln++
    if ($ln -le 6) { continue }
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $p = $line -split "`t"
    if ($p.Count -lt 8) { continue }
    $name   = $p[1].Trim()
    $typ    = $p[2].Trim()
    $obj    = $p[3].Trim()
    $okflag = $p[7].Trim()
    if ($typ -ne 'TR' -and $typ -ne 'RF') { continue }
    if ($okflag -eq 'Y' -or $okflag -eq 'X') {
        $proposed["$name|||$obj"] = $okflag
    }
}
Write-Host "USOBX: $($proposed.Count) tcode+object pairs"

Write-Host "Reading USOBT..."
$db = @{}
$ln2 = 0
foreach ($line in [System.IO.File]::ReadLines($USOBT)) {
    $ln2++
    if ($ln2 -le 5) { continue }
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $p = $line -split "`t"
    if ($p.Count -lt 5) { continue }
    $name  = $p[1].Trim()
    $typ   = $p[2].Trim()
    $obj   = $p[3].Trim()
    $field = $p[4].Trim()
    $val   = if ($p.Count -ge 6) { $p[5].Trim() } else { "" }
    if ([string]::IsNullOrWhiteSpace($name) -or [string]::IsNullOrWhiteSpace($obj)) { continue }
    if ($typ -ne 'TR' -and $typ -ne 'RF') { continue }
    $xkey = "$name|||$obj"
    if (-not $proposed.ContainsKey($xkey)) { continue }
    if (-not $db.ContainsKey($name)) { $db[$name] = @{} }
    if (-not $db[$name].ContainsKey($obj)) { $db[$name][$obj] = @{} }
    if ([string]::IsNullOrWhiteSpace($field)) { continue }
    if (-not $db[$name][$obj].ContainsKey($field)) { $db[$name][$obj][$field] = [System.Collections.Generic.List[string]]::new() }
    if (-not [string]::IsNullOrWhiteSpace($val)) { $db[$name][$obj][$field].Add($val) }
}
Write-Host "USOBT: $($db.Count) unique T-Codes/programs loaded"

Write-Host "Generating JavaScript..."
$sb = [System.Text.StringBuilder]::new()
$genDate = (Get-Date -Format 'yyyy-MM-dd HH:mm')
$null = $sb.AppendLine("// AUTO-GENERATED from USOBT + USOBX (SAP-Delivered Proposals)")
$null = $sb.AppendLine("// Generated: $genDate")
$null = $sb.AppendLine("// Total entries: $($db.Count)")
$null = $sb.AppendLine("var TCODE_DB = {")

$sorted = $db.Keys | Sort-Object
$total  = $sorted.Count
$idx    = 0

foreach ($tcode in $sorted) {
    $idx++
    $tcEsc = $tcode.Replace('\', '\\').Replace("'", "\'")
    $null = $sb.Append("  '$tcEsc':[")
    $entries = [System.Collections.Generic.List[string]]::new()

    foreach ($obj in ($db[$tcode].Keys | Sort-Object)) {
        $fields = $db[$tcode][$obj]
        $objEsc = $obj.Replace('\', '\\').Replace("'", "\'")
        $propKey = "$tcode|||$obj"
        $src = if ($proposed[$propKey] -eq 'Y') { 'SAP-Proposed' } else { 'SAP-Active' }

        $fp = [System.Collections.Generic.List[string]]::new()
        foreach ($fld in ($fields.Keys | Sort-Object)) {
            $vals = $fields[$fld]
            $valList = ($vals | Sort-Object | Select-Object -Unique) -join ','
            $fldEsc = $fld.Replace('\', '\\').Replace("'", "\'")
            $valEsc = $valList.Replace('\', '\\').Replace("'", "\'")
            $fp.Add("$fldEsc=$valEsc")
        }
        $fieldStr = ($fp -join '|').Replace('\', '\\').Replace("'", "\'")
        $entries.Add("'$objEsc|$fieldStr|$src'")
    }

    $entryStr = $entries -join ','
    $comma = if ($idx -lt $total) { ',' } else { '' }
    $null = $sb.AppendLine("$entryStr]$comma")
}

$null = $sb.AppendLine("};")
Set-Content -Path $OUT -Value $sb.ToString() -Encoding UTF8
Write-Host "Done -> $OUT  (T-Codes: $total)"
