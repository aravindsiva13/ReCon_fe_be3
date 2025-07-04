# Complete Error & Fix Summary by File

## **File 1: Process_PayTm.ps1**

### **Error 1: File Locking**

```
Add-Content : Stream was not readable.
Add-Content : The process cannot access the file because it is being used by another process.
```

**OLD CODE (Lines 19-21):**

```powershell
Add-Content -Path $outputFile -NoNewline -Value "Txn_Source, Txn_Machine, Txn_MID, Txn_Type, Txn_Date, Txn_RefNo, Txn_Amount"
Add-Content -Path $outputFile -Value ""
```

**NEW CODE:**

```powershell
"Txn_Source,Txn_Machine,Txn_MID,Txn_Type,Txn_Date,Txn_RefNo,Txn_Amount" | Out-File $outputFile -Encoding UTF8
```

### **Error 2: Date Format**

```
Error: 1292 (22007): Incorrect date value: '2025 06 10' for column 'Txn_Date' at row 1
```

**OLD CODE (Line 45):**

```powershell
$txn_date = $data1_row.transaction_date.Substring(7,4), $data1_row.transaction_date.Substring(4,2), $data1_row.transaction_date.Substring(1,2)
```

**NEW CODE:**

```powershell
$txn_date = "$($data1_row.transaction_date.Substring(7,4))-$($data1_row.transaction_date.Substring(4,2))-$($data1_row.transaction_date.Substring(1,2))"
```

### **Error 3: Data Writing**

```
pandas.errors.ParserError: Error tokenizing data. C error: Expected 7 fields in line 891, saw 13
```

**OLD CODE (Lines 62-63):**

```powershell
Add-Content -Path $outputFile -NoNewline -Value $txn_source, ",", $txn_machine, ",", $txn_mid, ",", $txn_type, ",", $txn_date, ",", $txn_refno, ",", $txn_amount
Add-Content -Path $outputFile -Value ""
```

**NEW CODE:**

```powershell
"$txn_source,$txn_machine,$txn_mid,$txn_type,$txn_date,$txn_refno,$txn_amount" | Out-File $outputFile -Append -Encoding UTF8
```

### **Error 4: File Rename**

```
Rename-Item : Cannot create a file when that file already exists.
```

**OLD CODE (Line 73):**

```powershell
Rename-Item -Path $outputFile -NewName $renamedOutputFile
```

**NEW CODE:**

```powershell
if (Test-Path $renamedOutputFile) { Remove-Item -Path $renamedOutputFile -Force }
Rename-Item -Path $outputFile -NewName $renamedOutputFile
```

---

## **File 2: Process_PhonePe.ps1**

### **Error 1: File Locking**

```
Add-Content : The process cannot access the file because it is being used by another process.
Add-Content : Stream was not readable.
```

**OLD CODE (Header section):**

```powershell
Add-Content -Path $outputFile -NoNewline -Value "Txn_Source, Txn_Machine, Txn_MID, Txn_Type, Txn_Date, Txn_RefNo, Txn_Amount"
Add-Content -Path $outputFile -Value ""
```

**NEW CODE:**

```powershell
"Txn_Source,Txn_Machine,Txn_MID,Txn_Type,Txn_Date,Txn_RefNo,Txn_Amount" | Out-File $outputFile -Encoding UTF8
```

### **Error 2: Date Format (Payment)**

```
Error: 1292 (22007): Incorrect date value: '2025 06 10' for column 'Txn_Date' at row 1
```

**OLD CODE (Line 41):**

```powershell
$txn_date = $data1_row.TransactionDate.Substring(6,4), $data1_row.TransactionDate.Substring(3,2), $data1_row.TransactionDate.Substring(0,2)
```

**NEW CODE:**

```powershell
$txn_date = "$($data1_row.TransactionDate.Substring(6,4))-$($data1_row.TransactionDate.Substring(3,2))-$($data1_row.TransactionDate.Substring(0,2))"
```

### **Error 3: Date Format (Refund)**

**OLD CODE (Line 49):**

```powershell
$txn_date = $data1_row.OriginalTransactionDate.Substring(6,4), $data1_row.OriginalTransactionDate.Substring(3,2), $data1_row.OriginalTransactionDate.Substring(0,2)
```

**NEW CODE:**

```powershell
$txn_date = "$($data1_row.OriginalTransactionDate.Substring(6,4))-$($data1_row.OriginalTransactionDate.Substring(3,2))-$($data1_row.OriginalTransactionDate.Substring(0,2))"
```

