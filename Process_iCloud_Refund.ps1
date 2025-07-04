# $HOME_DIR = "C:\Users\IT\Downloads\recon_updated (1)\Recon"
# #Write-Host "HOME_DIR is set to: $HOME_DIR"

# # Set the directory containing your .zip files
# $inputFolderPath = Join-Path $HOME_DIR "Input_Files"
# $outputFolderPath = Join-Path $HOME_DIR "Output_Files"
# $outputFile = Join-Path $outputFolderPath "iCloud_Refund.csv"
# $temp_ref_file = Join-Path $inputFolderPath "temp_ref_file.csv"

# #---------------- To remove blank spaces from Header record ----------------
# # Get all Refund files starting with "ref" from inputFolderPath
# $refundFiles = Get-ChildItem -Path $inputFolderPath -Filter ref*.csv

# # Loop through each .zip file and extract it
# foreach ($refundFile in $refundFiles) 
# {
#     #Write-Host $refundFile
#     $file2process = Join-Path $inputFolderPath $refundFile
#     #Write-Host $file2process
#     $csv = Get-Content $file2process
#     $csv[0] = $csv[0] -replace ' ', ''  # Modify only the first line (header)
#     $csv | Set-Content $temp_ref_file  # Save the changes
#     Remove-Item -Path $file2process
#     Rename-Item -Path $temp_ref_file -NewName $file2process
# }
# #---------------- To remove blank spaces from Header record ----------------



# # Get all Refund files starting with "ref" from inputFolderPath
# $refundFiles = Get-ChildItem -Path $inputFolderPath -Filter ref*.csv

# # Loop through each .zip file and extract it
# foreach ($refundFile in $refundFiles) 
# {
#     Write-Host "Processing refund file: $($refundFile.Name)"

#     # Delete Output File, if exist already
#     if ( Test-Path $outputFile) { Remove-Item -Path $outputFile }
#     # Create fresh Output File
#     if ( -not (Test-Path $outputFile) ) { Out-File -FilePath $outputfile -Encoding utf8 }

#     # Write Header - the first line into output CSV file
#     ###Write-Host "Txn_Source, Txn_Machine, Txn_MID, Txn_Type, Txn_Date, Txn_RefNo, Txn_Amount" 
#     Add-Content -Path $outputFile -NoNewline -Value "Txn_Source, Txn_Machine, Txn_MID, Txn_Type, Txn_Date, Txn_RefNo, Txn_Amount" 
#     Add-Content -Path $outputFile -Value ""

#     # Import the CSV file (Looking for records with PENDING status. It can be removed or to be fixed, if the status gets changed to SUCCESS
#     $file2process = Join-Path $inputFolderPath $refundFile
#     $data1 = Import-Csv -Path $file2process | Where-Object { $_.Status -like "*PENDING*" }
#     # $data1 = Import-Csv -Path $inputFile | Select-Object order_id | Sort-Object -Property order_id -Unique 

#     # Iterate through each row
#     foreach ($data1_row in $data1) 
#     {
#         $txn_source = "iCLOUD-REFUND"
#         $txn_machine = $data1_row.MachineId
#         $txn_mid = $data1_row.Remark
#         $txn_type = $data1_row.RefundPaymentMethod, " (", $data1_row.RefundType, ")"
#         # $txn_date = $data1_row.TransactionDate.Substring(6,4), $data1_row.TransactionDate.Substring(3,2), $data1_row.TransactionDate.Substring(0,2)
#         $txn_date = $data1_row.TransactionDate.Substring(6,4) + "-" + $data1_row.TransactionDate.Substring(3,2) + "-" + $data1_row.TransactionDate.Substring(0,2)
#         $txn_refno = $data1_row.TransactionId
#         $txn_amount = $data1_row.RefundAmount
#         $txn_amount = [double]$txn_amount * -1

