
from flask import Flask, jsonify, request, send_file
from flask_cors import CORS
import mysql.connector
import pandas as pd
from datetime import datetime
import loggingy
import traceback
from decimal import Decimal
import os
import subprocess
import threading
import time
from werkzeug.utils import secure_filename
import zipfile
import shutil
import json
import sys

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter frontend

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Database configuration
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': 'Templerun@2',
    'database': 'reconciliation'
}

# File upload configuration - CORRECTED PATH
UPLOAD_FOLDER = r'C:\Users\IT\Downloads\recon_updated (1)\Recon\Input_Files'  # Corrected to Input_Files
ALLOWED_EXTENSIONS = {'zip', 'xlsx', 'xls'}
MAX_FILE_SIZE = 50 * 1024 * 1024  # 50MB

# Simple batch file paths - JUST THE 3 FILES AS STRINGS
# BATCH_FILES = [
#     r'C:\Users\IT\Downloads\recon_updated (1)\Recon\1_Prepare_Input_Files.bat',
#     r'C:\Users\IT\Downloads\recon_updated (1)\Recon\2_PayTm_PhonePe_Recon.bat',
#     r'C:\Users\IT\Downloads\recon_updated (1)\Recon\3_LoadDB_ReconDailyExtract.bat'
# ]


BATCH_FILES = [
    r'C:\Users\IT\Downloads\recon_updated (1)\Recon\run_all_scripts.bat'
]

# Simple processing status
processing_status = {
    'is_processing': False,
    'current_step': 0,
    'total_steps': 3,
    'step_name': '',
    'progress': 0,
    'message': '',
    'error': None,
    'completed': False,
    'start_time': None,
    'uploaded_files': [],
    'detailed_log': []
}

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = MAX_FILE_SIZE

# Ensure upload directory exists
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Database Queries
QUERIES = {
    'SUMMARY': """
        (SELECT txn_source, Txn_type, sum(Txn_Amount) FROM reconciliation.payment_refund pr GROUP BY 1, 2) 
        UNION 
        (SELECT Txn_Source, Txn_type, sum(Txn_Amount) FROM reconciliation.paytm_phonepe pp GROUP BY 1, 2)
    """,
    'RAWDATA': """
        (SELECT * FROM reconciliation.paytm_phonepe pp) 
        UNION ALL 
        (SELECT * FROM reconciliation.payment_refund pr)
    """,
    'RECON_SUCCESS': """
        SELECT *, 
               IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),
                  "Perfect", "Investigate") AS Remarks 
        FROM reconciliation.recon_outcome ro1 
        WHERE ((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund)) 
        AND ro1.Txn_RefNo NOT IN (SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 WHERE ro2.txn_mid like '%manual%') 
        ORDER BY 1
    """,
    'RECON_INVESTIGATE': """
        SELECT *, 
               IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),
                  "Perfect", "Investigate") AS Remarks 
        FROM reconciliation.recon_outcome ro1 
        WHERE ((ro1.PTPP_Payment + ro1.PTPP_Refund) != (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund)) 
        AND ro1.Txn_RefNo NOT IN (SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 WHERE ro2.txn_mid like '%manual%') 
        ORDER BY 1
    """,
    'MANUAL_REFUND': """
        SELECT *, 
               IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),
                  "Perfect", "Investigate") AS Remarks 
        FROM reconciliation.recon_outcome ro1 
        WHERE ro1.Txn_RefNo IN (SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 WHERE ro2.txn_mid like '%manual%') 
        ORDER BY 1
    """
}

# ================== UTILITY FUNCTIONS ==================

def allowed_file(filename):
    """Check if file extension is allowed"""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def log_processing_step(message, level='INFO'):
    """Add detailed logging for processing steps"""
    global processing_status
    timestamp = datetime.now().isoformat()
    log_entry = {
        'timestamp': timestamp,
        'level': level,
        'message': message
    }
    processing_status['detailed_log'].append(log_entry)
    
    if level == 'ERROR':
        logger.error(message)
    elif level == 'WARNING':
        logger.warning(message)
    else:
        logger.info(message)

