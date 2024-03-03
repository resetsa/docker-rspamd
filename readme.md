# Назначение

Репозиторий для тестирования работы с RSPAMD [https://rspamd.com]

## Состав

- docker-compose.yaml - для быстрого запуска
- bash/cli_rspamd.sh - шаблон скрипта для тестирования писем на spam
- go/ - проект на golang

## Сборка Golang

```powershell
git clone https://github.com/resetsa/docker-rspamd.git
cd docker-rspamd/go/
go mod tidy
# for windows
go build cmd/cli_rspamd/cli_rspamd.go
# for linux
$env:GOOS="linux"; $env:GOARCH="amd64" go build cmd/cli_rspamd/cli_rspamd.go
```
