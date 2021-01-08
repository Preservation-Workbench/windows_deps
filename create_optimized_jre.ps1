[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
$url= "https://corretto.aws/downloads/latest/amazon-corretto-11-x64-windows-jdk.zip"
$jdkZipName = [System.IO.Path]::GetFileName($url)  
$jdkDirName = [io.path]::GetFileNameWithoutExtension($jdkZipName) 
$scriptDir = (get-item $PSScriptRoot).FullName
$jreDir = ("$scriptDir\jre")
$tmpDir = "$Env:USERPROFILE\AppData\Local\Temp"

If (-Not (Test-Path "$tmpDir\$jdkZipName")) { 
    Write-Host "Downloading $jdkZipName ..."
    Invoke-WebRequest -Uri $url -OutFile "$tmpDir\$jdkZipName"
}

If (-Not (Test-Path "$tmpDir\$jdkDirName")) { 
    Set-Location -Path $tmpDir
    Write-Host "Extracting zipped JDK..."
    Expand-Archive "$tmpDir\$jdkZipName" 
    Set-Location -Path $scriptDir 
}

If (-Not (Test-Path $jreDir)) { 
    $jreSubDir = Get-ChildItem -Directory -Path "$tmpDir\$jdkDirName" | Select-Object -ExpandProperty FullName
    $jlinkPath = ("$jreSubDir\bin\jlink.exe")
    Write-Host "Generating optimized Java runtime..."
    $process = Start-Process -NoNewWindow -FilePath $jlinkPath -ArgumentList "--output $jreDir --compress=2 --no-header-files --no-man-pages --module-path ..\jmods --add-modules java.base,java.datatransfer,java.desktop,java.management,java.net.http,java.security.jgss,java.sql,java.sql.rowset,java.xml,jdk.net,jdk.unsupported,jdk.unsupported.desktop,jdk.xml.dom,jdk.zipfs" -PassThru -Wait
    If ($process.ExitCode -eq 0) {
        Write-Host "Finished successfully"
    }
}

If (-Not (Test-Path "$scriptDir\jre.zip")) { 
    Compress-Archive -Path $jreDir\* -DestinationPath "$scriptDir\jre.zip" -Force
}

