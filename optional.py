#!/usr/bin/env python
# coding: utf-8

# In[63]:


import pandas as pd
import numpy as np
from datetime import datetime as dt

opath = "/Users/macbookair/Desktop/task/"


# In[64]:


# Read the file
df = pd.read_csv(opath+"rates_sample.csv")


# In[65]:


# Function to convert milliseconds to datetime

def milliseconds_to_datetime(milliseconds):
    
    # Convert milliseconds to seconds
    seconds = milliseconds / 1000.0
    
    # Convert seconds to datetime
    return dt.fromtimestamp(seconds)

# Apply the function to the "event_time" column
df["event_time"] = df["event_time"].apply(milliseconds_to_datetime)
df.set_index("event_time", inplace=True, drop=True)


# In[66]:


yesterday_rates = { "EURUSD": 1.0500,
                    "NZDUSD": 0.6660,
                    "AUDUSD": 0.6950,
                    "EURGBP": 0.8260,
                    "GBPUSD": 1.3000 }

# Fetch yesterday's rates for each currency couple
df["y_rate"] = df["ccy_couple"].map(yesterday_rates)


# In[71]:


# Calculate the percentage rate of each currency couple
df["change"] = ((df["rate"] - df["y_rate"]) / df["y_rate"]) * 100
df["change"] = df["change"].where(df["rate"] != 0, other=None)  # Set change to None where rate is 0


# In[70]:


# Iterate over each currency pair to display the latest change

for couple in df["ccy_couple"].unique():
    
    # Filter by currency pair and sort by event time in descending order
    couple_df = df[df["ccy_couple"] == couple].sort_values(by="event_time", ascending=False)
    
    # Drop rows with None values and consider only rows with valid changes
    couple_df = couple_df.dropna(subset=["change"])
    
    # Check if there are valid changes available
    if not couple_df.empty:
        # Get the latest change and rate
        latest_change = couple_df.iloc[0]["change"]
        latest_rate = couple_df.iloc[0]["rate"]
        
        # Format the output string
        output_str = f"{couple[:3]}/{couple[3:]}, " + f"{latest_rate:.5f}, " + f"{latest_change:.3f}%"
        
        # Print the output
        print(output_str)


# In[ ]:




