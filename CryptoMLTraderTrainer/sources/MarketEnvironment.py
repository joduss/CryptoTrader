from __future__ import absolute_import, division, print_function

import base64
from enum import Enum
from typing import Any, Dict

import imageio
import IPython
import matplotlib
import matplotlib.pyplot as plt
import numpy as np
import PIL.Image
import pyvirtualdisplay

import tensorflow as tf

from tf_agents.agents.dqn import dqn_agent
from tf_agents.drivers import dynamic_step_driver
from tf_agents.environments import suite_gym
from tf_agents.environments import tf_py_environment
from tf_agents.environments.py_environment import PyEnvironment
from tf_agents.eval import metric_utils
from tf_agents.metrics import tf_metrics
from tf_agents.networks import sequential
from tf_agents.policies import random_tf_policy
from tf_agents.replay_buffers import tf_uniform_replay_buffer
from tf_agents.trajectories import time_step as ts, trajectory
from tf_agents.specs import array_spec, tensor_spec
from tf_agents.trajectories.time_step import TimeStep
from tf_agents.typing import types
from tf_agents.utils import common
import pandas as pd
import pandas_ta as pdt

from utilities.DateUtility import dateparse


class MarketEnvironment(PyEnvironment):

    history_size: int = 225
    data_file_path: str
    wallet_state_size: int = 4

    def __init__(self, data: pd.DataFrame):
        super().__init__()
        self._action_spec = array_spec.BoundedArraySpec(
            shape=(), dtype=np.int32, minimum=0, maximum=2, name='action')
        self._observation_spec = {
            "market" : array_spec.BoundedArraySpec(shape=(self.history_size,), dtype=np.double, minimum=0, name='observation'),
            "wallet" : array_spec.BoundedArraySpec(shape=(self.wallet_state_size,), dtype=np.double, minimum=0, name='observation')
        }
        self.state_gen = MarketEnvironmentStateGenerator(data, self.history_size)
        self.state_gen.history_size = self.history_size

        self.setInitialState()


    def setInitialState(self):
        self.state_gen.reset()
        self._state = self.state_gen.next()
        self._episode_ended = False

    def observation_spec(self) -> types.NestedArraySpec:
        return self._observation_spec


    def action_spec(self) -> types.NestedArraySpec:
        return self._action_spec


    def get_info(self) -> Any:
        pass


    def _step(self, action: types.NestedArray) -> ts.TimeStep:
        if self._episode_ended:
            # The last action ended the episode. Ignore the current action and start
            # a new episode.
            return self.reset()

        new_state = self.state_gen.next()

        if self.state_gen.hasNext() == False:
            self._episode_ended = True

        reward = self.state_gen.action(Action(action.item()))

        if reward == None:
            return ts.termination(new_state, 0)


        # if self._balance < 10:
        #     return ts.termination(new_state, 0)
        # else:
            #print("transition")
        return ts.transition(new_state, reward=reward, discount=self.state_gen.discount())


    def _reset(self) -> ts.TimeStep:
        self.setInitialState()
        return ts.restart(self._state)


class Action(Enum):
    BUY = 0
    HOLD = 1
    SELL = 2


# FOR NOW, order = 100%
class MarketEnvironmentStateGenerator:

    _history_size: int = 225
    _idx: int = 0
    _max_idx: int = 0

    _fee = 0.1 / 100

    balance: int = 152
    coin_qty: int = 0
    max_order_count = 1
    order_count = 0
    order_size = balance / max_order_count

    order_price: float = 0

    def __init__(self, data: pd.DataFrame, history_size: int):
        self._history_size = history_size
        self.data: pd.DataFrame = data
        self.data = self.data.dropna()
        self._max_idx = self.data.shape[0]
        self._idx = self._history_size - 1

    def discount(self) -> float:
        if self.coin_qty == 0:
            return 0

        sell_cost = self.coin_qty * self._current_price() * (1 - self._fee)
        profits = sell_cost - self.order_size

        return profits

    def next(self) -> Dict[str, np.ndarray]:
        self._idx += 10
        state_data: pd.DataFrame = self.data["close"].iloc[self._idx - self._history_size : self._idx]
        return {
            "market" : state_data.to_numpy(),
            "wallet" : np.array([self.balance, self.order_count, self.max_order_count, self.order_size], dtype=float)
        }

    def hasNext(self) -> bool:
        return self._idx < self._max_idx

    def _current_price(self):
        return self.data["close"].iloc[self._idx]

    def action(self, action: Action) -> float:
        if action == Action.BUY:
            return self.buy()

        if action == Action.SELL:
            return self.sell()

        if action == Action.HOLD:
            return 0


    def can_buy(self) -> float:
        return self.balance >= self.order_size and self.order_count < self.max_order_count

    def can_sell(self) -> bool:
        return self.order_count > 0


    def buy(self) -> float:
        if not self.can_buy():
            return None

        self.coin_qty = (self.order_size / self._current_price()) * (1 - self._fee)
        self.order_count = 1
        self.balance -= self.order_size

        self.order_price = self._current_price()
        return 0

    def sell(self) -> float:
        if not self.can_sell():
            return None

        sell_cost = self.coin_qty * self._current_price() * (1 - self._fee)
        profits = sell_cost - self.order_size

        self.order_price = 0

        self.balance += sell_cost
        self.order_count = 0
        self.order_size = self.balance / (self.max_order_count - self.order_count)
        self.coin_qty = 0

        return profits


    def reset(self):
        self._idx = self._history_size - 1
        self.balance: int = 152
        self.coin_qty: int = 0
        self.max_order_count = 1
        self.order_count = 0
        self.order_size = self.balance / self.max_order_count

        self.order_price: float = 0
