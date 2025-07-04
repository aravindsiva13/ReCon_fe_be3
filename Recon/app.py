

# from flask import Flask, jsonify, request, send_file
# from flask_cors import CORS
# import mysql.connector
# import pandas as pd
# from datetime import datetime
# import logging
# import traceback
# from decimal import Decimal
# import os
# import subprocess
# import threading
# import time
# from werkzeug.utils import secure_filename
# import zipfile
# import shutil

# app = Flask(__name__)
# CORS(app)  # Enable CORS for Flutter frontend

# # Configure logging
# logging.basicConfig(level=logging.INFO)
# logger = logging.getLogger(__name__)

# # Database configuration
# DB_CONFIG = {
#     'host': 'localhost',
#     'user': 'root',
#     'password': 'Templerun@2',  # Update this to match your config
#     'database': 'reconciliation'
# }

# # File upload configuration
# UPLOAD_FOLDER = r'C:\Users\IT\Downloads\recon_updated (1)\Recon\input_files'
# ALLOWED_EXTENSIONS = {'zip', 'xlsx', 'xls'}
# MAX_FILE_SIZE = 50 * 1024 * 1024  # 50MB

# # Batch file paths
# BATCH_FILES = [
#     r'C:\Users\IT\Downloads\recon_updated (1)\Recon\1_Prepare_Input_Files.bat',
#     r'C:\Users\IT\Downloads\recon_updated (1)\Recon\2_PayTm_PhonePe_Recon.bat',
#     r'C:\Users\IT\Downloads\recon_updated (1)\Recon\3_LoadDB_ReconDailyExtract.bat'
# ]

# # Global variable to track processing status
# processing_status = {
#     'is_processing': False,
#     'current_step': 0,
#     'total_steps': 3,
#     'step_name': '',
#     'progress': 0,
#     'message': '',
#     'error': None,
#     'completed': False
# }

# app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
# app.config['MAX_CONTENT_LENGTH'] = MAX_FILE_SIZE

# # Ensure upload directory exists
# os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# # Queries from your specification
# QUERIES = {
#     'SUMMARY': """
#         (SELECT txn_source, Txn_type, sum(Txn_Amount) FROM reconciliation.payment_refund pr GROUP BY 1, 2) 
#         UNION 
#         (SELECT Txn_Source, Txn_type, sum(Txn_Amount) FROM reconciliation.paytm_phonepe pp GROUP BY 1, 2)
#     """,
#     'RAWDATA': """
#         (SELECT * FROM reconciliation.paytm_phonepe pp) 
#         UNION ALL 
#         (SELECT * FROM reconciliation.payment_refund pr)
#     """,
#     'RECON_SUCCESS': """
#         SELECT *, 
#                IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),
#                   "Perfect", "Investigate") AS Remarks 
#         FROM reconciliation.recon_outcome ro1 
#         WHERE ((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund)) 
#         AND ro1.Txn_RefNo NOT IN (SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 WHERE ro2.txn_mid like '%manual%') 
#         ORDER BY 1
#     """,
#     'RECON_INVESTIGATE': """
#         SELECT *, 
#                IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),
#                   "Perfect", "Investigate") AS Remarks 
#         FROM reconciliation.recon_outcome ro1 
#         WHERE ((ro1.PTPP_Payment + ro1.PTPP_Refund) != (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund)) 
#         AND ro1.Txn_RefNo NOT IN (SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 WHERE ro2.txn_mid like '%manual%') 
#         ORDER BY 1
#     """,
#     'MANUAL_REFUND': """
#         SELECT *, 
#                IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),
#                   "Perfect", "Investigate") AS Remarks 
#         FROM reconciliation.recon_outcome ro1 
#         WHERE ro1.Txn_RefNo IN (SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 WHERE ro2.txn_mid like '%manual%') 
#         ORDER BY 1
#     """
# }

# def allowed_file(filename):
#     """Check if file extension is allowed"""
#     return '.' in filename and \
#            filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# def get_db_connection():
#     """Create and return a database connection"""
#     try:
#         conn = mysql.connector.connect(**DB_CONFIG)
#         return conn
#     except mysql.connector.Error as err:
#         logger.error(f"Database connection error: {err}")
#         return None

# def serialize_value(value):
#     """Convert various data types to JSON serializable format"""
#     if value is None:
#         return None
#     elif isinstance(value, datetime):
#         return value.isoformat()
#     elif isinstance(value, bytes):
#         return value.decode('utf-8', errors='ignore')
#     elif isinstance(value, Decimal):
#         return float(value)
#     else:
#         return value

# def execute_query(query):
#     """Execute a query and return results as a list of dictionaries"""
#     conn = get_db_connection()
#     if not conn:
#         return None
    
#     try:
#         cursor = conn.cursor(dictionary=True)
#         cursor.execute(query)
#         results = cursor.fetchall()
        
#         # Convert any problematic data types for JSON serialization
#         serialized_results = []
#         for row in results:
#             serialized_row = {}
#             for key, value in row.items():
#                 serialized_row[key] = serialize_value(value)
#             serialized_results.append(serialized_row)
        
#         return serialized_results
#     except mysql.connector.Error as err:
#         logger.error(f"Query execution error: {err}")
#         logger.error(f"Query: {query}")
#         return None
#     except Exception as e:
#         logger.error(f"Unexpected error: {e}")
#         logger.error(traceback.format_exc())
#         return None
#     finally:
#         if conn.is_connected():
#             cursor.close()
#             conn.close()

# def calculate_summary_stats(data):
#     """Calculate summary statistics from the data"""
#     summary = {
#         'total_transactions': 0,
#         'total_amount': 0,
#         'by_source': {},
#         'by_type': {}
#     }
    
#     # Process RAWDATA for summary statistics
#     if 'RAWDATA' in data:
#         rawdata = data['RAWDATA']
#         summary['total_transactions'] = len(rawdata)
        
#         for row in rawdata:
#             amount = float(row.get('Txn_Amount', 0))
#             summary['total_amount'] += amount
            
#             source = row.get('Txn_Source', 'Unknown')
#             txn_type = row.get('Txn_Type', 'Unknown')
            
#             if source not in summary['by_source']:
#                 summary['by_source'][source] = {'count': 0, 'amount': 0}
#             summary['by_source'][source]['count'] += 1
#             summary['by_source'][source]['amount'] += amount
            
#             if txn_type not in summary['by_type']:
#                 summary['by_type'][txn_type] = {'count': 0, 'amount': 0}
#             summary['by_type'][txn_type]['count'] += 1
#             summary['by_type'][txn_type]['amount'] += amount
    
#     return summary

# def run_batch_files():
#     """Run the three batch files sequentially in a separate thread"""
#     global processing_status
    
#     try:
#         processing_status.update({
#             'is_processing': True,
#             'current_step': 0,
#             'total_steps': 3,
#             'progress': 0,
#             'error': None,
#             'completed': False
#         })
        
#         step_names = [
#             'Preparing Input Files',
#             'Processing PayTM & PhonePe Reconciliation',
#             'Loading Data to Database'
#         ]
        
#         for i, batch_file in enumerate(BATCH_FILES):
#             processing_status.update({
#                 'current_step': i + 1,
#                 'step_name': step_names[i],
#                 'message': f'Running {os.path.basename(batch_file)}...',
#                 'progress': (i / len(BATCH_FILES)) * 100
#             })
            
#             logger.info(f"Starting batch file: {batch_file}")
            
#             # Run batch file and wait for completion
#             result = subprocess.run(
#                 batch_file,
#                 shell=True,
#                 capture_output=True,
#                 text=True,
#                 cwd=os.path.dirname(batch_file)
#             )
            
#             if result.returncode != 0:
#                 error_msg = f"Batch file {batch_file} failed with return code {result.returncode}"
#                 if result.stderr:
#                     error_msg += f": {result.stderr}"
                
#                 processing_status.update({
#                     'error': error_msg,
#                     'is_processing': False
#                 })
#                 logger.error(error_msg)
#                 return
            
#             logger.info(f"Completed batch file: {batch_file}")
        
#         # All batch files completed successfully
#         processing_status.update({
#             'current_step': 3,
#             'step_name': 'Completed',
#             'message': 'All processing completed successfully!',
#             'progress': 100,
#             'completed': True,
#             'is_processing': False
#         })
        
#         logger.info("All batch files completed successfully")
        
#     except Exception as e:
#         error_msg = f"Error running batch files: {str(e)}"
#         processing_status.update({
#             'error': error_msg,
#             'is_processing': False
#         })
#         logger.error(error_msg)

# # NEW ENDPOINTS FOR FILE UPLOAD AND AUTOMATION

# @app.route('/api/upload', methods=['POST'])
# def upload_file():
#     """Handle file upload"""
#     try:
#         # Check if the post request has the file part
#         if 'file' not in request.files:
#             return jsonify({'error': 'No file part in the request'}), 400
        
#         file = request.files['file']
        
#         # If user does not select file, browser also submits an empty part without filename
#         if file.filename == '':
#             return jsonify({'error': 'No file selected'}), 400
        
#         if file and allowed_file(file.filename):
#             filename = secure_filename(file.filename)
#             filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            
#             # Save the uploaded file
#             file.save(filepath)
            
#             logger.info(f"File uploaded successfully: {filename}")
            
#             return jsonify({
#                 'message': 'File uploaded successfully',
#                 'filename': filename,
#                 'filepath': filepath,
#                 'timestamp': datetime.now().isoformat()
#             })
#         else:
#             return jsonify({'error': 'File type not allowed. Only .zip, .xlsx, .xls files are permitted'}), 400
            
#     except Exception as e:
#         logger.error(f"Error uploading file: {str(e)}")
#         return jsonify({'error': str(e)}), 500

# @app.route('/api/start-processing', methods=['POST'])
# def start_processing():
#     """Start the batch file execution process"""
#     global processing_status
    
#     try:
#         # Check if already processing
#         if processing_status['is_processing']:
#             return jsonify({
#                 'error': 'Processing already in progress',
#                 'status': processing_status
#             }), 400
        
#         # Reset processing status
#         processing_status = {
#             'is_processing': True,
#             'current_step': 0,
#             'total_steps': 3,
#             'step_name': 'Initializing',
#             'progress': 0,
#             'message': 'Starting batch processing...',
#             'error': None,
#             'completed': False
#         }
        
#         # Start batch processing in a separate thread
#         thread = threading.Thread(target=run_batch_files)
#         thread.daemon = True
#         thread.start()
        
#         return jsonify({
#             'message': 'Processing started successfully',
#             'status': processing_status,
#             'timestamp': datetime.now().isoformat()
#         })
        
#     except Exception as e:
#         logger.error(f"Error starting processing: {str(e)}")
#         return jsonify({'error': str(e)}), 500

# @app.route('/api/processing-status', methods=['GET'])
# def get_processing_status():
#     """Get current processing status"""
#     global processing_status
    
#     return jsonify({
#         'status': processing_status,
#         'timestamp': datetime.now().isoformat()
#     })

# # EXISTING ENDPOINTS (unchanged)

# @app.route('/api/health', methods=['GET'])
# def health_check():
#     """Health check endpoint"""
#     try:
#         conn = get_db_connection()
#         if conn and conn.is_connected():
#             cursor = conn.cursor()
#             cursor.execute("SELECT 1")
#             cursor.fetchone()
#             cursor.close()
#             conn.close()
#             return jsonify({
#                 "status": "healthy",
#                 "database": "connected",
#                 "timestamp": datetime.now().isoformat()
#             })
#         else:
#             return jsonify({
#                 "status": "unhealthy",
#                 "database": "disconnected",
#                 "timestamp": datetime.now().isoformat()
#             }), 500
#     except Exception as e:
#         logger.error(f"Health check error: {e}")
#         return jsonify({
#             "status": "error",
#             "database": "error",
#             "error": str(e),
#             "timestamp": datetime.now().isoformat()
#         })

# @app.route('/api/reconciliation/data', methods=['GET'])
# def get_reconciliation_data():
#     """Get all reconciliation data in Excel-like format"""
#     try:
#         result_data = {}
        
#         # Execute each query and store results
#         for sheet_name, query in QUERIES.items():
#             logger.info(f"Executing query for {sheet_name}")
#             data = execute_query(query)
            
#             if data is None:
#                 return jsonify({
#                     "error": f"Failed to execute query for {sheet_name}",
#                     "timestamp": datetime.now().isoformat()
#                 }), 500
            
#             result_data[sheet_name] = data
#             logger.info(f"Retrieved {len(data)} rows for {sheet_name}")
        
#         # Calculate summary statistics
#         summary_stats = calculate_summary_stats(result_data)
        
#         return jsonify({
#             "data": result_data,
#             "summary": summary_stats,
#             "timestamp": datetime.now().isoformat(),
#             "total_sheets": len(result_data),
#             "status": "success"
#         })
        
#     except Exception as e:
#         logger.error(f"Error in get_reconciliation_data: {str(e)}")
#         logger.error(traceback.format_exc())
#         return jsonify({
#             "error": str(e),
#             "timestamp": datetime.now().isoformat(),
#             "status": "error"
#         }), 500

# @app.route('/api/reconciliation/sheet/<sheet_name>', methods=['GET'])
# def get_sheet_data(sheet_name):
#     """Get data for a specific sheet"""
#     try:
#         sheet_name = sheet_name.upper()
        
#         if sheet_name not in QUERIES:
#             return jsonify({
#                 "error": f"Sheet {sheet_name} not found. Available sheets: {list(QUERIES.keys())}",
#                 "timestamp": datetime.now().isoformat()
#             }), 404
        
#         logger.info(f"Executing query for {sheet_name}")
#         data = execute_query(QUERIES[sheet_name])
        
#         if data is None:
#             return jsonify({
#                 "error": f"Failed to execute query for {sheet_name}",
#                 "timestamp": datetime.now().isoformat()
#             }), 500
        
#         return jsonify({
#             "sheet_name": sheet_name,
#             "data": data,
#             "row_count": len(data),
#             "timestamp": datetime.now().isoformat(),
#             "status": "success"
#         })
        
#     except Exception as e:
#         logger.error(f"Error in get_sheet_data: {str(e)}")
#         return jsonify({
#             "error": str(e),
#             "timestamp": datetime.now().isoformat(),
#             "status": "error"
#         }), 500

# @app.route('/api/reconciliation/summary', methods=['GET'])
# def get_summary():
#     """Get summary statistics"""
#     try:
#         logger.info("Executing SUMMARY query")
#         data = execute_query(QUERIES['SUMMARY'])
        