def calculate_summary_stats(data):
    """Calculate summary statistics from the data"""
    summary = {
        'total_transactions': 0,
        'total_amount': 0,
        'by_source': {},
        'by_type': {}
    }
    
    # Process RAWDATA for summary statistics
    if 'RAWDATA' in data:
        rawdata = data['RAWDATA']
        summary['total_transactions'] = len(rawdata)
        
        for row in rawdata:
            amount = float(row.get('Txn_Amount', 0))
            summary['total_amount'] += amount
            
            source = row.get('Txn_Source', 'Unknown')
            txn_type = row.get('Txn_Type', 'Unknown')
            
            if source not in summary['by_source']:
                summary['by_source'][source] = {'count': 0, 'amount': 0}
            summary['by_source'][source]['count'] += 1
            summary['by_source'][source]['amount'] += amount
            
            if txn_type not in summary['by_type']:
                summary['by_type'][txn_type] = {'count': 0, 'amount': 0}
            summary['by_type'][txn_type]['count'] += 1
            summary['by_type'][txn_type]['amount'] += amount
    
    return summary

def run_batch_files():
    """SIMPLE: Just run the 3 batch files in sequence"""
    global processing_status
    
    try:
        log_processing_step("🚀 Starting batch file execution")
        
        # Update processing status
        processing_status.update({
            'is_processing': True,
            'current_step': 0,
            'total_steps': 3,
            'progress': 0,
            'error': None,
            'completed': False,
            'start_time': datetime.now().isoformat()
        })
        
        step_names = [
            'Prepare Input Files',
            'PayTM & PhonePe Reconciliation',
            'Load Data to Database'
        ]
        
        # Check if all batch files exist
        for batch_file in BATCH_FILES:
            if not os.path.exists(batch_file):
                error_msg = f"❌ Batch file not found: {batch_file}"
                log_processing_step(error_msg, 'ERROR')
                processing_status.update({
                    'error': error_msg,
                    'is_processing': False
                })
                return
        
        log_processing_step("✅ All batch files found")
        
        # Execute each batch file in sequence
        for i, batch_file in enumerate(BATCH_FILES):
            step_name = step_names[i]
            batch_filename = os.path.basename(batch_file)
            
            processing_status.update({
                'current_step': i + 1,
                'step_name': step_name,
                'message': f'Running {batch_filename}...',
                'progress': (i / 3) * 100
            })
            
            log_processing_step(f"🔄 Step {i+1}/3: {step_name}")
            log_processing_step(f"📂 Executing: {batch_filename}")
            
            try:
                start_time = time.time()
                
                # Execute the batch file in its directory
                result = subprocess.run(
                    batch_file,
                    shell=True,
                    capture_output=True,
                    text=True,
                    cwd=r'C:\Users\IT\Downloads\recon_updated (1)\Recon',  # Working directory
                    timeout=7200  # 2 hours max
                )
                
                execution_time = time.time() - start_time
                log_processing_step(f"⏱️ Execution time: {execution_time:.1f} seconds")
                log_processing_step(f"🔢 Return code: {result.returncode}")
                
                if result.returncode != 0:
                    error_msg = f"❌ {step_name} failed with return code {result.returncode}"
                    if result.stderr:
                        error_msg += f"\nError: {result.stderr[:500]}"
                    if result.stdout:
                        error_msg += f"\nOutput: {result.stdout[:500]}"
                    
                    log_processing_step(error_msg, 'ERROR')
                    processing_status.update({
                        'error': error_msg,
                        'is_processing': False
                    })
                    return
                
                log_processing_step(f"✅ Completed: {step_name}")
                
                # Show some output if available
                if result.stdout:
                    output_preview = result.stdout[:300] + "..." if len(result.stdout) > 300 else result.stdout
                    log_processing_step(f"📄 Output: {output_preview}")
                
            except subprocess.TimeoutExpired:
                error_msg = f"⏰ {step_name} timed out after 2 hours"
                log_processing_step(error_msg, 'ERROR')
                processing_status.update({
                    'error': error_msg,
                    'is_processing': False
                })
                return
                
            except Exception as e:
                error_msg = f"💥 Error in {step_name}: {str(e)}"
                log_processing_step(error_msg, 'ERROR')
                processing_status.update({
                    'error': error_msg,
                    'is_processing': False
                })
                return
        
        # All completed successfully
        processing_status.update({
            'current_step': 3,
            'step_name': 'Completed',
            'message': 'All batch files completed successfully!',
            'progress': 100,
            'completed': True,
            'is_processing': False
        })
        
        log_processing_step("🎉 All batch files completed successfully!")
        
    except Exception as e:
        error_msg = f"💥 Unexpected error: {str(e)}"
        log_processing_step(error_msg, 'ERROR')
        processing_status.update({
            'error': error_msg,
            'is_processing': False
        })

