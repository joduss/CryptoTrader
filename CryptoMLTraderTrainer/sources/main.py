from numpy import genfromtxt
import matplotlib.pyplot as plt
import matplotlib.dates as md
import datetime as dt
import time
import numpy as np
import pandas as pd
import pandas_ta as ta
from pandas import DataFrame
import tensorflow as tf
import tensorflow.keras as keras
import tensorflow.keras.layers as kl
from typing import List, Tuple

from ManualInterrupter import ManualInterrupter


def dateparse (time_in_secs):
    return dt.datetime.fromtimestamp(float(time_in_secs))

data = pd.read_csv('./../input/btc_usd_1min.csv',
                                 delimiter=',',
                                 names=["time", "open", "high", "low", "close", "volume", "trades"],
                                 parse_dates=True,
                                 date_parser=dateparse,
                                 index_col='time', )#genfromtxt('./../input/btc_usd_1min.csv', delimiter=',')

# Time, Open, High, Low, Closing, Volume, Trades
print(data)

dates = data.index.to_numpy()
prices = data.to_numpy()[:,1]





data = data.join(data.ta.rsi(length=14))
data = data.join(data.ta.rsi(length=14*60))
data = data.join(data.ta.rsi(length=24*60*14))
# data = data.join(data.ta.macd(slow=26,fast=12))
data["macd-12-days"] = data["close"].rolling(window = 12*60*24).mean()
data["macd-26-days"] = data["close"].rolling(window = 26*60*24).mean()

data["macd-1-days"] = data["close"].rolling(window = 60*24).mean()
data["macd-2-days"] = data["close"].rolling(window = round(26*60*24/12)).mean()

data["macd-12-hours"] = data["close"].rolling(window = 60*12).mean()
data["macd-26-hours"] = data["close"].rolling(window = 60*26).mean()

data["macd-1-hours"] = data["close"].rolling(window = 60).mean()
data["macd-2-hours"] = data["close"].rolling(window = round(60*26/12)).mean()

std_20 = data["close"].rolling(window = 20*60*24).std()
data["mean_bol"] = data["close"].rolling(window = 20*60*24).mean()
data["bol_down"] = data["mean_bol"] - 2 * std_20
data["bol_up"] = data["mean_bol"] + 2 * std_20


# ax = data["close"].plot()

# data["bol_down"].plot(ax=ax)
# data["bol_up"].plot(ax=ax)
# data["mean_bol"].plot(ax=ax)
# ax.legend(["Closing", "bol_down", "bol_up", "mean_bol"])

# data["macd-1-hours"].plot(ax=ax)
# data["macd-2-hours"].plot(ax=ax)
# ax.legend(["Closing", "macd-1", "macd-2"])

#=========================================
# Data processing
#=========================================

data = data.dropna()
data_np: np.ndarray = data.to_numpy()

ml_inputs = np.empty([50000, 534, 20])
ml_inputs_norm = np.empty([50000, 534, 20])
ml_outputs = []
ml_outputs_norm = []
ml_normalization: List[Tuple] = []


idx = 60 * 24 * 30 # start after a month!
win_size = idx

# for the first hour, we keep all
elementCount = 0

while idx < len(data):
    currentWindowData: np.ndarray = data_np[np.arange(idx - win_size, idx - win_size + 60)]

    # From 1h to 1 day, take on every 10 min.
    w = data_np[np.arange(idx - win_size + 60, idx - win_size + 60*24, 10)]
    currentWindowData = np.append(currentWindowData, w, axis=0)

    # Then for a month, we keep every h
    w = data_np[np.arange(idx - win_size + 60*24, idx - win_size + 60*24*29, 120)]
    currentWindowData = np.append(currentWindowData, w, axis=0)

    # Normalization
    minData = currentWindowData.min(initial=100000000)
    maxData = currentWindowData.max(initial=-10000000)
    currentWindowData = currentWindowData

    ml_inputs[elementCount] = currentWindowData
    ml_inputs_norm[elementCount] = (currentWindowData - minData) / maxData

    max2H = data.iloc[np.arange(idx - win_size, idx - win_size + 120)]['close'].max()
    ml_outputs.append(max2H)
    ml_outputs_norm.append((max2H - minData) / maxData)
    ml_normalization.append((minData, maxData))

    idx += 60
    elementCount += 1


ml_inputs_norm = ml_inputs_norm[:elementCount]
ml_inputs = ml_inputs[:elementCount]

#=========================================
# Dataset preparation
#=========================================

record_count = len(ml_inputs_norm)
train_size = round(record_count * 0.7)
test_size = record_count - train_size

ml_inputs_train_norm = ml_inputs_norm[:train_size]
ml_inputs_test_norm = ml_inputs_norm[train_size:]

ml_inputs_train = ml_inputs[:train_size]
ml_inputs_test = ml_inputs[train_size:]

ml_outputs_norm_train = ml_outputs_norm[:train_size]
ml_outputs_norm_test = ml_outputs_norm[train_size:]

ml_outputs_train = ml_outputs[:train_size]
ml_outputs_test = ml_outputs[train_size:]

ml_normalization_train = ml_normalization[:train_size]
ml_normalization_test = ml_normalization[train_size:]

#=========================================
# ML
#=========================================


model_input = kl.Input(shape=(534,20,))
model_layer_1 = kl.Conv1D(filters=64, kernel_size=10)(model_input)
model_layer_2 = kl.GlobalMaxPooling1D()(model_layer_1)
model_layer_3 = kl.Dense(16)(model_layer_2)
model_output = kl.Dense(1, activation=keras.activations.linear)(model_layer_3)

model: keras.Model = keras.Model(inputs=model_input, outputs=model_output)
model.summary()

model.compile(loss=keras.losses.MeanSquaredError(), optimizer=keras.optimizers.Adam(learning_rate=0.00001), metrics=[keras.metrics.MeanSquaredError()])

# Normalized
#train_dataset = tf.data.Dataset.from_tensor_slices((ml_inputs_train_norm, ml_outputs_norm_train)).shuffle(buffer_size=50).batch(10)

# Not normalized
train_dataset = tf.data.Dataset.from_tensor_slices((ml_inputs_train, ml_outputs_train)).shuffle(buffer_size=50).batch(10)


history = model.fit(train_dataset, epochs=50, callbacks=[ManualInterrupter()])

#=========================================
# Predictions
#=========================================

predictions = np.empty([len(ml_outputs_norm)])

# normalized
# idx = 0
# for input_line in ml_inputs_norm:
#     normalization_param = ml_normalization[idx]
#     min = normalization_param[0]
#     max = normalization_param[1]
#
#     predictions[idx] = model.predict(np.array([input_line]))[0][0] * max + min
#     idx += 1

#not normalized
# idx = 0
# for input_line in ml_inputs:
#     pred = model.predict(np.array([input_line]))[0][0]
#     real = ml_outputs[idx]
#     predictions[idx] = model.predict(np.array([input_line]))[0][0]
#     idx += 1



all_dataset = tf.data.Dataset.from_tensor_slices((ml_inputs)).batch(10)
all_predictions = model.predict(all_dataset)

#Plotting
x = list(range(len(all_predictions)))
plt.plot(x, all_predictions, 'r')
plt.plot(x, ml_outputs, 'b')

plt.show(block = True)

