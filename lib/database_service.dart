// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:http/http.dart' as http;
// import 'models.dart';

// // Database Service for fetching data from MySQL via Flask API
// class DatabaseService {
//   static const String baseUrl =
//       'http://localhost:5000'; // Update this to your Flask server URL
//   static const Duration defaultTimeout = Duration(seconds: 30);
//   static const Duration healthCheckTimeout = Duration(seconds: 5);
//   static const Duration refreshTimeout = Duration(seconds: 60);

//   // Fetch all reconciliation data from database
//   static Future<Map<String, dynamic>?> fetchReconciliationData() async {
//     try {
//       print('Fetching reconciliation data from database...');

//       final response = await http.get(
//         Uri.parse('$baseUrl/api/reconciliation/data'),
//         headers: {'Content-Type': 'application/json'},
//       ).timeout(defaultTimeout);

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> jsonData = json.decode(response.body);
//         print('Successfully fetched data from database');
//         print('Total sheets: ${jsonData['total_sheets']}');
//         return jsonData;
//       } else {
//         final errorBody =
//             response.body.isNotEmpty ? response.body : 'No error details';
//         throw Exception('HTTP ${response.statusCode}: $errorBody');
//       }
//     } on http.ClientException catch (e) {
//       print('Network error fetching reconciliation data: $e');
//       throw Exception(
//           'Network error: Please check if the API server is running at $baseUrl');
//     } catch (e) {
//       print('Error fetching reconciliation data: $e');
//       throw Exception('Failed to fetch reconciliation data: $e');
//     }
//   }

//   // Fetch specific sheet data
//   static Future<Map<String, dynamic>?> fetchSheetData(String sheetName) async {
//     try {
//       print('Fetching $sheetName data from database...');

//       final response = await http.get(
//         Uri.parse('$baseUrl/api/reconciliation/sheet/$sheetName'),
//         headers: {'Content-Type': 'application/json'},
//       ).timeout(defaultTimeout);

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> jsonData = json.decode(response.body);
//         print(
//             'Successfully fetched $sheetName data: ${jsonData['row_count']} rows');
//         return jsonData;
//       } else if (response.statusCode == 404) {
//         throw Exception('Sheet $sheetName not found');
//       } else {
//         final errorBody =
//             response.body.isNotEmpty ? response.body : 'No error details';
//         throw Exception('HTTP ${response.statusCode}: $errorBody');
//       }
//     } on http.ClientException catch (e) {
//       print('Network error fetching $sheetName data: $e');
//       throw Exception('Network error: Please check API server connection');
//     } catch (e) {
//       print('Error fetching $sheetName data: $e');
//       throw Exception('Failed to fetch $sheetName data: $e');
//     }
//   }

//   // Fetch summary statistics
//   static Future<Map<String, dynamic>?> fetchSummaryStats() async {
//     try {
//       print('Fetching summary statistics from database...');

//       final response = await http.get(
//         Uri.parse('$baseUrl/api/reconciliation/summary'),
//         headers: {'Content-Type': 'application/json'},
//       ).timeout(defaultTimeout);

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> jsonData = json.decode(response.body);
//         print('Successfully fetched summary statistics');
//         return jsonData;
//       } else {
//         final errorBody =
//             response.body.isNotEmpty ? response.body : 'No error details';
//         throw Exception('HTTP ${response.statusCode}: $errorBody');
//       }
//     } on http.ClientException catch (e) {
//       print('Network error fetching summary statistics: $e');
//       throw Exception('Network error: Please check API server connection');
//     } catch (e) {
//       print('Error fetching summary statistics: $e');
//       throw Exception('Failed to fetch summary statistics: $e');
//     }
//   }

//   // Refresh data (trigger reconciliation process)
//   static Future<Map<String, dynamic>?> refreshReconciliationData() async {
//     try {
//       print('Refreshing reconciliation data...');

