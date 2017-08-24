module.exports = 
  class Mongoose
    
    constructor: (@Schema) ->
    
    _paths: => 
      Object.keys @Schema.paths
    
    _pathsByType: (type) => 
      @_paths().filter (path) => type.toLowerCase() is @Schema.paths[path].instance.toLowerCase()

    numbers: => @_pathsByType 'Number'

    dates: => @_pathsByType 'Date'
    
    booleans: => @_pathsByType 'Boolean'
    
    objectIds: => @_pathsByType 'ObjectId'
