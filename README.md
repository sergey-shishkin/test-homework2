# Тестовое задание по развертыванию NodeJS приложения в Kubernetes

### Описать сборку и развертывание N экземпляров такого приложения в Kubernetes (с балансировкой входящих запросов между экземплярами).

Для сборки приложения необходимо создать [Dockerfile](Dockerfile), в котором описать сборку приложения и запуск. После чего его необходимо собрать соответствующей командой:
```console
$ docker build -t registry/nodeapp:latest .
```
В образе проставлены дефолтные значения переменных окружения, но их так же можно "вшить" в образ, добавив параметры сборки:
```console
$ docker build -t registry/nodeapp:latest --build-arg HTTP_PORT=80 --build-arg MYSQL_HOST=mysql --build-arg MYSQL_PORT=3306 .
```
Предполагается, что у нас есть некий докер-реджистри по имени `registry`, соответственно, после сборки пушим туда образ:
```console
$ docker push registry/nodeapp:latest
```
Далее, необходимо поднять приложение в кубернетисе. Предполагается, что кубернетис уже поднят и настроен, так же настроен доступ к его консоли с помощью kubectl. Соответственно, необходим файл манифеста [app.yml](app.yml), в котором прописан деплоймент пода и сервис, через который он будет опубликовываться. Для простоты и универсальности реализации будем публиковать через `NodePort`, но вообще это очень зависит от среды, в которую опубликовывается. Скажем, в облаке это может быть `LoadBalancer`. Соответственно, применяем данный манифест:
```console
$ kubectl apply -f app.yml
```
Приложение будет поднято с тремя репликами, которые будут балансироваться самим кубернетисом. Изменить количество реплик можно, например, так:
```console
$ kubectl scale --replicas=10 deployment/nodeapp
```
*Замечание: т.к. самого приложения у меня нет, то все конфигурационные файлы являются "теоретическими". Т.е., по идее, должны работать, но по факту не проверены, потому что, как бы, не с чем.*

### Обеспечить централизованный сбор логов приложения из STDOUT/STDERR.

Реализация данной задачи довольно сильно зависит от фактической реализации кубернетиса и того, как и где он был развернут. В случае, скажем, OpenShift/OKD есть встроенный ELK-стек, который можно включить при развертывании (либо подключить позднее) стандартным плейбуком. Но если у нас, предположим, "голый" кубернетис, поднятый kubeadm, то добавить его можно с помощью `helm` (предполагаем, что он уже установлен) примерно следующим образом:
```console
$ helm repo add elastic https://helm.elastic.co
$ helm repo update
$ helm install elasticsearch elastic/elasticsearch
$ helm install kibana elastic/kibana
$ helm install filebeat elastic/filebeat
```
После этого можно будет опубликовать каким-либо (через NodePort, либо Ingress) образом консоль Kibana и смотреть прилетающие с подов логи.

Разумеется, установка с дефолтными значениями не особо рекомендуется, но тонкая настройка требует чуть более точной постановки задачи и анализа того, что и как будет собираться.

### Описать возможные подходы к мониторингу состояния приложения.

Это, опять же, зависит от реализации кубернетиса. В OpenShift/OKD, опять же, уже есть встроенный стек `prometheus-operator` (в который входят, собственно, Prometheus, AlertManager и Grafana), который ставится и настраивается по умолчанию на весь кластер. Опять же, в случае "голого" кубернетиса, поднятого kubeadm, поднять `prometheus-operator` можно примерно следующим образом:
```console
$ helm repo add stable https://kubernetes-charts.storage.googleapis.com
$ helm repo update
$ helm install metrics-server stable/metrics-server --set args[0]=--kubelet-insecure-tls
$ helm install prometheus stable/prometheus-operator
```
*Замечание: параметр `--set args[0]=--kubelet-insecure-tls` актуален только для инсталляций с использованием kubeadm!*


Каким образом использовать данный стек - довольно сильно зависит от инфраструктуры. Можно, скажем, настроить интеграцию Prometheus с Zabbix (что [официально поддерживается](https://www.zabbix.com/integrations/prometheus)), можно, как вариант, настроить телеграм бота (например, вот [такого](https://github.com/metalmatze/alertmanager-bot)) на определенные события AlertManager. К сожалению, задача поставлена достаточно широко и размыто, поэтому довольно сложно привести какие-то конкретные реализации. Каких-то фактических примеров реализации из собственного опыта я в данном случае, к сожалению, не смогу привести в силу отсутствия такового опыта.
