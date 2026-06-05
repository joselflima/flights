import pandas as pd

from loaders.base import DataLoader


class GCSLoader(DataLoader):
    def load(self, df: pd.DataFrame, destination: str, file_name: str) -> None:
        path = f"gs://{destination}/{file_name}"
        df.to_csv(path, index=False)
