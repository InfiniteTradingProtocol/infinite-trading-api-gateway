##########################################################################
#
#* @param apiKey The API key for authentication
#* @param protocol The protocol to use
#* @param network The network to use
#* @param pool The pool to target
#* @response 200 Returns the result of the bot deletion
#* @response 400 Bad request
#* @response 500 Internal server error
#* @tag Bot
#* @get /deleteBot
#
##########################################################################

deleteBotHandler =function(apiKey,protocol="dhedge",network,pool) {
        protocol=tolower(protocol); pool = tolower(pool); network = tolower(network);
        check = basic_check(network=network,protocol=protocol,pool=pool,apiKey=apiKey)
        if (check$status == "fail") { return(check) }
        url <- paste0(pep,"deleteBot?apiKey=",apiKey,"&protocol=",protocol,"&pool=",pool,"&network=",network,"&pair=",pair,"&side=",side,"&threshold=",threshold,"&max_usd=",max_usd,"&slippage=",slippage,"&share=",share,"&platform=",platform)
        # Perform the POST request
        if (res$status == "success") { response <- POST(url); content_response = content(response,"text"); parsed_response <- fromJSON(content_response) }
}

pr$handle("GET","/deleteBot",deleteBotHandler, comment="This endpoint is used to turn off the trading bot.")
