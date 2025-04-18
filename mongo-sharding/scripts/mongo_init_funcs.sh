#!/bin/bash

print_separator() {
  echo
  echo "--------------------------------------------------"
  echo "$1"
  echo "--------------------------------------------------"
  echo
}

init_mongo_serv()
{
print_separator "ИНИЦИАЛИЗАЦИЯ CONFIG SERVER"

docker compose exec -T configSrv mongosh --port 27017 --quiet << EOF
  rs.initiate(
    {
      _id : "config_server",
        configsvr: true,
      members: [
        { _id : 0, host : "configSrv:27017" }
      ]
    }
  );
  exit();
EOF

echo "Config Server инициализирован"
}

init_shards()
{

print_separator "ИНИЦИАЛИЗАЦИЯ ШАРДОВ"

print_separator "Инициализация shard1"
docker compose exec -T shard1 mongosh --port 27018 --quiet << EOF
  rs.initiate(
      {
        _id : "shard1",
        members: [
          { _id : 0, host : "shard1:27018" }
        ]
      }
  );
  exit();
EOF
echo "Shard1 инициализирован"

print_separator "Инициализация shard2"
docker compose exec -T shard2 mongosh --port 27019 --quiet << EOF
  rs.initiate(
      {
        _id : "shard2",
        members: [
          { _id : 1, host : "shard2:27019" }
        ]
      }
  );
  exit();
EOF
echo "Shard2 инициализирован"
}

wait_for_mongos()
{
  local host="mongos_router"
  local port="27020"
  local max_attempts=30
  local attempt=0

  echo "Ожидание запуска mongos_router на порту $port..."

  while ! docker compose exec -T "$host" mongosh --port "$port" --eval "db.runCommand({ping:1})" --quiet >/dev/null 2>&1; do
    attempt=$((attempt + 1))
    if [ "$attempt" -ge "$max_attempts" ]; then
      echo "Ошибка: mongos_router не запустился после $max_attempts попыток"
      exit 1
    fi
    sleep 2
    echo "Попытка $attempt/$max_attempts..."
  done

  echo "mongos_router запущен и доступен"
}

init_mongo_router()
{

wait_for_mongos
print_separator "НАСТРОЙКА МОНГОС РОУТЕРА"
docker compose exec -T mongos_router mongosh --port 27020 --quiet << EOF
  sh.addShard( "shard1/shard1:27018");
  sh.addShard( "shard2/shard2:27019");
  sh.enableSharding("somedb");
  sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )
  use somedb
  for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i})
  db.helloDoc.countDocuments()
  exit();
EOF
echo "Маршрутизатор настроен, тестовые данные добавлены"
}