#         ###Write-Host $txn_source, ",", $txn_machine, ",", $txn_mid, ",", $txn_type, ",", $txn_date, ",", $txn_refno, ",", $txn_amount
#         # Add-Content -Path $outputFile -NoNewline -Value $txn_source, ",",  $txn_machine, ",", $txn_mid, ",", $txn_type, ",", $txn_date, ",", $txn_refno, ",", $txn_amount
#         # Add-Content -Path $outputFile -Value ""

#         "$txn_source,$txn_machine,$txn_mid,$txn_type,$txn_date,$txn_refno,$txn_amount" | Out-File $outputFile -Append -Encoding UTF8
#     }


#     python load2table_iCloudRefund.py
#     # Rename Output File
#     $renamedOutputFile = Join-Path $outputFolderPath $refundFile
#     Rename-Item -Path $outputFile -NewName $renamedOutputFile
#     Write-Host "File renamed successfully"
# }


$HOME_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$inputFolderPath = Join-Path $HOME_DIR "Input_Files"
$outputFolderPath = Join-Path $HOME_DIR "Output_Files"
$outputFile = Join-Path $outputFolderPath "iCloud_Refund.csv"
$temp_ref_file = Join-Path $inputFolderPath "temp_ref_file.csv"

# To remove blank spaces from Header record
# Get all Refund files starting with "ref" from inputFolderPath
$refundFiles = Get-ChildItem -Path $inputFolderPath -Filter ref*.csv

# Loop through each .zip file and extract it
foreach ($refundFile in $refundFiles) {
    $file2process = Join-Path $inputFolderPath $refundFile
    $csv = Get-Content $file2process
    $csv[0] = $csv[0] -replace ' ', ''  # Modify only the first line (header)
    $csv | Set-Content $temp_ref_file  # Save the changes
    Remove-Item -Path $file2process
    Rename-Item -Path $temp_ref_file -NewName $file2process
}

# Get all Refund files starting with "ref" from inputFolderPath
$refundFiles = Get-ChildItem -Path $inputFolderPath -Filter ref*.csv

# Loop through each .zip file and extract it
foreach ($refundFile in $refundFiles) {
    Write-Host "Processing refund file: $($refundFile.Name)"

    # Delete Output File, if exist already
    if (Test-Path $outputFile) { Remove-Item -Path $outputFile }
    # Create fresh Output File
    if (-not (Test-Path $outputFile)) { Out-File -FilePath $outputfile -Encoding utf8 }

    # Write Header - the first line into output CSV file
    "Txn_Source,Txn_Machine,Txn_MID,Txn_Type,Txn_Date,Txn_RefNo,Txn_Amount" | Out-File $outputFile -Encoding UTF8

    # Import the CSV file (Looking for records with PENDING status)
    $file2process = Join-Path $inputFolderPath $refundFile
    $data1 = Import-Csv -Path $file2process | Where-Object { $_.Status -like "*PENDING*" }

    # Iterate through each row
    foreach ($data1_row in $data1) {
        $txn_source = "iCLOUD-REFUND"
        $txn_machine = $data1_row.MachineId
        $txn_mid = $data1_row.Remark
        $txn_type = $data1_row.RefundPaymentMethod + " (" + $data1_row.RefundType + ")"
        $txn_date = $data1_row.TransactionDate.Substring(6,4) + "-" + $data1_row.TransactionDate.Substring(3,2) + "-" + $data1_row.TransactionDate.Substring(0,2)
        $txn_refno = $data1_row.TransactionId
        $txn_amount = [double]$data1_row.RefundAmount * -1

        "$txn_source,$txn_machine,$txn_mid,$txn_type,$txn_date,$txn_refno,$txn_amount" | Out-File $outputFile -Append -Encoding UTF8
    }

    # Call Python script using relative path
    python load2table_iCloudRefund.py
    
    # Rename Output File
    $renamedOutputFile = Join-Path $outputFolderPath $refundFile
    Rename-Item -Path $outputFile -NewName $renamedOutputFile
    Write-Host "File renamed successfully"
}