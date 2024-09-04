import pandas as pd
from snowflake.sqlalchemy import URL
from sqlalchemy import create_engine
from googletrans import Translator

# Set up Snowflake connection
engine = create_engine(URL(
    account='xxxxxxxxxxx',
    user='rxhulshxrmx',
    password='xxxxxxxxxxxxxxxxx',
    database='xxxxxx',
    schema='public',
    warehouse='xxxxxx_wh'
))

# Fetch data from Snowflake
with engine.connect() as conn:
    query = "SELECT POSTING_ID, TITLE FROM OTODOM_DATA_DUMP ORDER BY POSTING_ID"
    df = pd.read_sql(query, conn)

# Print column names to verify
print("Column names:", df.columns)

# Print first few rows to verify data
print("First few rows of the DataFrame:")
print(df.head())

# Translate titles
translator = Translator()
df['title_en'] = df['title'].apply(lambda x: translator.translate(x, src='pl', dest='en').text)

# Print first few rows of the translated DataFrame
print("First few rows of the translated DataFrame:")
print(df.head())

# Store translated titles back to Snowflake
with engine.connect() as conn:
    df.to_sql('otodom_data_translated', con=conn, if_exists='replace', index=False)

engine.dispose()
