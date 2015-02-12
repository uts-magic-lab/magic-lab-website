var express = require('express');
var morgan = require('morgan');
var app = express().use([
    morgan('dev'),
    express.static(__dirname+'/build')
]);
var host = process.env.OPENSHIFT_NODEJS_IP || '0.0.0.0';
var port = process.env.OPENSHIFT_NODEJS_PORT || 3000;
var server = app.listen(port, host, function(){
    console.log("HTTP server started on port", this.address().port);
});
