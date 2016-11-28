Let's encrypt has made it very easy to get a valid public facing certificiate.
Unfortuantely, sometimes we want those for internal resources.   i.e. say you
have a build server and you want a proper cert on it but don't want to expose it to the
world. 


This project helps bridge that gap
by temporarily spinning up an instance with the proper hostname, getting the certs and downloading
you can then pause (i.e. stop) or terminate the instance.

This presumes that you have a hosted zone in your control at AWS, and a public subnet available
Run `make plan`  to double check everything.  When it looks good run `make apply`

you can run `make pause` to stop the instance

Note that you need rsync on your system to be able to automatically download the files.

Also note because we're grabbing 