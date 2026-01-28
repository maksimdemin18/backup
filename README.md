# Домашнее задание к занятию "`Резервное копирование`" - `Дёмин Максим`


### Задание 1

Что нужно сделать:

Составьте команду rsync, которая позволяет создавать зеркальную копию домашней директории пользователя в директорию /tmp/backup

Необходимо исключить из синхронизации все директории, начинающиеся с точки (скрытые)

Необходимо сделать так, чтобы rsync подсчитывал хэш-суммы для всех файлов, даже если их время модификации и размер идентичны в источнике и приемнике.

На проверку направить скриншот с командой и результатом ее выполнения

### Решение:

1. зеркальную копию домашней директории $HOME → в директорию /tmp/backup, исключить скрытые директории, проверка по хэшам
   ```
   rsync -a --delete --checksum   --filter='- .*/'   --info=stats2   "$HOME/" /tmp/backup/
   ```

```
-a архивный режим 

--delete  удаляет в /tmp/backup то, чего нет в источнике

--checksum  сравнение по контрольным суммам

--filter='- .*/'  исключает каталоги, начинающиеся с точки
```

2. [Проверяем домашнюю директорию и выполняем команду](task1/screen1.png)
   
3. [Проверяем директорию /tmp/backup](task1/screen2.png)


### Задание 2

Что нужно сделать:

Написать скрипт и настроить задачу на регулярное резервное копирование домашней директории пользователя с помощью rsync и cron.

Резервная копия должна быть полностью зеркальной

Резервная копия должна создаваться раз в день, в системном логе должна появляться запись об успешном или неуспешном выполнении операции

Резервная копия размещается локально, в директории /tmp/backup

На проверку направить файл crontab и скриншот с результатом работы утилиты.

### Решение:

1. Пишем скрипт [rsync_backup.sh](task2/rsync_backup.sh)

2. Добавляем в crontab чтобы резервная копия создавалась раз в день. Выполнячем команду crontab -e и добавляем
   
   ```
   MAILTO=""
   0 2 * * * SRC="$HOME/" DEST="/tmp/backup/" EXCLUDE_HIDDEN_DIRS=1 LOG_FILE="/tmp/rsync_backup.log" /usr/local/sbin/rsync_backup.sh
   ```
3. Проверяем
[Запускаем вручную для проверки](task2/screen1.png)

[Содержимое /tmp/backup/](task2/screen2.png)

[логи выполения скрипта](task2/screen3.png)

```
maksim@forzabbx1:/usr/local/sbin$ journalctl -t rsync_backup -n 20 --no-pager
-- Logs begin at Mon 2026-01-05 19:29:26 UTC, end at Tue 2026-01-27 16:50:49 UTC. --
Jan 27 16:48:07 forzabbx1 rsync_home_backup[1059187]: OK: SRC=/home/maksim/ DEST=/tmp/backup/
Jan 27 16:48:08 forzabbx1 rsync_home_backup[1059196]: OK: SRC=/home/maksim/ DEST=/tmp/backup/
Jan 27 16:48:08 forzabbx1 rsync_home_backup[1059205]: OK: SRC=/home/maksim/ DEST=/tmp/backup/
Jan 27 16:48:08 forzabbx1 rsync_home_backup[1059214]: OK: SRC=/home/maksim/ DEST=/tmp/backup/
Jan 27 16:48:09 forzabbx1 rsync_home_backup[1059223]: OK: SRC=/home/maksim/ DEST=/tmp/backup/
Jan 27 16:48:09 forzabbx1 rsync_home_backup[1059232]: OK: SRC=/home/maksim/ DEST=/tmp/backup/
Jan 27 16:48:09 forzabbx1 rsync_home_backup[1059241]: OK: SRC=/home/maksim/ DEST=/tmp/backup/
Jan 27 16:48:09 forzabbx1 rsync_home_backup[1059252]: OK: SRC=/home/maksim/ DEST=/tmp/backup/
Jan 27 16:48:10 forzabbx1 rsync_home_backup[1059261]: OK: SRC=/home/maksim/ DEST=/tmp/backup/
Jan 27 16:48:10 forzabbx1 rsync_home_backup[1059270]: OK: SRC=/home/maksim/ DEST=/tmp/backup/
Jan 27 16:48:10 forzabbx1 rsync_home_backup[1059279]: OK: SRC=/home/maksim/ DEST=/tmp/backup/
Jan 27 16:48:10 forzabbx1 rsync_home_backup[1059288]: OK: SRC=/home/maksim/ DEST=/tmp/backup/
Jan 27 16:48:11 forzabbx1 rsync_home_backup[1059297]: OK: SRC=/home/maksim/ DEST=/tmp/backup/
Jan 27 16:48:11 forzabbx1 rsync_home_backup[1059306]: OK: SRC=/home/maksim/ DEST=/tmp/backup/
Jan 27 16:48:11 forzabbx1 rsync_home_backup[1059315]: OK: SRC=/home/maksim/ DEST=/tmp/backup/
Jan 27 16:48:12 forzabbx1 rsync_home_backup[1059324]: OK: SRC=/home/maksim/ DEST=/tmp/backup/
Jan 27 16:48:12 forzabbx1 rsync_home_backup[1059333]: OK: SRC=/home/maksim/ DEST=/tmp/backup/
Jan 27 16:48:12 forzabbx1 rsync_home_backup[1059342]: OK: SRC=/home/maksim/ DEST=/tmp/backup/
Jan 27 16:48:12 forzabbx1 rsync_home_backup[1059351]: OK: SRC=/home/maksim/ DEST=/tmp/backup/
Jan 27 16:49:03 forzabbx1 rsync_home_backup[1059395]: OK: SRC=/home/maksim/ DEST=/tmp/backup/
```
Можем проверить лог выполнения скрипта
```
maksim@forzabbx1:~$ tail -n 50 /tmp/rsync_backup.log
Matched data: 0 bytes
File list size: 0
File list generation time: 0.001 seconds
File list transfer time: 0.000 seconds
Total bytes sent: 602
Total bytes received: 21

sent 602 bytes  received 21 bytes  1.25K bytes/sec
total size is 41.36K  speedup is 66.39

2026-01-27T16:48:12+00:00 OK: SRC=/home/maksim/ DEST=/tmp/backup/
----- 2026-01-27T16:48:12+00:00 rsync output (rc=0) -----

Number of files: 13 (reg: 10, dir: 3)
Number of created files: 0
Number of deleted files: 0
Number of regular files transferred: 0
Total file size: 41.36K bytes
Total transferred file size: 0 bytes
Literal data: 0 bytes
Matched data: 0 bytes
File list size: 0
File list generation time: 0.001 seconds
File list transfer time: 0.000 seconds
Total bytes sent: 602
Total bytes received: 21

sent 602 bytes  received 21 bytes  1.25K bytes/sec
total size is 41.36K  speedup is 66.39

2026-01-27T16:49:03+00:00 OK: SRC=/home/maksim/ DEST=/tmp/backup/
----- 2026-01-27T16:49:03+00:00 rsync output (rc=0) -----

Number of files: 13 (reg: 10, dir: 3)
Number of created files: 12 (reg: 10, dir: 2)
Number of deleted files: 0
Number of regular files transferred: 10
Total file size: 41.36K bytes
Total transferred file size: 41.36K bytes
Literal data: 41.36K bytes
Matched data: 0 bytes
File list size: 0
File list generation time: 0.001 seconds
File list transfer time: 0.000 seconds
Total bytes sent: 42.40K
Total bytes received: 228

sent 42.40K bytes  received 228 bytes  85.26K bytes/sec
total size is 41.36K  speedup is 0.97
```
Задания со звёздочкой*
Эти задания дополнительные. Их можно не выполнять. На зачёт это не повлияет. Вы можете их выполнить, если хотите глубже разобраться в материале.