//       final response = await http.post(
//         Uri.parse('$baseUrl/api/reconciliation/refresh'),
//         headers: {'Content-Type': 'application/json'},
//       ).timeout(refreshTimeout);

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> jsonData = json.decode(response.body);
//         print('Successfully refreshed reconciliation data');
//         return jsonData;
//       } else {
//         final errorBody =
//             response.body.isNotEmpty ? response.body : 'No error details';
//         throw Exception('HTTP ${response.statusCode}: $errorBody');
//       }
//     } on http.ClientException catch (e) {
//       print('Network error refreshing reconciliation data: $e');
//       throw Exception('Network error: Please check API server connection');
//     } catch (e) {
//       print('Error refreshing reconciliation data: $e');
//       throw Exception('Failed to refresh reconciliation data: $e');
//     }
//   }

//   // Parse database response to transaction models
//   static List<TransactionModel> parseTransactionsFromDatabase(
//       Map<String, dynamic> apiResponse) {
//     try {
//       print('Parsing transactions from database response...');
//       List<TransactionModel> allTransactions = [];

//       final Map<String, dynamic> data = apiResponse['data'] ?? {};

//       // Process each sheet's data
//       final transactionSheets = [
//         'RECON_SUCCESS',
//         'RECON_INVESTIGATE',
//         'MANUAL_REFUND'
//       ];

//       for (String sheetName in transactionSheets) {
//         if (!data.containsKey(sheetName)) {
//           print('Warning: Sheet $sheetName not found in response');
//           continue;
//         }

//         final List<dynamic> sheetData = data[sheetName] ?? [];
//         print('Processing $sheetName with ${sheetData.length} rows');

//         ReconciliationStatus status = _getStatusFromSheetName(sheetName);
//         int successCount = 0;
//         int errorCount = 0;

//         for (var row in sheetData) {
//           try {
//             if (row is Map<String, dynamic>) {
//               TransactionModel transaction =
//                   TransactionModel.fromDatabaseRow(row, status);
//               allTransactions.add(transaction);
//               successCount++;
//             } else {
//               print('Warning: Invalid row format in $sheetName');
//               errorCount++;
//             }
//           } catch (e) {
//             print('Error parsing transaction row in $sheetName: $e');
//             errorCount++;
//             continue;
//           }
//         }

//         print(
//             'Successfully parsed $successCount transactions from $sheetName (errors: $errorCount)');
//       }

//       if (allTransactions.isEmpty) {
//         throw Exception('No valid transactions found in database response');
//       }

//       print(
//           'Total transactions parsed from database: ${allTransactions.length}');
//       return allTransactions;
//     } catch (e) {
//       print('Error parsing transactions from database: $e');
//       throw Exception('Failed to parse database response: $e');
//     }
//   }

//   // Get reconciliation status from sheet name
//   static ReconciliationStatus _getStatusFromSheetName(String sheetName) {
//     final lowerSheetName = sheetName.toLowerCase();
//     if (lowerSheetName.contains('success') ||
//         lowerSheetName.contains('perfect')) {
//       return ReconciliationStatus.perfect;
//     } else if (lowerSheetName.contains('investigate')) {
//       return ReconciliationStatus.investigate;
//     } else if (lowerSheetName.contains('manual') ||
//         lowerSheetName.contains('refund')) {
//       return ReconciliationStatus.manualRefund;
//     }
//     return ReconciliationStatus.missing; // Default
//   }

//   // Check server health
//   static Future<bool> checkServerHealth() async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/api/health'),
//         headers: {'Content-Type': 'application/json'},
//       ).timeout(healthCheckTimeout);

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> healthData = json.decode(response.body);
//         final String status = healthData['status'] ?? 'unknown';
//         final String database = healthData['database'] ?? 'unknown';

//         print('Health check result: $status, Database: $database');
//         return status == 'healthy' && database == 'connected';
//       } else {
//         print('Health check failed: HTTP ${response.statusCode}');
//         return false;
//       }
//     } on http.ClientException catch (e) {
//       print('Health check network error: $e');
//       return false;
//     } catch (e) {
//       print('Server health check failed: $e');
//       return false;
//     }
//   }

//   // Export data (for compatibility with existing export functionality)
//   static Future<Map<String, dynamic>?> exportData(
//       {List<String>? sheets}) async {
//     try {
//       print('Exporting data from database...');

