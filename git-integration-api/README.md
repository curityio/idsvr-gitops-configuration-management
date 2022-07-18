# A Kotlin API to call GitHub APIs

A utility API with some code to create a GitHub pull request with changed configuration data.\
This involves a few technical steps, summarized below. 

## Interface

## Create a Commit

## Create a Branch

## Create a Pull Request

override fun handle(caught: Exception?, request: Request?, response: Response?) {

        println("API problem encountered")
        caught?.printStackTrace();

        val mapper = ObjectMapper()
        val data = mapper.createObjectNode()

        data.put("code", "server_error")
        data.put("message", "Problem encountered in the Git Integration API")
        println(caught?.message)

        response?.status(500)
        response?.header("content-type", "application/json")
        response?.body(data.toString())
    }