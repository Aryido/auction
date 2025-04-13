import requests
import json
import pandas as pd
from datetime import datetime
import os

def get_roc_year():
    """
    Get the current year in ROC (Republic of China) format.
    Returns:
        int: The current ROC year.
    """
    current_year = datetime.now().year
    return current_year - 1911

def fetch_auction_data(url='https://www.twse.com.tw/zh/announcement/auction', output_file='now_year_auction.json'):
    """
    Fetch auction data from the TWSE API and save it as a JSON file.
    
    Args:
        url (str): API URL.
        output_file (str): Filename to save the JSON response.
    """
    response = requests.get(url, verify=False) # skip verify
    if response.status_code == 200:
        with open(output_file, 'wb') as file:
            file.write(response.content)
        print(f"✅ Data successfully fetched and saved as {output_file}")
    else:
        print(f"❌ Failed to fetch data, status code: {response.status_code}")

def convert_json_to_csv(json_file='now_year_auction.json', output_directory='./years'):
    """
    Convert JSON data to CSV format and save it in a directory named after the current ROC year.
    
    Args:
        json_file (str): Path to the JSON file.
        output_directory (str): Directory where the CSV file will be saved.
    """
    with open(json_file, "r", encoding="utf-8") as file:
        data = json.load(file)
    
    df = pd.DataFrame(data["data"], columns=data["fields"])
    roc_year = get_roc_year()
    os.makedirs(output_directory, exist_ok=True)  # Ensure the directory exists
    csv_filename = os.path.join(output_directory, f"{roc_year}.csv")
    df.to_csv(csv_filename, index=False, encoding="utf-8", quoting=1)
    print(f"✅ CSV file saved as {csv_filename}")

def merge_csv_files(directory='./years', output_filename='./years/final/merged.csv'):
    """
    Merge all CSV files in the specified directory into a single CSV file.
    
    Args:
        directory (str): Directory containing CSV files.
        output_filename (str): Name of the merged output CSV file.
    
    Returns:
        pd.DataFrame or None: The merged DataFrame if files exist, else None.
    """
    if not os.path.exists(directory):
        print(f"❌ Directory {directory} does not exist!")
        return None
    
    all_files = [f for f in os.listdir(directory) if f.endswith(".csv")]
    if not all_files:
        print("❌ No CSV files found in the directory!")
        return None
    
    all_dfs = []
    for file in all_files:
        file_path = os.path.join(directory, file)
        df = pd.read_csv(file_path, encoding="utf-8").dropna(axis=1, how='all')
        df["source_file"] = file  # Add a column indicating the source file
        all_dfs.append(df)
    
    merged_df = pd.concat(all_dfs, ignore_index=True)
    
    if "序號" in merged_df.columns:
        merged_df = merged_df.drop(columns=["序號"])
        
    if "開標日期" in merged_df.columns:
        merged_df["開標日期"] = pd.to_datetime(merged_df["開標日期"], format="%Y/%m/%d", errors="coerce")
        merged_df = merged_df.sort_values(by="開標日期", ascending=False)
    
    merged_df.to_csv(output_filename, index=False, encoding="utf-8", quoting=1)
    print(f"✅ Merged CSV file saved as {output_filename}")
    return merged_df

# Execute the functions
fetch_auction_data()
convert_json_to_csv()
merged_df = merge_csv_files()
