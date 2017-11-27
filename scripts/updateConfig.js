/*
 * LiskHQ/lisk-build
 * Copyright © 2017 Lisk Foundation
 *
 * See the LICENSE file at the top-level directory of this distribution
 * for licensing information.
 *
 * Unless otherwise agreed in a custom licensing agreement with the Lisk Foundation,
 * no part of this software, including this file, may be copied, modified,
 * propagated, or distributed except according to the terms contained in the
 * LICENSE file.
 *
 * Removal or modification of this copyright notice is prohibited.
 */

var program = require('commander');
var fs = require('fs');
var path = require('path');
var extend = require('extend');

program
	.version('0.1.1')
	.option('-o, --old <path>', 'Old config.json')
	.option('-n, --new <path>', 'New config.json')
	.parse(process.argv);

var oldConfig, newConfig;

if (program.old) {
	oldConfig = JSON.parse(fs.readFileSync(program.old, 'utf8'));
	delete oldConfig.version;
	delete oldConfig.minVersion;
	delete oldConfig.consoleLogLevel;
	delete oldConfig.fileLogLevel;
	delete oldConfig.forging.force;
	delete oldConfig.peers.list;

	if (oldConfig.db.user == null) {
		delete oldConfig.db.user;
	}
} else {
	console.log('Previous config.json not found, exiting.');
	process.exit(1);
}

if (program.new) {
	newConfig = JSON.parse(fs.readFileSync(program.new, 'utf8'));
	newConfig = extend(true, {}, newConfig, oldConfig);

	fs.writeFile(program.new, JSON.stringify(newConfig, null, 4), function (err) {
		if (err) {
			throw err;
		}
	});
}