# ================== API ROUTES ==================

@app.route('/api/health', methods=['GET'])
def health_check():
    """Simple health check"""
    try:
        # Test database connection
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()
        cursor.execute("SELECT VERSION(), DATABASE(), USER()")
        db_result = cursor.fetchone()
        cursor.close()
        conn.close()
        db_status = {
            'status': 'connected',
            'version': db_result[0] if db_result else 'Unknown',
            'database': db_result[1] if db_result else 'Unknown',
            'user': db_result[2] if db_result else 'Unknown'
        }
    except Exception as e:
        db_status = {'status': 'error', 'error': str(e)}
    
    # Check system
    system_status = {
        'upload_folder_exists': os.path.exists(UPLOAD_FOLDER),
        'upload_folder_writable': os.access(UPLOAD_FOLDER, os.W_OK) if os.path.exists(UPLOAD_FOLDER) else False,
        'batch_files_exist': all(os.path.exists(bf) for bf in BATCH_FILES),
    }
    
    overall_healthy = (
        db_status['status'] == 'connected' and
        system_status['upload_folder_exists'] and
        system_status['upload_folder_writable'] and
        system_status['batch_files_exist']
    )
    
    return jsonify({
        'status': 'healthy' if overall_healthy else 'degraded',
        'timestamp': datetime.now().isoformat(),
        'database': db_status,
        'system': system_status,
        'upload_folder': UPLOAD_FOLDER,
        'batch_files_configured': len(BATCH_FILES),
        'processing_status': processing_status
    })

