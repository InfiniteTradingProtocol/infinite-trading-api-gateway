tradeHandler <- function(req, res, from, to, platform="uniswapV3", slippage=0.5, threshold=1, network="polygon", pool, share=100, protocol="dhedge", apiKey) {
  	# List of required parameters
  	required_params <- c("from", "to", "platform", "network", "pool", "share", "apiKey")
  	print(req$query)

  	# Assuming buy_dhedge() is your function to process the trade

  	result <- buy_defi(from=from, to=to, platform=platform, slippage=slippage, network=network, pool=pool, share=share, protocol=protocol, manager=manager,amount=amount)

  	#Return the result of buy_dhedge() function or another appropriate response
	return(result)
}

pr$handle("GET","/trade",tradeHandler, comment="This endpoint is used to execute trades inside a specific pool on the specified protocol, network and for the specified asset. You can also specify the platform, slippage,share threshold and max_usd amount for the trading." )
