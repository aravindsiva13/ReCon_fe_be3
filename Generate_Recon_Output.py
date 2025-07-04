# import mysql.connector
# import pandas as pd

# # MySQL connection details
# #host='localhost',  # e.g., localhost or an IP address
# #user='root',  # e.g., root
# #password='Riota@123',  # your MySQL password
# #database='reconciliation'  # the database you're using

# # Queries to extract data
# queries = {
#     'SUMMARY': '(SELECT txn_source, Txn_type, sum(Txn_Amount) FROM reconciliation.payment_refund pr GROUP BY 1, 2) UNION (SELECT Txn_Source, Txn_type, sum(Txn_Amount) FROM reconciliation.paytm_phonepe pp GROUP BY 1, 2);',
#     'RAWDATA': '(SELECT * FROM reconciliation.paytm_phonepe pp) UNION ALL (SELECT * FROM reconciliation.payment_refund pr);', 
#     'RECON_SUCCESS': 'SELECT *, IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),"Perfect", "Investigate") AS Remarks FROM reconciliation.recon_outcome ro1 WHERE ((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund)) AND ro1.Txn_RefNo NOT IN (SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 WHERE ro2.txn_mid like \'%manual%\') ORDER BY 1;',
#     'RECON_INVESTIGATE': 'SELECT *, IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),"Perfect", "Investigate") AS Remarks FROM reconciliation.recon_outcome ro1 WHERE ((ro1.PTPP_Payment + ro1.PTPP_Refund) != (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund)) AND ro1.Txn_RefNo NOT IN (SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 WHERE ro2.txn_mid like \'%manual%\') ORDER BY 1;',
#    'MANUAL_REFUND': 'SELECT *, IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),"Perfect", "Investigate") AS Remarks FROM reconciliation.recon_outcome ro1 WHERE ro1.Txn_RefNo IN (SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 WHERE ro2.txn_mid like \'%manual%\') ORDER BY 1;'
# }

# # Connect to MySQL
# conn = mysql.connector.connect(
# host='localhost',  # e.g., localhost or an IP address
# user='root',  # e.g., root
# password='Templerun@2',  # your MySQL password
# database='reconciliation'  # the database you're using
# )

# # Create a Pandas ExcelWriter to write multiple sheets
# output_file = 'recon_output.xlsx'
# with pd.ExcelWriter(output_file, engine='openpyxl') as writer:
#     for sheet_name, query in queries.items():
#         # Execute the query
#         df = pd.read_sql(query, conn)
        
#         # Write the dataframe to an Excel sheet
#         df.to_excel(writer, sheet_name=sheet_name, index=False)

# # Close the MySQL connection
# conn.close()

# print(f"Data has been successfully written to {output_file}.")	


import mysql.connector
import pandas as pd
import os
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

def get_db_config():
    """Get database configuration from .env file"""
    return {
        'host': os.getenv('DB_HOST'),
        'user': os.getenv('DB_USER'),
        'password': os.getenv('DB_PASSWORD'),
        'database': os.getenv('DB_DATABASE'),
        'port': int(os.getenv('DB_PORT', 3306))
    }

def main():
    # Queries to extract data
    queries = {
        'SUMMARY': '''(SELECT txn_source, Txn_type, sum(Txn_Amount) FROM reconciliation.payment_refund pr GROUP BY 1, 2) 
                     UNION 
                     (SELECT Txn_Source, Txn_type, sum(Txn_Amount) FROM reconciliation.paytm_phonepe pp GROUP BY 1, 2)''',
        
        'RAWDATA': '''(SELECT * FROM reconciliation.paytm_phonepe pp) 
                     UNION ALL 
                     (SELECT * FROM reconciliation.payment_refund pr)''',
        
        'RECON_SUCCESS': '''SELECT *, 
                           IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),
                              "Perfect", "Investigate") AS Remarks 
                           FROM reconciliation.recon_outcome ro1 
                           WHERE ((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund)) 
                           AND ro1.Txn_RefNo NOT IN (SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 WHERE ro2.txn_mid like '%manual%') 
                           ORDER BY 1''',
        
        'RECON_INVESTIGATE': '''SELECT *, 
                              IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),
                                 "Perfect", "Investigate") AS Remarks 
                              FROM reconciliation.recon_outcome ro1 
                              WHERE ((ro1.PTPP_Payment + ro1.PTPP_Refund) != (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund)) 
                              AND ro1.Txn_RefNo NOT IN (SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 WHERE ro2.txn_mid like '%manual%') 
                              ORDER BY 1''',
        
        'MANUAL_REFUND': '''SELECT *, 
                           IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),
                              "Perfect", "Investigate") AS Remarks 
                           FROM reconciliation.recon_outcome ro1 
                           WHERE ro1.Txn_RefNo IN (SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 WHERE ro2.txn_mid like '%manual%') 
                           ORDER BY 1'''
    }

    try:
        # Connect to MySQL using .env config
        print("Connecting to MySQL...")
        conn = mysql.connector.connect(**get_db_config())
        print("Connection successful!")

        # Auto-detect output path
        BASE_DIR = Path(__file__).parent.resolve()
        OUTPUT_FOLDER = BASE_DIR / 'Output_Files'
        OUTPUT_FOLDER.mkdir(exist_ok=True)
        output_file = OUTPUT_FOLDER / 'recon_output.xlsx'

        # Create a Pandas ExcelWriter to write multiple sheets
        with pd.ExcelWriter(output_file, engine='openpyxl') as writer:
            for sheet_name, query in queries.items():
                print(f"Processing {sheet_name}...")
                # Execute the query
                df = pd.read_sql(query, conn)
                
                # Write the dataframe to an Excel sheet
                df.to_excel(writer, sheet_name=sheet_name, index=False)
                print(f"✅ {sheet_name}: {len(df)} rows written")

        # Close the MySQL connection
        conn.close()
        print(f"✅ Data has been successfully written to {output_file}")

    except mysql.connector.Error as e:
        print(f"❌ Database error: {e}")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()