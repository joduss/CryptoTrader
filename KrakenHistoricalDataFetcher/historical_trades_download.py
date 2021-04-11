from typing import Dict, IO, List
import json
import urllib.request
import datetime as dt
import time


# Variables
# ================

pair = "ICXUSD"
start_idx = "1609347200000000000"

file_path: str = "trades_ICX-usd.csv"


# Constants
# ================

trades_url = " https://api.kraken.com/0/public/Trades"
api_excess_waiting_time = 60


# Utility functions
# ================

def buildUrl(pair: str, idx:int) -> str:
    return trades_url + "?pair=" + pair + "&since=" + str(idx)


def toCSV(record: List) -> str:
    """
    Transforms a record to a csv line
    "price, volume, time"
    :param record:
    :return:
    """
    return ",".join([str(value) for value in record[:3]])  + "\n"

# Process the response and append data to a file
def append_to_file(ohlc_record: List, file: IO):
    line = toCSV(ohlc_record)
    file.write(line)


def process_response(response: str) -> int:

    jsonResponse = json.loads(response)
    try:
        results: Dict = jsonResponse["result"]

        # results is a dictionary where the key is the pair and the value is an array of array of our expected data
        data: List[List] = list(results.values())[0]

        data_until_date = dt.datetime.utcfromtimestamp(data[len(data) - 1][2])
        print(f"Got data up to {data_until_date.strftime('%Y-%m-%d %H:%M:%S')}")

        with open(file_path, mode='a') as file:

            for ohlc_record in data:
                append_to_file(ohlc_record, file)

        return results["last"]

    except:
        if (jsonResponse["error"][0] == "EAPI:Rate limit exceeded"):
            print(f"API RATE EXCEEDED => Waiting {api_excess_waiting_time} seconds")
            time.sleep(api_excess_waiting_time)
        else:
            print(response)
            time.sleep(60)

        return -1







#
# Data downloading
# ================

idx = start_idx
throtle = 1.4

while idx != None:
    url = buildUrl(pair, idx)
    with urllib.request.urlopen(url) as response:
        response_data = response.read()

        new_idx = process_response(response_data)

        if new_idx == -1:
            print(f"Kraken throttled our calls.")
        else:
            idx = new_idx

        time.sleep(throtle)
