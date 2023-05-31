# Docker

**Build a Container**
```
docker build . -t foo:latest
```

**Rebuild a Container Using Docker Compose**
```
docker-compose up --build
```

**Run a Container Using a Specific Image and Tag**
```
docker run -t foo:latest
```

**Run and Interact with a Container of a Specific Image and Tag****
```
docker run -it foo:latest
```

**Prune Images, Containers, and Networks**
```
docker system prune -f
```

**Remove Multiple Images**
```
docker rmi certificates elastalert elasticsearch
```

**Remove All Images on a Windows Host**
```
docker rmi $(docker images --quiet) -f
```

**Remove All Volumes from a Windows Host**  
```
docker volume rm $(docker volume ls -q)
```

**Copy a File From a Container to the Host**
```
docker cp elasticsearch:/usr/share/elasticsearch/config/certs/http_ca.crt .
```

**List Volumes**
```
docker volume ls
```

**Inspect the Contents of a Volume**
```
docker run -v certificates:/tmp -it alpine sh
cd /tmp
ls
```

**Follow Logs Using Docker Compose**  
```
docker-compose logs -f
```

**Stop Running Containers Using Docker Compose**  
```
docker-compose down
```

## References
* [Windows, curl, and Self-signed Certs](https://www.phillipsj.net/posts/windows-curl-and-self-signed-certs/)
* [How to Run Elasticsearch 8 on Docker for Local Development](https://levelup.gitconnected.com/how-to-run-elasticsearch-8-on-docker-for-local-development-401fd3fff829)
