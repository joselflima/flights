import logging

import functions_framework
from extractors.kaggle_extractor import KaggleExtractor
from loaders.gcs_loader import GCSLoader

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

DATASET = "shubhambathwal/flight-price-prediction"
DESTINATION = "flight-pipeline-raw-data/bronze"

FLIGHTS = [
    "business.csv",
    "economy.csv",
]


@functions_framework.http
def main(request):
    extractor = KaggleExtractor()
    loader = GCSLoader()

    try:
        for file_name in FLIGHTS:
            logger.info("Extraindo %s", file_name)
            df = extractor.extract(DATASET, file_name)

            logger.info("Enviando %s para o storage %s", file_name, DESTINATION)
            loader.load(df, DESTINATION, file_name)

        return {"status": "success", "files_uploaded": len(FLIGHTS)}, 200

    except Exception as e:
        logger.error("Erro ao executar função principal: %s", e, exc_info=True)
        return {"status": "error", "message": str(e)}, 500