#         if data is None:
#             return jsonify({
#                 "error": "Failed to execute summary query",
#                 "timestamp": datetime.now().isoformat()
#             }), 500
        
#         return jsonify({
#             "summary": data,
#             "row_count": len(data),
#             "timestamp": datetime.now().isoformat(),
#             "status": "success"
#         })
        
#     except Exception as e:
#         logger.error(f"Error in get_summary: {str(e)}")
#         return jsonify({
#             "error": str(e),
#             "timestamp": datetime.now().isoformat(),
#             "status": "error"
#         }), 500

# @app.route('/api/reconciliation/refresh', methods=['POST'])
# def refresh_data():
#     """Refresh/reload data (trigger any backend refresh logic)"""
#     try:
#         # This endpoint can be used to trigger any refresh logic
#         # For now, it just confirms the refresh request
        
#         logger.info("Data refresh requested")
        
#         return jsonify({
#             "message": "Data refresh completed",
#             "timestamp": datetime.now().isoformat(),
#             "status": "success"
#         })
        
#     except Exception as e:
#         logger.error(f"Error in refresh_data: {str(e)}")
#         return jsonify({
#             "error": str(e),
#             "timestamp": datetime.now().isoformat(),
#             "status": "error"
#         }), 500

# @app.route('/api/reconciliation/export', methods=['POST'])
# def export_data():
#     """Export data in various formats"""
#     try:
#         request_data = request.get_json()
        
#         if not request_data:
#             return jsonify({
#                 "error": "No request data provided",
#                 "timestamp": datetime.now().isoformat()
#             }), 400
        
#         export_format = request_data.get('format', 'json').lower()
#         sheets = request_data.get('sheets', list(QUERIES.keys()))
        
#         if export_format not in ['json', 'csv', 'excel']:
#             return jsonify({
#                 "error": "Unsupported export format. Use 'json', 'csv', or 'excel'",
#                 "timestamp": datetime.now().isoformat()
#             }), 400
        
#         # For now, return JSON data (can be extended for other formats)
#         result_data = {}
#         for sheet_name in sheets:
#             if sheet_name.upper() in QUERIES:
#                 data = execute_query(QUERIES[sheet_name.upper()])
#                 if data:
#                     result_data[sheet_name] = data
        
#         return jsonify({
#             "data": result_data,
#             "format": export_format,
#             "exported_sheets": list(result_data.keys()),
#             "timestamp": datetime.now().isoformat(),
#             "status": "success"
#         })
        
#     except Exception as e:
#         logger.error(f"Error in export_data: {str(e)}")
#         return jsonify({
#             "error": str(e),
#             "timestamp": datetime.now().isoformat(),
#             "status": "error"
#         }), 500

# @app.route('/api/reconciliation/test-query', methods=['POST'])
# def test_query():
#     """Test a custom query (for debugging)"""
#     try:
#         request_data = request.get_json()
        
#         if not request_data or 'query' not in request_data:
#             return jsonify({
#                 "error": "Query parameter required",
#                 "timestamp": datetime.now().isoformat()
#             }), 400
        
#         query = request_data['query']
#         data = execute_query(query)
        
#         if data is None:
#             return jsonify({
#                 "error": "Query execution failed",
#                 "timestamp": datetime.now().isoformat()
#             }), 500
        
#         return jsonify({
#             "data": data,
#             "row_count": len(data),
#             "timestamp": datetime.now().isoformat(),
#             "status": "success"
#         })
        
#     except Exception as e:
#         logger.error(f"Error in test_query: {str(e)}")
#         return jsonify({
#             "error": str(e),
#             "timestamp": datetime.now().isoformat(),
#             "status": "error"
#         }), 500

# if __name__ == '__main__':
#     # Test database connection on startup
#     print("=" * 50)
#     print("Starting Reconciliation API Server")
#     print("=" * 50)
#     print("Testing database connection...")
    
#     try:
#         conn = get_db_connection()
#         if conn and conn.is_connected():
#             print("✅ Database connection successful")
            
#             # Test a simple query
#             cursor = conn.cursor()
#             cursor.execute("SHOW TABLES")
#             tables = cursor.fetchall()
#             print(f"✅ Found {len(tables)} tables in database")
            
#             cursor.close()
#             conn.close()
#         else:
#             print("❌ Database connection failed")
#             print("Please check your database configuration in DB_CONFIG")
#     except Exception as e:
#         print(f"❌ Database connection error: {e}")
#         print("Please ensure MySQL is running and credentials are correct")
    
#     print("=" * 50)
#     print("API Endpoints:")
#     print("  GET  /api/health")
#     print("  GET  /api/reconciliation/data")
#     print("  GET  /api/reconciliation/summary")
#     print("  GET  /api/reconciliation/sheet/<n>")
#     print("  POST /api/reconciliation/refresh")
#     print("  POST /api/reconciliation/export")
#     print("  POST /api/upload")
#     print("  POST /api/start-processing")
#     print("  GET  /api/processing-status")
#     print("=" * 50)
    
#     # Start the Flask application
#     app.run(debug=True, host='0.0.0.0', port=5000)


# from flask import Flask, jsonify, request, send_file
# from flask_cors import CORS
# import mysql.connector
# import pandas as pd
# from datetime import datetime
# import logging
# import traceback
# from decimal import Decimal
# import os
# import subprocess
# import threading
# import time
# from werkzeug.utils import secure_filename
# import zipfile
# import shutil
# import json
# import sys

# app = Flask(__name__)
# CORS(app)  # Enable CORS for Flutter frontend

# # Configure logging
# logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
# logger = logging.getLogger(__name__)

# # Database configuration
# DB_CONFIG = {
#     'host': 'localhost',
#     'user': 'root',
#     'password': 'Templerun@2',  # Update this to match your config
#     'database': 'reconciliation'
# }

# # File upload configuration
# UPLOAD_FOLDER = r'C:\Users\IT\Downloads\recon_updated (1)\Recon\Input_Files'
# ALLOWED_EXTENSIONS = {'zip', 'xlsx', 'xls'}
# MAX_FILE_SIZE = 50 * 1024 * 1024  # 50MB

# # Batch file paths with enhanced configuration
# BATCH_FILES = [
#     {
#         'path': r'C:\Users\IT\Downloads\recon_updated (1)\Recon\1_Prepare_Input_Files.bat',
#         'name': 'Prepare Input Files',
#         'description': 'Extract and prepare uploaded files for processing',
#         'timeout': 300,  # 5 minutes
#         'required_files': ['input_files'],
#         'expected_outputs': []
#     },
#     {
#         'path': r'C:\Users\IT\Downloads\recon_updated (1)\Recon\2_PayTm_PhonePe_Recon.bat',
#         'name': 'PayTM & PhonePe Reconciliation',
#         'description': 'Process PayTM, PhonePe, and iCloud data in parallel',
#         'timeout': 5400,  # 90 minutes
#         'required_files': [],
#         'expected_outputs': []
#     },
#     {
#         'path': r'C:\Users\IT\Downloads\recon_updated (1)\Recon\3_LoadDB_ReconDailyExtract.bat',
#         'name': 'Load Data to Database',
#         'description': 'Load processed data into MySQL database',
#         'timeout': 600,  # 10 minutes
#         'required_files': [],
#         'expected_outputs': []
#     }
# ]


# # BATCH_FILES = [
# #     r'C:\Users\IT\Downloads\recon_updated (1)\Recon\1_Prepare_Input_Files.bat',
# #     r'C:\Users\IT\Downloads\recon_updated (1)\Recon\2_PayTm_PhonePe_Recon.bat',
# #     r'C:\Users\IT\Downloads\recon_updated (1)\Recon\3_LoadDB_ReconDailyExtract.bat'
# # ]

# # Global variable to track processing status
# processing_status = {
#     'is_processing': False,
#     'current_step': 0,
#     'total_steps': len(BATCH_FILES),
#     'step_name': '',
#     'progress': 0,
#     'message': '',
#     'error': None,
#     'completed': False,
#     'start_time': None,
#     'uploaded_files': [],
#     'detailed_log': [],
#     'diagnostics': {}
# }

# app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
# app.config['MAX_CONTENT_LENGTH'] = MAX_FILE_SIZE

# # Ensure upload directory exists
# os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# # Database Queries
# QUERIES = {
#     'SUMMARY': """
#         (SELECT txn_source, Txn_type, sum(Txn_Amount) FROM reconciliation.payment_refund pr GROUP BY 1, 2) 
#         UNION 
#         (SELECT Txn_Source, Txn_type, sum(Txn_Amount) FROM reconciliation.paytm_phonepe pp GROUP BY 1, 2)
#     """,
#     'RAWDATA': """
#         (SELECT * FROM reconciliation.paytm_phonepe pp) 
#         UNION ALL 
#         (SELECT * FROM reconciliation.payment_refund pr)
#     """,
#     'RECON_SUCCESS': """
#         SELECT *, 
#                IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),
#                   "Perfect", "Investigate") AS Remarks 
#         FROM reconciliation.recon_outcome ro1 
#         WHERE ((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund)) 
#         AND ro1.Txn_RefNo NOT IN (SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 WHERE ro2.txn_mid like '%manual%') 
#         ORDER BY 1
#     """,
#     'RECON_INVESTIGATE': """
#         SELECT *, 
#                IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),
#                   "Perfect", "Investigate") AS Remarks 
#         FROM reconciliation.recon_outcome ro1 
#         WHERE ((ro1.PTPP_Payment + ro1.PTPP_Refund) != (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund)) 
#         AND ro1.Txn_RefNo NOT IN (SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 WHERE ro2.txn_mid like '%manual%') 
#         ORDER BY 1
#     """,
#     'MANUAL_REFUND': """
#         SELECT *, 
#                IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),
#                   "Perfect", "Investigate") AS Remarks 
#         FROM reconciliation.recon_outcome ro1 
#         WHERE ro1.Txn_RefNo IN (SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 WHERE ro2.txn_mid like '%manual%') 
#         ORDER BY 1
#     """
# }

# # ================== UTILITY FUNCTIONS ==================

# def allowed_file(filename):
#     """Check if file extension is allowed"""
#     return '.' in filename and \
#            filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# def log_processing_step(message, level='INFO'):
#     """Add detailed logging for processing steps"""
#     global processing_status
#     timestamp = datetime.now().isoformat()
#     log_entry = {
#         'timestamp': timestamp,
#         'level': level,
#         'message': message
#     }
#     processing_status['detailed_log'].append(log_entry)
    
#     if level == 'ERROR':
#         logger.error(message)
#     elif level == 'WARNING':
#         logger.warning(message)
#     else:
#         logger.info(message)

# def test_command_execution(command, timeout=10):
#     """Test if a command can be executed successfully"""
#     try:
#         result = subprocess.run(
#             command,
#             shell=True,
#             capture_output=True,
#             text=True,
#             timeout=timeout
#         )
#         return {
#             'success': result.returncode == 0,
#             'returncode': result.returncode,
#             'stdout': result.stdout[:500] if result.stdout else '',
#             'stderr': result.stderr[:500] if result.stderr else '',
#             'error': None
#         }
#     except subprocess.TimeoutExpired:
#         return {
#             'success': False,
#             'returncode': -1,
#             'stdout': '',
#             'stderr': '',
#             'error': f'Command timed out after {timeout} seconds'
#         }
#     except Exception as e:
#         return {
#             'success': False,
#             'returncode': -1,
#             'stdout': '',
#             'stderr': '',
#             'error': str(e)
#         }

# def analyze_batch_file(filepath):
#     """Analyze batch file content and structure"""
#     try:
#         if not os.path.exists(filepath):
#             return {'error': 'File does not exist', 'exists': False}
        
#         with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
#             content = f.read()
        
#         lines = [line.strip() for line in content.split('\n')]
#         non_empty_lines = [line for line in lines if line and not line.startswith('::') and not line.startswith('REM')]
        
#         analysis = {
#             'exists': True,
#             'readable': True,
#             'total_lines': len(lines),
#             'command_lines': len(non_empty_lines),
#             'commands': non_empty_lines[:10],  # First 10 commands
#             'cd_commands': [line for line in non_empty_lines if line.lower().startswith('cd ')],
#             'python_commands': [line for line in non_empty_lines if 'python' in line.lower()],
#             'powershell_commands': [line for line in non_empty_lines if 'powershell' in line.lower()],
#             'call_commands': [line for line in non_empty_lines if line.lower().startswith('call ')],
#             'file_size': os.path.getsize(filepath),
#             'last_modified': datetime.fromtimestamp(os.path.getmtime(filepath)).isoformat()
#         }
        
#         return analysis
#     except Exception as e:
#         return {'error': str(e), 'exists': os.path.exists(filepath), 'readable': False}

# def run_comprehensive_diagnostics():
#     """Run comprehensive system diagnostics"""
#     log_processing_step("Starting comprehensive system diagnostics")
    
#     diagnostics = {
#         'timestamp': datetime.now().isoformat(),
#         'system': {},
#         'directories': {},
#         'batch_files': {},
#         'dependencies': {},
#         'database': {},
#         'overall_status': True,
#         'critical_issues': [],
#         'warnings': []
#     }
    
#     # 1. System Information
#     try:
#         diagnostics['system'] = {
#             'platform': sys.platform,
#             'python_version': sys.version,
#             'working_directory': os.getcwd(),
#             'user': os.environ.get('USERNAME', 'Unknown'),
#             'path_env': os.environ.get('PATH', '')[:500] + '...' if len(os.environ.get('PATH', '')) > 500 else os.environ.get('PATH', '')
#         }
#     except Exception as e:
#         diagnostics['system'] = {'error': str(e)}
    
#     # 2. Directory Checks
#     directories_to_check = [
#         UPLOAD_FOLDER,
#         r'C:\Users\IT\Downloads\recon_updated (1)\Recon',
#         r'C:\Users\IT\Downloads\recon_updated (1)\Recon\output_files'
#     ]
    
#     for directory in directories_to_check:
#         try:
#             exists = os.path.exists(directory)
#             if exists:
#                 readable = os.access(directory, os.R_OK)
#                 writable = os.access(directory, os.W_OK)
#                 files_count = len([f for f in os.listdir(directory) if os.path.isfile(os.path.join(directory, f))])
#             else:
#                 readable = writable = files_count = False
            
#             diagnostics['directories'][directory] = {
#                 'exists': exists,
#                 'readable': readable,
#                 'writable': writable,
#                 'files_count': files_count,
#                 'status': 'OK' if exists and readable and writable else 'ISSUE'
#             }
            
