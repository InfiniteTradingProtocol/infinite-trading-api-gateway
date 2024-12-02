##########################################################################
#
#* @param apiKey The API key for authentication
#* @param protocol The protocol to use
#* @param pool The pool to target
#* @param network The network to use
#* @param pair The trading pair
#* @param side The side to set (long, short, or neutral)
#* @param threshold The threshold for the strategy (default is 1)
#* @param max_usd The maximum USD amount (default is 10,000,000)
#* @param slippage The slippage percentage (default is 1)
#* @param share The share percentage (default is 100)
#* @param platform The platform to use (default is uniswapV3)
#* @response 200 Returns the result of setting the bot strategy
#* @response 400 Bad request
#* @response 500 Internal server error
#* @tag Bot
#* @get /setBot
#
##########################################################################

setBotHandler = function(apiKey,protocol="dhedge",pool,network,pair,side,threshold=1,max_usd=10000000,slippage=1,share=100,platform="uniswapV3") {
        protocol=tolower(protocol); pool = tolower(pool); network = tolower(network); pair = toupper(pair); side = tolower(side); platform = tolower(platform)
        check = basic_check(network=network,protocol=protocol,pool=pool,apiKey=apiKey)
        if (check$status == "fail") { return(check) }
        if (!is.null(max_usd)) { max_usd = as.numeric(max_usd) }
        slippage = as.numeric(slippage); share = as.numeric(share); threshold=as.numeric(threshold)

        res = c(); res$status = "success"
        #i need to check if the API is valid for the specific pool.
        #i need to check if the wallet is linked.
        if (side != "neutral" && side != "short" && side != "long") { res = list(status = "fail",status_code=1008,message="The specified side is not long/short/neutral") }
        if (!is.na(threshold)) {
                if (threshold >= 1 && threshold <= 100) { threshold = round(threshold) }
                else { res = list(status="fail",status_code=1006,message="threshold is not an integer between the expected range [1,100]") }
        }
        else { res = list(status="fail",status_code=1006,message="threshold is not an integer between the expected range [1,100]") }
        if (!is.na(share)) {
                if (share >=1 && share <= 100) { share = round(share) }
                else { res = list(status="fail",status_code=1007,message="error: share is not an integer between [1,100]") }
        }
        else { res = list(status="fail",status_code=1007,message="error: share is not an integer between [1,100]") }
        if (!is.null(max_usd)) {
                if (is.na(max_usd)) { res = list(status="fail",error_code=1011,message="The specified max_usd parameter is not numeric") }
                if (max_usd > 0) { max_usd = round(max_usd,2) }
                else { res = list(status="fail",error_code=1009,message="The speficied max_usd parameter must be a number > 0") }
        }
        url <- paste0(pep,"setSide?apiKey=",apiKey,"&protocol=",protocol,"&pool=",pool,"&network=",network,"&pair=",pair,"&side=",side,"&threshold=",threshold,"&max_usd=",max_usd,"&slippage=",slippage,"&share=",share,"&platform=",platform)
        # Perform the POST request
        if (res$status == "success") { response <- POST(url); content_response = content(response,"text"); parsed_response <- fromJSON(content_response) }
        else { parsed_response = res }
        masked_api = mask_api(apiKey)
        msg = paste0(res$status," setBot invoked apiKey: ",masked_api, " / pool: ",pool," / protocol: ", protocol, " / network: ",network,"/ pair: ", pair,"/ side: ",side," / thresholds: ",threshold," / max usd:",max_usd," / slippapge: ",slippage," / share: ",share," / platform: ",platform," / response: ",content_response)
        print(msg)
        discord(msg=msg,channel="#api-logs",db=FALSE)
        return(parsed_response)
}

pr$handle("GET","/setBot",setBotHandler, comment="This endpoint is used to set the sides of your tradingbot strategy on a specific pool, network and protocol. The sides are used by the tradebots to monitor and rebalance the pools according to the strategy. The sides can be long, short or neutral." )
