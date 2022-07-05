# Run from top directory of local python install

[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
$tmpDir = "$Env:USERPROFILE\AppData\Local\Temp"
$pythonInstalledDir = (get-item $PSScriptRoot).FullName
$pythonInstalledParentDir = (get-item $pythonInstalledDir).parent.FullName
$pythonInstalledVersion = (get-item "$pythonInstalledDir\python.exe").VersionInfo.ProductVersion
$pythonInstalledMajorVersion = (get-item "$pythonInstalledDir\python.exe").VersionInfo | % {("{0}{1}" -f $_.ProductMajorPart,$_.ProductMinorPart)}
$pythonEmbeddedZipName = "python-$pythonInstalledVersion-embed-amd64.zip"
$pythonEmbeddedZipExtractedPath = "$tmpDir\python-$pythonInstalledVersion"

# Download same version embedded python as installed python to Temp if not exists:
If (-Not (Test-Path "$tmpDir\$pythonEmbeddedZipName")) {
    Write-Host "Downloading $pythonEmbeddedZipName ..."
    $url = "https://www.python.org/ftp/python/$pythonInstalledVersion/$pythonEmbeddedZipName"
    Invoke-WebRequest -Uri $url -OutFile "$tmpDir\$pythonEmbeddedZipName"
}

# Extract embedded python if downloaded to Temp
If (Test-Path "$tmpDir\$pythonEmbeddedZipName") {
    If (-Not (Test-Path $pythonEmbeddedZipExtractedPath)) {
        Expand-Archive -LiteralPath "$tmpDir\$pythonEmbeddedZipName" -DestinationPath $pythonEmbeddedZipExtractedPath
    }
}

# Add pip and tkinter to embedded python:
$url = "https://github.com/Preservation-Workbench/windows_deps/releases/latest/download/get-pip.py"
$output = "$pythonEmbeddedZipExtractedPath\get-pip.py"
Invoke-WebRequest -Uri $url -OutFile $output
& $pythonEmbeddedZipExtractedPath\python.exe $pythonEmbeddedZipExtractedPath\get-pip.py 'pip==20.2.4' # SSL error on later
# Fix python path:
$pthFile = "$pythonEmbeddedZipExtractedPath\python$pythonInstalledMajorVersion._pth"
$text = [string]::Join("`n", (Get-Content $pthFile))
[regex]::Replace($text, "\.`n", ".`nLib\site-packages`n..\..\..\`n", "Singleline") | Set-Content $pthFile
# Copy Tkinter to embedded from installed:
Copy-Item -Path "$pythonInstalledDir\tcl" -Destination $pythonEmbeddedZipExtractedPath -recurse -Force
Copy-Item -Path "$pythonInstalledDir\Lib\tkinter" -Destination $pythonEmbeddedZipExtractedPath -recurse -Force
Copy-Item -Path "$pythonInstalledDir\DLLs\_tkinter.pyd" -Destination $pythonEmbeddedZipExtractedPath -Force
Copy-Item -Path "$pythonInstalledDir\DLLs\tcl86t.dll" -Destination $pythonEmbeddedZipExtractedPath -Force
Copy-Item -Path "$pythonInstalledDir\DLLs\tk86t.dll" -Destination $pythonEmbeddedZipExtractedPath -Force
$pipProcess = Start-Process -NoNewWindow -FilePath "$pythonEmbeddedZipExtractedPath\python.exe" -ArgumentList "-m pip install --upgrade --no-warn-script-location --force-reinstall JPype1 blake3 psutil jaydebeapi toposort specific_import flake8 autopep8 rope beautifulsoup4 lxml pygments petl filetype -t $pythonEmbeddedZipExtractedPath\Lib\site-packages" -PassThru; $pipProcess.WaitForExit()
Compress-Archive -Path $pythonEmbeddedZipExtractedPath\* -DestinationPath "$pythonInstalledParentDir\python-$pythonInstalledVersion-embed-amd64.zip" -Force

