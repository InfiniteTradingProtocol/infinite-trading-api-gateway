#######################################################
#
#* @param network The network to use
#* @enum network:red,blue,green
#* @param protocol The protocol to use
#* @param wallet The wallet to link
#* @param pool The pool to target
#* @param apiKey The API key for authentication
#param provider The RPC provider (infura, alchemy, dRPC)
#param provider_key The RPC API Key
#* @response 200 Returns the result of the linking process
#* @response 400 Bad request
#* @response 500 Internal server error
#* @tag Wallet
#* @get /linkGasWallet
#
#######################################################

#linkGasWalletHandler = function(network,protocol="dhedge",wallet,pool,apiKey,provider="infura",provider_key) {
linkGasWalletHandler = function(network,protocol="dhedge",wallet,pool,apiKey) {
        network = tolower(network); protocol=tolower(protocol); wallet = tolower(wallet); check = basic_check(network=network,protocol=protocol,pool=pool,apiKey=apiKey,trader=wallet)
        if (check$status == "fail") return(check)
        gasBalance = getGasBalances(addresses=wallet,network=network)
        if (gasBalance == 0) return(list(status="fail",status_code=500,message="Your wallet gas token balance is 0, please send at least $1 USD worth of gas before linking the wallet."))
        #response <- POST(paste0(pep,"linkGasWallet?network=",network,"&protocol=",protocol,"&wallet=",wallet,"&pool=",pool,"&apiKey=",apiKey,"&provider=",provider,"&provider_key",provider_key))
        response <- POST(paste0(pep,"linkGasWallet?network=",network,"&protocol=",protocol,"&wallet=",wallet,"&pool=",pool,"&apiKey=",apiKey))
	response_content <- content(response, "text")
        parsed_response <- fromJSON(response_content)
        print(parsed_response)
        return(parsed_response)
}

pr$handle("GET","/linkGasWallet",linkGasWalletHandler, comment="This endpoint associates a gas wallet with a specific pool into the specified protocol and network. The wallet must be authorized as a trader wallet to be able to link it.")
