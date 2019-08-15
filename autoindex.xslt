<?xml version="1.0" encoding="UTF-8" ?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" encoding="UTF-8" />

<xsl:template match="/">
  <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>

  <html>
    <head>
      <title>DropZone</title>
	<script src="https://kit.fontawesome.com/55eb9c16a8.js"></script>
	<script type="text/javascript"><![CDATA[
		document.addEventListener('DOMContentLoaded', function(){ 

		    function calculateSize(size)
		    {
			var sufixes = ['B', 'KB', 'MB', 'GB', 'TB'];
			var output = size;
			var q = 0;

			while (size / 1024 > 1)
			{
				size = size / 1024;
				q++;
			}

			return (Math.round(size * 100) / 100) + ' ' + sufixes[q];
		    }
    
		    if (window.location.pathname == '/')
		    {
		        document.querySelector('.directory.go-up').style.display = 'none';
		    }

                    var path = window.location.pathname.split('/');
                    var nav = document.querySelector("nav#breadcrumbs ul");
                    var pathSoFar = '';
		
                    for (var i=1; i<path.length-1; i++)
                    {
			pathSoFar += '/' + path[i];
                        nav.innerHTML += '<li><a href="' + encodeURI(pathSoFar)  + '">' + path[i] + '</a></li>';
                    }

		    var mtimes = document.querySelectorAll("table#contents td.mtime a");

		    for (var i=0; i<mtimes.length; i++)
		    {
		        var mtime = mtimes[i].textContent;
		        if (mtime)
		        {
		            var d = new Date(mtime);
		            mtimes[i].textContent = d.toLocaleString();
		        }
		    }

		    var sizes = document.querySelectorAll("table#contents td.size a");

		    for (var i=0; i<sizes.length; i++)
		    {
		        var size = sizes[i].textContent;
		        if (size)
		        {
		            sizes[i].textContent = calculateSize(parseInt(size));
		        }
		    }
		
		}, false);
	]]></script>

	<script type="text/javascript"><![CDATA[
		document.addEventListener("DOMContentLoaded", function() {
    
		    var dropArea = document.getElementById('droparea');
		    var progressWin = document.getElementById('progresswin');
		    var progressBar = document.getElementById('progressbar');
		    var progressTrack = [];
		    var totalFiles = 0;
            
		    ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
		        dropArea.addEventListener(eventName, function (e){
		            e.preventDefault();
		            e.stopPropagation();
		        }, false);
		    });

		    ['dragenter', 'dragover'].forEach(eventName => {
		        dropArea.addEventListener(eventName, function(e) {
		            dropArea.classList.add('highlight');
		        }, false);
		    });

		    ['dragleave', 'drop'].forEach(eventName => {
		        dropArea.addEventListener(eventName, function(e) {
		            dropArea.classList.remove('highlight')
		        }, false)
		    });

		    dropArea.addEventListener('drop', function(e) {
		        var total = 0;

		        for (var i=0; i<e.dataTransfer.files.length; i++) {
		            var file = e.dataTransfer.files[i];
		            progressTrack[i] = { current: 0, max: file.size };
		            total += file.size;
		            totalFiles++;
		            uploadFile(file, i);
		        }

		        progressBar.value = 0;
		        progressBar.max = total;
		        progressWin.classList.add('show');
		    }, false);

		    function updateProgress(value, idx) {
		        progressTrack[idx].value = value;

		        var current = 0;
		        for (var i=0; i<progressTrack.length; i++) {
		            current += progressTrack[i].value;
		        }

		        progressBar.value = current || progressBar.value;
		    }
    
		    function uploadFile(file, idx) {
		        var xhr = new XMLHttpRequest();
		        var formData = new FormData();

		        xhr.open('PUT', document.location.href + '/' + file.name, true);
		        xhr.upload.addEventListener("progress", function(e) {
		            updateProgress(e.loaded, idx);
		        });
        
		        xhr.addEventListener('readystatechange', function(e) {
		            if (xhr.readyState == 4 && (xhr.status == 200 || xhr.status == 201 || xhr.status == 204)) {
		                totalFiles--;
		            } else if (xhr.readyState == 4) {
		                alert (xhr.statusText);
		                totalFiles--;
		            }

		            if (totalFiles == 0) {
		                document.location.reload();
		            }
		        });

		        formData.append('file', file);
		        xhr.send(formData);
		    }
		});
	]]></script>

	<style type="text/css"><![CDATA[
		* { box-sizing: border-box; }
		html { margin: 0px; padding: 0px; height: 100%; width: 100%; }
		body { background-color: #303030; font-family: Verdana, Geneva, sans-serif; font-size: 14px; padding: 20px; margin: 0px; height: 100%; width: 100%; }

		table#contents td a { text-decoration: none; display: block; padding: 10px 30px 10px 30px; }
		table#contents { width: 50%; margin-left: auto; margin-right: auto; border-collapse: collapse; border-width: 0px; }
		table#contents td { padding: 0px; word-wrap: none; white-space: nowrap; }
		table#contents td.icon, table td.size, table td.mtime { width: 1px; }
		table#contents td.icon a { padding-left: 0px; padding-right: 5px; }
		table#contents td.name a { padding-left: 5px; }
		table#contents td.size a { color: #9e9e9e }
		table#contents td.mtime a { padding-right: 0px; color: #9e9e9e }
		table#contents tr * { color: #efefef; }
		table#contents tr:hover * { color: #c1c1c1 !important; }
		table#contents tr.directory td.icon i { color: #FBDD7C !important; }
		table#contents tr.directory.go-up td.icon i { color: #BF8EF3 !important; }
		table#contents tr.separator td { padding: 10px 30px 10px 30px }
		table#contents tr.separator td hr { display: none; }

		nav#breadcrumbs { margin-bottom: 50px; display: flex; justify-content: center; align-items: center; }
		nav#breadcrumbs ul { list-style: none; display: inline-block; margin: 0px; padding: 0px; }
		nav#breadcrumbs ul .icon { font-size: 14px; }
		nav#breadcrumbs ul li { float: left; }
		nav#breadcrumbs ul li a { color: #FFF; display: block; background: #515151; text-decoration: none; position: relative; height: 40px; line-height: 40px; padding: 0 10px 0 5px; text-align: center; margin-right: 23px; }
		nav#breadcrumbs ul li:nth-child(even) a { background-color: #525252; }
		nav#breadcrumbs ul li:nth-child(even) a:before { border-color: #525252; border-left-color: transparent; }
		nav#breadcrumbs ul li:nth-child(even) a:after { border-left-color: #525252; }
		nav#breadcrumbs ul li:first-child a { padding-left: 15px; -moz-border-radius: 4px 0 0 4px; -webkit-border-radius: 4px; border-radius: 4px 0 0 4px; }
		nav#breadcrumbs ul li:first-child a:before { border: none; }
		nav#breadcrumbs ul li:last-child a { padding-right: 15px; -moz-border-radius: 0 4px 4px 0; -webkit-border-radius: 0; border-radius: 0 4px 4px 0; }
		nav#breadcrumbs ul li:last-child a:after { border: none; }
		nav#breadcrumbs ul li a:before, nav#breadcrumbs ul li a:after { content: ""; position: absolute; top: 0; border: 0 solid #515151; border-width: 20px 10px; width: 0; height: 0; }
		nav#breadcrumbs ul li a:before { left: -20px; border-left-color: transparent; }
		nav#breadcrumbs ul li a:after { left: 100%; border-color: transparent; border-left-color: #515151; }
		nav#breadcrumbs ul li a:hover { background-color: #6320aa; }
		nav#breadcrumbs ul li a:hover:before { border-color: #6320aa; border-left-color: transparent; }
		nav#breadcrumbs ul li a:hover:after { border-left-color: #6320aa; }
		nav#breadcrumbs ul li a:active { background-color: #330860; }
		nav#breadcrumbs ul li a:active:before { border-color: #330860; border-left-color: transparent; }
		nav#breadcrumbs ul li a:active:after { border-left-color: #330860; }

		div#droparea { height: 100%; width: 100%; border: 5px solid transparent; padding: 10px; }
		div#droparea.highlight { border: 5px dashed #CACACA; }

		div#progresswin { position: absolute; left: 0px; top: 0px; width: 100%; height: 100%; background-color: rgba(0, 0, 0, 0.8); z-index: 10000; justify-content: center; align-items: center; display: none; }
		div#progresswin.show { display: flex !important; }
		div#progresswin progress#progressbar { width: 25%; }
	]]></style>
    </head>
    <body>
      <div id="progresswin">
        <progress id="progressbar"></progress>
      </div>
      <div id="droparea">
	      <nav id="breadcrumbs"><ul><li><a href="/"><i class="fa fa-home"></i></a></li></ul></nav>
	      <table id="contents">
	        <tbody>
	            <tr class="directory go-up">
	              <td class="icon"><a href="../"><i class="fa fa-arrow-up"></i></a></td>
	              <td class="name"><a href="../">..</a></td>
	              <td class="size"><a href="../"></a></td>
	              <td class="mtime"><a href="../"></a></td>
	            </tr>
	
	          <xsl:if test="count(list/directory) != 0">
	            <tr class="separator directories">
	              <td colspan="4"><hr/></td>
	            </tr>
	          </xsl:if>

	          <xsl:for-each select="list/directory">
	            <tr class="directory">
	              <td class="icon"><a href="{.}"><i class="fa fa-folder"></i></a></td>
	              <td class="name"><a href="{.}"><xsl:value-of select="." /></a></td>
	              <td class="size"><a href="{.}"></a></td>
	              <td class="mtime"><a href="{.}"><xsl:value-of select="./@mtime" /></a></td>
	            </tr>
	          </xsl:for-each>

	          <xsl:if test="count(list/file) != 0">
	            <tr class="separator files">
	              <td colspan="4"><hr/></td>
	            </tr>
	          </xsl:if>

	          <xsl:for-each select="list/file">
	            <tr class="file">
	              <td class="icon"><a href="{.}" download="{.}"><i class="fa fa-file"></i></a></td>
	              <td class="name"><a href="{.}" download="{.}"><xsl:value-of select="." /></a></td>
	              <td class="size"><a href="{.}" download="{.}"><xsl:value-of select="./@size" /></a></td>
	              <td class="mtime"><a href="{.}" download="{.}"><xsl:value-of select="./@mtime" /></a></td>
	            </tr>
	          </xsl:for-each>
	        </tbody>
	      </table>
	</div>
    </body>
  </html>
  </xsl:template>
</xsl:stylesheet>

