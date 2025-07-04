# $HOME_DIR = "C:\Users\IT\Downloads\recon_updated (1)\Recon"
# Write-Host "HOME_DIR is set to:" $HOME_DIR

# # Set the directory containing your .zip files
# $zipFolderPath = Join-Path $HOME_DIR "Input_files"
# $extractedFolder = Join-Path $HOME_DIR "Input_files"

# # Get all .zip files in the specified folder
# $zipFiles = Get-ChildItem -Path $zipFolderPath -Filter *.zip

# # Loop through each .zip file and extract it
# foreach ($zipFile in $zipFiles) {
#     Write-Host "Extracting ZIP file: $($zipFile.Name)"
    
#     # Create a folder to extract the ZIP contents
#     $zipExtractedFolder = Join-Path $extractedFolder ($zipFile.BaseName)
#     if (-Not (Test-Path -Path $zipExtractedFolder)) {
#         New-Item -ItemType Directory -Path $zipExtractedFolder | Out-Null
#     }

#     # Step 1: Extract the ZIP file
#     Expand-Archive -Path $zipFile.FullName -DestinationPath $zipExtractedFolder

#     # Step 2: Look for a .tar file in the extracted folder
#     $tarFiles = Get-ChildItem -Path $zipExtractedFolder -Filter *.tar
#     foreach ($tarFile in $tarFiles) {
#         Write-Host "Extracting TAR file: $($tarFile.Name)"
        
#         # Create a folder to extract the TAR contents
#         $tarExtractedFolder = Join-Path $zipExtractedFolder "tar_extracted"
#         if (-Not (Test-Path -Path $tarExtractedFolder)) {
#             New-Item -ItemType Directory -Path $tarExtractedFolder | Out-Null
#         }

#         # Use the .NET API to extract the TAR file
#         Add-Type -TypeDefinition @"
# using System;
# using System.IO;
# using ICSharpCode.SharpZipLib.Tar;
# using ICSharpCode.SharpZipLib.GZip;
# public class TarExtractor
# {
#     public static void ExtractTar(string tarFile, string destinationDir)
#     {
#         using (Stream inStream = new FileStream(tarFile, FileMode.Open, FileAccess.Read))
#         using (Stream tarStream = new GZipInputStream(inStream))
#         using (TarArchive tarArchive = TarArchive.CreateInputTarArchive(tarStream))
#         {
#             tarArchive.ExtractContents(destinationDir);
#         }
#     }
# }
# "@

#         # Extract the tar file
#         [TarExtractor]::ExtractTar($tarFile.FullName, $tarExtractedFolder)

#         Write-Host "TAR file extracted to $tarExtractedFolder"
#     }
# }
# Write-Host "All files extracted successfully."


# # Get all subdirectories inside the parent directory
# $subDirs = Get-ChildItem -Path $extractedFolder -Directory

# # Loop through each subdirectory
# foreach ($subDir in $subDirs) {
#     Write-Host "Moving files from subdirectory: $($subDir.FullName)"

#     # Get all files in the current subdirectory (including sub-subdirectories)
#     $files = Get-ChildItem -Path $subDir.FullName -Recurse -File

#     # Move each file to the parent directory
#     foreach ($file in $files) {
#         # Define the destination path (parent directory)
#         $destination = Join-Path $extractedFolder ($file.BaseName + '_extracted' + $file.Extension)
        
#         # If the file already exists in the parent directory, overwrite it
#         if (Test-Path -Path $destination) {
#             Remove-Item -Path $destination -Force
#         }
        
#         # Move the file to the parent directory
#         Move-Item -Path $file.FullName -Destination $destination
#     }

#     # Step 2: After moving all files, delete the subdirectory - Using "_extracted" suffix to avoid conflit between directory name and file name
#     Write-Host "Deleting subdirectory: $($subDir.FullName)"
#     Remove-Item -Path $subDir.FullName -Recurse -Force
# }




$HOME_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "HOME_DIR is set to: $HOME_DIR"

# Set the directory containing your .zip files
$zipFolderPath = Join-Path $HOME_DIR "Input_Files"
$extractedFolder = Join-Path $HOME_DIR "Input_Files"

# Get all .zip files in the specified folder
$zipFiles = Get-ChildItem -Path $zipFolderPath -Filter *.zip

# Loop through each .zip file and extract it
foreach ($zipFile in $zipFiles) {
    Write-Host "Extracting ZIP file: $($zipFile.Name)"
    
    # Create a folder to extract the ZIP contents
    $zipExtractedFolder = Join-Path $extractedFolder ($zipFile.BaseName)
    if (-Not (Test-Path -Path $zipExtractedFolder)) {
        New-Item -ItemType Directory -Path $zipExtractedFolder | Out-Null
    }

    # Step 1: Extract the ZIP file
    Expand-Archive -Path $zipFile.FullName -DestinationPath $zipExtractedFolder

    # Step 2: Look for a .tar file in the extracted folder
    $tarFiles = Get-ChildItem -Path $zipExtractedFolder -Filter *.tar
    foreach ($tarFile in $tarFiles) {
        Write-Host "Extracting TAR file: $($tarFile.Name)"
        
        # Create a folder to extract the TAR contents
        $tarExtractedFolder = Join-Path $zipExtractedFolder "tar_extracted"
        if (-Not (Test-Path -Path $tarExtractedFolder)) {
            New-Item -ItemType Directory -Path $tarExtractedFolder | Out-Null
        }

        # Use the .NET API to extract the TAR file
        Add-Type -TypeDefinition @"
using System;
using System.IO;
using ICSharpCode.SharpZipLib.Tar;
using ICSharpCode.SharpZipLib.GZip;
public class TarExtractor {
    public static void ExtractTar(string tarFile, string destinationDir)
    {
        using (Stream inStream = new FileStream(tarFile, FileMode.Open, FileAccess.Read))
        using (Stream tarStream = new GZipInputStream(inStream))
        using (TarArchive tarArchive = TarArchive.CreateInputTarArchive(tarStream))
        {
            tarArchive.ExtractContents(destinationDir);
        }
    }
}
"@

        # Extract the tar file
        [TarExtractor]::ExtractTar($tarFile.FullName, $tarExtractedFolder)
        
        Write-Host "TAR file extracted to $tarExtractedFolder"
    }
}

Write-Host "All files extracted successfully."

# Get all subdirectories inside the parent directory
$subDirs = Get-ChildItem -Path $extractedFolder -Directory

# Loop through each subdirectory
foreach ($subDir in $subDirs) {
    Write-Host "Moving files from subdirectory: $($subDir.FullName)"

    # Get all files in the current subdirectory (including sub-subdirectories)
    $files = Get-ChildItem -Path $subDir.FullName -Recurse -File

    # Move each file to the parent directory
    foreach ($file in $files) {
        # Define the destination path (parent directory)
        $destination = Join-Path $extractedFolder ($file.BaseName + '_extracted' + $file.Extension)
        
        # If the file already exists in the parent directory, overwrite it
        if (Test-Path -Path $destination) {
            Remove-Item -Path $destination -Force
        }
        
        # Move the file to the parent directory
        Move-Item -Path $file.FullName -Destination $destination
    }

    # Step 2: After moving all files, delete the subdirectory
    Write-Host "Deleting subdirectory: $($subDir.FullName)"
    Remove-Item -Path $subDir.FullName -Recurse -Force
}
