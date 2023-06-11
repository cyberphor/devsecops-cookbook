## Error
```
exposing port TCP 0.0.0.0:8000 -> 0.0.0.0:0: listen tcp 0.0.0.0:8000: bind: An attempt was made to access a socket in a way forbidden by its access permissions.
```

## Fix
```
net stop winnat
# The Windows NAT Driver service was stopped successfully.
net start winnat
```
