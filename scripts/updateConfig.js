var program = require('commander');
var fs = require('fs');
var path = require('path');

program
  .version('1.0.0')
  .option('-o, --old <path>', 'Old config.json')
  .option('-n, --new <path>', 'New config.json')
  .parse(process.argv);

var oldConfig;

if (program.old) {
        oldConfig = require(path.resolve(program.old));
} else {
        console.log('Old config.json not found, please populate entries manually');
        process.exit(1);
}


fs.readFile(program.new, 'utf8', function (err, data)  {
  if (err) {
    throw err;
  }
  var config = JSON.parse(data);
  config.port = oldConfig.port;
  config.address = oldConfig.address;
  config.fileLogLevel = oldConfig.fileLogLevel;
  config.logFileName = oldConfig.logFileName;
  config.consoleLogLevel = oldConfig.consoleLogLevel;
  config.trustProxy = oldConfig.trustProxy;
  config.api.access.whiteList = oldConfig.api.access.whiteList;
  config.forging.secret = oldConfig.forging.secret;
  config.forging.access.whitelist = oldConfig.forging.access.whitelist;
  config.ssl.enabled = oldConfig.ssl.enabled;
  config.ssl.options.port = oldConfig.ssl.options.port;
  config.ssl.options.address = oldConfig.ssl.options.address;
  config.ssl.options.key = oldConfig.ssl.options.key;
  config.ssl.options.cert = oldConfig.ssl.options.cert;
  config.dapp.masterrequired = oldConfig.dapp.masterrequired;
  config.dapp.masterpassword = oldConfig.dapp.masterpassword;
  config.dapp.autoexec = oldConfig.dapp.autoexec;

  fs.writeFile(program.new, JSON.stringify(config, null, 4), function (err) {
    if (err) {
      throw err;
    }
  });
});
