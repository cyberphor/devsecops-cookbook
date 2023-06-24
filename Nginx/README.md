## Nginx
**Rewrite Rule**  

last: Stops processing rewrite rules in the current location block and restarts the search for the location using the modified URI.
```
location /foo/ {
  rewrite ^/foo/(.*) /bar/$ last;
}
```

redirect: Performs an external redirect by sending an HTTP 302 redirect response to the client with the modified URI.
```
location /foo/ {
  rewrite ^/foo/(.*) /bar/$ redirect;
}
```

permanent: Performs a permanent redirect by sending an HTTP 301 redirect response to the client with the modified URI.
```
location /foo/ {
  rewrite ^/foo/(.*) /bar/$ permanent;
}
```

break: Terminates the current set of rewrite rules and uses the modified URI immediately.
```
location /foo/ {
  rewrite ^/foo/(.*) /bar/$ brea;
}
```

if, if-not, break-if, return, set: These flags provide conditional processing and variable manipulation capabilities within rewrite rules.
```
location /foo/ {
  rewrite ^/foo/(.*) /bar/$ if;
}
```