### Задание 3*

Что нужно сделать:

Настройте ограничение на используемую пропускную способность rsync до 1 Мбит/c

Проверьте настройку, синхронизируя большой файл между двумя серверами

На проверку направьте команду и результат ее выполнения в виде скриншота

### Решение:

1 Создаем файл большого размера командой [bigfile.bin](task3/screen_1.png)
```fallocate -l 10M bigfile.bin ```

2 Для синхронизации используем команду [rsync](task3/screen_2.png)
```rsync -a --bwlimit=125 -e "ssh" ~/bigfile.bin maksim@192.168.88.216:/tmp/```
где --bwlimit задаётся в КБ/с.(1 Мбит/с ≈ 125 КБ/с (1,000,000 / 8 ≈ 125,000 байт/с))

3 Проверяем локально и замер времени [time](task3/screen_3.png)
```/usr/bin/time -p rsync -a --bwlimit=125 --stats ~/bigfile.bin /tmp/```
```

Number of files: 1 (reg: 1)
Number of created files: 1 (reg: 1)
Number of deleted files: 0
Number of regular files transferred: 1
Total file size: 10,485,760 bytes
Total transferred file size: 10,485,760 bytes
Literal data: 10,485,760 bytes
Matched data: 0 bytes
File list size: 0
File list generation time: 0.001 seconds
File list transfer time: 0.000 seconds
Total bytes sent: 10,488,425
Total bytes received: 35

sent 10,488,425 bytes  received 35 bytes  127,132.85 bytes/sec
total size is 10,485,760  speedup is 1.00
real 81.88
user 0.12
sys 0.14
```


### Задание 4*

Что нужно сделать:

Напишите скрипт, который будет производить инкрементное резервное копирование домашней директории пользователя с помощью rsync на другой сервер

Скрипт должен удалять старые резервные копии (сохранять только последние 5 штук)

Напишите скрипт управления резервными копиями, в нем можно выбрать резервную копию и данные восстановятся к состоянию на момент создания данной резервной копии.

На проверку направьте скрипт и скриншоты, демонстрирующие его работу в различных сценариях.

### Решение:

1. [Пишем скрипт](task4/rsync_snapshot_backup.sh), который будет производить инкрементное резервное копирование домашней директории пользователя с помощью rsync на другой сервер, должен удалять старые резервные копии (сохранять только последние 5 штук),
2. [Пишем скрипт](task4/rsync_snapshot_restore.sh), управления резервными копиями, в нем можно выбрать резервную копию и данные восстановятся к состоянию на момент создания данной резервной копии.
