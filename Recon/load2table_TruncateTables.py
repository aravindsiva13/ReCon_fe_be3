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

# # Main function to load CSV and insert into MySQL
# def main():
#     # Create a MySQL connection
#     connection = create_connection()
    
#     if connection:
#         delcursor = connection.cursor()
#         # Delete Existing Data
#         delcursor.execute("DELETE FROM payment_refund")
#         connection.commit()
#         print("payment_refund table truncated successfully")
#         delcursor.execute("DELETE FROM paytm_phonepe")
#         connection.commit()
#         print("paytm_phonepe table truncated successfully")
#         delcursor.execute("DELETE FROM Recon_Outcome")
#         connection.commit()
#         print("Recon_Outcome table truncated successfully")
#         connection.close()  # Close the connection when done

# if __name__ == "__main__":
#     main()



import mysql.connector
from mysql.connector import Error
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

def truncate_tables(connection):
    """Truncate all reconciliation tables"""
    try:
        cursor = connection.cursor()

        # List of tables to truncate
        tables_to_truncate = [
            'payment_refund',
            'paytm_phonepe', 
            'Recon_Outcome'
        ]

        for table in tables_to_truncate:
            try:
                cursor.execute(f"DELETE FROM {table}")
                connection.commit()
                print(f"✅ {table} table truncated successfully")
            except Error as e:
                print(f"❌ Error truncating {table}: {e}")
                connection.rollback()

        cursor.close()

    except Error as e:
        print(f"❌ Error in truncate operation: {e}")

def main():
    """Main function to truncate database tables"""
    print("🗑️ Starting database table truncation...")
    
    # Create a MySQL connection
    connection = create_connection()

    if connection:
        try:
            truncate_tables(connection)
            print("✅ All table truncation operations completed!")
        finally:
            connection.close()  # Close the connection when done
            print("🔌 Database connection closed.")
    else:
        print("❌ Failed to connect to database")

if __name__ == "__main__":
    main()
