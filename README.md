Dockerfile for Nuxeo 8.10 forked from https://github.com/nuxeo/docker-nuxeo

# Build docker image using s2i (outside openshift)
** s2i as standalone tool does not enforce any restrictions on the users, so the Dockerfile does not need to use an USER 100x **


Install https://github.com/openshift/source-to-image


 
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


# Build/run docker image in openshift
Install https://www.openshift.org/vm/
Using the CLI:

1. Create new project:

```
oc new-project deploynuxeo
```

2. Security constraints. If the Dockerfile for the base builder image does not contain an USER 1000- , the build fails on run ALLOWED_UIDS. This should fix the problem:
 https://docs.openshift.org/latest/creating_images/guidelines.html#openshift-specific-guidelines  ( section Support Arbitrary User IDs), but I did not manage to make it work:)
 
 Temporary fix:
 ```
 oc edit scc restricted
 and
 oc edit scc privileged -n default
 ```
 change strategy for user to 'RunAsAny' and add the following line to the list of users:
 system:serviceaccount:projectName:builder
 
  ```
  system:serviceaccount:deploynuxeo:builder
  ```
3. Build builder base image ( skip if the image already exists in internal/public repository)
  ```
  oc new-build https://github.com/mcedica/nuxeo-openshift-s2i-play.git --name nuxeo-oo-image-builder
   ```
   
4. Build docker image with complete configuration based on the previous base image. Pass all the needed configuration as env variables 
  
  ```  
   oc new-build nuxeo-oo-image-builder~https://github.com/mcedica/nuxeo-openshift-s2i-play.git   --strategy=source -e NUXEO_PACKAGES=nuxeo-web-ui
   
   ```
   or
   ```  
   oc new-build nuxeo-oo-image-builder~https://github.com/mcedica/nuxeo-openshift-s2i-play.git   --strategy=source -e NUXEO_PACKAGES=mcedica-SANDBOX -e NUXEO_CLID="$clid"
   
   ```  
5. Deploy and start app ( Step 4 and 5 can be merged into one, but because of a bug in CLI 1.3 env vars can not be passed to the builder in new-app command - fixed in 1.5, see https://github.com/openshift/origin/issues/8795 )
   
   ```
   oc new-app nuxeo-openshift-s2i-play
   ```  
   
# Using secrets 

!! Can not use encrypted env vars secrets in the build phase - there is an open bug in Openshift related to this: https://bugzilla.redhat.com/show_bug.cgi?id=1402468 )

1. Create the secret in OpenShift


- json file withe the following format, where secret data is base64 encoded.
nuxeoSecrets.json :
  ```{
  "apiVersion": "v1",
  "kind": "Secret",
  "metadata": {
    "name": "nuxeostudiosecret"
  },
  "namespace": "myns",
  "data": {
    "clid": "NzY4Y2MyYTgtMjI3OS00MjZkLTlkYmMtYTY1NmFhNDNkZDE0LUwNC0xMDBlLTQ0ODMtODNmYi1lMjc5YWIzMWQ3MTMNCg==",
    "project": "bWNlZGljYS1TQU5k9Y"
  }
}```  
- create the secret from the above file
```
oc create -f nuxeoSecrets.json
``` 

2. Inject the secret in the buid phase to use in the docker image
<p>The secrets are injected as files, abailable at the root folder only during the build phase, the name of file is the name of the secret </p>

!! I have only modified the assemble script to handle passing the NUXEO_CLID as secret for now, but the logic is very simple: before fetching the value from the env var, test if there is a file with that name, if the file is found, inject is content as the var

<b>Because in the nuxeostudiosecret, we have an entry key for clid, now we can just pass it as:  </b>
``` 
oc new-build nuxeo-oo-image-builder~https://github.com/mcedica/nuxeo-openshift-s2i-play.git  --name=nuxeo-configured-image  --strategy=source --build-secret=nuxeostudiosecret -e NUXEO_CLID=clid

``` 
3. Create a new app ( it will deploy and run the above image)
``` 
oc new-app nuxeo-configured-image
```