### **Error 4: Data Writing**

**OLD CODE (Lines 64-65):**

```powershell
Add-Content -Path $outputFile -NoNewline -Value $txn_source, ",", $txn_machine, ",", $txn_mid, ",", $txn_type, ",", $txn_date, ",", $txn_refno, ",", $txn_amount
Add-Content -Path $outputFile -Value ""
```

**NEW CODE:**

```powershell
"$txn_source,$txn_machine,$txn_mid,$txn_type,$txn_date,$txn_refno,$txn_amount" | Out-File $outputFile -Append -Encoding UTF8
```

### **Error 5: File Rename**

**NEW CODE (Added before rename):**

```powershell
if (Test-Path $renamedOutputFile) { Remove-Item -Path $renamedOutputFile -Force }
```

---

## **File 3: Process_iCloud_Payment.ps1**

### **Error 1: File Locking**

```
Add-Content : Stream was not readable.
```

**OLD CODE:**

```powershell
Add-Content -Path $outputFile -NoNewline -Value $txn_source, ",", $txn_machine, ",", $txn_mid, ",", $txn_type, ",", $txn_date, ",", $txn_refno, ",", $txn_amount
Add-Content -Path $outputFile -Value ""
```

**NEW CODE:**

```powershell
"$txn_source,$txn_machine,$txn_mid,$txn_type,$txn_date,$txn_refno,$txn_amount" | Out-File $outputFile -Append -Encoding UTF8
```

### **Error 2: Date Format**

**OLD CODE:**

```powershell
$txn_date = $data1_row.TransactionDate.Substring(6,4), $data1_row.TransactionDate.Substring(3,2), $data1_row.TransactionDate.Substring(0,2)
```

**NEW CODE:**

```powershell
$txn_date = "$($data1_row.TransactionDate.Substring(6,4))-$($data1_row.TransactionDate.Substring(3,2))-$($data1_row.TransactionDate.Substring(0,2))"
```

---

## **File 4: Process_iCloud_Refund.ps1**

### **Same fixes as Process_iCloud_Payment.ps1**

---

## **File 5: load2table_PayTM.py**

### **Error: Unicode Escape**

```
SyntaxError: (unicode error) 'unicodeescape' codec can't decode bytes in position 2-3: truncated \UXXXXXXXX escape
```

**OLD CODE (Line 56):**

```python
csv_file1 = 'C:\Users\IT\Downloads\recon_updated (1)\Recon\Output_Files\output_PayTM.csv'
```

**NEW CODE:**

```python
csv_file1 = r'C:\Users\IT\Downloads\recon_updated (1)\Recon\Output_Files\output_PayTM.csv'
```

---

## **File 6: load2table_PhonePe.py**

### **Error: Unicode Escape**

```
SyntaxError: (unicode error) 'unicodeescape' codec can't decode bytes in position 2-3: truncated \UXXXXXXXX escape
```

**OLD CODE (Line 56):**

```python
csv_file2 = 'C:\Users\IT\Downloads\recon_updated (1)\Recon\Output_Files\output_PhonePe.csv'
```

**NEW CODE:**

```python
csv_file2 = r'C:\Users\IT\Downloads\recon_updated (1)\Recon\Output_Files\output_PhonePe.csv'
```

---

## **File 7: load2table_iCloudRefund.py**

### **Error: Wrong Path**

```
FileNotFoundError (implicit - wrong directory path)
```

**OLD CODE (Line 65):**

```python
csv_file2 = 'E:\Recon_Automation\Output_Files\iCloud_Refund.csv'
```

**NEW CODE:**

```python
csv_file2 = r'C:\Users\IT\Downloads\recon_updated (1)\Recon\Output_Files\iCloud_Refund.csv'
```

---

## **File 8: load2table_iCloudPayment.py**

### **Error: Unicode Escape (Similar to others)**

**OLD CODE (Line 56):**

```python
csv_file1 = 'C:\Users\IT\Downloads\recon_updated (1)\Recon\Output_Files\iCloud_Payment.csv'
```

**NEW CODE:**

```python
csv_file1 = r'C:\Users\IT\Downloads\recon_updated (1)\Recon\Output_Files\iCloud_Payment.csv'
```

---

## ** Summary**

- **8 Files Modified**
- **5 Types of Errors Fixed**
- **Key Changes:** File locking → Out-File, Date arrays → String format, Paths → Raw strings
- **Result:** System working successfully
