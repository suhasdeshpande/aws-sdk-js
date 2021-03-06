helpers = require('./helpers')
AWS = helpers.AWS

if AWS.util.isNode()
  describe 'AWS.NodeHttpClient', ->
    http = new AWS.NodeHttpClient()

    describe 'maxSockets delegation', ->
      it 'delegates maxSockets from agent to globalAgent', ->
        https = require('https')
        agent = http.sslAgent()
        https.globalAgent.maxSockets = 5
        expect(https.globalAgent.maxSockets).to.equal(agent.maxSockets)
        https.globalAgent.maxSockets += 1
        expect(https.globalAgent.maxSockets).to.equal(agent.maxSockets)

      it 'overrides globalAgent value if global is set to Infinity', ->
        https = require('https')
        agent = http.sslAgent()
        https.globalAgent.maxSockets = Infinity
        expect(agent.maxSockets).to.equal(50)

      it 'overrides globalAgent value if global is set to false', ->
        https = require('https')
        oldGlobal = https.globalAgent
        https.globalAgent = false
        agent = http.sslAgent()
        expect(agent.maxSockets).to.equal(50)
        https.globalAgent = oldGlobal

    describe 'handleRequest', ->
      it 'emits error event', (done) ->
        req = new AWS.HttpRequest 'http://invalid'
        http.handleRequest req, {}, null, (err) ->
          expect(err.code).to.equal('ENOTFOUND')
          done()

      it 'supports timeout in httpOptions', ->
        numCalls = 0
        req = new AWS.HttpRequest 'http://1.1.1.1'
        http.handleRequest req, {timeout: 1}, null, (err) ->
          numCalls += 1
          expect(err.code).to.equal('TimeoutError')
          expect(err.message).to.equal('Connection timed out after 1ms')
          expect(numCalls).to.equal(1)

      it 'converts strings to buffers', ->
        body = 'foo'
        req = {
          body: body,
          headers: {
            'Content-Length': '3'
          }
        }

        sent = null;
        fakeStream = {
          once: () -> {},
          emit: () -> {},
          end: (toSend) -> sent = toSend
        }

        http.writeBody(fakeStream, req);
        expect(sent).not.to.equal(body)
        expect(Buffer.isBuffer(sent)).to.equal(true)
