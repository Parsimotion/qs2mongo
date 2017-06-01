module.exports = 
  class Mongoose
    
    constructor: (@Schema) ->
    
    _paths: => 
      Object.keys @Schema.paths
    
    _pathsByType: (type) => 
      @_paths().filter (path) => type is @Schema.paths[path].instance

    numbers: => @_pathsByType 'Number'

    dates: => @_pathsByType 'Date'
    
    booleans: => @_pathsByType 'Boolean'
