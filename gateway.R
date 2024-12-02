########################
# Infinite Trading API
# Author: etherpilled
########################

#* @apiTitle Infinite Trading Protocol API v1

####################
# Packages required
####################

require(plumber); require(data.table); require(DBI); require(RSQLite); require(lubridate); require(jsonlite); require(httr); require(dotenv)
load_dot_env("~/infinitetrading/src/api/.env")

# Initialize SQLite database

db <- RSQLite::dbConnect(SQLite(), "api_logs.sqlite")
RSQLite::dbExecute(db, "
  CREATE TABLE IF NOT EXISTS api_logs (
    id INTEGER PRIMARY KEY,
    timestamp TEXT,
    endpoint TEXT,
    api_key TEXT,
    ip TEXT
  )
")
if (RSQLite::dbExistsTable(db, "api_logs")) {
  print("Connection successful, and table exists.")
} else {
  stop("Table does not exist or database file is invalid.")
}

####################
# Dependencies
####################

wd = "~/infinitetrading/src/"
source(paste0(wd,"/api/messaging.R"))
source(paste0(wd,"/api/graphQL.R")) 
source(paste0(wd,"/tradebot/defi.R"))
source(paste0(wd,"/api/getGasBalances.R"))

add_endpoint = function(name) {
        path = paste0(wd,"api/gateway/endpoints/")
        file = paste0(path,name,".R")
        source(file)
}

###################
# Input validation
###################

isValidAPIKey <- function(api_key) {
  pattern <- "^[a-fA-F0-9]{128}$"
  if (grepl(pattern, api_key, perl = TRUE)) return(TRUE)
  return(FALSE)
}

isValidEthereumAddress <- function(address) {
  pattern <- "^0x[a-fA-F0-9]{40}$"
  if (grepl(pattern, address, perl = TRUE)) return(TRUE)
  return(FALSE)
}

isValidTrader <- function(protocol,pool,trader) {
	if (tolower(getPoolTrader(protocol,pool)) == tolower(trader)) return(TRUE)
	return(FALSE)
}

mask_api <- function(api_key) {
  api_length <- nchar(api_key)
  return(paste0("***",substr(api_key, api_length - 4, api_length)))
}

isValidEthPrivateKey <- function(privateKey) {
    if (startsWith(privateKey, "0x")) { privateKey <- substr(privateKey, 3, nchar(privateKey)) }
    return(nchar(privateKey) == 64 && grepl("^[0-9a-fA-F]+$", privateKey))
}

db_connect = function(user,hostname,port,password,dbname){
        default_authentication_plugin=password
        con = dbConnect(RMariaDB::MariaDB(),user = user, password = password, dbname = dbname,hostname = hostname)
        return(con)
}

db_con = function() { db_connect(Sys.getenv("db_user"),Sys.getenv("db_ip"),Sys.getenv("db_port"),Sys.getenv("db_password"),dbname=Sys.getenv("db_schema")) }

#express endpoint
ep = Sys.getenv("express_api")
pep = Sys.getenv("plumber_api")

is_valid_network <- function(network) {
  network <- gsub("[ ']", "", network)
  conn <- db_con()
  query <- "SELECT COUNT(*) as count FROM networks WHERE name = LOWER(?)"
  result <- dbGetQuery(conn, query, params = list(network))
  dbDisconnect(conn)
  return(result$count > 0)
}

is_valid_protocol <- function(protocol) {
  protocol <- gsub("[ ']", "", protocol)
  conn <- db_con()
  query <- "SELECT COUNT(*) as count FROM protocols WHERE name = LOWER(?)"
  result <- dbGetQuery(conn, query, params = list(protocol))
  dbDisconnect(conn)
  return(result$count > 0)
}

is_valid_pair <- function(network, pair) {
  network <- gsub("[ ']", "", network)
  pair <- gsub("[ ']", "", pair)
  conn <- db_con()
  query <- "SELECT COUNT(*) as count FROM pairs p JOIN networks n ON p.network_id = n.network_id WHERE n.name = LOWER(?) AND p.pair = ?"
  result <- dbGetQuery(conn, query, params = list(network, pair))
  dbDisconnect(conn)
  return(result$count > 0)
}

basic_check <- function(network, protocol, apiKey,pool= NULL, wallet = NULL,pair= NULL,trader=NULL) {
  network <- tolower(network); protocol <- tolower(protocol)
  if (!is_valid_network(network)) return(list(status="fail", status_code="1000", message="Unrecognized network")) 
  if (!is_valid_protocol(protocol)) return(list(status="fail", status_code="1001", message="Unrecognized protocol")) 
  if (!isValidAPIKey(apiKey)) return(list(status="fail", status= "1002", message="Invalid API Key")) 
  if (!is.null(pair)) {
	  if (!is_valid_pair(network, pair)) return(list(status="fail", status_code="1003", message="Invalid Pair")) 
  }
  if (!is.null(pool)) { 
  	if (!isValidEthereumAddress(pool)) return(list(status="fail", status_code="1004", message="Invalid Pool Address")) 
  }
  if (!is.null(wallet)) {
    	if (!isValidEthereumAddress(wallet)) return(list(status="fail", status_code="1005", message="Invalid Ethereum Address")) 
  }
  if (!is.null(trader)) { 
  	if (!isValidTrader(protocol=protocol,pool=pool,trader=trader)) return(list(status="fail", status_code="1006", message="The trader wallet is not configured as a trader in the specified pool")) 
  }
  return(list(status="success"))
}


#####################################################################################
# Run the API
# Initialize a list to track requests
#####################################################################################


pr <- Plumber$new()
options(encoding = "UTF-8")
request_tracker <- new.env()
limit_store <- new.env(parent = emptyenv())
# Middleware function for rate limiting
rate_limit_middleware <- function(req){
  # Identify the client (simplistic approach using IP address)
  client_ip <- req$HTTP_X_REAL_IP
  #client_ip <- req$REMOTE_ADDR
  # Set limits: max requests allowed and time window in seconds
  max_requests <- 600 # for example, 600 requests
  time_window <- 60 # for example, 1 hour (3600 seconds)

  # Get the current time
  current_time <- Sys.time()
  log_entry <- data.frame(timestamp = current_time, endpoint = req$PATH_INFO, api_key = ifelse(is.null(req$argsQuery$apiKey), "None", req$argsQuery$apiKey),ip = client_ip)
  RSQLite::dbWriteTable(db, "api_logs", log_entry, append = TRUE, row.names = FALSE)
  # Initialize or update the request tracker for the client
  if (!is.null(request_tracker[[client_ip]])) { request_tracker[[client_ip]] <<- request_tracker[[client_ip]][request_tracker[[client_ip]] > (current_time - time_window)] } 
  else { request_tracker[[client_ip]] <<- c() }

  # Add the current request to the tracker
  request_tracker[[client_ip]] <<- c(request_tracker[[client_ip]], current_time)

  # Check if the request limit has been exceeded
  if (length(request_tracker[[client_ip]]) > max_requests) {
    res = c()
    res$status <- 429  # Set status code directly on the res object
    res$body <- toJSON(list(error = "Rate limit exceeded"), auto_unbox = TRUE)
    return(res)
  }

  plumber::forward()
}

# Register the middleware
pr$registerHooks(list(
  "preroute" = rate_limit_middleware
))

add_endpoint("createGasWallet")
add_endpoint("getNewApiKey")
add_endpoint("linkGasWallet")
add_endpoint("unlinkGasWallet")
add_endpoint("approve")
add_endpoint("setBot")
add_endpoint("deleteBot")
add_endpoint("getCandles")
add_endpoint("getTicks")
add_endpoint("getContract")
add_endpoint("getSymbol")
add_endpoint("poolComposition")
add_endpoint("getTotalYield")
add_endpoint("getEstimatedAnualYield") 
#add_endpoint("trade")
#add_endpoint("createStrategy")
#add_endpoint("deleteStrategy")
#add_endpoint("setAllocations")
#add_endpoint("getCurrentAllocations")
#add_endpoint("isPoolTrader")
#add_endpoint("setAllowedAssets")
#add_endpoint("rebalancePool")
#add_endpoint("claimFees")

pr$setApiSpec(function(spec) {
  spec$info$title <- "Infinite Trading API"
  spec$info$description <- "Deploy automated trading strategies in DeFi without worriying about infrastructure."
  spec$info$version <- "1.0.0"
  spec
})

pr$run(host="0.0.0.0",port=8003)
