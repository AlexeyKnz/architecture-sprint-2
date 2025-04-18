#!/bin/bash

mongo_test_shard_doc_count() {
  local shard_name="$1"
  local shard_port="$2"
  print_separator "Проверка шарда с именем "$shard_name" и портом "$shard_port""
  docker compose exec -T "$shard_name" mongosh --port "$shard_port" --quiet <<EOF
    use somedb;
    db.helloDoc.countDocuments();
EOF
    echo Проверка шарда окончена
}