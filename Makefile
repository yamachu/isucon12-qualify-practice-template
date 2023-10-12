.PHONY: install-initialdata init-mysql run-bench run-bench-noload own-initial-data
# isucon12-qualify_isucon12-qualify は プロジェクト名_ネットワーク名 で生成されていたはず
# そのため、指定を頑張らなくていいように DOCKER_COMPOSE でプロジェクト名も指定している
NGINX_HOST = $$(docker network inspect -f '{{json .Containers}}' isucon12-qualify_isucon12-qualify |jq '.[] | .Name + ":" + .IPv4Address' | grep nginx | cut -d":" -f2 | cut -d"/" -f1)
DOCKER_COMPOSE = docker compose -p isucon12-qualify -f docker-compose.yml

up/%:
	APP_LANGUAGE=$* $(DOCKER_COMPOSE) up $(OPT)

down/%:
	APP_LANGUAGE=$* $(DOCKER_COMPOSE) down

logs-webapp/%:
	APP_LANGUAGE=$* $(DOCKER_COMPOSE) logs -f webapp

init-mysql:
	$(DOCKER_COMPOSE) exec --workdir /docker-entrypoint-initdb.d mysql \
		bash -c 'cat 10_schema.sql 90_data.sql | mysql -uisucon -pisucon isuports'

run-bench:
	$(DOCKER_COMPOSE) exec bench go run cmd/bench/main.go -target-url https://t.isucon.dev --target-addr $(NGINX_HOST):443

initial_data.tar.gz:
	gh release list | awk '/Latest/{print $$3}' | xargs gh release download --dir .

own-initial-data:
	$(DOCKER_COMPOSE) exec -u root bench bash -c "chown -R isucon:isucon /home/isucon/initial_data"
	$(DOCKER_COMPOSE) exec -u root webapp bash -c "chown -R isucon:isucon /home/isucon/webapp/tenant_db"

install_initial_data: own-initial-data
	$(DOCKER_COMPOSE)  cp ./initial_data/ bench:/home/isucon/

initial_data: initial_data.tar.gz
	tar -C . -xvf ./initial_data.tar.gz
