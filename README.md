# docker-presto
Facebook Presto docker image for development and testing purposes.

## What's inside
```
ubuntu:14.04
 |
 |--- zhicwu/java:8
       |
       |--- zhicwu/presto:0.136
```
* Official Ubuntu Trusty(14.04) docker image
* Oracle JDK 8 latest release
* [Facebook](http://prestodb.io/) 0.136 release

## How to use
- Pull the image
```
# docker pull zhicwu/presto:0.136
```
- Setup scripts
```
# git clone http://github.com/zhicwu/docker-presto.git
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
