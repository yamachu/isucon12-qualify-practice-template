.PHONY: install-initialdata init-mysql run-bench run-bench-noload own-initial-data

up/%:
	APP_LANGUAGE=$* docker compose -f docker-compose.yml up $(OPT)

down/%:
	APP_LANGUAGE=$* docker compose -f docker-compose.yml down

logs-webapp/%:
	APP_LANGUAGE=$* docker compose -f docker-compose.yml logs -f webapp

init-mysql:
	docker compose -f docker-compose.yml exec --workdir /docker-entrypoint-initdb.d mysql \
		bash -c 'cat 10_schema.sql 90_data.sql | mysql -uisucon -pisucon isuports'

run-bench:
	docker compose -f docker-compose.yml exec bench go run cmd/bench/main.go

initial_data.tar.gz:
	gh release list | awk '/Latest/{print $$3}' | xargs gh release download --dir .

own-initial-data:
	docker compose -f docker-compose.yml exec -u root bench bash -c "chown -R isucon:isucon /home/isucon/initial_data"
	docker compose -f docker-compose.yml exec -u root webapp bash -c "chown -R isucon:isucon /home/isucon/webapp/tenant_db"

install_initial_data: own-initial-data
	docker compose -f docker-compose.yml  cp ./initial_data/ bench:/home/isucon/

initial_data: initial_data.tar.gz
	tar -C . -xvf ./initial_data.tar.gz
