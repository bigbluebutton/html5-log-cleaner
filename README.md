
This cleans the html5 client logs by removing the escaping doe by nginx.

To run sending output to STDOUT

```
./html5-log-cleaner.rb testdata/jul-23-html5-client.log.1
```

Sending output to file. Make sure the directory is present.

```
LOG_PATH=log/foo.log ./html5-log-cleaner.rb testdata/jul-23-html5-client.log.1
```
