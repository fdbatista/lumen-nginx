Run Lumen/Laravel 9 applications with PHP FPM and Nginx.
Supervisor makes sure all services stay available.

You can also make the built-in Supervisor take care of Laravel queue.

Example:

- Queue worker configuration on `./docker/supervisor/conf.d/queue-worker.conf`:
```
[program:queue-worker]
command=php /var/www/html/artisan queue:work
process_name=%(program_name)s_%(process_num)02d
numprocs=2
autostart=true
autorestart=true
startsecs=1
startretries=30
user=www-data
redirect_stderr=false
stdout_logfile=/var/log/supervisor/queue-worker.log
stdout_logfile_maxbytes=1MB
stdout_logfile_backups=10
stderr_logfile=/var/log/supervisor/queue-worker-error.log
stderr_logfile_maxbytes=1MB
stderr_logfile_backups=10
```

Example Laravel/Lumen service on `docker-compose.yml`:
```
api:
    image: fdbatista/lumen-nginx:2.1
    container_name: api
    restart: always
    env_file:
      - .env
    environment:
      - DB_HOST=${DB_HOST}
      - DB_PORT=${DB_PORT}
      - DB_DATABASE=${DB_DATABASE}
      - DB_USERNAME=${DB_USERNAME}
      - DB_PASSWORD=${DB_PASSWORD}
    volumes:
      - ./:/var/www/html/
      - ./docker/supervisor/conf.d/:/etc/supervisor/conf.d/
    depends_on:
      - db
      - rabbitmq
      - memcached
```
