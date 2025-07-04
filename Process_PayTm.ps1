# $HOME_DIR = "C:\Users\IT\Downloads\recon_updated (1)\Recon"
# ###Write-Host "HOME_DIR is set to: $HOME_DIR"

# # Set the directory containing your .zip files
# $inputFolderPath = Join-Path $HOME_DIR "Input_Files"
# $outputFolderPath = Join-Path $HOME_DIR "Output_Files"
# $outputFile = Join-Path $outputFolderPath "output_PayTM.csv"

# # Get all PayTM files ending with ".bill_txn_report" from inputFolderPath
# $paytmFiles = Get-ChildItem -Path $inputFolderPath -Filter *bill_txn_report.csv

# # Loop through each *bill_txn_report.csv from PayTM file and extract it
# foreach ($paytmFile in $paytmFiles) 
# {
#     Write-Host "Processing PayTM file: $($paytmFile.Name)"

#     # Delete Output File, if exist already
#     if ( Test-Path $outputFile) { Remove-Item -Path $outputFile }
#     # Create fresh Output File
#     if ( -not (Test-Path $outputFile) ) { Out-File -FilePath $outputfile -Encoding utf8 }

#     # Write Header - the first line into output CSV file
#     ###Write-Host "Txn_Source, Txn_Machine, Txn_MID, Txn_Type, Txn_Date, Txn_RefNo, Txn_Amount" 
#     # Add-Content -Path $outputFile -NoNewline -Value "Txn_Source, Txn_Machine, Txn_MID, Txn_Type, Txn_Date, Txn_RefNo, Txn_Amount" 
#     # Add-Content -Path $outputFile -Value ""


#     "Txn_Source,Txn_Machine,Txn_MID,Txn_Type,Txn_Date,Txn_RefNo,Txn_Amount" | Out-File $outputFile -Encoding UTF8

#     # Import the CSV file
#     $file2process = Join-Path $inputFolderPath $paytmFile
#     $data1 = Import-Csv -Path $file2process
#     # $data1 = Import-Csv -Path $inputFile | Select-Object order_id | Sort-Object -Property order_id -Unique 

#     # Iterate through each row
#     foreach ($data1_row in $data1) 
#     {
#         #Write-Host -NoNewline "."

#         $txn_source = "PayTM"
#         if ( $data1_row.udf1.Substring(1,7) -eq 'S12_123' ) 
#              { $txn_machine = $data1_row.udf1.Substring(1,7) } 
#         else { $txn_machine = $data1_row.udf1.Substring($data1_row.udf1.Length-11,10) }
#         $txn_mid = $data1_row.original_mid.Substring(1,$data1_row.original_mid.Length-2)
#         $txn_type = $data1_row.transaction_type.Substring(1,$data1_row.transaction_type.Length-2)
#         if ($txn_type -eq 'ACQUIRING') {$txn_type = 'PAYMENT'}
#         $txn_date = "$($data1_row.transaction_date.Substring(7,4))-$($data1_row.transaction_date.Substring(4,2))-$($data1_row.transaction_date.Substring(1,2))"    
#         $temp_txn_refno = $data1_row.order_id.Substring(1,$data1_row.order_id.Length-2)
#         if ( $temp_txn_refno.IndexOf("AZ") -ge 0 ) { $txn_refno = $temp_txn_refno.Substring(0,$temp_txn_refno.IndexOf("AZ")) } 
#         elseif ( $temp_txn_refno.IndexOf("-") -ge 0 ) { $txn_refno = $temp_txn_refno.Substring(0,$temp_txn_refno.IndexOf("-")) } 
#         else { $txn_refno = $temp_txn_refno }
#         $len_amount = 0
#         $str_amount = ""
#         $txn_amount = 0
 
#         $len_amount = $data1_row.amount.Length
#         $str_amount = $data1_row.amount.Substring(1, $len_amount-2)
#         $txn_amount = [double]$str_amount

#         # FYI, PhonePe REFUND transactions are reported in -ve numbers. Thus no conversion required.
#         # While processing PayTM transactions multiply txn_amount with -1. 
#         if ($txn_type -eq 'REFUND') { $txn_amount = $txn_amount * -1 }

#         ###Write-Host $txn_source, ",", $txn_machine, ",", $txn_mid, ",", $txn_type, ",", $txn_date, ",", $txn_refno, ",", $txn_amount
#         # Add-Content -Path $outputFile -NoNewline -Value $txn_source, ",", $txn_machine, ",", $txn_mid, ",", $txn_type, ",", $txn_date, ",", $txn_refno, ",", $txn_amount
#         # Add-Content -Path $outputFile -Value ""
        