//       final Map<String, dynamic> requestData = {
//         'sheets': sheets ??
//             [
//               'SUMMARY',
//               'RAWDATA',
//               'RECON_SUCCESS',
//               'RECON_INVESTIGATE',
//               'MANUAL_REFUND'
//             ]
//       };

//       final response = await http
//           .post(
//             Uri.parse('$baseUrl/api/reconciliation/export'),
//             headers: {'Content-Type': 'application/json'},
//             body: json.encode(requestData),
//           )
//           .timeout(defaultTimeout);

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> jsonData = json.decode(response.body);
//         print('Successfully exported data: ${jsonData['exported_sheets']}');
//         return jsonData;
//       } else {
//         final errorBody =
//             response.body.isNotEmpty ? response.body : 'No error details';
//         throw Exception('HTTP ${response.statusCode}: $errorBody');
//       }
//     } on http.ClientException catch (e) {
//       print('Network error exporting data: $e');
//       throw Exception('Network error: Please check API server connection');
//     } catch (e) {
//       print('Error exporting data: $e');
//       throw Exception('Failed to export data: $e');
//     }
//   }

//   // Test custom query (for debugging)
//   static Future<Map<String, dynamic>?> testQuery(String query) async {
//     try {
//       print('Testing custom query...');

//       final Map<String, dynamic> requestData = {'query': query};

//       final response = await http
//           .post(
//             Uri.parse('$baseUrl/api/reconciliation/test-query'),
//             headers: {'Content-Type': 'application/json'},
//             body: json.encode(requestData),
//           )
//           .timeout(defaultTimeout);

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> jsonData = json.decode(response.body);
//         print('Query executed successfully: ${jsonData['row_count']} rows');
//         return jsonData;
//       } else {
//         final errorBody =
//             response.body.isNotEmpty ? response.body : 'No error details';
//         throw Exception('HTTP ${response.statusCode}: $errorBody');
//       }
//     } on http.ClientException catch (e) {
//       print('Network error testing query: $e');
//       throw Exception('Network error: Please check API server connection');
//     } catch (e) {
//       print('Error testing query: $e');
//       throw Exception('Failed to test query: $e');
//     }
//   }

//   // Convert database export to Excel-like format for existing export service
//   static Uint8List convertToExcelFormat(Map<String, dynamic> exportData) {
//     // This would integrate with your existing ExportService.exportToExcel
//     // For now, return empty bytes - you can integrate with your Excel export logic
//     print('Converting export data to Excel format...');
//     // You can implement actual Excel conversion here using your existing ExportService
//     return Uint8List(0);
//   }

//   // Get database connection info
//   static Map<String, String> getDatabaseInfo() {
//     return {
//       'baseUrl': baseUrl,
//       'healthEndpoint': '$baseUrl/api/health',
//       'dataEndpoint': '$baseUrl/api/reconciliation/data',
//       'summaryEndpoint': '$baseUrl/api/reconciliation/summary',
//       'refreshEndpoint': '$baseUrl/api/reconciliation/refresh',
//       'exportEndpoint': '$baseUrl/api/reconciliation/export',
//       'testQueryEndpoint': '$baseUrl/api/reconciliation/test-query',
//     };
//   }

//   // Validate API response structure
//   static bool validateApiResponse(Map<String, dynamic> response) {
//     try {
//       // Check for required fields
//       if (!response.containsKey('data') && !response.containsKey('summary')) {
//         print('Invalid API response: missing data or summary field');
//         return false;
//       }

//       // Check status if present
//       if (response.containsKey('status')) {
//         final status = response['status'];
//         if (status == 'error') {
//           print(
//               'API response indicates error: ${response['error'] ?? 'Unknown error'}');
//           return false;
//         }
//       }

//       // Check timestamp if present
//       if (response.containsKey('timestamp')) {
//         final timestamp = response['timestamp'];
//         if (timestamp == null || timestamp.toString().isEmpty) {
//           print('Warning: API response missing timestamp');
//         }
//       }

//       return true;
//     } catch (e) {
//       print('Error validating API response: $e');
//       return false;
//     }
//   }