@app.route('/api/upload', methods=['POST'])
def upload_file():
    """Upload file to Input_Files folder"""
    try:
        # Check if the post request has the file part
        if 'file' not in request.files:
            return jsonify({'error': 'No file part in the request'}), 400
        
        file = request.files['file']
        
        # If user does not select file, browser also submits an empty part without filename
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            
            # Check if file already exists and create unique name if needed
            if os.path.exists(filepath):
                name, ext = os.path.splitext(filename)
                counter = 1
                while os.path.exists(filepath):
                    filename = f"{name}_{counter}{ext}"
                    filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
                    counter += 1
            
            # Save the uploaded file
            file.save(filepath)
            
            # Add to uploaded files list
            if 'uploaded_files' not in processing_status:
                processing_status['uploaded_files'] = []
            
            file_info = {
                'filename': filename,
                'original_filename': file.filename,
                'filepath': filepath,
                'size': os.path.getsize(filepath),
                'upload_time': datetime.now().isoformat(),
                'file_type': filename.split('.')[-1].lower()
            }
            processing_status['uploaded_files'].append(file_info)
            
            logger.info(f"✅ File uploaded successfully: {filename} ({file_info['size']} bytes)")
            
            return jsonify({
                'success': True,
                'message': 'File uploaded successfully',
                'filename': filename,
                'original_filename': file.filename,
                'filepath': filepath,
                'size': file_info['size'],
                'file_type': file_info['file_type'],
                'timestamp': file_info['upload_time'],
                'total_uploaded_files': len(processing_status['uploaded_files'])
            })
        else:
            return jsonify({
                'success': False,
                'error': f'File type not allowed. Only {", ".join(ALLOWED_EXTENSIONS)} files are permitted'
            }), 400
            
    except Exception as e:
        logger.error(f"❌ Error uploading file: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/uploaded-files', methods=['GET'])
def get_uploaded_files():
    """Get list of uploaded files"""
    return jsonify({
        'uploaded_files': processing_status.get('uploaded_files', []),
        'total_count': len(processing_status.get('uploaded_files', [])),
        'total_size': sum(f.get('size', 0) for f in processing_status.get('uploaded_files', [])),
        'file_types': list(set(f.get('file_type', 'unknown') for f in processing_status.get('uploaded_files', []))),
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/uploaded-files', methods=['DELETE'])
def clear_uploaded_files():
    """Clear all uploaded files"""
    try:
        removed_count = 0
        # Remove files from disk
        for file_info in processing_status.get('uploaded_files', []):
            filepath = file_info.get('filepath')
            if filepath and os.path.exists(filepath):
                os.remove(filepath)
                removed_count += 1
        
        # Clear the list
        processing_status['uploaded_files'] = []
        
        return jsonify({
            'message': f'All uploaded files cleared ({removed_count} files removed)',
            'removed_count': removed_count
        })
    except Exception as e:
        logger.error(f"❌ Error clearing uploaded files: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/start-processing', methods=['POST'])
def start_processing():
    """FIXED: Enhanced processing start with correct file validation"""
    global processing_status
    
    try:
        print("🚀 Processing start request received...")
        
        # Check if already processing
        if processing_status['is_processing']:
            print("⚠️ Processing already in progress")
            return jsonify({
                'success': False,
                'error': 'Processing already in progress',
                'status': processing_status
            }), 400
        
        # Check if batch files exist
        missing_files = []
        for batch_file in BATCH_FILES:
            if not os.path.exists(batch_file):
                missing_files.append(batch_file)
        
        if missing_files:
            error_msg = f"❌ Missing batch files: {missing_files}"
            print(error_msg)
            return jsonify({
                'success': False,
                'error': error_msg,
                'missing_files': missing_files
            }), 400
        
        # FIXED: Check if upload folder has files (check the actual directory)
        if not os.path.exists(UPLOAD_FOLDER):
            error_msg = f"❌ Upload folder not found: {UPLOAD_FOLDER}"
            print(error_msg)
            return jsonify({'success': False, 'error': error_msg}), 400
        
        # FIXED: Get actual files from the directory (not from processing_status)
        try:
            uploaded_files = [f for f in os.listdir(UPLOAD_FOLDER) 
                            if os.path.isfile(os.path.join(UPLOAD_FOLDER, f))]
            print(f"📁 Checking directory: {UPLOAD_FOLDER}")
            print(f"📄 Files found in directory: {uploaded_files}")
        except Exception as e:
            error_msg = f"❌ Error reading upload folder: {str(e)}"
            print(error_msg)
            return jsonify({'success': False, 'error': error_msg}), 400
        
        if not uploaded_files:
            error_msg = f"❌ No files found in upload folder: {UPLOAD_FOLDER}"
            print(error_msg)
            print("💡 Files might be in a different location. Let me check...")
            
            # DEBUGGING: Check if files are in different locations
            possible_locations = [
                r'C:\Users\IT\Downloads\recon_updated (1)\Recon\input_files',  # lowercase
                r'C:\Users\IT\Downloads\recon_updated (1)\Recon\Input_Files',  # uppercase
                r'C:\Users\IT\Downloads\recon_updated (1)\Recon\Input_files',  # mixed case
            ]
            
            for location in possible_locations:
                if os.path.exists(location):
                    files_in_location = [f for f in os.listdir(location) 
                                       if os.path.isfile(os.path.join(location, f))]
                    print(f"📂 Found {len(files_in_location)} files in {location}: {files_in_location}")
            
            return jsonify({
                'success': False, 
                'error': error_msg,
                'upload_folder': UPLOAD_FOLDER,
                'checked_locations': possible_locations
            }), 400
        
        print(f"✅ Found {len(uploaded_files)} uploaded files: {uploaded_files}")
        print("✅ All batch files found, starting execution...")
        
        # Reset processing status
        processing_status.update({
            'is_processing': True,
            'current_step': 0,
            'total_steps': 3,
            'step_name': 'Initializing',
            'progress': 0,
            'message': 'Starting batch processing...',
            'error': None,
            'completed': False,
            'start_time': datetime.now().isoformat(),
            'detailed_log': []
        })
        
        print("🚀 Starting batch processing thread...")
        
        # Start batch processing in a separate thread
        thread = threading.Thread(target=run_batch_files)
        thread.daemon = True
        thread.start()
        
        return jsonify({
            'success': True,
            'message': 'Processing started successfully',
            'status': processing_status,
            'uploaded_files': uploaded_files,
            'upload_folder': UPLOAD_FOLDER,
            'files_count': len(uploaded_files),
            'batch_files_ready': True,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        error_msg = f"💥 Error starting processing: {str(e)}"
        print(error_msg)
        logger.error(error_msg)
        return jsonify({'success': False, 'error': error_msg}), 500

# ALSO ADD this debug endpoint to help diagnose:
@app.route('/api/debug-files', methods=['GET'])
def debug_files():
    """Debug endpoint to check file locations"""
    try:
        results = {}
        
        # Check configured upload folder
        results['configured_upload_folder'] = UPLOAD_FOLDER
        results['folder_exists'] = os.path.exists(UPLOAD_FOLDER)
        
        if os.path.exists(UPLOAD_FOLDER):
            files = [f for f in os.listdir(UPLOAD_FOLDER) 
                    if os.path.isfile(os.path.join(UPLOAD_FOLDER, f))]
            results['files_in_configured_folder'] = files
            results['file_count'] = len(files)
        
        # Check alternative locations
        possible_locations = [
            r'C:\Users\IT\Downloads\recon_updated (1)\Recon\input_files',
            r'C:\Users\IT\Downloads\recon_updated (1)\Recon\Input_Files', 
            r'C:\Users\IT\Downloads\recon_updated (1)\Recon\Input_files',
        ]
        
        results['alternative_locations'] = {}
        for location in possible_locations:
            if os.path.exists(location):
                files = [f for f in os.listdir(location) 
                        if os.path.isfile(os.path.join(location, f))]
                results['alternative_locations'][location] = {
                    'exists': True,
                    'files': files,
                    'count': len(files)
                }
            else:
                results['alternative_locations'][location] = {
                    'exists': False,
                    'files': [],
                    'count': 0
                }
        
        # Check processing status uploaded files
        results['processing_status_files'] = processing_status.get('uploaded_files', [])
        
        return jsonify(results)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500
@app.route('/api/processing-status', methods=['GET'])
def get_processing_status():
    """Get current processing status"""
    return jsonify({
        'status': processing_status,
        'batch_files': BATCH_FILES,
        'logs_count': len(processing_status.get('detailed_log', [])),
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/processing-logs', methods=['GET'])
def get_processing_logs():
    """Get processing logs"""
    try:
        level_filter = request.args.get('level', None)
        limit = request.args.get('limit', type=int, default=100)
        
        logs = processing_status.get('detailed_log', [])
        
        # Apply level filter
        if level_filter:
            logs = [log for log in logs if log.get('level') == level_filter.upper()]
        
        # Apply limit
        logs = logs[-limit:] if limit > 0 else logs
        
        return jsonify({
            'logs': logs,
            'total_logs': len(processing_status.get('detailed_log', [])),
            'filtered_logs': len(logs),
            'level_filter': level_filter,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"❌ Error getting processing logs: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/check-batch-files', methods=['GET'])
def check_batch_files():
    """Check if batch files exist and what files are in upload folder"""
    try:
        # Check batch files
        batch_results = []
        for i, batch_file in enumerate(BATCH_FILES):
            batch_results.append({
                'index': i + 1,
                'name': os.path.basename(batch_file),
                'path': batch_file,
                'exists': os.path.exists(batch_file),
                'readable': os.access(batch_file, os.R_OK) if os.path.exists(batch_file) else False
            })
        
        # Check upload folder
        upload_folder_info = {
            'path': UPLOAD_FOLDER,
            'exists': os.path.exists(UPLOAD_FOLDER),
            'files': []
        }
        
        if upload_folder_info['exists']:
            try:
                files = os.listdir(UPLOAD_FOLDER)
                upload_folder_info['files'] = [
                    {
                        'name': f,
                        'size': os.path.getsize(os.path.join(UPLOAD_FOLDER, f)),
                        'modified': os.path.getmtime(os.path.join(UPLOAD_FOLDER, f))
                    }
                    for f in files if os.path.isfile(os.path.join(UPLOAD_FOLDER, f))
                ]
            except Exception as e:
                upload_folder_info['error'] = str(e)
        
        return jsonify({
            'batch_files': batch_results,
            'upload_folder': upload_folder_info,
            'all_batch_files_ready': all(r['exists'] and r['readable'] for r in batch_results),
            'uploaded_files_count': len(upload_folder_info.get('files', [])),
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ================== DATABASE ROUTES (SIMPLIFIED) ==================

@app.route('/api/reconciliation/data', methods=['GET'])
def get_reconciliation_data():
    """Get reconciliation data from database"""
    try:
        sheet = request.args.get('sheet', 'RAWDATA')
        limit = request.args.get('limit', type=int)
        
        if sheet not in QUERIES:
            return jsonify({'error': f'Invalid sheet parameter. Available: {list(QUERIES.keys())}'}), 400
        
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor(dictionary=True)
        
        query = QUERIES[sheet]
        if limit and limit > 0:
            query += f" LIMIT {limit}"
        
        cursor.execute(query)
        data = cursor.fetchall()
        
        # Convert Decimal objects to float for JSON serialization
        for row in data:
            for key, value in row.items():
                if isinstance(value, Decimal):
                    row[key] = float(value)
        
        summary_stats = calculate_summary_stats({'RAWDATA': data}) if sheet == 'RAWDATA' else {}
        
        return jsonify({
            'data': data,
            'count': len(data),
            'sheet': sheet,
            'summary': summary_stats,
            'timestamp': datetime.now().isoformat()
        })
        
    except mysql.connector.Error as e:
        logger.error(f"❌ Database error: {str(e)}")
        return jsonify({'error': f'Database error: {str(e)}'}), 500
    except Exception as e:
        logger.error(f"❌ Error fetching data: {str(e)}")
        return jsonify({'error': str(e)}), 500
    finally:
        try:
            cursor.close()
            conn.close()
        except:
            pass

# ================== MAIN APPLICATION ==================

if __name__ == '__main__':
    print("=" * 60)
    print("🚀 SIMPLE RECONCILIATION API SERVER")
    print("=" * 60)
    
    # Display startup information
    print(f"📅 Startup: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"📁 Upload Folder: {UPLOAD_FOLDER}")
    print(f"🗄️ Database: {DB_CONFIG['database']} on {DB_CONFIG['host']}")
    
    print("\n🔧 Batch Files to Execute:")
    for i, batch_file in enumerate(BATCH_FILES, 1):
        exists = "✅" if os.path.exists(batch_file) else "❌"
        print(f"   {exists} {i}. {os.path.basename(batch_file)}")
        print(f"        {batch_file}")
    
    print(f"\n🌐 Key Endpoints:")
    print(f"   POST /api/upload              - Upload files to Input_Files")
    print(f"   POST /api/start-processing    - Run the 3 batch files")
    print(f"   GET  /api/processing-status   - Check processing status")
    print(f"   GET  /api/check-batch-files   - Verify batch files and uploads")
    print(f"   GET  /api/health              - System health check")
    
    print("=" * 60)
    print("🎯 SIMPLE WORKFLOW:")
    print("   1. Upload files to Input_Files folder")
    print("   2. Click 'Start Processing'") 
    print("   3. Runs: 1_Prepare_Input_Files.bat")
    print("   4. Runs: 2_PayTm_PhonePe_Recon.bat")
    print("   5. Runs: 3_LoadDB_ReconDailyExtract.bat")
    print("=" * 60)
    print("🚀 Starting server on http://localhost:5000")
    print("=" * 60)
    
    # Start the Flask application
    try:
        app.run(debug=True, host='0.0.0.0', port=5000, threaded=True)
    except KeyboardInterrupt:
        print("\n\n🛑 Server stopped by user")
    except Exception as e:
        print(f"\n❌ Server error: {str(e)}")
    finally:
        print("👋 Goodbye!")