# docker-presto
Facebook Presto docker image for development and testing purposes.

## What's inside
```
ubuntu:14.04
 |
 |--- zhicwu/java:8
       |
       |--- zhicwu/presto:latest
```
* Official Ubuntu Trusty(14.04) docker image
* Oracle JDK 8 latest release
* [Facebook Presto](http://prestodb.io/) 0.139 release

## How to use
- Pull the image
```
# docker pull zhicwu/presto:latest
```
- Setup scripts
```
# git clone https://github.com/zhicwu/docker-presto.git
# cd docker-presto
# chmod +x *.sh
```
- Start Presto
```
# ./start-presto.sh
# docker logs -f my-presto
...
# docker exec -it my-presto bash
# cd /presto
# ./presto --server presto:8080 --catalog jmx --schema jmx
presto:jmx> show tables;
```
