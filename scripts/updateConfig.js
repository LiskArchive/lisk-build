var program = require('commander');
var fs = require('fs');
var path = require('path');
var extend = require('extend');

program
	.version('0.1.0')
	.option('-o, --old <path>', 'Old config.json')
	.option('-n, --new <path>', 'New config.json')
	.parse(process.argv);

var oldConfig, newConfig;

if (program.old) {
	oldConfig = JSON.parse(fs.readFileSync(program.old, 'utf8'));
	delete oldConfig.version;
	delete oldConfig.minVersion;
	delete oldConfig.forging.force;
	delete oldConfig.peers.list;

	if (oldConfig.db.user == null) {
		delete oldConfig.db.user;
	}
} else {
	console.log('Old config.json not provided, please populate entries manually');
	process.exit(1);
}

if (program.new) {
	newConfig = JSON.parse(fs.readFileSync(program.new, 'utf8'));
	newConfig = extend(true, {}, newConfig, oldConfig);

	// Migrate peers blacklist between <= 0.6.0 and >= 0.7.0
	if (newConfig.peers && newConfig.peers.access) {
		if (Array.isArray(newConfig.peers.blackList) && Array.isArray(newConfig.peers.access.blackList)) {
			newConfig.peers.access.blackList = newConfig.peers.blackList;
			delete newConfig.peers.blackList;
		}
	}

	fs.writeFile(program.new, JSON.stringify(newConfig, null, 4), function (err) {
		if (err) {
			throw err;
		}
	});
}
