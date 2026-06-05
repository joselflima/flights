from abc import ABC, abstractmethod

import pandas as pd


class DataExtractor(ABC):
    @abstractmethod
    def extract(self, source: str, file_name: str) -> pd.DataFrame:
        raise NotImplementedError