#             if not exists or not readable or not writable:
#                 diagnostics['critical_issues'].append(f"Directory issue: {directory}")
#                 diagnostics['overall_status'] = False
                
#         except Exception as e:
#             diagnostics['directories'][directory] = {'error': str(e), 'status': 'ERROR'}
#             diagnostics['critical_issues'].append(f"Directory error: {directory} - {str(e)}")
#             diagnostics['overall_status'] = False
    
#     # 3. Batch File Analysis
#     for i, batch_info in enumerate(BATCH_FILES):
#         batch_path = batch_info['path']
#         analysis = analyze_batch_file(batch_path)
        
#         diagnostics['batch_files'][f'batch_{i+1}'] = {
#             'name': batch_info['name'],
#             'path': batch_path,
#             'analysis': analysis,
#             'status': 'OK' if analysis.get('exists') and analysis.get('readable') else 'ISSUE'
#         }
        
#         if not analysis.get('exists'):
#             diagnostics['critical_issues'].append(f"Batch file missing: {batch_path}")
#             diagnostics['overall_status'] = False
#         elif not analysis.get('readable'):
#             diagnostics['critical_issues'].append(f"Batch file not readable: {batch_path}")
#             diagnostics['overall_status'] = False
    
#     # 4. Dependency Checks
#     dependencies = [
#         {'name': 'Python', 'command': 'python --version'},
#         {'name': 'PowerShell', 'command': 'powershell -Command "Get-ExecutionPolicy"'},
#         {'name': 'MySQL Client', 'command': 'mysql --version'},
#         {'name': 'Pip', 'command': 'pip --version'}
#     ]
    
#     for dep in dependencies:
#         result = test_command_execution(dep['command'], timeout=15)
#         diagnostics['dependencies'][dep['name']] = {
#             'command': dep['command'],
#             'result': result,
#             'status': 'OK' if result['success'] else 'ISSUE'
#         }
        
#         if not result['success']:
#             diagnostics['warnings'].append(f"Dependency issue: {dep['name']} - {result.get('error', 'Command failed')}")
    
#     # 5. Database Connection Test
#     try:
#         conn = mysql.connector.connect(**DB_CONFIG)
#         cursor = conn.cursor()
#         cursor.execute("SELECT VERSION(), DATABASE(), USER()")
#         result = cursor.fetchone()
#         cursor.close()
#         conn.close()
        
#         diagnostics['database'] = {
#             'connection': 'SUCCESS',
#             'mysql_version': result[0] if result else 'Unknown',
#             'database': result[1] if result else 'Unknown',
#             'user': result[2] if result else 'Unknown',
#             'status': 'OK'
#         }
#     except Exception as e:
#         diagnostics['database'] = {
#             'connection': 'FAILED',
#             'error': str(e),
#             'status': 'CRITICAL'
#         }
#         diagnostics['critical_issues'].append(f"Database connection failed: {str(e)}")
#         diagnostics['overall_status'] = False
    
#     # Store diagnostics in global status
#     processing_status['diagnostics'] = diagnostics
    
#     log_processing_step(f"Diagnostics completed. Overall status: {'PASS' if diagnostics['overall_status'] else 'FAIL'}")
#     log_processing_step(f"Critical issues found: {len(diagnostics['critical_issues'])}")
#     log_processing_step(f"Warnings: {len(diagnostics['warnings'])}")
    
#     return diagnostics

# def check_batch_file_prerequisites():
#     """Quick prerequisite check (lightweight version of diagnostics)"""
#     prerequisites = {
#         'batch_files_exist': True,
#         'mysql_running': True,
#         'python_available': True,
#         'powershell_available': True,
#         'upload_folder_exists': True,
#         'details': []
#     }
    
#     # Check if batch files exist
#     for batch_file in BATCH_FILES:
#         if not os.path.exists(batch_file['path']):
#             prerequisites['batch_files_exist'] = False
#             prerequisites['details'].append(f"Batch file not found: {batch_file['path']}")
    
#     # Check if upload folder exists and is writable
#     if not os.path.exists(UPLOAD_FOLDER):
#         prerequisites['upload_folder_exists'] = False
#         prerequisites['details'].append(f"Upload folder not found: {UPLOAD_FOLDER}")
#     elif not os.access(UPLOAD_FOLDER, os.W_OK):
#         prerequisites['upload_folder_exists'] = False
#         prerequisites['details'].append(f"Upload folder not writable: {UPLOAD_FOLDER}")
    
#     # Check MySQL connection
#     try:
#         conn = mysql.connector.connect(**DB_CONFIG)
#         conn.close()
#     except Exception as e:
#         prerequisites['mysql_running'] = False
#         prerequisites['details'].append(f"MySQL connection failed: {str(e)}")
    
#     # Check Python availability
#     try:
#         result = subprocess.run(['python', '--version'], capture_output=True, text=True, timeout=10)
#         if result.returncode != 0:
#             prerequisites['python_available'] = False
#             prerequisites['details'].append("Python not available in PATH")
#     except Exception as e:
#         prerequisites['python_available'] = False
#         prerequisites['details'].append(f"Python check failed: {str(e)}")
    
#     # Check PowerShell availability
#     try:
#         result = subprocess.run(['powershell', '-Command', 'Get-ExecutionPolicy'], 
#                               capture_output=True, text=True, timeout=10)
#         if result.returncode != 0:
#             prerequisites['powershell_available'] = False
#             prerequisites['details'].append("PowerShell not available or execution policy restricted")
#     except Exception as e:
#         prerequisites['powershell_available'] = False
#         prerequisites['details'].append(f"PowerShell check failed: {str(e)}")
    
#     return prerequisites

# def calculate_summary_stats(data):
#     """Calculate summary statistics from the data"""
#     summary = {
#         'total_transactions': 0,
#         'total_amount': 0,
#         'by_source': {},
#         'by_type': {}
#     }
    
#     # Process RAWDATA for summary statistics
#     if 'RAWDATA' in data:
#         rawdata = data['RAWDATA']
#         summary['total_transactions'] = len(rawdata)
        
#         for row in rawdata:
#             amount = float(row.get('Txn_Amount', 0))
#             summary['total_amount'] += amount
            
#             source = row.get('Txn_Source', 'Unknown')
#             txn_type = row.get('Txn_Type', 'Unknown')
            
#             if source not in summary['by_source']:
#                 summary['by_source'][source] = {'count': 0, 'amount': 0}
#             summary['by_source'][source]['count'] += 1
#             summary['by_source'][source]['amount'] += amount
            
#             if txn_type not in summary['by_type']:
#                 summary['by_type'][txn_type] = {'count': 0, 'amount': 0}
#             summary['by_type'][txn_type]['count'] += 1
#             summary['by_type'][txn_type]['amount'] += amount
    
#     return summary

# def run_batch_files():
#     """CORRECTED: Enhanced batch file execution with proper error handling"""
#     global processing_status
    
#     try:
#         log_processing_step("🚀 Starting batch file execution process")
        
#         # Run comprehensive diagnostics before starting
#         diagnostics = run_comprehensive_diagnostics()
        
#         if not diagnostics['overall_status']:
#             error_msg = f"Diagnostics failed. Critical issues: {'; '.join(diagnostics['critical_issues'])}"
#             processing_status.update({
#                 'error': error_msg,
#                 'is_processing': False
#             })
#             log_processing_step(error_msg, 'ERROR')
#             return
        
#         # Update processing status
#         processing_status.update({
#             'is_processing': True,
#             'current_step': 0,
#             'total_steps': len(BATCH_FILES),
#             'progress': 0,
#             'error': None,
#             'completed': False,
#             'start_time': datetime.now().isoformat()
#         })
        
#         log_processing_step(f"✅ Diagnostics passed. Starting {len(BATCH_FILES)} batch files")
#         log_processing_step(f"📁 Uploaded files: {len(processing_status.get('uploaded_files', []))}")
        
#         # Execute each batch file
#         for i, batch_info in enumerate(BATCH_FILES):
#             batch_file_path = batch_info['path']  # CORRECTED: Use the 'path' key
#             step_name = batch_info['name']
#             timeout = batch_info.get('timeout', 600)
            
#             processing_status.update({
#                 'current_step': i + 1,
#                 'step_name': step_name,
#                 'message': f'Running {os.path.basename(batch_file_path)}...',
#                 'progress': (i / len(BATCH_FILES)) * 100
#             })
            
#             log_processing_step(f"🔄 Starting Step {i+1}/{len(BATCH_FILES)}: {step_name}")
#             log_processing_step(f"📂 Executing: {batch_file_path}")
#             log_processing_step(f"⏱️ Timeout: {timeout} seconds")
            
#             try:
#                 # Enhanced subprocess execution
#                 startupinfo = subprocess.STARTUPINFO()
#                 startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
#                 startupinfo.wShowWindow = subprocess.SW_HIDE
                
#                 # Change to the batch file directory
#                 batch_dir = os.path.dirname(batch_file_path)
                
#                 log_processing_step(f"📁 Working directory: {batch_dir}")
                
#                 # Execute the batch file
#                 start_time = time.time()
#                 result = subprocess.run(
#                     batch_file_path,
#                     shell=True,
#                     capture_output=True,
#                     text=True,
#                     cwd=batch_dir,
#                     timeout=timeout,
#                     startupinfo=startupinfo
#                 )
#                 execution_time = time.time() - start_time
                
#                 log_processing_step(f"⏱️ Execution time: {execution_time:.2f} seconds")
#                 log_processing_step(f"🔢 Return code: {result.returncode}")
                
#                 if result.returncode != 0:
#                     error_msg = f"❌ Batch file {step_name} failed with return code {result.returncode}"
                    
#                     if result.stderr:
#                         error_msg += f"\n📝 Error output:\n{result.stderr}"
#                         log_processing_step(f"📝 STDERR: {result.stderr}", 'ERROR')
                    
#                     if result.stdout:
#                         error_msg += f"\n📄 Standard output:\n{result.stdout}"
#                         log_processing_step(f"📄 STDOUT: {result.stdout}")
                    
#                     processing_status.update({
#                         'error': error_msg,
#                         'is_processing': False
#                     })
#                     log_processing_step(error_msg, 'ERROR')
#                     return
                
#                 # Success
#                 log_processing_step(f"✅ Completed Step {i+1}/{len(BATCH_FILES)}: {step_name}")
                
#                 if result.stdout:
#                     # Log first 1000 characters of output
#                     stdout_preview = result.stdout[:1000] + "..." if len(result.stdout) > 1000 else result.stdout
#                     log_processing_step(f"📄 Output preview: {stdout_preview}")
                
#             except subprocess.TimeoutExpired:
#                 error_msg = f"⏰ Batch file {step_name} timed out after {timeout} seconds"
#                 processing_status.update({
#                     'error': error_msg,
#                     'is_processing': False
#                 })
#                 log_processing_step(error_msg, 'ERROR')
#                 return
                
#             except Exception as e:
#                 error_msg = f"💥 Unexpected error executing {step_name}: {str(e)}"
#                 processing_status.update({
#                     'error': error_msg,
#                     'is_processing': False
#                 })
#                 log_processing_step(error_msg, 'ERROR')
#                 return
        
#         # All batch files completed successfully
#         processing_status.update({
#             'current_step': len(BATCH_FILES),
#             'step_name': 'Completed',
#             'message': 'All processing completed successfully!',
#             'progress': 100,
#             'completed': True,
#             'is_processing': False
#         })
        
#         log_processing_step("🎉 All batch files completed successfully!")
#         log_processing_step(f"📊 Total execution time: {(time.time() - time.mktime(datetime.fromisoformat(processing_status['start_time']).timetuple())):.2f} seconds")
        
#     except Exception as e:
#         error_msg = f"💥 Unexpected error in batch processing: {str(e)}"
#         processing_status.update({
#             'error': error_msg,
#             'is_processing': False
#         })
#         log_processing_step(error_msg, 'ERROR')
#         log_processing_step(f"📋 Traceback: {traceback.format_exc()}", 'ERROR')

# # ================== API ROUTES ==================

# @app.route('/api/health', methods=['GET'])
# def health_check():
#     """Enhanced health check with comprehensive system status"""
#     try:
#         # Test database connection
#         conn = mysql.connector.connect(**DB_CONFIG)
#         cursor = conn.cursor()
#         cursor.execute("SELECT VERSION(), DATABASE(), USER()")
#         db_result = cursor.fetchone()
#         cursor.close()
#         conn.close()
#         db_status = {
#             'status': 'connected',
#             'version': db_result[0] if db_result else 'Unknown',
#             'database': db_result[1] if db_result else 'Unknown',
#             'user': db_result[2] if db_result else 'Unknown'
#         }
#     except Exception as e:
#         db_status = {'status': 'error', 'error': str(e)}
    
#     # Quick system checks
#     system_status = {
#         'upload_folder_exists': os.path.exists(UPLOAD_FOLDER),
#         'upload_folder_writable': os.access(UPLOAD_FOLDER, os.W_OK) if os.path.exists(UPLOAD_FOLDER) else False,
#         'batch_files_exist': all(os.path.exists(bf['path']) for bf in BATCH_FILES),
#         'python_available': test_command_execution('python --version', 5)['success'],
#         'powershell_available': test_command_execution('powershell -Command "Get-ExecutionPolicy"', 5)['success']
#     }
    
#     overall_healthy = (
#         db_status['status'] == 'connected' and
#         system_status['upload_folder_exists'] and
#         system_status['upload_folder_writable'] and
#         system_status['batch_files_exist']
#     )
    
#     return jsonify({
#         'status': 'healthy' if overall_healthy else 'degraded',
#         'timestamp': datetime.now().isoformat(),
#         'database': db_status,
#         'system': system_status,
#         'upload_folder': UPLOAD_FOLDER,
#         'batch_files_configured': len(BATCH_FILES),
#         'processing_status': processing_status,
#         'uploaded_files_count': len(processing_status.get('uploaded_files', []))
#     })

# @app.route('/api/diagnostics', methods=['GET'])
# def get_diagnostics():
#     """Get comprehensive system diagnostics"""
#     try:
#         # Run fresh diagnostics
#         diagnostics = run_comprehensive_diagnostics()
#         return jsonify(diagnostics)
#     except Exception as e:
#         return jsonify({
#             'error': str(e),
#             'timestamp': datetime.now().isoformat()
#         }), 500

