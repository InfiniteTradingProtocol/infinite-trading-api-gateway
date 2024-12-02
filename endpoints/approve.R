#######################################################
#
#* @param network The network to use
#* @enum network:polygon,arbitrum,optimism
#* @param protocol The protocol to use
#* @enum protocol: dhedge
#* @param asset The asset to approve
#* @enum: WBTC,WETH,WMATIC,ETHBEAR1X,BTCBEAR1X, MATICBEAR1X, OP
#* @param platform The platform where the trade will be executed
#* @enum: uniswapV3, toros, 1inch
#* @param pool The pool to target
#* @param apiKey The API key for authentication
#* @response 200 Returns the result of the linking process
#* @response 400 Bad request
#* @response 500 Internal server error
#* @tag approve
#* @get /approve
#
#######################################################

approveHandler = function(network,protocol="dhedge",pool,apiKey,platform="uniswapV3",asset) {
        network = tolower(network); protocol=tolower(protocol); platform=tolower(platform); check = basic_check(network=network,protocol=protocol,pool=pool,apiKey=apiKey)
        if (check$status == "fail") return(check)
        #gasBalance = getGasBalances(addresses=wallet,network=network)
        #if (gasBalance == 0) return(list(status="fail",status_code=500,message="Your gas wallet balance is 0, please send at least $5 USD worth of gas before approving assets"))
        response <- POST(paste0(pep,"approve?network=",network,"&protocol=",protocol,"&pool=",pool,"&apiKey=",apiKey,"&asset=",asset,"&platform=",platform))
        response_content <- content(response, "text")
        parsed_response <- fromJSON(response_content)
        print(parsed_response)
        return(parsed_response)
}

pr$handle("GET","/approve",approveHandler, comment="This endpoint is used to approve the assets to be trade within the pool for the gas wallet. If you plan to go also go short, You need to enable BTC1XBEAR ETH1XBEAR (Polygon,Optimism,Arbitrum) MATIC1XBEAR(Polygon) to be able to go short.")
