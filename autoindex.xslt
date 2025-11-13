<?xml version="1.0" encoding="UTF-8" ?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:D="DAV:" exclude-result-prefixes="D">
<xsl:output method="html" encoding="UTF-8" />

<xsl:template match="D:multistatus">
	<xsl:text disable-output-escaping="yes">&lt;?xml version="1.0" encoding="utf-8" ?&gt;</xsl:text>
	<D:multistatus xmlns:D="DAV:">
		<xsl:copy-of select="*"/>
	</D:multistatus>
</xsl:template>

<xsl:template match="/list">
  <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>

  <html>
    <head>
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
			pathSoFar += '/' + decodeURI(path[i]);
                        nav.innerHTML += '<li><a href="' + encodeURI(pathSoFar)  + '">' + decodeURI(path[i]) + '</a></li>';
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

		    var xhr = new XMLHttpRequest();
		    xhr.open('GET', document.location, true);
		    xhr.send(null);

                    xhr.addEventListener('readystatechange', function(e) {
			if (xhr.readyState == 4) {
			    var headers = parseHttpHeaders(xhr.getAllResponseHeaders().toLowerCase());

			    if (!headers.hasOwnProperty('x-options')){
				document.body.classList.add('nowebdav');
			    }
			}
                    });
    
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
		        }, false);
		    });

		    document.querySelectorAll('table#contents tr td.actions ul li a[data-action]').forEach(el => {
			el.addEventListener('click', function(e) {
                            e.preventDefault();
                            e.stopPropagation();

			    var source = event.target || event.srcElement;
			    var action = source.getAttribute('data-action');
			    var href = source.getAttribute('href');

			    if (action == 'delete') {
				deleteFile(href);
			    }

			}, false);
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
		                console.log(xhr);
		                totalFiles--;
		            }

		            if (totalFiles == 0) {
		                document.location.reload();
		            }
		        });

		        xhr.setRequestHeader('Content-Type', 'application/octet-stream');
		        xhr.send(file);
		    }

		    function deleteFile(path) {
			if (confirm('Are you sure you want to delete [' + path + ']?')) {
				var xhr = new XMLHttpRequest();
				xhr.open('DELETE', document.location.href + '/' + path, true);
				xhr.send();
	                        xhr.addEventListener('readystatechange', function(e) {

                        	        if (xhr.readyState == 4 && (xhr.status == 200 || xhr.status == 201 || xhr.status == 204)) {
	        	                        document.location.reload();
		                        }
	                        });
			}
  		    }

		    function parseHttpHeaders(httpHeaders) {
			return httpHeaders.split("\n").map(x=>x.split(/: */,2)).filter(x=>x[0]).reduce((ac, x)=>{ac[x[0]] = x[1];return ac;}, {});
		    }
		});
	]]></script>

	<style type="text/css"><![CDATA[
		@font-face {
		font-family: 'glyphs';
		src: url('data:font/eof;base64,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') format('embedded-opentype'),
			url('data:font/woff;base64,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') format('woff'),
			url('data:font/ttf;base64,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I0KxDABCsAtDKyCwYFBYILBAUVizBCAFIBuzBCYFGllCQiMgR7AGQ7ACYiCwAFBYsEBgWWawAWNgILABKyCKimEgsARDYGQjsAVDYWRQWLAEQ2EbsAVDYFmwAyWwAmIgsABQWLBAYFlmsAFjYbACJUZhOCMgPCM4GyEgIEYjR7ABKyNhOCFZsTABFCstsEcssQA6Ky6xMAEUKy2wSCyxADsrISMgIDywBiNCIzixMAEUK7AGQy6wMCstsEkssAAVIEewACNCsgABARUUEy6wNiotsEossAAVIEewACNCsgABARUUEy6wNiotsEsssQABFBOwNyotsEwssDkqLbBNLLAAFkUjIC4gRoojYTixMAEUKy2wTiywCiNCsE0rLbBPLLIAAEYrLbBQLLIAAUYrLbBRLLIBAEYrLbBSLLIBAUYrLbBTLLIAAEcrLbBULLIAAUcrLbBVLLIBAEcrLbBWLLIBAUcrLbBXLLMAAABDKy2wWCyzAAEAQystsFksswEAAEMrLbBaLLMBAQBDKy2wWyyzAAABQystsFwsswABAUMrLbBdLLMBAAFDKy2wXiyzAQEBQystsF8ssgAARSstsGAssgABRSstsGEssgEARSstsGIssgEBRSstsGMssgAASCstsGQssgABSCstsGUssgEASCstsGYssgEBSCstsGcsswAAAEQrLbBoLLMAAQBEKy2waSyzAQAARCstsGosswEBAEQrLbBrLLMAAAFEKy2wbCyzAAEBRCstsG0sswEAAUQrLbBuLLMBAQFEKy2wbyyxADwrLrEwARQrLbBwLLEAPCuwQCstsHEssQA8K7BBKy2wciywABaxADwrsEIrLbBzLLEBPCuwQCstsHQssQE8K7BBKy2wdSywABaxATwrsEIrLbB2LLEAPSsusTABFCstsHcssQA9K7BAKy2weCyxAD0rsEErLbB5LLEAPSuwQistsHossQE9K7BAKy2weyyxAT0rsEErLbB8LLEBPSuwQistsH0ssQA+Ky6xMAEUKy2wfiyxAD4rsEArLbB/LLEAPiuwQSstsIAssQA+K7BCKy2wgSyxAT4rsEArLbCCLLEBPiuwQSstsIMssQE+K7BCKy2whCyxAD8rLrEwARQrLbCFLLEAPyuwQCstsIYssQA/K7BBKy2whyyxAD8rsEIrLbCILLEBPyuwQCstsIkssQE/K7BBKy2wiiyxAT8rsEIrLbCLLLILAANFUFiwBhuyBAIDRVgjIRshWVlCK7AIZbADJFB4sQUBFUVYMFktAEu4AMhSWLEBAY5ZsAG5CAAIAGNwsQAHQrEAACqxAAdCsQAKKrEAB0KxAAoqsQAHQrkAAAALKrEAB0K5AAAACyq5AAMAAESxJAGIUViwQIhYuQADAGREsSgBiFFYuAgAiFi5AAMAAERZG7EnAYhRWLoIgAABBECIY1RYuQADAABEWVlZWVmxAA4quAH/hbAEjbECAESzBWQGAERE') format('truetype'),
			url('data:font/svg;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBzdGFuZGFsb25lPSJubyI/Pgo8IURPQ1RZUEUgc3ZnIFBVQkxJQyAiLS8vVzNDLy9EVEQgU1ZHIDEuMS8vRU4iICJodHRwOi8vd3d3LnczLm9yZy9HcmFwaGljcy9TVkcvMS4xL0RURC9zdmcxMS5kdGQiPgo8c3ZnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxtZXRhZGF0YT5Db3B5cmlnaHQgKEMpIDIwMjUgYnkgb3JpZ2luYWwgYXV0aG9ycyBAIGZvbnRlbGxvLmNvbTwvbWV0YWRhdGE+CjxkZWZzPgo8Zm9udCBpZD0iZ2x5cGhzIiBob3Jpei1hZHYteD0iMTAwMCIgPgo8Zm9udC1mYWNlIGZvbnQtZmFtaWx5PSJnbHlwaHMiIGZvbnQtd2VpZ2h0PSI0MDAiIGZvbnQtc3RyZXRjaD0ibm9ybWFsIiB1bml0cy1wZXItZW09IjEwMDAiIGFzY2VudD0iODUwIiBkZXNjZW50PSItMTUwIiAvPgo8bWlzc2luZy1nbHlwaCBob3Jpei1hZHYteD0iMTAwMCIgLz4KPGdseXBoIGdseXBoLW5hbWU9InVwLWJpZyIgdW5pY29kZT0iJiN4ZTgwMDsiIGQ9Ik04OTkgMzA4cTAtMjgtMjEtNTBsLTQxLTQycS0yMi0yMS01MS0yMS0zMCAwLTUwIDIxbC0xNjUgMTY0di0zOTNxMC0yOS0yMC00N3QtNTEtMTloLTcxcS0zMCAwLTUxIDE5dC0yMSA0N3YzOTNsLTE2NC0xNjRxLTIwLTIxLTUwLTIxdC01MCAyMWwtNDIgNDJxLTIxIDIxLTIxIDUwIDAgMzAgMjEgNTFsMzYzIDM2M3EyMCAyMSA1MCAyMSAzMCAwIDUxLTIxbDM2My0zNjNxMjEtMjIgMjEtNTF6IiBob3Jpei1hZHYteD0iOTI4LjYiIC8+Cgo8Z2x5cGggZ2x5cGgtbmFtZT0iZm9sZGVyIiB1bmljb2RlPSImI3hlODAxOyIgZD0iTTkyOSA1MTF2LTM5M3EwLTUxLTM3LTg4dC04OC0zN2gtNjc5cS01MSAwLTg4IDM3dC0zNyA4OHY1MzZxMCA1MSAzNyA4OHQ4OCAzN2gxNzlxNTEgMCA4OC0zN3QzNy04OHYtMThoMzc1cTUxIDAgODgtMzd0MzctODh6IiBob3Jpei1hZHYteD0iOTI4LjYiIC8+Cgo8Z2x5cGggZ2x5cGgtbmFtZT0iaG9tZSIgdW5pY29kZT0iJiN4ZTgwYTsiIGQ9Ik03ODYgMjk2di0yNjdxMC0xNS0xMS0yNXQtMjUtMTFoLTIxNHYyMTRoLTE0M3YtMjE0aC0yMTRxLTE1IDAtMjUgMTF0LTExIDI1djI2N3EwIDEgMCAydDAgMmwzMjEgMjY0IDMyMS0yNjRxMS0xIDEtNHogbTEyNCAzOWwtMzQtNDFxLTUtNS0xMi02aC0ycS03IDAtMTIgM2wtMzg2IDMyMi0zODYtMzIycS03LTQtMTMtMy03IDEtMTIgNmwtMzUgNDFxLTQgNi0zIDEzdDYgMTJsNDAxIDMzNHExOCAxNSA0MiAxNXQ0My0xNWwxMzYtMTEzdjEwOHEwIDggNSAxM3QxMyA1aDEwN3E4IDAgMTMtNXQ1LTEzdi0yMjdsMTIyLTEwMnE2LTQgNi0xMnQtNC0xM3oiIGhvcml6LWFkdi14PSI5MjguNiIgLz4KCjxnbHlwaCBnbHlwaC1uYW1lPSJkb2MtaW52IiB1bmljb2RlPSImI3hmMTViOyIgZD0iTTU3MSA1NjR2MjY0cTEzLTggMjEtMTZsMjI3LTIyOHE4LTcgMTYtMjBoLTI2NHogbS03MS0xOHEwLTIyIDE2LTM3dDM4LTE2aDMwM3YtNTg5cTAtMjMtMTUtMzh0LTM4LTE2aC03NTBxLTIzIDAtMzggMTZ0LTE2IDM4djg5MnEwIDIzIDE2IDM4dDM4IDE2aDQ0NnYtMzA0eiIgaG9yaXotYWR2LXg9Ijg1Ny4xIiAvPgoKPGdseXBoIGdseXBoLW5hbWU9InRyYXNoIiB1bmljb2RlPSImI3hmMWY4OyIgZD0iTTI4NiA4MnYzOTNxMCA4LTUgMTN0LTEzIDVoLTM2cS04IDAtMTMtNXQtNS0xM3YtMzkzcTAtOCA1LTEzdDEzLTVoMzZxOCAwIDEzIDV0NSAxM3ogbTE0MyAwdjM5M3EwIDgtNSAxM3QtMTMgNWgtMzZxLTggMC0xMy01dC01LTEzdi0zOTNxMC04IDUtMTN0MTMtNWgzNnE4IDAgMTMgNXQ1IDEzeiBtMTQyIDB2MzkzcTAgOC01IDEzdC0xMiA1aC0zNnEtOCAwLTEzLTV0LTUtMTN2LTM5M3EwLTggNS0xM3QxMy01aDM2cTcgMCAxMiA1dDUgMTN6IG0tMzAzIDU1NGgyNTBsLTI3IDY1cS00IDUtOSA2aC0xNzdxLTYtMS0xMC02eiBtNTE4LTE4di0zNnEwLTgtNS0xM3QtMTMtNWgtNTR2LTUyOXEwLTQ2LTI2LTgwdC02My0zNGgtNDY0cS0zNyAwLTYzIDMzdC0yNyA3OXY1MzFoLTUzcS04IDAtMTMgNXQtNSAxM3YzNnEwIDggNSAxM3QxMyA1aDE3MmwzOSA5M3E5IDIxIDMxIDM1dDQ0IDE1aDE3OHEyMyAwIDQ0LTE1dDMwLTM1bDM5LTkzaDE3M3E4IDAgMTMtNXQ1LTEzeiIgaG9yaXotYWR2LXg9Ijc4NS43IiAvPgo8L2ZvbnQ+CjwvZGVmcz4KPC9zdmc+Cg==') format('svg');
		font-weight: normal;
		font-style: normal;
		}

		* { box-sizing: border-box; }
		html { margin: 0px; padding: 0px; height: 100%; width: 100%; }
		body { background-color: #303030; font-family: Verdana, Geneva, sans-serif; font-size: 14px; padding: 20px; margin: 0px; height: 100%; width: 100%; }

		table#contents td a { text-decoration: none; display: block; padding: 10px 30px 10px 30px; pointer: default; }
		table#contents { width: 50%; margin-left: auto; margin-right: auto; border-collapse: collapse; border-width: 0px; }
		table#contents td { padding: 0px; word-wrap: none; white-space: nowrap; }
		table#contents td.icon, table td.size, table td.mtime, table td.actions { width: 1px; white-space: nowrap; }
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
		table#contents tr td.actions ul { list-style-type: none; margin: 0px; padding: 0px; visibility: hidden; }
		table#contents tr td.actions ul li { float: left; }
		table#contents tr:hover td.actions ul { visibility: visible; }
		table#contents tr td.actions ul li a { display: inline; padding: 10px 10px 10px 10px !important; }
		table#contents tr td.actions ul li a:hover[data-action='delete'] { color: #c90000 !important; }
		body.nowebdav table#contents tr td.actions ul { display: none !important; }

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

		.icon { font-family: "glyphs"; font-style: normal; font-weight: normal; speak: never; display: inline-block; text-decoration: inherit; width: 1em; margin-right: .4em; text-align: center; font-variant: normal; text-transform: none; line-height: 1em; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; }
		.icon-file { font-size: 1em }
		.icon-folder { font-size: 1.1em }
		.icon-up { font-size: 1.1em }
		.icon-trash { font-size: 1.1em }
	]]></style>
    </head>
    <body>
      <div id="progresswin">
        <progress id="progressbar"></progress>
      </div>
      <div id="droparea">
	      <nav id="breadcrumbs"><ul><li><a href="/"><i class="icon icon-home">&#xe80a;</i></a></li></ul></nav>
	      <table id="contents">
	        <tbody>
	            <tr class="directory go-up">
	              <td class="icon"><a href="../"><i class="icon icon-up">&#xe800;</i></a></td>
	              <td class="name"><a href="../">..</a></td>
	              <td class="size"><a href="../"></a></td>
	              <td class="mtime"><a href="../"></a></td>
                      <td class="actions"><a href="../"></a></td>
	            </tr>
	
	          <xsl:if test="count(directory) != 0">
	            <tr class="separator directories">
	              <td colspan="4"><hr/></td>
	            </tr>
	          </xsl:if>

	          <xsl:for-each select="directory">
	            <tr class="directory">
	              <td class="icon"><a href="{.}/"><i class="icon icon-folder">&#xe801;</i></a></td>
	              <td class="name"><a href="{.}/"><xsl:value-of select="." /></a></td>
	              <td class="size"><a href="{.}/"></a></td>
	              <td class="mtime"><a href="{.}/"><xsl:value-of select="./@mtime" /></a></td>
		      <td class="actions"><a href="{.}/"></a></td>
	            </tr>
	          </xsl:for-each>

	          <xsl:if test="count(file) != 0">
	            <tr class="separator files">
	              <td colspan="4"><hr/></td>
	            </tr>
	          </xsl:if>

	          <xsl:for-each select="file">
	            <tr class="file">
	              <td class="icon"><a href="{.}" download="{.}"><i class="icon icon-file">&#xf15b;</i></a></td>
	              <td class="name"><a href="{.}" download="{.}"><xsl:value-of select="." /></a></td>
	              <td class="size"><a href="{.}" download="{.}"><xsl:value-of select="./@size" /></a></td>
	              <td class="mtime"><a href="{.}" download="{.}"><xsl:value-of select="./@mtime" /></a></td>
                      <td class="actions">
			<ul>
				<li><a href="{.}" data-action="delete" class="icon icon-trash">&#xf1f8;</a></li>
			</ul>
		      </td>
	            </tr>
	          </xsl:for-each>
	        </tbody>
	      </table>
	</div>
    </body>
  </html>
  </xsl:template>
</xsl:stylesheet>