# @app.route('/api/upload', methods=['POST'])
# def upload_file():
#     """Enhanced file upload with validation and multiple file tracking"""
#     try:
#         # Check if the post request has the file part
#         if 'file' not in request.files:
#             return jsonify({'error': 'No file part in the request'}), 400
        
#         file = request.files['file']
        
#         # If user does not select file, browser also submits an empty part without filename
#         if file.filename == '':
#             return jsonify({'error': 'No file selected'}), 400
        
#         if file and allowed_file(file.filename):
#             filename = secure_filename(file.filename)
#             filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            
#             # Check if file already exists and create unique name if needed
#             if os.path.exists(filepath):
#                 name, ext = os.path.splitext(filename)
#                 counter = 1
#                 while os.path.exists(filepath):
#                     filename = f"{name}_{counter}{ext}"
#                     filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
#                     counter += 1
            
#             # Save the uploaded file
#             file.save(filepath)
            
#             # Add to uploaded files list
#             if 'uploaded_files' not in processing_status:
#                 processing_status['uploaded_files'] = []
            
#             file_info = {
#                 'filename': filename,
#                 'original_filename': file.filename,
#                 'filepath': filepath,
#                 'size': os.path.getsize(filepath),
#                 'upload_time': datetime.now().isoformat(),
#                 'file_type': filename.split('.')[-1].lower()
#             }
#             processing_status['uploaded_files'].append(file_info)
            
#             logger.info(f"✅ File uploaded successfully: {filename} ({file_info['size']} bytes)")
            
#             return jsonify({
#                 'success': True,
#                 'message': 'File uploaded successfully',
#                 'filename': filename,
#                 'original_filename': file.filename,
#                 'filepath': filepath,
#                 'size': file_info['size'],
#                 'file_type': file_info['file_type'],
#                 'timestamp': file_info['upload_time'],
#                 'total_uploaded_files': len(processing_status['uploaded_files'])
#             })
#         else:
#             return jsonify({
#                 'success': False,
#                 'error': f'File type not allowed. Only {", ".join(ALLOWED_EXTENSIONS)} files are permitted'
#             }), 400
            
#     except Exception as e:
#         logger.error(f"❌ Error uploading file: {str(e)}")
#         return jsonify({'success': False, 'error': str(e)}), 500

# @app.route('/api/uploaded-files', methods=['GET'])
# def get_uploaded_files():
#     """Get list of uploaded files with detailed information"""
#     return jsonify({
#         'uploaded_files': processing_status.get('uploaded_files', []),
#         'total_count': len(processing_status.get('uploaded_files', [])),
#         'total_size': sum(f.get('size', 0) for f in processing_status.get('uploaded_files', [])),
#         'file_types': list(set(f.get('file_type', 'unknown') for f in processing_status.get('uploaded_files', []))),
#         'timestamp': datetime.now().isoformat()
#     })

# @app.route('/api/uploaded-files/<filename>', methods=['DELETE'])
# def delete_uploaded_file(filename):
#     """Delete a specific uploaded file"""
#     try:
#         uploaded_files = processing_status.get('uploaded_files', [])
#         file_to_remove = None
        
#         for i, file_info in enumerate(uploaded_files):
#             if file_info.get('filename') == filename:
#                 file_to_remove = i
#                 break
        
#         if file_to_remove is None:
#             return jsonify({'error': 'File not found in uploaded files list'}), 404
        
#         # Remove file from disk
#         file_info = uploaded_files[file_to_remove]
#         filepath = file_info.get('filepath')
#         if filepath and os.path.exists(filepath):
#             os.remove(filepath)
        
#         # Remove from list
#         uploaded_files.pop(file_to_remove)
        
#         return jsonify({
#             'message': f'File {filename} deleted successfully',
#             'remaining_files': len(uploaded_files)
#         })
        
#     except Exception as e:
#         logger.error(f"❌ Error deleting file {filename}: {str(e)}")
#         return jsonify({'error': str(e)}), 500

# @app.route('/api/uploaded-files', methods=['DELETE'])
# def clear_uploaded_files():
#     """Clear all uploaded files"""
#     try:
#         removed_count = 0
#         # Remove files from disk
#         for file_info in processing_status.get('uploaded_files', []):
#             filepath = file_info.get('filepath')
#             if filepath and os.path.exists(filepath):
#                 os.remove(filepath)
#                 removed_count += 1
        
#         # Clear the list
#         processing_status['uploaded_files'] = []
        
#         return jsonify({
#             'message': f'All uploaded files cleared ({removed_count} files removed)',
#             'removed_count': removed_count
#         })
#     except Exception as e:
#         logger.error(f"❌ Error clearing uploaded files: {str(e)}")
#         return jsonify({'error': str(e)}), 500

# @app.route('/api/start-processing', methods=['POST'])
# def start_processing():
#     """Enhanced processing start with comprehensive validation"""
#     global processing_status
    
#     try:
#         print("🚀 Processing start request received...")
        
#         # Check if already processing
#         if processing_status['is_processing']:
#             print("⚠️ Processing already in progress")
#             return jsonify({
#                 'success': False,
#                 'error': 'Processing already in progress',
#                 'status': processing_status
#             }), 400
        
#         # Check if batch files exist
#         missing_files = []
#         for batch_file in BATCH_FILES:
#             if not os.path.exists(batch_file['path']):
#                 missing_files.append(batch_file['path'])
        
#         if missing_files:
#             error_msg = f"❌ Missing batch files: {', '.join(missing_files)}"
#             print(error_msg)
#             return jsonify({
#                 'success': False,
#                 'error': error_msg,
#                 'missing_files': missing_files
#             }), 400
        
#         # Check if upload folder has files
#         if not os.path.exists(UPLOAD_FOLDER):
#             error_msg = f"❌ Upload folder not found: {UPLOAD_FOLDER}"
#             print(error_msg)
#             return jsonify({'success': False, 'error': error_msg}), 400
        
#         uploaded_files = [f for f in os.listdir(UPLOAD_FOLDER) 
#                          if os.path.isfile(os.path.join(UPLOAD_FOLDER, f))]
        
#         if not uploaded_files:
#             error_msg = "❌ No files found in upload folder. Please upload files first."
#             print(error_msg)
#             return jsonify({'success': False, 'error': error_msg}), 400
        
#         print(f"✅ Found {len(uploaded_files)} uploaded files: {uploaded_files}")
        
#         # Reset processing status
#         processing_status = {
#             'is_processing': True,
#             'current_step': 0,
#             'total_steps': len(BATCH_FILES),
#             'step_name': 'Initializing',
#             'progress': 0,
#             'message': 'Starting batch processing...',
#             'error': None,
#             'completed': False,
#             'start_time': datetime.now().isoformat(),
#             'uploaded_files': processing_status.get('uploaded_files', []),
#             'detailed_log': [],
#             'diagnostics': {}
#         }
        
#         print("🚀 Starting batch processing thread...")
        
#         # Start batch processing in a separate thread
#         thread = threading.Thread(target=run_batch_files)
#         thread.daemon = True
#         thread.start()
        
#         return jsonify({
#             'success': True,
#             'message': 'Processing started successfully',
#             'status': processing_status,
#             'uploaded_files': uploaded_files,
#             'batch_files_ready': True,
#             'timestamp': datetime.now().isoformat()
#         })
        
#     except Exception as e:
#         error_msg = f"💥 Error starting processing: {str(e)}"
#         print(error_msg)
#         logger.error(error_msg)
#         return jsonify({'success': False, 'error': error_msg}), 500

# @app.route('/api/processing-status', methods=['GET'])
# def get_processing_status():
#     """Enhanced processing status with detailed information"""
#     return jsonify({
#         'status': processing_status,
#         'batch_files_info': BATCH_FILES,
#         'logs_count': len(processing_status.get('detailed_log', [])),
#         'uploaded_files_count': len(processing_status.get('uploaded_files', [])),
#         'timestamp': datetime.now().isoformat()
#     })

# @app.route('/api/stop-processing', methods=['POST'])
# def stop_processing():
#     """Stop current processing (if possible)"""
#     global processing_status
    
#     try:
#         if not processing_status['is_processing']:
#             return jsonify({
#                 'success': False,
#                 'error': 'No processing currently running'
#             }), 400
        
#         # Note: This is a graceful stop request - actual stopping depends on batch file cooperation
#         processing_status.update({
#             'message': 'Stop requested - waiting for current step to complete...',
#             'stop_requested': True
#         })
        
#         log_processing_step("🛑 Stop processing requested by user", 'WARNING')
        
#         return jsonify({
#             'success': True,
#             'message': 'Stop request sent. Processing will stop after current step completes.',
#             'timestamp': datetime.now().isoformat()
#         })
        
#     except Exception as e:
#         logger.error(f"❌ Error stopping processing: {str(e)}")
#         return jsonify({'success': False, 'error': str(e)}), 500

# @app.route('/api/processing-logs', methods=['GET'])
# def get_processing_logs():
#     """Get detailed processing logs with filtering options"""
#     try:
#         level_filter = request.args.get('level', None)  # INFO, WARNING, ERROR
#         limit = request.args.get('limit', type=int, default=100)
        
#         logs = processing_status.get('detailed_log', [])
        
#         # Apply level filter
#         if level_filter:
#             logs = [log for log in logs if log.get('level') == level_filter.upper()]
        
#         # Apply limit
#         logs = logs[-limit:] if limit > 0 else logs
        
#         return jsonify({
#             'logs': logs,
#             'total_logs': len(processing_status.get('detailed_log', [])),
#             'filtered_logs': len(logs),
#             'level_filter': level_filter,
#             'timestamp': datetime.now().isoformat()
#         })
        
#     except Exception as e:
#         logger.error(f"❌ Error getting processing logs: {str(e)}")
#         return jsonify({'error': str(e)}), 500

# @app.route('/api/test-batch-file/<int:batch_index>', methods=['POST'])
# def test_batch_file(batch_index):
#     """Test a specific batch file without full processing"""
#     try:
#         if batch_index < 0 or batch_index >= len(BATCH_FILES):
#             return jsonify({
#                 'success': False,
#                 'error': f'Invalid batch index. Must be 0-{len(BATCH_FILES)-1}'
#             }), 400
        
#         batch_info = BATCH_FILES[batch_index]
#         batch_path = batch_info['path']
        
#         # Analyze the batch file
#         analysis = analyze_batch_file(batch_path)
        
#         if not analysis.get('exists'):
#             return jsonify({
#                 'success': False,
#                 'error': f'Batch file does not exist: {batch_path}',
#                 'analysis': analysis
#             }), 404
        
#         # Test execution with short timeout (dry run)
#         test_result = test_command_execution(f'echo Testing {batch_path}', timeout=5)
        
#         return jsonify({
#             'success': True,
#             'batch_info': batch_info,
#             'analysis': analysis,
#             'test_result': test_result,
#             'message': f'Batch file {batch_info["name"]} analysis completed',
#             'timestamp': datetime.now().isoformat()
#         })
        
#     except Exception as e:
#         logger.error(f"❌ Error testing batch file {batch_index}: {str(e)}")
#         return jsonify({'success': False, 'error': str(e)}), 500

# @app.route('/api/check-batch-files', methods=['GET'])
# def check_batch_files():
#     """Check if batch files exist and are accessible"""
#     try:
#         results = []
        
#         for i, batch_info in enumerate(BATCH_FILES):
#             batch_path = batch_info['path']
#             file_info = {
#                 'index': i + 1,
#                 'name': batch_info['name'],
#                 'path': batch_path,
#                 'exists': os.path.exists(batch_path),
#                 'readable': os.access(batch_path, os.R_OK) if os.path.exists(batch_path) else False,
#                 'size': os.path.getsize(batch_path) if os.path.exists(batch_path) else 0
#             }
            
#             # Try to read first few lines
#             if file_info['exists'] and file_info['readable']:
#                 try:
#                     with open(batch_path, 'r', encoding='utf-8', errors='ignore') as f:
#                         first_lines = [f.readline().strip() for _ in range(3)]
#                         file_info['preview'] = first_lines
#                 except Exception as e:
#                     file_info['preview_error'] = str(e)
            
#             results.append(file_info)
        
#         # Check upload folder
#         upload_folder_info = {
#             'path': UPLOAD_FOLDER,
#             'exists': os.path.exists(UPLOAD_FOLDER),
#             'files': []
#         }
        
#         if upload_folder_info['exists']:
#             try:
#                 files = os.listdir(UPLOAD_FOLDER)
#                 upload_folder_info['files'] = [
#                     {
#                         'name': f,
#                         'size': os.path.getsize(os.path.join(UPLOAD_FOLDER, f)),
#                         'modified': os.path.getmtime(os.path.join(UPLOAD_FOLDER, f))
#                     }
#                     for f in files if os.path.isfile(os.path.join(UPLOAD_FOLDER, f))
#                 ]
#             except Exception as e:
#                 upload_folder_info['error'] = str(e)
        
#         return jsonify({
#             'batch_files': results,
#             'upload_folder': upload_folder_info,
#             'all_batch_files_ready': all(r['exists'] and r['readable'] for r in results),
#             'uploaded_files_count': len(upload_folder_info.get('files', [])),
#             'timestamp': datetime.now().isoformat()
#         })
        
#     except Exception as e:
#         return jsonify({'error': str(e)}), 500

# # ================== DATABASE ROUTES ==================

# @app.route('/api/reconciliation/data', methods=['GET'])
# def get_reconciliation_data():
#     """Get all reconciliation data with optional filtering"""
#     try:
#         sheet = request.args.get('sheet', 'RAWDATA')
#         limit = request.args.get('limit', type=int)
        
#         if sheet not in QUERIES:
#             return jsonify({'error': f'Invalid sheet parameter. Available: {list(QUERIES.keys())}'}), 400
        
#         conn = mysql.connector.connect(**DB_CONFIG)
#         cursor = conn.cursor(dictionary=True)
        
#         query = QUERIES[sheet]
#         if limit and limit > 0:
#             query += f" LIMIT {limit}"
        
#         cursor.execute(query)
#         data = cursor.fetchall()
        
#         # Convert Decimal objects to float for JSON serialization
#         for row in data:
#             for key, value in row.items():
#                 if isinstance(value, Decimal):
#                     row[key] = float(value)
        
#         summary_stats = calculate_summary_stats({'RAWDATA': data}) if sheet == 'RAWDATA' else {}
        
#         return jsonify({
#             'data': data,
#             'count': len(data),
#             'sheet': sheet,
#             'summary': summary_stats,
#             'timestamp': datetime.now().isoformat()
#         })
        