//   // Format error message for UI display
//   static String formatErrorMessage(String error) {
//     if (error.contains('Network error')) {
//       return 'Unable to connect to database server. Please ensure the API server is running on $baseUrl.';
//     } else if (error.contains('HTTP 500')) {
//       return 'Database server error. Please check the server logs and database connection.';
//     } else if (error.contains('HTTP 404')) {
//       return 'Requested data not found in database. Please check if the reconciliation tables contain data.';
//     } else if (error.contains('HTTP 400')) {
//       return 'Invalid request. Please check the request parameters.';
//     } else if (error.contains('timeout')) {
//       return 'Request timed out. The database might be slow or unavailable. Please try again.';
//     } else if (error.contains('Connection refused')) {
//       return 'Cannot connect to API server. Please ensure the Flask API is running on $baseUrl.';
//     } else if (error.contains('Failed to fetch')) {
//       return 'Network connection failed. Please check your internet connection and API server status.';
//     } else {
//       return error;
//     }
//   }

//   // Parse response and extract meaningful error info
//   static String extractErrorFromResponse(String responseBody) {
//     try {
//       final Map<String, dynamic> errorResponse = json.decode(responseBody);
//       return errorResponse['error'] ??
//           errorResponse['message'] ??
//           'Unknown server error';
//     } catch (e) {
//       return responseBody.isNotEmpty
//           ? responseBody
//           : 'Empty response from server';
//     }
//   }

//   // Validate response data structure for transactions
//   static bool validateTransactionData(Map<String, dynamic> data) {
//     try {
//       // Check if data contains expected sheet keys
//       final expectedSheets = [
//         'RECON_SUCCESS',
//         'RECON_INVESTIGATE',
//         'MANUAL_REFUND'
//       ];
//       bool hasValidSheets = false;

//       for (String sheet in expectedSheets) {
//         if (data.containsKey(sheet) && data[sheet] is List) {
//           hasValidSheets = true;
//           break;
//         }
//       }

//       if (!hasValidSheets) {
//         print('Invalid transaction data: missing expected sheets');
//         return false;
//       }

//       return true;
//     } catch (e) {
//       print('Error validating transaction data: $e');
//       return false;
//     }
//   }

//   // Get API status info
//   static Future<Map<String, dynamic>> getApiStatus() async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/api/health'),
//         headers: {'Content-Type': 'application/json'},
//       ).timeout(healthCheckTimeout);

//       if (response.statusCode == 200) {
//         return json.decode(response.body);
//       } else {
//         return {
//           'status': 'error',
//           'database': 'unknown',
//           'message': 'HTTP ${response.statusCode}',
//         };
//       }
//     } catch (e) {
//       return {
//         'status': 'error',
//         'database': 'disconnected',
//         'message': e.toString(),
//       };
//     }
//   }

//   // Helper method to retry failed requests
//   static Future<Map<String, dynamic>?> retryRequest(
//       Future<Map<String, dynamic>?> Function() requestFunction,
//       {int maxRetries = 3,
//       Duration delay = const Duration(seconds: 2)}) async {
//     for (int attempt = 1; attempt <= maxRetries; attempt++) {
//       try {
//         final result = await requestFunction();
//         return result;
//       } catch (e) {
//         print('Request attempt $attempt failed: $e');

//         if (attempt == maxRetries) {
//           rethrow; // Throw the last error if all attempts failed
//         }

//         // Wait before retrying
//         await Future.delayed(delay);
//       }
//     }
//     return null;
//   }

//   // Batch request helper for multiple endpoints
//   static Future<Map<String, dynamic>> batchRequest(
//       List<String> endpoints) async {
//     final Map<String, dynamic> results = {};

//     final futures = endpoints.map((endpoint) async {
//       try {
//         final response = await http.get(
//           Uri.parse('$baseUrl$endpoint'),
//           headers: {'Content-Type': 'application/json'},
//         ).timeout(defaultTimeout);

//         if (response.statusCode == 200) {
//           return MapEntry(endpoint, json.decode(response.body));
//         } else {
//           return MapEntry(endpoint, {'error': 'HTTP ${response.statusCode}'});
//         }
//       } catch (e) {
//         return MapEntry(endpoint, {'error': e.toString()});
//       }
//     });

