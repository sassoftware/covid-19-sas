const { createProxyMiddleware } = require('http-proxy-middleware');
const body = require('body')

const sasVersion = process.env.SASVER
const sasHost = process.env.SASHOST
const sasHttps = process.env.HTTPS || "false"
const devPort  = process.env.PORT || "3000"


var targetProtocol = 'http'
if (sasHttps.toLowerCase() === 'true') {
  targetProtocol = 'https'
}

let fullHostname = targetProtocol + '://' + sasHost

module.exports = function(app) {
    app.use(
        ['/identities', '/SAS*', '/folders', '/files'],
        createProxyMiddleware({
            target: fullHostname,
            logLevel: 'debug',
            changeOrigin: false,
            autoRewrite: true,
            hostRewrite: false,
            protocolRewrite: false,
            headers: {
                Host: sasHost,
                Origin: fullHostname,
            },
            cookieDomainRewrite:  "localhost",
            router: {
                fullHostname : targetProtocol + '://localhost:' + devPort ,
            },
            
            onProxyReq: function onProxyReq(proxyReq, req, res) {

                // Log outbound request to remote target
               
                console.log('[REQUEST] -> ', req.hostname, req.method, req.path);
                console.log('[REQUEST BODY] -> ');
                body(req, res, function(err, body){
                  if (err) console.error(err)
                  console.log(body)
                })

                // and clean up some confusing headers 
                proxyReq.removeHeader('Referer');
                proxyReq.removeHeader('Origin');
            },
        })
        );
    };
