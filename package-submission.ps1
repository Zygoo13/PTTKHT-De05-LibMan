$ErrorActionPreference = 'Stop'

$root = (Get-Item -LiteralPath $PSScriptRoot).FullName
$files = @(
    '.gitignore', 'pom.xml', 'nb-configuration.xml', 'README.md',
    'package-submission.ps1',
    'database/01_schema.sql', 'database/02_seed.sql', 'database/03_verify.sql',
    'database/04_stored_procedures.sql',
    'database/catalog_sources.csv',
    'src/main/webapp/WEB-INF/view/nhanvienthuvien/.gitkeep'
)

# Chỉ lấy mã nguồn Java và các loại tệp web mà ứng dụng sử dụng.
$files += Get-ChildItem -LiteralPath (Join-Path $root 'src/main/java') -Recurse -File |
    Where-Object Extension -eq '.java' |
    ForEach-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') }
$files += Get-ChildItem -LiteralPath (Join-Path $root 'src/main/webapp') -Recurse -File |
    Where-Object { $_.Extension -in '.jsp', '.jspf', '.tag', '.css', '.js', '.svg', '.xml' } |
    ForEach-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') }

foreach ($file in $files) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $file) -PathType Leaf)) {
        throw "Missing submission file: $file"
    }
}

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$daoPath = Join-Path $root 'src/main/java/vn/edu/ptit/libman/dao/DAO.java'
$daoSource = Get-Content -LiteralPath $daoPath -Raw
$connectionCalls = [regex]::Matches($daoSource, 'DriverManager\.getConnection\s*\(')
if ($connectionCalls.Count -ne 1 -or
    $daoSource -cnotmatch 'DriverManager\.getConnection\(\s*url\s*,\s*"root"\s*,\s*"MAT_KHAU_MYSQL"\s*\)') {
    throw 'Restore the demo MySQL credentials in DAO.java before creating the ZIP.'
}

$path = Join-Path (Split-Path -Parent $root) 'libman-src.zip'
$stream = [IO.File]::Create($path)
try {
    $zip = [IO.Compression.ZipArchive]::new($stream, [IO.Compression.ZipArchiveMode]::Create, $true)
    try {
        foreach ($file in ($files | Sort-Object)) {
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $zip, (Join-Path $root $file), "LibMan/$file"
            ) | Out-Null
        }
    } finally {
        $zip.Dispose()
    }
} finally {
    $stream.Dispose()
}
Write-Output $path