#     except mysql.connector.Error as e:
#         logger.error(f"❌ Database error fetching reconciliation data: {str(e)}")
#         return jsonify({'error': f'Database error: {str(e)}'}), 500
#     except Exception as e:
#         logger.error(f"❌ Error fetching reconciliation data: {str(e)}")
#         logger.error(traceback.format_exc())
#         return jsonify({'error': str(e)}), 500
#     finally:
#         try:
#             cursor.close()
#             conn.close()
#         except:
#             pass

# @app.route('/api/reconciliation/summary', methods=['GET'])
# def get_summary():
#     """Get summary statistics"""
#     try:
#         conn = mysql.connector.connect(**DB_CONFIG)
#         cursor = conn.cursor(dictionary=True)
        
#         cursor.execute(QUERIES['SUMMARY'])
#         summary_data = cursor.fetchall()
        
#         # Convert Decimal objects to float
#         for row in summary_data:
#             for key, value in row.items():
#                 if isinstance(value, Decimal):
#                     row[key] = float(value)
        
#         return jsonify({
#             'data': summary_data,
#             'count': len(summary_data),
#             'timestamp': datetime.now().isoformat()
#         })
        
#     except mysql.connector.Error as e:
#         logger.error(f"❌ Database error fetching summary: {str(e)}")
#         return jsonify({'error': f'Database error: {str(e)}'}), 500
#     except Exception as e:
#         logger.error(f"❌ Error fetching summary: {str(e)}")
#         return jsonify({'error': str(e)}), 500
#     finally:
#         try:
#             cursor.close()
#             conn.close()
#         except:
#             pass

# @app.route('/api/reconciliation/sheet/<int:sheet_number>', methods=['GET'])
# def get_sheet_data(sheet_number):
#     """Get data for specific sheet number"""
#     try:
#         sheet_mapping = {
#             1: 'SUMMARY',
#             2: 'RAWDATA', 
#             3: 'RECON_SUCCESS',
#             4: 'RECON_INVESTIGATE',
#             5: 'MANUAL_REFUND'
#         }
        
#         if sheet_number not in sheet_mapping:
#             return jsonify({
#                 'error': f'Invalid sheet number. Available: {list(sheet_mapping.keys())}'
#             }), 400
            
#         sheet_name = sheet_mapping[sheet_number]
        
#         conn = mysql.connector.connect(**DB_CONFIG)
#         cursor = conn.cursor(dictionary=True)
        
#         cursor.execute(QUERIES[sheet_name])
#         data = cursor.fetchall()
        
#         # Convert Decimal objects to float
#         for row in data:
#             for key, value in row.items():
#                 if isinstance(value, Decimal):
#                     row[key] = float(value)
        
#         return jsonify({
#             'data': data,
#             'count': len(data),
#             'sheet_number': sheet_number,
#             'sheet_name': sheet_name,
#             'timestamp': datetime.now().isoformat()
#         })
        
#     except mysql.connector.Error as e:
#         logger.error(f"❌ Database error fetching sheet {sheet_number}: {str(e)}")
#         return jsonify({'error': f'Database error: {str(e)}'}), 500
#     except Exception as e:
#         logger.error(f"❌ Error fetching sheet {sheet_number}: {str(e)}")
#         return jsonify({'error': str(e)}), 500
#     finally:
#         try:
#             cursor.close()
#             conn.close()
#         except:
#             pass

# @app.route('/api/reconciliation/refresh', methods=['POST'])
# def refresh_data():
#     """Refresh data by re-running queries or triggering data reload"""
#     try:
#         # Test database connection
#         conn = mysql.connector.connect(**DB_CONFIG)
#         cursor = conn.cursor()
#         cursor.execute("SELECT COUNT(*) FROM reconciliation.paytm_phonepe")
#         paytm_count = cursor.fetchone()[0]
        
#         cursor.execute("SELECT COUNT(*) FROM reconciliation.payment_refund")
#         payment_count = cursor.fetchone()[0]
        
#         cursor.close()
#         conn.close()
        
#         return jsonify({
#             'message': 'Data refresh completed',
#             'paytm_phonepe_records': paytm_count,
#             'payment_refund_records': payment_count,
#             'total_records': paytm_count + payment_count,
#             'timestamp': datetime.now().isoformat()
#         })
        
#     except mysql.connector.Error as e:
#         logger.error(f"❌ Database error refreshing data: {str(e)}")
#         return jsonify({'error': f'Database error: {str(e)}'}), 500
#     except Exception as e:
#         logger.error(f"❌ Error refreshing data: {str(e)}")
#         return jsonify({'error': str(e)}), 500

# @app.route('/api/reconciliation/export', methods=['POST'])
# def export_data():
#     """Export data to Excel file"""
#     try:
#         sheet_name = request.json.get('sheet', 'RAWDATA') if request.json else 'RAWDATA'
        
#         if sheet_name not in QUERIES:
#             return jsonify({'error': f'Invalid sheet name. Available: {list(QUERIES.keys())}'}), 400
        
#         conn = mysql.connector.connect(**DB_CONFIG)
#         cursor = conn.cursor(dictionary=True)
        
#         cursor.execute(QUERIES[sheet_name])
#         data = cursor.fetchall()
        
#         # Convert Decimal objects to float for Excel
#         for row in data:
#             for key, value in row.items():
#                 if isinstance(value, Decimal):
#                     row[key] = float(value)
        
#         # Convert to DataFrame
#         df = pd.DataFrame(data)
        
#         if df.empty:
#             return jsonify({'error': 'No data to export'}), 400
        
#         # Create export file
#         export_filename = f'reconciliation_{sheet_name}_{datetime.now().strftime("%Y%m%d_%H%M%S")}.xlsx'
#         export_path = os.path.join(app.config['UPLOAD_FOLDER'], export_filename)
        
#         # Ensure export directory exists
#         os.makedirs(os.path.dirname(export_path), exist_ok=True)
        
#         df.to_excel(export_path, index=False, sheet_name=sheet_name)
        
#         return jsonify({
#             'message': 'Export completed successfully',
#             'filename': export_filename,
#             'path': export_path,
#             'records': len(data),
#             'sheet': sheet_name,
#             'file_size': os.path.getsize(export_path),
#             'timestamp': datetime.now().isoformat()
#         })
        
#     except mysql.connector.Error as e:
#         logger.error(f"❌ Database error exporting data: {str(e)}")
#         return jsonify({'error': f'Database error: {str(e)}'}), 500
#     except Exception as e:
#         logger.error(f"❌ Error exporting data: {str(e)}")
#         return jsonify({'error': str(e)}), 500
#     finally:
#         try:
#             cursor.close()
#             conn.close()
#         except:
#             pass

# @app.route('/api/reconciliation/download/<filename>', methods=['GET'])
# def download_exported_file(filename):
#     """Download exported file"""
#     try:
#         file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        
#         if not os.path.exists(file_path):
#             return jsonify({'error': 'File not found'}), 404
        
#         return send_file(
#             file_path,
#             as_attachment=True,
#             download_name=filename,
#             mimetype='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
#         )
        
#     except Exception as e:
#         logger.error(f"❌ Error downloading file {filename}: {str(e)}")
#         return jsonify({'error': str(e)}), 500

# # ================== MAIN APPLICATION ==================

# if __name__ == '__main__':
#     print("=" * 70)
#     print("🚀 ENHANCED RECONCILIATION API SERVER")
#     print("=" * 70)
    
#     # Display startup information
#     print(f"📅 Startup Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
#     print(f"🐍 Python Version: {sys.version.split()[0]}")
#     print(f"📁 Upload Folder: {UPLOAD_FOLDER}")
#     print(f"🗄️  Database: {DB_CONFIG['database']} on {DB_CONFIG['host']}")
#     print(f"🔧 Batch Files Configured: {len(BATCH_FILES)}")
#     print(f"📊 Allowed File Types: {', '.join(ALLOWED_EXTENSIONS)}")
#     print(f"📏 Max File Size: {MAX_FILE_SIZE / (1024*1024):.0f}MB")
    
#     print("\n" + "="*50)
#     print("📋 SYSTEM STATUS CHECK")
#     print("="*50)
    
#     # Run initial diagnostics
#     try:
#         prerequisites = check_batch_file_prerequisites()
        
#         for key, value in prerequisites.items():
#             if key != 'details':
#                 status = "✅" if value else "❌"
#                 print(f"  {status} {key.replace('_', ' ').title()}: {value}")
        
#         if prerequisites['details']:
#             print("\n⚠️  Issues Found:")
#             for detail in prerequisites['details']:
#                 print(f"     • {detail}")
        
#         print(f"\n🎯 Overall System Status: {'✅ READY' if all(prerequisites[k] for k in prerequisites if k != 'details') else '⚠️ ISSUES DETECTED'}")
        
#     except Exception as e:
#         print(f"❌ Error during system check: {str(e)}")
    
#     print("\n" + "="*50)
#     print("🌐 API ENDPOINTS")
#     print("="*50)
#     print("📊 HEALTH & DIAGNOSTICS:")
#     print("   GET  /api/health                    - System health check")
#     print("   GET  /api/diagnostics               - Comprehensive diagnostics")
#     print("   GET  /api/check-batch-files         - Check batch files status")
#     print("\n📤 FILE UPLOAD:")
#     print("   POST /api/upload                    - Upload single file")
#     print("   GET  /api/uploaded-files            - List uploaded files")
#     print("   DEL  /api/uploaded-files            - Clear all uploaded files")
#     print("   DEL  /api/uploaded-files/<filename> - Delete specific file")
#     print("\n⚙️  BATCH PROCESSING:")
#     print("   POST /api/start-processing          - Start batch processing")
#     print("   GET  /api/processing-status         - Get processing status")
#     print("   POST /api/stop-processing           - Stop processing")
#     print("   GET  /api/processing-logs           - Get detailed logs")
#     print("   POST /api/test-batch-file/<index>   - Test specific batch file")
#     print("\n🗄️  DATABASE:")
#     print("   GET  /api/reconciliation/data       - Get reconciliation data")
#     print("   GET  /api/reconciliation/summary    - Get summary statistics") 
#     print("   GET  /api/reconciliation/sheet/<n>  - Get specific sheet data")
#     print("   POST /api/reconciliation/refresh    - Refresh data")
#     print("   POST /api/reconciliation/export     - Export data to Excel")
#     print("   GET  /api/reconciliation/download/<file> - Download exported file")
    
#     print("\n" + "="*50)
#     print("🔧 BATCH FILES CONFIGURED:")
#     print("="*50)
#     for i, batch_info in enumerate(BATCH_FILES, 1):
#         status = "✅" if os.path.exists(batch_info['path']) else "❌"
#         print(f"   {status} {i}. {batch_info['name']}")
#         print(f"        Path: {batch_info['path']}")
#         print(f"        Timeout: {batch_info['timeout']}s")
#         print(f"        Description: {batch_info['description']}")
#         print()
    
#     print("="*70)
#     print("🌟 SERVER FEATURES:")
#     print("   • Multiple file upload support")
#     print("   • Comprehensive system diagnostics")
#     print("   • Real-time batch processing monitoring")
#     print("   • Detailed logging and error tracking")
#     print("   • Enhanced error handling and recovery")
#     print("   • File management and cleanup")
#     print("   • Database integration with all sheets")
#     print("   • Export functionality with multiple formats")
#     print("="*70)
#     print("🚀 Starting Flask development server...")
#     print("📡 Access the API at: http://localhost:5000")
#     print("💡 Use /api/health to verify system status")
#     print("💡 Use /api/check-batch-files to verify batch files")
#     print("="*70)
    
#     # Start the Flask application
#     try:
#         app.run(debug=True, host='0.0.0.0', port=5000, threaded=True)
#     except KeyboardInterrupt:
#         print("\n\n🛑 Server stopped by user")
#     except Exception as e:
#         print(f"\n❌ Server error: {str(e)}")
#     finally:
#         print("👋 Goodbye!")


# from flask import Flask, jsonify, request, send_file
# from flask_cors import CORS
# import mysql.connector
# import pandas as pd
# from datetime import datetime
# import logging
# import traceback
# from decimal import Decimal
# import os
# import subprocess
# import threading
# import time
# from werkzeug.utils import secure_filename
# import zipfile
# import shutil
# import json
# import sys

# app = Flask(__name__)
# CORS(app)  # Enable CORS for Flutter frontend

# # Configure logging
# logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
# logger = logging.getLogger(__name__)

# # Database configuration - KEEP YOUR ORIGINAL SIMPLE APPROACH
# DB_CONFIG = {
#     'host': 'localhost',
#     'user': 'root',
#     'password': 'Templerun@2',  # Your original password
#     'database': 'reconciliation'
# }

# # File upload configuration
# UPLOAD_FOLDER = r'C:\Users\IT\Downloads\recon_updated (1)\Recon\Input_Files'
# ALLOWED_EXTENSIONS = {'zip', 'xlsx', 'xls'}
# MAX_FILE_SIZE = 50 * 1024 * 1024  # 50MB

# # Batch file paths - Enhanced version
# BATCH_FILES = [
#     {
#         'path': r'C:\Users\IT\Downloads\recon_updated (1)\Recon\1_Prepare_Input_Files.bat',
#         'name': 'Prepare Input Files',
#         'description': 'Extract and prepare uploaded files for processing',
#         'timeout': 300,
#     },
#     {
#         'path': r'C:\Users\IT\Downloads\recon_updated (1)\Recon\2_PayTm_PhonePe_Recon.bat',
#         'name': 'PayTM & PhonePe Reconciliation', 
#         'description': 'Process PayTM, PhonePe, and iCloud data in parallel',
#         'timeout': 5400,
#     },
#     {
#         'path': r'C:\Users\IT\Downloads\recon_updated (1)\Recon\3_LoadDB_ReconDailyExtract.bat',
#         'name': 'Load Data to Database',
#         'description': 'Load processed data into MySQL database',
#         'timeout': 600,
#     }
# ]

# # Global variable to track processing status
# processing_status = {
#     'is_processing': False,
#     'current_step': 0,
#     'total_steps': len(BATCH_FILES),
#     'step_name': '',
#     'progress': 0,
#     'message': '',
#     'error': None,
#     'completed': False,
#     'start_time': None,
#     'uploaded_files': [],
#     'detailed_log': []
# }

# app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
# app.config['MAX_CONTENT_LENGTH'] = MAX_FILE_SIZE

