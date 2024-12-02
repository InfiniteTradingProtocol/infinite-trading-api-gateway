##########################################################################
#* @hide
#* @param apiKey The API key for authentication
#* @param protocol The protocol to use
#* @param network The network to use
#* @param pool The pool to target
#* @response 200 Returns the result of the fee claiming process
#* @response 400 Bad request
#* @response 500 Internal server error
#* @tag Fees
#* @get /claimFees
#
##########################################################################

claimFeesHandler =function(apiKey,protocol="dhedge",network,pool) {
        protocol=tolower(protocol); pool = tolower(pool); network = tolower(network);
        check = basic_check(network=network,protocol=protocol,pool=pool,apiKey=apiKey)
        if (check$status == "fail") { return(check) }
        return(list(status="success",status_code=200,message="Endpoint not available yet"))
}

pr$handle("GET","/claimFees",claimFeesHandler,comment="This endpoint is used to mint performance and management fees into a specified pool.")
