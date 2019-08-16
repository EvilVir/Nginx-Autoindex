# Nginx Autoindex
HTML5 replacement for default Nginx Autoindex directory browser. Zero dependencies other then few standard Nginx modules, no backend scripts nor apps. Supports file uploading via WebDav and HTML5 + AJAX drag and drop!

**Modern, clean look with breadcrumbs.**

![](https://github.com/EvilVir/Nginx-Autoindex/raw/master/p1.jpg)

**Upload multiple files without any backend, just WebDav & AJAX.**

![pic2](https://github.com/EvilVir/Nginx-Autoindex/raw/master/p2.jpg)

## Required Nginx modules
1. Ensure that you have [ngx_http_xslt_module](http://nginx.org/en/docs/http/ngx_http_xslt_module.html) (it can be also called ngx_http_xslt_filter_module, that's ok).
1. If you want to use upload functionality, you'll also need [ngx_http_dav_module](https://nginx.org/en/docs/http/ngx_http_dav_module.html).

Both are included in most of standard distributions out of the box, but you might need to initialize one or both of them them by using `load_module` directive in main `nginx.conf` file (place it outside any server, location or http block):

```
load_module "/etc/nginx/modules/ngx_http_xslt_filter_module.so";
```

## Instalation
1. Place `autoindex.xslt` file somewhere on your web server, it doesn't need to be in any www root directory, can be placed anywhere from where nginx daemon can read (in this documentation we assume that file is places under `/srv/autoindex.xslt`).
1. Configure location as follows:

```
    location / {
        root /srv/www/dropzone; # Change root to whatever you want
        autoindex on;
        autoindex_format xml;
        autoindex_exact_size off;
        autoindex_localtime off;

        xslt_stylesheet /srv/autoindex.xslt;
    }
```
1. Restart Nginx.

And that's it! You have now modern web directory browser enabled.

## Enabling uploads
For uploads to work you need to enable WebDav on the location, let's extend our example from above:

```
    location / {
        root /srv/www/dropzone; # Change root to whatever you want
        autoindex on;
        autoindex_format xml;
        autoindex_exact_size off;
        autoindex_localtime off;

        xslt_stylesheet /srv/autoindex.xslt;

	    client_body_temp_path /srv/temp; # Set to path where WebDav will save temporary files
	    dav_methods PUT;
        create_full_put_path on;
        dav_access group:rw all:r;
	    client_max_body_size 1000M; # Change this as you need
    }
```

And now just navigate to the location and drag-and-drop a file into browser's window. This feature should work in any modern web browser _(sorry IE fans)_.

### Hardening uploads
Of course allowing anybody to upload any file to your server isn't the best idea in the world, so you might want to think about adding at least [HTTP Basic Auth](https://en.wikipedia.org/wiki/.htpasswd):

```
    location / {
        root /srv/www/dropzone; # Change root to whatever you want
        autoindex on;
        autoindex_format xml;
        autoindex_exact_size off;
        autoindex_localtime off;

        xslt_stylesheet /srv/autoindex.xslt;

	    client_body_temp_path /srv/temp; # Set to path where WebDav will save temporary files
	    dav_methods PUT;
        create_full_put_path on;
        dav_access group:rw all:r;
	    client_max_body_size 1000M; # Change this as you need

        auth_basic "Please authenticate yourself";
        auth_basic_user_file /srv/.htpasswd; # Set to path where you keep your .htpasswd file
    }
```

## Credits

Based on [ngx-superbindex](https://github.com/gibatronic/ngx-superbindex) by [Gibran Malheiros](https://github.com/gibatronic).
