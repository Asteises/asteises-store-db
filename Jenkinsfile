pipeline {
  agent any

  options {
    timestamps()
    ansiColor('xterm')
    disableConcurrentBuilds()
  }

  parameters {
    // Можно переключать «чистый» старт (удаление volume)
    booleanParam(name: 'RESET_DB', defaultValue: false, description: 'Удалить контейнер и volume для чистой инициализации')
    // Явно задаём БД и TZ (user/pass берём из credentials)
    string(name: 'POSTGRES_DB', defaultValue: 'bootlegbricks', description: 'Имя базы данных')
    string(name: 'TZ', defaultValue: 'Europe/Moscow', description: 'Часовой пояс контейнера')
    string(name: 'POSTGRES_IMAGE', defaultValue: 'postgres:18-alpine', description: 'Тег Docker-образа PostgreSQL')
    string(name: 'HOST_PORT', defaultValue: '5445', description: 'Проброшенный порт хоста')
  }

  environment {
    COMPOSE_FILE_PATH = './docker-compose.db.yml'
    // Рабочая директория
    DB_DIR = './db'
    CONTAINER_NAME = 'bootlegbricks-db'
    VOLUME_NAME    = 'bootlegbricks_pgdata'

    POSTGRES_DB = credentials('POSTGRES_DB')
    POSTGRES_USER = credentials('POSTGRES_USER')
    POSTGRES_PASSWORD = credentials('POSTGRES_PASSWORD')
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Prepare env') {
      steps {
        dir("${DB_DIR}") {
          // Комментарий: формируем .env для docker compose (в VCS не коммитим)
          sh '''
            set -eu
            cat > .env <<EOF
            POSTGRES_DB=${POSTGRES_DB}
            POSTGRES_USER=${POSTGRES_USER}
            POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
            TZ=${TZ}
            EOF
            echo "[info] .env создан в ${PWD}"
            '''
          }

        sh '''
          set -eu
          cp "${COMPOSE_FILE_PATH}" "${COMPOSE_FILE_PATH}.bak"
          # Комментарий: заменяем тег образа (только первую встречу строки image:)
          awk -v img="${POSTGRES_IMAGE}" '
            $1=="image:"{$2=img; print "  image: " img; next} {print}
          ' "${COMPOSE_FILE_PATH}.bak" > "${COMPOSE_FILE_PATH}.tmp1"

          # Комментарий: при желании заменить порт "5445:5432" на параметр
          awk -v hp="${HOST_PORT}" '
            /- ".*:5432"/ { sub(/[0-9]+:5432/, hp ":5432"); print; next }
            { print }
          ' "${COMPOSE_FILE_PATH}.tmp1" > "${COMPOSE_FILE_PATH}.tmp2"

          mv "${COMPOSE_FILE_PATH}.tmp2" "${COMPOSE_FILE_PATH}.effective"
          echo "[info] Сгенерирован compose-эффективный файл: ${COMPOSE_FILE_PATH}.effective"
        '''
      }
    }

    stage('Stop / Reset (optional)') {
      steps {
        dir("${DB_DIR}") {
          script {
            // Комментарий: корректно останавливаем текущий стек (без ошибок, если его нет)
            sh '''
              set +e
              docker compose -f "${COMPOSE_FILE_PATH}.effective" --env-file .env down --remove-orphans
              exit 0
            '''

            if (params.RESET_DB) {
              // Комментарий: полная очистка volume для повторного прогона init-скриптов
              sh '''
                set +e
                docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true
                docker volume rm -f "${VOLUME_NAME}" 2>/dev/null || true
                exit 0
              '''
            }
          }
        }
      }
    }

    stage('Deploy DB') {
      steps {
        dir("${DB_DIR}") {
          // Комментарий: поднимаем БД и ждём healthcheck
          sh '''
            set -eu
            docker compose -f "${COMPOSE_FILE_PATH}.effective" --env-file .env up -d --remove-orphans
            echo "[info] Ожидание статуса health=healthy…"
            # Ждём до ~2 минут (12*10с) пока healthcheck не станет healthy
            for i in $(seq 1 12); do
              STATUS=$(docker inspect -f '{{ if .State.Health }}{{ .State.Health.Status }}{{ else }}unknown{{ end }}' "${CONTAINER_NAME}" || echo "unknown")
              echo "  попытка $i: ${STATUS}"
              if [ "${STATUS}" = "healthy" ]; then
                echo "[ok] Контейнер готов."
                exit 0
              fi
              sleep 10
            done
            echo "[err] Контейнер не стал healthy вовремя."
            docker logs --since=10m "${CONTAINER_NAME}" || true
            exit 1
          '''
        }
      }
    }

    stage('Smoke SQL') {
      steps {
        // Комментарий: простой SQL-дым-тест — покажем список таблиц; init-скрипты сработают только при пустом volume
          sh '''
            set -eu
            docker exec -e POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" "${CONTAINER_NAME}" \
              psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "\\l" >/dev/null

            docker exec -e POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" "${CONTAINER_NAME}" \
              psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "\\dt" || true
          '''
      }
    }
  }

  post {
    always {
      // Комментарий: показываем последние строки логов для диагностики
      sh '''
        set +e
        echo "=== tail logs ==="
        docker logs --since=5m "${CONTAINER_NAME}" 2>/dev/null | tail -n 200 || true
        exit 0
      '''
    }
  }
}
