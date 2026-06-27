server {
	listen %ip%:%proxy_port%;
	server_name %domain_idn% %alias_idn%;
	error_log /var/log/%web_system%/domains/%domain%.error.log error;

	include %home%/%user%/web/%domain%/private/nodeapp/config/nodejs-app.conf;

	location /error/ {
		alias %home%/%user%/web/%domain%/document_errors/;
	}

	include %home%/%user%/web/%domain%/private/nodeapp/config/nodejs-app-fallback.conf;

	location ~ /\.(?!well-known\/|file) {
		deny all;
		return 404;
	}
}
