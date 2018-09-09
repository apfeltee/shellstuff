#!powershell

Get-ChildItem | foreach {
    $class = if($_.PSIsContainer){ "Win32_Directory" } else { "CIM_DataFile" }
    Get-WMIObject $class -Filter "Name = '$($_.FullName -replace '\\','\\')'" | Select-Object -ExpandProperty EightDotThreeFileName
}

