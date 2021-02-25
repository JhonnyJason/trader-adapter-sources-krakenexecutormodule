krakenexecutormodule = {name: "krakenexecutormodule"}
############################################################
#region printLogFunctions
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["krakenexecutormodule"]?  then console.log "[krakenexecutormodule]: " + arg
    return
ostr = (obj) -> JSON.stringify(obj, null, 4)
olog = (obj) -> log "\n" + ostr(obj)
print = (arg) -> console.log(arg)
#endregion


############################################################
KrakenClient = require('kraken-api')
tasks = null

############################################################
heartbeatIntervalId = 0
heartbeatMS = 0

############################################################
kraken = null
krakenTranslation = null
ourNameToKrakenName = {}

############################################################
krakenexecutormodule.initialize = () ->
    log "krakenexecutormodule.initialize"
    tasks = allModules.taskmodule
    krakenTranslation = allModules.krakentranslationmodule

    c = allModules.configmodule
    kraken       = new KrakenClient(c.apiKey, c.secret)
    heartbeatMS = c.executorHeartbeatS * 1000
    
    digestKrakenTranslation()
    setInterval(heartbeat, heartbeatMS)
    return

############################################################
#region internalFunctions
heartbeat = ->
    task = tasks.getTask()
    return unless task? 
    olog task
    if task.type == "cancelOrder" then cancelOrder(task.order)
    if task.type == "placeOrder" then placeOrder(task.order)
    return

############################################################
#region executeTasks
cancelOrder = (order) ->
    log "cancelOrder"
    try
        txid = order.id
        
        if !txid? then throw new Error("No order Id!")

        data = {txid}
        # olog data

        result = await kraken.api("CancelOrder", {txid})
        # olog result
    catch err
        log "Error: in executeCancelTask!"
        log err
    return

placeOrder = (order) ->
    log "placeOrder"
    try
        ## get krakenPair from krakentranslationmodule
        pair = ourNameToKrakenName[order.pair]
        
        if !pair? then throw new Error("Unsupported asset pair!")

        type = order.type
        ordertype = "limit"
        price = parseFloat(order.price)
        volume = parseFloat(order.volume)
        data = {pair,type,ordertype,price,volume}
        # olog data

        result = await kraken.api("AddOrder", data)    
        # olog result
    catch err
        log "Error: in executePlaceOrderTask!"
        log err
    return

#endregion

digestKrakenTranslation = ->
    log "digestKrakenTranslation"
    pairs = krakenTranslation.relevantAssetPairs
    for pair in pairs
        ourNameToKrakenName[pair.ourName] = pair.krakenName
    return
#endregion

module.exports = krakenexecutormodule