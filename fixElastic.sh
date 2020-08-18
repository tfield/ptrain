#!/bin/sh

site="pokemon-react-training-2"

echo "Crafter Elastic Index cleanup tool"
echo "Fixing and rebuilding authoring and preview indices for site: ${site}"

echo "\nEnabling writes to index to be able to set configuration..."
curl -X PUT http://localhost:9201/${site}-authoring/_settings -H 'Content-Type: application/json' -d ' {"index": {"blocks": {"read_only_allow_delete": "false"}}}'
curl -X PUT http://localhost:9201/${site}-preview/_settings -H 'Content-Type: application/json' -d ' {"index": {"blocks": {"read_only_allow_delete": "false"}}}'

echo "\nSetting high water marks..."
curl -X PUT http://localhost:9201/_cluster/settings -H 'Content-Type: application/json' -d ' {
  "transient": {
    "cluster.routing.allocation.disk.watermark.low": "11gb",
    "cluster.routing.allocation.disk.watermark.high": "10gb",
    "cluster.routing.allocation.disk.watermark.flood_stage": "3gb",
    "cluster.info.update.interval": "1m"
  }
}'

echo "\nRe-enabling writes to index just in case..."
curl -X PUT http://localhost:9201/${site}-authoring/_settings -H 'Content-Type: application/json' -d ' {"index": {"blocks": {"read_only_allow_delete": "false"}}}'
curl -X PUT http://localhost:9201/${site}-preview/_settings -H 'Content-Type: application/json' -d ' {"index": {"blocks": {"read_only_allow_delete": "false"}}}'

echo "\nPausing 2 seconds..."
sleep 2



echo "Emptying Indices..."
curl http://localhost:9201/${site}-authoring/_doc/_delete_by_query -H 'Content-Type: application/json' -d '{ "query": { "match_all": {} } }'
curl http://localhost:9201/${site}-preview/_doc/_delete_by_query -H 'Content-Type: application/json' -d '{ "query": { "match_all": {} } }'

echo "\nPausing 5 seconds..."
sleep 5

echo "Reindexing..."
curl http://localhost:9191/api/1/target/deploy/preview/${site} -X POST -H 'Content-Type: application/json' -d '{ "reprocess_all_files": true }'
curl http://localhost:9191/api/1/target/deploy/authoring/${site} -X POST -H 'Content-Type: application/json' -d '{ "reprocess_all_files": true }'

echo "\n...Done. Please wait while reindexing is done"