#         "$txn_source,$txn_machine,$txn_mid,$txn_type,$txn_date,$txn_refno,$txn_amount" | Out-File $outputFile -Append -Encoding UTF8

#     }
#     python load2table_PayTM.py
    
#     # Rename Output File
#     $renamedOutputFile = Join-Path $outputFolderPath $paytmFile
#     if (Test-Path $renamedOutputFile) { Remove-Item -Path $renamedOutputFile -Force }  # ADD THIS LINE
#     Rename-Item -Path $outputFile -NewName $renamedOutputFile
#     Write-Host "File renamed successfully"
# }



$HOME_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$inputFolderPath = Join-Path $HOME_DIR "Input_Files"
$outputFolderPath = Join-Path $HOME_DIR "Output_Files"
$outputFile = Join-Path $outputFolderPath "output_PayTM.csv"

# Get all PayTM files ending with ".bill_txn_report" from inputFolderPath
$paytmFiles = Get-ChildItem -Path $inputFolderPath -Filter *bill_txn_report.csv

# Loop through each *bill_txn_report.csv from PayTM file and extract it
foreach ($paytmFile in $paytmFiles) {
    Write-Host "Processing PayTM file: $($paytmFile.Name)"

    # Delete Output File, if exist already
    if (Test-Path $outputFile) { Remove-Item -Path $outputFile }
    # Create fresh Output File
    if (-not (Test-Path $outputFile)) { Out-File -FilePath $outputfile -Encoding utf8 }

    # Write Header - the first line into output CSV file
    "Txn_Source,Txn_Machine,Txn_MID,Txn_Type,Txn_Date,Txn_RefNo,Txn_Amount" | Out-File $outputFile -Encoding UTF8

    # Import the CSV file
    $file2process = Join-Path $inputFolderPath $paytmFile
    $data1 = Import-Csv -Path $file2process

    # Iterate through each row
    foreach ($data1_row in $data1) {
        $txn_source = "PayTM"
        if ($data1_row.udf1.Substring(1,7) -eq 'S12_123') { 
            $txn_machine = $data1_row.udf1.Substring(1,7) 
        } else { 
            $txn_machine = $data1_row.udf1.Substring($data1_row.udf1.Length-11,10) 
        }
        $txn_mid = $data1_row.original_mid.Substring(1,$data1_row.original_mid.Length-2)
        $txn_type = $data1_row.transaction_type.Substring(1,$data1_row.transaction_type.Length-2)
        if ($txn_type -eq 'ACQUIRING') {$txn_type = 'PAYMENT'}
        $txn_date = "$($data1_row.transaction_date.Substring(7,4))-$($data1_row.transaction_date.Substring(4,2))-$($data1_row.transaction_date.Substring(1,2))"
        $temp_txn_refno = $data1_row.order_id.Substring(1,$data1_row.order_id.Length-2)
        if ($temp_txn_refno.IndexOf("AZ") -ge 0) { 
            $txn_refno = $temp_txn_refno.Substring(0,$temp_txn_refno.IndexOf("AZ")) 
        } elseif ($temp_txn_refno.IndexOf("-") -ge 0) { 
            $txn_refno = $temp_txn_refno.Substring(0,$temp_txn_refno.IndexOf("-")) 
        } else { 
            $txn_refno = $temp_txn_refno 
        }
        $len_amount = 0
        $str_amount = ""
        $txn_amount = 0

        $len_amount = $data1_row.amount.Length
        $str_amount = $data1_row.amount.Substring(1, $len_amount-2)
        $txn_amount = [double]$str_amount

        # While processing PayTM transactions multiply txn_amount with -1 for REFUND
        if ($txn_type -eq 'REFUND') { $txn_amount = $txn_amount * -1 }

        "$txn_source,$txn_machine,$txn_mid,$txn_type,$txn_date,$txn_refno,$txn_amount" | Out-File $outputFile -Append -Encoding UTF8
    }
    
    # Call Python script using relative path
    python load2table_PayTM.py
    
    # Rename Output File
    $renamedOutputFile = Join-Path $outputFolderPath $paytmFile
    if (Test-Path $renamedOutputFile) { Remove-Item -Path $renamedOutputFile -Force }
    Rename-Item -Path $outputFile -NewName $renamedOutputFile
    Write-Host "File renamed successfully"
}