//     final completedFutures = await Future.wait(futures);

//     for (var entry in completedFutures) {
//       results[entry.key] = entry.value;
//     }

//     return results;
//   }

//   // Cache management for frequently accessed data
//   static final Map<String, Map<String, dynamic>> _cache = {};
//   static final Map<String, DateTime> _cacheTimestamps = {};
//   static const Duration cacheExpiry = Duration(minutes: 5);

//   static Future<Map<String, dynamic>?> getCachedData(String key) async {
//     if (_cache.containsKey(key) && _cacheTimestamps.containsKey(key)) {
//       final cacheTime = _cacheTimestamps[key]!;
//       if (DateTime.now().difference(cacheTime) < cacheExpiry) {
//         print('Returning cached data for: $key');
//         return _cache[key];
//       } else {
//         // Remove expired cache
//         _cache.remove(key);
//         _cacheTimestamps.remove(key);
//       }
//     }
//     return null;
//   }

//   static void setCachedData(String key, Map<String, dynamic> data) {
//     _cache[key] = data;
//     _cacheTimestamps[key] = DateTime.now();
//     print('Cached data for: $key');
//   }

//   static void clearCache() {
//     _cache.clear();
//     _cacheTimestamps.clear();
//     print('Cache cleared');
//   }

//   // Enhanced fetch with caching
//   static Future<Map<String, dynamic>?> fetchReconciliationDataWithCache(
//       {bool useCache = true}) async {
//     const cacheKey = 'reconciliation_data';

//     if (useCache) {
//       final cachedData = await getCachedData(cacheKey);
//       if (cachedData != null) {
//         return cachedData;
//       }
//     }

//     final freshData = await fetchReconciliationData();
//     if (freshData != null) {
//       setCachedData(cacheKey, freshData);
//     }

//     return freshData;
//   }
// }

//2

import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'models.dart';

// Enhanced Database Service with file upload and processing support
class DatabaseService {
  static const String baseUrl = 'http://localhost:5000';
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration healthCheckTimeout = Duration(seconds: 5);
  static const Duration refreshTimeout = Duration(seconds: 60);
  static const Duration uploadTimeout = Duration(seconds: 120);
  static const Duration processingTimeout = Duration(seconds: 300);

  // EXISTING METHODS (unchanged)

