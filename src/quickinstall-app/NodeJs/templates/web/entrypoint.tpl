module.exports = {
	apps: [{
		name: '%app_name%',
		script: '%app_start_script%',
		cwd: '%app_cwd%',
		watch: false,
		env: {
			NODE_ENV: 'production',
		},
		error_file: '%app_cwd%/logs/error.log',
		out_file: '%app_cwd%/logs/out.log',
	}],
};