# # Ensure upload directory exists
# os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# # Database Queries - YOUR ORIGINAL QUERIES
# QUERIES = {
#     'SUMMARY': """
#         (SELECT txn_source, Txn_type, sum(Txn_Amount) FROM reconciliation.payment_refund pr GROUP BY 1, 2) 
#         UNION 
#         (SELECT Txn_Source, Txn_type, sum(Txn_Amount) FROM reconciliation.paytm_phonepe pp GROUP BY 1, 2)
#     """,
#     'RAWDATA': """
#         (SELECT * FROM reconciliation.paytm_phonepe pp) 
#         UNION ALL 
#         (SELECT * FROM reconciliation.payment_refund pr)
#     """,
#     'RECON_SUCCESS': """
#         SELECT *, 
#                IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),
#                   "Perfect", "Investigate") AS Remarks 
#         FROM reconciliation.recon_outcome ro1 
#         WHERE ((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund)) 
#         AND ro1.Txn_RefNo NOT IN (SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 WHERE ro2.txn_mid like '%manual%') 
#         ORDER BY 1
#     """,
#     'RECON_INVESTIGATE': """
#         SELECT *, 
#                IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),
#                   "Perfect", "Investigate") AS Remarks 
#         FROM reconciliation.recon_outcome ro1 
#         WHERE ((ro1.PTPP_Payment + ro1.PTPP_Refund) != (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund)) 
#         AND ro1.Txn_RefNo NOT IN (SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 WHERE ro2.txn_mid like '%manual%') 
#         ORDER BY 1
#     """,
#     'MANUAL_REFUND': """
#         SELECT *, 
#                IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),
#                   "Perfect", "Investigate") AS Remarks 
#         FROM reconciliation.recon_outcome ro1 
#         WHERE ro1.Txn_RefNo IN (SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 WHERE ro2.txn_mid like '%manual%') 
#         ORDER BY 1
#     """
# }

# # YOUR ORIGINAL DATABASE FUNCTIONS - KEEP SIMPLE
# def get_db_connection():
#     """Create and return a database connection - YOUR ORIGINAL APPROACH"""
#     try:
#         conn = mysql.connector.connect(**DB_CONFIG)
#         return conn
#     except mysql.connector.Error as err:
#         logger.error(f"Database connection error: {err}")
#         return None

# def serialize_value(value):
#     """Convert various data types to JSON serializable format - YOUR ORIGINAL"""
#     if value is None:
#         return None
#     elif isinstance(value, datetime):
#         return value.isoformat()
#     elif isinstance(value, bytes):
#         return value.decode('utf-8', errors='ignore')
#     elif isinstance(value, Decimal):
#         return float(value)
#     else:
#         return value

# def execute_query(query):
#     """Execute a query and return results as a list of dictionaries - YOUR ORIGINAL"""
#     conn = get_db_connection()
#     if not conn:
#         return None
    
#     try:
#         cursor = conn.cursor(dictionary=True)
#         cursor.execute(query)
#         results = cursor.fetchall()
        
#         # Convert any problematic data types for JSON serialization
#         serialized_results = []
#         for row in results:
#             serialized_row = {}
#             for key, value in row.items():
#                 serialized_row[key] = serialize_value(value)
#             serialized_results.append(serialized_row)
        
#         return serialized_results
#     except mysql.connector.Error as err:
#         logger.error(f"Query execution error: {err}")
#         logger.error(f"Query: {query}")
#         return None
#     except Exception as e:
#         logger.error(f"Unexpected error: {e}")
#         logger.error(traceback.format_exc())
#         return None
#     finally:
#         if conn.is_connected():
#             cursor.close()
#             conn.close()

# def allowed_file(filename):
#     """Check if file extension is allowed"""
#     return '.' in filename and \
#            filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# def calculate_summary_stats(data):
#     """Calculate summary statistics from the data"""
#     summary = {
#         'total_transactions': 0,
#         'total_amount': 0,
#         'by_source': {},
#         'by_type': {}
#     }
    
#     # Process RAWDATA for summary statistics
#     if 'RAWDATA' in data:
#         rawdata = data['RAWDATA']
#         summary['total_transactions'] = len(rawdata)
        
#         for row in rawdata:
#             amount = float(row.get('Txn_Amount', 0))
#             summary['total_amount'] += amount
            
#             source = row.get('Txn_Source', 'Unknown')
#             txn_type = row.get('Txn_Type', 'Unknown')
            
#             if source not in summary['by_source']:
#                 summary['by_source'][source] = {'count': 0, 'amount': 0}
#             summary['by_source'][source]['count'] += 1
#             summary['by_source'][source]['amount'] += amount
            
#             if txn_type not in summary['by_type']:
#                 summary['by_type'][txn_type] = {'count': 0, 'amount': 0}
#             summary['by_type'][txn_type]['count'] += 1
#             summary['by_type'][txn_type]['amount'] += amount
    
#     return summary

# def run_batch_files():
#     """Enhanced batch file execution"""
#     global processing_status
    
#     try:
#         processing_status.update({
#             'is_processing': True,
#             'current_step': 0,
#             'total_steps': len(BATCH_FILES),
#             'progress': 0,
#             'error': None,
#             'completed': False,
#             'start_time': datetime.now().isoformat()
#         })
        
#         for i, batch_info in enumerate(BATCH_FILES):
#             batch_file_path = batch_info['path']
#             step_name = batch_info['name']
#             timeout = batch_info.get('timeout', 600)
            
#             processing_status.update({
#                 'current_step': i + 1,
#                 'step_name': step_name,
#                 'message': f'Running {os.path.basename(batch_file_path)}...',
#                 'progress': (i / len(BATCH_FILES)) * 100
#             })
            
#             logger.info(f"Starting batch file: {batch_file_path}")
            
#             try:
#                 # Enhanced subprocess execution
#                 result = subprocess.run(
#                     batch_file_path,
#                     shell=True,
#                     capture_output=True,
#                     text=True,
#                     cwd=os.path.dirname(batch_file_path),
#                     timeout=timeout
#                 )
                
#                 if result.returncode != 0:
#                     error_msg = f"Batch file {step_name} failed with return code {result.returncode}"
#                     if result.stderr:
#                         error_msg += f": {result.stderr}"
                    
#                     processing_status.update({
#                         'error': error_msg,
#                         'is_processing': False
#                     })
#                     logger.error(error_msg)
#                     return
                
#                 logger.info(f"Completed batch file: {batch_file_path}")
                
#             except subprocess.TimeoutExpired:
#                 error_msg = f"Batch file {step_name} timed out after {timeout} seconds"
#                 processing_status.update({
#                     'error': error_msg,
#                     'is_processing': False
#                 })
#                 logger.error(error_msg)
#                 return
                
#             except Exception as e:
#                 error_msg = f"Error executing {step_name}: {str(e)}"
#                 processing_status.update({
#                     'error': error_msg,
#                     'is_processing': False
#                 })
#                 logger.error(error_msg)
#                 return
        
#         # All batch files completed successfully
#         processing_status.update({
#             'current_step': len(BATCH_FILES),
#             'step_name': 'Completed',
#             'message': 'All processing completed successfully!',
#             'progress': 100,
#             'completed': True,
#             'is_processing': False
#         })
        
#         logger.info("All batch files completed successfully")
        
#     except Exception as e:
#         error_msg = f"Error running batch files: {str(e)}"
#         processing_status.update({
#             'error': error_msg,
#             'is_processing': False
#         })
#         logger.error(error_msg)

# # API ROUTES

# @app.route('/api/health', methods=['GET'])
# def health_check():
#     """Enhanced health check - BASED ON YOUR ORIGINAL BUT ENHANCED"""
#     try:
#         conn = get_db_connection()
#         if conn and conn.is_connected():
#             cursor = conn.cursor()
#             cursor.execute("SELECT 1")
#             cursor.fetchone()
#             cursor.close()
#             conn.close()
            
#             return jsonify({
#                 "status": "healthy",
#                 "database": "connected",
#                 "database_connected": True,  # Added for Flutter compatibility
#                 "timestamp": datetime.now().isoformat(),
#                 "upload_folder": UPLOAD_FOLDER,
#                 "batch_files_configured": len(BATCH_FILES)
#             })
#         else:
#             return jsonify({
#                 "status": "unhealthy",
#                 "database": "disconnected", 
#                 "database_connected": False,  # Added for Flutter compatibility
#                 "timestamp": datetime.now().isoformat()
#             }), 500
#     except Exception as e:
#         logger.error(f"Health check error: {e}")
#         return jsonify({
#             "status": "error",
#             "database": "error",
#             "database_connected": False,  # Added for Flutter compatibility
#             "error": str(e),
#             "timestamp": datetime.now().isoformat()
#         }), 500

# @app.route('/api/upload', methods=['POST'])
# def upload_file():
#     """Enhanced file upload"""
#     try:
#         if 'file' not in request.files:
#             return jsonify({'error': 'No file part in the request'}), 400
        
#         file = request.files['file']
        
#         if file.filename == '':
#             return jsonify({'error': 'No file selected'}), 400
        
#         if file and allowed_file(file.filename):
#             filename = secure_filename(file.filename)
#             filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            
#             # Check if file already exists and create unique name if needed
#             if os.path.exists(filepath):
#                 name, ext = os.path.splitext(filename)
#                 counter = 1
#                 while os.path.exists(filepath):
#                     filename = f"{name}_{counter}{ext}"
#                     filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
#                     counter += 1
            
#             # Save the uploaded file
#             file.save(filepath)
            
#             # Add to uploaded files list
#             if 'uploaded_files' not in processing_status:
#                 processing_status['uploaded_files'] = []
            
#             file_info = {
#                 'filename': filename,
#                 'original_filename': file.filename,
#                 'filepath': filepath,
#                 'size': os.path.getsize(filepath),
#                 'upload_time': datetime.now().isoformat(),
#                 'file_type': filename.split('.')[-1].lower()
#             }
#             processing_status['uploaded_files'].append(file_info)
            
#             logger.info(f"File uploaded successfully: {filename} ({file_info['size']} bytes)")
            
#             return jsonify({
#                 'success': True,
#                 'message': 'File uploaded successfully',
#                 'filename': filename,
#                 'original_filename': file.filename,
#                 'filepath': filepath,
#                 'size': file_info['size'],
#                 'file_type': file_info['file_type'],
#                 'timestamp': file_info['upload_time'],
#                 'total_uploaded_files': len(processing_status['uploaded_files'])
#             })
#         else:
#             return jsonify({
#                 'success': False,
#                 'error': f'File type not allowed. Only {", ".join(ALLOWED_EXTENSIONS)} files are permitted'
#             }), 400
            
#     except Exception as e:
#         logger.error(f"Error uploading file: {str(e)}")
#         return jsonify({'success': False, 'error': str(e)}), 500

# @app.route('/api/start-processing', methods=['POST'])
# def start_processing():
#     """Enhanced processing start"""
#     global processing_status
    
#     try:
#         # Check if already processing
#         if processing_status['is_processing']:
#             return jsonify({
#                 'success': False,
#                 'error': 'Processing already in progress',
#                 'status': processing_status
#             }), 400
        
#         # Check if batch files exist
#         missing_files = []
#         for batch_file in BATCH_FILES:
#             if not os.path.exists(batch_file['path']):
#                 missing_files.append(batch_file['path'])
        
#         if missing_files:
#             error_msg = f"Missing batch files: {', '.join(missing_files)}"
#             return jsonify({
#                 'success': False,
#                 'error': error_msg,
#                 'missing_files': missing_files
#             }), 400
        
#         # Check if upload folder has files
#         if not os.path.exists(UPLOAD_FOLDER):
#             error_msg = f"Upload folder not found: {UPLOAD_FOLDER}"
#             return jsonify({'success': False, 'error': error_msg}), 400
        
#         uploaded_files = [f for f in os.listdir(UPLOAD_FOLDER) 
#                          if os.path.isfile(os.path.join(UPLOAD_FOLDER, f))]
        
#         if not uploaded_files:
#             error_msg = "No files found in upload folder. Please upload files first."
#             return jsonify({'success': False, 'error': error_msg}), 400
        
#         # Reset processing status
#         processing_status = {
#             'is_processing': True,
#             'current_step': 0,
#             'total_steps': len(BATCH_FILES),
#             'step_name': 'Initializing',
#             'progress': 0,
#             'message': 'Starting batch processing...',
#             'error': None,
#             'completed': False,
#             'start_time': datetime.now().isoformat(),
#             'uploaded_files': processing_status.get('uploaded_files', []),
#             'detailed_log': []
#         }
        
#         # Start batch processing in a separate thread
#         thread = threading.Thread(target=run_batch_files)
#         thread.daemon = True
#         thread.start()
        
#         return jsonify({
#             'success': True,
#             'message': 'Processing started successfully',
#             'status': processing_status,
#             'uploaded_files': uploaded_files,
#             'timestamp': datetime.now().isoformat()
#         })
        
#     except Exception as e:
#         error_msg = f"Error starting processing: {str(e)}"
#         logger.error(error_msg)
#         return jsonify({'success': False, 'error': error_msg}), 500

# @app.route('/api/processing-status', methods=['GET'])
# def get_processing_status():
#     """Get current processing status"""
#     return jsonify({
#         'status': processing_status,
#         'timestamp': datetime.now().isoformat()
#     })

# # YOUR ORIGINAL DATABASE ENDPOINTS - UNCHANGED
# @app.route('/api/reconciliation/data', methods=['GET'])
# def get_reconciliation_data():
#     """Get all reconciliation data - YOUR ORIGINAL LOGIC"""
#     try:
#         sheet = request.args.get('sheet', 'RAWDATA')
#         limit = request.args.get('limit', type=int)
        
#         if sheet not in QUERIES:
#             return jsonify({'error': f'Invalid sheet parameter. Available: {list(QUERIES.keys())}'}), 400
        
#         query = QUERIES[sheet]
#         if limit and limit > 0:
#             query += f" LIMIT {limit}"
        
#         data = execute_query(query)
        
#         if data is None:
#             return jsonify({'error': f'Failed to execute query for {sheet}'}), 500
        
#         summary_stats = calculate_summary_stats({sheet: data}) if sheet == 'RAWDATA' else {}
        
#         return jsonify({
#             'data': data,
#             'count': len(data),
#             'sheet': sheet,
#             'summary': summary_stats,
#             'timestamp': datetime.now().isoformat(),
#             'status': 'success'
#         })
        
#     except Exception as e:
#         logger.error(f"Error fetching reconciliation data: {str(e)}")
#         return jsonify({'error': str(e)}), 500

