This is the Infinite Trading Protocol API Gateway

To run this, you need to install the following packages:

RSQLite
DBI
Shiny
Plumber
DotEnv


This gateway is the filter between the API, NGINX, and the internet.

Internet -> NGINX -> Gateway -> ITP API

This is protecting our API from DOS attacks and other known vulnerabilities and issues that arise when you expose endpoints to the internet. 

More instructions on how to run this will be added later.
