# dcape-app-mattermost
### Настройка очистки каналов

Для удаления устаревших сообщений из каналов mattermost, используется динамически создаваемый sql скрипт, выполняемый согласно расписания.

#### Управление параметрами очистки - настройка переменных кофигурации:
- *CLEAN_ENABLED* - разрешение запуска процедуры удаления сообщений, значения yes/no;
- *EMAIL_ADMIN* - адрес эл.почты для отправки уведомлений cron;
- *CRON_SCHED* - расписание выполнения скрипта очистки БД в формате cron;
- *CLEAN_RULES* - правила очистки каналов: имя_канала1:промежуток_времени,имя_канала2:промежуток_времени, где имя_канала1 - имя канала mattermost, промежуток_времени - 1 min, 3 days и т.д.
Пример:
Удалять,согласно расписания, сообщения старше 1 минуты из канала channel-name1; сообщения старше 4х дней из канала channel-name2.
````
CLEAN_RULES="channel-name1:1 min,channel-name2:4 days"
````

В случае обновления уже существующего деплоя приложения mattermost, перед обновлением необходимо добавить переменные *CLEAN_ENABLED*, *EMAIL_ADMIN*, *CLEAN_RULES*, *CRON_SCHED* в конфигурацию (cis dcape) установленного приложения.

#### Ручная инициализация расписания и скрипта очистки БД.
Выполняется в каталоге с развернутым приложением mattermost.

- создание файла расписания cron и скрипта БД:
````
make cron
````
#### Принудительный запуск очистки БД в ручном режиме.
Выполняется в каталоге с развернутым приложением mattermost.
````
make mmost-clean
````

#### Удаление файла расписания удаления сообщений, выполняется из корневого каталога развернутого приложния коммандой:
````
make cleanup
````

[![GitHub Release][1]][2] [![GitHub code size in bytes][3]]() [![GitHub license][4]][5]

[1]: https://img.shields.io/github/release/dopos/dcape-app-mattermost.svg
[2]: https://github.com/dopos/dcape-app-mattermost/releases
[3]: https://img.shields.io/github/languages/code-size/dopos/dcape-app-mattermost.svg
[4]: https://img.shields.io/github/license/dopos/dcape-app-mattermost.svg
[5]: LICENSE

[Mattermost](https://about.mattermost.com/) application package for [dcape](https://github.com/dopos/dcape).

## Docker image used

* [mattermost/mattermost-prod-app](https://hub.docker.com/r/mattermost/mattermost-prod-app/)

## Requirements

* linux 64bit (git, make, wget, gawk, openssl)
* [docker](http://docker.io)
* [dcape](https://github.com/dopos/dcape)
* Git service ([github](https://github.com), [gitea](https://gitea.io) or [gogs](https://gogs.io))

## Usage

* Fork this repo in your Git service
* Setup deploy hook
* Run "Test delivery" (config sample will be created in dcape)
* Edit and save config (enable deploy etc)
* Run "Test delivery" again (app will be installed and started on webhook host)
See also: [Deploy setup](https://github.com/dopos/dcape/blob/master/DEPLOY.md) (in Russian)

## License

The MIT License (MIT), see [LICENSE](LICENSE).

Copyright (c) 2017 Alexey Kovrizhkin <lekovr+dopos@gmail.com>
