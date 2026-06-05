#! /bin/zsh

gcloud secrets add-iam-policy-binding KAGGLE_API_TOKEN \
  --member="serviceAccount:246692151112-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" \
  --project=ev-elt
