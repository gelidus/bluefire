global.CurrentWorkingDirectory = process.cwd() # set current dit to global for easy pathing

DependencyInjector = require("./di/Injector")

Async = require("async")
Configuration = require("./config").Configuration
ConfigurationManager = require("./config").ConfigurationManager

Services = require("./services/Services")
TaskManager = require("./task/TaskManager")
Connection = require("./connection/Connection")

###
  Base Bluefire module. When install is called, application will try to load
  various files from folders (see documentation). This will enable structured
  approach to application style.
###
module.exports = class Application extends Connection

  ###
    Creates just basic applicatin with parser and tcp setup
  ###
  constructor: (isServer = true) ->
    #process.on "uncaughtException", (err) -> # catch all uncaught exceptions here. What to do next?
    #  console.log "Uncaught exception captured : #{err}"
    global.Injector = new DependencyInjector() #establish injector

    super(isServer) # creates defualt parser and injects server

    @taskManager = new TaskManager()
    # add task manager to the injector services
    Injector.addService("$taskmgr", @taskManager)

    @services = new Services()

    Injector.addService("$service", @services) # add connections to injector

  ###
    Installs the whole application using structured approach

    @param callback [Function] function to be called after install
  ###
  install: (callback) =>
    if globalConfiguration.get("configuration") is "debug"
      global.debug = (debugText) ->
        console.log debugText
    else
      global.debug = () ->
        # nothing here

    Async.series([
      (asyncCallback) =>
        @configurationManager = new ConfigurationManager
        @configurationManager.load (err) ->
          asyncCallback(err, 1)
      
      (asyncCallback) =>
        @taskManager.install(asyncCallback)

      (asyncCallback) =>
        @services.install(@configurationManager.get("connections"), @configurationManager.get("models"), asyncCallback)

      (asyncCallback) =>
        super(@configurationManager.get("config"), @configurationManager.get("routes"), asyncCallback) # call server install
    ], callback)

  ###
    Configurate the application. All currently injectable items will be injected
    into the callback function

    @param function [Function] injected callback for configuration

    @exmaple Configurate the application (application is already created Application instance)
      application.config ($connect, $router) ->
        # see documentation for injectable application modules to access API
  ###
  config: (callback) =>
    Injector.inject(callback, @)

  onConnect: (session) ->
    # virtual method - override this when needed

  _onDisconnect: (session) ->
    console.log "Client disconnected"
    session.removeAllTasks() # remove all current tasks on the session
    #@onDisconnect(session)

  onDisconnect: (session) =>
    # virtual method - override this when needed

  _onData: (session, packetName, data) =>
    @onData(session, packetName, data)

  ###
    @virtual
  ###
  onData: (session, packetName, data) =>
    # virtual method - override this when needed