# @app.route('/api/reconciliation/summary', methods=['GET'])
# def get_summary():
#     """Get summary statistics - YOUR ORIGINAL"""
#     try:
#         data = execute_query(QUERIES['SUMMARY'])
        
#         if data is None:
#             return jsonify({'error': 'Failed to execute summary query'}), 500
        
#         return jsonify({
#             'data': data,
#             'count': len(data),
#             'timestamp': datetime.now().isoformat(),
#             'status': 'success'
#         })
        
#     except Exception as e:
#         logger.error(f"Error fetching summary: {str(e)}")
#         return jsonify({'error': str(e)}), 500

# @app.route('/api/reconciliation/refresh', methods=['POST'])
# def refresh_data():
#     """Refresh data - YOUR ORIGINAL ENHANCED"""
#     try:
#         # Test database connection
#         conn = get_db_connection()
#         if not conn:
#             return jsonify({'error': 'Database connection failed'}), 500
        
#         cursor = conn.cursor()
#         cursor.execute("SELECT COUNT(*) FROM reconciliation.paytm_phonepe")
#         paytm_count = cursor.fetchone()[0]
        
#         cursor.execute("SELECT COUNT(*) FROM reconciliation.payment_refund")
#         payment_count = cursor.fetchone()[0]
        
#         cursor.close()
#         conn.close()
        
#         return jsonify({
#             'message': 'Data refresh completed',
#             'paytm_phonepe_records': paytm_count,
#             'payment_refund_records': payment_count,
#             'total_records': paytm_count + payment_count,
#             'status': 'success',
#             'timestamp': datetime.now().isoformat()
#         })
        
#     except Exception as e:
#         logger.error(f"Error refreshing data: {str(e)}")
#         return jsonify({'error': str(e)}), 500

# if __name__ == '__main__':
#     # Test database connection on startup - YOUR ORIGINAL APPROACH ENHANCED
#     print("=" * 70)
#     print("🚀 RECONCILIATION API SERVER")
#     print("=" * 70)
#     print(f"📅 Startup Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
#     print(f"🗄️  Database: {DB_CONFIG['database']} on {DB_CONFIG['host']}")
#     print(f"📁 Upload Folder: {UPLOAD_FOLDER}")
#     print(f"🔧 Batch Files: {len(BATCH_FILES)}")
    
#     print("\n" + "="*50)
#     print("📋 DATABASE CONNECTION TEST")
#     print("="*50)
    
#     try:
#         conn = get_db_connection()
#         if conn and conn.is_connected():
#             print("✅ Database connection successful")
            
#             # Test a simple query
#             cursor = conn.cursor()
#             cursor.execute("SHOW TABLES")
#             tables = cursor.fetchall()
#             print(f"✅ Found {len(tables)} tables in database")
            
#             cursor.close()
#             conn.close()
#         else:
#             print("❌ Database connection failed")
#             print("Please check:")
#             print("  1. MySQL server is running")
#             print("  2. Database 'reconciliation' exists") 
#             print("  3. Credentials in DB_CONFIG are correct")
#     except Exception as e:
#         print(f"❌ Database connection error: {e}")
#         print("Please ensure MySQL is running and credentials are correct")
    
#     print("\n" + "="*50)
#     print("🌐 API ENDPOINTS")
#     print("="*50)
#     print("  GET  /api/health")
#     print("  POST /api/upload")
#     print("  POST /api/start-processing")
#     print("  GET  /api/processing-status")
#     print("  GET  /api/reconciliation/data")
#     print("  GET  /api/reconciliation/summary")
#     print("  POST /api/reconciliation/refresh")
#     print("="*70)
    
#     # Start the Flask application
#     app.run(debug=True, host='0.0.0.0', port=5000, threaded=True)


import os
from pathlib import Path
from flask import Flask, jsonify, request, send_file
from flask_cors import CORS
import mysql.connector
import pandas as pd
from datetime import datetime
import logging
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




BASE_DIR = Path(__file__).parent.resolve()

# Build paths relative to the app.py location
UPLOAD_FOLDER = BASE_DIR / 'Input_Files'
BATCH_FILES = [
    {
        'path': str(BASE_DIR / 'run_all_scripts.bat'),
        'name': 'Complete Reconciliation Process',
        'description': 'Execute all 3 steps: Prepare Files → Process Data → Load Database',
        'timeout': 7200
    }
]

ALLOWED_EXTENSIONS = {'zip', 'xlsx', 'xls'}
MAX_FILE_SIZE = 50 * 1024 * 1024

app = Flask(__name__)
CORS(app)


# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Database configuration - KEEP YOUR ORIGINAL SIMPLE APPROACH
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': 'Templerun@2',  # Your original password
    'database': 'reconciliation'
}


# Get the directory where this script is located
BASE_DIR = Path(__file__).parent.resolve()
UPLOAD_FOLDER = BASE_DIR / 'Input_Files'
ALLOWED_EXTENSIONS = {'zip', 'xlsx', 'xls'}
MAX_FILE_SIZE = 50 * 1024 * 1024  # 50MB

 

BATCH_FILES = [
    {
        'path': str(BASE_DIR / 'run_all_scripts.bat'),
        'name': 'Complete Reconciliation Process',
        'description': 'Execute all 3 steps: Prepare Files → Process Data → Load Database',
        'timeout': 7200,  # 2 hours timeout for all steps
    }
]

