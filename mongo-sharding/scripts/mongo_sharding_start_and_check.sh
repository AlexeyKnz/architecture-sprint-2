#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CLEANUP=false  #  По умолчанию очистка отключена

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cleanup)
      CLEANUP=true
      shift
      ;;
    --help)
      echo "Использование: $0 [--cleanup]"
      echo "  --cleanup выполнять 'docker-compose down -v' после завершения"
      echo "  --help        Показать эту справку"
      exit 0
      ;;
    *)
      echo "Неизвестный аргумент: $1" >&2
      exit 1
      ;;
  esac
done

# Запуск контейнеров
docker compose up -d

# Импорт функций
source "${SCRIPT_DIR}/mongo_init_funcs.sh"
source "${SCRIPT_DIR}/mongo_test_funcs.sh"

# Инициализация MongoDB
init_mongo_serv     # Инициализируем configSrv mongo
init_shards         # Инициализируем шарды
init_mongo_router   # Инициализируем mongo роутер, наполняем БД данными

# Тестирование
mongo_test_shard_doc_count shard1 27018  # Проверка shard1
mongo_test_shard_doc_count shard2 27019  # Проверка shard2

# Очистка (если не отключено)
if [ "$CLEANUP" = true ]; then
  echo "Выполняю очистку контейнеров..."
  docker-compose down -v
else
  echo "Очистка контейнеров пропущена (по запросу)"
fi