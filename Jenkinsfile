pipeline {
  agent any

  options {
    timestamps()
    ansiColor('xterm')
    disableConcurrentBuilds()
  }

  parameters {
    booleanParam(name: 'RESET_DB', defaultValue: false, description: 'Удалить контейнер и volume для чистой инициализации')
    string(name: 'POSTGRES_DB', defaultValue: 'bootlegbricks', description: 'Имя базы данных')
    string(name: 'TZ', defaultValue: 'Europe/Moscow', description: 'Часовой пояс контейнера')
    string(name: 'POSTGRES_IMAGE', defaultValue: 'postgres:18-alpine', description: 'Тег Docker-образа PostgreSQL')
    string(name: 'HOST_PORT', defaultValue: '5445', description: 'Проброшенный порт хоста')
  }

  environment {
    COMPOSE_FILE_PATH = './docker-compose.db.yml'
    DB_DIR            = '.'
    CONTAINER_NAME    = 'bootlegbricks-db'
    VOLUME_NAME       = 'bootlegbricks_pgdata'

    POSTGRES_DB       = credentials('POSTGRES_DB')
    POSTGRES_USER     = credentials('POSTGRES_USER')
    POSTGRES_PASSWORD = credentials('POSTGRES_PASSWORD')
  }

  stages {

    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Prepare env') {
      steps {
        dir("${DB_DIR}") {
          sh '''
            set -eu
            cat > .env <<-EOF
POSTGRES_DB=${POSTGRES_DB}
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
INIT_SQL_DIR=${WORKSPACE}/sql/init
TZ=${TZ}
EOF
            echo "[info] .env создан в ${PWD}"
          '''
        }
      }
    }

    stage('Stop / Reset') {
      steps {
        dir("${DB_DIR}") {
          script {
            sh '''
              set +e
              docker compose -f "${COMPOSE_FILE_PATH}" --env-file .env down --remove-orphans
              exit 0
            '''

            if (params.RESET_DB) {
              sh '''
                set +e
                docker compose -f "${COMPOSE_FILE_PATH}" --env-file .env down -v --remove-orphans || true
                # ИЗМЕНЕНИЕ: на всякий случай удалить зафиксированный том по имени (теперь имя стабильное)
                docker volume rm -f "bootlegbricks_pgdata" 2>/dev/null || true
                exit 0
              '''
            }
          }
        }
      }
    }

    stage('Build DB Image') {
      steps {
        dir("${DB_DIR}") {
          sh '''
            set -eu
            docker compose -f "${COMPOSE_FILE_PATH}" build bootlegbricks-db
          '''
        }
      }
    }

    stage('Deploy DB') {
      steps {
        dir("${DB_DIR}") {
          sh '''
            set -eu
            docker compose -f "${COMPOSE_FILE_PATH}" --env-file .env up -d --remove-orphans

            docker inspect "${CONTAINER_NAME}" --format '{{json .Mounts}}' | jq .
            docker exec "${CONTAINER_NAME}" sh -lc 'ls -la /docker-entrypoint-initdb.d || true'

            echo "[info] Ожидание статуса health=healthy…"
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
        sh '''
          set -eu
          docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" "${CONTAINER_NAME}" \
            psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "\\l" >/dev/null

          docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" "${CONTAINER_NAME}" \
            psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "\\dt" || true
        '''
      }
    }
  }

  post {
    always {
      sh '''
        set +e
        echo "=== tail logs ==="
        docker logs --since=5m "${CONTAINER_NAME}" 2>/dev/null | tail -n 200 || true
        exit 0
      '''
    }
  }
}
