import kagglehub
import pandas as pd
from kagglehub import KaggleDatasetAdapter

from extractors.base import DataExtractor

_KAGGLE_TOKEN_ENV = "KAGGLE_TOKEN"


class KaggleExtractor(DataExtractor):
    def extract(self, source: str, file_name: str) -> pd.DataFrame:
        return kagglehub.dataset_load(KaggleDatasetAdapter.PANDAS, source, file_name)
