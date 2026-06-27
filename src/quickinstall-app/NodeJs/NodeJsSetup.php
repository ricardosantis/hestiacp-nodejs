<?php

namespace Hestia\WebApp\Installers\NodeJs;

use Hestia\WebApp\Installers\BaseSetup as BaseSetup;
use Hestia\WebApp\Installers\NodeJs\NodeJsUtils\NodeJsPaths as NodeJsPaths;
use Hestia\WebApp\Installers\NodeJs\NodeJsUtils\NodeJsUtil as NodeJsUtil;
use Hestia\System\HestiaApp;

class NodeJsSetup extends BaseSetup {

	protected const TEMPLATE_PROXY_VARS = ['%nginx_port%'];
	protected const TEMPLATE_ENTRYPOINT_VARS = ['%app_name%', '%app_start_script%', '%app_cwd%'];

	protected $nodeJsPaths;
	protected $nodeJsUtils;

	protected $appInfo = [
		'name' => 'NodeJs',
		'group' => 'node',
		'enabled' => true,
		'version' => '1.0.0',
		'thumbnail' => 'nodejs.png',
	];

	protected $appname = 'NodeJs';

	protected $config = [
		'form' => [
			'node_version' => [
				'type' => 'select',
				'options' => ['v22.14.0', 'v20.20.0', 'v18.20.0', 'v16.20.2'],
			],
			'install_sample' => [
				'type' => 'boolean',
				'label' => 'Install sample app (Hello World)',
				'value' => 'true',
			],
			'php_notice' => [
				'type' => 'boolean',
				'label' => 'Ignore PHP version below — Node.js does not use PHP',
				'value' => 'yes',
			],
		],
		'database' => false,
		'server' => [
			'php' => [
				'supported' => [
					'5.6', '7.0', '7.1', '7.2', '7.3', '7.4',
					'8.0', '8.1', '8.2', '8.3', '8.4',
				],
			],
		],
	];

	public function info() {
		$this->appInfo["enabled"] = true;
		$this->appInfo["php_support"] = [
			'5.6', '7.0', '7.1', '7.2', '7.3', '7.4',
			'8.0', '8.1', '8.2', '8.3', '8.4',
		];
		return $this->appInfo;
	}

	public function __construct($domain, HestiaApp $appcontext) {
		parent::__construct($domain, $appcontext);
		$this->nodeJsPaths = new NodeJsPaths($appcontext);
		$this->nodeJsUtils = new NodeJsUtil($appcontext);
	}

	public function install(array $options = null) {
		if (empty($options['start_script'])) {
			$options['start_script'] = 'app.js';
		}
		if (empty($options['port'])) {
			$options['port'] = '3000';
		}

		$this->createAppDir();
		$this->createConfDir();
		$this->createAppEntryPoint($options);
		$this->createAppNvmVersion($options);
		$this->createAppEnv($options);
		$this->createAppProxyTemplates($options);
		$this->createAppConfig($options);

		if (!empty($options['install_sample'])) {
			$this->installSampleApp();
		}

		$this->setProxyTemplate();
		$this->pm2StartApp();

		return true;
	}

	public function installSampleApp() {
		$sampleDir = __DIR__ . '/sample-app';
		$appDir = $this->nodeJsPaths->getAppDir($this->domain);

		$publicDir = $this->nodeJsPaths->getAppDir($this->domain, 'public');
		if (!is_dir($publicDir)) {
			$this->nodeJsUtils->createDir($publicDir);
		}

		$files = ['package.json', 'app.js', 'public/index.html'];

		foreach ($files as $file) {
			$srcFile = $sampleDir . '/' . $file;
			if (!file_exists($srcFile)) {
				continue;
			}

			$tmpFile = $this->saveTempFile(file_get_contents($srcFile));
			$this->nodeJsUtils->moveFile($tmpFile, $appDir . '/' . $file);
		}
	}

	public function createAppEntryPoint(array $options = null) {
		$templateReplaceVars = [
			$this->domain,
			trim($options['start_script']),
			$this->nodeJsPaths->getAppDir($this->domain),
		];

		$data = $this->nodeJsUtils->parseTemplate(
			$this->nodeJsPaths->getAppEntrypointTemplate(),
			self::TEMPLATE_ENTRYPOINT_VARS,
			$templateReplaceVars,
		);
		$tmpFile = $this->saveTempFile(implode($data));

		return $this->nodeJsUtils->moveFile(
			$tmpFile,
			$this->nodeJsPaths->getAppEntryPoint($this->domain),
		);
	}

	public function createAppNvmVersion($options) {
		$tmpFile = $this->saveTempFile($options['node_version']);
		return $this->nodeJsUtils->moveFile(
			$tmpFile,
			$this->nodeJsPaths->getAppDir($this->domain, '.nvmrc'),
		);
	}

	public function createAppEnv($options) {
		$data = 'PORT="' . trim($options['port']) . '"' . PHP_EOL;
		$data .= 'HOST="127.0.0.1"' . PHP_EOL;
		$data .= 'NODE_ENV="production"' . PHP_EOL;

		$tmpFile = $this->saveTempFile($data);
		return $this->nodeJsUtils->moveFile(
			$tmpFile,
			$this->nodeJsPaths->getAppDir($this->domain, '.env'),
		);
	}

	public function createAppProxyTemplates(array $options = null) {
		$tplReplace = [trim($options['port'])];

		$proxyData = $this->nodeJsUtils->parseTemplate(
			$this->nodeJsPaths->getNodeJsProxyTemplate(),
			self::TEMPLATE_PROXY_VARS,
			$tplReplace,
		);
		$proxyFallbackData = $this->nodeJsUtils->parseTemplate(
			$this->nodeJsPaths->getNodeJsProxyFallbackTemplate(),
			self::TEMPLATE_PROXY_VARS,
			$tplReplace,
		);

		$tmpProxyFile = $this->saveTempFile(implode($proxyData));
		$tmpProxyFallbackFile = $this->saveTempFile(implode($proxyFallbackData));

		$this->nodeJsUtils->moveFile(
			$tmpProxyFile,
			$this->nodeJsPaths->getAppProxyConfig($this->domain),
		);
		$this->nodeJsUtils->moveFile(
			$tmpProxyFallbackFile,
			$this->nodeJsPaths->getAppProxyFallbackConfig($this->domain),
		);
	}

	public function createAppConfig(array $options = null) {
		$config = 'PORT=' . trim($options['port']) . '|';
		$config .= 'START_SCRIPT="' . trim($options['start_script']) . '"|';
		$config .= 'NODE_VERSION=' . trim($options['node_version']);
		$file = $this->saveTempFile($config);
		return $this->nodeJsUtils->moveFile(
			$file,
			$this->nodeJsPaths->getConfigFile($this->domain),
		);
	}

	public function createAppDir() {
		$this->nodeJsUtils->createDir($this->nodeJsPaths->getAppDir($this->domain));
	}

	public function createConfDir() {
		$this->nodeJsUtils->createDir($this->nodeJsPaths->getConfigDir($this->domain));
	}

	public function setProxyTemplate() {
		$this->appcontext->runUser('v-change-web-domain-proxy-tpl', [$this->domain, 'NodeJS']);
	}

	public function pm2StartApp() {
		return $this->appcontext->runUser(
			'v-add-pm2-app',
			[$this->domain, $this->nodeJsPaths->getAppEntryPointFileName()],
		);
	}
}
