# nuxeo-openshift-s2i-play

Dockerfile for Nuxeo 8.10 forked from https://github.com/nuxeo/docker-nuxeo
 
1. BUILD INITIAL IMAGE
```
docker build  -t nuxeoplay .
```

2. CUSTOMIZE BY SETTING SOME ENV VARS
```
s2i build .  nuxeoplay -e NUXEO_PACKAGES=nuxeo-web-ui -e NUXEO_DEV_MODE=false --loglevel=5 test-nuxeo
```

3. RUN CUSTOMIZED IMANGE
```
docker run -d -p 8080:8080 test-nuxeo
```
!! DO NOT RUN docker exec against the container as it's going to be killed !!

