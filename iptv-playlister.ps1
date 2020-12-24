$aDesiredChannels = Get-Content  -Encoding UTF8 -Path ".\channels.json" | ConvertFrom-Json
$aDesiredChannels | fl

$sOutFilePath = ".\out.m3u8"
$sSimpleChannelListPath = ".\channelslist.txt"

$aSimpleChannelList= Get-Content $sSimpleChannelListPath -Encoding UTF8
$aSimpleChannelList = $aSimpleChannelList | ForEach-Object{$_.Trim()} | Where-Object { -not $_.StartsWith("#")} | Where-Object {$_ -ne ""} | Where-Object {$_ -ne $null}

Clear-Content $sOutFilePath
Clear-Content $sSimpleChannelListPath

$Channels = @{}

$sGRP = ""
$sINF = ""
$sURL = ""
$inChannels = @{}
foreach($line in (Get-Content ".\in.m3u8" -Encoding UTF8 )) {
    if ($line.StartsWith("#EXTM3U")) {
        Add-Content -Path $sOutFilePath -Value $line
        continue
    }
    if ($line.StartsWith("#EXTGRP")) {
        if ($sGRP -ne $line) {
            Add-Content -Path $sSimpleChannelListPath -Value ">>>>> $line <<<<<<<<<<<<" -Encoding UTF8
        }
        $sGRP =  $line
        continue
    }
    if ($line.StartsWith("#EXTINF")) {
        $sINF =  $line
        continue
    }
    if ($line.StartsWith("http:")) {
        $sURL =  $line
        $sThisChannelName =  ($sINF.Split(","))[-1]
        $thisChannel  = "" |Select  sGRP,sINF,sURL
        $thisChannel.sGRP = $sGRP
        $thisChannel.sINF = $sINF
        $thisChannel.sURL = $sURL
        $inChannels[$sThisChannelName] = $thisChannel
        Add-Content -Path $sSimpleChannelListPath -Value ('"' + $sThisChannelName+'",') -Encoding UTF8
        continue
    }
}

Clear-Content $sOutFilePath
Add-Content -Path $sOutFilePath -Value "#EXTM3U" -Encoding UTF8

foreach ($oDesiredChannel in $aDesiredChannels ) {
    $sNewGRP = "#EXTGRP:" + $oDesiredChannel.SectionID
    foreach ($sDesiredChannelCaption in $oDesiredChannel.ChannelCaptions) {
        if ($inChannels.ContainsKey($sDesiredChannelCaption)) {
            Add-Content -Path $sOutFilePath -Value $inChannels[$sDesiredChannelCaption].sINF -Encoding UTF8
            Add-Content -Path $sOutFilePath -Value $sNewGRP -Encoding UTF8
            Add-Content -Path $sOutFilePath -Value $inChannels[$sDesiredChannelCaption].sURL -Encoding UTF8
        }
    }
}