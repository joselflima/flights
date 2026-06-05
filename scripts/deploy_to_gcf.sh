#! /bin/zsh

gcloud functions deploy olist-ingestion \
  --gen2 \
  --runtime=python312 \
  --region=us-east4 \
  --source=../ingestion \
  --entry-point=main \
  --trigger-http \
  --allow-unauthenticated \
  --memory=512MB \
  --timeout=540s \
  --set-secrets="KAGGLE_API_TOKEN=projects/ev-elt/secrets/KAGGLE_API_TOKEN/versions/latest"
