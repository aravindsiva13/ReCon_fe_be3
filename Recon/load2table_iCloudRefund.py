# import pandas as pd
# import mysql.connector
# from mysql.connector import Error

# # Establish a MySQL connection
# def create_connection():
#     try:
#         connection = mysql.connector.connect(
#             host='localhost',  # e.g., localhost or an IP address
#             user='root',  # e.g., root
#             password='Templerun@2',  # your MySQL password
#             database='reconciliation'  # the database you're using
#         )
#         if connection.is_connected():
#             print("Connection to MySQL is successful!")
#             return connection
#     except Error as e:
#         print(f"Error: {e}")
#         return None

# # Insert data into MySQL table
# def insert_data_from_csv(csv_file_path, connection):
#     try:
#         # Load the CSV data into a pandas DataFrame
#         df = pd.read_csv(csv_file_path)
#         #print (df)

#         # Convert empty values to None (NULL in MySQL)
#         # This will replace empty strings, NaN values, or any other placeholder you want to treat as NULL
#         df = df.where(pd.notnull(df), None)  # Replaces NaN with None
#         df = df.replace(r'^\s*$', None, regex=True)  # Replaces empty strings (or spaces) with None
#         #print (df)

#         # Create a cursor object
#         cursor = connection.cursor()

#         # Assuming the MySQL table has the same structure as the CSV file
#         for i, row in df.iterrows():
#             # Creating the SQL INSERT query dynamically
#             sql = f"INSERT INTO payment_refund ({', '.join(df.columns)}) VALUES ({', '.join(['%s'] * len(row))})"
#             ###print (sql)
#             cursor.execute(sql, tuple(row))
           

#         # Commit the transaction
#         connection.commit()
#         print(f"{cursor.rowcount} rows inserted successfully.")
        
#     except Error as e:
#         print(f"Error: {e}")
#         connection.rollback()  # Rollback in case of error

# # Main function to load CSV and insert into MySQL
# def main():
#     # Path to your CSV file
#     csv_file2 = r'C:\Users\IT\Downloads\recon_updated (1)\Recon\Output_Files\iCloud_Refund.csv'

#     # Create a MySQL connection
#     connection = create_connection()
    
#     if connection:
#         delcursor = connection.cursor()
#         insert_data_from_csv(csv_file2, connection)
#         connection.commit()
#         connection.close()  # Close the connection when done

# if __name__ == "__main__":
#     main()



import pandas as pd
import mysql.connector
from mysql.connector import Error
from pathlib import Path
import os
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

def create_connection():
    """Establish a MySQL connection using .env config"""
    try:
        connection = mysql.connector.connect(**get_db_config())
        if connection.is_connected():
            print("Connection to MySQL is successful!")
            return connection
    except Error as e:
        print(f"Error: {e}")
        return None

def insert_data_from_csv(csv_file_path, connection):
    """Insert data from CSV to MySQL table"""
    try:
        # Load the CSV data into a pandas DataFrame
        df = pd.read_csv(csv_file_path)

        # Convert empty values to None (NULL in MySQL)
        df = df.where(pd.notnull(df), None)  # Replaces NaN with None
        df = df.replace(r'^\s*$', None, regex=True)  # Replaces empty strings with None

        # Create a cursor object
        cursor = connection.cursor()

        # Insert data row by row
        for i, row in df.iterrows():
            # Creating the SQL INSERT query dynamically
            sql = f"INSERT INTO payment_refund ({', '.join(df.columns)}) VALUES ({', '.join(['%s'] * len(row))})"
            cursor.execute(sql, tuple(row))

        # Commit the transaction
        connection.commit()
        print(f"{cursor.rowcount} rows inserted successfully.")

    except Error as e:
        print(f"Error: {e}")
        connection.rollback()  # Rollback in case of error

def main():
    """Main function to load CSV and insert into MySQL"""
    # Auto-detect CSV path - no hardcoding!
    BASE_DIR = Path(__file__).parent.resolve()
    OUTPUT_FOLDER = BASE_DIR / 'Output_Files'
    csv_file2 = OUTPUT_FOLDER / 'iCloud_Refund.csv'

    # Check if file exists
    if not csv_file2.exists():
        print(f"❌ CSV file not found: {csv_file2}")
        return

    # Create a MySQL connection
    connection = create_connection()

    if connection:
        try:
            insert_data_from_csv(csv_file2, connection)
            connection.commit()
            print("✅ Refund data insertion completed successfully!")
        finally:
            connection.close()  # Close the connection when done
    else:
        print("❌ Failed to connect to database")

if __name__ == "__main__":
    main()