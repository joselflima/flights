from abc import ABC, abstractmethod

import pandas as pd


class DataLoader(ABC):
    @abstractmethod
    def load(self, df: pd.DataFrame, destination: str, file_name: str) -> None:
        raise NotImplementedError
