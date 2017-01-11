# nuxeo-openshift-s2i-play
Install https://github.com/openshift/source-to-image

Dockerfile for Nuxeo 8.10 forked from https://github.com/nuxeo/docker-nuxeo
 
* BUILD INITIAL IMAGE
```
docker build  -t nuxeoplay .
```

*  CUSTOMIZE BY SETTING SOME ENV VARS
```
s2i build .  nuxeoplay -e NUXEO_PACKAGES=nuxeo-web-ui -e NUXEO_DEV_MODE=false --loglevel=5 test-nuxeo
```
or
```
s2i build .  nuxeoplay -e NUXEO_PACKAGES="$STUDIO_PROJECT" -e NUXEO_CLID="$CLID" --loglevel=5 test-nuxeo
```

*  RUN CUSTOMIZED IMANGE
```
docker run -d -p 8080:8080 test-nuxeo
```
!! DO NOT RUN docker exec against the container as it's going to be killed !!

