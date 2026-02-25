docker pull dpage/pgadmin4
docker run -p 5050:80 \
  -e PGADMIN_DEFAULT_EMAIL=karneeshkar68@gmail.com \
  -e PGADMIN_DEFAULT_PASSWORD=Password123\
  -d dpage/pgadmin4