  /// Fetch all reconciliation data from database
  static Future<Map<String, dynamic>?> fetchReconciliationData() async {
    try {
      print('Fetching reconciliation data from database...');

      final response = await http.get(
        Uri.parse('$baseUrl/api/reconciliation/data'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        print('Successfully fetched data from database');
        print('Total sheets: ${jsonData['total_sheets']}');
        return jsonData;
      } else {
        final errorBody =
            response.body.isNotEmpty ? response.body : 'No error details';
        throw Exception('HTTP ${response.statusCode}: $errorBody');
      }
    } on http.ClientException catch (e) {
      print('Network error fetching reconciliation data: $e');
      throw Exception(
          'Network error: Please check if the API server is running at $baseUrl');
    } catch (e) {
      print('Error fetching reconciliation data: $e');
      throw Exception('Failed to fetch reconciliation data: $e');
    }
  }

  /// Fetch specific sheet data
  static Future<Map<String, dynamic>?> fetchSheetData(String sheetName) async {
    try {
      print('Fetching $sheetName data from database...');

      final response = await http.get(
        Uri.parse('$baseUrl/api/reconciliation/sheet/$sheetName'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        print(
            'Successfully fetched $sheetName data: ${jsonData['row_count']} rows');
        return jsonData;
      } else if (response.statusCode == 404) {
        throw Exception('Sheet $sheetName not found');
      } else {
        final errorBody =
            response.body.isNotEmpty ? response.body : 'No error details';
        throw Exception('HTTP ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      print('Error fetching $sheetName data: $e');
      throw Exception('Failed to fetch $sheetName data: $e');
    }
  }

  /// Check server health
  static Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(healthCheckTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> healthData = json.decode(response.body);
        return healthData['status'] == 'healthy' &&
            healthData['database'] == 'connected';
      }
      return false;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  /// Refresh data
  static Future<Map<String, dynamic>?> refreshData() async {
    try {
      print('Triggering data refresh...');

      final response = await http.post(
        Uri.parse('$baseUrl/api/reconciliation/refresh'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(refreshTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> refreshData = json.decode(response.body);
        print('Data refresh completed successfully');
        return refreshData;
      } else {
        final errorBody =
            response.body.isNotEmpty ? response.body : 'No error details';
        throw Exception('HTTP ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      print('Error refreshing data: $e');
      throw Exception('Failed to refresh data: $e');
    }
  }

  // NEW METHODS FOR FILE UPLOAD AND PROCESSING

  /// Upload file to server
  static Future<Map<String, dynamic>?> uploadFile(
      Uint8List fileBytes, String fileName,
      {Function(double)? onProgress}) async {
    try {
      print('Uploading file: $fileName');

      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/api/upload'));

      // Add file
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));

      // Send request
      var streamedResponse = await request.send().timeout(uploadTimeout);

      // Update progress to 100% when upload completes
      onProgress?.call(1.0);

      // Get response
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> uploadData = json.decode(response.body);
        print('File uploaded successfully: ${uploadData['filename']}');
        return uploadData;
      } else {
        final errorBody =
            response.body.isNotEmpty ? response.body : 'No error details';
        throw Exception(
            'Upload failed - HTTP ${response.statusCode}: $errorBody');
      }
    } on TimeoutException catch (e) {
      print('Upload timeout: $e');
      throw Exception(
          'Upload timeout: File upload took too long. Please try again with a smaller file.');
    } catch (e) {
      print('Error uploading file: $e');
      throw Exception('Upload failed: $e');
    }
  }

  /// Start batch processing
  static Future<Map<String, dynamic>?> startProcessing() async {
    try {
      print('Starting batch processing...');

      final response = await http.post(
        Uri.parse('$baseUrl/api/start-processing'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(processingTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> processingData = json.decode(response.body);
        print('Processing started successfully');
        return processingData;
      } else {
        final errorBody =
            response.body.isNotEmpty ? response.body : 'No error details';
        throw Exception(
            'Failed to start processing - HTTP ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      print('Error starting processing: $e');
      throw Exception('Failed to start processing: $e');
    }
  }

  /// Get processing status
  static Future<Map<String, dynamic>?> getProcessingStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/processing-status'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> statusData = json.decode(response.body);
        return statusData;
      } else {
        final errorBody =
            response.body.isNotEmpty ? response.body : 'No error details';
        throw Exception(
            'Failed to get processing status - HTTP ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      print('Error getting processing status: $e');
      throw Exception('Failed to get processing status: $e');
    }
  }

  /// Export data
  static Future<Map<String, dynamic>?> exportData({
    String format = 'json',
    List<String>? sheets,
  }) async {
    try {
      print('Exporting data in $format format...');

      final requestBody = {
        'format': format,
        if (sheets != null) 'sheets': sheets,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/reconciliation/export'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> exportData = json.decode(response.body);
        print('Data exported successfully');
        return exportData;
      } else {
        final errorBody =
            response.body.isNotEmpty ? response.body : 'No error details';
        throw Exception(
            'Export failed - HTTP ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      print('Error exporting data: $e');
      throw Exception('Failed to export data: $e');
    }
  }

  // UTILITY METHODS

  /// Get database info for display
  static Map<String, dynamic> getDatabaseInfo() {
    return {
      'baseUrl': baseUrl,
      'supportedFileTypes': ['zip', 'xlsx', 'xls'],
      'maxFileSize': '50MB',
      'processingSteps': [
        'Prepare Input Files',
        'PayTM & PhonePe Reconciliation',
        'Load Data to Database'
      ],
    };
  }

  /// Validate API response structure
  static bool validateApiResponse(Map<String, dynamic> response) {
    return response.containsKey('status') &&
        response['status'] == 'success' &&
        response.containsKey('data');
  }

  /// Parse transactions from database response
  // static List<TransactionModel> parseTransactionsFromDatabase(
  //     Map<String, dynamic> apiResponse) {
  //   List<TransactionModel> transactions = [];

  //   try {
  //     if (apiResponse['data'] != null &&
  //         apiResponse['data']['RAWDATA'] != null) {
  //       List<dynamic> rawData = apiResponse['data']['RAWDATA'];

  //       for (var row in rawData) {
  //         try {
  //           // Create simple transaction from database row
  //           TransactionModel transaction = TransactionModel.fromDatabaseRow(
  //             row,
  //             ReconciliationStatus.perfect, // Default status
  //           );
  //           transactions.add(transaction);
  //         } catch (e) {
  //           print('Error parsing transaction row: $e');
  //           // Continue processing other rows
  //         }
  //       }
  //     }
  //   } catch (e) {
  //     print('Error parsing transactions from database: $e');
  //     throw Exception(
  //         'Failed to parse transaction data from database response');
  //   }

  //   return transactions;
  // }

  static List<TransactionModel> parseTransactionsFromDatabase(
      Map<String, dynamic> apiResponse) {
    List<TransactionModel> transactions = [];

    try {
      print('🔍 Parsing transactions from database response...');
      print('📄 API Response structure: ${apiResponse.keys.toList()}');

      // FIXED: Handle the actual Flask API response structure
      List<dynamic> rawData = [];

      // Your Flask API returns data directly in 'data' field, not nested under 'data.RAWDATA'
      if (apiResponse['data'] != null) {
        if (apiResponse['data'] is List) {
          // Direct array format from Flask
          rawData = apiResponse['data'];
          print('✅ Found direct data array with ${rawData.length} rows');
        } else if (apiResponse['data'] is Map &&
            apiResponse['data']['RAWDATA'] != null) {
          // Nested format (fallback)
          rawData = apiResponse['data']['RAWDATA'];
          print('✅ Found nested RAWDATA with ${rawData.length} rows');
        }
      }

      if (rawData.isEmpty) {
        print('⚠️ No transaction data found in response');
        print(
            '📄 Full response: ${apiResponse.toString().substring(0, 500)}...');
        return transactions;
      }

      print('🔄 Processing ${rawData.length} database rows...');

      for (int i = 0; i < rawData.length; i++) {
        try {
          var row = rawData[i];

          // Determine status based on data
          ReconciliationStatus status = ReconciliationStatus.perfect;

          // Check if the row contains reconciliation logic to determine status
          if (row is Map<String, dynamic>) {
            if (row.containsKey('Remarks')) {
              String remarks = row['Remarks']?.toString().toLowerCase() ?? '';
              if (remarks.contains('investigate')) {
                status = ReconciliationStatus.investigate;
              } else if (remarks.contains('manual')) {
                status = ReconciliationStatus.manualRefund;
              }
            }

            // For raw transaction data without reconciliation, determine status based on amounts
            if (row.containsKey('PTPP_Payment') &&
                row.containsKey('Cloud_Payment')) {
              double ptppAmount = _parseAmount(row['PTPP_Payment']) +
                  _parseAmount(row['PTPP_Refund']);
              double cloudAmount = _parseAmount(row['Cloud_Payment']) +
                  _parseAmount(row['Cloud_Refund']) +
                  _parseAmount(row['Cloud_MRefund']);

              if ((ptppAmount - cloudAmount).abs() > 0.01) {
                status = ReconciliationStatus.investigate;
              }
            }
          }

          TransactionModel transaction = TransactionModel.fromDatabaseRow(
            row,
            status,
          );

          transactions.add(transaction);

          // Progress logging for large datasets
          if (i % 1000 == 0 && i > 0) {
            print('📊 Processed ${i}/${rawData.length} rows...');
          }
        } catch (e) {
          print('❌ Error parsing transaction row ${i}: $e');
          print('🔍 Row data: ${rawData[i].toString().substring(0, 200)}...');
          // Continue processing other rows
        }
      }
    } catch (e) {
      print('💥 Error parsing transactions from database: $e');
      print('📄 Response keys: ${apiResponse.keys.toList()}');
      print(
          '📄 Response structure: ${apiResponse.toString().substring(0, 300)}...');

      throw Exception(
          'Failed to parse transaction data from database response: $e');
    }

    print(
        '✅ Successfully parsed ${transactions.length} transactions from database');
    return transactions;
  }

  /// Parse amount safely
  static double _parseAmount(dynamic amount) {
    if (amount == null) return 0.0;
    if (amount is num) return amount.toDouble();
    if (amount is String) {
      try {
        return double.parse(amount.replaceAll(',', ''));
      } catch (e) {
        print('Error parsing amount: $amount');
        return 0.0;
      }
    }
    return 0.0;
  }

  /// Format error message for user display
  static String formatErrorMessage(String error) {
    if (error.contains('Network error')) {
      return 'Unable to connect to the server. Please check:\n'
          '• Server is running at $baseUrl\n'
          '• Network connection is stable\n'
          '• Firewall/antivirus is not blocking the connection';
    } else if (error.contains('timeout')) {
      return 'Operation timed out. This might be due to:\n'
          '• Large file size\n'
          '• Slow network connection\n'
          '• Server overload\n'
          'Please try again with a smaller file or wait a moment.';
    } else if (error.contains('HTTP 4')) {
      return 'Request error. Please check:\n'
          '• File format is correct (.zip, .xlsx, .xls)\n'
          '• File size is under 50MB\n'
          '• All required data is present';
    } else if (error.contains('HTTP 5')) {
      return 'Server error. Please:\n'
          '• Check server logs for details\n'
          '• Ensure database is running\n'
          '• Verify all batch files are accessible\n'
          '• Try again after a few minutes';
    } else {
      return 'Error: $error\n\nIf this problem persists, please contact support.';
    }
  }

  /// Validate file before upload
  static String? validateFile(String fileName, int fileSizeBytes) {
    // Check file extension
    final allowedExtensions = ['zip', 'xlsx', 'xls'];
    final extension = fileName.split('.').last.toLowerCase();

    if (!allowedExtensions.contains(extension)) {
      return 'Invalid file type. Only .zip, .xlsx, and .xls files are allowed.';
    }

    // Check file size (50MB limit)
    const maxSizeBytes = 50 * 1024 * 1024;
    if (fileSizeBytes > maxSizeBytes) {
      final sizeMB = fileSizeBytes / (1024 * 1024);
      return 'File too large (${sizeMB.toStringAsFixed(1)}MB). Maximum size is 50MB.';
    }

    return null; // Valid file
  }

  /// Get upload guidelines
  static List<String> getUploadGuidelines() {
    return [
      'Supported file types: .zip, .xlsx, .xls',
      'Maximum file size: 50MB',
      'Ensure files contain reconciliation data in the expected format',
      'PayTM files should end with "*bill_txn_report.xlsx"',
      'PhonePe files should start with "Merchant_Settlement_Report*.zip"',
      'iCloud payment files should start with "pmt*.zip"',
      'iCloud refund files should start with "ref*.zip"',
      'Upload one file at a time for best results',
      'Wait for upload completion before starting processing',
    ];
  }

  /// Get processing information
  static Map<String, dynamic> getProcessingInfo() {
    return {
      'steps': [
        {
          'name': 'Prepare Input Files',
          'description': 'Extract and prepare uploaded files for processing',
          'estimatedTime': '1-2 minutes',
          'batchFile': '1_Prepare_Input_Files.bat'
        },
        {
          'name': 'PayTM & PhonePe Reconciliation',
          'description': 'Process PayTM, PhonePe, and iCloud data in parallel',
          'estimatedTime': '30-90 minutes (depends on file size)',
          'batchFile': '2_PayTm_PhonePe_Recon.bat'
        },
        {
          'name': 'Load Data to Database',
          'description': 'Load processed data into MySQL database',
          'estimatedTime': '2-3 minutes',
          'batchFile': '3_LoadDB_ReconDailyExtract.bat'
        }
      ],
      'totalEstimatedTime': '35-95 minutes',
      'requirements': [
        'MySQL database must be running',
        'Python environment must be configured',
        'PowerShell execution policy must allow script execution',
        'All batch files must be accessible at specified paths'
      ]
    };
  }
}
