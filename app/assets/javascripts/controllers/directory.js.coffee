$(document).ready ->

  search_callback = (query) ->
    Directory.search query

  directory = new Directory(search_callback: search_callback)
