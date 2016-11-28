Let's encrypt has made it very easy to get a valid public facing certificiate.
Unfortuantely, sometimes we want those for internal resources.   

This project helps bridge that gap
by temporarily spinning up an instance with the proper hostname, getting the certs and downloading
you can then pause (i.e. stop) or terminate the instance.


Run `make plan`  to double check everything.  When it looks good run `make apply`

you can run `make pause` to stop the instance