# Global variable to track processing status
processing_status = {
    'is_processing': False,
    'current_step': 0,
    'total_steps': 1,
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
# Create other required directories
os.makedirs(BASE_DIR / 'Output_Files', exist_ok=True)

# Database Queries - YOUR ORIGINAL QUERIES
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

# YOUR ORIGINAL DATABASE FUNCTIONS - KEEP SIMPLE
def get_db_connection():
    """Create and return a database connection - YOUR ORIGINAL APPROACH"""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        return conn
    except mysql.connector.Error as err:
        logger.error(f"Database connection error: {err}")
        return None

def serialize_value(value):
    """Convert various data types to JSON serializable format - YOUR ORIGINAL"""
    if value is None:
        return None
    elif isinstance(value, datetime):
        return value.isoformat()
    elif isinstance(value, bytes):
        return value.decode('utf-8', errors='ignore')
    elif isinstance(value, Decimal):
        return float(value)
    else:
        return value

def execute_query(query):
    """Execute a query and return results as a list of dictionaries - YOUR ORIGINAL"""
    conn = get_db_connection()
    if not conn:
        return None
    
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute(query)
        results = cursor.fetchall()
        
        # Convert any problematic data types for JSON serialization
        serialized_results = []
        for row in results:
            serialized_row = {}
            for key, value in row.items():
                serialized_row[key] = serialize_value(value)
            serialized_results.append(serialized_row)
        
        return serialized_results
    except mysql.connector.Error as err:
        logger.error(f"Query execution error: {err}")
        logger.error(f"Query: {query}")
        return None
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        logger.error(traceback.format_exc())
        return None
    finally:
        if conn.is_connected():
            cursor.close()
            conn.close()

def allowed_file(filename):
    """Check if file extension is allowed"""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

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

@app.route('/api/debug/processing', methods=['GET'])
def debug_processing():
    """Debug processing status and files"""
    try:
        # Check upload folder
        upload_files = []
        if os.path.exists(UPLOAD_FOLDER):
            for f in os.listdir(UPLOAD_FOLDER):
                if os.path.isfile(os.path.join(UPLOAD_FOLDER, f)):
                    filepath = os.path.join(UPLOAD_FOLDER, f)
                    upload_files.append({
                        'name': f,
                        'size': os.path.getsize(filepath),
                        'modified': datetime.fromtimestamp(os.path.getmtime(filepath)).isoformat()
                    })
        
        # Check batch file
        batch_file_exists = os.path.exists(BATCH_FILES[0]['path']) if BATCH_FILES else False
        
        # Check if process is running
        import psutil
        python_processes = []
        for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
            try:
                if 'python' in proc.info['name'].lower():
                    cmdline = ' '.join(proc.info['cmdline']) if proc.info['cmdline'] else ''
                    if 'run_all_scripts' in cmdline or 'app.py' in cmdline:
                        python_processes.append({
                            'pid': proc.info['pid'],
                            'name': proc.info['name'],
                            'cmdline': cmdline
                        })
            except:
                pass
        
        return jsonify({
            'upload_folder': str(UPLOAD_FOLDER),
            'upload_folder_exists': os.path.exists(UPLOAD_FOLDER),
            'uploaded_files': upload_files,
            'batch_file_path': BATCH_FILES[0]['path'] if BATCH_FILES else None,
            'batch_file_exists': batch_file_exists,
            'processing_status': processing_status,
            'python_processes': python_processes,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# 2. ADD this route to manually test the batch file:
@app.route('/api/debug/test-batch', methods=['POST'])
def test_batch_file():
    """Test batch file execution manually"""
    try:
        if not BATCH_FILES:
            return jsonify({'error': 'No batch files configured'}), 400
        
        batch_file = BATCH_FILES[0]['path']
        
        if not os.path.exists(batch_file):
            return jsonify({'error': f'Batch file not found: {batch_file}'}), 400
        
        # Test execution with short timeout
        result = subprocess.run(
            batch_file,
            shell=True,
            capture_output=True,
            text=True,
            cwd=str(Path(batch_file).parent),
            timeout=30  # Short timeout for testing
        )
        
        return jsonify({
            'batch_file': batch_file,
            'return_code': result.returncode,
            'stdout': result.stdout[-1000:] if result.stdout else None,  # Last 1000 chars
            'stderr': result.stderr[-1000:] if result.stderr else None,
            'success': result.returncode == 0
        })
        
    except subprocess.TimeoutExpired:
        return jsonify({'error': 'Batch file test timed out (30s)', 'note': 'This might be normal if the script takes long'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/debug/check-files', methods=['GET'])
def check_uploaded_files():
    """Check what files are actually in the upload folder"""
    try:
        if not os.path.exists(UPLOAD_FOLDER):
            return jsonify({'error': f'Upload folder does not exist: {UPLOAD_FOLDER}'}), 400
        
        files_info = []
        for filename in os.listdir(UPLOAD_FOLDER):
            filepath = os.path.join(UPLOAD_FOLDER, filename)
            if os.path.isfile(filepath):
                # Get file info
                stat = os.stat(filepath)
                files_info.append({
                    'filename': filename,
                    'size_bytes': stat.st_size,
                    'size_mb': round(stat.st_size / (1024*1024), 2),
                    'modified': datetime.fromtimestamp(stat.st_mtime).isoformat(),
                    'extension': filename.split('.')[-1].lower() if '.' in filename else 'none',
                    'is_allowed': filename.split('.')[-1].lower() in ALLOWED_EXTENSIONS if '.' in filename else False
                })
        
        return jsonify({
            'upload_folder': str(UPLOAD_FOLDER),
            'total_files': len(files_info),
            'files': files_info,
            'allowed_extensions': list(ALLOWED_EXTENSIONS),
            'has_valid_files': any(f['is_allowed'] for f in files_info)
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

def run_batch_files():
    """Execute the single run_all_scripts.bat file"""
    global processing_status
    
    try:
        processing_status.update({
            'is_processing': True,
            'current_step': 1,
            'total_steps': 1,
            'progress': 10,
            'error': None,
            'completed': False,
            'start_time': datetime.now().isoformat(),
            'step_name': 'Complete Reconciliation Process',
            'message': 'Starting complete reconciliation workflow...'
        })
        
        batch_file = BATCH_FILES[0]['path']
        timeout = BATCH_FILES[0]['timeout']
        
        logger.info(f"🚀 Starting run_all_scripts.bat: {batch_file}")
        
        # Update progress
        processing_status['progress'] = 20
        processing_status['message'] = 'Executing run_all_scripts.bat (Step 1/3: Preparing files...)'
        
        # Execute the batch file
        result = subprocess.run(
            batch_file,
            shell=True,
            capture_output=True,
            text=True,
            cwd=str(BASE_DIR),  # Use BASE_DIR as working directory
            timeout=timeout
        )
        
        processing_status['progress'] = 90
        
        if result.returncode != 0:
            # Check which step failed based on return code
            step_errors = {
                1: "Step 1 failed - Prepare Input Files",
                2: "Step 2 failed - PayTM PhonePe Reconciliation", 
                3: "Step 3 failed - Load DB and Generate Report"
            }
            
            error_msg = step_errors.get(result.returncode, f"Unknown error (code: {result.returncode})")
            
            if result.stderr:
                error_msg += f"\nError details: {result.stderr}"
            if result.stdout:
                error_msg += f"\nOutput: {result.stdout[-500:]}"  # Last 500 chars
            
            processing_status.update({
                'error': error_msg,
                'is_processing': False,
                'progress': 0,
                'message': f'Failed at step {result.returncode}'
            })
            
            logger.error(f"❌ run_all_scripts.bat failed: {error_msg}")
            return
        
        # SUCCESS!
        processing_status.update({
            'message': 'All steps completed! Files cleaned up automatically.',
            'progress': 100,
            'completed': True,
            'is_processing': False
        })
        
        logger.info("✅ run_all_scripts.bat completed successfully!")
        logger.info("✅ Database should now contain reconciliation data")
        
    except subprocess.TimeoutExpired:
        error_msg = f"Processing timed out after {timeout/60:.1f} minutes"
        processing_status.update({
            'error': error_msg,
            'is_processing': False,
            'progress': 0,
            'message': 'Process timed out'
        })
        logger.error(f"⏰ Timeout: {error_msg}")
        
    except Exception as e:
        error_msg = f"Unexpected error: {str(e)}"
        processing_status.update({
            'error': error_msg,
            'is_processing': False,
            'progress': 0,
            'message': 'Process failed'
        })
        logger.error(f"💥 Exception: {error_msg}")
# API ROUTES

@app.route('/api/health', methods=['GET'])
def health_check():
    """Enhanced health check - BASED ON YOUR ORIGINAL BUT ENHANCED"""
    try:
        conn = get_db_connection()
        if conn and conn.is_connected():
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            cursor.fetchone()
            cursor.close()
            conn.close()
            
            return jsonify({
                "status": "healthy",
                "database": "connected",
                "database_connected": True,  # Added for Flutter compatibility
                "timestamp": datetime.now().isoformat(),
                "upload_folder": str(UPLOAD_FOLDER),
                "batch_files_configured": len(BATCH_FILES)
            })
        else:
            return jsonify({
                "status": "unhealthy",
                "database": "disconnected", 
                "database_connected": False,  # Added for Flutter compatibility
                "timestamp": datetime.now().isoformat()
            }), 500
    except Exception as e:
        logger.error(f"Health check error: {e}")
        return jsonify({
            "status": "error",
            "database": "error",
            "database_connected": False,  # Added for Flutter compatibility
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }), 500

@app.route('/api/upload', methods=['POST'])
def upload_file():
    """Enhanced file upload"""
    try:
        if 'file' not in request.files:
            return jsonify({'error': 'No file part in the request'}), 400
        
        file = request.files['file']
        
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
            
            logger.info(f"File uploaded successfully: {filename} ({file_info['size']} bytes)")
            
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
        logger.error(f"Error uploading file: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/start-processing', methods=['POST'])
def start_processing():
    """Enhanced processing start"""
    global processing_status
    
    try:
        # Check if already processing
        if processing_status['is_processing']:
            return jsonify({
                'success': False,
                'error': 'Processing already in progress',
                'status': processing_status
            }), 400
        
        # Check if batch files exist
        missing_files = []
        for batch_file in BATCH_FILES:
            if not os.path.exists(batch_file['path']):
                missing_files.append(batch_file['path'])
        
        if missing_files:
            error_msg = f"Missing batch files: {', '.join(missing_files)}"
            return jsonify({
                'success': False,
                'error': error_msg,
                'missing_files': missing_files
            }), 400
        
        # Check if upload folder has files
        if not os.path.exists(UPLOAD_FOLDER):
            error_msg = f"Upload folder not found: {UPLOAD_FOLDER}"
            return jsonify({'success': False, 'error': error_msg}), 400
        
        uploaded_files = [f for f in os.listdir(UPLOAD_FOLDER) 
                         if os.path.isfile(os.path.join(UPLOAD_FOLDER, f))]
        
        if not uploaded_files:
            error_msg = "No files found in upload folder. Please upload files first."
            return jsonify({'success': False, 'error': error_msg}), 400
        
        # Reset processing status
        processing_status = {
            'is_processing': True,
            'current_step': 0,
            'total_steps': len(BATCH_FILES),
            'step_name': 'Initializing',
            'progress': 0,
            'message': 'Starting batch processing...',
            'error': None,
            'completed': False,
            'start_time': datetime.now().isoformat(),
            'uploaded_files': processing_status.get('uploaded_files', []),
            'detailed_log': []
        }
        
        # Start batch processing in a separate thread
        thread = threading.Thread(target=run_batch_files)
        thread.daemon = True
        thread.start()
        
        return jsonify({
            'success': True,
            'message': 'Processing started successfully',
            'status': processing_status,
            'uploaded_files': uploaded_files,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        error_msg = f"Error starting processing: {str(e)}"
        logger.error(error_msg)
        return jsonify({'success': False, 'error': error_msg}), 500

@app.route('/api/processing-status', methods=['GET'])
def get_processing_status():
    """Get current processing status"""
    return jsonify({
        'status': processing_status,
        'timestamp': datetime.now().isoformat()
    })

# YOUR ORIGINAL DATABASE ENDPOINTS - UNCHANGED
@app.route('/api/reconciliation/data', methods=['GET'])
def get_reconciliation_data():
    """Get all reconciliation data - YOUR ORIGINAL LOGIC"""
    try:
        sheet = request.args.get('sheet', 'RAWDATA')
        limit = request.args.get('limit', type=int)
        
        if sheet not in QUERIES:
            return jsonify({'error': f'Invalid sheet parameter. Available: {list(QUERIES.keys())}'}), 400
        
        query = QUERIES[sheet]
        if limit and limit > 0:
            query += f" LIMIT {limit}"
        
        data = execute_query(query)
        
        if data is None:
            return jsonify({'error': f'Failed to execute query for {sheet}'}), 500
        
        summary_stats = calculate_summary_stats({sheet: data}) if sheet == 'RAWDATA' else {}
        
        return jsonify({
            'data': data,
            'count': len(data),
            'sheet': sheet,
            'summary': summary_stats,
            'timestamp': datetime.now().isoformat(),
            'status': 'success'
        })
        
    except Exception as e:
        logger.error(f"Error fetching reconciliation data: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/reconciliation/summary', methods=['GET'])
def get_summary():
    """Get summary statistics - YOUR ORIGINAL"""
    try:
        data = execute_query(QUERIES['SUMMARY'])
        
        if data is None:
            return jsonify({'error': 'Failed to execute summary query'}), 500
        
        return jsonify({
            'data': data,
            'count': len(data),
            'timestamp': datetime.now().isoformat(),
            'status': 'success'
        })
        
    except Exception as e:
        logger.error(f"Error fetching summary: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/reconciliation/refresh', methods=['POST'])
def refresh_data():
    """Refresh data - YOUR ORIGINAL ENHANCED"""
    try:
        # Test database connection
        conn = get_db_connection()
        if not conn:
            return jsonify({'error': 'Database connection failed'}), 500
        
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM reconciliation.paytm_phonepe")
        paytm_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM reconciliation.payment_refund")
        payment_count = cursor.fetchone()[0]
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'message': 'Data refresh completed',
            'paytm_phonepe_records': paytm_count,
            'payment_refund_records': payment_count,
            'total_records': paytm_count + payment_count,
            'status': 'success',
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Error refreshing data: {str(e)}")
        return jsonify({'error': str(e)}), 500



# debug


@app.route('/api/debug/kill-processing', methods=['POST'])
def kill_processing():
    """Force kill any stuck processing"""
    global processing_status
    
    try:
        # Reset processing status
        processing_status.update({
            'is_processing': False,
            'current_step': 0,
            'progress': 0,
            'error': 'Processing was manually stopped',
            'completed': False,
            'message': 'Processing stopped by user'
        })
        
        # Try to kill any hanging batch processes
        import psutil
        killed_processes = []
        
        for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
            try:
                cmdline = ' '.join(proc.info['cmdline']) if proc.info['cmdline'] else ''
                if any(keyword in cmdline.lower() for keyword in ['run_all_scripts', 'batch', '.bat']):
                    proc.kill()
                    killed_processes.append({
                        'pid': proc.info['pid'],
                        'name': proc.info['name'],
                        'cmdline': cmdline
                    })
            except:
                pass
        
        return jsonify({
            'success': True,
            'message': 'Processing killed and reset',
            'killed_processes': killed_processes,
            'new_status': processing_status
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/debug/check-batch-running', methods=['GET'])
def check_batch_running():
    """Check if batch processes are running"""
    try:
        import psutil
        running_processes = []
        
        for proc in psutil.process_iter(['pid', 'name', 'cmdline', 'create_time', 'cpu_percent']):
            try:
                cmdline = ' '.join(proc.info['cmdline']) if proc.info['cmdline'] else ''
                if any(keyword in cmdline.lower() for keyword in ['run_all_scripts', '.bat', 'cmd.exe']):
                    running_processes.append({
                        'pid': proc.info['pid'],
                        'name': proc.info['name'],
                        'cmdline': cmdline,
                        'running_time': time.time() - proc.info['create_time'],
                        'cpu_percent': proc.info['cpu_percent']
                    })
            except:
                pass
        
        return jsonify({
            'running_processes': running_processes,
            'process_count': len(running_processes),
            'processing_status': processing_status,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/debug/test-batch-simple', methods=['POST'])
def test_batch_simple():
    """Test batch file with simple execution"""
    try:
        batch_file = BATCH_FILES[0]['path']
        
        # Test 1: Check if file exists and is readable
        if not os.path.exists(batch_file):
            return jsonify({'error': f'Batch file not found: {batch_file}'}), 400
        
        # Test 2: Try to read the first few lines
        try:
            with open(batch_file, 'r') as f:
                first_lines = [f.readline().strip() for _ in range(5)]
        except Exception as e:
            return jsonify({'error': f'Cannot read batch file: {e}'}), 400
        
        # Test 3: Try very short execution with timeout
        try:
            result = subprocess.run(
                ['cmd', '/c', 'echo', 'Testing...'],
                capture_output=True,
                text=True,
                timeout=5
            )
            cmd_test = {'success': True, 'output': result.stdout}
        except Exception as e:
            cmd_test = {'success': False, 'error': str(e)}
        
        # Test 4: Check working directory
        working_dir = str(Path(batch_file).parent)
        dir_contents = os.listdir(working_dir) if os.path.exists(working_dir) else []
        
        return jsonify({
            'batch_file': batch_file,
            'file_exists': True,
            'file_readable': True,
            'first_lines': first_lines,
            'cmd_test': cmd_test,
            'working_directory': working_dir,
            'dir_contents': dir_contents[:10],  # First 10 files
            'batch_files_in_dir': [f for f in dir_contents if f.endswith('.bat')]
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ENHANCED run_batch_files function with better logging
def run_batch_files():
    """Simplified and reliable batch file execution"""
    global processing_status
    
    try:
        processing_status.update({
            'is_processing': True,
            'current_step': 1,
            'total_steps': 1,
            'progress': 10,
            'error': None,
            'completed': False,
            'start_time': datetime.now().isoformat(),
            'step_name': 'Complete Reconciliation Process',
            'message': 'Starting batch execution...'
        })
        
        batch_file = BATCH_FILES[0]['path']
        timeout = BATCH_FILES[0]['timeout']
        working_dir = str(Path(batch_file).parent)
        
        logger.info(f"🚀 Starting batch file: {batch_file}")
        logger.info(f"📁 Working directory: {working_dir}")
        logger.info(f"⏰ Timeout set to: {timeout} seconds")
        
        # Update progress
        processing_status['progress'] = 20
        processing_status['message'] = 'Executing batch file...'
        
        # SIMPLIFIED APPROACH: Just run the batch file directly
        # Since you confirmed it works manually, let's not modify it
        
        logger.info("📋 Executing batch file directly...")
        
        # Use Popen for better control and real-time logging
        process = subprocess.Popen(
            [batch_file],
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            cwd=working_dir,
            env=os.environ.copy(),  # Important: pass environment variables
            bufsize=1,  # Line buffering
            universal_newlines=True
        )
        
        # Update progress while process runs
        processing_status['progress'] = 30
        processing_status['message'] = 'Batch file is running...'
        
        # Wait for completion with timeout
        try:
            stdout, stderr = process.communicate(timeout=timeout)
            return_code = process.returncode
            
            logger.info(f"📊 Batch execution completed - Return code: {return_code}")
            
            # Log output for debugging
            if stdout:
                logger.info(f"📝 Batch stdout (last 500 chars): {stdout[-500:]}")
            if stderr:
                logger.warning(f"⚠️ Batch stderr: {stderr}")
            
            # Check return code
            if return_code != 0:
                error_msg = f"Batch file failed with exit code {return_code}"
                if stderr:
                    error_msg += f"\nError output: {stderr}"
                if stdout:
                    error_msg += f"\nLast output: {stdout[-500:]}"
                
                processing_status.update({
                    'error': error_msg,
                    'is_processing': False,
                    'progress': 0,
                    'message': f'Processing failed (exit code {return_code})'
                })
                logger.error(f"❌ Batch execution failed: {error_msg}")
                return
            
            # SUCCESS!
            processing_status.update({
                'progress': 100,
                'completed': True,
                'is_processing': False,
                'message': 'All processing completed successfully!'
            })
            logger.info("✅ Batch processing completed successfully!")
            
            # Log success details
            if "ALL SCRIPTS COMPLETED SUCCESSFULLY" in stdout:
                logger.info("🎉 Confirmed: All scripts completed successfully")
            
        except subprocess.TimeoutExpired:
            logger.warning(f"⏰ Batch process timed out after {timeout} seconds, terminating...")
            process.kill()
            
            # Wait a bit for cleanup
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                logger.error("💀 Force killing process...")
                process.terminate()
            
            processing_status.update({
                'error': f'Batch processing timed out after {timeout/60:.1f} minutes',
                'is_processing': False,
                'progress': 0,
                'message': 'Processing timed out'
            })
            
    except FileNotFoundError:
        error_msg = f"Batch file not found: {batch_file}"
        processing_status.update({
            'error': error_msg,
            'is_processing': False,
            'progress': 0,
            'message': 'Batch file not found'
        })
        logger.error(f"❌ {error_msg}")
        
    except PermissionError:
        error_msg = f"Permission denied executing batch file: {batch_file}"
        processing_status.update({
            'error': error_msg,
            'is_processing': False,
            'progress': 0,
            'message': 'Permission denied'
        })
        logger.error(f"❌ {error_msg}")
        
    except Exception as e:
        error_msg = f"Unexpected error: {str(e)}"
        processing_status.update({
            'error': error_msg,
            'is_processing': False,
            'progress': 0,
            'message': 'Unexpected error occurred'
        })
        logger.error(f"💥 Exception in batch execution: {error_msg}")
        logger.error(traceback.format_exc())


if __name__ == '__main__':
    # Test database connection on startup - YOUR ORIGINAL APPROACH ENHANCED
    print("=" * 70)
    print("🚀 RECONCILIATION API SERVER")
    print("=" * 70)
    print(f"📅 Startup Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"🗄️  Database: {DB_CONFIG['database']} on {DB_CONFIG['host']}")
    print(f"📁 Upload Folder: {UPLOAD_FOLDER}")
    print(f"🔧 Batch Files: {len(BATCH_FILES)}")
    
    print("\n" + "="*50)
    print("📋 DATABASE CONNECTION TEST")
    print("="*50)
    
    try:
        conn = get_db_connection()
        if conn and conn.is_connected():
            print("✅ Database connection successful")
            
            # Test a simple query
            cursor = conn.cursor()
            cursor.execute("SHOW TABLES")
            tables = cursor.fetchall()
            print(f"✅ Found {len(tables)} tables in database")
            
            cursor.close()
            conn.close()
        else:
            print("❌ Database connection failed")
            print("Please check:")
            print("  1. MySQL server is running")
            print("  2. Database 'reconciliation' exists") 
            print("  3. Credentials in DB_CONFIG are correct")
    except Exception as e:
        print(f"❌ Database connection error: {e}")
        print("Please ensure MySQL is running and credentials are correct")
    
    print("\n" + "="*50)
    print("🌐 API ENDPOINTS")
    print("="*50)
    print("  GET  /api/health")
    print("  POST /api/upload")
    print("  POST /api/start-processing")
    print("  GET  /api/processing-status")
    print("  GET  /api/reconciliation/data")
    print("  GET  /api/reconciliation/summary")
    print("  POST /api/reconciliation/refresh")
    print("="*70)
    
    # Start the Flask application
    app.run(debug=True, host='0.0.0.0', port=5000, threaded=True)