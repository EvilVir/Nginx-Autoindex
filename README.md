# Nginx Autoindex
HTML5 replacement for default Nginx Autoindex directory browser. Zero dependencies other then few standard Nginx modules, no backend scripts nor apps. Supports file uploading via WebDav and HTML5 + AJAX drag and drop!

**Modern, clean look with breadcrumbs.**

![](https://github.com/EvilVir/Nginx-Autoindex/raw/master/p1.jpg)

**Upload multiple files without any backend, just WebDav & AJAX.**

![pic2](https://github.com/EvilVir/Nginx-Autoindex/raw/master/p2.jpg)

## Required Nginx modules
1. Ensure that you have [ngx_http_xslt_module](http://nginx.org/en/docs/http/ngx_http_xslt_module.html) (it can be also called ngx_http_xslt_filter_module, that's ok).
1. If you want to use upload functionality, you'll also need [ngx_http_dav_module](https://nginx.org/en/docs/http/ngx_http_dav_module.html).

Both are included in most of standard distributions out of the box, but you might need to initialize one or both of them by using `load_module` directive in main `nginx.conf` file (place it outside any server, location or http block):

```
load_module "/etc/nginx/modules/ngx_http_xslt_filter_module.so";
```

## Instalation
1. Place `autoindex.xslt` file somewhere on your web server, it doesn't need to be in any www root directory, can be placed anywhere from where nginx daemon can read (in this documentation we assume that file is placed under `/srv/autoindex.xslt`).
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
3. Restart Nginx.

And that's it! You have now modern web directory browser enabled.

### Enabling uploads
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

## Advanced configuration (you can stop with config above if you want)

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

### Even fancier configuration
This is advanced configuration, that allows you to mix password secured and public folders. Only password secured folders will support uploads.

```
server {
    listen 80; # You might want to add SSL here :)

    server_name "your_servername.com"; # Configure this

    location ~* /(?<subpath>[^/]*)/?(?<file>.*)$ {
	    set $htaccess_user_file /srv/www/dropzone/$subpath/.htpasswd; # Set first part of the path to your root directory, leave `/$subpath/.htpasswd;` part

	    if (!-f $htaccess_user_file) {
	        return 599;
	    }

	    auth_basic "Please authenticate yourself";
	    auth_basic_user_file $htaccess_user_file;

	    client_body_temp_path /srv/temp;
	    dav_methods PUT;
	    create_full_put_path on;
	    dav_access group:rw all:r;
	    client_max_body_size 1000M; # Change this as you need

	    root /srv/www/dropzone; # Change root to whatever you want
	    autoindex on;
	    autoindex_format xml;
	    autoindex_exact_size off;
	    autoindex_localtime off;

	    xslt_stylesheet /srv/autoindex.xslt;
    }

    error_page 599 = @nosec;

    location @nosec {
        root /srv/www/dropzone; # Set to same root as location above
        autoindex on;
        autoindex_format xml;
        autoindex_exact_size off;
        autoindex_localtime off;

        xslt_stylesheet /srv/autoindex.xslt;
    }
}
```

What this configuration does is it looks for `.htpasswd` file in the first subfolder of the request path and if it finds it, then the password is required and WebDav enabled. If there is no `.htpasswd` file in first subfolder, then fallback to `@nosec` location is made and this one doesn't have WebDav (so no uploads) but still is nicely styled.

Note that only first subfolder is checked and then whole path upwards is secured. Placing `.htpassword` in any other sub-subfolder will not work as expected.

```
\
|- My Folder 1
    |- File1.txt
    |- File2.txt
    |- Sub Folder 1
        |- File3.txt
|        
|- My Secret Folder 1
    |- .htpasswd
    |- Presentation1.ppt
    |- My Secret Folder 2
        |- Presentation2.ppt
|
|- My Folder 3
    |- Music1.mp3
    |- Sub Folder 2
        |- .htpasswd
        |- Unsecured.mp3
```

In example above `My Folder 1` is standard folder with public access (no `.htpasswd` anywhere in the path). 

`My Secret Folder 1` has `.htpasswd` inside so access to this location will require authentication, as well as access to `My Secret Folder 2` and anything inside it.

`My Folder 3` is again standard folder with public access. There is `.htpasswd` in `Sub Folder 2` but it isn't used so access to `Unsecured.mp3` is still public.

## Credits

Based on [ngx-superbindex](https://github.com/gibatronic/ngx-superbindex) by [Gibran Malheiros](https://github.com/gibatronic).
