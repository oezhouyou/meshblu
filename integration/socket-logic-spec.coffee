_ = require 'lodash'
path = require 'path'
meshblu = require 'meshblu'
MeshbluConfig = require 'meshblu-config'

describe 'SocketLogic Events', ->
  before (done) ->
    filename = path.join __dirname, 'meshblu.json'
    @config = new MeshbluConfig(filename: filename).toJSON()
    @eventForwarder = meshblu.createConnection
      server : @config.server
      port   : @config.port
      uuid   : @config.uuid
      token  : @config.token

    @eventForwarder.on 'ready', => done()
    @eventForwarder.on 'notReady', done

  before (done) ->
    @meshblu = meshblu.createConnection _.pick(@config, 'server', 'port')
    @meshblu.once 'ready', (@device) => done()
    @meshblu.on 'notReady', done

  it 'should get here', ->
    expect(true).to.be.true

  describe 'EVENT devices', ->
    describe 'when called with a valid request', ->
      beforeEach (done) ->
        @meshblu.devices {}, (data) =>
          return done new Error(data.error) if data.error?
          @eventForwarder.once 'message', (@message) =>
            done()

      it 'should send a "devices" message', ->
        expect(@message.topic).to.deep.equal 'devices'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromUuid: @device.uuid
          request: {}
        }

    describe 'when called with an invalid request', ->
      beforeEach (done) ->
        @meshblu.devices {uuid: 'invalid-uuid'}, =>
          @eventForwarder.once 'message', (@message) =>
            done()

      it 'should send a "devices-error" message', ->
        expect(@message.topic).to.deep.equal 'devices-error'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromUuid: @device.uuid
          error: "Devices not found"
          request:
            uuid: 'invalid-uuid'
        }

  describe 'EVENT device', ->
    describe 'when called with a valid request', ->
      beforeEach (done) ->
        @meshblu.device {uuid: @device.uuid}, (data) =>
          return done new Error(data.error) if data.error?
          @eventForwarder.once 'message', (@message) =>
            done()

      it 'should send a "devices" message', ->
        expect(@message.topic).to.deep.equal 'devices'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromUuid: @device.uuid
          request:
            uuid: @device.uuid
        }

    describe 'when called with an invalid request', ->
      beforeEach (done) ->
        @meshblu.device {uuid: 'invalid-uuid'}, (data) =>
          return done new Error(data.error) if data.error?
          @eventForwarder.once 'message', (@message) =>
            done()

      it 'should send a "devices-error" message', ->
        expect(@message.topic).to.deep.equal 'devices-error'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromUuid: @device.uuid
          error: "Devices not found"
          request:
            uuid: 'invalid-uuid'
        }

  describe 'EVENT whoami', ->
    describe 'when called with a valid request', ->
      beforeEach (done) ->
        @meshblu.whoami {}, (data) =>
          return done new Error(data.error) if data.error?
          @eventForwarder.once 'message', (@message) =>
            done()

      it 'should send a "whoami" message', ->
        expect(@message.topic).to.deep.equal 'whoami'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromUuid: @device.uuid
          request: {}
        }

  describe 'EVENT update', ->
    describe 'when called with a valid request', ->
      beforeEach (done) ->
        @meshblu.update uuid: @device.uuid, foo: 'bar', (data) =>
          return done new Error(data.error) if data.error?
          @eventForwarder.once 'message', (@message) =>
            done()

      it 'should send a "update" message', ->
        expect(@message.topic).to.deep.equal 'update'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromUuid: @device.uuid
          request:
            query: {uuid: @device.uuid}
            params: {$set: {foo: 'bar', uuid: @device.uuid}}
        }

    describe 'when called with an invalid request', ->
      beforeEach (done) ->
        @meshblu.update uuid: 'invalid-uuid', foo: 'bar', (error) =>
          @eventForwarder.once 'message', (@message) =>
            done()

      it 'should send an "update-error" message', ->
        expect(@message.topic).to.deep.equal 'update-error'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromUuid: @device.uuid
          error: "Device not found"
          request:
            query: {uuid: 'invalid-uuid'}
            params: {$set: {foo: 'bar', uuid: 'invalid-uuid'}}
        }

  describe 'EVENT localdevices', ->
    describe 'when called with a valid request', ->
      beforeEach (done) ->
        @meshblu.localdevices (error) =>
          @eventForwarder.once 'message', (@message) =>
            done()

      it 'should send a "localdevices" message', ->
        expect(@message.topic).to.deep.equal 'localdevices'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromIp: '127.0.0.1'
          fromUuid: @device.uuid
          request: {}
        }

  describe 'EVENT unclaimeddevices', ->
    describe 'when called with a valid request', ->
      beforeEach (done) ->
        @meshblu.unclaimeddevices {}, (error) =>
          @eventForwarder.once 'message', (@message) =>
            done()

      it 'should send a "unclaimeddevices" message', ->
        expect(@message.topic).to.deep.equal 'unclaimeddevices'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromIp: '127.0.0.1'
          fromUuid: @device.uuid
          request: {}
        }

    describe 'when called with an invalid request', ->
      beforeEach (done) ->
        @meshblu.unclaimeddevices {uuid: 'invalid-uuid'}, (error) =>
          @eventForwarder.once 'message', (@message) =>
            done()

      it 'should send an "unclaimeddevices-error" message', ->
        expect(@message.topic).to.deep.equal 'unclaimeddevices-error'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromUuid: @device.uuid
          fromIp: "127.0.0.1"
          error: "Devices not found"
          request:
            uuid: 'invalid-uuid'
        }

  describe 'EVENT claimdevice', ->
    describe 'when called with a valid request', ->
      beforeEach (done) ->
        @meshblu.register configWhitelist: ['*'], (data) =>
          return done new Error data.error if data.error?

          @newDevice = data
          @meshblu.claimdevice uuid: @newDevice.uuid, (data) =>
            return done new Error data.error if data.error?
            @eventForwarder.once 'message', (@message) =>
              done()

      it 'should send a "claimdevice" message', ->
        expect(@message.topic).to.deep.equal 'claimdevice'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromUuid: @device.uuid
          fromIp:   "127.0.0.1"
          request:
            uuid: @newDevice.uuid
        }

    describe 'when called with an invalid request', ->
      beforeEach (done) ->
        @meshblu.claimdevice uuid: 'invalid-uuid', (data) =>
          @eventForwarder.once 'message', (@message) =>
            done()

      it 'should send an "claimdevice-error" message', ->
        expect(@message.topic).to.deep.equal 'claimdevice-error'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromUuid: @device.uuid
          fromIp:   '127.0.0.1'
          error:    'Device not found'
          request:
            uuid: 'invalid-uuid'
        }

  describe 'EVENT getPublicKey', ->
    describe 'when called with a valid request', ->
      beforeEach (done) ->
        @meshblu.getPublicKey @config.uuid, (error) =>
          @eventForwarder.once 'message', (@message) =>
            done()

      it 'should send a "getpublickey" message', ->
        expect(@message.topic).to.deep.equal 'getpublickey'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          request:
            uuid: @config.uuid
        }

    describe 'when called with an invalid request', ->
      beforeEach (done) ->
        @meshblu.getPublicKey 'invalid-uuid', (error) =>
          @eventForwarder.once 'message', (@message) =>
            done()

      it 'should send an "getpublickey-error" message', ->
        expect(@message.topic).to.deep.equal 'getpublickey-error'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          error: 'Device not found'
          request:
            uuid: 'invalid-uuid'
        }

  describe 'EVENT resetToken', ->
    describe 'when called with a valid request', ->
      beforeEach (done) ->
        @meshblu.register configWhitelist: ['*'], (data) =>
          return done new Error data.error if data.error?

          @newDevice = data
          @meshblu.resetToken @newDevice.uuid, (data) =>
            return done new Error data.error if data.error?
            @eventForwarder.once 'message', (@message) =>
              done()

      it 'should send a "resettoken" message', ->
        expect(@message.topic).to.deep.equal 'resettoken'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromUuid: @device.uuid
          request:
            uuid: @newDevice.uuid
        }

    describe 'when called with an invalid request', ->
      beforeEach (done) ->
        @meshblu.resetToken 'invalid-uuid', (error) =>
          @eventForwarder.once 'message', (@message) =>
            done()

      it 'should send an "resettoken-error" message', ->
        expect(@message.topic).to.deep.equal 'resettoken-error'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromUuid: @device.uuid
          error:    'invalid device'
          request:
            uuid: 'invalid-uuid'
        }

  describe 'EVENT generateAndStoreToken', ->
    describe 'when called with a valid request', ->
      beforeEach (done) ->
        @meshblu.register configWhitelist: ['*'], (data) =>
          return done new Error data.error if data.error?

          @newDevice = data
          @meshblu.generateAndStoreToken uuid: @newDevice.uuid, (data) =>
            return done new Error data.error if data.error?
            @eventForwarder.once 'message', (@message) =>
              done()

      it 'should send a "generatetoken" message', ->
        expect(@message.topic).to.deep.equal 'generatetoken'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromUuid: @device.uuid
          request:
            uuid: @newDevice.uuid
        }

    describe 'when called with an invalid request', ->
      beforeEach (done) ->
        @meshblu.generateAndStoreToken uuid: 'invalid-uuid', (data) =>
          @eventForwarder.once 'message', (@message) =>
            done()

      it 'should send an "generatetoken-error" message', ->
        expect(@message.topic).to.deep.equal 'generatetoken-error'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromUuid: @device.uuid
          error:    'Device not found'
          request:
            uuid: 'invalid-uuid'
        }

  describe 'EVENT revokeToken', ->
    describe 'when called with a valid request', ->
      beforeEach (done) ->
        @meshblu.register configWhitelist: ['*'], (data) =>
          return done new Error data.error if data.error?

          @meshblu.generateAndStoreToken uuid: data.uuid, (device) =>
            @newDevice = device
            @meshblu.revokeToken @newDevice, =>
              @eventForwarder.once 'message', (@message) =>
                done()

      it 'should send a "revoketoken" message', ->
        expect(@message.topic).to.deep.equal 'revoketoken'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromUuid: @device.uuid
          request:
            uuid: @newDevice.uuid
        }

    describe 'when called with an invalid request', ->
      beforeEach (done) ->
        @meshblu.revokeToken uuid: 'invalid-uuid', token: 'invalid-token', (error) =>
          @eventForwarder.once 'message', (@message) =>
            done()

      it 'should send an "revoketoken-error" message', ->
        expect(@message.topic).to.deep.equal 'revoketoken-error'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromUuid: @device.uuid
          error:    'Device not found'
          request:
            uuid: 'invalid-uuid'
        }

  describe 'EVENT register', ->
    describe 'when called with a valid request', ->
      beforeEach (done) ->
        @meshblu.register {}, (data) =>
          return done new Error data.error if data.error?

          @eventForwarder.once 'message', (@message) =>
            done()

      it 'should send a "register" message', ->
        expect(@message.topic).to.deep.equal 'register'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          request:
            ipAddress: '127.0.0.1'
        }

    describe 'when called with an invalid request', ->
      beforeEach (done) ->
        @meshblu.register uuid: 'not-allowed', (error) =>
          @eventForwarder.once 'message', (@message) =>
            done()

      it 'should send an "register-error" message', ->
        expect(@message.topic).to.deep.equal 'register-error'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          error:  'Device not updated'
          request:
            uuid: 'not-allowed'
            ipAddress: '127.0.0.1'
        }

  describe 'EVENT unregister', ->
    describe 'when called with a valid request', ->
      beforeEach (done) ->
        @meshblu.register {}, (data) =>
          return done new Error data.error if data.error?

          @newDevice = data
          @meshblu.unregister uuid: @newDevice.uuid, (data) =>
            return done new Error data.error if data.error?
            @eventForwarder.once 'message', (@message) =>
              done()

      it 'should send a "unregister" message', ->
        expect(@message.topic).to.deep.equal 'unregister'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromUuid: @device.uuid
          request: {uuid: @newDevice.uuid}
        }

    describe 'when called with an invalid request', ->
      beforeEach (done) ->
        @meshblu.unregister uuid: 'invalid-uuid', (error) =>
          @eventForwarder.once 'message', (@message) =>
            done()

      it 'should send an "unregister-error" message', ->
        expect(@message.topic).to.deep.equal 'unregister-error'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          error:  'invalid device to unregister'
          fromUuid: @device.uuid
          request: {uuid: 'invalid-uuid'}
        }

  describe 'EVENT mydevices', ->
    describe 'when called with a valid request', ->
      beforeEach (done) ->
        @meshblu.register owner: @device.uuid, =>
          @meshblu.mydevices {}, =>
            @eventForwarder.once 'message', (@message) =>
              done()

      it 'should send a "devices" message', ->
        expect(@message.topic).to.deep.equal 'devices'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromUuid: @device.uuid
          request:
            owner: @device.uuid
        }

    describe 'when called with an invalid request', ->
      beforeEach (done) ->
        @meshblu.mydevices {uuid: 'invalid-uuid'}, =>
          @eventForwarder.once 'message', (@message) =>
            done()

      it 'should send a "devices-error" message', ->
        expect(@message.topic).to.deep.equal 'devices-error'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromUuid: @device.uuid
          error: "Devices not found"
          request:
            owner: @device.uuid
            uuid: 'invalid-uuid'
        }

  describe 'EVENT subscribe', ->
    describe 'when called with a valid request', ->
      beforeEach (done) ->
        @meshblu.subscribe {uuid: @device.uuid}, (data) =>
          return done new Error data.error if data.error?

          @eventForwarder.once 'message', (@message) =>
            done()

      it 'should send a "subscribe" message', ->
        expect(@message.topic).to.deep.equal 'subscribe'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromUuid: @device.uuid
          request:
            uuid: @device.uuid
        }

    describe 'when called with a valid request with token', ->
      beforeEach (done) ->
        @meshblu.subscribe {uuid: @device.uuid, token: @device.token}, (data) =>
          return done new Error data.error if data.error?

          @eventForwarder.once 'message', (@message) =>
            done()

      it 'should send a "subscribe" message', ->
        expect(@message.topic).to.deep.equal 'subscribe'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromUuid: @device.uuid
          request:
            uuid: @device.uuid
        }

  describe 'EVENT identity', ->
    describe 'when called with a valid request', ->
      beforeEach (done) ->
        @meshblu.identify()
        @eventForwarder.once 'message', (@message) =>
          done()

      it 'should send a "identity" message', ->
        expect(@message.topic).to.deep.equal 'identity'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          request:
            uuid: @device.uuid
        }

    describe 'when called with an invalid request', ->
      beforeEach (done) ->
        @tempMeshblu = meshblu.createConnection _.pick(@config, 'server', 'port')
        @tempMeshblu.once 'ready', (@newDevice) =>
          @eventForwarder.once 'message', (@message) =>
            done() # To ignore the first 'identity' message

      beforeEach (done) ->
        @tempMeshblu.bufferedSocketEmit 'identity', uuid: 'invalid-uuid', debug: true
        @eventForwarder.on 'message', (message) =>
          if message.topic == 'identity-error'
            @message = message
            @eventForwarder.removeAllListeners 'message'
            done()

      it 'should send a "identity-error" message', ->
        expect(@message.topic).to.deep.equal 'identity-error'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          error: "Device not found or token not valid"
          request:
            uuid: 'invalid-uuid'
        }

  describe 'EVENT message', ->
    describe 'when called with a valid request', ->
      beforeEach (done) ->
        @meshblu.message {devices: ['some-uuid']}
        @eventForwarder.on 'message', (message) =>
          if message.topic == 'message'
            @message = message
            @eventForwarder.removeAllListeners 'message'
            done()

      it 'should send a "message" message', ->
        expect(@message.topic).to.deep.equal 'message'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromUuid: @device.uuid
          request:
            devices: ['some-uuid']
        }

  describe 'EVENT data', ->
    describe 'when called with a valid request', ->
      beforeEach (done) ->
        @meshblu.data uuid: @device.uuid, value: 1, =>
          @eventForwarder.once 'message', (@message) =>
            done()

      it 'should send a "data" message', ->
        expect(@message.topic).to.deep.equal 'data'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromUuid: @device.uuid
          request:
            uuid: @device.uuid
            value: 1
        }

    describe 'when called with an invalid request', ->
      beforeEach (done) ->
        @meshblu.data uuid: 'invalid-uuid', value: 1, =>
          @eventForwarder.once 'message', (@message) =>
            done()

      it 'should send a "data-error" message', ->
        expect(@message.topic).to.deep.equal 'data-error'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromUuid: @device.uuid
          error: "Device not found"
          request:
            uuid: 'invalid-uuid'
            value: 1
        }

  describe 'EVENT getdata', ->
    describe 'when called with a valid request', ->
      beforeEach (done) ->
        @meshblu.getdata uuid: @device.uuid, token: @device.token, =>
        @eventForwarder.on 'message', (message) =>
          if message.topic == 'subscribe'
            @message = message
            @eventForwarder.removeAllListeners 'message'
            done()

      it 'should send a "subscribe" message', ->
        expect(@message.topic).to.deep.equal 'subscribe'
        expect(_.omit @message.payload, '_timestamp').to.deep.equal {
          fromUuid: @device.uuid
          request:
            type: 'data'
            uuid: @device.uuid
        }
